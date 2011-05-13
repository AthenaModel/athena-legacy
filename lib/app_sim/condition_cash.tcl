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

            return [condition compare $cash $op1 $x1]
        }
    }
}

# CONDITION:CASH:CREATE
#
# Creates a new CASH condition.

order define CONDITION:CASH:CREATE {
    title "Create Condition: Cash Reserve"

    options -sendstates {PREP PAUSED}

    parm cc_id     key   "Tactic/Goal ID" -context yes         \
                                          -table   cond_collections \
                                          -keys    cc_id
    parm a         actor "Actor"
    parm op1       enum  "Comparison"     -enumtype ecomparator \
                                          -displaylong yes
    parm x1        text  "Amount"
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
        -sendstates {PREP PAUSED}                              \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key   "Condition ID"  -context yes          \
                                            -table   conditions   \
                                            -keys    condition_id
    parm a            actor "Actor"         -table actors -keys a
    parm op1          enum  "Comparison"    -enumtype ecomparator \
                                            -displaylong yes
    parm x1           text  "Amount"
                
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




