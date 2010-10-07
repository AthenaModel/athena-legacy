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
    # Simulation

    # start
    #
    # Starts the ascending and descending trends for cooperation curves.

    typemethod start {} {
        log normal coop "start"

        rdb eval {
            SELECT * FROM coop_nfg
            WHERE atrend > 0.0 OR dtrend < 0.0
        } row {
            if {$row(atrend) > 0.0} {
                aram coop slope 0 0 $row(n) $row(f) $row(g) $row(atrend) \
                    -cause   ATREND        \
                    -s       0.0           \
                    -athresh $row(athresh)
            }

            if {$row(dtrend) < 0.0} {
                aram coop slope 0 0 $row(n) $row(f) $row(g) $row(dtrend) \
                    -cause   DTREND        \
                    -s       0.0           \
                    -dthresh $row(dthresh)
            }
        }
        
        log normal coop "start complete"
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
    #    id               list {n f g}
    #    coop0            Cooperation of f with g in n at time 0.
    #    atrend           A new ascending trend, or ""
    #    athresh          A new ascending threshold, or ""
    #    dtrend           A new descending trend, or ""
    #    dthresh          A new descending threshold, or ""
    #
    # Updates a cooperation given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n f g

            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM coop_nfg
                WHERE n=$n AND f=$f AND g=$g
            } undoData {
                unset undoData(*)
                set undoData(id) $id
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE coop_nfg
                SET coop0    = nonempty($coop0,   coop0),
                    atrend   = nonempty($atrend,  atrend),
                    athresh  = nonempty($athresh, athresh),
                    dtrend   = nonempty($dtrend,  dtrend),
                    dthresh  = nonempty($dthresh, dthresh)
                WHERE n=$n AND f=$f AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::coop <Entity> update $id

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}


#-------------------------------------------------------------------
# Orders: COOP:*

# COOP:UPDATE
#
# Updates existing cooperations

order define ::coop COOP:UPDATE {
    title "Update Initial Cooperation"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey id *}

    parm id      key   "Curve"           -table  gui_coop_nfg     \
                                         -key    {n f g}          \
                                         -labels {"" "Of" "With"}
    parm coop0   text  "Cooperation"
    parm atrend  text  "Ascending Trend"
    parm athresh text  "Asc. Threshold"
    parm dtrend  text  "Descending Trend"
    parm dthresh text  "Desc. Threshold"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type coop
    prepare coop0    -toupper            -type qcooperation \
        -xform [list qcooperation value]
    prepare atrend   -toupper            -type ratrend
    prepare athresh  -toupper            -type qcooperation \
        -xform [list qcooperation value]
    prepare dtrend   -toupper            -type rdtrend
    prepare dthresh  -toupper            -type qcooperation \
        -xform [list qcooperation value]

    returnOnError -final

    # NEXT, modify the curve
    setundo [$type mutate update [array get parms]]
}


# COOP:UPDATE:MULTI
#
# Updates multiple existing cooperations

order define ::coop COOP:UPDATE:MULTI {
    title "Update Initial Cooperation (Multi)"
    options \
        -sendstates PREP                                  \
        -refreshcmd {orderdialog refreshForMulti ids *}
 
    parm ids     multi  "IDs"              -table gui_coop_nfg \
                                           -key id
    parm coop0   text   "Cooperation"
    parm atrend  text   "Ascending Trend"
    parm athresh text   "Asc. Threshold"
    parm dtrend  text   "Descending Trend"
    parm dthresh text   "Desc. Threshold"
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof coop

    prepare coop0    -toupper            -type qcooperation \
        -xform [list qcooperation value]
    prepare atrend   -toupper            -type ratrend
    prepare athresh  -toupper            -type qcooperation \
        -xform [list qcooperation value]
    prepare dtrend   -toupper            -type rdtrend
    prepare dthresh  -toupper            -type qcooperation \
        -xform [list qcooperation value]

    returnOnError -final


    # NEXT, modify the curves
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


