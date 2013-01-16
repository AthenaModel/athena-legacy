#-----------------------------------------------------------------------
# TITLE:
#    tactic_withdraw.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): WITHDRAW(amount) tactic
#
# This module defines the WITHDRAW tactic, which allows an actor to
# withdraw a sum of money from his cash reserve.   The reserve is allowed to
# be negative; thus, WITHDRAW allows the actor to "borrow" money
# (though from whom is unclear).
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Tactic: WITHDRAW

tactic type define WITHDRAW {amount} actor {
    typemethod narrative {tdict} {
        dict with tdict {}
        return "Withdraw \$[moneyfmt $amount] from the cash reserve."
    }

    typemethod execute {tdict} {
        dict with tdict {}
        
        cash withdraw $owner $amount

        sigevent log 2 tactic "
            WITHDRAW: $owner transfers \$[moneyfmt $amount] 
            from reserve to cash-on-hand.
        " $owner

        return 1
    }
}

# TACTIC:WITHDRAW:CREATE
#
# Creates a new WITHDRAW tactic.

order define TACTIC:WITHDRAW:CREATE {
    title "Create Tactic: Spend Money"

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
    set parms(tactic_type) WITHDRAW

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:WITHDRAW:UPDATE
#
# Updates existing WITHDRAW tactic.

order define TACTIC:WITHDRAW:UPDATE {
    title "Update Tactic: Spend Money"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_WITHDRAW -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Amount:"
        text amount
        label "dollars"
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id        -required -type tactic
    prepare amount    -toupper -required -type money

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType WITHDRAW $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}




