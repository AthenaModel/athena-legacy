#-----------------------------------------------------------------------
# TITLE:
#    condition_nbmood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): NBMOOD Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: NBMOOD(n, comp, amount)
#
# How does the mood of neighborhood n
# compare with some amount?

condition type define NBMOOD {n op1 x1} {
    typemethod narrative {cdict} {
        dict with cdict {
            set comp [ecomparator longname $op1]

            return [normalize "
                Neighborhood $n's mood is
                $comp [qsat format $x1].
            "]
        }
    }

    typemethod check {cdict} {
        dict with cdict {
            if {$n ni [nbhood names]} {
                return "Neighborhood $n no longer exists."
            }
        }

        return
    }

    typemethod eval {cdict} {
        dict with cdict {
            set nbmood [rdb onecolumn {
                SELECT sat FROM gram_n WHERE n=$n
            }]

            set nbmood [qsat format $nbmood]
            set x1     [qsat format $x1]

            return [condition compare $nbmood $op1 $x1]
        }
    }
}

# CONDITION:NBMOOD:CREATE
#
# Creates a new NBMOOD condition.

order define CONDITION:NBMOOD:CREATE {
    title "Create Condition: Neighborhood Mood"

    options -sendstates {PREP PAUSED}

    parm cc_id     key   "Tactic/Goal ID" -context yes              \
                                          -table   cond_collections \
                                          -keys    cc_id
    parm n         enum  "Neighborhood"   -enumtype nbhood
    parm op1       enum  "Comparison"     -enumtype ecomparator \
                                          -displaylong yes
    parm x1        text  "Amount"
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare n          -toupper  -required -type nbhood
    prepare op1        -toupper  -required -type ecomparator
    prepare x1         -toupper  -required -type qsat

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) NBMOOD

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:NBMOOD:UPDATE
#
# Updates existing NBMOOD condition.

order define CONDITION:NBMOOD:UPDATE {
    title "Update Condition: Neighborhood Mood"
    options \
        -sendstates {PREP PAUSED}                              \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key   "Condition ID"  -context yes          \
                                            -table   conditions   \
                                            -keys    condition_id
    parm n            enum  "Neighborhood"  -enumtype nbhood
    parm op1          enum  "Comparison"    -enumtype ecomparator \
                                            -displaylong yes
    parm x1           text  "Amount"
                
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare n                       -toupper  -type nbhood
    prepare op1                     -toupper  -type ecomparator
    prepare x1                      -toupper  -type qsat

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType NBMOOD $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




