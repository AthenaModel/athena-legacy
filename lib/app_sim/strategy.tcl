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
#    An actor's strategy is his collection of goals and tactics and their
#    attached conditions.  This module is responsible for sanity-checking
#    actor strategies, and for executing the actor's strategy at each 
#    strategy execution tock (nominally seven days).
#
#-----------------------------------------------------------------------

snit::type strategy {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Strategy Execution Tock
    #
    # These routines are called during the strategy execution tock
    # to select and execute tactics.

    # tock
    #
    # Executes actor strategies:
    #
    # * Determines whether all goals and conditions are met or unmet.
    # * For each actor, 
    #   * Determines which tactics are eligible for 
    #     execution (i.e., have no unmet conditions).
    #   * Selects the tactics to execute given available resources.
    #   * Executes the selected tactics.

    typemethod tock {} {
        # FIRST, prepare for this tock.
        set deployments [$type SaveOldDeployments]

        personnel reset
        tactic reset
        tactic::DEFROE reset

        # NEXT, give actors their income.
        rdb eval {
            UPDATE actors
            SET cash_on_hand = cash_on_hand + income
        }

        # NEXT, determine whether the goals are met or unmet.
        $type ComputeGoalFlags

        # NEXT, determine which Tactics are eligible for each actor,
        # e.g., the list of tactics for which all conditions are met.
        set etactics [$type ComputeEligibleTactics]

        # NEXT, execute the eligible tactics in priority order given
        # available resources.
        dict for {a elist} $etactics {
            $type ExecuteTactics $a $elist
        }

        # NEXT, log deployment changes
        $type LogDeploymentChanges $deployments

        # NEXT, demobilize undeployed troops.
        if {[parm get strategy.autoDemob]} {
            foreach {g available a} [rdb eval {
                SELECT g, available, a 
                FROM personnel_g
                JOIN agroups USING (g) 
                WHERE available > 0
            }] {
                sigevent log warning strategy "
                    Demobilizing $available undeployed {group:$g} personnel.
                " $g $a
                personnel demob $g $available
            }
        }
    }

    # ComputeGoalFlags
    #
    # Computes for each goal whether the goal is met or unmet.

    typemethod ComputeGoalFlags {} {
        log normal strat ComputeGoalFlags

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
            LEFT OUTER JOIN conditions ON (co_id = goal_id)
            WHERE goals.state = 'normal'
        } row {
            if {![info exists gconds($row(goal_id))]} {
                set gconds($row(goal_id)) [list]
            }

            if {$row(condition_id) ne ""} {
                lappend gconds($row(goal_id)) $row(condition_id)

                set cdicts($row(condition_id)) [array get row]
            }
        }

        # NEXT, compute the goal flags for all goals; and the
        # condition flags along the way.
        foreach gid [array names gconds] {
            log normal strat "Goal $gid:"

            # FIRST, compute the condition flags, accumulating the 
            # goal flag
            set gflag 1

            foreach cid $gconds($gid) {
                set cstate [dict get $cdicts($cid) state]

                # FIRST, if compute the flag if the condition's
                # state is normal; otherwise, ignore the condition
                # (which means pretending that it's true).
                if {$cstate eq "normal"} {
                    set flag [condition call eval $cdicts($cid)]
                    set gflag [expr {$gflag && $flag}]
                } else {
                    set flag ""
                }

                log normal strat "==> Condition $cid is met: <$flag>"

                # NEXT, save the condition's flag; make it NULL
                # if the value is unknown
                rdb eval {
                    UPDATE conditions
                    SET flag = nullif($flag,"")
                    WHERE condition_id = $cid
                }
            }

            # NEXT, save the goal's flag.
            log normal strat "!!! Goal $gid is met: <$gflag>"
            
            rdb eval {
                UPDATE goals
                SET flag = $gflag
                WHERE goal_id = $gid
            }
        }
    }

    # ComputeEligibleTactics
    #
    # Computes for each tactic whether it is eligible or not, i.e.,
    # whether all of its conditions are met or not.
    # Returns a dictionary of actors -> list of eligible tactics

    typemethod ComputeEligibleTactics {} {
        log normal strat "ComputeEligibleTactics"

        # FIRST, load the tactics and tactic conditions.
        set tids [list]

        rdb eval {
            SELECT tactics.tactic_id AS tactic_id,
                   tactics.owner     AS owner,
                   conditions.*
            FROM tactics
            LEFT OUTER JOIN conditions ON (co_id = tactic_id)
            WHERE tactics.state = 'normal'
            ORDER BY tactics.priority
        } row {
            if {![info exists tconds($row(tactic_id))]} {
                lappend tids $row(tactic_id)
                set tconds($row(tactic_id)) [list]
            }

            set owner($row(tactic_id)) $row(owner)

            if {$row(condition_id) ne ""} {
                lappend tconds($row(tactic_id)) $row(condition_id)
                set cdicts($row(condition_id)) [array get row]
            }
        }

        # NEXT, compute eligibility for all tactics; and the
        # condition flags along the way.  Note that $tids has
        # the tactics in priority order.
        foreach tid $tids {
            log normal strat "Tactic $tid:"

            # FIRST, compute the condition flags, accumulating the 
            # eligiblity flag
            set tflag 1

            foreach cid $tconds($tid) {
                set cstate [dict get $cdicts($cid) state]

                # FIRST, compute the flag if the condition's
                # state is normal; otherwise, ignore the condition
                # (which means pretending that it's true).
                if {$cstate eq "normal"} {
                    set flag [condition call eval $cdicts($cid)]
                    set tflag [expr {$tflag && $flag}]
                } else {
                    set flag ""
                }

                log normal strat "==> Condition $cid is met: <$flag>"

                # NEXT, save the condition's flag; make it NULL
                # if the value is unknown
                rdb eval {
                    UPDATE conditions
                    SET flag = nullif($flag,"")
                    WHERE condition_id = $cid
                }
            }

            # NEXT, If the tactic is eligible, save its ID for the
            # given owner.
            log normal strat "!!! Tactic $tid is eligible: <$tflag>"


            if {$tflag} {
                lappend etactics($owner($tid)) $tid
            }
        }

        log normal strat "Eligible tactics: [array get etactics]"

        return [array get etactics]
    }


    # ExecuteTactics a elist
    #
    # a     - An actor
    # elist - The eligible tactics for this actor
    #
    # Executes  tactics for actor a from the list
    # of eligible tactics, as constrained by available resources.  The
    # tactics are simply executed in order; tactics for which resources
    # are unavailable do nothing.

    typemethod ExecuteTactics {a elist} {
        log normal strat "ExecuteTactics $a: start"

        foreach tid $elist {
            set tdict [tactic get $tid]

            if {[tactic execute $tdict]} {
                log normal strat "Actor $a executed <$tdict>"
            }
        }

        log normal strat "ExecuteTactics $a: finish"
    }

    # SaveOldDeployments
    #
    # Returns a dictionary n->g->personnel of all non-zero deployments.

    typemethod SaveOldDeployments {} {
        set result [dict create]

        rdb eval {
            SELECT n,g,personnel 
            FROM deploy_ng
            WHERE personnel != 0
        } {
            dict set result $n $g $personnel
        }

        return $result
    }

    # LogDeploymentChanges old
    #
    # old    - Dictionary n->g->personnel of old deployments
    #
    # Logs all deployment changes.

    typemethod LogDeploymentChanges {old} {
        rdb eval {
            SELECT n,g,personnel,a
            FROM deploy_ng
            JOIN agroups USING (g)
        } {
            if {$personnel == 0 &&
                [dict exists $old $n $g]
            } {
                set oldPersonnel [dict get $old $n $g]

                sigevent log 1 strategy "
                    Actor {actor:$a} withdrew all $oldPersonnel {group:$g} 
                    personnel from {nbhood:$n}.
                " $a $g $n

                continue
            }

            if {[dict exists $old $n $g]} {
                set oldPersonnel [dict get $old $n $g]
            } else {
                set oldPersonnel 0
            }

            let delta {$personnel - $oldPersonnel}

            if {$delta > 0} {
                sigevent log 1 strategy "
                    Actor {actor:$a} added $delta {group:$g} personnel 
                    to {nbhood:$n}, for a total of $personnel personnel.
                " $a $g $n
            } elseif {$delta < 0} {
                let delta {-$delta}

                sigevent log 1 strategy "
                    Actor {actor:$a} withdrew $delta {group:$g} personnel 
                    from {nbhood:$n} for a total of $personnel personnel.
                " $a $g $n
            }
        }
    }

    #-------------------------------------------------------------------
    # Strategy Sanity Check

    # sanity check
    #
    # Tactics and conditions can become invalid after they are created.
    # For example, a group referenced by a tactic might be deleted,
    # or assigned to a different owner.  The sanity check looks for
    # such problems, and highlights them.  Invalid tactics and
    # conditions are so marked, and the user is notified.
    #
    # Returns 1 if the check is successful, and 0 otherwise.

    typemethod {sanity check} {} {
        set flag [$type DoSanityCheck cerror terror]

        notifier send ::strategy <Check>

        return $flag
    }

    # sanity report ht
    #
    # ht    - An htools buffer
    #
    # Computes the sanity check, and formats the results into the ht
    # buffer for inclusion in an HTML page.  This command can presume
    # that the buffer is already initialized and ready to receive the
    # data.

    typemethod {sanity report} {ht} {
        $type DoSanityCheck cerror terror
        
        return [$type DoSanityReport $ht cerror terror]
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
            SELECT *
            FROM conditions
            JOIN cond_owners USING (co_id)
            WHERE state != 'disabled'
        } row {
            # FIRST, Check and skip valid conditions
            set result [condition call check [array get row]]

            if {$result ne ""} {
                set cerror($row(condition_id)) $result
                lappend badConditions $row(condition_id)
            }
        }

        # FIRST, NEXT invalid tactics.
        set badTactics [list]

        rdb eval {
            SELECT * FROM tactics
        } row {
            set result [tactic call check [array get row]]

            if {$result ne ""} {
                set terror($row(tactic_id)) $result
                lappend badTactics $row(tactic_id)
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

        # FIRST, if there's nothing wrong, the report is simple.
        if {[array size cerror] == 0 &&
            [array size terror] == 0
        } {
            if {$ht ne ""} {
                $ht putln "No sanity check failures were found."
            }

            return
        }

        # NEXT, Build the report
        $ht putln {
            Certain tactics or conditions have failed their sanity
            checks and have been marked invalid in the
        }
        
        $ht link gui:/tab/strategy "Strategy Browser"

        $ht put " Please fix them or delete them."
        $ht para


        # Goals with condition errors
        $ht push
        $ht h2 "Goals with Condition Errors"

        $ht putln "The following goals have invalid conditions attached."
        $ht para
             
        # Get the errant conditions by actor and goal.
        
        # Dictionary: actor->goal->condition
        set adict [dict create]

        rdb eval {
            SELECT goals.goal_id   AS goal_id, 
                   goals.narrative AS goal_narrative,
                   goals.owner     AS owner,
                   conditions.*
            FROM goals
            JOIN conditions ON (co_id = goal_id)
            WHERE conditions.state = 'invalid'
            ORDER BY owner, goal_id, condition_id
        } row {
            dict set adict $row(owner) $row(goal_id) $row(condition_id) 1
            set gdata($row(goal_id)) $row(goal_narrative)
            set cdata($row(condition_id)) [array get row]
        }

        dict for {a gdict} $adict {
            $ht putln "<b>Actor: $a</b>"
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
                        $ht putln "==> <font color=red>$cerror($cid)</font>"
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
        $ht h2 "Tactics Errors"

        $ht putln {
            The following tactics are invalid or have invalid 
            conditions attached to them.
        }

        $ht para

        # Dictionary: actor->tactic->condition
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
            LEFT OUTER JOIN conditions AS C ON (co_id = tactic_id)
            WHERE T.state = 'invalid' OR C.state = 'invalid'
        } row {
            dict set adict $row(owner) $row(tactic_id) $row(condition_id) 1
            set tdata($row(tactic_id))    [array get row]
            set cdata($row(condition_id)) [array get row]
        }

        dict for {a tdict} $adict {
            $ht putln "<b>Actor: $a</b>"
            $ht ul

            dict for {tid cdict} $tdict {
                $ht li

                dict with tdata($tid) {
                    $ht put $tactic_narrative
                    $ht tiny " (tactic type=$tactic_type, id=$tactic_id)"

                    if {$tactic_state eq "invalid"} {
                        $ht br
                        $ht putln "==> <font color=red>$terror($tid)</font>"
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
                        $ht putln "==> <font color=red>$cerror($cid)</font>"
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

