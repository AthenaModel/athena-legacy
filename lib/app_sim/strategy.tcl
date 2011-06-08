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
        # FIRST, Set up working tables.  This includes giving
        # the actors their incomes.
        cash load
        personnel load
        tactic reset
        tactic::ATTROE reset
        tactic::DEFROE reset
        unit reset

        # NEXT, determine whether the goals are met or unmet.
        $type ComputeGoalFlags

        # NEXT, examine each actor's tactic in priority order.  If the
        # tactic is eligible, attempt to execute it.
        foreach tid [rdb eval {
            SELECT tactic_id
            FROM tactics
            WHERE state = 'normal'
            ORDER BY owner, priority
        }] {
            if {[$type IsEligible $tid]} {
                log normal strategy "Tactic $tid IS eligible"
                $type ExecuteTactic $tid
            } else {
                log normal strategy "Tactic $tid IS NOT eligible"
            }
        }

        # NEXT, save working data
        cash save
        personnel save

        # NEXT, populate base units for all groups.
        unit makebase
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

                set cdicts($row(condition_id)) [array get row]
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
    # tid - A tactic_id
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

        rdb eval {
            SELECT *
            FROM conditions
            WHERE cc_id = $tid
            AND   state = 'normal'
        } row {
            unset -nocomplain row(*)

            set flag [condition call eval [array get row]]

            lappend cflags $row(condition_id) $flag

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
            JOIN cond_collections USING (cc_id)
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
            JOIN conditions ON (cc_id = goal_id)
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
            LEFT OUTER JOIN conditions AS C ON (cc_id = tactic_id)
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



