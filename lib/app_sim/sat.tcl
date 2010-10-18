#-----------------------------------------------------------------------
# TITLE:
#    sat.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Satisfaction Curve Inputs Manager
#
#    This module is responsible for managing the scenario's satisfaction
#    curve inputs as groups come and ago, and for allowing the analyst
#    to update particular satisfaction levels.
#
#    Civilian Satisfaction curves are created and deleted when nbgroups 
#    are created and deleted.
#
#    Organization Satisfaction curves are created and deleted:
#
#    * For each neighborhood when an org group is created/deleted.
#    * For each org group when a neighborhood is created/deleted.
#
#-----------------------------------------------------------------------

snit::type sat {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Simulation

    # start
    #
    # Starts the ascending and descending trends for satisfaction curves.

    typemethod start {} {
        log normal sat "start"

        rdb eval {
            SELECT * FROM sat_ngc
            WHERE atrend > 0.0 OR dtrend < 0.0
        } row {
            if {$row(atrend) > 0.0} {
                aram sat slope 0 0 $row(n) $row(g) $row(c) $row(atrend) \
                    -cause   ATREND        \
                    -s       0.0           \
                    -athresh $row(athresh)
            }

            if {$row(dtrend) < 0.0} {
                aram sat slope 0 0 $row(n) $row(g) $row(c) $row(dtrend) \
                    -cause   DTREND        \
                    -s       0.0           \
                    -dthresh $row(dthresh)
            }
        }
        
        log normal sat "start complete"
    }



    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     A curve ID, [list $n $g $c]
    #
    # Throws INVALID if there's no satisfaction level for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id n g c

        set n [nbhood   validate $n]
        set g [civgroup validate $g]
        set c [econcern validate $c]


        if {![$type exists $n $g $c]} {
            return -code error -errorcode INVALID \
                "Satisfaction is not tracked for group $g's $c in $n."
        }

        return [list $n $g $c]
    }

    # exists n g c
    #
    # n       A neighborhood ID
    # g       A group ID
    # c       A concern ID
    #
    # Returns 1 if there is such a satisfaction curve, and 0 otherwise.

    typemethod exists {n g c} {
        rdb exists {
            SELECT * FROM sat_ngc WHERE n=$n AND g=$g AND c=$c
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
    # Determines which satisfaction curves should exist, and 
    # adds or deletes them, returning an undo script.

    typemethod {mutate reconcile} {} {
        # FIRST, List required curves
        set valid [dict create]

        rdb eval {
            -- Civilian
            SELECT n,g,c FROM nbgroups JOIN concerns
        } {
            dict set valid [list $n $g $c] 0
        }

        # NEXT, Begin the undo script.
        set undo [list]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM sat_ngc
        } row {
            unset -nocomplain row(*)

            set id [list $row(n) $row(g) $row(c)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod Restore [array get row]]

                rdb eval {
                    DELETE FROM sat_ngc
                    WHERE n=$row(n) AND g=$row(g) AND c=$row(c)
                }

                notifier send ::sat <Entity> delete $id
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id n g c

            rdb eval {
                INSERT INTO sat_ngc(n,g,c)
                VALUES($n,$g,$c)
            }

            lappend undo [mytypemethod Delete $n $g $c]

            notifier send ::sat <Entity> create $id
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
        rdb insert sat_ngc $parmdict
        dict with parmdict {
            notifier send ::sat <Entity> create [list $n $g $c]
        }
    }

    # Delete n g c
    #
    # n,g,c    The indices of the curve
    #
    # Deletes the curve.  Used only in undo scripts.
    
    typemethod Delete {n g c} {
        rdb eval {
            DELETE FROM sat_ngc WHERE n=$n AND g=$g AND c=$c
        }

        notifier send ::sat <Entity> delete [list $n $g $c]
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {n g c}
    #    sat0             A new initial satisfaction, or ""
    #    saliency         A new saliency, or ""
    #    atrend           A new ascending trend, or ""
    #    athresh          A new ascending threshold, or ""
    #    dtrend           A new descending trend, or ""
    #    dthresh          A new descending threshold, or ""
    #
    # Updates a satisfaction level the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n g c

            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM sat_ngc
                WHERE n=$n AND g=$g AND c=$c
            } undoData {
                unset undoData(*)
                set undoData(id) $id
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE sat_ngc
                SET sat0     = nonempty($sat0,     sat0),
                    saliency = nonempty($saliency, saliency),
                    atrend   = nonempty($atrend,   atrend),
                    athresh  = nonempty($athresh,  athresh),
                    dtrend   = nonempty($dtrend,   dtrend),
                    dthresh  = nonempty($dthresh,  dthresh)
                WHERE n=$n AND g=$g AND c=$c
            } {}

            # NEXT, notify the app.
            notifier send ::sat <Entity> update $id

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

}

#-------------------------------------------------------------------
# Orders: SAT:*

# SAT:UPDATE
#
# Updates existing curves

order define SAT:UPDATE {
    title "Update Initial Satisfaction"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey id *}

    parm id        key   "Curve"            -table  gui_sat_ngc \
                                            -key    {n g c}     \
                                            -labels {"" "Grp" "Con"}
    parm sat0      text  "Sat at T0"
    parm saliency  text  "Saliency"
    parm atrend    text  "Ascending Trend"
    parm athresh   text  "Asc. Threshold"
    parm dtrend    text  "Descending Trend"
    parm dthresh   text  "Desc. Threshold"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type ::sat

    prepare sat0     -toupper -type qsat      -xform [list qsat value]
    prepare saliency -toupper -type qsaliency -xform [list qsaliency value]
    prepare atrend   -toupper -type ratrend
    prepare athresh  -toupper -type qsat      -xform [list qsat value]
    prepare dtrend   -toupper -type rdtrend
    prepare dthresh  -toupper -type qsat      -xform [list qsat value]

    returnOnError -final

    # NEXT, modify the curve
    setundo [sat mutate update [array get parms]]
}


# SAT:UPDATE:MULTI
#
# Updates multiple existing curves

order define SAT:UPDATE:MULTI {
    title "Update Initial Satisfaction (Multi)"
    options \
        -sendstates PREP                                  \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids       multi  "Curves"           -table gui_sat_ngc \
                                             -key id
    parm sat0      text   "Sat at T0"
    parm saliency  text   "Saliency"
    parm atrend    text   "Ascending Trend"
    parm athresh   text   "Asc. Threshold"
    parm dtrend    text   "Descending Trend"
    parm dthresh   text   "Desc. Threshold"
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof sat

    prepare sat0     -toupper -type qsat      -xform [list qsat value]
    prepare saliency -toupper -type qsaliency -xform [list qsaliency value]
    prepare atrend   -toupper -type ratrend
    prepare athresh  -toupper -type qsat      -xform [list qsat value]
    prepare dtrend   -toupper -type rdtrend
    prepare dthresh  -toupper -type qsat      -xform [list qsat value]

    returnOnError -final


    # NEXT, modify the curves
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [sat mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


