#-----------------------------------------------------------------------
# TITLE:
#    tactic_build.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, BUILD
#
#    A BUILD tactic spends cash-on-hand to build new goods sector
#    production infrastructure
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tactic define BUILD "Build Infrastructure" {actor} {
    #-------------------------------------------------------------------
    # Instance Variables

    variable mode    ;# Spending mode: ALL, EXACT or PERCENT
    variable num     ;# Number of plants to build
    variable amount  ;# Amount of money to spend depending on mode
    variable percent ;# Percent of money to spend if mode is PERCENT
    variable n       ;# Nbhood in which to build plants
    variable bid     ;# Build ID, used internally
    variable done    ;# A flag indicating the build is complete

    # Transient Data
    variable trans
    
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set mode    ALL
        set amount  0
        set num     1
        set percent 0
        set n       {}  
        set bid     0
        set done    0

        my set state invalid

        set trans(amount)   0.0

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    method SanityCheck {errdict} {
        # Neighborhood
        if {$n eq ""} {
            dict set errdict n "No neighborhood selected."
        } elseif {$n ni [nbhood names]} {
            dict set errdict n "No such neighborhood: \"$n\"."
        }

        # Non-zero number of plants
        if {$num == 0} {
            dict set errdict num "Must specify > 0 plants to build."
        }

        return [next $errdict]
    }

    method narrative {} {
        set s(n)       [link make nbhood $n]
        set s(amount)  "\$[commafmt $amount]"
        set s(percent) [format %.1f%% $percent]
        set s(num)     [expr {$num == 1 ? "1 plant" : "$num plants"}]

        switch -exact -- $mode {
            ALL {
                return \
                  "Build $s(num) in $s(n) using up to remaining cash-on-hand each week."
            }

            EXACT {
                return "Build $s(num) in $s(n) using at most $s(amount)/week."
            }

            PERCENT {
                return \
                    "Build $s(num) in $s(n) using at most $s(percent) of cash-on-hand per week."
            }

            default {
                error "Invalid mode: \"$mode\"."
            }
        }
    }

    # ObligateResources coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resourcemaxAmts
    #
    # Obligates the money to be spent.

    method ObligateResources {coffer} {
        # FIRST, if building is complete no cost
        if {$done} {
            return 1
        }

        set cash [$coffer cash]

        set cost [plant buildcost $num $bid]
        set spend 0.0

        switch -exact -- $mode {
            ALL {
                let spend {min($cost, $cash)}
            }

            EXACT {
                let spend {min($cost, $amount)}
            }

            PERCENT {
                let spend {min($cost, $cash * $percent)}
            }

            default {
                error "Invalid mode: \"$mode\"."
            }
        }

        if {$cost > 0.0 && $cash == 0.0} {
            my Fail CASH "Need \$[moneyfmt $cost] to build, have none."
            return 0
        }

        set trans(amount) $spend

        return 1

    }
 
    method execute {} {
        # FIRST, if building is complete nothing to do
        if {$done} {
            return 1
        }

        set owner [my agent]

        cash spend $owner BUILD $trans(amount)

        if {$bid == 0} {
            set bid [plant startbuild $n $owner $num]
        }

        if {[plant endbuildtime $bid] == [simclock now]} {
            sigevent log 2 tactic "
                BUILD: Actor {actor:$owner} has finished building
                $num infrastructure plant(s) in $n.
            " $owner $n

            set done 1

        } else { 

            sigevent log 2 tactic "
                BUILD: Actor {actor:$owner} spends
                \$[moneyfmt $trans(amount)] to construct $num
                infrastructure plant(s) in $n.
            " $owner $n
    
            plant build $bid $trans(amount)
        }
    }
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:BUILD
#
# Updates existing BUILD tactic.

order define TACTIC:BUILD {
    title "Tactic: Build Infrastructure"
    options -sendstates PREP

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Nbhood:" -for n 
        nbhood n

        rcc "Number of Plants:" -for num
        text num -defvalue 1

        rcc "Mode:" -for mode
        selector mode {
            case ALL "Use up to as much cash-on-hand as possible" {}

            case EXACT "Use no more than an exact amount of cash-on-hand" {
                rcc "Amount:" -for amount
                text amount
                label "dollars"
            }

            case PERCENT "Use no more than a percentage of cash-on-hand" {
               rcc "Percentage:" -for percent
               text percent
               label "%"
            }
        }
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic::BUILD
    returnOnError

    set tactic [tactic get $parms(tactic_id)]

    prepare n
    prepare mode    -toupper  -selector
    prepare amount  -type money
    prepare percent -type rpercent
    prepare num     -type iquantity

    returnOnError

    # NEXT, check cross-constraints
    fillparms parms [$tactic view]

    if {$parms(num) == 0} {
        reject num "You must specify a number of plants > 0."
    }

    if {$parms(mode) eq "PERCENT" && $parms(percent) == 0.0} {
        reject percent "You must specify a percentage of cash > 0.0"
    }

    returnOnError -final

    # NEXT, update the tactic, saving the undo script
    setundo [$tactic update_ {
        n mode amount num percent
    } [array get parms]]
}






