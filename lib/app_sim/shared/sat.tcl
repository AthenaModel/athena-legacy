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

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {g c}
    #    sat0             A new initial satisfaction, or ""
    #    saliency         A new saliency, or ""
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
                    saliency = nonempty($saliency, saliency)
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
                                            -keys   {g c}         \
                                            -labels {"Grp" "Con"}
    parm sat0      sat   "Sat at T0"
    parm saliency  frac  "Saliency"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type ::sat

    prepare sat0     -toupper -type qsat      -xform [list qsat value]
    prepare saliency -toupper -type qsaliency -xform [list qsaliency value]

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
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof sat

    prepare sat0     -toupper -type qsat      -xform [list qsat value]
    prepare saliency -toupper -type qsaliency -xform [list qsaliency value]

    returnOnError -final


    # NEXT, modify the curves
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [sat mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


