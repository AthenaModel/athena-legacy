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

    variable mode    ;# Spending mode: CASH or EFFORT
    variable num     ;# Number of plants to build
    variable amount  ;# Amount of money to spend depending on mode
    variable percent ;# Percent of money to spend if mode is PERCENT
    variable n       ;# Nbhood in which to build plants
    variable done    ;# A flag indicating the build is complete

    # Transient Data
    variable trans
    
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set mode    CASH
        set amount  0
        set num     1
        set percent 0
        set n       {}  
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
        } elseif {$n ni [nbhood local names]} {
            dict set errdict n "Neighborhood \"$n\" is not local, should be."
        }

        # Non-zero work-weeks if mode is effort
        if {$mode eq "EFFORT" && $num == 0} {
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
            EFFORT {
                return \
                  "Use up to all remaining cash-on-hand each week to fund $num work-weeks each week in $s(n)."
            }

            CASH {
                return \
                    "Use at most $s(amount)/week to build infrastructure in $s(n)."
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
        set cash [$coffer cash]
        if {$cash == 0.0} {
            my Fail CASH "Need money to build, have none."
            return 0
        }

        set owner [my agent]
        set spend 0.0

        switch -exact -- $mode {
            EFFORT {
                set cost [plant buildcost $n $owner $num]
                let spend {min($cost, $cash)}
            }

            CASH {
                let spend {min($amount, $cash)}
            }

            default {
                error "Invalid mode: \"$mode\"."
            }
        }

        $coffer spend $spend
        set trans(amount) $spend

        return 1

    }
 
    method execute {} {
        set owner [my agent]

        cash spend $owner BUILD $trans(amount)

        lassign [plant build $n $owner $trans(amount)] old new

        if {$mode eq "EFFORT"} {
            sigevent log 2 tactic "
                BUILD: Actor {actor:$owner} spends
                \$[moneyfmt $trans(amount)] in an effort to 
                construct $num infrastructure plant(s) in $n. 
                $old plant(s) were worked on, $new plant(s) started.
            " $owner $n
        } elseif {$mode eq "CASH"} {
            sigevent log 2 tactic "
                BUILD: Actor {actor:$owner} spends
                \$[moneyfmt $trans(amount)] in an effort to 
                construct as much infrastructure plant(s) in $n as possible. 
                $old plant(s) were worked on, $new plant(s) started.
            " $owner $n
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
        localn n

        rcc "Construction Mode:" -for mode
        selector mode {
            case EFFORT "Use as much cash-on-hand it takes to work up to" {
                rcc "Number:" -for num
                text num 
                label "work weeks each week."
            }

            case CASH "Use up to this amount of cash-on-hand" {
               rcc "Amount:" -for amount
               text amount
               label "dollars"
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






