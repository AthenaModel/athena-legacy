#-----------------------------------------------------------------------
# TITLE:
#    condition_nbcoop.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): NBCOOP Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: NBCOOP(n, g, comp, amount)
#
# How does the cooperation of neighborhood n with group g
# compare with some amount?

condition type define NBCOOP {n g op1 x1} {
    typemethod narrative {cdict} {
        dict with cdict {
            set comp [ecomparator longname $op1]

            return [normalize "
                Neighborhood $n's cooperation with force group $g is
                $comp [qcooperation format $x1].
            "]
        }
    }

    typemethod check {cdict} {
        dict with cdict {
            if {$n ni [nbhood names]} {
                return "Neighborhood $n no longer exists."
            }

            if {$g ni [frcgroup names]} {
                return "Force group $g no longer exists."
            }
        }

        return
    }

    typemethod eval {cdict} {
        dict with cdict {
            set nbcoop [rdb onecolumn {
                SELECT nbcoop FROM uram_nbcoop WHERE n=$n AND g=$g
            }]

            set nbcoop [qcooperation format $nbcoop]
            set x1     [qcooperation format $x1]

            return [condition compare $nbcoop $op1 $x1]
        }
    }
}

# CONDITION:NBCOOP:CREATE
#
# Creates a new NBCOOP condition.

order define CONDITION:NBCOOP:CREATE {
    title "Create Condition: Neighborhood Cooperation"

    options -sendstates {PREP PAUSED}

    parm cc_id     key   "Tactic/Goal ID" -context yes              \
                                          -table   cond_collections \
                                          -keys    cc_id
    parm n         enum  "Neighborhood"   -enumtype nbhood
    parm g         enum  "Group"          -enumtype frcgroup
    parm op1       enum  "Comparison"     -enumtype ecomparator \
                                          -displaylong yes
    parm x1        text  "Amount"
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare n          -toupper  -required -type nbhood
    prepare g          -toupper  -required -type frcgroup
    prepare op1        -toupper  -required -type ecomparator
    prepare x1         -toupper  -required -type qcooperation

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) NBCOOP

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:NBCOOP:UPDATE
#
# Updates existing NBCOOP condition.

order define CONDITION:NBCOOP:UPDATE {
    title "Update Condition: Neighborhood Cooperation"
    options \
        -sendstates {PREP PAUSED}                              \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key   "Condition ID"  -context yes          \
                                            -table   conditions   \
                                            -keys    condition_id
    parm n            enum  "Neighborhood"  -enumtype nbhood
    parm g            enum  "Group"         -enumtype frcgroup
    parm op1          enum  "Comparison"    -enumtype ecomparator \
                                            -displaylong yes
    parm x1           text  "Amount"
                
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare n                       -toupper  -type nbhood
    prepare g                       -toupper  -type frcgroup
    prepare op1                     -toupper  -type ecomparator
    prepare x1                      -toupper  -type qcooperation

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType NBCOOP $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




