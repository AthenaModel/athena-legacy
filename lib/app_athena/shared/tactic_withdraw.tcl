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

    variable mode    ;# ALL, EXACT, UPTO, PERCENT or BORROW
    variable amount  ;# Amount of money to withdraw
    variable percent ;# Percent of money to withdraw if mode is PERCENT

    # Transient data
    variable trans

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set mode    ALL
        set amount  0.0
        set percent 0.0

        set trans(amount) 0.0

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    # No special SanityCheck is required.

    method narrative {} {
        set amt [moneyfmt $amount]

        switch -exact -- $mode {
            ALL {
                return "Withdraw all money from cash reserve."
            }

            EXACT {
                return "Withdraw \$$amt from cash reserve."
            }

            UPTO {
                return "Withdraw up to \$$amt from cash reserve."
            }

            PERCENT {
                return "Withdraw $percent% of cash reserve."
            }

            BORROW {
                return "Withdraw \$$amt from cash reserve, borrowing if necessary."
            }

            default {
                error "Invalid mode: \"$mode\""
            }
        }
    }

    # ObligateResources coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resources
    #
    # Obligates the money to be withdrawn.  Note that cash_reserve is
    # allowed to go negative.
    #
    # NOTE: WITHDRAW never executes on lock.

    method ObligateResources {coffer} {
        assert {[strategy ontick]}

        # FIRST, retrieve the current reserve amount
        let cash_reserve [$coffer reserve]
        set withdrawal 0.0

        # NEXT, depending on mode, try to withdraw money
        switch -exact -- $mode {
            ALL {
                if {$cash_reserve > 0.0} {
                    set withdrawal $cash_reserve
                }
            }

            EXACT {
                # This is the only one that can fail
                if {[my InsufficientCash $cash_reserve $amount]} {
                    return
                }

                set withdrawal $amount
            }

            UPTO {
                let withdrawal {max(0.0, min($cash_reserve, $amount))}
            }

            PERCENT {
                if {$cash_reserve > 0.0} {
                    let withdrawal {double($percent/100.0) * $cash_reserve}
                }
            }

            BORROW {
                set withdrawal $amount
            }

            default {
                error "Invalid mode: \"$mode\""
            }
        }

        # NEXT, get the actual amount of the withdrawal
        set trans(amount) $withdrawal

        # NEXT, obligate it
        $coffer withdraw $trans(amount)
    }

    method execute {} {
        cash withdraw [my agent] $trans(amount)

        sigevent log 2 tactic "
            WITHDRAW: [my agent] withdraws \$[moneyfmt $trans(amount)] from reserve.
        " [my agent]
    }
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:WITHDRAW
#
# Updates existing WITHDRAW tactic.

order define TACTIC:WITHDRAW {
    title "Tactic: Withdraw Money"
    options -sendstates PREP

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Mode:"   -for mode
        selector mode {
            case ALL "Withdraw all available money from cash reserve" {}

            case EXACT "Withdraw exactly this much from cash reserve" {
                rcc "Amount:" -for amount
                text amount
            }

            case UPTO "Withdraw up to this much from cash reserve" {
                rcc "Amount:" -for amount
                text amount
            }

            case PERCENT "Withdraw this percentage of cash reserve" {
                rcc "Percent:" -for percent
                text percent
                label "%"
            }

            case BORROW "Withdraw from cash reserve, borrowing if necessary" {
                rcc "Amount:" -for amount
                text amount
            }
        }
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic::WITHDRAW

    returnOnError

    # NEXT, get the tactic
    set tactic [tactic get $parms(tactic_id)]

    prepare mode    -toupper -selector
    prepare amount  -toupper -type money
    prepare percent -toupper -type rpercent

    returnOnError 

    # NEXT, do cross checks
    fillparms parms [$tactic view]

    if {$parms(mode) ne "PERCENT" &&
        $parms(mode) ne "ALL"     &&
        $parms(amount) == 0.0} {
            reject amount "You must specify an amount > 0.0"
    }

    if {$parms(mode) eq "PERCENT" && $parms(percent) == 0.0} {
        reject percent "You must specify a percent > 0.0"
    }

    returnOnError -final

    # NEXT, update the tactic, saving the undo script
    set undo [$tactic update_ {mode amount percent} [array get parms]]

    # NEXT, modify the tactic
    setundo $undo
}






