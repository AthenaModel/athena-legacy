#-----------------------------------------------------------------------
# TITLE:
#    simevent_drought.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Simulation Event, DROUGHT
#
#    This module implements the DROUGHT event, which represents
#    a drought in a neighborhood at a particular week.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
simevent define DROUGHT "Drought" {
    A "Drought" event represents a shortage of water for agricultural
    and industrial purposes in a neighborhood (rather than a shortage
    of drinking water). "Drought" will affect all civilian groups in the 
    neighborhood, but will affect subsistence agriculture groups more.
} {
    A "Drought" event is represented in Athena as a "block" in the 
    SYSTEM agent's strategy.  The block will contain a CURSE tactic
    that injects the attitude effects of the drought on the civilians
    into the attitude model.  Civilians living by subsistence agriculture
    will be affected more than others.<p>

    Note that drought is distinct from the NOWATER abstract situation,
    which reflects a water supply that has been disabled by enemy action,
    and also from the BADWATER abstract situation, which reflects a 
    water supply that has been contaminated.
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

        set text "Drought in $t(n)"

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
            tactic add - CURSE \\
                -curse DROUGHT \\
                -roles [list @NONSACIV [gofer civgroups non_sa_in %n] \\
                             @SACIV    [gofer civgroups sa_in %n]]
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

# SIMEVENT:DROUGHT
#
# Updates existing DROUGHT event.

order define SIMEVENT:DROUGHT {
    title "Event: Drought in Neighborhood"

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
    prepare event_id  -required -type simevent::DROUGHT
    prepare duration  -num      -type ipositive
 
    returnOnError -final

    # NEXT, update the event.
    set e [simevent get $parms(event_id)]
    $e update_ {duration} [array get parms]

    return
}






