#-----------------------------------------------------------------------
# TITLE:
#    tactic_curse.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, Complex User-defined Role-based 
#                   Situation and Events (CURSE)
#
#    This module implements the CURSE tactic. 
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: CURSE

tactic define CURSE "Cause a CURSE" {system} {
    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    variable curse    ;# ID of a CURSE
    variable roles    ;# Mapping of roles to gofers

    # modeChar: mapping between the mode (in each inject) and 
    # mode character used by the driver
    variable modeChar 

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean
        next

        # Set mapping from mode name to mode character
        set modeChar(persistent) P
        set modeChar(transient)  T

        # Initialize state variables
        set curse    ""
        set roles    ""

        # Initial state is invalid (no curse, roles)
        my set state invalid

        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    # No ObligateResources method is required; the ROE uses no resources.

    method SanityCheck {errdict} {
        # FIRST check for existence of the CURSE
        set exists [curse exists $curse]

        # NEXT, the curse this tactic uses may have been deleted, disabled,
        # or invalid
        if {$curse eq ""} {
            dict set errdict curse \
                "No curse selected."
        } elseif {!$exists} {
            dict set errdict curse \
                "No such curse: \"$curse\"."
        } else {
            set state [curse get $curse state]

            if {$state ne "normal"} {
                dict set errdict curse \
                    "Curse $curse is $state."
            }
        }

        # NEXT, it exists and is "normal", are the roles good?
        
        # Make sure it is a rolemap
        set isrolemap 0

        if {[catch {
            set roles [::projectlib::rolemap validate $roles]
        } result]} {
            dict set errdict roles $result
        } else {
            set isrolemap 1
        }

        if {$isrolemap && $exists && $state eq "normal"} {
            set keys [dict keys $roles]

            set badr [list]
            # NEXT, roles this tactic uses may have been deleted
            foreach role $keys {
                if {$role ni [curse rolenames $curse]} {
                    lappend badr "Role $role no longer exists."
                }
            }

            # NEXT, all roles must be accounted for
            foreach role [curse rolenames $curse] {
                if {$role ni $roles} {
                    lappend badr "Role $role is not defined."
                }
            }

            # NEXT, the roletype must not change out from underneath
            # the tactic
            foreach role $keys {
                set gtype [dict get [dict get $roles $role] _type]
                if {$role in [curse rolenames $curse] &&
                    $gtype ne [inject roletype $curse $role]} {
                    lappend badr "Role type of $role changed."
                }
            }

            if {[llength $badr] > 0} {
                dict set errdict roles [join $badr " "]
            }
        }

        return [next $errdict]
    }

    method narrative {} {
        set narr [curse narrative $curse]
        append narr ". "

        foreach {role goferdict} $roles {
            append narr "$role = "
            append narr [gofer narrative $goferdict]
            append narr ". "
        }

        return $narr
    }

    method execute {} {
        set inject_executed 0

        # NEXT, go through each inject associated with this CURSE
        # firing rules as we go
        rdb eval {
            SELECT * FROM curse_injects
            WHERE curse_id=$curse AND state='normal'
        } idata {
            set parms(curse_id) $idata(curse_id)

            switch -exact -- $idata(inject_type) {
                HREL {
                    # Change to horizontal relationships of group(s) in
                    # f with group(s) in g
                    set parms(f)    [gofer eval [dict get $roles $idata(f)]]
                    set parms(g)    [gofer eval [dict get $roles $idata(g)]]
                    set parms(mode) $modeChar($idata(mode))
                    set parms(mag)  $idata(mag)

                    if {$parms(f) eq "" || $parms(g) eq ""} {
                        log detail tactic \
                            "$idata(curse_id) inject $idata(inject_num) did not execute because one or more roles are empty."
                        continue
                    }

                    set inject_executed 1

                    my hrel [array get parms]
                }

                VREL {
                    # Change to verticl relationships of group(s) in
                    # g with actor(s) in a
                    set parms(g)    [gofer eval [dict get $roles $idata(g)]]
                    set parms(a)    [gofer eval [dict get $roles $idata(a)]]
                    set parms(mode) $modeChar($idata(mode))
                    set parms(mag)  $idata(mag)

                    if {$parms(g) eq "" || $parms(a) eq ""} {
                        log detail tactic \
                            "$idata(curse_id) inject $idata(inject_num) did not execute because one or more roles are empty."
                        continue
                    }

                    set inject_executed 1

                    my vrel [array get parms]
                }

                COOP {
                    # Change to cooperation of CIV group(s) in f
                    # with FRC group(s) in g
                    set parms(f)    [gofer eval [dict get $roles $idata(f)]]
                    set parms(g)    [gofer eval [dict get $roles $idata(g)]]
                    set parms(mode) $modeChar($idata(mode))
                    set parms(mag)  $idata(mag)

                    if {$parms(f) eq "" || $parms(g) eq ""} {
                        log detail tactic \
                            "$idata(curse_id) inject $idata(inject_num) did not execute because one or more roles are empty."
                        continue
                    }

                    set inject_executed 1

                    my coop [array get parms]
                }

                SAT {
                    # Change of satisfaction of CIV group(s) in g
                    # with concern c
                    set parms(g)    [gofer eval [dict get $roles $idata(g)]]
                    set parms(c)    $idata(c)
                    set parms(mode) $modeChar($idata(mode))
                    set parms(mag)  $idata(mag)

                    if {$parms(g) eq ""} {
                        log detail tactic \
                            "$idata(curse_id) inject $idata(inject_num) did not execute because one or more roles are empty."
                        continue
                    }

                    set inject_executed 1

                    my sat [array get parms]
                }

                default {
                    #Should never happen
                    error "Unrecognized inject type: $idata(inject_type)"
                }
            }
        }
    }

    # hrel parmdict
    #
    # Causes an assessment of horizontal relationship among
    # group(s).
    #
    # parmdict:
    #   curse_id   - ID of the CURSE causing the change
    #   mode       - P (persistent) or T (transient)
    #   mag        - qmag(n) value of the change
    #   f          - One or more groups
    #   g          - One or more groups

    method hrel {parmdict} {
        dict with parmdict {}

        set fdict [dict create \
            dtype    CURSE     \
            curse_id $curse_id \
            atype    hrel      \
            mode     $mode     \
            mag      $mag      \
            f        $f        \
            g        $g        ]

            driver::CURSE assess $fdict

        return
    }

    # vrel parmdict
    #
    # Causes an assessment vertical relationship among
    # group(s).
    #
    # parmdict:
    #   curse_id   - ID of the CURSE causing the change
    #   mode       - P (persistent) or T (transient)
    #   mag        - qmag(n) value of the change
    #   g          - One or more groups
    #   a          - One or more actors

    method vrel {parmdict} {
        dict with parmdict {}

        set fdict [dict create  \
            dtype    CURSE      \
            curse_id $curse_id  \
            atype    vrel       \
            mode     $mode      \
            mag      $mag       \
            g        $g         \
            a        $a         ]

            driver::CURSE assess $fdict

        return
    }

    # sat parmdict
    #
    # Causes an assessment of satsifaction change of
    # group(s) with a concern
    #
    # parmdict:
    #   curse_id   - ID of the CURSE causing the change
    #   mode       - P (persistent) or T (transient)
    #   mag        - qmag(n) value of the change
    #   g          - One or more groups
    #   c          - AUT, SFT, CUL or QOL

    method sat {parmdict} {
        dict with parmdict {}

        set fdict [dict create \
            dtype    CURSE     \
            curse_id $curse_id \
            atype    sat       \
            mode     $mode     \
            mag      $mag      \
            c        $c        \
            g        $g        ]

        driver::CURSE assess $fdict

        return
    }

    # coop parmdict
    #
    # Causes an assessment of cooperation change of 
    # CIV group(s) with FRC groups(s)
    #
    # parmdict:
    #   curse_id   - ID of the CURSE causing the change
    #   mode       - P (persistent) or T (transient)
    #   mag        - qmag(n) value of the change
    #   f          - One or more CIV groups
    #   g          - One or more FRC groups

    method coop {parmdict} {
        dict with parmdict {}

        set fdict [dict create \
            dtype    CURSE     \
            curse_id $curse_id \
            atype    coop      \
            mode     $mode     \
            mag      $mag      \
            f        $f        \
            g        $g        ]

        driver::CURSE assess $fdict

        return
    }
}

# TACTIC:CURSE
#
# Creates/Updates CURSE tactic.

order define TACTIC:CURSE {
    title "Tactic: CURSE"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Owner" -for owner
        disp owner

        rcc "CURSE" -for curse
        curse curse

        rc "" -for roles -span 2
        roles roles -rolespeccmd {curse rolespec $curse}
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic::CURSE
    returnOnError

    set tactic [tactic get $parms(tactic_id)]

    # All validation takes place on sanity check
    prepare curse -toupper
    prepare roles

    returnOnError -final

    # NEXT, modify the tactic
    setundo [$tactic update_ {curse roles} [array get parms]]
}



