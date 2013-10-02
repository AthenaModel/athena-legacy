#-----------------------------------------------------------------------
# TITLE:
#    tactic_deposit.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): DEPOSIT(amount) tactic
#
# This module defines the DEPOSIT tactic, which deposits a sum of
# money in the actor's cash reserve.
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Tactic: DEPOSIT

tactic type define DEPOSIT {amount} actor {
    typemethod narrative {tdict} {
        dict with tdict {}
        return "Deposit \$[moneyfmt $amount] to the cash reserve."
    }

    typemethod dollars {tdict} {
        dict with tdict {}
        return [moneyfmt $amount]
    }

    typemethod execute {tdict} {
        # FIRST, if there's no cash_on_hand, return 0.
        dict with tdict {}
        array set cinfo [cash get $owner]

        let amount {min($cinfo(cash_on_hand), $amount)}

        if {$amount == 0.0} {
            return 0
        }
        
        cash deposit $owner $amount

        sigevent log 2 tactic "
            DEPOSIT: $owner deposits \$[moneyfmt $amount] to reserve.
        " $owner

        return 1
    }
}

# TACTIC:DEPOSIT:CREATE
#
# Creates a new DEPOSIT tactic.

order define TACTIC:DEPOSIT:CREATE {
    title "Create Tactic: Deposit Money"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Amount:" -for amount
        text amount 
        label "dollars"

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare amount   -toupper   -required -type money
    prepare priority -tolower             -type ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parm dict
    set parms(tactic_type) DEPOSIT

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:DEPOSIT:UPDATE
#
# Updates existing DEPOSIT tactic.

order define TACTIC:DEPOSIT:UPDATE {
    title "Update Tactic: Deposit Money"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_DEPOSIT -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Amount:"
        text amount
        label "dollars"
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id          -required -type tactic
    prepare amount    -toupper -required -type money

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType DEPOSIT $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}




