#-----------------------------------------------------------------------
# TITLE:
#    rel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Relationship Manager
#
#    This module is responsible for managing relationships between
#    groups as groups come and go, and for allowing the analyst
#    to update particular relationships.
#
#    Every group has a bidirectional relationship with every other
#    group.
#   
#
#-----------------------------------------------------------------------

snit::type rel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An fg relationship ID, [list $f $g]
    #
    # Throws INVALID if there's no relationship for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id f g

        set f [group validate $f]
        set g [group validate $g]

        return [list $f $g]
    }

    # exists f g
    #
    # f       A group ID
    # g       A group ID
    #
    # Returns 1 if relationship is tracked between f and g

    typemethod exists {f g} {
        rdb exists {
            SELECT * FROM rel_fg WHERE f=$f AND g=$g
        }
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
    # Determines which relationships should exist, and 
    # adds or deletes them, returning an undo script.
    #
    # TBD: Since every pair of groups now has a relationships, it
    # might be possible to simplify this code.

    typemethod {mutate reconcile} {} {
        # FIRST, List required relationships
        set valid [dict create]

        rdb eval {
            SELECT F.g       AS f, 
                   G.g       AS g
            FROM groups AS F
            JOIN groups AS G
        } {
            dict set valid [list $f $g] 0
        }

        # NEXT, Begin the undo script.
        set undo [list]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM rel_fg
        } row {
            unset -nocomplain row(*)

            set id [list $row(f) $row(g)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod Restore [array get row]]

                rdb eval {
                    DELETE FROM rel_fg
                    WHERE f=$row(f) AND g=$row(g)
                }
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id f g

            if {$f eq $g} {
                # Every group has a relationship of 1.0 with itself.
                rdb eval {
                    INSERT INTO rel_fg(f,g,rel)
                    VALUES($f,$g,1.0)
                }

            } else {
                # Otherwise, we get the default relationship.
                rdb eval {
                    INSERT INTO rel_fg(f,g)
                    VALUES($f,$g)
                }
            }

            lappend undo [mytypemethod Delete $f $g]
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
        rdb insert rel_fg $parmdict
    }


    # Delete f g
    #
    # f,g    The indices of the entity
    #
    # Deletes the entity.  Used only in undo scripts.
    
    typemethod Delete {f g} {
        rdb eval {
            DELETE FROM rel_fg WHERE f=$f AND g=$g
        }
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {f g}
    #    rel              Relationship of f with g
    #
    # Updates a relationship given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id f g

            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM rel_fg
                WHERE f=$f AND g=$g
            } undoData {
                unset undoData(*)
                set undoData(id) $id
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE rel_fg
                SET rel = nonempty($rel, rel)
                WHERE f=$f AND g=$g
            } {}

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

    #---------------------------------------------------------------
    # Order Helpers

    # Refresh_RU dlg fields fdict
    #
    # dlg        The order dialog
    # fields     Names of the fields that changed
    # fdict      Current field values.
    #
    # Disables "rel" if f=g

    typemethod Refresh_RU {dlg fields fdict} {
        if {"id" in $fields} {
            dict with fdict {
                lassign $id f g

                $dlg loadForKey id

                if {$f ne $g} {
                    $dlg disabled {}
                } else {
                    $dlg disabled rel
                }
            }
        }
    }

    # Refresh_RUM dlg fields fdict
    #
    # dlg        The order dialog
    # fields     Names of the fields that changed
    # fdict      Current field values.
    #
    # Disables "rel" if f=g

    typemethod Refresh_RUM {dlg fields fdict} {
        if {"ids" in $fields} {
            $dlg loadForMulti ids

            dict with fdict {
                foreach id $ids {
                    lassign $id f g
                    if {$f eq $g} {
                        $dlg disabled rel
                        return
                    }
                }
            }

            $dlg disabled {}
        }
    }
}


#-------------------------------------------------------------------
# Orders: REL:*

# REL:UPDATE
#
# Updates existing relationships

order define REL:UPDATE {
    title "Update Group Relationship"
    options \
        -sendstates PREP \
        -refreshcmd {::rel Refresh_RU}

    parm id   key   "Groups"         -table  gui_rel_fg \
                                     -key    {f g}      \
                                     -labels {Of With}
    parm rel  rel   "Relationship"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type rel
    prepare rel      -toupper            -type qrel

    returnOnError

    # NEXT, do cross-validation
    lassign $parms(id) f g

    validate rel {
        if {$f eq $g && $parms(rel) != 1.0
        } {
            reject rel \
              "invalid value \"$parms(rel)\", a group's relationship with itself must be 1.0"
        }
    }

    returnOnError -final

    # NEXT, modify the curve
    setundo [rel mutate update [array get parms]]
}


# REL:UPDATE:MULTI
#
# Updates multiple existing relationships

order define REL:UPDATE:MULTI {
    title "Update Multiple Relationships"
    options \
        -sendstates PREP \
        -refreshcmd {::rel Refresh_RUM}

    parm ids  multi  "IDs"           -table gui_rel_fg \
                                     -key   id
    parm rel  rel    "Relationship"
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof rel

    prepare rel      -toupper            -type qrel

    returnOnError

    # Cross-validate
    validate rel {
        foreach id $parms(ids) {
            lassign $id f g
 
            if {$f eq $g && $parms(rel) != 1.0} {
                reject rel \
                "invalid value \"$parms(rel)\", a group's relationship with itself must be 1.0"
            }
        }
    }

    returnOnError -final


    # NEXT, modify the curves
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [rel mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


