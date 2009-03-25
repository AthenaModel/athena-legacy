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
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # TBD

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail sat "Initialized"
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
    # id     A curve ID, [list $n $g $c]
    #
    # Throws INVALID if there's no satisfaction level for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id n g c

        set n [nbhood    validate $n]
        set g [sat group validate $g]
        set c [econcern  validate $c]


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

    # group validate g
    #
    # g    A group name
    #
    # Throws INVALID if g is not the name of a group for which 
    # satisfaction can be tracked.

    typemethod {group validate} {g} {
        set groups [$type group names]

        if {[llength $groups] == 0} {
            return -code error -errorcode INVALID \
                "Invalid satisfaction group, none are defined"
        } elseif {$g ni $groups} {
            return -code error -errorcode INVALID \
                "Invalid satisfaction group, should be one of: [join $groups {, }]"
        }

        return $g
    }

    # group names
    #
    # Returns a list of the names of the satisfaction groups.

    typemethod {group names} {} {
        return [rdb eval {
            SELECT g FROM groups
            WHERE gtype IN ('CIV', 'ORG')
        }]

        return $g
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
            WHERE concerns.gtype = 'CIV'

            UNION

            -- Organization
            SELECT n,g,c FROM nbhoods JOIN orggroups JOIN concerns
            WHERE concerns.gtype = 'ORG'

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
    #    n                Neighborhood ID
    #    g                Group ID
    #    c                Concern
    #    sat0             A new initial satisfaction, or ""
    #    trend0           A new long-term trend, or ""
    #    saliency         A new saliency, or ""
    #
    # Updates a satisfaction level the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM sat_ngc
                WHERE n=$n AND g=$g AND c=$c
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE sat_ngc
                SET sat0     = nonempty($sat0,     sat0),
                    trend0   = nonempty($trend0,   trend0),
                    saliency = nonempty($saliency, saliency)
                WHERE n=$n AND g=$g AND c=$c
            } {}

            # NEXT, notify the app.
            notifier send ::sat <Entity> update [list $n $g $c]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}

#-------------------------------------------------------------------
# Orders: SATISFACTION:*

# SATISFACTION:UPDATE
#
# Updates existing curves

order define ::sat SATISFACTION:UPDATE {
    title "Update Satisfaction Curve"
    options -sendstates PREP -table gui_sat_ngc -tags ngc

    parm n         key   "Neighborhood"  -tags nbhood
    parm g         key   "Group"         -tags group
    parm c         key   "Concern"       -tags concern
    parm sat0      text  "Sat at T0"
    parm trend0    text  "Trend"
    parm saliency  text  "Saliency"
} {
    # FIRST, prepare the parameters
    prepare n        -toupper  -required -type nbhood
    prepare g        -toupper  -required -type [list sat group]
    prepare c        -toupper  -required -type econcern

    prepare sat0     -toupper \
        -type qsat      -xform [list qsat value]
    prepare trend0   -toupper \
        -type qtrend    -xform [list qtrend value]
    prepare saliency -toupper \
        -type qsaliency -xform [list qsaliency value]

    returnOnError

    # NEXT, do cross-validation
    validate c {
        sat validate [list $parms(n) $parms(g) $parms(c)]
    }

    returnOnError

    # NEXT, modify the curve
    setundo [$type mutate update [array get parms]]
}


# SATISFACTION:UPDATE:MULTI
#
# Updates multiple existing curves

order define ::sat SATISFACTION:UPDATE:MULTI {
    title "Update Multiple Satisfaction Curves"
    options -sendstates PREP -table gui_sat_ngc

    parm ids       multi  "Curves"
    parm sat0      text   "Sat at T0"
    parm trend0    text   "Trend"
    parm saliency  text   "Saliency"
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof sat

    prepare sat0     -toupper -type qsat      -xform [list qsat value]
    prepare trend0   -toupper -type qtrend    -xform [list qtrend value]
    prepare saliency -toupper -type qsaliency -xform [list qsaliency value]

    returnOnError


    # NEXT, modify the curves
    set undo [list]

    foreach id $parms(ids) {
        lassign $id parms(n) parms(g) parms(c)

        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


