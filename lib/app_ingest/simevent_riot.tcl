#-----------------------------------------------------------------------
# TITLE:
#    simevent_riot.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Simulation Event, RIOT
#
#    This module implements the RIOT event, which represents a violent 
#    public disturbance by residents of a neighborhood.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
simevent define RIOT "Riot" {
    A "Riot" event represents a violent public disturbance by residents of 
    a neighborhood.  The cause of the riot and what the rioters target for 
    violence are not always related.  The event will affect all groups in 
    the neighborhood.<p>

    The duration of a "Riot" event is always 1 week; reports from 
    successive weeks will generate additional events.  
} {
    An "Riot" event is represented in Athena as a "block" in the 
    SYSTEM agent's strategy.  The block will contain a CURSE tactic that 
    injects the attitude effects of the riot on the civilians into the 
    attitude model.<p>

    Note that "Riot" is distinct from the "Civilian Casualties" 
    event, which reflects actual civilian deaths.
} {
    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    #
    # No type-specific parameters.

    # TBD: Might eventually add a magnitude.

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

    method canedit {} {
        return 0
    }

    method canextend {} {
        return 0
    }


    method narrative {} {
        set t(n) [nbhood fullname [my get n]]

        return "Riot in $t(n)."
    }


    method export {} {
        enscript {
            # %intent
            block add SYSTEM \\
                -intent  %qintent \\
                %timeopts
            make_riot - %n
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

# SIMEVENT:RIOT
#
# Updates existing RIOT event.

# NONE.  This event type cannot be edited.







