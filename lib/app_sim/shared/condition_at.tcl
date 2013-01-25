#-----------------------------------------------------------------------
# TITLE:
#    condition_at.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): AT Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: AT(t1)
#
# Is now() == t1?

condition type define AT {t1} {
    typemethod narrative {cdict} {
        dict with cdict {
            set z1 [simclock toString $t1]

            return [normalize "
                The current simulation time is week $t1,
                i.e., $z1.
            "]
        }
    }

    typemethod eval {cdict} {
        # FIRST, if the condition time is "now" then return true, else false.
        dict with cdict {
            set t [simclock now]
            return [expr {$t == $t1}]
        }
    }
}

# CONDITION:AT:CREATE
#
# Creates a new AT condition.

order define CONDITION:AT:CREATE {
    title "Create Condition: At"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic/Goal ID:" -for cc_id
        condcc cc_id

        rcc "" -width 3in
        label {
            This condition is met when the current simulation time
            is exactly
        }
        rcc "Week:" -for t1
        text t1
    }
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare t1         -toupper  -required -type {simclock timespec}

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) AT

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:AT:UPDATE
#
# Updates existing AT condition.

order define CONDITION:AT:UPDATE {
    title "Update Condition: At"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        cond condition_id -table conditions_AT

        rcc "" -width 3in
        label {
            This condition is met when the current simulation time
            is exactly
        }
        rcc "Week:" -for t1
        text t1
    }
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required            -type condition
    prepare t1            -required -toupper   -type {simclock timespec}

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType AT $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}





