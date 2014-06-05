#-----------------------------------------------------------------------
# TITLE:
#    simevent_explosion.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Simulation Event, EXPLOSION
#
#    This module implements the EXPLOSION event, which represents
#    random explosions in a neighborhood at a particular week.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
simevent define EXPLOSION "Explosion" {
    An "Explosion" event represents a large explosion or series of 
    explosions that are seen as a significant threat in the neighborhood.
    An "Explosion" event will affect all civilian groups in the 
    neighborhood.<p>

    The duration of an "Explosion" event is always 1 week; reports from 
    successive weeks will generate additional events.  
} {
    An "Explosion" event is represented in Athena as a "block" in the 
    SYSTEM agent's strategy.  The block will contain a CURSE tactic that 
    injects the attitude effects of the explosion on the civilians into the 
    attitude model.<p>

    Note that "Explosion" is distinct from the "Civilian Casualties" 
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

        return "Explosion in $t(n)."
    }


    method export {} {
        enscript {
            # %intent
            block add SYSTEM \\
                -intent  %qintent \\
                %timeopts
            make_explosion - %n
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

# SIMEVENT:EXPLOSION
#
# Updates existing EXPLOSION event.

# NONE.  This event type cannot be edited.







