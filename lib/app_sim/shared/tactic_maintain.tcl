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

    variable rmode   ;# Repair mode: FULL, UPTO
    variable level   ;# Desired level of repair if mode is UPTO
    variable amount  ;# Max amount of money to spend regardless of rmode
    variable percent ;# Percent of money to spend if mode is PERCENT
    variable nlist   ;# List of nbhoods in which to maintain plants

    # Transient Data
    variable trans

    
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set rmode   FULL
        set level   0.0
        set amount  0.0
        set percent 0.0
        set nlist   [gofer::NBHOODS blank]

        my set state invalid

        set trans(amount)   0.0
        set trans(nlist)    [list]
        set trans(repairs)  [dict create]
        set trans(repaired) 0

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

        # owner must not be automatically maintaining infrastructure
        set owner [my agent]

        if {[actor get $owner auto_maintain]} {
            set errmsg "$owner has auto maintenance enabled."
            dict set errdict owner $errmsg
        }

        return [next $errdict]
    }

    method narrative {} {
        set ntext [gofer::NBHOODS narrative $nlist]
        set atext [moneyfmt $amount]
        set ltext [format "%.1f%%" $level]
        set anarr "Spend no more than \$$atext of cash-on-hand to maintain"
        set enarr "capacity of the infrastructure owned in $ntext"

        set text ""
        switch -exact -- $rmode {
            FULL {
                return "$anarr full $enarr."
            }

            UPTO {
                return "$anarr at least $ltext $enarr."
            }

            default {
                error "Invalid mode: \"$mode\""
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
        # FIRST, retrieve relevant data.
        set cash  [$coffer cash]
        set owner [my agent]

        # Only going to deal in whole dollars
        let cash {entier($cash)}

        # NEXT, max amount that can possibly be spent is either the
        # amount of cash on hand or the limiting amount
        let maxAmt {min($cash, $amount)}

        # NEXT, get nbhoods, the gofer may retrieve an empty list
        set trans(nlist) [my GetNbhoods]

        if {[llength $trans(nlist)] == 0} {
            return 0
        }

        # NEXT, the maximum possible amount of repair that could be
        # performed in one tick
        set rTime [parmdb get plant.repairtime]
        if {$rTime == 0.0} {
            set maxDeltaRho 1.0
        } else {
            let maxDeltaRho {1.0/$rTime}
        }

        # NEXT, the maximum repair level is either fully repaired or
        # the level of repair the user has requested
        # Note: This will need to be changed if more repair modes are
        # added
        set maxRho 1.0

        if {$rmode eq "UPTO"} {
            let maxRho {$level/100.0}
        }

        # NEXT, set up to book keep the repairs and their cost
        set trans(repairs) [dict create]
        set costProfile    [dict create]
        set totalCost 0.0
         
        # NEXT, go through each neighborhood that has plants owned by
        # this actor and compute the amount and cost of repairs
        foreach n $trans(nlist) {
            # FIRST, the current level of repair at the start of the tick
            set currRho [plant get [list $n $owner] rho]

            # NEXT, the amount of repair is the difference between
            # the maximum and the current levl
            let deltaRho {$maxRho - $currRho}

            # NEXT, if the current level of repair is already greater 
            # than the max, nothing to do
            if {$deltaRho <= 0.0} {
                continue
            }

            # NEXT, constrain the actual amount of repair by the maximum that
            # could be done in this tick
            let actualDeltaRho {min($deltaRho, $maxDeltaRho)}

            # NEXT, see if there's been any work done to these plants during
            # strategy execution
            let unrepaired {
                ($currRho+$actualDeltaRho) - [$coffer plants $n]
            }

            # NEXT, constrain the amount of repair further by whatever is
            # left unrepaired
            let actualDeltaRho {min($actualDeltaRho, $unrepaired)}

            # NEXT, these plants may have already had the maximum amount
            # of repair done to them
            if {$actualDeltaRho == 0.0} {
                continue
            }
                    
            # NEXT, determine the cost and bookkeep it, the actor may
            # not have enough money to pay for it all
            set nCost [plant repaircost $n $owner $actualDeltaRho]
            dict set costProfile $n $nCost
            let totalCost {$totalCost + $nCost}
        }

        # NEXT, if no cash, tactic fails
        if {$totalCost > 0.0 && $cash == 0} {
            my Fail CASH "Need \$[moneyfmt $totalCost] for repairs, have none."
            return 0
        }

        set totalSpent 0.0
        # NEXT, use cost profile to determine the actual repair done
        foreach n [dict keys $costProfile] {
            # NEXT, the share of the cost in this neighborhood and the
            # actual amount spent
            set spend 0.0

            if {$totalCost > 0.0} {
                let share {[dict get $costProfile $n] / $totalCost}
                let spend {$share * min($totalCost, $maxAmt)}
                let totalSpent {$totalSpent + $spend}
            }

            # NEXT, the actual amount of repair done
            set dRho [plant repairlevel $n $owner $spend]
            dict set trans(repairs) $n $dRho
            $coffer repair $n $dRho
        }

        # NEXT, obligate cash
        $coffer spend $totalSpent
        set trans(amount) $totalSpent

        # NEXT, if there's no repair cost, no repairs are needed
        if {$totalCost == 0.0} {
            set trans(repaired) 1
        }

        return 1
    }
 
    method GetNbhoods {} {
        set nbhoods [gofer::NBHOODS eval $nlist]
        set owner [my agent]

        if {[llength $nbhoods] == 0} {
            my Fail WARNING "Gofer retrieved no neighborhoods."
            return ""
        }

        # NEXT, filter out any neighborhoods that have no infrastructure
        # owned by the actor
        set nbhoodsWithPlants [rdb eval {
            SELECT n FROM plants_na
            WHERE a = $owner
        }]

        set inNbhoods [list]

        foreach n $nbhoods {
            if {$n in $nbhoodsWithPlants} {
                lappend inNbhoods $n
            }
        }

        if {[llength $inNbhoods] == 0} {
            my Fail WARNING \
                "$owner has no infrastructure in the retrieved neighborhoods."
        }

        return $inNbhoods
    }

    method execute {} {
        set owner [my agent]

        cash spend $owner MAINTAIN $trans(amount)

        set nbhoods [gofer::NBHOODS eval $nlist]
        set ntext   [gofer::NBHOODS narrative $nlist]

        if {$trans(repaired)} {
            sigevent log 2 tactic "
                MAINTAIN: Actor {actor:$owner} spends
                \$[moneyfmt $trans(amount)] since any
                infrastructure owned in $ntext have already 
                had the maximum amount of repair.
            " $owner {*}$nbhoods

        } else {
            sigevent log 2 tactic "
                MAINTAIN: Actor {actor:$owner} spends
                \$[moneyfmt $trans(amount)] to maintain any 
                infrastructure owned in $ntext.
            " $owner {*}$nbhoods
        }

        foreach n [dict keys $trans(repairs)] {
            plant repair $owner $n [dict get $trans(repairs) $n]
        }
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

        rc "Maintain In:" -span 3 

        rcc "Nbhoods:" -for nlist -span 4 
        gofer nlist -typename gofer::NBHOODS

        rcc "A Capacity of:" -for rmode 
        selector rmode {
            case FULL "100%" {}

            case UPTO "at least" {
                cc "" -for level 
                text level
                c 
                label "%"
            }
        }
        
        rcc "Using a max of:" -for amount -span 3
        text amount
        label "cash-on-hand."
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic::MAINTAIN
    returnOnError

    set tactic [tactic get $parms(tactic_id)]

    prepare nlist
    prepare rmode   -toupper  -selector
    prepare amount  -type money
    prepare level   -type rpercent

    returnOnError

    # NEXT, check cross-constraints
    fillparms parms [$tactic view]

    if {$parms(rmode) eq "UPTO" && $parms(level) == 0.0} {
        reject level "You must specify a capacity level > 0.0"
    }

    returnOnError -final

    # NEXT, update the tactic, saving the undo script
    setundo [$tactic update_ {
        nlist rmode amount level
    } [array get parms]]
}





