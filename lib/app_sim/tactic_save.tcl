#-----------------------------------------------------------------------
# TITLE:
#    tactic_save.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): SAVE Tactic Definition
#
# This module defines the SAVE tactic.  See tactic(i) for the interface that
# each tactic type must provide.
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Tactic: SAVE
#
# int1 - Integer percentage of income to save to the actor's reserve.


tactic type define SAVE {
    typemethod narrative {tdict} {
        dict with tdict {
            return "Save $int1% of income for later use"
        }
    }

    typemethod dollars {tdict} {
        dict with tdict {
            set income [actor get $owner income]
            return [moneyfmt [expr {$income*$int1/100.0}]]
        }
    }

    typemethod execute {tdict} {
        # FIRST, if there's no cash_on_hand, return 0.
        dict with tdict {
            array set ainfo [actor get $owner]

            let amount {min($ainfo(cash_on_hand), $ainfo(income)*$int1/100.0)}

            if {$amount == 0.0} {
                return 0
            }

            rdb eval {
                UPDATE actors 
                SET cash_reserve = cash_reserve + $amount,
                    cash_on_hand = cash_on_hand - $amount
                WHERE a=$owner;
            }

            return 1
        }
    }
}

# TACTIC:SAVE:CREATE
#
# Creates a new SAVE tactic.

order define TACTIC:SAVE:CREATE {
    title "Create Tactic: Save Money"

    options -sendstates {PREP PAUSED}

    parm owner    actor "Owner"                -context yes
    parm int1     text  "Percentage of Income" -defval 10
    parm priority enum  "Priority"             -enumtype ePrioSched \
                                               -displaylong yes     \
                                               -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare int1                -required -type ipercent
    prepare priority -tolower             -type ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parm dict
    set parms(tactic_type) SAVE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:SAVE:UPDATE
#
# Updates existing SAVE tactic.

order define TACTIC:SAVE:UPDATE {
    title "Update Tactic: Save Money"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id key  "Tactic ID"            -context yes          \
                                               -table   tactics_SAVE \
                                               -keys    tactic_id
    parm owner     disp "Owner"
    parm int1      text "Percentage of Income"
} {
    # FIRST, prepare the parameters
    prepare tactic_id   -required -type tactic
    prepare int1        -required -type ipercent

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType SAVE $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


