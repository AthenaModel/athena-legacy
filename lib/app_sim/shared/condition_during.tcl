#-----------------------------------------------------------------------
# TITLE:
#    condition_during.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): DURING Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: DURING(t1,t2)
#
# Is t1 <= now() <= t2?

condition type define DURING {t1 t2} {
    typemethod narrative {cdict} {
        dict with cdict {
            set z1 [simclock toZulu $t1]
            set z2 [simclock toZulu $t2]

            return [normalize "
                The current simulation time is between week $t1 and week $t2,
                inclusive, i.e., from $z1 to $z2.
            "]
        }
    }

    typemethod eval {cdict} {
        dict with cdict {
            set t [simclock now]

            return [expr {$t1 <= $t && $t <= $t2}]
        }
    }
}

# CONDITION:DURING:CREATE
#
# Creates a new DURING condition.

order define CONDITION:DURING:CREATE {
    title "Create Condition: During"

    options -sendstates {PREP PAUSED}

    parm cc_id     key   "Tactic/Goal ID" -context yes         \
                                          -table   cond_collections \
                                          -keys    cc_id
    parm t1        text  "Start Week"          
    parm t2        text  "End Week"
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare t1         -toupper  -required -type {simclock timespec}
    prepare t2         -toupper  -required -type {simclock timespec}

    returnOnError

    validate t2 {
        if {$parms(t2) < $parms(t1)} {
            reject t2 "End week must be no earlier than start week."
        }
    }

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) DURING

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:DURING:UPDATE
#
# Updates existing DURING condition.

order define CONDITION:DURING:UPDATE {
    title "Update Condition: During"
    options \
        -sendstates {PREP PAUSED}                              \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key   "Condition ID"  -context yes          \
                                            -table   conditions   \
                                            -keys    condition_id
    parm t1           text  "Start Week"          
    parm t2           text  "End Week"
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required  -type condition
    prepare t1            -toupper   -type {simclock timespec}
    prepare t2            -toupper   -type {simclock timespec}

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType DURING $parms(condition_id)  
    }

    # NEXT, make sure this is a valid interval.  Retrieve the previous
    # values of t1 and t2 if they are needed.

    if {$parms(t1) eq ""} {
        set parms(t1) [rdb onecolumn {
            SELECT t1 FROM conditions WHERE condition_id=$parms(condition_id)
        }]
    }

    if {$parms(t2) eq ""} {
        set parms(t2) [rdb onecolumn {
            SELECT t2 FROM conditions WHERE condition_id=$parms(condition_id)
        }]
    }

    validate t2 {
        if {$parms(t2) < $parms(t1)} {
            reject t2 "End week must be no earlier than start week."
        }
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




