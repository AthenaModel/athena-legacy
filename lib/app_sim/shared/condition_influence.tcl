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

    parm cc_id     key   "Tactic/Goal ID" -context yes         \
                                          -table   cond_collections \
                                          -keys    cc_id
    parm a         actor "Actor"
    parm n         enum  "Neighborhood"   -enumtype nbhood
    parm op1       enum  "Comparison"     -enumtype ecomparator \
                                          -displaylong yes
    parm x1        text  "Amount"
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare a          -toupper  -required -type actor
    prepare n          -toupper  -required -type nbhood
    prepare op1        -toupper  -required -type ecomparator
    prepare x1         -toupper  -required -type rfraction

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
    options \
        -sendstates {PREP PAUSED}                              \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key   "Condition ID"  -context yes          \
                                            -table   conditions   \
                                            -keys    condition_id
    parm a            actor "Actor"         
    parm n            enum  "Neighborhood"  -enumtype nbhood
    parm op1          enum  "Comparison"    -enumtype ecomparator \
                                            -displaylong yes
    parm x1           text  "Amount"
                
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare a                       -toupper  -type actor
    prepare n                       -toupper  -type nbhood
    prepare op1                     -toupper  -type ecomparator
    prepare x1                      -toupper  -type rfraction     

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType INFLUENCE $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




