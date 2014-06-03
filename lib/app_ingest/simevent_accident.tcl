#-----------------------------------------------------------------------
# TITLE:
#    simevent_accident.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Simulation Event, ACCIDENT
#
#    This module implements the ACCIDENT event, which represents
#    random accidents in a neighborhood at a particular week.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
simevent define ACCIDENT "Accident" {
    An "Accident" event represents some small accident in the 
    neighborhood that temporarily causes the residents to fear for
    their lives. 
    "Accident" events will affect all civilian groups 
    in the neighborhood.
} {
    An "Accident" event is represented in Athena as a "block" in the 
    SYSTEM agent's strategy.  The block will contain a CURSE tactic that 
    injects the attitude effects of the accident on the civilians into the 
    attitude model.<p>

    Note that "Accident" is distinct from the "Civilian Casualties" 
    event, which reflects actual civilian deaths.
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

        set text "Accident in $t(n)"

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
            make_accident - %n
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

# SIMEVENT:ACCIDENT
#
# Updates existing ACCIDENT event.

order define SIMEVENT:ACCIDENT {
    title "Event: Accident in Neighborhood"
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
    prepare event_id  -required -type simevent::ACCIDENT
    prepare duration  -num      -type ipositive
 
    returnOnError -final

    # NEXT, update the event.
    set e [simevent get $parms(event_id)]
    $e update_ {duration} [array get parms]

    return
}






