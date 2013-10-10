#-----------------------------------------------------------------------
# TITLE:
#    tactic_mobilize.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, MOBILIZE
#
#    A MOBILIZE tactic mobilizes force or organization group personnel,
#    moving new personnel into the playbox.
#
# TBD:
#    * We might want to use a gofer to choose the number of people to
#      mobilize.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tactic define MOBILIZE "Mobilize Personnel" {actor} {
    #-------------------------------------------------------------------
    # Instance Variables

    variable g           ;# A FRC or ORG group
    variable personnel   ;# Number of personnel.

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set g ""
        set personnel 0
        my set state invalid   ;# Initially we're invalid: no group

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    method SanityCheck {errdict} {
        if {$g eq ""} {
            dict set errdict g "No group selected."
        } elseif {$g ni [group ownedby [my agent]]} {
            dict set errdict g \
                "Force/organization group \"$g\" is not owned by [my agent]."
        }

        return [next $errdict]
    }


    method narrative {} {
        if {$g eq ""} {
            set gtext "???"
        } else {
            set gtext $g
        }

        return "Mobilize $personnel new $gtext personnel."
    }

    # obligate coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resources
    #
    # Obligates the personnel to be mobilizeilized.
    #
    # NOTE: MOBILIZE never executes on lock.

    method obligate {coffer} {
        assert {[strategy ontick]}

        $coffer mobilize $g $personnel

        return 1
    }

    method execute {} {
        personnel mobilize $g $personnel
            
        sigevent log 1 tactic "
            MOBILIZE: Actor {actor:[my agent]} mobilizes $personnel new 
            {group:$g} personnel.
        " [my agent] $g
    }
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:MOBILIZE:UPDATE
#
# Updates existing MOBILIZE tactic.

order define TACTIC:MOBILIZE:UPDATE {
    title "Update Tactic: Mobilize Personnel"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Group:" -for g
        enum g -listcmd {tactic groupsOwnedByAgent $tactic_id}

        rcc "Personnel:" -for personnel
        text personnel
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -oneof [tactic::MOBILIZE ids]
    returnOnError

    # NEXT, get the tactic
    set tactic [tactic get $parms(tactic_id)]

    prepare g                    -oneof [group ownedby [$tactic agent]]
    prepare personnel  -num      -type  ipositive

    returnOnError -final

    # NEXT, update the tactic, saving the undo script
    set undo [$tactic update_ {g personnel} [array get parms]]

    # NEXT, modify the tactic
    setundo $undo
}





