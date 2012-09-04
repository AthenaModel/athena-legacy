#-----------------------------------------------------------------------
# TITLE:
#    condition_mood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): MOOD Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: MOOD(g, comp, amount)
#
# How does the mood of civgroup g
# compare with some amount?

condition type define MOOD {g op1 x1} {
    typemethod narrative {cdict} {
        dict with cdict {
            set comp [ecomparator longname $op1]

            return [normalize "
                Group $g's mood is $comp [qsat format $x1].
            "]
        }
    }

    typemethod check {cdict} {
        dict with cdict {
            if {$g ni [civgroup names]} {
                return "Group $g no longer exists."
            }
        }

        return
    }

    typemethod eval {cdict} {
        dict with cdict {
            set mood [rdb onecolumn {
                SELECT mood FROM uram_mood WHERE g=$g
            }]

            set mood [qsat format $mood]
            set x1   [qsat format $x1]

            return [condition compare $mood $op1 $x1]
        }
    }
}

# CONDITION:MOOD:CREATE
#
# Creates a new MOOD condition.

order define CONDITION:MOOD:CREATE {
    title "Create Condition: Group Mood"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic/Goal ID:" -for cc_id
        condcc cc_id

        rcc ""
        label {
            This condition is met when
        }

        rcc "Group:" -for g
        civgroup g
        label "'s mood"

        rcc "Is:" -for op1
        comparator op1

        rcc "Amount:" -for x1
        sat x1
    }
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare g          -toupper  -required -type civgroup
    prepare op1        -toupper  -required -type ecomparator
    prepare x1    -num -toupper  -required -type qsat

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) MOOD

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:MOOD:UPDATE
#
# Updates existing MOOD condition.

order define CONDITION:MOOD:UPDATE {
    title "Update Condition: Group Mood"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        cond condition_id

        rcc ""
        label {
            This condition is met when
        }

        rcc "Group:" -for g
        civgroup g
        label "'s mood"

        rcc "Is:" -for op1
        comparator op1

        rcc "Amount:" -for x1
        sat x1
    }
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare g                       -toupper  -type civgroup
    prepare op1                     -toupper  -type ecomparator
    prepare x1            -num      -toupper  -type qsat

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType MOOD $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




