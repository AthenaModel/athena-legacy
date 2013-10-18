#-----------------------------------------------------------------------
# TITLE:
#    condition_compare.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Condition, COMPARE
#
#-----------------------------------------------------------------------

# FIRST, create the class.
condition define COMPARE "Compare Numbers" {
    #-------------------------------------------------------------------
    # Instance Variables

    variable x          ;# A gofer::NUMBER value
    variable comp       ;# An ecomparator value
    variable y          ;# A gofer::NUMBER value
    
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as tactic bean.
        next

        # Initialize state variables
        set x     [gofer construct NUMBER BY_VALUE 0]
        set comp  EQ
        set y     [gofer construct NUMBER BY_VALUE 0]

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    method narrative {} {
        set xt    [my GoferNarrative $x]
        set compt [ecomparator longname $comp]
        set yt    [my GoferNarrative $y]

        return [normalize "Compare whether $xt is $compt $yt"]
    }

    # GoferNarrative gdict
    #
    # gdict   - A gofer value
    #
    # Returns a narrative for a value that might not be a gofer value.

    method GoferNarrative {gdict} {
        set text [gofer narrative $gdict -brief]

        if {$text eq "Not a gofer type value"} {
            return "???"
        } else {
            return $text
        }
    }

    method SanityCheck {errdict} {
        if {[catch {gofer validate $x} result]} {
            dict set errdict x $result
        }

        if {[catch {gofer validate $y} result]} {
            dict set errdict y $result
        }

        return [next $errdict]
    }

    method Evaluate {} {
        set xval [gofer eval $x]
        set yval [gofer eval $y]

        return [ecomparatorx compare $xval $comp $yval]
    }
}

#-----------------------------------------------------------------------
# CONDITION:* Orders


# CONDITION:COMPARE
#
# Updates the condition's parameters

order define CONDITION:COMPARE {
    title "Condition: Compare Numbers"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        text condition_id -context yes \
            -loadcmd {beanload}

        rcc ""
        label {
            This condition is met when
        }

        rcc "X Value:" -for x
        gofer x -typename gofer::NUMBER

        rcc "Is:" -for comp
        comparator comp

        rcc "Y Value:" -for y
        gofer y -typename gofer::NUMBER
    }
} {
    # FIRST, prepare and validate the parameters
    prepare condition_id -required -oneof [condition::COMPARE ids]
    prepare x                      
    prepare comp         -toupper  -type ecomparatorx
    prepare y                      
    returnOnError -final

    set cond [condition get $parms(condition_id)]

    # NEXT, update the block
    setundo [$cond update_ {x comp y} [array get parms]]
}



