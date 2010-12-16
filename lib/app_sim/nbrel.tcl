#-----------------------------------------------------------------------
# TITLE:
#    nbrel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Neighborhood Relationship Manager
#
#    This module is responsible for managing relationships between
#    neighborhoods (proximity and effects delay), and for allowing the 
#    analyst to update particular neighborhood relationships.
#    These relationships come and go as neighborhoods come and go.
#
#-----------------------------------------------------------------------

snit::type nbrel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An mn neighborhood relationship ID, [list $n $f $g]
    #
    # Throws INVALID if there's no neighborhood relationship for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id m n

        set m [nbhood validate $m]
        set n [nbhood validate $n]

        # No need to check for existence of the record in nbrel_mn; 
        # there are relationships for every pair of neighborhoods.

        return [list $m $n]
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate reconcile
    #
    # Determines which neighborhood relationships should exist, and 
    # adds or deletes them, returning an undo script.

    typemethod {mutate reconcile} {} {
        # FIRST, List required neighborhood relationships
        set valid [dict create]

        rdb eval {
            -- Nbgroup with force groups
            SELECT M.n   AS m, 
                   N.n   AS n
            FROM nbhoods AS M JOIN nbhoods AS N
        } {
            dict set valid [list $m $n] 0
        }

        # NEXT, Begin the undo script.
        set undo [list]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM nbrel_mn
        } row {
            unset -nocomplain row(*)

            set id [list $row(m) $row(n)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod Restore [array get row]]

                rdb eval {
                    DELETE FROM nbrel_mn
                    WHERE m=$row(m) AND n=$row(n)
                }
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id m n

            if {$m eq $n} {
                # A neighborhood is always "HERE" to itself.
                rdb eval {
                    INSERT INTO nbrel_mn(m,n,proximity)
                    VALUES($m,$n,'HERE')
                }
            } else {
                rdb eval {
                    INSERT INTO nbrel_mn(m,n)
                    VALUES($m,$n)
                }
            }

            lappend undo [mytypemethod Delete $m $n]
        }

        # NEXT, return the undo script
        return [join $undo \n]
    }


    # Restore parmdict
    #
    # parmdict     row dict for deleted entity
    #
    # Restores the entity in the database

    typemethod Restore {parmdict} {
        rdb insert nbrel_mn $parmdict
    }


    # Delete m n
    #
    # m,n    The indices of the entity
    #
    # Deletes the entity.  Used only in undo scripts.
    
    typemethod Delete {m n} {
        rdb eval {
            DELETE FROM nbrel_mn WHERE m=$m AND n=$n
        }
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {m n}
    #    proximity        Proximity of m to n from m's point of view
    #    effects_delay    Delay in days for effects to reach m from n
    #
    # Updates a neighborhood relationship given the parms, which are 
    # presumed to be valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id m n

            # FIRST, get the undo information
            set data [rdb grab nbrel_mn {m=$m AND n=$n}]

            # NEXT, Update the group
            rdb eval {
                UPDATE nbrel_mn
                SET proximity     = nonempty($proximity,     proximity),
                    effects_delay = nonempty($effects_delay, effects_delay)
                WHERE m=$m AND n=$n
            }

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # Refresh_NRU dlg fields fdict
    #
    # dlg       The order dialog
    # fields    Names of fields that changed
    # fdict     Current field values
    #
    # Refreshes the data in the NBREL:UPDATE dialog
    # when field values change.
    #
    # NOTE: The gui_nbrel_mn view is now defined such
    # that m != n.

    typemethod Refresh_NRU {dlg fields fdict} {
        # FIRST, if the id changed, refresh the fields.
        dict with fdict {
            if {"id" in $fields} {
                lassign $id m n
                set disabled [list]

                # NEXT, refresh proximity
                if {$m eq $n} {
                    $dlg field configure proximity -values HERE
                    lappend disabled proximity
                } else {
                    set values [lrange [eproximity names] 1 end]
                    $dlg field configure proximity -values $values
                }
                
                # NEXT, refresh effects_delay
                if {$m eq $n} {
                    lappend disabled effects_delay
                }

                $dlg disabled $disabled

                # NEXT, load the current data.
                $dlg loadForKey id
            }
        }
    }

    # Refresh_NRUM dlg fields fdict
    #
    # dlg       The order dialog
    # fields    Names of fields that changed
    # fdict     Current field values
    #
    # Refreshes the data in the NBREL:UPDATE:MULTI dialog
    # when field values change.

    typemethod Refresh_NRUM {dlg fields fdict} {
        if {"ids" ni $fields} {
            return
        }

        set disabled [list]

        set same 0
        set diff 0

        foreach id [dict get $fdict ids] {
            lassign $id m n

            if {$m eq $n} {
                incr same
            } else {
                incr diff
            }
        }

        if {$same > 0 && $diff > 0} {
            # Mixed bag
            # $dlg set proximity ""
            lappend disabled proximity
        } elseif {$same > 0} {
            # All are HERE
            $dlg field configure proximity -values HERE
            # $dlg set proximity HERE
            lappend disabled proximity
        } else {
            # None are HERE
            set values [lrange [eproximity names] 1 end]
            $dlg field configure proximity -values $values

            # $dlg set proximity ""
        }

        if {$same > 0} {
            lappend disabled effects_delay
        }

        $dlg disabled $disabled

        $dlg loadForMulti ids
    }
}


#-------------------------------------------------------------------
# Orders: NBREL:*

# NBREL:UPDATE
#
# Updates existing neighborhood relationships


order define NBREL:UPDATE {
    title "Update Neighborhood Relationship"
    options \
        -sendstates PREP                               \
        -refreshcmd {::orderdialog refreshForKey id *}

    parm id            key  "Neighborhood"       -table  gui_nbrel_mn  \
                                                 -key    {m n}         \
                                                 -labels {"Of" "With"}
    parm proximity     enum "Proximity"          -type   {ptype prox-HERE}
    parm effects_delay text "Effects Delay (Days)"
} {
    # FIRST, prepare the parameters
    prepare id            -toupper  -required -type nbrel
    prepare proximity     -toupper            -type {ptype prox-HERE}
    prepare effects_delay -toupper            -type rdays

    returnOnError

    # NEXT, can't change relationship of a neighborhood with itself
    lassign $parms(id) m n

    if {$m eq $n} {
        reject id "Cannot change the relationship of a neighborhood to itself."
    }

    returnOnError -final

    # NEXT, modify the curve
    setundo [nbrel mutate update [array get parms]]
}


# NBREL:UPDATE:MULTI
#
# Updates multiple existing neighborhood relationships

order define NBREL:UPDATE:MULTI {
    title "Update Multiple Neighborhood Relationships"
    options \
        -sendstates PREP                                  \
        -refreshcmd {::orderdialog refreshForMulti ids *}

    parm ids           multi  "IDs"                  -table gui_nbrel_mn \
                                                     -key   id

    parm proximity     enum   "Proximity"            -type  {ptype prox-HERE}
    parm effects_delay text   "Effects Delay (Days)"
} {
    # FIRST, prepare the parameters
    prepare ids           -toupper  -required -listof nbrel
    prepare proximity     -toupper            -type {ptype prox-HERE}
    prepare effects_delay -toupper            -type rdays

    returnOnError

    # NEXT, make sure that m != n.
    foreach id $parms(ids) {
        lassign $id m n
            
        if {$m eq $n} {
            reject ids \
                "Cannot change the relationship of a neighborhood to itself."
        }
    }

    returnOnError -final

    # NEXT, modify the curves
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [nbrel mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


