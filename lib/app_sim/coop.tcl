#-----------------------------------------------------------------------
# TITLE:
#    coop.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Cooperation Manager
#
#    This module is responsible for managing cooperations between
#    groups as groups come and ago, and for allowing the analyst
#    to update particular cooperations.
#
#    Every frc and org group has a bidirectional cooperation with 
#    every other frc and org group; these are stored in the coop_fg
#    table.
#
#    Every frc and org group has a bidirectional cooperation with
#    every neighborhood group; these are stored in the coop_nfg table.
#
#    Every civ group has a cooperation with every other civ group
#    in every neighborhood.
#   
#
#-----------------------------------------------------------------------

snit::type coop {
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
        log detail coop "Initialized"
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
    # id     An nfg cooperation ID, [list $n $f $g]
    #
    # Throws INVALID if there's no cooperation for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id n f g

        set n [nbhood validate $n]
        set f [civgroup validate $f]
        set g [frcgroup validate $g]

        if {![$type exists $n $f $g]} {
            return -code error -errorcode INVALID \
               "Cooperation is not tracked for $f with $g in $n."
        }

        return [list $n $f $g]
    }

    # exists n f g
    #
    # n       A nbhood ID, or PLAYBOX
    # f       A group ID
    # g       A group ID
    #
    # Returns 1 if cooperation is tracked between f and g in n.

    typemethod exists {n f g} {
        rdb exists {
            SELECT * FROM coop_nfg WHERE n=$n AND f=$f AND g=$g
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
    # Determines which cooperations should exist, and 
    # adds or deletes them, returning an undo script.

    typemethod {mutate reconcile} {} {
        # FIRST, List required cooperations
        set valid [dict create]

        rdb eval {
            -- Nbgroup with force groups
            SELECT nbgroups.n  AS n, 
                   nbgroups.g  AS f,
                   frcgroups.g AS g
            FROM nbgroups JOIN frcgroups
        } {
            dict set valid [list $n $f $g] 0
        }

        # NEXT, Begin the undo script.
        set undo [list]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM coop_nfg
        } row {
            unset -nocomplain row(*)

            set id [list $row(n) $row(f) $row(g)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod Restore [array get row]]

                rdb eval {
                    DELETE FROM coop_nfg
                    WHERE n=$row(n) AND f=$row(f) AND g=$row(g)
                }

                notifier send ::coop <Entity> delete $id
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id n f g

            rdb eval {
                INSERT INTO coop_nfg(n,f,g)
                VALUES($n,$f,$g)
            }

            lappend undo [mytypemethod Delete $n $f $g]

            notifier send ::coop <Entity> create $id
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
        rdb insert coop_nfg $parmdict
        dict with parmdict {
            notifier send ::coop <Entity> create [list $n $f $g]
        }
    }


    # Delete n f g
    #
    # n,f,g    The indices of the entity
    #
    # Deletes the entity.  Used only in undo scripts.
    
    typemethod Delete {n f g} {
        rdb eval {
            DELETE FROM coop_nfg WHERE n=$n AND f=$f AND g=$g
        }

        notifier send ::coop <Entity> delete [list $n $f $g]
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID
    #    f                Group ID
    #    g                Group ID
    #    coop0            Cooperation of f with g in n at time 0.
    #
    # Updates a cooperation given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM coop_nfg
                WHERE n=$n AND f=$f AND g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE coop_nfg
                SET coop0 = nonempty($coop0, coop0)
                WHERE n=$n AND f=$f AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::coop <Entity> update [list $n $f $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}


#-------------------------------------------------------------------
# Orders: COOPERATION:*

# COOPERATION:UPDATE
#
# Updates existing cooperations

order define ::coop COOPERATION:UPDATE {
} {
    # FIRST, prepare the parameters
    prepare n        -toupper  -required -type nbhood
    prepare f        -toupper  -required -type civgroup
    prepare g        -toupper  -required -type frcgroup
    prepare coop0    -toupper            -type qcooperation

    returnOnError

    # NEXT, do cross-validation
    validate g {
        coop validate [list $parms(n) $parms(f) $parms(g)]
    }

    returnOnError

    # NEXT, modify the curve
    setundo [$type mutate update [array get parms]]
}


# COOPERATION:UPDATE:MULTI
#
# Updates multiple existing cooperations

order define ::coop COOPERATION:UPDATE:MULTI {
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof coop

    prepare coop0    -toupper            -type qcooperation

    returnOnError


    # NEXT, modify the curves
    set undo [list]

    foreach id $parms(ids) {
        lassign $id parms(n) parms(f) parms(g)

        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}

