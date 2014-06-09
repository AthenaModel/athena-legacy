#-----------------------------------------------------------------------
# TITLE:
#    simevent_traffic.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Simulation Event, TRAFFIC
#
#    This module implements the TRAFFIC event, which represents
#    a transportation network blockage or breakdown in a neighborhood at 
#    a particular week.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
simevent define TRAFFIC "Traffic" {
    A "Random Traffic" event represents a significant disturbance or 
    blockage of the transportation network which causes hardship on 
    civilian groups.  The event will affect all groups in the neighborhood.
} {
    A "Random Traffic" event is represented in Athena as a "block" in the 
    SYSTEM agent's strategy.  The block will contain a CURSE tactic that 
    injects the attitude effects of the traffic disruption on the civilians 
    into the attitude model.
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

    method narrative {} {
        set t(n) [nbhood fullname [my get n]]

        set text "Traffic in $t(n)"

        if {[my get duration] > 1} {
            append text " for [my get duration] weeks"
        }

        append text "."
    }


    method export {} {
        enscript {
            # %intent
            block add SYSTEM \\
                -intent  %qintent \\
                %timeopts
            make_traffic - %n
        } %intent   [my intent]        \
          %qintent  [list [my intent]] \
          %timeopts [my timeopts]      \
          %n        [my get n]
    }

    #-------------------------------------------------------------------
    # Order Helper Typemethods
}


#-----------------------------------------------------------------------
# EVENT:* orders

# SIMEVENT:TRAFFIC
#
# Updates existing TRAFFIC event.

order define SIMEVENT:TRAFFIC {
    title "Event: Random Traffic in Neighborhood"
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
    prepare event_id  -required -type simevent::TRAFFIC
    prepare duration  -num      -type ipositive
 
    returnOnError -final

    # NEXT, update the event.
    set e [simevent get $parms(event_id)]
    $e update_ {duration} [array get parms]

    return
}






