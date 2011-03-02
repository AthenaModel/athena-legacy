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
#    * The data inheritance is handled by defining a number of 
#      generic columns to hold type-specific parameters.
#
#    * The mutators work for all tactic types.
#
#    * Each tactic type has its own CREATE and UPDATE orders; the 
#      DELETE and PRIORITY orders are common to all.
#
#    * scenariodb(sim) defines a view for each tactic type,
#      tactics_<type>.
#
#    * The tactic type-specific code is in tactic_types.tcl.
#
#-----------------------------------------------------------------------

snit::type tactic {
    # Make it a singleton
    pragma -hasinstances no

    #===================================================================
    # Tactic Types: Definition and Query interface.

    #-------------------------------------------------------------------
    # Uncheckpointed Type variables

    # tinfo array: Type Info
    #
    # names - List of the names of the tactic types.

    typevariable tinfo -array {
        names {}
    }

    # type names
    #
    # Returns the tactic type names.
    
    typemethod {type names} {} {
        return [lsort $tinfo(names)]
    }

    # type define name defscript
    #
    # name       - The tactic name
    # defscript  - The definition script (a snit::type script)
    #
    # Defines tactic::$name as a type ensemble given the typemethods
    # defined in the defscript.  See tactic(i) for documentation of the
    # expected typemethods.

    typemethod {type define} {name defscript} {
        # FIRST, define the type.
        set header {
            # Make it a singleton
            pragma -hasinstances no
        }

        snit::type ${type}::${name} "$header\n$defscript"

        # NEXT, save the type name.
        ladd tinfo(names) $name
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
    # Retrieves a row dictionary, or a particular column value, from
    # tactics.

    typemethod get {id {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM tactics WHERE tactic_id=$id} row {
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
    # parmdict     A dictionary of tactic parms
    #
    #    tactic_type    The tactic type
    #    owner          The tactic's owning actor
    #    priority       "top" or "bottom" or ""; defaults to "bottom".
    #    m,n            Neighborhoods, or ""
    #    f,g            Groups, or ""
    #    text1          Text string, or ""
    #    int1           Integer, or ""
    #
    # Creates a tactic given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        # FIRST, compute the narrative string.
        set narrative [$type call narrative $parmdict]

        # NEXT, put the tactic in the database.
        dict with parmdict {
            # FIRST, Put the tactic in the database
            rdb eval {
                INSERT INTO cond_owners(co_type) VALUES('tactic');

                INSERT INTO 
                tactics(tactic_id, 
                        tactic_type, owner, narrative, priority, 
                        m,
                        n, 
                        f,
                        g,
                        text1,
                        int1)
                VALUES(last_insert_rowid(),
                       $tactic_type, $owner, $narrative, 0, 
                       nullif($m,     ''),
                       nullif($n,     ''),
                       nullif($f,     ''),
                       nullif($g,     ''),
                       nullif($text1, ''),
                       nullif($int1,  ''));
            }

            set id [rdb last_insert_rowid]

            lappend undo [list rdb delete tactics "tactic_id=$id"]

            # NEXT, set the priority.
            if {$priority eq ""} {
                set priority "bottom"
            }

            lappend undo [$type mutate priority $id $priority]

            # NEXT, Return undo command.
            return [join $undo \n]
        }
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
    #    m,n            Neighborhoods, or ""
    #    f,g            Groups, or ""
    #    text1          Text string, or ""
    #    int1           Integer, or ""
    #
    # Updates a tactic given the parms, which are presumed to be
    # valid.  Note that you can't change the tactic's actor or
    # type, and the priority is set by a different mutator.

    typemethod {mutate update} {parmdict} {
        # FIRST, save the changed data.
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab tactics {tactic_id=$tactic_id}]

            # NEXT, Update the tactic.  The nullif(nonempty()) pattern
            # is so that the old value of the column will be used
            # if the input is empty, and that empty columns will be
            # NULL rather than "".
            rdb eval {
                UPDATE tactics
                SET m     = nullif(nonempty($m,     m),     ''),
                    n     = nullif(nonempty($n,     n),     ''),
                    f     = nullif(nonempty($f,     f),     ''),
                    g     = nullif(nonempty($g,     g),     ''),
                    text1 = nullif(nonempty($text1, text1), ''),
                    int1  = nullif(nonempty($int1,  int1),  '')
                WHERE tactic_id=$tactic_id;
            } {}

            # NEXT, compute and set the narrative
            set tdict [$type get $tactic_id]

            set narrative [$type call narrative $tdict]

            rdb eval {
                UPDATE tactics
                SET   narrative=$narrative
                WHERE tactic_id=$tactic_id
            }

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
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
    # Re-prioritizes the items for the tactic's actor so that id has the
    # desired position.

    typemethod {mutate priority} {id priority} {
        # FIRST, get the tactic's actor
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

    #-------------------------------------------------------------------
    # Tactic Ensemble Interface

    # tactic call op tdict ?args...?
    #
    # op    - One of the above tactic type subcommands
    # tdict - A tactic parameter dictionary
    #
    # This is a convenience command that calls the relevant subcommand
    # for the tactic.

    typemethod call {op tdict args} {
        [dict get $tdict tactic_type] $op $tdict {*}$args
    }


    #-------------------------------------------------------------------
    # Order Helpers

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

    # RefreshUPDATE dlg fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the TACTIC:*:UPDATE dialog fields when field values
    # change, and disables the tactic_id field; they can't pick
    # new ones.

    typemethod RefreshUPDATE {dlg fields fdict} {
        orderdialog refreshForKey tactic_id * $dlg $fields $fdict

        # make tactic_id invalid
        $dlg disabled tactic_id
    }
}


#-----------------------------------------------------------------------
# Orders: TACTIC:*

# TACTIC:DELETE
#
# Deletes an existing tactic, of whatever type.

order define TACTIC:DELETE {
    title "Delete Tactic"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id   key  "Tactic ID" -table tactics -keys tactic_id
    parm owner       disp "Owner"
    parm tactic_type disp "Tactic Type"
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

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id   key  "Tactic ID"  -table tactics -keys tactic_id
    parm state       text "State"
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
    title "Prioritize Tactic Activity"

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id   key  "Tactic ID"  -table tactics -keys tactic_id
    parm owner       disp "Owner"
    parm tactic_type disp "Tactic Type"
    parm priority    enum "Priority" -type ePrioUpdate
} {
    # FIRST, prepare and validate the parameters
    prepare tactic_id -required          -type tactic
    prepare priority  -required -tolower -type ePrioUpdate

    returnOnError -final

    setundo [tactic mutate priority $parms(tactic_id) $parms(priority)]
}
