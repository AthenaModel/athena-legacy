#-----------------------------------------------------------------------
# TITLE:
#    tactic_withdraw.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, WITHDRAW
#
#    A WITHDRAW tactic transfers money from cash-reserver to cash-on-hand.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tactic define WITHDRAW "Withdraw Money" {actor} {
    #-------------------------------------------------------------------
    # Instance Variables

    variable amount  ;# Amount of money to withdraw

    #-------------------------------------------------------------------
    # Constructor

    # constructor ?block_?
    #
    # block_  - The block that owns the tactic
    #
    # Creates a new tactic for the given block.

    constructor {{block_ ""}} {
        next $block_
        set amount 0.0
    }

    #-------------------------------------------------------------------
    # Operations

    # No special SanityCheck is required.

    method narrative {} {
        return "Withdraw \$[moneyfmt $amount] from the cash reserve."
    }

    # obligate coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resources
    #
    # Obligates the money to be withdrawn.  Note that cash_reserve is
    # allowed to go negative.
    #
    # NOTE: WITHDRAW never executes on lock.

    method obligate {coffer} {
        assert {[strategy ontick]}

        $coffer withdraw $amount

        return 1
    }

    method execute {} {
        cash withdraw [my agent] $amount

        sigevent log 2 tactic "
            WITHDRAW: [my agent] withdraws \$[moneyfmt $amount] from reserve.
        " [my agent]
    }
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:WITHDRAW:UPDATE
#
# Updates existing WITHDRAW tactic.

order define TACTIC:WITHDRAW:UPDATE {
    title "Update Tactic: Withdraw Money"
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
    prepare tactic_id  -required           -oneof [tactic::WITHDRAW ids]
    prepare amount     -required -toupper  -type money

    returnOnError -final

    # NEXT, get the tactic
    set tactic [tactic get $parms(tactic_id)]

    # NEXT, update the tactic, saving the undo script
    set undo [$tactic update_ {amount} [array get parms]]

    # NEXT, modify the tactic
    setundo $undo
}





