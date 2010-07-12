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

    # mutate reconcile
    #
    # Deletes records for which either the neighborhood or the
    # group no longer exists, and adds records that should exist but
    # don't.

    typemethod {mutate reconcile} {} {
        # FIRST, get the set of possible personnel records
        set valid [dict create]

        rdb eval {
            SELECT n, g 
            FROM nbhoods 
            JOIN groups
            WHERE gtype IN ('FRC','ORG')
        } {
            dict set valid [list $n $g] 0
        }

        # NEXT, delete the ones that are no longer valid, accumulating
        # an undo script.
        set undo [list]

        rdb eval {
            SELECT n,g FROM personnel_ng
        } {
            # If it's unknown, create it; and if it is know, remove it.
            if {![dict exists $valid [list $n $g]]} {
                lappend undo [$type mutate delete $n $g]
            } else {
                set valid [dict remove $valid [list $n $g]]
            }
        }

        # NEXT, create ones that are needed.
        foreach ng [dict keys $valid] {
            lappend undo [$type mutate create {*}$ng]
        }

        return [join $undo \n]
    }

    # mutate create n g
    #
    # n   The neighborhood ID
    # g   The group ID
    #
    # Creates a record

    typemethod {mutate create} {n g} {
        # FIRST, Put the group in the database
        rdb eval {
            INSERT INTO personnel_ng(n,g)
            VALUES($n,$g)
        }

        # NEXT, notify the app.
        notifier send ::personnel <Entity> create [list $n $g]

        # NEXT, Return the undo command
        set undo [list]
        lappend undo [mytypemethod mutate delete $n $g]

        return [join $undo \n]
    }

    # mutate delete n g
    #
    # n g     A personnel_ng ID
    #
    # Deletes the record, including all references.

    typemethod {mutate delete} {n g} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM personnel_ng WHERE n=$n AND g=$g} row {
            unset row(*)
        }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM personnel_ng WHERE n=$n AND g=$g;
        }

        # NEXT, notify the app.
        notifier send ::personnel <Entity> delete [list $n $g]

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row]]
    }

    # Restore parmdict
    #
    # parmdict     row dict for deleted entity
    #
    # Restores the entity in the database

    typemethod Restore {parmdict} {
        rdb insert personnel_ng $parmdict

        dict with parmdict {
            notifier send ::personnel <Entity> create [list $n $g]
        }
    }

    # mutate set parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID
    #    g                Group ID
    #    personnel        A new personnel, or ""
    #
    # Updates a personnel record given the parms, which are presumed to be
    # valid.

    typemethod {mutate set} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM personnel_ng
                WHERE n=$n AND g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE personnel_ng
                SET personnel = nonempty($personnel, personnel)
                WHERE n=$n AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::personnel <Entity> update [list $n $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate set [array get undoData]]
        }
    }

    # mutate adjust parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID
    #    g                Group ID
    #    delta            A delta to personnel
    #
    # Updates a personnel record given the parms, which are presumed to be
    # valid.

    typemethod {mutate adjust} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
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

            # NEXT, notify the app.
            notifier send ::personnel <Entity> update [list $n $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate adjust \
                        [list n $n g $g delta $undoDelta]]
        }
    }

}

#-------------------------------------------------------------------
# Orders: PERSONNEL:*

# PERSONNEL:SET
#
# Sets the total personnel for a group in a neighborhood.

order define ::personnel PERSONNEL:SET {
    title "Set Group Personnel"
    options \
        -sendstates     {PREP PAUSED}     \
        -schedulestates {PREP PAUSED}     \
        -table          gui_personnel_ng  \
        -tags           ng                \
        -narrativecmd   {apply {{name pdict} {
            dict with pdict {
                return "Assign $personnel $g personnel, total, to nbhood $n"
            }
        }}}


    parm n              key  "Neighborhood"  -tags nbhood
    parm g              key  "Group"         -tags group
    parm personnel      text "Personnel"
} {
    # FIRST, prepare the parameters
    prepare n              -toupper  -required -type nbhood
    prepare g              -toupper  -required -type group
    prepare personnel                -required -type iquantity

    returnOnError

    # NEXT, do cross-validation
    validate g {
        $type validate [list $parms(n) $parms(g)]
    }

    returnOnError -final

    # NEXT, modify the group
    lappend undo [$type mutate set [array get parms]]

    setundo [join $undo \n]
    return
}

# PERSONNEL:ADJUST
#
# Sets the total personnel for a group in a neighborhood.

order define ::personnel PERSONNEL:ADJUST {
    title "Adjust Group Personnel"
    options \
        -sendstates     {PREP PAUSED}     \
        -schedulestates {PREP PAUSED}     \
        -table          gui_personnel_ng  \
        -tags           ng                \
        -narrativecmd   {apply {{name pdict} {
            dict with pdict {
                if {$delta >= 0} {
                    return "Add $delta $g personnel to nbhood $n"
                } else {
                    return "Remove [expr {-$delta}] $g personnel from nbhood $n"
                }
            }
        }}}


    parm n              key  "Neighborhood"     -tags nbhood
    parm g              key  "Group"            -tags group
    parm delta          text "Delta Personnel"
} {
    # FIRST, prepare the parameters
    prepare n              -toupper  -required -type nbhood
    prepare g              -toupper  -required -type group
    prepare delta                    -required -type snit::integer

    returnOnError

    # NEXT, do cross-validation
    validate g {
        $type validate [list $parms(n) $parms(g)]
    }

    returnOnError -final

    # NEXT, modify the group
    lappend undo [$type mutate adjust [array get parms]]

    setundo [join $undo \n]
    return
}




