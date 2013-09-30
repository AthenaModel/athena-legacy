#-----------------------------------------------------------------------
# TITLE:
#    tacticx_demob.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, DEMOB
#
#    A DEMOB tactic demobilizes force or organization group personnel,
#    moving them out of the playbox.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tacticx define DEMOB "Demobilize Personnel" {actor} {
    #-------------------------------------------------------------------
    # Instance Variables

    variable g           ;# A FRC or ORG group
    variable mode        ;# ALL | SOME
    variable personnel   ;# Number of personnel.

    # Transient data
    variable trans

    #-------------------------------------------------------------------
    # Constructor

    # constructor ?block_?
    #
    # block_  - The block that owns the tactic
    #
    # Creates a new tactic for the given block.

    constructor {{block_ ""}} {
        next $block_
        set g ""
        set mode ALL
        set personnel 0
        my set state invalid   ;# Initially we're invalid: no group

        set trans(personnel) 0
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
        set gtext [expr {$g    ne ""     ? $g         : "???"}]
        set ptext [expr {$mode eq "SOME" ? $personnel : "all"}]

        return "Demobilize $ptext of group $gtext's undeployed personnel."
    }

    # obligate coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resources
    #
    # Obligates the personnel to be demobilized.
    #
    # NOTE: DEMOB never executes on lock.

    method obligate {coffer} {
        assert {[strategyx ontick]}
        
        set undeployed [$coffer troops $g undeployed]

        if {$mode eq "SOME"} {
            if {$undeployed < $personnel} {
                return 0
            }

            set trans(personnel) $personnel
        } else {
            set trans(personnel) $undeployed 
        }

        $coffer demobilize $g $trans(personnel)

        return 1
    }

    method execute {} {
        personnel demob $g $trans(personnel)
            
        sigevent log 1 tactic "
            DEMOB: Actor {actor:[my agent]} demobilizes $trans(personnel)
            {group:$g} personnel.
        " [my agent] $g
    }
}

#-----------------------------------------------------------------------
# TACTICX:* orders

# TACTICX:DEMOB:UPDATE
#
# Updates existing DEMOB tactic.

order define TACTICX:DEMOB:UPDATE {
    title "Update Tactic: Demobilize Personnel"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Group:" -for g
        enum g -listcmd {tacticx groupsOwnedByAgent $tactic_id}

        rcc "Mode:" -for mode
        selector mode {
            case SOME "Demobilize some of the group's personnel" {
                rcc "Personnel:" -for personnel
                text personnel
            }

            case ALL "Demobilize all of the group's remaining personnel" {}
        }
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -oneof [tacticx::DEMOB ids]
    returnOnError

    # NEXT, get the tactic
    set tactic [tacticx get $parms(tactic_id)]

    prepare g                    -oneof [group ownedby [$tactic agent]]
    prepare mode       -toupper  -selector
    prepare personnel  -num      -type  ipositive

    returnOnError

    # NEXT, do the cross checks
    fillparms parms [$tactic view]

    if {$parms(mode) eq "SOME"} {
        if {$parms(personnel) == 0} {
            reject personnel "Must be positive when mode is SOME."
        }
    }

    returnOnError -final

    # NEXT, update the tactic, saving the undo script
    set undo [$tactic update_ {g mode personnel} [array get parms]]

    # NEXT, modify the tactic
    setundo $undo
}


