#-----------------------------------------------------------------------
# TITLE:
#    tactic.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Tactic Manager
#
#    This module is responsible for managing tactics and operations
#    upon them.  As such, it is a type ensemble.
#
#    There are a number of different tactic types.
#
#    * All are stored in the tactics table.
#
#    * The data inheritance is handled by putting the type-specific
#      parameters in a Tcl dictionary in the "pdict" column.
#
#    * The mutators work for all tactic types.
#
#    * Each tactic type has its own CREATE and UPDATE orders; the
#      DELETE and PRIORITY orders are common to all.
#
#    * scenariodb(sim) defines a view for each tactic type,
#      tactics_<type>.
#
#-----------------------------------------------------------------------

snit::type tactic {
    # Make it a singleton
    pragma -hasinstances no

    #===================================================================
    # Lookup Tables

    # A list of the table columns in the tactics table, to avoid
    # name conflicts.
    typevariable tableColumns {
        tactic_id
        tactic_type
        owner
        narrative
        priority
        once
        on_lock
        state
        exec_ts
        exec_flag
        pdict
    }

    #===================================================================
    # Tactic Types: Definition and Query interface.

    #-------------------------------------------------------------------
    # Uncheckpointed Type variables

    # tinfo array: Type Info
    #
    # names          - List of the names of the tactic types.
    # parms-$ttype   - List of the type-specific parms used by the tactic
    #                  type.
    # once-$ttype    - 1 if the tactic takes the "once" parameter.
    # on_lock-$ttype - 1 if the tactic takes the "on_lock" parameters.
    # atypes-$ttype  - Agent types that can use this tactic type.
    # ttypes-$atype  - Tactic types that can be used by this agent type

    typevariable tinfo -array {
        names {}
    }

    # type names
    #
    # Returns the tactic type names.

    typemethod {type names} {} {
        return [lsort $tinfo(names)]
    }

    # type names_by_agent agent
    #
    # agent   - An agent ID
    #
    # Returns the tactic type names that can be used by the given
    # agent.

    typemethod {type names_by_agent} {agent} {
        set atype [agent type $agent]

        if {[info exists tinfo(ttypes-$atype)]} {
            return [lsort $tinfo(ttypes-$atype)]
        } else {
            return [list]
        }
    }

    # type parms ttype
    #
    # ttype - A tactic type
    #
    # Returns a list of the names of the type-specific parameters used by
    # the tactic.

    typemethod {type parms} {ttype} {
        return $tinfo(parms-$ttype)
    }

    # type hasOnce ttype
    #
    # ttype - A tactic type
    #
    # Returns 1 if the tactic type takes the "once" parameter

    typemethod {type hasOnce} {ttype} {
        return $tinfo(once-$ttype)
    }

    # type hasOnLock ttype
    #
    # ttype - A tactic type
    #
    # Returns 1 if the tactic type takes the "on_lock" parameter

    typemethod {type hasOnLock} {ttype} {
        return $tinfo(on_lock-$ttype)
    }

    # type define name parms agent_types defscript
    #
    # name        - The tactic name
    # parms       - List of type-specific parameters, plus on_lock and once.
    # agent_types - List of agent types that can use this tactic_type.
    # defscript   - The definition script (a snit::type script)
    #
    # Defines tactic::$name as a type ensemble given the typemethods
    # defined in the defscript.  See tactic(i) for documentation of the
    # expected typemethods.

    typemethod {type define} {name parms agent_types defscript} {
        # FIRST, define the type.
        set header {
            # Make it a singleton
            pragma -hasinstances no

            typemethod check   {tdict} { return       }
            typemethod dollars {tdict} { return "n/a" }
        }

        snit::type ${type}::${name} "$header\n$defscript"

        # NEXT, save the type metadata
        ladd tinfo(names) $name

        if {"once" in $parms} {
            set tinfo(once-$name) 1
            ldelete parms once
        } else {
            set tinfo(once-$name) 0
        }

        if {"on_lock" in $parms} {
            set tinfo(on_lock-$name) 1
            ldelete parms on_lock
        } else {
            set tinfo(on_lock-$name) 0
        }

        set tinfo(parms-$name) $parms
        set tinfo(atypes-$name) $agent_types

        foreach atype $agent_types {
            lappend tinfo(ttypes-$atype) $name
        }

        # NEXT, make sure the parm names don't conflict with the
        # tactics table.
        foreach parm $parms {
            if {$parm in $tableColumns} {
                error "Parameter/table column conflict: \"$parm\""
            }
        }
    }

    # tempschema
    #
    # Returns the temporary view definitions for the currently
    # defined tactics.

    typemethod tempschema {} {
        set sql ""
        foreach ttype [tactic type names] {
            set opt ""
            if {[tactic type hasOnce $ttype]} {
                append opt "once, "
            }

            if {[tactic type hasOnLock $ttype]} {
                append opt "on_lock, "
            }

            set tparms ""

            foreach parm [tactic type parms $ttype] {
                append tparms "dictget(pdict,'$parm') AS $parm, "
            }

            append sql "
                CREATE TEMP VIEW tactics_$ttype AS
                SELECT tactic_id, tactic_type, owner, narrative, priority,
                       $tparms
                       $opt
                       state, exec_ts, exec_flag
                FROM tactics WHERE tactic_type='$ttype';
            "
        }

        return $sql
    }


    #===================================================================
    # Scenario Control

    # reset
    #
    # Resets all tactics execution flags back to 0.

    typemethod reset {} {
        rdb eval {
            UPDATE tactics SET exec_flag = 0
        }
    }

    # rebase
    #
    # Create a new scenario prep baseline based on the current simulation
    # state.
    
    typemethod rebase {} {
        # FIRST, set on_lock flag if the tactic was executed at the 
        # last tick.
        foreach {tactic_id tactic_type exec_flag} [rdb eval {
            SELECT tactic_id, tactic_type, exec_flag
            FROM tactics
        }] {
            if {![tactic type hasOnLock $tactic_type]} {
                continue
            }

            rdb eval {
                UPDATE tactics
                SET on_lock = $exec_flag
                WHERE tactic_id = $tactic_id;
            }
        }

        # NEXT, reset the other tactic data.
        rdb eval {
            UPDATE tactics
            SET exec_flag = 0, 
                exec_ts = NULL;
        }
    }
 

    #===================================================================
    # Tactic Instance: Modification and Query Interace

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of tactic ids

    typemethod names {} {
        set names [rdb eval {
            SELECT tactic_id FROM tactics ORDER BY tactic_id
        }]
    }


    # validate id
    #
    # id - Possibly, a tactic ID
    #
    # Validates a tactic ID

    typemethod validate {id} {
        set ids [$type names]

        if {$id ni $ids} {
            return -code error -errorcode INVALID \
                "Invalid tactic ID: \"$id\""
        }

        return $id
    }

    # get id ?parm?
    #
    # id   - A tactic_id
    # parm - A tactics column name
    #
    # Retrieves an unpacked tactic dictionary, or a particular
    # parameter value, from tactics.

    typemethod get {id {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM tactics WHERE tactic_id=$id} row {
            # FIRST, pull in the pdict
            unset row(*)
            set tdict [unpackData [array get row]]

            if {$parm eq ""} {
                return $tdict
            } else {
                return [dict get $tdict $parm]
            }
        }

        return ""
    }

    # delta varname
    #
    # varname  - An array of tactic order parameters
    #
    # Fills in empty parameters from the RDB.  This routine is
    # intended to be used in :UPDATE orders to retrieve the entire
    # set of data for cross-checks.

    typemethod delta {varname} {
        upvar 1 $varname parms

        set tdict [$type get $parms(tactic_id)]
        set ttype [dict get $tdict tactic_type]

        foreach parm $tinfo(parms-$ttype) {
            if {![info exists parms($parm)] || $parms($parm) eq ""} {
                set parms($parm) [dict get $tdict $parm]
            }
        }

        # Retrieve the owner
        set parms(owner) [dict get $tdict owner]
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
    # parmdict     A dictionary of tactic parms
    #
    #    tactic_type    The tactic type
    #    owner          The tactic's owning agent
    #    priority       "top" or "bottom" or ""; defaults to "bottom".
    #    once           1 or 0 or ""; defaults to 0.
    #    on_lock        1 or 0, defaults to 0.
    #
    #    type-specific parms
    #
    # Creates a tactic given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        # FIRST, get the pdata into an array.
        set tdata(on_lock) 0
        set tdata(once) 0
        array set tdata $parmdict

        # NEXT, ensure that this agent can own this tactic.
        set validTypes [$type type names_by_agent $tdata(owner)]

        require {$tdata(tactic_type) in $validTypes} \
            "Agent $tdata(owner) cannot own $tdata(tactic_type) tactics"

        # NEXT, compute the narrative string.
        set narrative [$type call narrative $parmdict]

        # NEXT, pack the type-specific parms
        array set tdata [packData [array get tdata]]

        # NEXT, put the tactic in the database.
        rdb eval {
            INSERT INTO cond_collections(cc_type) VALUES('tactic');

            INSERT INTO
            tactics(tactic_id, tactic_type,
                    owner, narrative, priority, once, on_lock, pdict)
            VALUES(last_insert_rowid(),
                   $tdata(tactic_type),
                   $tdata(owner),
                   $narrative,
                   0,
                   $tdata(once),
                   $tdata(on_lock),
                   $tdata(pdict));
        }

        set id [rdb last_insert_rowid]

        lappend undo [list rdb delete tactics "tactic_id=$id"]

        # NEXT, set the priority.
        if {$tdata(priority) eq ""} {
            set tdata(priority) "bottom"
        }

        lappend undo [$type mutate priority $id $tdata(priority)]

        # NEXT, Return undo command.
        return [join $undo \n]
    }


    # mutate delete id
    #
    # id     a tactic ID
    #
    # Deletes the tactic.  Note that deleting a tactic leaves a
    # gap in the priority order, but doesn't change the order of
    # the remaining tactics; hence, we don't need to worry about it.

    typemethod {mutate delete} {id} {
        # FIRST, get the undo information
        set data [rdb delete -grab tactics {tactic_id=$id}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of tactic parms
    #
    #    tactic_id      The tactic's ID
    #    once           Once flag, 1 or 0, or ""
    #    on_lock        On lock flag, 1 or 0
    #
    #    type-specific parameters
    #
    # Updates a tactic given the parms, which are presumed to be
    # valid.  Note that you can't change the tactic's agent or
    # type, and the priority is set by a different mutator.

    typemethod {mutate update} {parmdict} {
        # FIRST, get the undo information
        set tactic_id [dict get $parmdict tactic_id]
        set data [rdb grab tactics {tactic_id=$tactic_id}]

        # NEXT, get the unpacked type data
        array set tdata [$type get $tactic_id]

        # NEXT, add in the new parameter values.
        foreach {parm value} $parmdict {
            if {$value ne ""} {
                set tdata($parm) $value
            }
        }

        # NEXT, re-pack the data into pdict
        array set tdata [packData [array get tdata]]

        # NEXT, Update the tactic.  Note that tdata contains all the
        # values, so we'll update all of them.
        #
        # Note: set exec_flag = 0 and exec_ts = NULL: this is effectively
        # a new tactic, and may bear little resemblance to what it was
        # before.  Setting exec_ts to NULL allows the tactic's 
        # [execute] method to know that this version of the tactic
        # hasn't executed before.
        set tdata(narrative) [$type call narrative [array get tdata]]

        rdb eval {
            UPDATE tactics
            SET narrative = $tdata(narrative),
                once      = $tdata(once),
                on_lock   = $tdata(on_lock),
                pdict     = $tdata(pdict),
                exec_flag = 0,
                exec_ts   = NULL
            WHERE tactic_id=$tactic_id;
        } {}

        # NEXT, Return the undo command
        return [list rdb ungrab $data]
    }

    # mutate state tactic_id state
    #
    # tactic_id - The tactic's ID
    # state     - The tactic's new etactic_state
    #
    # Updates a tactic's state.

    typemethod {mutate state} {tactic_id state} {
        # FIRST, get the undo information
        set data [rdb grab tactics {tactic_id=$tactic_id}]

        # NEXT, Update the tactic.
        rdb eval {
            UPDATE tactics
            SET state = $state
            WHERE tactic_id=$tactic_id;
        }

        # NEXT, Return the undo command
        return [list rdb ungrab $data]
    }

    # mutate priority id priority
    #
    # id        The tactic ID whose priority is changing.
    # priority  An ePrioUpdate value
    #
    # Re-prioritizes the items for the tactic's agent so that id has the
    # desired position.

    typemethod {mutate priority} {id priority} {
        # FIRST, get the tactic's agent
        set owner [rdb onecolumn {
            SELECT owner FROM tactics WHERE tactic_id=$id
        }]

        # NEXT, get the existing priority ranking
        set oldRanking [rdb eval {
            SELECT tactic_id,priority FROM tactics
            WHERE owner=$owner
            ORDER BY priority
        }]

        # NEXT, Reposition id in the ranking.
        set ranking [lprio [dict keys $oldRanking] $id $priority]

        # NEXT, assign new priority numbers
        set prio 1

        foreach id $ranking {
            rdb eval {
                UPDATE tactics
                SET   priority=$prio
                WHERE tactic_id=$id
            }
            incr prio
        }

        # NEXT, return the undo script
        return [mytypemethod RestorePriority $oldRanking]
    }

    # RestorePriority ranking
    #
    # ranking  The ranking to restore
    #
    # Restores an old ranking

   typemethod RestorePriority {ranking} {
       # FIRST, restore the data
        foreach {id prio} $ranking {
            rdb eval {
                UPDATE tactics
                SET priority=$prio
                WHERE tactic_id=$id
            }
        }
    }

    # packData tdict
    #
    # tdict   - A dictionary of tactic data
    #
    # Given a dictionary of tactic data with the type-specific parms
    # broken out, returns a new tactic dictionary with the
    # type-specific parms packed into pdict.

    proc packData {tdict} {
        dict set $tdict pdict [dict create]

        foreach parm $tinfo(parms-[dict get $tdict tactic_type]) {
            if (![dict exists $tdict $parm]) {
                dict set tdict $parm ""
            }
            dict set tdict pdict $parm [dict get $tdict $parm]
        }

        return $tdict
    }

    # unpackData tdict
    #
    # tdict   - A dictionary of tactic data
    #
    # Given a dictionary of tactic data with the type-specific parms
    # packed into pdict, extracts them out as entries in their own right.
    # Returns the new tdict.

    proc unpackData {tdict} {
        set tdict [dict merge $tdict [dict get $tdict pdict]]
    }


    #-------------------------------------------------------------------
    # Tactic Ensemble Interface

    # call op tdict ?args...?
    #
    # op    - One of the above tactic type subcommands
    # tdict - An unpacked tactic parameter dictionary
    #
    # This is a convenience command that calls the relevant subcommand
    # for the tactic.

    typemethod call {op tdict args} {
        [dict get $tdict tactic_type] $op $tdict {*}$args
    }

    # execute tdict
    #
    # tdict - A tactic parameter dictionary
    #
    # Attempts to execute the tactic, returning 1 on success and 0
    # on failure.  On success, the tactic's exec_flag and exec_ts are
    # set.  Errors are logged.

    typemethod execute {tdict} {
        set flag 0

        bgcatch {
            set flag [tactic call execute $tdict]
        }

        if {$flag} {
            set tid  [dict get $tdict tactic_id]
            set once [dict get $tdict once]

            rdb eval {
                UPDATE tactics
                SET exec_flag = 1,
                    exec_ts   = now()
                WHERE tactic_id = $tid
            }

            if {$once} {
                rdb eval {
                    UPDATE tactics
                    SET state = 'disabled'
                    WHERE tactic_id = $tid
                }
            }
        }

        return $flag
    }


    #-------------------------------------------------------------------
    # Order Helpers: Private

    # RequireType tactic_type id
    #
    # tactic_type  - The desired tactic_type
    # id           - A tactic_id
    #
    # Throws an error if the tactic doesn't have the desired type.

    typemethod RequireType {tactic_type id} {
        if {[rdb onecolumn {
            SELECT tactic_type FROM tactics WHERE tactic_id = $id
        }] ne $tactic_type} {
            return -code error -errorcode INVALID \
                "Tactic $id is not a $tactic_type tactic"
        }
    }

}


#-----------------------------------------------------------------------
# Orders: TACTIC:*

# TACTIC:DELETE
#
# Deletes an existing tactic, of whatever type.

order define TACTIC:DELETE {
    # This order dialog isn't usually used.

    title "Delete Tactic"
    options -sendstates {PREP PAUSED}

    form {
        key tactic_id -table tactics -keys tactic_id
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id -toupper -required -type tactic

    returnOnError -final

    # NEXT, Delete the tactic and dependent entities
    setundo [tactic mutate delete $parms(tactic_id)]
}

# TACTIC:STATE
#
# Sets a tactic's state.  Note that this order isn't intended
# for use with a dialog.

order define TACTIC:STATE {
    title "Set Tactic State"

    options -sendstates {PREP PAUSED}

    form {
        key tactic_id -table tactics -keys tactic_id
        text state
    }
} {
    # FIRST, prepare and validate the parameters
    prepare tactic_id -required          -type tactic
    prepare state     -required -tolower -type etactic_state

    returnOnError -final

    setundo [tactic mutate state $parms(tactic_id) $parms(state)]
}

# TACTIC:PRIORITY
#
# Re-prioritizes a tactic item.

order define TACTIC:PRIORITY {
    # This order dialog isn't usually used.
    title "Prioritize Tactic Activity"

    options -sendstates {PREP PAUSED}

    form {
        key tactic_id -table tactics -keys tactic_id
        enum priority -listcmd {ePrioUpdate names}
    }
} {
    # FIRST, prepare and validate the parameters
    prepare tactic_id -required          -type tactic
    prepare priority  -required -tolower -type ePrioUpdate

    returnOnError -final

    setundo [tactic mutate priority $parms(tactic_id) $parms(priority)]
}
