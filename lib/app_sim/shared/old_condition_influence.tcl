#-----------------------------------------------------------------------
# TITLE:
#    condition_influence.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): INFLUENCE Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: INFLUENCE(a,n,comp,,amount)
#
# How does actor a's influence in n compare with some amount?

condition type define INFLUENCE {a n op1 x1} {
    typemethod narrative {cdict} {
        dict with cdict {
            set comp   [ecomparator longname $op1]
            set amount [format %.2f $x1]
            return "Actor $a's influence in $n is $comp $amount"
        }
    }

    typemethod check {cdict} {
        set result [list]
        dict with cdict {
            if {$a ni [actor names]} {
                lappend result "Actor $a no longer exists."
            }

            if {$n ni [nbhood names]} {
                lappend result "Neighborhood $n no longer exists."
            }
        }

        return [join $result " "]
    }

    typemethod eval {cdict} {
        dict with cdict {
            set influence [rdb onecolumn {
                SELECT influence FROM influence_na
                WHERE n=$n AND a=$a
            }]

            return [condition compare \
                        [format %.2f $influence] \
                        $op1                     \
                        [format %.2f $x1]]
        }
    }
}

# CONDITION:INFLUENCE:CREATE
#
# Creates a new INFLUENCE condition.

order define CONDITION:INFLUENCE:CREATE {
    title "Create Condition: Influence"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic/Goal ID:" -for cc_id
        condcc cc_id

        rcc ""
        label {
            This condition is met when
        }
        
        rcc "Actor:" -for a
        actor a
        label "'s influence on"

        rcc "Neighborhood:" -for n
        nbhood n

        rcc "Is:" -for op1
        enumlong op1 -dictcmd {ecomparator deflist}

        rcc "Amount:" -for x1
        frac x1
    }
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare a          -toupper  -required -type actor
    prepare n          -toupper  -required -type nbhood
    prepare op1        -toupper  -required -type ecomparator
    prepare x1         -num      -required -type rfraction

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) INFLUENCE

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:INFLUENCE:UPDATE
#
# Updates existing INFLUENCE condition.

order define CONDITION:INFLUENCE:UPDATE {
    title "Update Condition: Influence"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        cond condition_id -table conditions_INFLUENCE

        rcc ""
        label {
            This condition is met when
        }
        
        rcc "Actor:" -for a
        actor a
        label "'s influence on"

        rcc "Neighborhood:" -for n
        nbhood n

        rcc "Is:" -for op1
        comparator op1

        rcc "Amount:" -for x1
        frac x1
    }
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare a                       -toupper  -type actor
    prepare n                       -toupper  -type nbhood
    prepare op1                     -toupper  -type ecomparator
    prepare x1                      -num      -type rfraction     

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType INFLUENCE $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




