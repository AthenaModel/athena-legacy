#-----------------------------------------------------------------------
# TITLE:
#    condition_types.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Condition Type Definitions
#
# Every Condition Type defines an ensemble, ::condition::<type>>,
# with the following subcommands, each of which operations on a 
# dictionary of the condition's parameters (and possibly other 
# arguments):
#
#    narrative cdict
#        Creates a narrative description of the condition.
#
#    eval cdict a
#        Evaluates the condition, returning 1 if true, 0 if false,
#        and "" if we don't know, given actor a.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: CASH
#
# How does the actor's cash-on-hand compare with some amount?

snit::type ::condition::CASH {
    pragma -hasinstances no

    typemethod narrative {cdict} {
        dict with cdict {
            set comp   [ecomparator longname $text1]
            set amount [moneyfmt $x1]
            return "Actor's cash-on-hand is $comp \$$amount"
        }
    }

    typemethod eval {cdict a} {
        dict with cdict {
            # Get the owner's cash reserves
            set cash [actor get $a cash]

            # TBD: EQ should be an epsilon check
            switch $text1 {
                LT      { return [expr {$cash <  $x1}] }
                EQ      { return [expr {$cash == $x1}] }
                GT      { return [expr {$cash >  $x1}] }
                default { error "Invalid comparator: \"$comp\"" }
            }
        }
    }
}

# CONDITION:CASH:CREATE
#
# Creates a new CASH condition.

order define CONDITION:CASH:CREATE {
    title "Create Condition: Cash on hand"

    options -sendstates {PREP PAUSED}

    parm tactic_id key  "Tactic ID"    -table tactics -key tactic_id
    parm text1     enum "Comparison"   -type ecomparator -displaylong
    parm x1        text "Amount"
} {
    # FIRST, prepare and validate the parameters
    prepare tactic_id            -required -type tactic
    prepare text1      -toupper  -required -type ecomparator
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
    title "Update Condition: Cash on hand"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key  "Condition ID"  -table gui_conditions_CASH  \
                                           -key   condition_id
    parm tactic_id    disp "Tactic ID"
    parm text1        enum "Comparison"    -type ecomparator -displaylong
    parm x1           text "Amount"
                
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare text1                   -toupper  -type ecomparator
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



