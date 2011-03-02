#-----------------------------------------------------------------------
# TITLE:
#    personnel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): FRC/ORG Group Personnel Manager
#
#    This module is responsible for managing personnel of FRC and ORG
#    groups in neighborhoods.
#
# CREATION/DELETION:
#    personnel_ng records are created explicitly by the 
#    nbhood(sim), frcgroup(sim), and orggroup(sim) modules, and
#    deleted by cascading delete.
#
#-----------------------------------------------------------------------

snit::type personnel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id      A group ID, [list $n $g]
    #
    # Validates an n,g pair.

    typemethod validate {id} {
        lassign $id n g

        set n [nbhood validate $n]
        set g [group  validate $g]

        if {[group gtype $g] ni {FRC ORG}} { 
            return -code error -errorcode INVALID \
                "Group $g is neither a FRC nor an ORG group."
        }

        return [list $n $g]
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate set parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {n g}
    #    personnel        A new personnel, or ""
    #
    # Updates a personnel record given the parms, which are presumed to be
    # valid.

    typemethod {mutate set} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n g

            # FIRST, get the undo information
            set data [rdb grab personnel_ng {n=$n AND g=$g}]

            # NEXT, Update the group
            rdb eval {
                UPDATE personnel_ng
                SET personnel = nonempty($personnel, personnel)
                WHERE n=$n AND g=$g
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }

    # mutate adjust parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {n g}
    #    delta            A delta to personnel
    #
    # Updates a personnel record given the parms, which are presumed to be
    # valid.

    typemethod {mutate adjust} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n g

            # FIRST, get the undo information
            rdb eval {
                SELECT personnel FROM personnel_ng
                WHERE n=$n AND g=$g
            } {}

            let newPersonnel {max(0, $personnel + $delta)}
            let undoDelta    {$personnel - $newPersonnel}

            # NEXT, Update the group
            rdb eval {
                UPDATE personnel_ng
                SET personnel = $newPersonnel
                WHERE n=$n AND g=$g
            } {}

            # NEXT, Return the undo command
            return [mytypemethod mutate adjust \
                        [list id $id delta $undoDelta]]
        }
    }

}

#-------------------------------------------------------------------
# Orders: PERSONNEL:*

# PERSONNEL:SET
#
# Sets the total personnel for a group in a neighborhood.

order define PERSONNEL:SET {
    title "Set Group Personnel"
    options \
        -sendstates     {PREP PAUSED}     \
        -schedulestates {PREP PAUSED}     \
        -narrativecmd   {apply {{name pdict} {
            dict with pdict {
                lassign $id n g
                return "Assign $personnel $g personnel, total, to nbhood $n"
            }
        }}}


    parm id             key  "Nbhood/Group"  -table gui_personnel_ng \
                                             -keys {n g}
    parm personnel      text "Personnel"
} {
    # FIRST, prepare the parameters
    prepare id             -toupper  -required -type personnel
    prepare personnel                -required -type iquantity

    returnOnError -final

    # NEXT, modify the group
    lappend undo [personnel mutate set [array get parms]]

    setundo [join $undo \n]
    return
}

# PERSONNEL:ADJUST
#
# Sets the total personnel for a group in a neighborhood.

order define PERSONNEL:ADJUST {
    title "Adjust Group Personnel"
    options \
        -sendstates     {PREP PAUSED}     \
        -schedulestates {PREP PAUSED}     \
        -narrativecmd   {apply {{name pdict} {
            dict with pdict {
                lassign $id n g
                if {$delta >= 0} {
                    return "Add $delta $g personnel to nbhood $n"
                } else {
                    return "Remove [expr {-$delta}] $g personnel from nbhood $n"
                }
            }
        }}}


    parm id             key  "Nbhood/Group"    -table gui_personnel_ng \
                                               -keys  {n g}
    parm delta          text "Delta Personnel"
} {
    # FIRST, prepare the parameters
    prepare id             -toupper  -required -type personnel
    prepare delta                    -required -type snit::integer

    returnOnError -final

    # NEXT, modify the group
    lappend undo [personnel mutate adjust [array get parms]]

    setundo [join $undo \n]
    return
}




