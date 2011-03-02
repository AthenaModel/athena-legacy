#-----------------------------------------------------------------------
# TITLE:
#    condition_goals.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Condition Type Definitions relating to Goals.
#
# This module defines the GOAL condition ensemble and orders.  
# See condition(i) for a description of the standard 
# subcommands.
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Condition: GOAL(list1,text1)
#
# list1   - A list of IDs of one or more goals belonging to the condition's
#           owning actor.
# text1   - egoal_predicate(n): MET or UNMET.
#
# If MET, the condition is met if all goals in the list are met.
# If UNMET, the condition is met if any goal in the list is unmet.

condition type define GOAL -attachto tactic {
  
    # narrative
    #
    # Return a human-readable description of the condition.

    typemethod narrative {cdict} {
        # TBD: Display goal narratives as well as goal IDs?
        dict with cdict {
            if {[llength $list1] == 1} {
                return "Goal is [string tolower $text1]: $list1"
            } elseif {$text1 eq "MET"} {
                return "All of these goals are met: [join $list1 {, }]"
            } else {
                return "Any of these goals are unmet: [join $list1 {, }]"
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
    # Evaluate the condition.  In this case, the condition is true
    # if there are any goals in the list that are unmet, i.e., have
    # flag of 0.
    #
    # TBD: Optimization: Write one query, using "IN", instead of
    # using [goal get]


    typemethod eval {cdict} {
        dict with cdict {
            if {$text1 eq "MET"} {
                set A 0
                set B 1
            } else {
                set A 1
                set B 0
            }

            foreach gid $list1 {
                set gflag [goal get $gid flag]
                
                if {$gflag ne "" && !$gflag} {
                    return $A
                }
            }

            return $B
        }
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # RefreshCREATE dlg fields fdict
    #
    # Populates the Goals field when the order dialog is popped up.

    typemethod RefreshCREATE {dlg fields fdict} {
        # FIRST, load the goals.
        if {"co_id" in $fields} {
            set co_id [dict get $fdict co_id]
            $type SetItemDict $dlg $co_id

            # NEXT, make condition_id invalid
            # TBD: This is tacky; we need a better mechanism to make
            # the co_id field read-only.
            $dlg disabled co_id
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
            set co_id [condition get $condition_id co_id]
            $type SetItemDict $dlg $co_id
        }
        
        # NEXT, refresh the fields from the RDB
        orderdialog refreshForKey condition_id * $dlg $fields $fdict

        # NEXT, make condition_id invalid
        # TBD: This is tacky; we need a better mechanism to make
        # the condition_id field read-only.
        $dlg disabled condition_id
    }

    # SetItemDict dlg co_id
    #
    # dlg    - The order dialog
    # co_id  - The tactic ID
    #
    # Retrieves the owning actor for the tactic, and then the
    # dictionary of goal IDs and narratives for the owning actor.
    # These are loaded into the list1 field's -itemdict, so that
    # the user can choose from the required goals.

    typemethod SetItemDict {dlg co_id} {
        
        set owner [tactic get $co_id owner]
            
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
    # owner - The owning actor
    # gids  - The goals
    #
    # Verifies that all goals belong to the specified actor.

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
                    "Goal $gid does not belong to the condition's owning actor"
            }
        }
        
        return
    }
}

# CONDITION:GOAL:CREATE
#
# Creates a new GOAL condition.

order define CONDITION:GOAL:CREATE {
    title "Create Condition: Goal Flag"

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {condition::GOAL RefreshCREATE}

    parm co_id  key   "Tactic ID"  -table       cond_owners \
                                   -keys        co_id
    parm list1  goals "Goals"     
    parm text1  enum  "Are"        -enumtype    egoal_predicate \
                                   -displaylong yes
} {
    # FIRST, prepare and validate the parameters
    prepare co_id     -required -type   tactic
    prepare list1     -required -listof goal
    prepare text1     -required -type   egoal_predicate

    returnOnError

    # NEXT, make sure that the goals belong to the tactic's owner
    set owner [tactic get $parms(co_id) owner]
    
    validate list1 {
        condition::GOAL ValidateGoals $owner $parms(list1)
    }

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) GOAL

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:GOAL:UPDATE
#
# Updates existing GOAL condition.

order define CONDITION:GOAL:UPDATE {
    title "Update Condition: Goals Unmet"
    options \
        -sendstates {PREP PAUSED}                               \
        -refreshcmd {condition::GOAL RefreshUPDATE}

    parm condition_id key  "Condition ID"  -table    conditions   \
                                           -keys     condition_id
    parm list1        goals "Goals"
    parm text1        enum  "Are"          -enumtype egoal_predicate \
                                           -displaylong yes
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required  -type   condition
    prepare list1                    -listof goal
    prepare text1                    -type   egoal_predicate

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType GOAL $parms(condition_id)  
    }

    returnOnError

    # NEXT, make sure that the goals belong to the tactic's owner
    set co_id [condition get $parms(condition_id) co_id]
    set owner [tactic get $co_id owner]
    
    validate list1 {
        condition::GOAL ValidateGoals $owner $parms(list1)
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}



