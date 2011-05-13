#-----------------------------------------------------------------------
# TITLE:
#    condition_troops.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): TROOPS Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: TROOPS(g,comp,amount)
#
# How does group g's number of troops in the playbox compare with some 
# amount?

condition type define TROOPS {g op1 x1} {
    typemethod narrative {cdict} {
        dict with cdict {
            set comp   [ecomparator longname $op1]
            return [normalize "
                Group $g's total number of personnel in the playbox is 
                $comp [commafmt [expr int($x1)]].
            "]
        }
    }

    typemethod check {cdict} {
        dict with cdict {
            if {$g ni [ptype fog names]} {
                return "Force/organization group $g no longer exists."
            }
        }

        return
    }

    typemethod eval {cdict} {
        dict with cdict {
            # If the group is owned by the condition's owner, use the
            # transient number of troops; otherwise, the static value.
            set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$g}]

            if {$a eq $owner} {
                set troops [personnel inplaybox $g]
            } else {
                set troops [rdb onecolumn {
                    SELECT personnel FROM personnel_g WHERE g=$g
                }]
            }

            return [condition compare $troops $op1 $x1]
        }
    }
}

# CONDITION:TROOPS:CREATE
#
# Creates a new TROOPS condition.

order define CONDITION:TROOPS:CREATE {
    title "Create Condition: Troops"

    options -sendstates {PREP PAUSED}

    parm cc_id     key   "Tactic/Goal ID" -context yes         \
                                          -table   cond_collections \
                                          -keys    cc_id
    parm g         enum  "Group"          -enumtype {ptype fog}
    parm op1       enum  "Comparison"     -enumtype ecomparator \
                                          -displaylong yes
    parm x1        text  "Amount"
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare g          -toupper  -required -type {ptype fog}
    prepare op1        -toupper  -required -type ecomparator
    prepare x1         -toupper  -required -type count

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) TROOPS

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:TROOPS:UPDATE
#
# Updates existing TROOPS condition.

order define CONDITION:TROOPS:UPDATE {
    title "Update Condition: Troops"
    options \
        -sendstates {PREP PAUSED}                              \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key   "Condition ID"  -context yes          \
                                            -table   conditions   \
                                            -keys    condition_id
    parm g            enum  "Group"         -enumtype {ptype fog}
    parm op1          enum  "Comparison"    -enumtype ecomparator \
                                            -displaylong yes
    parm x1           text  "Amount"
                
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare g                       -toupper  -type {ptype fog}
    prepare op1                     -toupper  -type ecomparator
    prepare x1                      -toupper  -type count

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType TROOPS $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




