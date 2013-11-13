#-----------------------------------------------------------------------
# TITLE:
#    tactic.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, SIGEVENT
#
#    A tactic is a bean that represents an action taken by an agent.
#    Tactics consume assets (money, personnel), and are contained by
#    strategy blocks.
#
#    Athena uses many different kinds of tactic.  This module
#    defines a base class for tactic types.
#
# EXECSTATUS:
#    Each tactic has an "execstatus" variable, an eexecstatus value
#    that indicates whether or not it executed, and if not why not.  The
#    valid values are as follows:
#
#    NONE            - Set at creation and on update
#    SKIPPED         - The tactic wasn't supposed to execute, and didn't.
#    FAIL_RESOURCES  - The tactic couldn't obligate its required 
#                      resources. 
#    SUCCESS         - The tactic executed successfully.
#
#    The execstatus is set to NONE automatically when the tactic is created
#    and when it is updated.  The other status values are set by 
#    the owning block as it tries to execute (otherwise, they'd need to
#    be set by each individual tactic type).
#
#-----------------------------------------------------------------------

# FIRST, create the class.
beanclass create tactic

# NEXT, define class methods
oo::objdefine tactic {
    # List of defined tactic types
    variable types

    # define typename title atypes ?options...? script
    #
    # typename - The tactic type name
    # title    - A tactic title
    # atypes   - The list of agent types this tactic type supports
    # options  - Other options
    # script   - The tactic's oo::define script
    #
    # The options are as follows:
    #
    # -onlock   - If present, the tactic executes on lock.  If not, not.
    #
    # Defines a new tactic type.

    method define {typename title atypes args} {
        # FIRST, get the options and script
        set optlist [lrange $args 0 end-1]
        set script  [lindex $args end]

        # NEXT, process the options
        array set opts {
            -onlock 0
        }

        while {[llength $optlist] > 0} {
            set opt [lshift optlist]

            switch -exact -- $opt {
                -onlock { 
                    set opts(-onlock) 1 
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # NEXT, create the new type
        set fullname ::tactic::$typename
        lappend types $fullname

        beanclass create $fullname {
            superclass ::tactic
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

            method atypes {} {
                return %s
            }

            method onlock {} {
                return %d
            }
        } $typename $title [list $atypes] $opts(-onlock)]
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
        return ::tactic::$typename
    }

    # typedict ?agent_type?
    #
    # Returns a dictionary of type objects and titles.  If agent_type is
    # given, the result is limited to tactics applicable to that
    # agent type.

    method typedict {{agent_type ""}} {
        set result [dict create]

        foreach type [my types] {
            if {$agent_type ne ""} {
                if {$agent_type ni [$type atypes]} {
                    continue
                }
            }
            dict set result $type "[$type typename]: [$type title]"
        }

        return $result
    }

    # titledict ?agent_type?
    #
    # Returns a dictionary of titles and type names.  If agent_type is
    # given, the result is limited to tactics applicable to that
    # agent type.

    method titledict {{agent_type ""}} {
        set result [dict create]

        foreach type [my types] {
            if {$agent_type ne ""} {
                if {$agent_type ni [$type atypes]} {
                    continue
                }
            }
            dict set result "[$type typename]: [$type title]" [$type typename]
        }

        return $result
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # groupsOwnedByAgent id
    #
    # id   - A tactic ID
    #
    # Returns a list of force and organization groups owned by the 
    # agent who owns the given tactic.  This is for use in order
    # dynaforms where the user must choose an owned group.

    method groupsOwnedByAgent {id} {
        if {[my exists $id]} {
            set tactic [my get $id]
            return [group ownedby [$tactic agent]]
        } else {
            return [list]
        }
    }

    # frcgroupsOwnedByAgent id
    #
    # id   - A tactic ID
    #
    # Returns a list of force groups owned by the 
    # agent who owns the given tactic.  This is for use in order
    # dynaforms where the user must choose an owned group.

    method frcgroupsOwnedByAgent {id} {
        if {[my exists $id]} {
            set tactic [my get $id]
            return [frcgroup ownedby [$tactic agent]]
        } else {
            return [list]
        }
    }

    # groupsOwnedAndUniformed id
    #
    # id   - A tactic ID
    #
    # Returns a list of uniformed force groups owned by the 
    # agent who owns the given tactic.  This is for use in order
    # dynaforms where the user must choose an owned group.

    method groupsOwnedAndUniformed {id} {
        if {[my exists $id]} {
            set tactic [my get $id]
            return [frcgroup ownedAndUniformed [$tactic agent]]
        } else {
            return [list]
        }
    }

    # allAgentsBut id
    #
    # id  - A tactic ID
    #
    # Returns a list of agents except the one that owns the 
    # given tactic.

    method allAgentsBut {id} {
        if {[my exists $id]} {
            set tactic [my get $id]
            set alist [actor names]
            return [ldelete alist [$tactic agent]]
        } else {
            return [list]
        }
    }

}


# NEXT, define instance methods
oo::define tactic {
    #-------------------------------------------------------------------
    # Instance Variables

    # Every tactic has a "id", due to being a bean.

    variable parent      ;# The tactic's owning block
    variable state       ;# The tactic's state: normal, disabled, invalid
    variable execstatus  ;# An eexecstatus value: NONE, SKIPPED, 
                          # FAIL_RESOURCES, or SUCCESS.
    variable faildict    ;# Dictionary of resource failure detail messages
                          # by eresource symbol.

    # Tactic types will add their own variables.

    #-------------------------------------------------------------------
    # Constructor

    constructor {} {
        next
        set parent     ""
        set state      normal
        set execstatus NONE
        set faildict   [dict create]
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These methods will rarely if ever be overridden by subclasses.

    # subject
    #
    # Set subject for notifier events.

    method subject {} {
        return "::tactic"
    }


    # typename
    #
    # Returns the tactic's typename

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
    # Returns the tactic's state: normal, disabled, invalid

    method state {} {
        return $state
    }

    # execstatus
    #
    # Returns the execution status.

    method execstatus {} {
        return $execstatus
    }

    # execflag
    #
    # Returns 1 if the tactic executed successfully, and 0 otherwise.

    method execflag {} {
        return [expr {$execstatus eq "SUCCESS"}]
    }

    #-------------------------------------------------------------------
    # Resource Failure Detail Management
    

    # Fail code message
    #
    # code    - An eresource code
    # message - The failure message
    # 
    # Saves the resource failure message.  This is for use by
    # obligate methods.

    method Fail {code message} {
        dict set faildict $code $message
    }

    # InsufficientCash cash cost
    #
    # cash   - Cash available
    # cost   - Cash required
    #
    # Returns 1 on insufficient cash, setting the failure message,
    # and 0 otherwise.  Cash is always sufficient on lock.

    method InsufficientCash {cash cost} {
        if {[strategy ontick] && $cost > $cash} {

            set cash [commafmt $cash]
            set cost [commafmt $cost]

            my Fail CASH "Required \$$cost, but had only \$$cash."

            return 1
        } else {
            return 0
        }
    }

    # InsufficientPersonnel available required
    #
    # available  - Personnel available
    # required   - Personnel required
    #
    # Returns 1 on insufficient personnel, setting the failure
    # message, and 0 otherwise.

    method InsufficientPersonnel {available required} {
        if {$required > $available} {
            my Fail PERSONNEL \
            "Required $required personnel, but had only $available available."
            return 1
        } else {
            return 0
        }
    }


    # faildict
    #
    # Returns the tactic's failure dictionary.

    method faildict {} {
        return $faildict
    }

    # failicon
    #
    # Returns the icon associated with the first failure
    # in the faildict., or "" if none.

    method failicon {} {
        set code [lindex [dict keys $faildict] 0]

        if {$code ne ""} {
            return [eresource as icon $code]
        } else {
            return ""
        }
    }

    # failures
    #
    # Returns a list of the resource failure messages.

    method failures {} {
        return [dict values $faildict]
    }

    #-------------------------------------------------------------------
    # Tactic Reset

    # reset
    #
    # Resets the execution status of the tactic.

    method reset {} {
        my set execstatus NONE
        my set faildict   [dict create]
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
    # obligate, and ExecuteTactic methods.

    # check
    #
    # Sanity checks the tactic, returning a dict of variable names
    # and error strings:
    #
    #   $var -> $errmsg 
    #
    # If the dict is empty, there are no problems.

    method check {} {
        set errdict [my SanityCheck [dict create]]

        if {[dict size $errdict] > 0} {
            my set state invalid
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
    # Thus allowing parent classes their chance at it.

    method SanityCheck {errdict} {
        return $errdict
    }

    # narrative
    #
    # Computes a narrative for this tactic, for use in the GUI.

    method narrative {} {
        return "no narrative defined"
    }

    # obligate coffer
    #
    # coffer - A coffer object, representing the owning actor's
    #          current resources.
    #
    # Obligates the resources for use by this tactic, updating
    # the coffer.  Returns 1 on success, and 0 on failure.
    #
    # Subclasses override ObligateResources.  The obligation is
    # known to have failed if the subclass has registered a
    # resource failure using [my Fail] or one of the other
    # helper methods.

    method obligate {coffer} {
        # FIRST, initialize the failure dictionary
        my set faildict [dict create]

        my ObligateResources $coffer

        return [expr {[dict size $faildict] == 0}]
    }

    # ObligateResources coffer
    #
    # coffer - A coffer object, representing the owning actor's
    #          current resources.
    #
    # Obligates resources required by this tactic, updating
    # the coffer.  Subclasses should override this method.  
    # It is not necessary to call "next".  However, the
    # method should call [my Fail] on resource failure.
    # (This is done automatically by [my InsufficientCash]
    # and [my InsufficientTroops]).

    method ObligateResources {coffer} {
        # By default, obligation trivally succeeds.
    }

    # execute
    #
    # Executes this tactic using the obligated resources.
    # It is assumed that the tactic can execute, given that
    # the tactic is not invalid and the resources were obligated.

    method execute {} {
        # Every tactic should override this.
        error "Tactic execution is undefined"
    }

    #-------------------------------------------------------------------
    # Event Handlers and Order Mutators
    #
    # Order mutators are special operations used to modify this object in 
    # response to user input.  Mutators return an undo script that will
    # undo the change, or "" if the change cannot be undone.
    #
    # Event Handlers do additional work when the object is mutated.

    # onUpdate_
    #
    # On update_, resets status data and does a sanity check
    # if appropriate.
    
    method onUpdate_ {} {
        # FIRST, clear the execstatus; the tactic has changed, and
        # is effectively different from any tactic that ran previously.
        my reset

        # NEXT, Check only if the tactic is not disabled; otherwise, if you
        # try to disable an invalid tactic so that you can lock the
        # scenario, it gets marked invalid again.

        if {$state ne "disabled"} {
            my check
        }

        next
    }

    # onPaste_
    #
    # Pasted objects are like new objects.  Reset execution
    # status data.

    method onPaste_ {} {
        my reset
        next
    }
}


# TACTIC:STATE
#
# Sets a tactic's state to normal or disabled.  The order dialog
# is not generally used.

order define TACTIC:STATE {
    title "Set Tactic State"

    options -sendstates {PREP PAUSED}

    form {
        label "Tactic ID:" -for tactic_id
        text tactic_id -context yes

        rc "State:" -for state
        text state
    }
} {
    # FIRST, prepare and validate the parameters
    prepare tactic_id -required          -type tactic
    prepare state     -required -tolower -type ebeanstate
    returnOnError -final

    set tactic [tactic get $parms(tactic_id)]

    # NEXT, update the block, clearing the execution status
    setundo [$tactic update_ {state} [array get parms]]
}



