#-----------------------------------------------------------------------
# TITLE:
#    condition_met.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): MET(goals) condition.
#
# This module defines the MET condition ensemble and orders.  
# See condition(i) for a description of the standard subcommands.
#
# list <= goals -- List of goals
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Condition: MET(list1)
#
# list1   - A list of IDs of one or more goals belonging to the condition's
#           owner.
#
# The condition is met if all goals in the list are met.

condition type define MET {list1} -attachto tactic {
  
    # narrative
    #
    # Return a human-readable description of the condition.

    typemethod narrative {cdict} {
        dict with cdict {
            set gtext [list]

            rdb eval "
                SELECT goal_id, narrative
                FROM goals
                WHERE goal_id IN ([join $list1 ,])
                ORDER BY goal_id
            " {
                lappend gtext "    ($goal_id) $narrative"
            }

            if {[llength $list1] == 1} {
                return "Goal is met:\n[lindex $gtext 0]"
            } else {
                return "All of these goals are met:\n[join $gtext \n]"
            }
        }
    }

    # check
    #
    # sanity check the condition

    typemethod check {cdict} {
        dict with cdict {
            set result [list]

            foreach gid $list1 {
                if {$gid ni [goal names]} {
                    lappend result "Goal $gid no longer exists."
                }
            }
        }

        return [join $result " "]
    }

    # eval
    #
    # Evaluate the condition.  The condition is true if all of the
    # goals in the list with known values have a flag of one.

    typemethod eval {cdict} {
        set count 0

        dict with cdict {
            rdb eval "
                SELECT flag FROM goals
                WHERE goal_id IN ([join $list1 ,])
                AND   flag != ''
            " {
                incr count

                if {!$flag} {
                    return 0
                }
            }
        }

        # The goal can only be presumed to be met if there's at least
        # one condition with a known value.
        if {$count > 0} {
            return 1
        } else {
            return 0
        }
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # RefreshCREATE dlg fields fdict
    #
    # Populates the Goals field when the order dialog is popped up.

    typemethod RefreshCREATE {dlg fields fdict} {
        # FIRST, load the goals.
        if {"cc_id" in $fields} {
            set cc_id [dict get $fdict cc_id]
            $type SetItemDict $dlg $cc_id
        }
    }

    # RefreshUPDATE dlg fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the CONDITION:*:UPDATE dialog fields when field values
    # change, and disables the condition_id field; they can't pick
    # new ones.

    typemethod RefreshUPDATE {dlg fields fdict} {
        # FIRST, load the list1 field's -itemdict
        if {"condition_id" in $fields} {
            set condition_id [dict get $fdict condition_id]
            set cc_id [condition get $condition_id cc_id]
            $type SetItemDict $dlg $cc_id
        }
        
        # NEXT, refresh the fields from the RDB
        orderdialog refreshForKey condition_id * $dlg $fields $fdict
    }

    # SetItemDict dlg cid
    #
    # dlg    - The order dialog
    # cc_id  - The tactic ID
    #
    # Retrieves the owning agent for the tactic, and then the
    # dictionary of goal IDs and narratives for the owning agent.
    # These are loaded into the list1 field's -itemdict, so that
    # the user can choose from the required goals.

    typemethod SetItemDict {dlg cc_id} {
        
        set owner [tactic get $cc_id owner]
            
        set itemdict [rdb eval {
            SELECT goal_id, narrative
            FROM goals
            WHERE owner=$owner
        }]

        $dlg field configure list1 \
            -itemdict $itemdict

        if {[dict size $itemdict] == 0} {
            $dlg disabled list1
        } else {
            $dlg disabled {}
        }
    }

    # ValidateGoals owner gids
    #
    # owner - The owning agent
    # gids  - The goals
    #
    # Verifies that all goals belong to the specified agent.

    typemethod ValidateGoals {owner gids} {
        # FIRST, get the valid goals
        set validGoals [rdb eval {
            SELECT goal_id 
            FROM goals
            WHERE owner=$owner
        }]

        # NEXT, make sure we've been given a subset
        foreach gid $gids {
            if {$gid ni $validGoals} {
                return -code error -errorcode INVALID \
                    "Goal $gid does not belong to the condition's owning agent"
            }
        }
        
        return
    }
}

# CONDITION:MET:CREATE
#
# Creates a new MET condition.

order define CONDITION:MET:CREATE {
    title "Create Condition: Goal is Met"

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {condition::MET RefreshCREATE}

    parm cc_id  key   "Tactic ID"  -context yes         \
                                   -table   cond_collections \
                                   -keys    cc_id
    parm list1  goals "Goals"     
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id     -required -type   tactic
    prepare list1     -required -listof goal

    returnOnError

    # NEXT, make sure that the goals belong to the tactic's owner
    set owner [tactic get $parms(cc_id) owner]
    
    validate list1 {
        condition::MET ValidateGoals $owner $parms(list1)
    }

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) MET

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:MET:UPDATE
#
# Updates existing MET condition.

order define CONDITION:MET:UPDATE {
    title "Update Condition: Goal is Met"
    options \
        -sendstates {PREP PAUSED}                   \
        -refreshcmd {condition::MET RefreshUPDATE}

    parm condition_id key  "Condition ID"  -context yes          \
                                           -table   conditions   \
                                           -keys    condition_id
    parm list1        goals "Goals"
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required  -type   condition
    prepare list1                    -listof goal

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType MET $parms(condition_id)  
    }

    returnOnError

    # NEXT, make sure that the goals belong to the tactic's owner
    set cc_id [condition get $parms(condition_id) cc_id]
    set owner [tactic get $cc_id owner]
    
    validate list1 {
        condition::MET ValidateGoals $owner $parms(list1)
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}





