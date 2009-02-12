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
#    groups as groups come and ago, and for allowing the analyst
#    to update particular relationships.
#
#    Every frc and org group has a bidirectional relationship with 
#    every other frc and org group; these are stored in the rel_fg
#    table.
#
#    Every frc and org group has a bidirectional relationship with
#    every neighborhood group; these are stored in the rel_nfg table.
#
#    Every civ group has a relationship with every other civ group
#    in every neighborhood.
#   
#
#-----------------------------------------------------------------------

snit::type rel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # TBD

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail rel "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module's in-memory data from the database.
    
    typemethod reconfigure {} {
        # Nothing to do
    }

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An nfg relationship ID, [list $n $f $g]
    #
    # Throws INVALID if there's no relationship for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id n f g

        set n [rel nbhood validate $n]
        set f [group validate $f]
        set g [group validate $g]

        if {![$type exists $n $f $g]} {
            return -code error -errorcode INVALID \
               "Relationship is not tracked for $f with $g in $n."
        }

        return [list $n $f $g]
    }

    # exists n f g
    #
    # n       A nbhood ID, or PLAYBOX
    # f       A group ID
    # g       A group ID
    #
    # Returns 1 if relationship is tracked between f and g in n.

    typemethod exists {n f g} {
        rdb exists {
            SELECT * FROM rel_nfg WHERE n=$n AND f=$f AND g=$g
        }
    }

    # nbhood validate n
    #
    # n     A possible neighborhood name, or "PLAYBOX"
    #
    # Validates and returns n.

    typemethod {nbhood validate} {n} {
        set nbhoods [concat PLAYBOX [nbhood names]]

        if {$n ni $nbhoods} {
            return -code error -errorcode INVALID \
                "Invalid neighborhood, should be one of: [join $nbhoods {, }]"
        }

        return $n
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

    typemethod {mutate reconcile} {} {
        # FIRST, List required relationships
        set valid [dict create]

        rdb eval {
            -- Force/Org vs. Force/Org
            SELECT 'PLAYBOX' AS n, 
                   F.g       AS f, 
                   G.g       AS g
            FROM groups AS F
            JOIN groups AS G
            WHERE F.gtype IN ('FRC', 'ORG')
            AND   G.gtype IN ('FRC', 'ORG')

            UNION

            -- Nbgroup with all other groups
            SELECT nbgroups.n AS n, 
                   groups.g   AS f, 
                   nbgroups.g AS g
            FROM nbgroups JOIN groups
        } {
            # Some of these will be set more often than is necessary,
            # but that's OK.
            dict set valid [list $n $f $g] 0
            dict set valid [list $n $g $f] 0
        }

        # NEXT, Begin the undo script.
        set undo [list]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM rel_nfg
        } row {
            unset -nocomplain row(*)

            set id [list $row(n) $row(f) $row(g)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod Restore [array get row]]

                rdb eval {
                    DELETE FROM rel_nfg
                    WHERE n=$row(n) AND f=$row(f) AND g=$row(g)
                }

                notifier send ::rel <Entity> delete $id
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id n f g

            if {$f eq $g} {
                # Every group has a relationship of 1.0 with itself.
                rdb eval {
                    INSERT INTO rel_nfg(n,f,g,rel)
                    VALUES($n,$f,$g,1.0)
                }

            } else {
                # Otherwise, we get the default relationship.
                rdb eval {
                    INSERT INTO rel_nfg(n,f,g)
                    VALUES($n,$f,$g)
                }
            }

            lappend undo [mytypemethod Delete $n $f $g]

            notifier send ::rel <Entity> create $id
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
        rdb insert rel_nfg $parmdict
        dict with parmdict {
            notifier send ::rel <Entity> create [list $n $f $g]
        }
    }


    # Delete n f g
    #
    # n,f,g    The indices of the entity
    #
    # Deletes the entity.  Used only in undo scripts.
    
    typemethod Delete {n f g} {
        rdb eval {
            DELETE FROM rel_nfg WHERE n=$n AND f=$f AND g=$g
        }

        notifier send ::rel <Entity> delete [list $n $f $g]
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID
    #    f                Group ID
    #    g                Group ID
    #    rel              Relationship of f with g in n.
    #
    # Updates a relationship given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM rel_nfg
                WHERE n=$n AND f=$f AND g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE rel_nfg
                SET rel = nonempty($rel, rel)
                WHERE n=$n AND f=$f AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::rel <Entity> update [list $n $f $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}


#-------------------------------------------------------------------
# Orders: RELATIONSHIP:*

# RELATIONSHIP:UPDATE
#
# Updates existing relationships

order define ::rel RELATIONSHIP:UPDATE {
} {
    # FIRST, prepare the parameters
    prepare n        -toupper  -required -type [list ::rel nbhood]
    prepare f        -toupper  -required -type group
    prepare g        -toupper  -required -type group
    prepare rel      -toupper            -type rgrouprel

    returnOnError

    # NEXT, do cross-validation
    validate g {
        rel validate [list $parms(n) $parms(f) $parms(g)]
    }

    returnOnError

    # NEXT, modify the curve
    setundo [$type mutate update [array get parms]]
}


# RELATIONSHIP:UPDATE:MULTI
#
# Updates multiple existing relationships

order define ::rel RELATIONSHIP:UPDATE:MULTI {
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof rel

    prepare rel      -toupper            -type rgrouprel

    returnOnError


    # NEXT, modify the curves
    set undo [list]

    foreach id $parms(ids) {
        lassign $id parms(n) parms(f) parms(g)

        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}

