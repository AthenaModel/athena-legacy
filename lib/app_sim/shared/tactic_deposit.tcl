#-----------------------------------------------------------------------
# TITLE:
#    tactic_deposit.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, DEPOSIT
#
#    A DEPOSIT tactic deposits money from cash-on-hand to cash-reserve.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tactic define DEPOSIT "Deposit Money" {actor} {
    #-------------------------------------------------------------------
    # Instance Variables

    variable amount  ;# Amount of money to deposit

    # Transient Data
    variable trans

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set amount 0.0

        set trans(amount) 0.0

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    # No special SanityCheck is required.

    method narrative {} {
        return "Deposit \$[moneyfmt $amount] to the cash reserve."
    }

    # obligate coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resources
    #
    # Obligates the money to be spent: whatever remains, up to the
    # requested amount.
    #
    # NOTE: DEPOSIT never executes on lock.

    method obligate {coffer} {
        assert {[strategy ontick]}
        
        # FIRST, retrieve relevant data.
        let cash_on_hand [$coffer cash]

        # NEXT, if there's no cash at all we can't deposit any.
        if {$amount > 0.0 && $cash_on_hand == 0.0} {
            return 0
        }

        # NEXT, get the actual amount to deposit.
        let trans(amount) {min($cash_on_hand, $amount)}

        # NEXT, obligate it.
        $coffer deposit $trans(amount)

        return 1

    }

    method execute {} {
        cash deposit [my agent] $trans(amount)

        sigevent log 2 tactic "
            DEPOSIT: [my agent] deposits \$[moneyfmt $trans(amount)] to reserve.
        " [my agent]
    }
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:DEPOSIT:UPDATE
#
# Updates existing DEPOSIT tactic.

order define TACTIC:DEPOSIT:UPDATE {
    title "Update Tactic: Deposit Money"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Amount:" -for amount
        text amount
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required           -oneof [tactic::DEPOSIT ids]
    prepare amount     -required -toupper  -type money

    returnOnError -final

    # NEXT, get the tactic
    set tactic [tactic get $parms(tactic_id)]

    # NEXT, update the tactic, saving the undo script
    set undo [$tactic update_ {amount} [array get parms]]

    # NEXT, modify the tactic
    setundo $undo
}





