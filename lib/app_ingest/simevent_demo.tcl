#-----------------------------------------------------------------------
# TITLE:
#    simevent_demo.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Simulation Event, DEMO
#
#    This module implements the DEMO event, which represents a non-violent 
#    demonstration by residents of a neighborhood.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
simevent define DEMO "Demonstration" {
    A "Demonstration" event represents a non-violent public assembly
    of people who are supporting a cause.  The event will affect all
    groups who reside in the neighborhood, but the effects will 
    depend on whether the residents like or dislike (have a positive
    or negative horizontal relationship with) the groups that are
    demonstrating.<p>

    One or more groups from the neighborhood can demonstrate during 
    the same week.  It doesn't matter whether they are demonstrating
    together or for separate (and possibly opposing) causes.<p>

    The duration of a "Demonstration" event is always 1 week; reports from 
    successive weeks will generate additional events.  
} {
    A "Demonstration" event is represented in Athena as a "block" in the 
    SYSTEM agent's strategy.  The block will contain a CURSE tactic for
    each individual group that is demonstrating in the neighborhood;
    the CURSE injects into the attitude model the effects of the 
    demonstration on the civilians in the neighborhood.
} {
    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters

    variable glist

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Initialize as a event bean.
        next

        # NEXT, initialize the variables
        set glist [list]

        # NEXT, Save the options
        my configure {*}$args

        # NEXT, default the glist.
        set nbhood [my get n]

        if {[llength $glist] == 0} {
            set glist [civgroup gIn [my get n]]
        }
    }

    #-------------------------------------------------------------------
    # Operations

    method canedit {} {
        return 1
    }

    method canextend {} {
        return 0
    }


    method narrative {} {
        set t(n) [nbhood fullname [my get n]]
        set t(glist) [join $glist ", "]

        return "Demonstration in $t(n) by $t(glist)."
    }


    method export {} {
        enscript {
            # %intent
            block add SYSTEM \\
                -intent  %qintent \\
                %timeopts
            make_demo - %n %glist
        } %intent   [my intent]        \
          %qintent  [list [my intent]] \
          %timeopts [my timeopts]      \
          %n        [my get n]         \
          %glist    [my get glist]
    }

    #-------------------------------------------------------------------
    # Order Helper Typemethods

    # nbhoodGroups event_id
    #
    # Retrieve the namedict for the groups living in the event's neighborhood.

    typemethod nbhoodGroups {event_id} {
        if {$event_id eq ""} {
            return ""
        }

        set e [simevent get $event_id]
        set n [$e get n]

        return [adb eval {
            SELECT g, longname FROM civgroups_view WHERE n=$n
        }]
    }
}


#-----------------------------------------------------------------------
# EVENT:* orders

# SIMEVENT:DEMO
#
# Updates existing DEMO event.

order define SIMEVENT:DEMO {
    title "Event: Demonstration in Neighborhood"
    options -sendstates PREP

    form {
        rcc "Event ID" -for event_id
        text event_id -context yes \
            -loadcmd {beanload}

        rcc "Demonstrating Groups:" -for glist
        enumlonglist glist \
            -showkeys yes  \
            -width    30   \
            -dictcmd  {::simevent::DEMO nbhoodGroups $event_id}
    }
} {
    # FIRST, prepare the parameters
    prepare event_id   -required -type simevent::DEMO
    returnOnError

    set e [simevent get $parms(event_id)]

    prepare glist -required -toupper -someof [::civgroup gIn [$e get n]]
 
    returnOnError -final

    # NEXT, update the event.
    $e update_ {casualties} [array get parms]

    return
}







