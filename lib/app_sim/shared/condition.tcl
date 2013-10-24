#-----------------------------------------------------------------------
# TITLE:
#    condition.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Conditions
#
#    A condition is an bean that represents a boolean proposition
#    regarding the state of the simulation.  It can be evaluated to 
#    determine whether or not the condition is currently met.
#
#    Athena uses many different kinds of condition.  This module
#    defines a base class for condition types.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
beanclass create condition

# NEXT, define class methods
#
# TBD: This is essentially the same as tactic; can we refactor this
# somehow?
oo::objdefine condition {
    # List of defined condition types
    variable types

    # define typename title atypes script
    #
    # typename - The condition type name
    # title    - A condition title
    # script   - The condition's oo::define script
    #
    # Defines a new condition type.

    method define {typename title script} {
        # FIRST, create the new type
        set fullname ::condition::$typename
        lappend types $fullname

        beanclass create $fullname {
            superclass ::condition
        }

        # NEXT, define the instance members.
        oo::define $fullname $script

        # NEXT, define type commands

        oo::objdefine $fullname [format {
            method typename {} {
                return "%s"
            }

            method title {} {
                return "%s"
            }
        } $typename $title]
    }

    # types
    #
    # Returns a list of the available types.

    method types {} {
        return $types
    }

    # typenames
    #
    # Returns a list of the names of the available types.

    method typenames {} {
        set result [list]

        foreach type [my types] {
            lappend result [$type typename]
        }

        return $result
    }

    # type typename
    #
    # name   A typename
    #
    # Returns the actual type object given the typename.

    method type {typename} {
        return ::condition::$typename
    }

    # typedict
    #
    # Returns a dictionary of type objects and titles.

    method typedict {} {
        set result [dict create]

        foreach type [my types] {
            dict set result $type "[$type typename]: [$type title]"
        }

        return $result
    }

    # titledict
    #
    # Returns a dictionary of titles and type names.

    method titledict {} {
        set result [dict create]

        foreach type [my types] {
            dict set result "[$type typename]: [$type title]" [$type typename]
        }

        return $result
    }
}


# NEXT, define instance methods
oo::define condition {
    #-------------------------------------------------------------------
    # Instance Variables

    variable parent   ;# The condition's owning block
                       # TBD: in the long run, it won't always be a block.
    variable state    ;# The condition's state
    variable metflag  ;# 1 if condition is met, 0 if it is unmet, 
                       # or "" if the result is unknown
    
    #-------------------------------------------------------------------
    # Constructor

    constructor {} {
        next
        set parent  ""
        set state   normal
        set metflag ""
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These methods will rarely if ever be overridden by subclasses.
    
    # subject
    #
    # Set subject for notifier events.

    method subject {} {
        return "::condition"
    }


    # typename
    #
    # Returns the condition's typename

    method typename {} {
        return [namespace tail [info object class [self]]]
    }

    # agent
    #
    # Returns the agent who owns the strategy that owns the block that
    # owns this condition.

    method agent {} {
        return [$parent agent]
    }
    
    # strategy 
    #
    # Returns the strategy that owns the block that owns this condition.

    method strategy {} {
        return [$parent strategy]
    }

    # block
    #
    # Returns the block that owns this condition.

    method block {} {
        return $parent
    }

    # state
    #
    # Returns the block's state, normal or invalid.

    method state {} {
        return $state
    }

    # isknown
    #
    # Returns 1 if the value of the metflag is known, and 0 otherwise.

    method isknown {} {
        return [expr {$metflag ne ""}]
    }

    # ismet
    #
    # Returns 1 if the value of the metflag is known, and the flag
    # is met.  Returns 0 otherwise.

    method ismet {} {
        return [expr {$metflag ne "" && $metflag}]
    }


    #-------------------------------------------------------------------
    # Views

    # view ?view?
    #
    # view   - A view name (ignored at present)
    #
    # Returns a view dictionary, for display.

    method view {{view ""}} {
        set result [next $view]

        dict set result agent     [my agent]
        dict set result narrative [my narrative]
        dict set result typename  [my typename]

        return $result
    }

    #-------------------------------------------------------------------
    # Operations
    #
    # These methods represent condition operations whose actions may
    # vary by condition type.
    #
    # Subclasses will usually need to override the SanityCheck, narrative,
    # and Evaluate methods.

    # reset
    #
    # Resets execution status variables.

    method reset {} {
        my set metflag ""
    }
    
    # check
    #
    # Sanity checks the condition, returning a dict of variable names
    # and error strings:
    #
    #   $var -> $errmsg 
    #
    # If the dict is empty, there are no problems.
    # If the subclass has possible sanity check failures, it should
    # override SanityCheck.

    method check {} {
        set errdict [my SanityCheck [dict create]]

        if {[dict size $errdict] > 0} {
            my set state invalid
            my set metflag ""
        } elseif {$state eq "invalid"} {
            my set state normal
        }

        return $errdict
    }

    # SanityCheck errdict
    #
    # errdict   - A dictionary of instance variable names and error
    #             messages.
    #
    # This command should check the class's variables for errors, and
    # add the error messages to the errdict, returning the errdict
    # on completion.  The usual pattern for subclasses is this:
    #
    #    ... check for errors ...
    #    return [next $errdict]
    #
    # thus allowing parent classes their chance at it.
    #
    # This method should be overridden by every condition type that
    # can have sanity check failures.

    method SanityCheck {errdict} {
        return $errdict
    }

    # narrative
    #
    # Returns the condition's narrative.  This should be overridden by 
    # the subclass.
    method narrative {} {
        return "no narrative defined"
    }

    # eval
    #
    # Evaluates the condition and saves the metflag.  The subclass
    # should override Evaluate.

    method eval {} {
        my set metflag [my Evaluate]
        return $metflag
    }

    # Evaluate
    #
    # This method should be overridden by every condition type; it
    # should compute whether the condition is met or not, and return
    # 1 if so and 0 otherwise.  The [eval] method will call it on
    # demand and cache the result.

    method Evaluate {} {
        return 1
    }

    #-------------------------------------------------------------------
    # Event Handlers

    # onUpdate_
    #
    # On update_, clears the metflag and does a sanity check, if appropriate.

    method onUpdate_ {} {
        # FIRST, clear execution status; the condition has changed, and
        # we don't know what its status is.
        my reset

        # NEXT, do a sanity check (unless it's already disabled)
        if {$state ne "disabled"} {
            my check
        }

        next
    }

    # onPaste_
    #
    # When a condition is pasted into another bean, resets relevant data.

    method onPaste_ {} {
        my reset
        next
    }

}

#-----------------------------------------------------------------------
# Orders

# CONDITION:STATE
#
# Sets a condition's state to normal or disabled.  The order dialog
# is not generally used.

order define CONDITION:STATE {
    title "Set Condition State"

    options -sendstates {PREP PAUSED}

    form {
        label "Condition ID:" -for condition_id
        text condition_id -context yes

        rc "State:" -for state
        text state
    }
} {
    # FIRST, prepare and validate the parameters
    prepare condition_id -required          -type condition
    prepare state        -required -tolower -type ebeanstate
    returnOnError -final

    set cond [condition get $parms(condition_id)]

    # NEXT, update the block
    setundo [$cond update_ {state} [array get parms]]
}




