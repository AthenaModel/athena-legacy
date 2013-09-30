#-----------------------------------------------------------------------
# TITLE:
#    tacticx.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, SIGEVENT
#
#    A SIGEVENT tactic writes a message to the sigevents log.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tacticx define SIGEVENT "Log Significant Event" {system actor} {
    #-------------------------------------------------------------------
    # Instance Variables

    variable msg        ;# The message to log.
    
    #-------------------------------------------------------------------
    # Constructor

    # constructor ?block_?
    #
    # block_  - The block that owns the tactic
    #
    # Creates a new tactic for the given block.

    constructor {{block_ ""}} {
        next $block_
        set msg ""
    }

    #-------------------------------------------------------------------
    # Operations

    # No special SanityCheck is required; this is 
    # No special obligation is required

    method narrative {} {
        if {$msg ne ""} {
            return "Logs \"$msg\" to the sigevents log"
        } else {
            return "Logs \"???\" to the sigevents log"
        }
    }

    method execute {} {
        if {$msg ne ""} {
            set output $msg
        } else {
            set output "*NULL*"
        }
        sigevent log 1 tactic "SIGEVENT: $output" [my agent]
    }
}

#-----------------------------------------------------------------------
# TACTICX:* orders

# TACTICX:SIGEVENT:UPDATE
#
# Updates the tactic's parameters

order define TACTICX:SIGEVENT:UPDATE {
    title "Update SIGEVENT Tactic"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID:" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Message:" -for msg
        text msg -width 40
    }
} {
    # FIRST, prepare and validate the parameters
    prepare tactic_id -required -oneof [tacticx::SIGEVENT ids]
    prepare msg       -required 
    returnOnError -final

    set tactic [tacticx get $parms(tactic_id)]

    # NEXT, update the block
    setundo [$tactic update_ {msg} [array get parms]]
}

