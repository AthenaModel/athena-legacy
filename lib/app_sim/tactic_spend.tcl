#-----------------------------------------------------------------------
# TITLE:
#    tactic_spend.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): SPEND Tactic Definition
#
# This module defines the SPEND tactic.  See tactic(i) for the interface that
# each tactic type must provide.
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Tactic: SPEND
#
# int1 - Integer percentage of cash_reserve to move from the actor's
#        cash_reserve to the actor's cash_on_hand.


tactic type define SPEND {int1} {
    typemethod narrative {tdict} {
        dict with tdict {
            return "Spend $int1% of cash reserve"
        }
    }

    typemethod execute {tdict} {
        dict with tdict {
            array set cinfo [cash get $owner]

            let amount {$cinfo(cash_reserve)*$int1/100.0}

            if {$amount == 0.0} {
                return 0
            }

            cash withdraw $owner $amount

            sigevent log 2 tactic "
                SPEND: $owner transfers \$[moneyfmt $amount] 
                from reserve to cash-on-hand.
            " $owner

            return 1
        }
    }
}

# TACTIC:SPEND:CREATE
#
# Creates a new SPEND tactic.

order define TACTIC:SPEND:CREATE {
    title "Create Tactic: Spend Money"

    options -sendstates {PREP PAUSED}

    parm owner    actor "Owner"                 -context yes
    parm int1     text  "Percentage of Reserve" -defval 10
    parm priority enum  "Priority"              -enumtype ePrioSched \
                                                -displaylong yes     \
                                                -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare int1                -required -type ipercent
    prepare priority -tolower             -type ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parm dict
    set parms(tactic_type) SPEND

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:SPEND:UPDATE
#
# Updates existing SPEND tactic.

order define TACTIC:SPEND:UPDATE {
    title "Update Tactic: Spend Money"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id key  "Tactic ID"             -context yes           \
                                                -table   tactics_SPEND \
                                                -keys    tactic_id
    parm owner     disp "Owner"
    parm int1      text "Percentage of Reserve"
} {
    # FIRST, prepare the parameters
    prepare tactic_id   -required -type tactic
    prepare int1        -required -type ipercent

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType SPEND $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


