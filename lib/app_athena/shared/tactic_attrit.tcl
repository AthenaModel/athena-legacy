#-----------------------------------------------------------------------
# TITLE:
#    tactic_attrit.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, Cause magic attrition
#
#    This module implements the CURSE tactic. 
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: ATTRIT

tactic define ATTRIT "Magic Attrition" {system} {
    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    variable mode       ;# Attrition mode: NBHOOD or GROUP
    variable n          ;# Neighborhood to attrit if mode is NBHOOD
    variable f          ;# Group to attrit id mode is GROUP
    variable casualties ;# The number of casualties
    variable g1         ;# Responsible group 1, or "NONE"
    variable g2         ;# Responsible group 2, or "NONE"

    variable trans
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean
        next

        # Initialize state variables
        set mode       NBHOOD
        set n          ""
        set f          ""
        set casualties 1
        set g1         "NONE"
        set g2         "NONE"

        # transient data default
        set trans(ok) 1
        set trans(msg) ""

        # Initial state is invalid (no n)
        my set state invalid

        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    # No ObligateResources method is required; the ROE uses no resources.

    method SanityCheck {errdict} {
        if {$n eq ""} {
            dict set errdict n "No neighborhood selected."
        } elseif {$n ni [nbhood names]} {
            dict set errdict n "No such neighborhood: \"$n\"."
        }

        switch -exact -- $mode {
            NBHOOD {
                # Nothing in particular yet
            }

            GROUP {
                if {$f eq ""} {
                    dict set errdict f "No group selected."
                } elseif {$f ni [group names]} {
                    dict set errdict f "No such group: \"$f\"."
                }
            }

            default {
                error "Invalid mode: \"$mode\""
            }
        }

        if {$g1 ne "NONE" && $g1 ni [frcgroup names]} {
            dict set errdict g1 "No such FRC group: \"$g1\"."
        }

        if {$g2 ne "NONE" && $g2 ni [frcgroup names]} {
             dict set errdict g2 "No such FRC group: \"$g2\"."
        }

        return [next $errdict]
    }

    method narrative {} {
        set narr ""

        set s(n)  [link make nbhood $n]
        set s(f)  [link make group $f]
        set s(g1) [link make group $g1]
        set s(g2) [link make group $g2]

        switch -exact -- $mode {
            NBHOOD {
                set narr "Magic attrit $casualties personnel in $s(n)"
            }

            GROUP {
                set narr "Magic attrit $casualties of $s(f)'s personnel in $s(n)"
            }

            default {
                error "Invalid mode: \"$mode\""
            }
        }

        if {$g1 ne "NONE"} {
            append narr " and attribute it to $s(g1)"
        }

        if {$g2 ne "NONE"} {
            append narr " and $s(g2)"
        }
        
        append narr "."
        
        return $narr
    }

    method execute {} {
        set owner [my agent]
        set objects [list]

        set s(n)  [link make nbhood $n]
        set s(f)  [link make group $f]
        set s(g1) [link make group $g1]
        set s(g2) [link make group $g2]

        # FIRST, is f in n?  If not, there's nothing to do.
        if {$mode eq "GROUP"} {
            set groupsInN [rdb eval {
                SELECT DISTINCT g
                FROM units
                WHERE n=$n
            }]

            if {$f ni $groupsInN} {
                sigevent log 2 tactic "
                    ATTRIT: No magic attrition; group $s(f) is not in $s(n).
                " $owner $n

                return 1
            }

            set msg "
                ATTRIT: Magic attrition attempted against $s(f): 
                $casualties casualties in $s(n)
            "
            lappend objects $f
        } else {
            # Mode is NBHOOD
            set msg "
                ATTRIT: Magic attrition attempted in $s(n): 
                $casualties casualties
            "
            lappend objects $n
        }


        # NEXT add in responsible groups if necessary
        if {$g1 ne "NONE"} {
            append msg " by $s(g1)"
            lappend objects $g1
        } 

        if {$g2 ne "NONE"} {
            append msg " and $s(g2)"
            lappend objects $g2
        }

        append msg "."

        # NEXT log it and schedule the attrition in AAM
        sigevent log 2 tactic $msg $owner {*}$objects

        set p(mode)       $mode
        set p(casualties) $casualties
        set p(n)          $n
        set p(f)          [expr {$mode eq "GROUP"  ? $f  : ""}]
        set p(g1)         [expr {$g1   ne "NONE"   ? $g1 : ""}]
        set p(g2)         [expr {$g2   ne "NONE"   ? $g2 : ""}]

        aam attrit [array get p]
    }
}

# TACTIC:ATTRIT
#
# Creates/Updates ATTRIT tactic.

order define TACTIC:ATTRIT {
    title "Tactic: Magic Attrition"
    options -sendstates PREP

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Attrition Mode:" -for mode
        selector mode {
            case NBHOOD "Cause attrition in a neighborhood" {
                rcc "Nbhood:" -for n
                nbhood n

                rcc "Responsible Group:" -for g1
                enum g1 -listcmd {ptype frcg+none names} -defvalue NONE

                when {$g1 ne "NONE"} {
                    rcc "Responsible Group 2:" -for g2
                    enum g2 -listcmd {::aam AllButG1 $g1}
                }
            }

            case GROUP "Cause attrition to a group" {
                rcc "Nbhood:" -for n
                nbhood n

                rcc "Group:" -for f
                group f 

                when {$f in [::civgroup names]} {
                    rcc "Responsible Group:" -for g1
                    enum g1 -listcmd {ptype frcg+none names} -defvalue NONE

                    when {$g1 ne "NONE"} {
                        rcc "Responsible Group 2:" -for g2
                        enum g2 -listcmd {::aam AllButG1 $g1}
                    }
                }
            }
        }

        rcc "Casualties:" -for casualties
        text casualties -defvalue 1
    }

} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic::ATTRIT
    returnOnError

    set tactic [tactic get $parms(tactic_id)]

    # All validation takes place on sanity check
    prepare mode       -toupper -selector
    prepare casualties -num     -type iquantity
    prepare n          -toupper
    prepare f          -toupper
    prepare g1         -toupper
    prepare g2         -toupper

    returnOnError -final

    fillparms parms [$tactic view]

    if {$parms(g1) eq ""} {set parms(g1) "NONE"}
    if {$parms(g2) eq ""} {set parms(g2) "NONE"}

    # NEXT, if mode is GROUP and f not CIV clear out g1 
    if {$parms(mode) eq "GROUP" && $parms(f) ni [civgroup names]} {
        set parms(g1) "NONE"
    }

    if {$parms(g1) eq "NONE"} {
        set parms(g2) "NONE"
    }

    # NEXT, g1 != g2
    if {$parms(g1) eq $parms(g2)} {
        set parms(g2) "NONE"
    }

    # NEXT, modify the tactic
    setundo [$tactic update_ {
        mode casualties n f g1 g2
    } [array get parms]]
}




