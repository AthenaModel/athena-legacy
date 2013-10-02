#-----------------------------------------------------------------------
# TITLE:
#   tactic_flow.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   athena_sim(1): FLOW(f,g,mode,number,rate) tactic
#
#   This module implements the FLOW tactic, which flows 
#   civilian personnel from one group to another.
#
# PARAMETER MAPPING:
#
#   f       <= f            The source group
#   g       <= g            The destination group
#   text1   <= mode         RATE, NUMBER, ALL
#   int1    <= number       Number to flow (for mode NUMBER)
#   x1      <= rate         Yearly rate, as a percentage of population,
#                           for mode RATE.
#   on_lock <= on_lock
#   once    <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: FLOW

tactic type define FLOW {f g text1 int1 x1 once} system {
    # A list of pending flows: f g delta ...
    typevariable pending {}
    
    #-------------------------------------------------------------------
    # Public Methods
    
    # reset
    #
    # Clears the list of pending flows prior to the beginning of
    # strategy execution.
    
    typemethod reset {} {
        set pending [list]
    }
    
    # save
    #
    # Adjusts civilian population according to the pending flows.
    
    typemethod save {} {
        foreach {f g delta} $pending {
            demog flow $f $g $delta
        }
    }

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        # FIRST, Bring the attributes into scope.
        dict with tdict {}

        # NEXT, determine the narrative string
        switch -exact -- $text1 {
            ALL {
                return "Flow all remaining members of $f into $g."
            }
            RATE {
                set pct [format "%.1f" $x1]
                return \
                "Flow population from $f to $g at a rate of $pct%/year."
            }
            NUMBER {
                return "Flow $int1 members of $f into $g."
            }
            default {
                error "Unknown mode: \"$text1\""
            }
        }
    }

    typemethod check {tdict} {
        # FIRST, Bring the attributes into scope.
        dict with tdict {}

        # NEXT, prepare to accumulate errors.
        set errors [list]
        
        # f
        if {$f ni [civgroup names]} {
            lappend errors "Civilian group $f no longer exists."
        }
        
        # g
        if {$g ni [civgroup names]} {
            lappend errors "Civilian group $g no longer exists."
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        # FIRST, Bring the attributes into scope.
        dict with tdict {}
        
        # NEXT, get the current population of group f.  If none,
        # the tactic fails.
        set population [demog getg $f population]
        
        if {$population == 0} {
            return 0
        }
        
        # NEXT, determine the number of people to move.
        switch -exact -- $text1 {
            ALL {
                set delta $population
            }
            NUMBER {
                set delta $int1
            }
            RATE {
                # The given rate is a percentage where we need a fraction,
                # so we need to divide by 100; and it's a yearly rate when
                # we need a weekly rate, so we need to divide by 52.
                #
                # Note: We could use the compound interest formula to
                # determine the weekly rate, but for our purposes the
                # difference turns out to be negligible.
                #
                # Note that [demog adjust] allows and will accumulate
                # fractional people; this is so that small rates of
                # change will still have effect given enough time.
                
                let weeklyRate {$x1/5200.0}
                let delta {$population*$weeklyRate}
                
            }
            default {
                error "Unknown mode: \"$text1\""
            }
        }

        # NEXT, add the adjustment to the pending list.
        lappend pending $f $g $delta
        
        # NEXT, log the changes.
        set m [civgroup getg $f n]
        set n [civgroup getg $g n]
        
        sigevent log 2 tactic "
            FLOW: up to $delta people moved from {group:$f} in {nbhood:$m}
            to {group:$g} in {nbhood:$n}
        " $f $g $m $n

        return 1
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # TBD
}

# TACTIC:FLOW:CREATE
#
# Creates a new FLOW tactic.

order define TACTIC:FLOW:CREATE {
    title "Create Tactic: Flow Population"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Source Group:" -for f
        enum f -listcmd {civgroup names}

        rcc "Destination Group:" -for g
        enum g -listcmd {lexcept [civgroup names] $f}

        rcc "Mode:" -for text1
        selector text1 {
            case ALL "Flow all of the group's remaining members" {}
            case NUMBER "Flow some number of the group's members" {
                rcc "Personnel:" -for int1
                text int1 -defvalue 0
            }
            case RATE "Flow members at a yearly rate" {
                rcc "Rate:" -for x1
                text x1 -defvalue 0.0
                label "%/year"
            }
        }

        rcc "Once Only?" -for once
        yesno once -defvalue 0

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type {agent system}
    prepare f        -toupper   -required -type civgroup
    prepare g        -toupper   -required \
        -oneof [lexcept [civgroup names] $parms(f)]
    prepare text1    -toupper   -required -selector
    prepare int1     -num                 -type iquantity
    prepare x1                            -type snit::double
    prepare once                -required -type boolean
    prepare priority -tolower             -type ePrioSched

    returnOnError
    
    # NEXT, cross-checks

    # text1 vs int1 and x1
    if {$parms(text1) eq "NUMBER" && $parms(int1) eq ""} {
        reject int1 "Required value when mode is NUMBER."
    } elseif {$parms(text1) eq "RATE" && $parms(x1) eq ""} {
        reject x1 "Required value when mode is RATE."
    }
    
    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) FLOW

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:FLOW:UPDATE
#
# Updates existing FLOW tactic.

order define TACTIC:FLOW:UPDATE {
    title "Update Tactic: Assign Activity"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_FLOW -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Source Group:" -for f
        enum f -listcmd {civgroup names}

        rcc "Destination Group:" -for g
        enum g -listcmd {lexcept [civgroup names] $f}

        rcc "Mode:" -for text1
        selector text1 {
            case ALL "Flow all of the group's remaining members" {}
            case NUMBER "Flow some number of the group's members" {
                rcc "Personnel:" -for int1
                text int1
            }
            case RATE "Flow members at a yearly rate" {
                rcc "Rate:" -for x1
                text x1
                label "%/year"
            }
        }

        rcc "Once Only?" -for once
        yesno once
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare f          -toupper  -type civgroup
    prepare g          -toupper    \
        -oneof [lexcept [civgroup names] $parms(f)]
    prepare text1      -toupper  -selector
    prepare int1       -num      -type iquantity
    prepare x1                   -type snit::double
    prepare once                 -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType FLOW $parms(tactic_id) }
    
    returnOnError
    
    # NEXT, cross-checks
    tactic delta parms

    # text1 vs int1 and x1
    if {$parms(text1) eq "NUMBER" && $parms(int1) eq ""} {
        reject int1 "Required value when mode is NUMBER."
    } elseif {$parms(text1) eq "RATE" && $parms(x1) eq ""} {
        reject x1 "Required value when mode is RATE."
    }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}

