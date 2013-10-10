#-----------------------------------------------------------------------
# TITLE:
#    tactic_deploy.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, DEPLOY
#
#    A DEPLOY tactic deploys force or organization group personnel into
#    neighborhoods, without or without reinforcement.
#
# TBD:
#    * We might want to use a gofer to choose the group(s) to deploy
#    * We might want to use a gofer to choose the nbhood(s) to deploy in.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tactic define DEPLOY "Deploy Personnel" {actor} -onlock {
    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    variable g           ;# A FRC or ORG group
    variable mode        ;# ALL or SOME
    variable personnel   ;# Number of personnel.
    variable reinforce   ;# Reinforce each week flag
    variable nlist       ;# Neighborhoods to deploy in

    # Other State Variables
    #
    # These are cleared on update.

    variable last_tick       ;# Tick at which tactic last executed

    # Transient data
    #
    # personnel    - Dictionary, troops by neighborhood.
    # cost         - Amount of cash obligated
    variable trans

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set g              ""
        set mode           ALL
        set personnel      0
        set reinforce      0
        set nlist          [list]
        set last_tick      ""

        # Initial state is invalid (no g, nlist)
        my set state invalid

        # Initialize transient data
        set trans(personnel) 0
        set trans(cost)      0.0

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    # reset
    #
    # On reset, clear the "last_tick".

    method reset {} {
        my set last_tick ""
        next
    }
    


    method SanityCheck {errdict} {
        # Check g
        if {$g eq ""} {
            dict set errdict g "No group selected."
        } elseif {$g ni [group ownedby [my agent]]} {
            dict set errdict g \
                "Force/organization group \"$g\" is not owned by [my agent]."
        }

        # Check nlist
        if {[llength $nlist] == 0} {
            dict set errdict nlist \
                "No neighborhood(s) specified."
        } else {
            set nbhoods [nbhood names]

            set badn [list]
            foreach n $nlist {
                if {$n ni $nbhoods} {
                    lappend badn $n
                } 
            }

            if {[llength $badn] > 0} {
                dict set errdict nlist \
                    "Non-existent neighborhood(s): [join $badn {, }]"
            }
        }

        return [next $errdict]
    }

    method narrative {} {
        if {$g eq ""} {
            set s(g) "???"
        } else {
            set s(g) $g
        }

        if {[llength $nlist] == 0} {
            set s(nlist) " ???"
        } elseif {[llength $nlist] == 1} {
            set s(nlist) " [lindex $nlist 0]"
        } else {
            set s(nlist) "s [join $nlist {, }]"
        }

        if {$mode eq "ALL"} {
            append output \
                "Deploy all of group $s(g)'s remaining personnel " \
                "into neighborhood$s(nlist)."
        } else {
            if {$reinforce} {
                set s(reinforce) "with"
            } else {
                set s(reinforce) "without"
            }

            append output \
                "Deploy $personnel of group $s(g)'s remaining personnel " \
                "into neighborhood$s(nlist) "                             \
                "$s(reinforce) reinforcement."
        }

        return $output
    }

    # obligate coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resources
    #
    # Obligates the personnel and cash required for the deployment.

    method obligate {coffer} {
        # FIRST, compute deployment; this will populate trans(personnel)
        switch -exact -- $mode {
            ALL {
                set totalTroops [my ObligateALL $coffer] 
            }

            SOME {
                set totalTroops [my ObligateSOME $coffer]
            }

            default {
                error "Invalid mode: \"$mode\""
            }
        }

        # NEXT, if none got deployed, we're done.
        if {$totalTroops == 0} {
            return 0
        }

        # NEXT, obligate the troops
        dict for {n ntroops} $trans(personnel) {
            $coffer deploy $g $n $ntroops
        }

        # NEXT, save and obligate the cost.  Note that we chose the
        # total within our budget, so there's enough money.
        set trans(cost) [expr {[group maintPerPerson $g] * $totalTroops}]

        $coffer spend $trans(cost)

        return 1

    }

    # ObligateALL coffer
    #
    # coffer   - The agent's coffer of resources
    #
    # When mode is ALL, figures out how many troops can actually be
    # deployed, and allocates them to neighborhoods.  Returns the 
    # number of troops deployed, or 0 if no troops can be deployed.

    method ObligateALL {coffer} {
        # FIRST, retrieve relevant data.
        set available     [$coffer troops $g undeployed]
        set cash          [$coffer cash]
        set costPerPerson [group maintPerPerson $g]

        # NEXT, How many troops can we afford? All of them if we
        # are locking or they are free.
        if {[strategy locking] || $costPerPerson == 0.0} {
            set troops $available
        } else {
            let maxTroops {double($cash)/$costPerPerson}

            # troops needs to be an integer.  int() truncates to
            # machine integer, not a bignum.  round() rounds to
            # a bignum; but we want to truncate.  Hence, 
            # round(floor(x)).
            let troops {round(floor(min($available,$maxTroops)))}
        }

        # NEXT, if there are no troops left, we're done.
        if {$troops == 0} {
            return 0
        }

        # NEXT, allocate troops to neighborhoods.
        set trans(personnel) [my AllocateTroops $troops]

        return $troops
    }

    # AllocateTroops troops
    #
    # troops    - The number of troops to deploy
    #
    # Allocates the troops to the nlist, and returns the resulting
    # dictionary.

    method AllocateTroops {troops} {
        set deployment [dict create]
        set num        [llength $nlist]
        let each       {$troops / $num}
        let remainder  {$troops % $num}

        set count 0
        foreach n $nlist {
            set ntroops $each

            if {[incr count] <= $remainder} {
                incr ntroops
            }

            dict set deployment $n $ntroops
        }

        return $deployment
    }

    # ObligateSOME coffer
    #
    # coffer   - The agent's coffer of resources
    #
    # When mode is SOME, figures out how many troops can actually be
    # deployed (taking the reinforcement flag and past history into
    # account) and allocates them to neighborhoods.  Returns the 
    # number of troops deployed, or 0 if no troops can be deployed.

    method ObligateSOME {coffer} {
        # FIRST, retrieve relevant data.
        set tactic_id     [my id]
        set available     [$coffer troops $g undeployed]
        set cash          [$coffer cash]

        # NEXT, determine if we need to take past deployments into 
        # account.  If we are deploying all remaining, or we are 
        # reinforcing, or if the tactic has not yet executed, we don't.
        #
        # NOTE: last_tick is cleared by the update mutator.  If they edit
        # the tactic after it's executed, it's like it is a new
        # tactic.

        if {[strategy ontick]} {
            if {$reinforce       || 
                $last_tick eq "" || 
                $last_tick < [simclock now] - 1
            } {
                # This is a new deployment, or we are reinforcing.
                set alreadyDeployed 0
                set troops $personnel
            } else {
                # This is an old deployment, and we are not reinforcing.
                # See how many we actually have.
                # TBD: What should happen if we get down to zero?  Should
                # we continue "successfully" deploying 0?
                rdb eval {
                    SELECT count(*)                             AS alreadyDeployed,
                           coalesce(sum(personnel), $personnel) AS troops
                           FROM working_deploy_tng
                           WHERE tactic_id = $tactic_id
                } {}
            }

            if {$troops * [group maintPerPerson $g] > $cash} {
                return 0
            }
        } else {
            # On lock, it's a new deployment and they get what they want.
            set alreadyDeployed 0
            set troops $personnel
        }

        # NEXT, If there are insufficient troops or insufficent funds
        # available, we're done.
        if {$troops > $available} {
            return 0
        }

        # NEXT, allocate troops to neighborhoods.
        if {$alreadyDeployed} {
            # We're not reinforcing; use the remains of the old deployment.
            set trans(personnel) [rdb eval {
                SELECT n, personnel 
                FROM working_deploy_tng
                WHERE tactic_id=$tactic_id
            }]
        } else {
            set trans(personnel) [my AllocateTroops $troops]
        }

        return $troops
    }


    method execute {} {
        # FIRST, Pay the maintenance cost.
        cash spend [my agent] DEPLOY $trans(cost)

        # NEXT, deploy the troops to those neighborhoods.
        dict for {n ntroops} $trans(personnel) {
            personnel deploy [my id] $n $g $ntroops

            sigevent log 2 tactic "
                DEPLOY: Actor {actor:[my agent]} deploys $ntroops {group:$g} 
                personnel to {nbhood:$n}
            " [my agent] $n $g
        }
    }

}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:DEPLOY:UPDATE
#
# Updates existing DEPLOY tactic.

