#-----------------------------------------------------------------------
# TITLE:
#    condition.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Condition Manager
#
#    A condition is a boolean expression attached to a tactic that
#    indicates whether or not the tactic should be used.  This module is
#    responsible for managing conditions and operations upon them.  As
#    such, it is a type ensemble.
#
#    There are a number of different condition types.
#
#    * All are stored in the conditions table.
#
#    * The data inheritance is handled by putting the type-specific
#      parameters in a Tcl dictionary in the "pdict" column.
#
#    * The mutators work for all condition types.
#
#    * Each condition type has its own CREATE and UPDATE orders; the
#      DELETE order is common to all.
#
#    * scenario.tcl defines a view for each condition type,
#      conditions_<type>.
#
#-----------------------------------------------------------------------

snit::type condition {
    # Make it a singleton
    pragma -hasinstances no

    #===================================================================
    # Lookup Tables

    # A list of the table columns in the conditions table, to avoid
    # name conflicts.
    typevariable tableColumns {
        condition_id
        condition_type
        cc_id
        owner
        narrative
        state
        flag
        pdict
    }

    #===================================================================
    # Condition Types: Definition and Query interface.

    #-------------------------------------------------------------------
    # Uncheckpointed Type variables

    # tinfo array: Type Info
    #
    # all           - List of the names of all condition types.
    # goal          - List of the names of goal conditions
    # tactic        - List of the names of tactic conditions
    # parms-$ctype  - List of the type-specific parms used by the condition
    #                 type

    typevariable tinfo -array {
        all    {}
        goal   {}
        tactic {}
    }

    # type names ?-all|-goal|-tactic?
    #
    # Returns the tactic type names.

    typemethod {type names} {{opt -all}} {
        switch -exact -- $opt {
            -all    { return [lsort $tinfo(all)]       }
            -goal   { return [lsort $tinfo(goal)]      }
            -tactic { return [lsort $tinfo(tactic)]    }
            default { error "Unknown option: \"$opt\"" }
        }
    }

    # type parms ctype
    #
    # Returns a list of the names of the type-specific parameters used by
    # the condition.

    typemethod {type parms} {ctype} {
        return $tinfo(parms-$ctype)
    }

    # type define name parms ?options...? defscript
    #
    # name       - The condition name
    # parms      - The type-specific parms defined by this condition
    # options... - Options; see below.
    # defscript  - The definition script (a snit::type script)
    #
    # Options:
    #
    #   -attachto  - goal|tactic|both.  Defaults to "both".  Determines
    #                the kind of things that instances of this type can
    #                be attached to.
    #
    # Defines condition::$name as a type ensemble given the typemethods
    # defined in the defscript.  See condition(i) for documentation of
    # the expected typemethods.

    typemethod {type define} {name parms args} {
        # FIRST, get the defscript.
        if {[llength $args] == 0} {
            error "wrong \# args, should be: $type type define parms ?options...? defscript"
        }

        set defscript [lindex $args end]
        set args [lrange $args 0 end-1]

        # NEXT, get the options
        array set opts {
            -attachto both
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -attachto {
                    set val [lshift args]

                    if {$val ni {goal tactic both}} {
                        error "Invalid $opt value: \"$val\""
                    }

                    set opts(-attachto) $val
                }

                default {
                    error "Invalid option: \"$opt\""
                }
            }
        }

        # NEXT, define the type.
        set header {
            # Make it a singleton
            pragma -hasinstances no

            typemethod check {cdict} { return }
        }

        snit::type ${type}::${name} "$header\n$defscript"

        # NEXT, make sure the parm names don't conflict with the
        # conditions table.
        foreach parm $parms {
            if {$parm in $tableColumns} {
                error "Parameter/table column conflict: \"$parm\""
            }
        }

        # NEXT, save the type name.
        ladd tinfo(all) $name

        if {$opts(-attachto) in {goal both}} {
            ladd tinfo(goal) $name
        }

        if {$opts(-attachto) in {tactic both}} {
            ladd tinfo(tactic) $name
        }

        set tinfo(parms-$name) $parms
    }

    # tempschema
    #
    # Returns the temporary view definitions for the currently defined
    # condition types.

    typemethod tempschema {} {
        set sql ""
        foreach ctype [condition type names] {
            set parms [list]
            foreach parm $tinfo(parms-$ctype) {
                lappend parms "dictget(pdict,'$parm') AS $parm"
            }

            if {[llength $parms] > 0} {
                set clause ",[join $parms ,]"
            } else {
                set clause ""
            }

            append sql "
                CREATE TEMP VIEW conditions_$ctype AS
                SELECT condition_id, condition_type, cc_id, narrative,
                       state, flag $clause
                FROM conditions WHERE condition_type='$ctype';
            "
        }

        return $sql
    }

    #===================================================================
    # Condition Instance Interface.

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of condition ids

    typemethod names {} {
        set names [rdb eval {
            SELECT condition_id FROM conditions ORDER BY condition_id
        }]
    }


    # validate id
    #
    # id - Possibly, a condition ID
    #
    # Validates a condition ID

    typemethod validate {id} {
        set ids [$type names]

        if {$id ni $ids} {
            return -code error -errorcode INVALID \
                "Invalid condition ID: \"$id\""
        }

        return $id
    }

    # get id ?parm?
    #
    # id   - A condition_id
    # parm - A conditions column name
    #
    # Retrieves an unpacked condition dictionary, or a particular
    # parameter value, from conditions.

    typemethod get {id {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM conditions WHERE condition_id=$id} row {
            # FIRST, pull in the pdict
            unset row(*)
            set cdict [unpackData [array get row]]

            if {$parm eq ""} {
                return $cdict
            } else {
                return [dict get $cdict $parm]
            }
        }
        return ""
    }

    #-------------------------------------------------------------------
    # Condition Ensemble Interface

    # condition call sub cdict ?args...?
    #
    # sub   - One of the above condition type subcommands
    # cdict - An unpacked condition parameter dictionary
    #
    # This is a convenience command that calls the relevant subcommand
    # for the condition.

    typemethod call {sub cdict args} {
        [dict get $cdict condition_type] $sub $cdict {*}$args
    }

    #-------------------------------------------------------------------
    # Condition Tools
    #
    # These commands are for use implementing conditions.

    # compare x comp y
    #
    # x          - A numeric value
    # comp       - An ecomparator
    # y          - A numeric value
    #
    # Compares x and y using the comparator, and returns 1 if the
    # comparison is true and 0 otherwise.

    typemethod compare {x comp y} {
        switch -exact -- $comp {
            EQ      { return [expr {$x == $y}] }
            GE      { return [expr {$x >= $y}] }
            GT      { return [expr {$x >  $y}] }
            LE      { return [expr {$x <= $y}] }
            LT      { return [expr {$x <  $y}] }
            default { error "Invalid comparator: \"$comp\"" }
        }
    }


    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate create parmdict
    #
    # parmdict     An unpacked dictionary of condition parms
    #
    #    condition_type - The condition type (econditiontype)
    #    cc_id          - The owning tactic or goal
    #
    #    type-specific parms
    #
    # Creates a condition given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        # FIRST, get the owning actor
        dict set parmdict owner [$type GetOwner [dict get $parmdict cc_id]]

        # NEXT, compute the narrative string.
        set narrative [condition call narrative $parmdict]

        # NEXT, pack the type-specific parms
        array set cdata [packData $parmdict]

        # NEXT, put the condition in the database.
        rdb eval {
            INSERT INTO
            conditions(condition_type, cc_id, owner, narrative, pdict)
            VALUES($cdata(condition_type),
                   $cdata(cc_id),
                   $cdata(owner),
                   $narrative,
                   $cdata(pdict));
        }

        set id [rdb last_insert_rowid]

        lappend undo [list rdb delete conditions "condition_id=$id"]

        # NEXT, Return undo command.
        return [join $undo \n]
    }

    # GetOwner cc_id
    #
    # cc_id   A condition collection ID, e.g., a tactic or goal
    #
    # Given a cc_id, return the actor that owns the tactic or goal.

    typemethod GetOwner {cc_id} {
        rdb eval {
            SELECT owner FROM goals WHERE goal_id=$cc_id
            UNION
            SELECT owner FROM tactics WHERE tactic_id=$cc_id
        } {
            return $owner
        }

        return ""
    }

    # mutate delete id
    #
    # id     a condition ID
    #
    # Deletes the condition.

    typemethod {mutate delete} {id} {
        # FIRST, get the undo information
        set data [rdb delete -grab conditions {condition_id=$id}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     An unpacked dictionary of condition parms
    #
    #    condition_id   The condition's ID
    #
    #    type-specific parms
    #
    # Updates a condition given the parms, which are presumed to be
    # valid.  Note that you can't change the condition's cc_id or
    # type.

    typemethod {mutate update} {parmdict} {
        # FIRST, get the undo information
        set condition_id [dict get $parmdict condition_id]
        set data [rdb grab conditions {condition_id=$condition_id}]

        # NEXT, get the previous condition data, and merge in the
        # changed values.
        set cdict [$type get $condition_id]

        dict for {parm value} $parmdict {
            if {$value ne ""} {
                dict set cdict $parm $value
            }
        }

        # NEXT, compute and set the narrative
        set narrative [condition call narrative $cdict]

        # NEXT, pack up the updated condition data.
        array set cdata [packData $cdict]

        # NEXT, Update the condition.
        rdb eval {
            UPDATE conditions
            SET flag      = NULL,
                pdict     = $cdata(pdict),
                narrative = $narrative
            WHERE condition_id=$condition_id;
        }

        # NEXT, Return the undo command
        return [list rdb ungrab $data]
    }

    # mutate state condition_id state
    #
    # condition_id - The condition's ID
    # state        - The condition's econdition_state
    #
    # Updates a condition's state.

    typemethod {mutate state} {condition_id state} {
        # FIRST, get the undo information
        set data [rdb grab conditions {condition_id=$condition_id}]

        # NEXT, Update the condition.
        rdb eval {
            UPDATE conditions
            SET state = $state
            WHERE condition_id=$condition_id;
        }

        # NEXT, Return the undo command
        return [list rdb ungrab $data]
    }

    # packData cdict
    #
    # cdict   - A dictionary of condition data
    #
    # Given a dictionary of condition data with the type-specific parms
    # broken out, returns a new condition dictionary with the
    # type-specific parms packed into pdict.

    proc packData {cdict} {
        dict set cdict pdict [dict create]

        foreach parm $tinfo(parms-[dict get $cdict condition_type]) {
            if {![dict exists $cdict $parm]} {
                dict set cdict $parm ""
            }
            dict set cdict pdict $parm [dict get $cdict $parm]
        }

        return $cdict
    }

    # unpackData cdict
    #
    # cdict   - A dictionary of condition data
    #
    # Given a dictionary of condition data with the type-specific parms
    # packed into pdict, extracts them out as entries in their own right.
    # Returns the new pdict.

    proc unpackData {cdict} {
        return [dict merge $cdict [dict get $cdict pdict]]
    }



    #-------------------------------------------------------------------
    # Order Helpers

    # RequireType condition_type id
    #
    # condition_type  - The desired condition_type
    # id           - A condition_id
    #
    # Throws an error if the condition doesn't have the desired type.

    typemethod RequireType {condition_type id} {
        if {[rdb onecolumn {
            SELECT condition_type FROM conditions WHERE condition_id = $id
        }] ne $condition_type} {
            return -code error -errorcode INVALID \
                "Condition $id is not a $condition_type condition"
        }
    }
}


#-----------------------------------------------------------------------
# Orders: CONDITION:*

# CONDITION:DELETE
#
# Deletes an existing condition, of whatever type.
#
# TBD: The form spec could be much simpler.

order define CONDITION:DELETE {
    title "Delete Condition"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        key condition_id -context yes -table conditions -keys condition_id \
            -loadcmd {orderdialog keyload condition_id *}

        rcc "Condition Type:" -for condition_type
        disp condition_type
    }
} {
    # FIRST, prepare the parameters
    prepare condition_id -toupper -required -type condition

    returnOnError -final

    # NEXT, Delete the condition and dependent entities
    setundo [condition mutate delete $parms(condition_id)]
}

# CONDITION:STATE
#
# Sets a condition's state.  Note that this order isn't intended
# for use with a dialog.
#
# TBD: The form spec could be much simpler.

order define CONDITION:STATE {
    title "Set Condition State"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        key condition_id -context yes -table conditions -keys condition_id \
            -loadcmd {orderdialog keyload condition_id *}

        rcc "State:" -for state
        text state
    }
} {
    # FIRST, prepare and validate the parameters
    prepare condition_id -required          -type condition
    prepare state        -required -tolower -type econdition_state

    returnOnError -final

    setundo [condition mutate state $parms(condition_id) $parms(state)]
}
