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
    # Transient Type Variables
    #
    # These variables are used transiently while processing.

    # TBD

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

        # NEXT, determine which Tactics are eligible for each actor.
        set etactics [$type ComputeEligibleTactics]

        # NEXT, clean up the effects of the previous tock.
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
    #
    # TBD: This algorithm is going to be straightforward; it will
    # get more complicated when the GoalIsMet()/GoalIsUnmet() 
    # condition types are implemented.

    typemethod ComputeGoalFlags {} {
        log normal strat ComputeGoalFlags
        # FIRST, load the goals and goal conditions.
        rdb eval {
            SELECT goals.goal_id AS goal_id,
                   conditions.*
            FROM goals
            LEFT OUTER JOIN conditions ON (co_id = goal_id)
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
            # TBD: Once we have GoalIsMet/GoalIsUnmet conditions,
            # we'll need to save it in memory as well.
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
    # Computes for each tactic whether it is eligible or not.
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

    
    # SelectTactics a elist
    #
    # a     - An actor
    # elist - The eligible tactics for this actor
    #
    # Selects and executes tactics for actor a from the list
    # of eligible tactics, as constrained by available resources.

    typemethod SelectTactics {a elist} {
        log normal strat "SelectTactics $a: start"

        # FIRST, the plan is empty.
        set plan [list]

        # NEXT, get the actor's available assets
        set cash [actor get $a cash]

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


    #-------------------------------------------------------------------
    # Strategy Sanity Check

    # check
    #
    # Tactics and conditions can become invalid after they are created.
    # For example, a group referenced by a tactic might be deleted,
    # or assigned to a different owner.  The sanity check looks for
    # such problems, and highlights them.  Invalid tactics and
    # conditions are so marked, and the user is notified.
    #
    # Returns 1 if the check is successful, and 0 otherwise.

    typemethod check {} {
        # FIRST, find invalid conditions
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
                lappend badConditions $row(condition_id)
                set cerror($row(condition_id)) $result
            }
        }

        # NEXT, mark the bad conditions invalid.  Use CONDITION:STATE, 
        # because it guarantees that the RDB <conditions> updates 
        # are sent.
        foreach condition_id $badConditions {
            order send sim CONDITION:STATE \
                condition_id $condition_id \
                state        invalid
        }

        # FIRST, NEXT invalid tactics.
        set badTactics [list]

        rdb eval {
            SELECT * FROM tactics
        } row {
            set result [tactic call check [array get row]]

            if {$result ne ""} {
                lappend badTactics $row(tactic_id)
                set terror($row(tactic_id)) $result
            }
        }

        # NEXT, mark them invalid.  Use TACTIC:STATE, because
        # it guarantees that the RDB <tactics> updates are sent.
        foreach tactic_id $badTactics {
            order send sim TACTIC:STATE \
                tactic_id $tactic_id \
                state     invalid
        }

        # NEXT, if there's nothing wrong, we're done.
        if {[llength $badConditions] == 0 &&
            [llength $badTactics] == 0
        } {
            return 1
        }

        # NEXT, Build a report
        set report [list]
        lappend report \
            "Certain tactics or conditions have failed their sanity"     \
            "checks and have been marked invalid.  Please fix or delete" \
            "them on the Strategy tab."                                  \
            ""

        # Goals with condition errors
        set entries {}
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
                set lastOwner $row(owner)
                set lastGoal {}
                
                lappend entries "Actor: $row(owner)"
            }

            if {$row(goal_id) ne $lastGoal} {
                set lastGoal $row(goal_id)

                lappend entries \
                    "    Goal ID=$row(goal_id), $row(goal_narrative)"
            }

            lappend entries \
                "        Condition ID=$row(condition_id), $row(narrative) ($row(condition_type))" \
                "            ==> $cerror($row(condition_id))"              \
                ""
        }

        if {[llength $entries] != 0} {
            lappend report \
                "The following goals have invalid conditions attached" \
                ""

            lappend report {*}$entries
        }

        # Bad Tactics/Tactics with bad conditions
        set entries {}
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
                set lastOwner $row(owner)
                set lastGoal {}
                
                lappend entries "Actor: $row(owner)"
            }

            if {$row(tactic_id) ne $lastTactic} {
                set lastTactic $row(tactic_id)

                lappend entries \
                    "    Tactic ID=$row(tactic_id), $row(tactic_narrative) ($row(tactic_type))"

                if {$row(tactic_state) eq "invalid"} {
                    lappend entries \
                        "        ==> $terror($row(tactic_id))" \
                        ""
                }
            }

            if {$row(state) eq "invalid"} {
                lappend entries \
                    "        Condition ID=$row(condition_id), $row(narrative) ($row(condition_type))" \
                    "            ==> $cerror($row(condition_id))"  \
                    ""

            }
        }

        if {[llength $entries] != 0} {
            lappend report \
                "The following tactics are invalid or have invalid conditions attached" \
                "to them." \
                ""

            lappend report {*}$entries
        }


        # NEXT, send the report.
        report save \
            -rtype   SCENARIO                \
            -subtype SANITY                  \
            -meta1   STRATEGY                \
            -title   "Strategy Sanity Check" \
            -text    [join $report \n]
        
        return 0
    }
}