order define TACTIC:DEPLOY:UPDATE {
    title "Update Tactic: Deploy Personnel"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID:" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Group:" -for g
        enum g -listcmd {tactic groupsOwnedByAgent $tactic_id}

        rcc "Mode:" -for mode
        selector mode {
            case SOME "Deploy some of the group's personnel" {
                rcc "Personnel:" -for personnel
                text personnel

                rcc "Reinforce?" -for reinforce
                yesno reinforce -defvalue 0
            }

            case ALL "Deploy all of the group's remaining personnel" {}
        }

        rcc "In Neighborhoods:" -for nlist
        nlist nlist
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -oneof [tactic::DEPLOY ids]
    returnOnError

    # NEXT, get the tactic
    set tactic [tactic get $parms(tactic_id)]

    prepare g                    -oneof [group ownedby [$tactic agent]]
    prepare mode       -toupper  -selector
    prepare personnel  -num      -type ipositive
    prepare reinforce            -type boolean
    prepare nlist      -toupper  -listof nbhood

    returnOnError

    # NEXT, do the cross checks
    fillparms parms [$tactic view]

    if {$parms(mode) eq "SOME" && $parms(personnel) == 0} {
        reject personnel "Positive personnel required when mode is SOME"
    }

    returnOnError -final

    # NEXT, update the tactic, saving the undo script, and clearing
    # historical state data.

    set undo [$tactic update_ {
        g mode personnel reinforce nlist
    } [array get parms]]

    # NEXT, save the undo script
    setundo $undo
}





