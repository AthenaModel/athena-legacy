#-----------------------------------------------------------------------
# TITLE:
#    tactic_spend.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): SPEND(mode,amount,goods,pop,black,region,world) tactic
#
#    This module implements the SPEND tactic, which spends a sum
#    of money on things not explicitly modeled in Athena.  The money
#    goes to the five non-actor sectors as indicated by shares set
#    by the analyst.
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: SPEND

tactic type define SPEND {
    mode amount goods black pop region world once on_lock
} actor {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {}
        
        if {$mode eq "ALL"} {
            set text "Spend all remaining cash-on-hand "
        } else {
            set text "Spend [moneyfmt $amount] "
        }
        
        append text "according to the following profile: "
        append text [getPercentages $tdict]
        
        return $text
    }

    typemethod dollars {tdict} {
        dict with tdict {}
        if {$mode eq "SOME"} {
            return [moneyfmt $amount]
        } else {
            return "?"
        }
    }

    typemethod execute {tdict} {
        dict with tdict {}
            
        # FIRST, retrieve relevant data.
        set cash_on_hand [cash get $owner cash_on_hand]
        
        # NEXT, do we have it?
        if {$mode eq "ALL"} {
            # NEXT, cash on hand can be negative if we are locking
            # this simply keeps a negative number from being 
            # reported in the sigevent log
            set amount [expr {max(0.0, $cash_on_hand)}]
        } elseif {![strategy locking] && $amount > $cash_on_hand} {
            return 0
        }
        
        # NEXT, spend it.
        cash spendon $owner $amount [getProfile $tdict]

        sigevent log 2 tactic "
            SPEND: Actor {actor:$owner} spends $amount
            on [getPercentages $tdict]
        " $owner 

        return 1
    }

    #-----------------------------------------------------------------
    # Helpers
    
    # getPercentages tdict
    #
    # tdict - An unpacked tactic dictionary
    #
    # Turns the shares into percentages and returns a string
    # showing them.
    
    proc getPercentages {tdict} {
        set fracs [getProfile $tdict]
       
        set profile [list]
        dict for {sector value} $fracs {
            lappend profile "$sector: [string trim [percent $value]]"
        }
        
        return [join $profile "; "]
    }
    
    # getProfile tdict
    #
    # tdict - An unpacked tactic dictionary
    #
    # Turns the shares into fractions and returns a dictionary
    # of the non-zero fractions by sector.
    
    proc getProfile {tdict} {
        let total 0.0
        
        foreach sector {goods black pop region world} {
            let total {$total + [dict get $tdict $sector]}
        }
        
        set result [dict create]
        
        foreach sector {goods black pop region world} {
            set share [dict get $tdict $sector]
            
            if {$share > 0.0} {
                let fraction {$share/$total}
                dict set result $sector $fraction
            }
        }

        return $result        
    }
    
    # getTotalShares parmsVar
    #
    # parmsVar - name of the parms array.
    #
    # Ensures that all shares have a value (0, at least),
    # and the total is positive: the money is going somewhere.
    
    typemethod getTotalShares {parmsVar} {
        upvar 1 $parmsVar parms
        
        set total 0
        foreach sector {goods black pop region world} {
            if {$parms($sector) eq ""} {
                set parms($sector) 0
            }
            
            let total {$total + $parms($sector)}
        }
        
        return $total
    }
}

# TACTIC:SPEND:CREATE
#
# Creates a new SPEND tactic.

order define TACTIC:SPEND:CREATE {
    title "Create Tactic: Spend Money"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Mode:" -for text1
        selector mode {
            case SOME "Spend some cash-on-hand" {
                rcc "Amount:" -for amount
                text amount
            }

            case ALL "Spend all remaining cash-on-hand" {}
        }
        
        rcc "Goods:" -for goods
        text goods -defvalue 0
        label "share(s)"        

        rcc "Black:" -for black
        text black -defvalue 0
        label "share(s)"        

        rcc "Pop:" -for pop
        text pop -defvalue 0
        label "share(s)"        

        rcc "Region:" -for region
        text region -defvalue 0
        label "share(s)"        

        rcc "World:" -for world
        text world -defvalue 0
        label "share(s)"        

        rcc "Once Only?" -for once
        yesno once -defvalue 0

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock -defvalue 1

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare mode     -toupper   -required -selector
    prepare amount   -toupper             -type money
    prepare goods    -num                 -type iquantity
    prepare black    -num                 -type iquantity
    prepare pop      -num                 -type iquantity
    prepare region   -num                 -type iquantity
    prepare world    -num                 -type iquantity
    prepare once                          -type boolean
    prepare on_lock                       -type boolean
    prepare priority -tolower             -type ePrioSched

    returnOnError

    # NEXT, cross-checks

    # Amount is required when mode is "SOME"
    if {$parms(mode) eq "SOME" && $parms(amount) eq ""} {
        reject amount "Required value when mode is SOME."
    }

    # At least one sector must get a positive share
    set total [tactic::SPEND getTotalShares parms]
    
    if {$total == 0} {
        reject goods "At least one sector must have a positive share."
    }

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) SPEND

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:SPEND:UPDATE
#
# Updates existing SPEND tactic.

order define TACTIC:SPEND:UPDATE {
    title "Update Tactic: Deploy Forces"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_SPEND -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Mode:" -for text1
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
        
        rcc "Once Only?" -for once
        yesno once

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare mode       -toupper  -selector
    prepare amount     -toupper  -type money
    prepare goods      -num      -type iquantity
    prepare black      -num      -type iquantity
    prepare pop        -num      -type iquantity
    prepare region     -num      -type iquantity
    prepare world      -num      -type iquantity
    prepare once                 -type boolean
    prepare on_lock              -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType SPEND $parms(tactic_id) }

    returnOnError

    # NEXT, cross-checks
    tactic delta parms
    
    # Amount is required when mode is "SOME"
    if {$parms(mode) eq "SOME" && $parms(amount) eq ""} {
        reject amount "Required value when mode is SOME."
    }

    # At least one sector must get a positive share
    set total [tactic::SPEND getTotalShares parms]
    
    if {$total == 0} {
        reject goods "At least one sector must have a positive share."
    }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


