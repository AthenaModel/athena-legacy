#-----------------------------------------------------------------------
# TITLE:
#    tactic_fundeni.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, FUNDENI
#
#    The FUNDENI tactic funds Essential Non-Infrastructure services 
#    aimed at particular groups.  The services are funded for the 
#    following week.
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: FUNDENI

tactic define FUNDENI \
    "Fund Essential Non-Infrastructure Services" {actor} -onlock {
    #-------------------------------------------------------------------
    # Instance Variables 

    variable mode    ;# ALL, EXACT, UPTO, PERCENT or EXCESS
    variable los     ;# Desired level of service to fund, as a percentage
    variable amount  ;# Amount of money to use for funding
    variable percent ;# Percent of money to use if mode is PERCENT
    variable glist   ;# List if CIV groups to receive services

    # Transient data
    variable trans

    #------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean
        next

        # Initialize state variables
        set mode    ALL
        set los     100.0
        set amount  0.0
        set percent 0.0
        set glist   [gofer::CIVGROUPS blank]

        # Initial state is invalid (no glist)
        my set state invalid

        set trans(amount) 0.0
        set trans(glist)  [list]

        # Save the options
        my configure {*}$args
    }

    #-----------------------------------------------------------------
    # Operations

    method SanityCheck {errdict} {
        # glist
        if {[catch {gofer::CIVGROUPS validate $glist} result]} {
            dict set errdict glist $result
        }

        return [next $errdict]
    }

    method narrative {} {

        set gtext [gofer::CIVGROUPS narrative $glist]
        set atext [moneyfmt $amount]
        set ltext [format "%.1f%%" $los]
        set ptext "[format "%.1f%%" $percent] of cash-on-hand"
        set anarr "\$$atext but not more than $ltext of the saturation LOS"
        set pnarr "$ptext but not more than $ltext of the saturation LOS"
        set enarr "worth of Essential Non-Infrastructure services for $gtext"

        switch -exact -- $mode {
            ALL {
                return "Use remaining cash on hand to fund at least $ltext of the saturation LOS $enarr."
            }

            EXACT {
                return "Fund exactly $anarr $enarr."
            }

            UPTO {
                return "Fund up to $anarr $enarr."
            }

            PERCENT {
                return "Fund $pnarr $enarr."
            }

            EXCESS {
                return "Fund with anything in excess of $anarr $enarr."
            }

            default {
                error "Invalid mode: \"$mode\""
            }
        }

    }

    method ObligateResources {coffer} {
        # FIRST, retrieve relevant data.
        let cash [$coffer cash]

        # NEXT, filter out groups that do not provide enough direct support
        # to the tactic owner
        set list [gofer::CIVGROUPS eval $glist]
        set trans(glist) [my groupsInSupportingNbhoods [my agent] $list]

        # NEXT, compute the upper limit of funding as a percentage of
        # saturation level of service for all groups
        let max_fund [service_eni fundlevel $los $trans(glist)]
        let amt {min($amount, $max_fund)}

        set funds 0.0

        # NEXT, depending on mode, try to obligate money
        switch -exact -- $mode {
            ALL {
                let funds {min($cash, $max_fund)}
            }

            EXACT {
                # This is the only one than could give rise to an error
                if {[my InsufficientCash $cash $amt]} {
                    return
                }

                set funds $amt
            }

            UPTO {
                let funds {max(0.0, min($cash, $amt))}
            }

            PERCENT {
                if {$cash > 0.0} {
                    let funds \
                        {min(double($percent/100.0) * $cash,$max_fund)}
                }
            }

            EXCESS {
                let funds {max(0.0, min($cash-$amount,$max_fund))}
            }

            default {
                error "Invalid mode: \"$mode\""
            }

        }

        # NEXT, get the actual amount to obligate.
        set trans(amount) $funds

        # NEXT, obligate it.
        $coffer spend $trans(amount)

        return 1
    }

    method execute {} {
        # FIRST, set the owner of the tactic
        set owner [my agent]

        # NEXT, if there's no one to fund quick exit
        if {[llength $trans(glist)] == 0} {
            sigevent log 2 tactic "
                FUNDENI: Actor {actor:$owner} could not fund
                \$[moneyfmt $trans(amount)] worth of Essential 
                Non-Infrastructure services, because there are no
                groups to fund.
            " $owner {*}$glist
            return 
        }

        cash spend $owner FUNDENI $trans(amount)

        # NEXT, Compute strings needed for logging.
        if {[llength $trans(glist)] == 1} {
            set gtext "{group:[lindex $trans(glist) 0]}"
        } else {
            set grps [list]
 
            foreach g $trans(glist) {
                lappend grps "{group:$g}"
            }

            set gtext [join $grps ", "]
        }

        
        # NEXT, try to fund the service.  This will fail if
        # all of the groups are empty.
        if {![service_eni fundeni $owner $trans(amount) $trans(glist)]} {
            cash refund $owner FUNDENI $trans(amount)
            sigevent log 2 tactic "
                FUNDENI: Actor {actor:$owner} could not fund
                \$[moneyfmt $trans(amount)] worth of Essential 
                Non-Infrastructure services to $gtext, because 
                all of those groups are empty.
            " $owner {*}$glist
            return
        }

        # NEXT, get the related neighborhoods.
        set nbhoods [rdb eval "
            SELECT DISTINCT n 
            FROM civgroups
            WHERE g IN ('[join $trans(glist) ',']')
        "]


        # TBD: Do I need to include neighborhoods in here?
        sigevent log 2 tactic "
            FUNDENI: Actor {actor:$owner} funds \$[moneyfmt $trans(amount)]
            worth of Essential Non-Infrastructure services to
            $gtext.
        " $owner {*}$trans(glist) {*}$nbhoods
    }

    # groupsInSupportingNbhoods  a glist
    # 
    # a     - the agent that owns this tactic
    # glist - a list of civilian groups
    #
    # This helper method filters out any groups in glist that are
    # in neighborhoods which are not providing enough direct support to the 
    # agent for the funding of ENI to take place. 
    #
    # It also filters out groups in non-local neighborhoods.
    #
    # It may return an empty list.

    method groupsInSupportingNbhoods {a glist} {
        # FIRST, make an "IN" clause
        set inClause "IN ('[join $glist ',']')"

        # NEXT, get the list of groups that reside in local neighborhoods in
        # which the owner has positive direct support

        set minSupport [parm get service.ENI.minSupport]

        rdb eval "
            SELECT g 
            FROM local_civgroups
            JOIN influence_na USING (n)
            WHERE a=\$a
            AND   direct_support >= $minSupport
            AND   g $inClause 
        "
    }

}

# TACTIC:FUNDENI
#
# Updates a FUNDENI tactic.

order define TACTIC:FUNDENI {
    title "Tactic: Fund ENI Services"
    options -sendstates PREP

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rc "Fund ENI For:" -span 2

        rcc "Groups:" -for glist -span 3
        gofer glist -typename gofer::CIVGROUPS

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

        rcc "Up to:" -for los
        text los
        label "% of SLOS"

    }
} {
    prepare tactic_id -required -type tactic::FUNDENI
    returnOnError

    set tactic [tactic get $parms(tactic_id)]

    # FIRST, prepare and validate the parameters
    prepare glist   
    prepare mode    -toupper -selector
    prepare amount  -type money
    prepare percent -type rpercent
    prepare los     -type rpercent
 
    returnOnError 

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

    # NEXT, create the tactic
    setundo [$tactic update_ {glist mode amount percent los} [array get parms]]
}



