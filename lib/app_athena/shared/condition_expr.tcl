#-----------------------------------------------------------------------
# TITLE:
#    condition_expr.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Condition, EXPR
#
#-----------------------------------------------------------------------

# FIRST, create the class.
condition define EXPR "Boolean Expression" {
    #-------------------------------------------------------------------
    # Instance Variables

    variable expression ;# The executive expression
    
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Initialize as a condition bean.
        next

        # NEXT, Initialize state variables
        set expression ""
        my set state invalid

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    method narrative {} {
        let expr {$expression ne "" ? $expression : "???"}
        return [normalize "Expression: $expr"]
    }

    method SanityCheck {errdict} {
        if {$expression eq ""} {
            dict set errdict expression "No expression has been specified"
        } elseif {[catch {executive expr validate $expression} result]} {
            dict set errdict expression $result
        }

        return [next $errdict]
    }

    method Evaluate {} {
        if {[catch {
            set flag [executive eval [list expr $expression]]
        } result eopts]} {
            # FAILURE

            sigevent log error tactic "
                EXPR condition: In [my agent]'s strategy, 
                failed to evaluate expression {$expression}: $result
            " [my agent]

            my set state invalid
            return 0
        }

        # SUCCESS
        return $flag
    }
}

#-----------------------------------------------------------------------
# CONDITION:* Orders


# CONDITION:EXPR
#
# Updates the condition's parameters

order define CONDITION:EXPR {
    title "Condition: Expr Numbers"

    options -sendstates PREP

    form {
        rcc "Condition ID:" -for condition_id
        text condition_id -context yes \
            -loadcmd {beanload}

        rcc ""
        label {
            This condition is met when the following Boolean
            expression is true.  See the help for the syntax,
            as well as for useful functions to use within it.
        }

        rcc "Expression:" -for expression
        expr expression
    }
} {
    prepare condition_id -required -type condition::EXPR

    # In the GUI, give detailed feedback on errors.  From other sources,
    # the sanity check will catch it.
    prepare expression -oncheck -type {executive expr}

    returnOnError -final

    set cond [condition get $parms(condition_id)]

    # NEXT, update the block
    setundo [$cond update_ {expression} [array get parms]]
}




