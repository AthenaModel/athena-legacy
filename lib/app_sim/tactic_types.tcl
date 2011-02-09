#-----------------------------------------------------------------------
# TITLE:
#    tactic_types.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Tactic Type Definitions
#
# This module contains miscellaneous tactic type definitions which
# have no other obvious home.  See tactic(i) for the interface that
# each tactic type must provide.
#
#-----------------------------------------------------------------------




#-------------------------------------------------------------------
# Tactic: SAVEMONEY

tactic type define SAVEMONEY {
    typemethod narrative {tdict} {
        dict with tdict {
            return "Save $int1% of income for later use"
        }
    }

    typemethod check {tdict} {
        # Nothing to check
        return
    }

    typemethod estdollars {tdict} {
        return [lindex [$type dollars $tdict] 1]
    }

    typemethod dollars {tdict} {
        dict with tdict {
            set income [actor get $owner income]
            return [list 0.0 [expr {$income*$int1/100.0}]]
        }

        return 0
    }

    typemethod estpersonnel {tdict} {
        return 0
    }

    typemethod personnel_by_group {tdict} {
        return {}
    }

    typemethod execute {tdict dollars} {
        dict with tdict {
            rdb eval {
                UPDATE actors 
                SET cash = cash + $dollars
                WHERE a=$owner;
            }
        }
    }
}

# TACTIC:SAVEMONEY:CREATE
#
# Creates a new SAVEMONEY tactic.

order define TACTIC:SAVEMONEY:CREATE {
    title "Create Tactic: Save Money"

    options -sendstates {PREP PAUSED}

    parm owner    key  "Owner"             -table actors -key a
    parm int1     text "Percent of Income" -defval 10
    parm priority enum "Priority"          -type ePrioSched \
                                           -displaylong     \
                                           -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare int1                -required -type ipercent
    prepare priority -tolower             -type ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parm dict
    set parms(tactic_type) SAVEMONEY

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:SAVEMONEY:UPDATE
#
# Updates existing SAVEMONEY tactic.

order define TACTIC:SAVEMONEY:UPDATE {
    title "Update Tactic: Save Money"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {tactic RefreshUPDATE}

    parm tactic_id key  "Tactic ID"  -table tactics_SAVEMONEY -key tactic_id
    parm owner     disp "Owner"
    parm int1      text "Percent"
} {
    # FIRST, prepare the parameters
    prepare tactic_id   -required -type tactic
    prepare int1        -required -type ipercent

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType SAVEMONEY $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


