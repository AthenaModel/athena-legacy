#-----------------------------------------------------------------------
# TITLE:
#    strategy.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Strategy Execution Engine
#
#    An agent's strategy is his collection of goals and tactics and their
#    attached conditions.  This module is responsible for sanity-checking
#    agent strategies, and for executing the agent's strategy at each 
#    strategy execution tock (nominally seven days).
#
#-----------------------------------------------------------------------

snit::type strategy {
    # Make it a singleton
    pragma -hasinstances no

    # locking: this flag indicates whether strategy is being executed on
    # lock. This flag is used by tactics to determine whether money
    # should be spent.

    typevariable locking 0

    #-------------------------------------------------------------------
    # Strategy Execution Tock
    #
    # These routines are called during the strategy execution tock
    # to select and execute tactics.

    # start
    #
    # This method is called when the simulation is locked and going to
    # the paused state

    typemethod start {} {
        set locking 1

        $type DoTock $locking
        
        set locking 0
    }

    # tock
    #
    # This method is called when the simulation is running forward in
    # time

    typemethod tock {} {
        $type DoTock 0
    }

    # locking
    #
    # This method returns the locking flag. This is called by types
    # that need to know if strategy execution is occurring on scenario
    # lock

    typemethod locking {} {
        return $locking
    }

    # DoTock locking
    #
    # onlock  - a flag indicating whether the sim is locking or not
    #
    # Executes agent tactics:
    #
    # * Determines whether conditions for executing tactics are met. If
    #   conditions are met, then an attempt is made to execute it. A
    #   tactic may not execute if there are not enough resources for it.
    #
    # * Some tactics are defined to execute on lock. If so, then that is
    #   the only condition that must be met when Athena is locked and 
    #   those tactics are attempted to execute.

    typemethod DoTock {onlock} {
        # FIRST, Set up working tables.  This includes giving
        # the actors their incomes, unless we are locking, in which
        # case no cash moves
        profile 1 control load
        profile 1 cash load
        profile 1 personnel load
        profile 1 service load
        profile 1 cap access load
        profile 1 tactic reset
        profile 1 tactic::ATTROE reset
        profile 1 tactic::BROADCAST reset
        profile 1 tactic::DEFROE reset
        profile 1 tactic::FLOW reset
        profile 1 tactic::STANCE reset
        profile 1 unit reset

        # NEXT, determine whether the goals are met or unmet.
        profile 1 $type ComputeGoalFlags

        # NEXT, examine each agent's tactic in priority order.  If the
        # tactic is eligible, attempt to execute it. If it is a tactic
        # meant to execute on lock and we are locking, attempt to 
        # execute it.
        foreach {tactic_id on_lock} [rdb eval {
            SELECT tactic_id, on_lock
            FROM tactics
            WHERE state = 'normal'
            ORDER BY owner, priority
        }] {
            if {$onlock} {
                if {$on_lock} {
                    log normal strategy \
                        "Tactic $tactic_id IS eligible on lock"
                    profile 1 $type ExecuteTactic $tactic_id
                }
            } else {
                if {[$type IsEligible $tactic_id]} {
                    log normal strategy "Tactic $tactic_id IS eligible"
                    profile 1 $type ExecuteTactic $tactic_id
                } else {
                    log normal strategy "Tactic $tactic_id IS NOT eligible"
                }
            }
        }

        # NEXT, save working data. If we are on lock, no cash has been used
        # so we don't want to save it
        profile 1 control save
        if {!$onlock} {
            profile 1 cash save
        }
        profile 1 personnel save
        profile 1 tactic::FLOW save
        profile 1 service save
        profile 1 cap access save

        # NEXT, determine the actual stance of each group based on the
        # effects of the STANCE and ATTROE tactics.
        profile 1 tactic::STANCE assess

        # NEXT, populate base units for all groups.
        profile 1 unit makebase

        # NEXT, assess all requested IOM broadcasts
        profile 1 tactic::BROADCAST assess
    }


    # ComputeGoalFlags
    #
    # Computes for each goal whether the goal is met or unmet.

    typemethod ComputeGoalFlags {} {
        log normal strategy ComputeGoalFlags

        # FIRST, empty all goal and condition flags.  This will
        # clear tactic condition flags as well, but that's OK.
        rdb eval {
            UPDATE goals      SET flag='';
            UPDATE conditions SET flag='';
        }

        # NEXT, load the goals and goal conditions.
        # Ignore goals whose state is not normal.
        rdb eval {
            SELECT goals.goal_id AS goal_id,
                   conditions.*
            FROM goals
            LEFT OUTER JOIN conditions ON (cc_id = goal_id)
            WHERE goals.state = 'normal'
        } row {
            if {![info exists gconds($row(goal_id))]} {
                set gconds($row(goal_id)) [list]
            }

            if {$row(condition_id) ne ""} {
                lappend gconds($row(goal_id)) $row(condition_id)
            }
        }

        # NEXT, compute the goal flags for all goals; and the
        # condition flags along the way.
        foreach gid [array names gconds] {
            log normal strategy "Goal $gid:"

            # FIRST, compute the condition flags, accumulating the 
            # goal flag
            set gflag 1

            foreach cid $gconds($gid) {
                set cdict [condition get $cid]
                set cstate [dict get $cdict state]

                # FIRST, if compute the flag if the condition's
                # state is normal; otherwise, ignore the condition
                # (which means pretending that it's true).
                if {$cstate eq "normal"} {
                    set flag [condition call eval $cdict]
                    set gflag [expr {$gflag && $flag}]
                } else {
                    set flag ""
                }

                log normal strategy "==> Condition $cid is met: <$flag>"

                # NEXT, save the condition's flag; make it NULL
                # if the value is unknown
                rdb eval {
                    UPDATE conditions
                    SET flag = nullif($flag,"")
                    WHERE condition_id = $cid
                }
            }

            # NEXT, save the goal's flag.
            log normal strategy "!!! Goal $gid is met: <$gflag>"
            
            rdb eval {
                UPDATE goals
                SET flag = $gflag
                WHERE goal_id = $gid
            }
        }
    }

    # IsEligible tid
    #
    # tid     - A tactic_id
    #
    # Computes whether or not the tactic is eligible, i.e.,
    # whether or not all of its conditions are met.
    # Returns 1 if so and 0 otherwise; it also sets the
    # condition flags for the tactic's conditions.

    typemethod IsEligible {tid} {
        # FIRST, evaluate the conditions belonging to this
        # tactic.
        set tflag 1
        set cflags [list]
        set badlist [list]

        rdb eval {
            SELECT condition_id
            FROM conditions
            WHERE cc_id = $tid
            AND   state = 'normal'
        } {
            set cdict [condition get $condition_id]
            set flag [condition call eval $cdict]

            # If an attached condition has no value, the tactic shouldn't
            # execute.  At the same time, we don't want to flag such a
            # condition as false in the GUI.
            if {$flag eq ""} {
                set flag 0
            } else {
                lappend cflags $condition_id $flag
            }

            if {!$flag} {
                set tflag 0
            }
        }

        # NEXT, save the condition flags.
        foreach {cid cflag} $cflags {
            rdb eval {
                UPDATE conditions
                SET flag=$cflag
                WHERE condition_id = $cid
            }
        }

        # NEXT, return the tactic's eligibility flag.
        return $tflag
    }

    # ExecuteTactic tid
    #
    # tid   - A tactic ID
    #
    # Attempts to execute an eligible tactic, as constrained by 
    # available resources.  Tactics for which resources
    # are unavailable do nothing.

    typemethod ExecuteTactic {tid} {
        set tdict [tactic get $tid]

        if {[tactic execute $tdict]} {
            log normal strategy \
                "Actor [dict get $tdict owner] executed <$tdict>"
        }
    }

    #-------------------------------------------------------------------
    # Strategy Sanity Check

    # checker ?ht?
    #
    # ht - An htools buffer
    #
    # Computes the sanity check, and formats the results into the buffer
    # for inclusion into an HTML page.  Returns an esanity value, either
    # OK or WARNING.

    typemethod checker {{ht ""}} {
        set flag [$type DoSanityCheck cerror terror]

        if {$flag} {
            return OK
        }

        if {$ht ne ""} {
            $type DoSanityReport $ht cerror terror
        }

        return WARNING
    }

    # DoSanityCheck cerrorVar terrorVar
    #
    # cerrorVar - An array to receive condition error strings by condition ID
    # terrorVar - An array to receive tactic error strings by tactic ID
    #
    # This routine does the actual sanity check, marking the condition
    # and tactic records in the RDB and putting error messages in the
    # cerrorVar and terrorVar variables, which are presumed to be empty.
    #
    # Returns 1 if the check succeeds, and 0 if errors are found.

    typemethod DoSanityCheck {cerrorVar terrorVar} {
        upvar 1 $cerrorVar cerror
        upvar 1 $terrorVar terror

        # FIRST, clear the invalid states, since we're going to 
        # recompute them.

        rdb eval {
            UPDATE conditions 
            SET state = 'normal'
            WHERE state = 'invalid';

            UPDATE tactics
            SET state = 'normal'
            WHERE state = 'invalid';
        }

        # NEXT, find invalid conditions
        set badConditions [list]

        rdb eval {
            SELECT condition_id
            FROM conditions
            JOIN cond_collections USING (cc_id)
            WHERE state != 'disabled'
        } {
            # FIRST, Check and skip valid conditions
            set cdict [condition get $condition_id]
            set result [condition call check $cdict]

            if {$result ne ""} {
                set cerror($condition_id) $result
                lappend badConditions $condition_id
            }
        }

        # FIRST, NEXT invalid tactics.
        set badTactics [list]

        rdb eval {
            SELECT tactic_id FROM tactics
        } {
            set tdict [tactic get $tactic_id]
            set result [tactic call check $tdict]

            if {$result ne ""} {
                set terror($tactic_id) $result
                lappend badTactics $tactic_id
            }
        }

        # NEXT, mark the bad conditions and tactics invalid.
        foreach condition_id $badConditions {
            rdb eval {
                UPDATE conditions
                SET state = 'invalid'
                WHERE condition_id = $condition_id;
            }
        }

        foreach tactic_id $badTactics {
            rdb eval {
                UPDATE tactics
                SET state = 'invalid'
                WHERE tactic_id = $tactic_id;
            }
        }

        # NEXT, notify the application that a check has been done.
        notifier send ::strategy <Check>

        # NEXT, if there's nothing wrong, we're done.
        if {[llength $badConditions] == 0 &&
            [llength $badTactics] == 0
        } {
            return 1
        }

        return 0
    }


    # DoSanityReport ht cerrorVar terrorVar
    #
    # ht        - An htools buffer to receive a report.
    # cerrorVar - An array of condition error strings by condition ID
    # terrorVar - An array of tactic error strings by tactic ID
    #
    # Writes HTML text of the results of the sanity check to the ht
    # buffer.

    typemethod DoSanityReport {ht cerrorVar terrorVar} {
        upvar 1 $cerrorVar cerror
        upvar 1 $terrorVar terror

        # Goals with condition errors
        $ht push
        $ht subtitle "Goals with Condition Errors"

        $ht putln {
            The following goals have invalid conditions attached.  The
            conditions have failed their sanity checks and have
            been marked invalid in the
        }
        
        $ht link gui:/tab/strategy "Strategy Browser"

        $ht put ". Please fix them or delete them."
        $ht para
             
        # Get the errant conditions by agent and goal.
        
        # Dictionary: agent->goal->condition
        set adict [dict create]

        rdb eval {
            SELECT goals.goal_id   AS goal_id, 
                   goals.narrative AS goal_narrative,
                   goals.owner     AS owner,
                   conditions.*
            FROM goals
            JOIN conditions ON (cc_id = goal_id)
            WHERE conditions.state = 'invalid'
            ORDER BY owner, goal_id, condition_id
        } row {
            dict set adict $row(owner) $row(goal_id) $row(condition_id) 1
            set gdata($row(goal_id)) $row(goal_narrative)
            set cdata($row(condition_id)) [array get row]
        }

        dict for {a gdict} $adict {
            $ht putln "<b>Agent: $a</b>"
            $ht ul

            dict for {gid cdict} $gdict {
                $ht li
                $ht put "$gdata($gid)"
                $ht tiny " (goal id=$gid) "
                $ht ul

                dict for {cid dummy} $cdict {
                    dict with cdata($cid) {
                        $ht li
                        $ht put $narrative
                        $ht tiny " (condition type=$condition_type, id=$cid)"
                        $ht br
                        $ht putln "==> <font color=red>Warning: $cerror($cid)</font>"
                    }
                }
                
                $ht /ul
            }
            
            $ht /ul
        }

        $ht para

        set result [$ht pop]

        if {[dict size $adict] > 0} {
            $ht put $result
        }


        # Bad Tactics/Tactics with bad conditions
        $ht push
        $ht subtitle "Tactics Errors"

        $ht putln {
            The following tactics are invalid or have invalid
            conditions attached to them.  The invalid entities
            failed their sanity checks and have
            been marked invalid in the
        }
        
        $ht link gui:/tab/strategy "Strategy Browser"

        $ht put ". Please fix them or delete them."
        $ht para

        # Dictionary: agent->tactic->condition
        set adict [dict create]

        rdb eval {
            SELECT T.tactic_id      AS tactic_id,
                   T.owner          AS owner,
                   T.narrative      AS tactic_narrative,
                   T.tactic_type    AS tactic_type,
                   T.state          AS tactic_state,
                   C.condition_id   AS condition_id,
                   C.condition_type AS condition_type,
                   C.state          AS state,
                   C.narrative      AS narrative
            FROM tactics AS T 
            LEFT OUTER JOIN conditions AS C ON (cc_id = tactic_id)
            WHERE T.state = 'invalid' OR C.state = 'invalid'
        } row {
            dict set adict $row(owner) $row(tactic_id) $row(condition_id) 1
            set tdata($row(tactic_id))    [array get row]
            set cdata($row(condition_id)) [array get row]
        }

        dict for {a tdict} $adict {
            $ht putln "<b>Agent: $a</b>"
            $ht ul

            dict for {tid cdict} $tdict {
                $ht li

                dict with tdata($tid) {
                    $ht put $tactic_narrative
                    $ht tiny " (tactic type=$tactic_type, id=$tactic_id)"

                    if {$tactic_state eq "invalid"} {
                        $ht br
                        $ht putln "==> <font color=red>Warning: $terror($tid)</font>"
                    }
                }

                # If the tactic is invalid, we get all of its conditions; 
                # thus, we need to be careful here.

                $ht push

                dict for {cid dummy} $cdict {
                    if {[dict get $cdata($cid) state] != "invalid"} {
                        continue
                    }

                    dict with cdata($cid) {
                        $ht li
                        $ht put $narrative
                        $ht tiny " (condition type=$condition_type, id=$cid)"
                        $ht br
                        $ht putln "==> <font color=red>Warning: $cerror($cid)</font>"
                    }
                }

                set clist [$ht pop]

                if {$clist ne ""} {
                    $ht ul
                    $ht putln $clist
                    $ht /ul
                }
            }

            $ht /ul
        }

        $ht para

        set result [$ht pop]

        if {[dict size $adict] > 0} {
            $ht put $result
        }

        return
    }
}



