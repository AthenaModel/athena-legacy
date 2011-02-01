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
#    * The data inheritance is handled by defining a number of 
#      generic columns to hold type-specific parameters.
#
#    * The mutators work for all condition types.
#
#    * Each condition type has its own CREATE and UPDATE orders; the 
#      DELETE order is common to all.
#
#    * gui_views.sql defines a view for each condition type,
#      conditions_<type>.
#
#    The actual condition types are defined in condition_types.tcl.
#
#-----------------------------------------------------------------------

snit::type condition {
    # Make it a singleton
    pragma -hasinstances no

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
    # Retrieves a row dictionary, or a particular column value, from
    # conditions.

    typemethod get {id {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM conditions WHERE condition_id=$id} row {
            if {$parm eq ""} {
                unset row(*)
                return [array get row]
            } else {
                return $row($parm)
            }
        }

        return ""
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
    # parmdict     A dictionary of condition parms
    #
    #    condition_type - The condition type (econditiontype)
    #    tactic_id      - The owning tactic
    #    text1          - Text string, or ""
    #    x1             - Real number, or ""
    #
    # Creates a condition given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        # FIRST, build the ddict
        set condition_type [dict get $parmdict condition_type]

        # NEXT, compute the narrative string.
        set narrative [condition call narrative $parmdict]

        # NEXT, put the condition in the database.
        dict with parmdict {
            # FIRST, Put the condition in the database
            rdb eval {
                INSERT INTO 
                conditions(condition_type, tactic_id, narrative,
                           text1,
                           x1)
                VALUES($condition_type, $tactic_id, $narrative, 
                       nullif($text1,  ''),
                       nullif($x1,     ''));
            }

            set id [rdb last_insert_rowid]

            lappend undo [list rdb delete conditions "condition_id=$id"]

            # NEXT, Return undo command.
            return [join $undo \n]
        }
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
    # parmdict     A dictionary of condition parms
    #
    #    condition_id   The condition's ID
    #    text1          Text string, or ""
    #    x1             Real number, or ""
    #
    # Updates a condition given the parms, which are presumed to be
    # valid.  Note that you can't change the condition's tactic_id or
    # type.

    typemethod {mutate update} {parmdict} {
        # FIRST, save the changed data.
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab conditions {condition_id=$condition_id}]

            # NEXT, Update the condition.  The nullif(nonempty()) pattern
            # is so that the old value of the column will be used
            # if the input is empty, and that empty columns will be
            # NULL rather than "".
            rdb eval {
                UPDATE conditions
                SET text1 = nullif(nonempty($text1, text1),  ''),
                    x1    = nullif(nonempty($x1,    x1),     '')
                WHERE condition_id=$condition_id;
            } {}

            # NEXT, compute and set the narrative
            set cdict [$type get $condition_id]

            set narrative \
                [condition call narrative $cdict]

            rdb eval {
                UPDATE conditions
                SET   narrative=$narrative
                WHERE condition_id=$condition_id
            }

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
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

    #-------------------------------------------------------------------
    # Condition Ensemble Interface

    # condition call op cdict ?args...?
    #
    # op    - One of the above condition type subcommands
    # cdict - A condition parameter dictionary
    #
    # This is a convenience command that calls the relevant subcommand
    # for the condition.

    typemethod call {op cdict args} {
        [dict get $cdict condition_type] $op $cdict {*}$args
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

order define CONDITION:DELETE {
    title "Delete Condition"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id   key  "Condition ID"   -table conditions   \
                                              -key   condition_id
    parm condition_type disp "Condition Type"
    parm tactic_id      disp "Tactic ID"
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

order define CONDITION:STATE {
    title "Set Condition State"

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id   key  "Condition ID"  -table conditions   \
                                             -key   condition_id
    parm state          text "State"
} {
    # FIRST, prepare and validate the parameters
    prepare condition_id -required          -type condition
    prepare state        -required -tolower -type econdition_state

    returnOnError -final

    setundo [condition mutate state $parms(condition_id) $parms(state)]
}
