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
tactic define SPEND "Spend Cash-On-Hand" {actor} -onlock {
    #-------------------------------------------------------------------
    # Instance Variables

    variable mode    ;# ALL or SOME
    variable amount  ;# Amount of money if mode is SOME
    variable goods   ;# Integer # of shares going to goods sector
    variable black   ;# Integer # of shares going to black sector
    variable pop     ;# Integer # of shares going to pop sector
    variable region  ;# Integer # of shares going to region sector
    variable world   ;# Integer # of shares going to world sector

    # Transient Data
    variable trans

    
    #-------------------------------------------------------------------
    # Constructor

    # constructor ?block_?
    #
    # block_  - The block that owns the tactic
    #
    # Creates a new tactic for the given block.
    #
    # TBD: What should initial shares be?

    constructor {{block_ ""}} {
        next $block_
        set mode   ALL
        set amount 0.0
        set goods  1
        set black  1
        set pop    1
        set region 1
        set world  1

        set trans(amount) 0.0
    }

    #-------------------------------------------------------------------
    # Operations

    # No special SanityCheck is required, unless we default to 
    # all-zero shares.

    method narrative {} {
        if {$mode eq "ALL"} {
            set text "Spend all remaining cash-on-hand "
        } else {
            set text "Spend [moneyfmt $amount] "
        }
        
        append text "according to the following profile: "
        append text [my GetPercentages]
        
        return $text
    }

    # obligate coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resources
    #
    # Obligates the money to be spent.

    method obligate {coffer} {
        # FIRST, retrieve relevant data.
        let cash_on_hand [$coffer cash]
        
        # NEXT, do we have it?
        if {$mode eq "ALL"} {
            set trans(amount) $cash_on_hand
        } else {
            # mode is SOME.

            # Except on-lock, we have to have the funds on hand.
            if {[strategy ontick]} {
                if {$amount > $cash_on_hand} {
                    return 0
                }
            }    

            set trans(amount) $amount
        }

        # NEXT, obligate it.
        $coffer spend $trans(amount)

        return 1

    }

    method execute {} {
        cash spendon [my agent] $trans(amount) [my GetProfile]

        sigevent log 2 tactic "
            SPEND: Actor {actor:[my agent]} spends $trans(amount)
            on [my GetPercentages]
        " [my agent]
    }

    #-------------------------------------------------------------------
    # Helpers

    # GetPercentages 
    #
    # Turns the shares into percentages and returns a string
    # showing them.
    
    method GetPercentages {} {
        set fracs [my GetProfile]
       
        set profile [list]
        dict for {sector value} $fracs {
            lappend profile "$sector: [string trim [percent $value]]"
        }
        
        return [join $profile "; "]
    }
    
    # GetProfile
    #
    # Turns the shares into fractions and returns a dictionary
    # of the non-zero fractions by sector.
    
    method GetProfile {} {
        let total 0.0
        
        foreach sector {goods black pop region world} {
            let total {$total + [set $sector]}
        }
        
        set result [dict create]
        
        foreach sector {goods black pop region world} {
            set share [set $sector]
            
            if {$share > 0.0} {
                let fraction {$share/$total}
                dict set result $sector $fraction
            }
        }

        return $result        
    }    
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:SPEND:UPDATE
#
# Updates existing SPEND tactic.

order define TACTIC:SPEND:UPDATE {
    title "Update Tactic: Spend Money"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Mode:" -for mode
        selector mode {
            case SOME "Spend some cash-on-hand" {
                rcc "Amount:" -for amount
                text amount
            }

            case ALL "Spend all remaining cash-on-hand" {}
        }
        
        rcc "Goods:" -for goods
        text goods
        label "share(s)"        

        rcc "Black:" -for black
        text black
        label "share(s)"        

        rcc "Pop:" -for pop
        text pop
        label "share(s)"        

        rcc "Region:" -for region
        text region
        label "share(s)"        

        rcc "World:" -for world
        text world
        label "share(s)"        
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -oneof [tactic::SPEND ids]
    prepare mode       -toupper  -selector
    prepare amount     -toupper  -type money
    prepare goods      -num      -type iquantity
    prepare black      -num      -type iquantity
    prepare pop        -num      -type iquantity
    prepare region     -num      -type iquantity
    prepare world      -num      -type iquantity

    returnOnError

    # NEXT, get the tactic
    set tactic [tactic get $parms(tactic_id)]

    # NEXT, check cross-constraints
    fillparms parms [$tactic view]

    # Amount is required when mode is "SOME"
    if {$parms(mode) eq "SOME" && $parms(amount) == 0.0} {
        reject amount "Required value when mode is SOME."
    }

    # At least one sector must get a positive share
    let total {
        $parms(goods) + $parms(black) + $parms(pop) + $parms(region) + 
        $parms(world)
    }
    
    if {$total == 0} {
        reject goods "At least one sector must have a positive share."
    }

    returnOnError -final

    # NEXT, update the tactic, saving the undo script
    set undo [$tactic update_ {
        mode amount goods black pop region world
    } [array get parms]]

    # NEXT, modify the tactic
    setundo $undo
}





