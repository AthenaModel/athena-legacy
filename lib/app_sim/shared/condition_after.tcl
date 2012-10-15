#-----------------------------------------------------------------------
# TITLE:
#    condition_after.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): AFTER Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: AFTER(t1)
#
# Is now() > t1?

condition type define AFTER {t1} {
    typemethod narrative {cdict} {
        dict with cdict {
            set z1 [simclock toString $t1]

            return [normalize "
                The current simulation time is later than week $t1,
                i.e., after $z1.
            "]
        }
    }

    typemethod eval {cdict} {
        dict with cdict {
            set t [simclock now]

            return [expr {$t > $t1}]
        }
    }
}

# CONDITION:AFTER:CREATE
#
# Creates a new AFTER condition.

order define CONDITION:AFTER:CREATE {
    title "Create Condition: After"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic/Goal ID:" -for cc_id
        condcc cc_id

        rcc "" -width 3in
        label {
            This condition is met when the current simulation time
            is later than
        }

        rcc "Week:" -for t1
        # TBD: Consider defining a new simtime field type.
        text t1
    }
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare t1         -toupper  -required -type {simclock timespec}

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) AFTER

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:AFTER:UPDATE
#
# Updates existing AFTER condition.

order define CONDITION:AFTER:UPDATE {
    title "Update Condition: After"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        cond condition_id

        rcc "" -width 3in
        label {
            This condition is met when the current simulation time 
            is later than 
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
        condition RequireType AFTER $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}





