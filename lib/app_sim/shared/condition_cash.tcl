#-----------------------------------------------------------------------
# TITLE:
#    condition_cash.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): CASH Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: CASH(a,comp,amount)
#
# How does actor a's cash reserve compare with some amount?

condition type define CASH {a op1 x1} {
    typemethod narrative {cdict} {
        dict with cdict {
            set comp   [ecomparator longname $op1]
            set amount [moneyfmt $x1]
            return "Actor $a's cash reserve is $comp \$$amount"
        }
    }

    typemethod check {cdict} {
        dict with cdict {
            if {$a ni [actor names]} {
                return "Actor $a no longer exists."
            }
        }

        return
    }

    typemethod eval {cdict} {
        dict with cdict {
            # Get the actor's cash reserve, transient or otherwise
            if {$a eq $owner} {
                set cash [cash get $owner cash_reserve]
            } else {
                set cash [actor get $a cash_reserve]
            }

            return [condition compare \
                        [format %.2f $cash] \
                        $op1                \
                        [format %.2f $x1]]
        }
    }
}

# CONDITION:CASH:CREATE
#
# Creates a new CASH condition.

order define CONDITION:CASH:CREATE {
    title "Create Condition: Cash Reserve"

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
        label "'s cash reserve"

        rcc "Is:" -for op1
        enumlong op1 -dictcmd {ecomparator deflist}

        rcc "Amount:" -for x1
        text x1
        label "dollars."
    }
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare a          -toupper  -required -type actor
    prepare op1        -toupper  -required -type ecomparator
    prepare x1         -toupper  -required -type money

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) CASH

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:CASH:UPDATE
#
# Updates existing CASH condition.

order define CONDITION:CASH:UPDATE {
    title "Update Condition: Cash Reserve"
    options \
        -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        cond condition_id

        rcc ""
        label {
            This condition is met when 
        }

        rcc "Actor:" -for a
        actor a
        label "'s cash reserve"

        rcc "Is:" -for op1
        comparator op1

        rcc "Amount:" -for x1
        text x1
        label "dollars."
    }
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare a                       -toupper  -type actor
    prepare op1                     -toupper  -type ecomparator
    prepare x1                      -toupper  -type money     

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType CASH $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




