#-----------------------------------------------------------------------
# TITLE:
#    tactic_attroe.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, ATTROE
#
#    This module implements the Attacking ROE tactic.
#    Every force group has an attacking ROE of DO_NOT_ATTACK by
#    default with respect to every other force group.  This default 
#    is overridden by the ATTROE tactic, which inserts an entry into 
#    the attroe_nfg table on execution.  The override lasts until the next
#    strategy execution tock.
#
#    The tactic never executes on lock.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
tactic define ATTROE "Attacking ROE" {actor} {
    #-------------------------------------------------------------------
    # Type Methods

    # reset
    #
    # Resets all attack ROEs at the beginning of the tock.

    typemethod reset {} {
        rdb eval { DELETE FROM attroe_nfg }
    }
    
    # refund
    #
    # Reimburses the owning actor for unused attacks.  This should
    # be called at the end of the AAM assessment.

    typemethod refund {} {
        # FIRST, reimburse the owning actor for the unused attacks
        rdb eval {
            SELECT F.a                                         AS a,
                   F.attack_cost * (A.max_attacks - A.attacks) AS extra
            FROM attroe_nfg AS A
            JOIN frcgroups AS F ON (A.f = F.g)
            WHERE F.attack_cost > 0
            AND   A.max_attacks > A.attacks
        } {
            log normal attroe "Return \$$extra to $a"
            cash refund $a ATTROE $extra
        }
    }


    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    variable f           ;# The attacking force group, owned by the agent.
    variable g           ;# The defending force group
    variable n           ;# The neighborhood.
    variable roe         ;# The ROE; type depends on whether f is uniformed
                          # or not.
    variable attacks     ;# Maximum number of attacks per week.

    # Transient data
    variable trans

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Initialize as a tactic bean.
        next

        # NEXT, Initialize state variables
        set f       ""
        set g       ""
        set n       ""
        set roe     DO_NOT_ATTACK
        set attacks 1

        # NEXT, Initial state is invalid (no f, g, n)
        my set state invalid

        # NEXT, initialize transient variables
        set trans(cost) 0.0

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    method SanityCheck {errdict} {
        set fUniformed [frcgroup get $f uniformed]
        set gUniformed [frcgroup get $g uniformed]

        # Check f
        if {$f eq ""} {
            dict set errdict f "No group selected."
        } elseif {[frcgroup get $f a] ne [my agent]} {
            dict set errdict f \
                "[my agent] does not own a force group called \"$f\"."
        }

        # Check g
        if {$g eq ""} {
            dict set errdict g "No group selected."
        } elseif {[catch {frcgroup validate $g} result]} {
            dict set errdict g $result
        }

        if {$fUniformed ne "" && $gUniformed ne ""} {
            if {$fUniformed} {
                if {$gUniformed} {
                    dict set errdict g \
                        "Groups \"$f\" and \"$g\" are both uniformed"
                }
            } else {
                if {!$gUniformed} {
                    dict set errdict g \
                        "Groups \"$f\" and \"$g\" are both non-uniformed"
                }
            }
        }

        # Check ROE
        if {$fUniformed ne ""} {
            if {$fUniformed} {
                if {$roe ni [eattroeuf names]} {
                    dict set errdict roe \
                        "ROE is invalid for a uniformed group: \"$roe\"."
                }
            } else {
                if {$roe ni [eattroenf names]} {
                    dict set errdict roe \
                        "ROE is invalid for a non-uniformed group: \"$roe\"."
                }
            }
        }

        # Check n
        if {[llength $n] == 0} {
            dict set errdict n "No neighborhood selected."
        } elseif {$n ni [nbhood names]} {
            dict set errdict n "Non-existent neighborhood: \"$n\""
        }


        return [next $errdict]
    }

    method narrative {} {
        let s(f) {$f ne "" ? $f : "???"}
        let s(g) {$g ne "" ? $g : "???"}
        let s(n) {$n ne "" ? $n : "???"}

        if {$attacks == 1} {
            set rate "1 time/week"
        } else {
            set rate "$attacks times/week"
        }

        if {$roe eq "DO_NOT_ATTACK"} {
            return "Group $s(f) will not attack $s(g) in $s(n)."
        } elseif {$roe eq "ATTACK"} {
            return "Group $s(f) attacks $s(g) in $s(n) up to $rate."
        } else {
            return \
                "Group $s(f) attacks $s(g) in $s(n) with ROE $roe up to $rate."
        }
    }

    # ObligateResources coffer
    #
    # coffer  - A coffer object with the owning agent's current resources
    #
    # Obligates cash required for the attacks if possible.

    method ObligateResources {coffer} {
        # FIRST, if we aren't attacking there's no cost.
        if {$roe eq "DO_NOT_ATTACK"} {
            set trans(cost) 0.0
            return
        }

        # NEXT, compute the cost; can we afford it?
        set costPerAttack [frcgroup get $f attack_cost]

        let trans(cost) {$costPerAttack * $attacks}

        if {[my InsufficientCash [$coffer cash] $trans(cost)]} {
            return
        } 

        # NEXT, yes; obligate it.
        $coffer spend $trans(cost)
    }

    method execute {} {
        # FIRST, spend the cash.
        if {$trans(cost) > 0.0} {
            cash spend [my agent] ATTROE $trans(cost)
        }

        # NEXT, create the ROE override.
        set uniformed [frcgroup get $f uniformed]
        rdb eval {
            INSERT OR REPLACE 
            INTO attroe_nfg(n,f,g,uniformed,roe,max_attacks)
            VALUES($n, $f, $g, $uniformed, $roe, $attacks);
        }

        # NEXT, log it.
        set gOwner [frcgroup get $g a]

        if {$roe eq "DO_NOT_ATTACK"} {
            sigevent log 2 tactic "
                ATTROE: Group {group:$f} will not attack {group:$g} 
                in {nbhood:$n}.
            " [my agent] $n $f $g $gOwner
        } else {
            sigevent log 2 tactic "
                ATTROE: Group {group:$f} attacks {group:$g} in {nbhood:$n} 
                with ROE $roe up to $attacks times/week.
            " [my agent] $n $f $g $gOwner
        }
    }

    #-------------------------------------------------------------------
    # Order Helpers
    #
    # These are typemethods used by the orders, below.

    # oppositeTo f
    #
    # f   - A force group
    #
    # Returns a list of the groups whose uniformed flag is opposite that
    # of f.
    #
    # TBD: SHould this be [frcgroup opposites $f]?

    typemethod oppositeTo {f} {
        if {$f eq ""} {
            return [list]
        }

        set flag [frcgroup get $f uniformed]

        return [rdb eval {
            SELECT g FROM frcgroups
            WHERE uniformed != $flag
        }]
    }

    # roeDict f
    #
    # f   - A force group
    #
    # Returns the dictionary of attacking ROE symbols and long names for
    # the given group.

    typemethod roeDict {f} {
        if {$f eq ""} {
            return [dict create]
        } elseif {[frcgroup get $f uniformed]} {
            return [eattroeuf deflist]
        } else {
            return [eattroenf deflist]
        }
    }
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:ATTROE
#
# Updates existing ATTROE tactic.

order define TACTIC:ATTROE {
    title "Tactic: Attacking ROE"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Attacking Group:" -for f
        enum f -listcmd {tactic frcgroupsOwnedByAgent $tactic_id }

        rcc "Defending Group:" -for g
        enum g -listcmd {::tactic::ATTROE oppositeTo $f}

        rcc "In Neighborhood:" -for n
        nbhood n

        rcc "ROE:" -for roe
        enumlong roe -dictcmd {::tactic::ATTROE roeDict $f}

        rcc "Max Attacks" -for attacks
        text attacks
        label "per week"
    }
} {
    # FIRST, prepare the parameters
    # TBD: Could define a "symbol" type for the ROE
    prepare tactic_id  -required -type tactic::ATTROE
    prepare f          -toupper  -type  ident
    prepare g          -toupper  -type  ident
    prepare n          -toupper  -type  ident
    prepare roe        -toupper
    prepare attacks    -num      -type  ipositive
 
    returnOnError -final

    # NOTE: most checks could be invalid on paste.  The sanity check
    # will do the work.

    # NEXT, update the tactic, saving the undo script, and clearing
    # historical state data.
    set tactic [tactic get $parms(tactic_id)]
    set undo [$tactic update_ {f g n roe attacks} [array get parms]]

    # NEXT, save the undo script
    setundo $undo
}





