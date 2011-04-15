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
        # FIRST, determine whether the goals are met or unmet.
        $type ComputeGoalFlags

        # NEXT, determine which Tactics are eligible for each actor,
        # e.g., the list of tactics for which all conditions are met.
        set etactics [$type ComputeEligibleTactics]

        # NEXT, clean up the effects of the previous tock.
        # TBD: This is ugly; each tactic type should have a "clear"
        # method, and they should be called automatically.
        tactic::DEFROE clear
        rdb eval { UPDATE tactics SET exec_flag = 0; }

        # NEXT, execute the eligible tactics in priority order given
        # available resources.
        dict for {a elist} $etactics {
            $type SelectTactics $a $elist
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

    
    # OldSelectTactics a elist
    #
    # a     - An actor
    # elist - The eligible tactics for this actor
    #
    # Selects and executes tactics for actor a from the list
    # of eligible tactics, as constrained by available resources.
    #
    # TBD: Remove this before committing.

    typemethod OldSelectTactics {a elist} {
        log normal strat "SelectTactics $a: start"

        # FIRST, the plan is empty.
        set plan [list]

        # NEXT, get the actor's available assets
        set cash [actor get $a cash_on_hand]

        # FRC groups
        array set troops [rdb eval {
            SELECT g, total(personnel) 
            FROM personnel_ng
            JOIN frcgroups USING (g)
            WHERE a=$a
            GROUP BY g
        }]

        # ORG groups
        array set troops [rdb eval {
            SELECT g, total(personnel) 
            FROM personnel_ng
            JOIN orggroups USING (g)
            WHERE a=$a
            GROUP BY g
        }]


        # NEXT, step through the eligible tactics in priority order,
        # reducing assets or skipping tactics as we go.
        foreach tid $elist {
            # FIRST, get the tactic data
            set tdicts($tid) [tactic get $tid]

            # NEXT, skip if we haven't enough dollars
            lassign [tactic call dollars $tdicts($tid)] \
                minDollars desiredDollars

            if {$minDollars > $cash} {
                # Can't afford it
                continue
            }

            # NEXT, compute the actual cost: desiredDollars if there's
            # enough, and whatever is left otherwise.
            if {$cash >= $desiredDollars} {
                set dollars($tid) $desiredDollars
            } else {
                set dollars($tid) $cash
            }

            # NEXT, skip if we haven't enough personnel
            # TBD: Some tactics should soak up whatever is left.
            set pdict [tactic call personnel_by_group $tdicts($tid)] 

            dict for {g personnel} $pdict {
                if {$personnel > $troops($g)} {
                    # Can't afford it
                    continue
                }
            }

            # NEXT, we can afford it; consume the assets and add it to
            # the plan.

            let cash {$cash - $dollars($tid)}

            dict for {g personnel} $pdict {
                let troops($g) {max($troops(g) - $personnel, 0)}
            }

            log normal strat \
                "Tactic $tid costs \$$dollars($tid), <$pdict>"

            lappend plan $tid
        }

        # NEXT, save the new cash balance
        rdb eval { UPDATE actors SET cash=$cash WHERE a=$a; }

        # NEXT, execute the plan
        log normal strat "actor $a executes <$plan>"

        foreach tid $plan {
            set ttype [dict get $tdicts($tid) tactic_type]
            log normal strat \
                "Execute $ttype $tid, \$$dollars($tid): $tdicts($tid)"

            tactic call execute $tdicts($tid) $dollars($tid)

            rdb eval {
                UPDATE tactics
                SET exec_flag = 1,
                    exec_ts   = now()
                WHERE tactic_id = $tid
            }
        }

        log normal strat "SelectTactics $a: finish"
    }


    # SelectTactics a elist
    #
    # a     - An actor
    # elist - The eligible tactics for this actor
    #
    # Selects and executes tactics for actor a from the list
    # of eligible tactics, as constrained by available resources.  The
    # tactics are simply executed in order; tactics for which resources
    # are available are skipped.

    typemethod SelectTactics {a elist} {
        log normal strat "SelectTactics $a: start"

        # FIRST, the plan is empty.
        set plan [list]

        # NEXT, get the actor's available assets
        set adict [actor get $a]

        dict with adict {
            let cash {$income + $cash_on_hand}
        }

        # Personnel by FRC/ORG group
        array set troops [rdb eval {
            SELECT g, total(personnel) 
            FROM personnel_ng
            JOIN gui_agroups USING (g)
            WHERE a=$a
            GROUP BY g
        }]

        # NEXT, step through the eligible tactics in priority order,
        # reducing assets or skipping tactics as we go.
        foreach tid $elist {
            # FIRST, get the tactic data
            set tdicts($tid) [tactic get $tid]

            # NEXT, skip if we haven't enough dollars.
            lassign [tactic call dollars $tdicts($tid)] \
                minDollars desiredDollars

            if {$minDollars > $cash} {
                # Can't afford it
                continue
            }

            # NEXT, compute the actual cost: desiredDollars if there's
            # enough, and whatever is left otherwise.  Note that
            # desiredDollars can be negative for tactics that produce
            # cash on hand (e.g., SPEND).
            if {$cash >= $desiredDollars} {
                set toSpend $desiredDollars
            } else {
                set toSpend $cash
            }

            # NEXT, skip if we haven't enough personnel
            # TBD: Some tactics should soak up whatever is left.  We
            # should get the personnel data in that form, and provide
            # the actual troops to the tactic on execution.
            set pdict [tactic call personnel_by_group $tdicts($tid)] 

            dict for {g personnel} $pdict {
                if {$personnel > $troops($g)} {
                    # Can't afford it
                    continue
                }
            }

            # NEXT, we can afford it; consume the assets and add it to
            # the plan.

            let cash {$cash - $toSpend}

            dict for {g personnel} $pdict {
                let troops($g) {max($troops(g) - $personnel, 0)}
            }

            log normal strat \
                "Actor $a executes Tactic $tid: \$$toSpend, <$pdict>"

            # NEXT, execute the tactic.
            bgcatch {
                tactic call execute $tdicts($tid) $toSpend
            }

            rdb eval {
                UPDATE tactics
                SET exec_flag = 1,
                    exec_ts   = now()
                WHERE tactic_id = $tid
            }
        }

        # NEXT, save the new cash balance
        rdb eval { UPDATE actors SET cash_on_hand=$cash WHERE a=$a; }

        log normal strat "SelectTactics $a: finish"
    }

    #-------------------------------------------------------------------
    # Strategy Sanity Check

    # check ?ht?
    #
    # ht   - An htools buffer to receive a report.
    #
    # Tactics and conditions can become invalid after they are created.
    # For example, a group referenced by a tactic might be deleted,
    # or assigned to a different owner.  The sanity check looks for
    # such problems, and highlights them.  Invalid tactics and
    # conditions are so marked, and the user is notified.
    #
    # Returns 1 if the check is successful, and 0 otherwise.
    # If the ht value is given, then a report is written to the
    # named htools buffer.  It's presumed that the caller will handle
    # the page header and footer.
    #
    # Note that the database is not modified when writing a report.

    typemethod check {{ht ""}} {
        # FIRST, clear the invalid states, since we're going to 
        # recompute them, unless we're just writing a report.

        if {$ht eq ""} {
            rdb eval {
                UPDATE conditions 
                SET state = 'normal'
                WHERE state = 'invalid';

                UPDATE tactics
                SET state = 'normal'
                WHERE state = 'invalid';
            }
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
        # Use CONDITION:STATE and TACTIC:STATE, because this
        # guarantees that RDB notifier events are sent.
        #
        # BUT: Don't do this if we've been given an ht buffer;
        # then we just want to generate a report.
        if {$ht eq ""} {
            foreach condition_id $badConditions {
                order send app CONDITION:STATE \
                    condition_id $condition_id \
                    state        invalid
            }

            foreach tactic_id $badTactics {
                order send app TACTIC:STATE \
                    tactic_id $tactic_id \
                    state     invalid
            }
        }

        # NEXT, if there's nothing wrong, we're done.
        if {[array size cerror] == 0 &&
            [array size terror] == 0
        } {
            if {$ht ne ""} {
                $ht putln "No sanity check failures were found."
            }

            return 1
        }

        # NEXT, If they don't want a report, just return the flag.
        if {$ht eq ""} {
            return 0
        }

        # NEXT, Build the report
        $ht putln {
            Certain tactics or conditions have failed their sanity
            checks and have been marked invalid in the Strategy
            Browser.  Please fix them or delete them.
        }

        # Goals with condition errors
        $ht push
        $ht h2 "Goals with Condition Errors"

        $ht putln "The following goals have invalid conditions attached."
        $ht para
             
        set lastOwner {}
        set lastGoal {}

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
            if {$row(owner) ne $lastOwner} {
                if {$lastOwner ne ""} {
                    $ht /ul
                    $ht /ul
                }

                set lastOwner $row(owner)
                set lastGoal {}
               
                $ht para
                $ht putln "<b>Actor: $row(owner)</b>"
                $ht ul
            }

            if {$row(goal_id) ne $lastGoal} {
                if {$lastGoal ne ""} {
                    $ht /ul
                }
                set lastGoal $row(goal_id)


                $ht li
                $ht put "$row(goal_narrative)"
                $ht tiny " (goal_id=$row(goal_id)) "
                $ht ul
            }

            $ht li {
                $ht put $row(narrative)
                $ht tiny " (type=$row(condition_type), id=$row(condition_id))"
                $ht br
                $ht put "==> $cerror($row(condition_id))"
            }
        }

        $ht /ul
        $ht /ul
        $ht para

        set result [$ht pop]

        if {$lastOwner ne ""} {
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

        set lastOwner {}
        set lastTactic {}

        rdb eval {
            SELECT T.tactic_id   AS tactic_id,
                   T.narrative   AS tactic_narrative,
                   T.tactic_type AS tactic_type,
                   T.state       AS tactic_state,
                   C.*
            FROM tactics AS T 
            JOIN conditions AS C ON (co_id = tactic_id)
            WHERE T.state = 'invalid' OR C.state = 'invalid'
        } row {
            if {$row(owner) ne $lastOwner} {
                if {$lastOwner ne ""} {
                    $ht /ul
                    $ht /ul
                }

                set lastOwner $row(owner)
                set lastTactic {}

                $ht para
                $ht putln "<b>Actor: $row(owner)</b>"
                $ht ul
            }

            if {$row(tactic_id) ne $lastTactic} {
                if {$lastTactic ne ""} {
                    $ht /ul
                }

                set lastTactic $row(tactic_id)

                $ht li 
                $ht put $row(tactic_narrative)
                $ht tiny " (type=$row(tactic_type), id=$row(tactic_id))"

                if {$row(tactic_state) eq "invalid"} {
                    $ht br
                    $ht put "==> $terror($row(tactic_id))"
                }
                
                # If there are conditions, begin the list of conditions.
                if {$row(state) eq "invalid"} {
                    $ht ul
                }
            }

            if {$row(state) eq "invalid"} {
                $ht li {
                    $ht put $row(narrative)
                    $ht tiny " (type=$row(condition_type), id=$row(condition_id))"
                    $ht br
                    $ht put "==> $cerror($row(condition_id))"
                }
            }
        }

        if {$row(state) eq "invalid"} {
            $ht /ul
        }
        $ht /ul
        $ht para

        set result [$ht pop]

        if {$lastOwner ne ""} {
            $ht put $result
        }

        # FINALLY, return the flag.
        return 0
    }
}
