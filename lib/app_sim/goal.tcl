#-----------------------------------------------------------------------
# TITLE:
#    goal.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Goal Manager
#
#    This module is responsible for managing goals and operations
#    upon them.  As such, it is a type ensemble.
#
#    A goal is an object owned by an actor that can be met or unmet.
#    Whether it is met or unmet is determined by the conditions
#    attached to it.  As such, it is a "cond_collection".
#
#-----------------------------------------------------------------------

snit::type goal {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of goal ids

    typemethod names {} {
        set names [rdb eval {
            SELECT goal_id FROM goals ORDER BY goal_id
        }]
    }


    # validate id
    #
    # id - Possibly, a goal ID
    #
    # Validates a goal ID

    typemethod validate {id} {
        set ids [$type names]

        if {$id ni $ids} {
            return -code error -errorcode INVALID \
                "Invalid goal ID: \"$id\""
        }

        return $id
    }

    # get id ?parm?
    #
    # id   - A goal_id
    # parm - A goals column name
    #
    # Retrieves a row dictionary, or a particular column value, from
    # goals.

    typemethod get {id {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM goals WHERE goal_id=$id} row {
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
    # parmdict     A dictionary of goal parms
    #
    #    owner          The goal's owning actor
    #    narrative      The narrative text.
    #
    # Creates a goal given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        # FIRST, put the goal in the database.
        dict with parmdict {
            # FIRST, Put the goal in the database
            rdb eval {
                INSERT INTO cond_collections(cc_type) VALUES('goal');

                INSERT INTO 
                goals(goal_id, 
                      owner, 
                      narrative)
                VALUES(last_insert_rowid(),
                       $owner, 
                       $narrative);
            }

            set id [rdb last_insert_rowid]

            lappend undo [list rdb delete goals "goal_id=$id"]

            # NEXT, Return undo command.
            return [join $undo \n]
        }
    }

    # mutate delete id
    #
    # id     a goal ID
    #
    # Deletes the goal.

    typemethod {mutate delete} {id} {
        # FIRST, get the undo information
        set data [rdb delete -grab goals {goal_id=$id}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of goal parms
    #
    #    goal_id        The goal's ID
    #    narrative      The new narrative
    #
    # Updates a goal given the parms, which are presumed to be
    # valid.  Note that you can't change the goal's actor.

    typemethod {mutate update} {parmdict} {
        # FIRST, save the changed data.
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab goals {goal_id=$goal_id}]

            # NEXT, Update the goal.
            rdb eval {
                UPDATE goals
                SET narrative = nonempty($narrative, narrative)
                WHERE goal_id=$goal_id;
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }

    # mutate state goal_id state
    #
    # goal_id - The goal's ID
    # state   - The goal's new egoal_state
    #
    # Updates a goal's state.

    typemethod {mutate state} {goal_id state} {
        # FIRST, get the undo information
        set data [rdb grab goals {goal_id=$goal_id}]

        # NEXT, Update the goal.
        rdb eval {
            UPDATE goals
            SET state = $state
            WHERE goal_id=$goal_id;
        }

        # NEXT, Return the undo command
        return [list rdb ungrab $data]
    }
}


#-----------------------------------------------------------------------
# Orders: GOAL:*

# GOAL:CREATE
#
# Creates a new goal.

order define GOAL:CREATE {
    title "Create Goal"

    options -sendstates {PREP PAUSED}

    parm owner     actor  "Owner"      -context yes
    parm narrative text   "Narrative"
} {
    # FIRST, prepare and validate the parameters
    prepare owner     -toupper   -required -type actor
    prepare narrative -normalize -required

    returnOnError -final

    # NEXT, create the goal
    setundo [goal mutate create [array get parms]]
}

# GOAL:DELETE
#
# Deletes an existing goal, of whatever type.

order define GOAL:DELETE {
    # TBD: This order dialog is not usually used.

    title "Delete Goal"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey goal_id *}

    parm goal_id goal "Goal ID"
    parm owner   disp "Owner"
} {
    # FIRST, prepare the parameters
    prepare goal_id -toupper -required -type goal

    returnOnError -final

    # NEXT, Delete the goal and dependent entities
    setundo [goal mutate delete $parms(goal_id)]
}

# GOAL:UPDATE
#
# Updates existing goal.

order define GOAL:UPDATE {
    title "Update Goal"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey goal_id *}

    parm goal_id   goal "Goal ID"    -context yes
    parm owner     disp "Owner"
    parm narrative text "Narrative"
} {
    # FIRST, prepare the parameters
    prepare goal_id              -required -type goal
    prepare narrative -normalize -required

    returnOnError -final

    # NEXT, modify the goal
    setundo [goal mutate update [array get parms]]
}

# GOAL:STATE
#
# Sets a goal's state.

order define GOAL:STATE {
    # This order dialog isn't usually used.

    title "Set Goal State"

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {orderdialog refreshForKey goal_id *}

    parm goal_id goal "Goal ID" -context yes
    parm state   text "State"
} {
    # FIRST, prepare and validate the parameters
    prepare goal_id  -required          -type goal
    prepare state    -required -tolower -type egoal_state

    returnOnError -final

    setundo [goal mutate state $parms(goal_id) $parms(state)]
}





