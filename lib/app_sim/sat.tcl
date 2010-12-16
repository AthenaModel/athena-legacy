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
#    curve inputs as CIV groups come and ago, and for allowing the analyst
#    to update particular satisfaction levels.  Curves are created and
#    deleted when civ groups are created and deleted.
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
            SELECT * 
            FROM sat_gc
            JOIN civgroups USING (g)
            WHERE atrend > 0.0 OR dtrend < 0.0
        } row {
            if {$row(atrend) > 0.0} {
                aram sat slope 0 0 $row(g) $row(c) $row(atrend) \
                    -cause   ATREND        \
                    -s       0.0           \
                    -athresh $row(athresh)
            }

            if {$row(dtrend) < 0.0} {
                aram sat slope 0 0 $row(g) $row(c) $row(dtrend) \
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
    # id     A curve ID, [list $g $c]
    #
    # Throws INVALID if there's no satisfaction level for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id g c

        set g [civgroup validate $g]
        set c [econcern validate $c]

        return [list $g $c]
    }

    # exists g c
    #
    # g       A group ID
    # c       A concern ID
    #
    # Returns 1 if there is such a satisfaction curve, and 0 otherwise.

    typemethod exists {g c} {
        rdb exists {
            SELECT * FROM sat_gc WHERE g=$g AND c=$c
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
    #
    # TBD: Since all civgroups have all concerns under the new 
    # model, I think this routine can be simplified.

    typemethod {mutate reconcile} {} {
        # FIRST, List required curves
        set valid [dict create]

        rdb eval {
            -- Civilian
            SELECT g,c FROM civgroups JOIN concerns
        } {
            dict set valid [list $g $c] 0
        }

        # NEXT, Begin the undo script.
        set undo [list]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM sat_gc
        } row {
            unset -nocomplain row(*)

            set id [list $row(g) $row(c)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod Restore [array get row]]

                rdb eval {
                    DELETE FROM sat_gc
                    WHERE g=$row(g) AND c=$row(c)
                }
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id g c

            rdb eval {
                INSERT INTO sat_gc(g,c)
                VALUES($g,$c)
            }

            lappend undo [mytypemethod Delete $g $c]
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
        rdb insert sat_gc $parmdict
    }

    # Delete g c
    #
    # g,c    The indices of the curve
    #
    # Deletes the curve.  Used only in undo scripts.
    
    typemethod Delete {g c} {
        rdb eval {
            DELETE FROM sat_gc WHERE g=$g AND c=$c
        }
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {g c}
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
            lassign $id g c

            # FIRST, get the undo information
            set data [rdb grab sat_gc {g=$g AND c=$c}]

            # NEXT, Update the group
            rdb eval {
                UPDATE sat_gc
                SET sat0     = nonempty($sat0,     sat0),
                    saliency = nonempty($saliency, saliency),
                    atrend   = nonempty($atrend,   atrend),
                    athresh  = nonempty($athresh,  athresh),
                    dtrend   = nonempty($dtrend,   dtrend),
                    dthresh  = nonempty($dthresh,  dthresh)
                WHERE g=$g AND c=$c
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
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

    parm id        key   "Curve"            -table  gui_sat_gc    \
                                            -key    {g c}         \
                                            -labels {"Grp" "Con"}
    parm sat0      sat   "Sat at T0"
    parm saliency  frac  "Saliency"
    parm atrend    text  "Ascending Trend"
    parm athresh   sat   "Asc. Threshold"
    parm dtrend    text  "Descending Trend"
    parm dthresh   sat   "Desc. Threshold"
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

    parm ids       multi  "Curves"           -table gui_sat_gc \
                                             -key id
    parm sat0      sat    "Sat at T0"
    parm saliency  frac   "Saliency"
    parm atrend    text   "Ascending Trend"
    parm athresh   sat    "Asc. Threshold"
    parm dtrend    text   "Descending Trend"
    parm dthresh   sat    "Desc. Threshold"
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


