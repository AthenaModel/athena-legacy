#-----------------------------------------------------------------------
# TITLE:
#    simevent_civcas.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Simulation Event, CIVCAS
#
#    This module implements the CIVCAS event, which represents
#    civilian casualties in a neighborhood at a particular week.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
simevent define CIVCAS "Civilian Casualties" {
    A "Civilian Casualties" event represents some number of civilians
    killed in a neighborhood during the given week, either because they
    were directly targetted or as collateral damage resulting from
    conflict between force groups.<p>  Note that the duration of a 
    "Civilian Casualties" event is always one week; casualties in 
    successive weeks are treated as individual events.
} {
    A "Civilian Casualties" event is represented in Athena as a "block" in the 
    SYSTEM agent's strategy.  The block will contain an ATTRIT tactic that 
    causes the specified number of casualties in the given neighborhood in
    the given week.
} {
    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    variable casualties

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Initialize as a event bean.
        next

        # NEXT, initialize the variables
        set casualties 1

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    # CIVCAS events cannot extend over multiple weeks.
    method canextend {} {
        return 0
    }


    method narrative {} {
        set t(n) [nbhood fullname [my get n]]

        return "$casualties Civilian Casualties in $t(n)."
    }


    method export {} {
        enscript {
            # %intent
            block add SYSTEM \\
                -intent  %qintent \\
                %timeopts
            make_civcas - %n %casualties
        } %intent     [my intent]         \
          %qintent    [list [my intent]]  \
          %timeopts   [my timeopts]       \
          %n          [my get n]          \
          %casualties [my get casualties]
    }

    #-------------------------------------------------------------------
    # Order Helper Typemethods
}


#-----------------------------------------------------------------------
# EVENT:* orders

# SIMEVENT:CIVCAS
#
# Updates existing CIVCAS event.

order define SIMEVENT:CIVCAS {
    title "Event: Civilian Casualties in Neighborhood"
    options -sendstates PREP

    form {
        rcc "Event ID" -for event_id
        text event_id -context yes \
            -loadcmd {beanload}

        rcc "Casualties:" -for casualties
        text casualties 
        label "civilians killed"
    }
} {
    # FIRST, prepare the parameters
    prepare event_id   -required -type simevent::CIVCAS
    prepare casualties -num      -type ipositive
 
    returnOnError -final

    # NEXT, update the event.
    set e [simevent get $parms(event_id)]
    $e update_ {casualties} [array get parms]

    return
}






