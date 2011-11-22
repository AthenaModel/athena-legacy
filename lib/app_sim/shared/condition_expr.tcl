#-----------------------------------------------------------------------
# TITLE:
#    condition_expr.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): EXPR Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
# PARAMETERS:
#    text1 <= expression
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: EXPR(text1)
#
# How does the expr of civgroup g
# compare with some amount?

condition type define EXPR {text1} {
    typemethod narrative {cdict} {
        dict with cdict {
            return [normalize "
                Expression: $text1
            "]
        }
    }

    typemethod check {cdict} {
        # Alas, it will be checked in use.
        return
    }

    typemethod eval {cdict} {
        dict with cdict {
            if {[catch {
                set flag [executive eval [list expr $text1]]
            } result eopts]} {
                # FAILURE

                sigevent log error tactic "
                    EXPR condition: In $owner's strategy, 
                    failed to evaluate expression {$text1}: $result
                " $owner

                # Return nothing; this condition has no value.
                return ""
            }

            # SUCCESS
            return $flag
        }
    }
}

# CONDITION:EXPR:CREATE
#
# Creates a new EXPR condition.

order define CONDITION:EXPR:CREATE {
    title "Create Condition: Boolean Expression"

    options -sendstates {PREP PAUSED}

    parm cc_id     key   "Tactic/Goal ID" -context yes              \
                                          -table   cond_collections \
                                          -keys    cc_id
    parm text1     expr  "Expression"     
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type cond_collection
    prepare text1                -required

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) EXPR

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:EXPR:UPDATE
#
# Updates existing EXPR condition.

order define CONDITION:EXPR:UPDATE {
    title "Update Condition: Group Expr"
    options \
        -sendstates {PREP PAUSED}                              \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key   "Condition ID"  -context yes          \
                                            -table   conditions   \
                                            -keys    condition_id
    parm text1        expr  "Expression"
                
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare text1

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType EXPR $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}



