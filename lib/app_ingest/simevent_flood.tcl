#-----------------------------------------------------------------------
# TITLE:
#    simevent_flood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Simulation Event, FLOOD
#
#    This module implements the FLOOD event, which represents
#    a flood in a neighborhood at a particular week.
#
#    The "midlist", neighborhood, and start week are usually set on 
#    creation.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
simevent define FLOOD "Flood" {
    A "Flood" event represents a natural disaster consisting of
    serious flooding in a neighborhood with attendant loss of life.
} {
    A "Flood" event is represented in Athena as a "block" in a
    the SYSTEM agent's strategy.  The block will contain an
    EXECUTIVE tactic that will create a DISASTER abstract situation
    at the requested time for the requested duration.
} {
    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    #
    # No type-specific parameters.

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Initialize as a event bean.
        next

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    method SanityCheck {errdict} {
        # Just make sure it was created properly.
        assert {$n ne ""}
        assert {$week ne ""}

        return [next $errdict]
    }

    method narrative {} {
        # TBD: We'll want to get the neighborhood longname, ultimately.
        set t(n)    [coalesce [my get n] "???"]
        set t(week) [coalesce [my get week] "???"]

        set text "Flood in $t(n)"

        if {[my get duration] > 1} {
            append text " for [my get duration] weeks"
        }

        append text "."
    }


    method export {} {
        # Note: duration is handled by absit code.
        enscript {
            # %intent
            block add SYSTEM \\
                -intent  %qintent \\
                %timeopts
            tactic add - EXECUTIVE \\
                -command [list flood %n %duration]

        } %intent   [my intent]        \
          %qintent  [list [my intent]] \
          %timeopts [my timeopts 1]    \
          %n        [my get n]         \
          %duration [my get duration]
    }

    #-------------------------------------------------------------------
    # Order Helper Typemethods
}


#-----------------------------------------------------------------------
# EVENT:* orders

# SIMEVENT:FLOOD
#
# Updates existing FLOOD event.

order define SIMEVENT:FLOOD {
    title "Event: Flooding in Neighborhood"
    options -sendstates PREP

    form {
        rcc "Event ID" -for event_id
        text event_id -context yes \
            -loadcmd {beanload}

        rcc "Duration:" -for duration
        text duration -defvalue 1
        label "week(s)"
    }
} {
    # FIRST, prepare the parameters
    prepare event_id  -required -type simevent::FLOOD
    prepare duration  -num      -type ipositive
 
    returnOnError -final

    # NEXT, update the event.
    set e [simevent get $parms(event_id)]
    $e update_ {duration} [array get parms]

    return
}






