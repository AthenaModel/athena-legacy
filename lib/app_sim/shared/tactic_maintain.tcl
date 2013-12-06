#-----------------------------------------------------------------------
# TITLE:
#    tactic_spend.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, SPEND
#
#    A SPEND tactic spends cash-on-hand to particular economic sectors.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tactic define MAINTAIN "Maintain Infrastructure" {actor} {
    #-------------------------------------------------------------------
    # Instance Variables

    variable mode    ;# ALL, EXACT, UPTO, PERCENT or EXCESS 
    variable level   ;# Desired level of repair as a percentage
    variable amount  ;# Amount of money if mode is SOME
    variable percent ;# Percent of money to spend if mode is PERCENT
    variable nlist   ;# List of nbhoods in which to spend to maintain

    # Transient Data
    variable trans

    
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set mode    ALL
        set level   100.0
        set amount  0.0
        set percent 0.0
        set nlist   [gofer::NBHOODS blank]

        set trans(amount) 0.0

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    method SanityCheck {errdict} {
        # nlist
        if {[catch {gofer::NBHOODS validate $nlist} result]} {
            dict set errdict nlist $result
        }

        return [next $errdict]
    }

    method narrative {} {
        set ntext [gofer::NBHOODS narrative $nlist]
        set atext [moneyfmt $amount]
        set ltext [format "%.1f%%" $level]
        set ptext [format "%.1f%%" $percent]
        set anarr "\$$atext of cash-on-hand, but not more than is required"
        set lnarr "to maintain at least $ltext of the total production capacity"
        set pnarr "$ptext of cash-on-hand, but not more than is required"
        set enarr "of the infrastructure owned in $ntext"

        set text ""
        switch -exact -- $mode {
            ALL {
                return "Spend all remaining cash-on-hand $lnarr $enarr."
            }

            EXACT {
                return "Spend exactly $anarr $lnarr $enarr."
            }

            UPTO {
                return "Spend up to $anarr $lnarr $enarr."
            }

            PERCENT {
                return "Spend $pnarr $lnarr $enarr."
            }

            EXCESS {
                return "Spend anything in excess of $anarr $lnarr $enarr."
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
    # Obligates the money to be spent.

    method ObligateResources {coffer} {
        # FIRST, retrieve relevant data.
        let cash [$coffer cash]
        set owner [my agent]

        let lfrac {$level/100.0}
        set spend 0.0
        set max_spend 0.0

        # NEXT, compute the upper limit of spending which is either one
        # weeks worth of repair cost, or just enough money to bring all
        # plants to the requested repair level.
        foreach n [gofer::NBHOODS eval $nlist] {
            let max_spend {$max_spend + [plant repaircost $n $owner $lfrac]}
        }

        let amt {min($amount, $max_spend)}

        # NEXT, depending on mode, try to obligate money
        switch -exact -- $mode {
            ALL {
                let spend {min($cash, $max_spend)}
            }

            EXACT {
                # This is the only one than could give rise to an error and
                # only if we are on a tick
                if {[my InsufficientCash $cash $amt]} {
                    return
                }

                set spend $amt
            }

            UPTO {
                let spend {max(0.0, min($cash, $amt))}
            }

            PERCENT {
                if {$cash > 0.0} {
                    let spend \
                        {min(double($percent/100.0) * $cash, $max_spend)}
                }
            }

            EXCESS {
                let spend {max(0.0, min($cash-$amount, $max_spend))}
            }

            default {
                error "Invalid mode: \"$mode\""
            }

        }
        
        set trans(amount) $spend

        # NEXT, obligate it.
        $coffer spend $trans(amount)

        return 1
    }
 
    method execute {} {
        set owner [my agent]

        cash spend $owner MAINTAIN $trans(amount)

        set nbs   [gofer::NBHOODS eval $nlist]
        set ntext [gofer::NBHOODS narrative $nlist]

        sigevent log 2 tactic "
            MAINTAIN: Actor {actor:$owner} spends
            \$[moneyfmt $trans(amount)] to maintain manufacturing
            infrastructure in $ntext.
        " $owner {*}$nbs

        let lfrac {$level/100.0}
        plant repair $owner $nbs $trans(amount) $lfrac
    }
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:MAINTAIN
#
# Updates existing SPEND tactic.

order define TACTIC:MAINTAIN {
    title "Tactic: Maintain Infrastructure"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rc "Maintain In:" -span 2

        rcc "Nbhoods:" -for nlist -span 3
        gofer nlist -typename gofer::NBHOODS

        rcc "Amount:"   -for mode
        selector mode {
            case ALL "All remaining cash-on-hand" {}

            case EXACT "Exactly this much" {
                c "" -for amount
                text amount
            }

            case UPTO "Up to this much" {
                c "" -for amount
                text amount
            }

            case PERCENT "Percentage of cash-on-hand" {
                cc "" -for percent
                text percent
                c
                label "%"
            }

            case EXCESS "Excess of cash-on-hand" {
                c "" -for amount
                text amount
            }
        }
        
        rcc "Maximum:" -for level -span 2
        text level
        label "% of capacity."
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic::MAINTAIN
    returnOnError

    set tactic [tactic get $parms(tactic_id)]

    prepare nlist
    prepare mode    -toupper  -selector
    prepare amount  -type money
    prepare percent -type rpercent
    prepare level   -type rpercent

    returnOnError

    # NEXT, check cross-constraints
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
    setundo [$tactic update_ {
        nlist mode amount percent level
    } [array get parms]]
}





