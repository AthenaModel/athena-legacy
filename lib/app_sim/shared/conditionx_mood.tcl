#-----------------------------------------------------------------------
# TITLE:
#    conditionx_mood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Condition, MOOD
#
#-----------------------------------------------------------------------

# FIRST, create the class.
conditionx define MOOD "Group Mood" {
    #-------------------------------------------------------------------
    # Instance Variables

    variable g          ;# A civilian group
    variable comp       ;# An ecomparator value
    variable limit      ;# A satisfaction value
    
    #-------------------------------------------------------------------
    # Constructor

    # constructor ?block_?
    #
    # block_  - The block that owns the condition
    #
    # Creates a new tactic for the given block.

    constructor {{block_ ""}} {
        next $block_
        set g     ""
        set comp  EQ
        set limit 0.0
        my set state invalid   ;# g is still unknown.
    }

    #-------------------------------------------------------------------
    # Operations

    method narrative {} {
        set compt [ecomparator longname $comp]

        if {$g eq ""} {
            set gt "???"
        } else {
            set gt $g
        }

        return [normalize "Group $gt's mood is $compt [qsat format $limit]"]
    }

    method SanityCheck {errdict} {
        if {$g ni [civgroup names]} {
            dict set errdict g "Group \"$g\" does not exist"
        }

        return [next $errdict]
    }

    method Evaluate {} {
        set mood [rdb onecolumn {
            SELECT mood FROM uram_mood WHERE g=$g
        }]

        set mood  [qsat format $mood]
        set limit [qsat format $limit]

        return [ecomparatorx compare $mood $comp $limit]
    }
}

#-----------------------------------------------------------------------
# CONDITIONX:* Orders


# CONDITIONX:MOOD:UPDATE
#
# Updates the condition's parameters

order define CONDITIONX:MOOD:UPDATE {
    title "Update MOOD Condition"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        text condition_id -context yes \
            -loadcmd {beanload}

        rcc ""
        label {
            This condition is met when
        }

        rcc "Group:" -for g
        civgroup g
        label "'s mood"

        rcc "Is:" -for comp
        comparator comp

        rcc "Amount:" -for limit
        sat limit
    }
} {
    # FIRST, prepare and validate the parameters
    prepare condition_id -required -oneof [conditionx::MOOD ids]
    prepare g                      -toupper  -type civgroup
    prepare comp                   -toupper  -type ecomparatorx
    prepare limit        -num      -toupper  -type qsat
    returnOnError -final

    set cond [conditionx get $parms(condition_id)]

    # NEXT, update the block
    setundo [$cond update_ {g comp limit} [array get parms]]
}

