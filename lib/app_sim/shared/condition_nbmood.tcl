#-----------------------------------------------------------------------
# TITLE:
#    condition_nbmood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Condition, NBMOOD
#
#-----------------------------------------------------------------------

# FIRST, create the class.
condition define NBMOOD "Neighborhood Mood" {
    #-------------------------------------------------------------------
    # Instance Variables

    variable n          ;# A neighborhood
    variable comp       ;# An ecomparator value
    variable limit      ;# A satisfaction value
    
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set n     ""
        set comp  EQ
        set limit 0.0
        my set state invalid   ;# n is still unknown.

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    method narrative {} {
        set compt [ecomparator longname $comp]

        if {$n eq ""} {
            set text "???"
        } else {
            set text $n
        }

        return [normalize "Neighborhood $text's mood is $compt [qsat format $limit]"]
    }

    method SanityCheck {errdict} {
        if {$n ni [nbhood names]} {
            dict set errdict n "Neighborhood \"$n\" does not exist"
        }

        return [next $errdict]
    }

    method Evaluate {} {
        set mood [rdb onecolumn {
            SELECT nbmood FROM uram_n WHERE n=$n
        }]

        set mood  [qsat format $mood]
        set limit [qsat format $limit]

        return [ecomparatorx compare $mood $comp $limit]
    }
}

#-----------------------------------------------------------------------
# CONDITION:* Orders


# CONDITION:NBMOOD
#
# Updates the condition's parameters

order define CONDITION:NBMOOD {
    title "Condition: Neighborhood Mood"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        text condition_id -context yes\
            -loadcmd {beanload}

        rcc ""
        label {
            This condition is met when
        }

        rcc "Neighborhood:" -for n
        nbhood n
        label "'s mood"

        rcc "Is:" -for comp
        comparator comp

        rcc "Amount:" -for limit
        sat limit
    }
} {
    # FIRST, prepare and validate the parameters
    prepare condition_id -required           -type condition::NBMOOD
    prepare n                      -toupper  -type nbhood
    prepare comp                   -toupper  -type ecomparatorx
    prepare limit        -num      -toupper  -type qsat
    returnOnError -final

    set cond [condition get $parms(condition_id)]

    # NEXT, update the block
    setundo [$cond update_ {n comp limit} [array get parms]]
}



