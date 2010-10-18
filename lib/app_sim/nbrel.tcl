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
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # TBD

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

                notifier send ::nbrel <Entity> delete $id
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

            notifier send ::nbrel <Entity> create $id
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
        dict with parmdict {
            notifier send ::nbrel <Entity> create [list $m $n]
        }
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

        notifier send ::nbrel <Entity> delete [list $m $n]
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
            rdb eval {
                SELECT * FROM nbrel_mn
                WHERE m=$m AND n=$n
            } undoData {
                unset undoData(*)
                set undoData(id) $id
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE nbrel_mn
                SET proximity     = nonempty($proximity,     proximity),
                    effects_delay = nonempty($effects_delay, effects_delay)
                WHERE m=$m AND n=$n
            } {}

            # NEXT, notify the app.
            notifier send ::nbrel <Entity> update $id

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
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
    # Refreshes the data in the NBHOOD:RELATIONSHIP:UPDATE dialog
    # when field values change.

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
    # Refreshes the data in the NBHOOD:RELATIONSHIP:UPDATE:MULTI dialog
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
# Orders: NBHOOD:RELATIONSHIP:*

# NBHOOD:RELATIONSHIP:UPDATE
#
# Updates existing neighborhood relationships


order define NBHOOD:RELATIONSHIP:UPDATE {
    title "Update Neighborhood Relationship"
    options \
        -sendstates PREP \
        -refreshcmd {::nbrel Refresh_NRU}

    parm id            key  "Neighborhood"       -table  gui_nbrel_mn  \
                                                 -key    {m n}         \
                                                 -labels {"Of" "With"}
    parm proximity     enum "Proximity"
    parm effects_delay text "Effects Delay (Days)"
} {
    # FIRST, prepare the parameters
    prepare id            -toupper  -required -type nbrel
    prepare proximity     -toupper            -type eproximity
    prepare effects_delay -toupper            -type rdays

    returnOnError

    # NEXT, can't change HERE for a neighborhood with itself
    lassign $parms(id) m n

    if {[valid proximity]} {
        if {$m eq $n && $parms(proximity) ne "HERE"} { 
            reject proximity "Proximity of $m to itself must be HERE"
        } elseif {$m ne $n && $parms(proximity) eq "HERE"} { 
            reject proximity \
                "Proximity of $m to $n cannot be HERE"
        }
    }

    # NEXT, effects_delay must be 0.0 if m=n
    if {[valid effects_delay]} {
        if {$m eq $n && $parms(effects_delay) != 0.0} {
            reject effects_delay \
                "Effects Delay cannot be non-zero for these neighborhoods."
        }
    }


    returnOnError -final

    # NEXT, modify the curve
    setundo [nbrel mutate update [array get parms]]
}


# NBHOOD:RELATIONSHIP:UPDATE:MULTI
#
# Updates multiple existing neighborhood relationships

order define NBHOOD:RELATIONSHIP:UPDATE:MULTI {
    title "Update Multiple Neighborhood Relationships"
    options \
        -sendstates PREP                   \
        -refreshcmd {::nbrel Refresh_NRUM}

    parm ids           multi  "IDs"                  -table gui_nbrel_mn \
                                                     -key   id

    parm proximity     enum   "Proximity"
    parm effects_delay text   "Effects Delay (Days)"
} {
    # FIRST, prepare the parameters
    prepare ids           -toupper  -required -listof nbrel
    prepare proximity     -toupper            -type eproximity
    prepare effects_delay -toupper            -type rdays

    returnOnError

    # NEXT, make sure that we're not changing the proximity when we
    # shouldn't.
    if {[valid proximity]} {
        foreach id $parms(ids) {
            lassign $id m n
            
            if {$m eq $n && $parms(proximity) ne "HERE"} {
                reject proximity \
           "Proximity cannot be HERE for these neighborhoods."
                break
            } elseif {$m ne $n && $parms(proximity) eq "HERE"} {
                reject proximity \
           "Proximity cannot be $parms(proximity) for these neighborhoods."
                break
            }
        }
    }

    # NEXT, make sure that we're not changing the effects_delay when we
    # shouldn't.
    if {[valid effects_delay]} {
        foreach id $parms(ids) {
            lassign $id m n
            
            if {$m eq $n && $parms(effects_delay) != 0.0} {
                reject effects_delay \
           "Effects Delay cannot be non-zero for these neighborhoods."
                break
            }
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

