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
# TBD: Move this info into condition(i).
#
# Every Condition Type defines an ensemble, ::condition::<type>>,
# with the following subcommands, each of which operations on a 
# dictionary of the condition's parameters (and possibly other 
# arguments):
#
#    narrative cdict
#        Creates a narrative description of the condition.
#
#    check cdict
#        Sanity checks the condition.  Note that this routine only 
#        needs to look for things that can change after the condition 
#        was created, e.g., an actor that no longer exists.  
#        Returns a message describing the error if the condition is 
#        invalid, and the empty string otherwise.
#
#    eval cdict
#        Evaluates the condition, returning 1 if true and 0 if false.
#        The "eval" subcommand will be called only after the simulation
#        is locked, and should always be able to compute a value for
#        a condition with "normal" state.
#
# ORDERS:
#
# * The UPDATE orders are expected to use RefreshUPDATE so that the
#   user cannot switch to a different condition.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: CASH(a,comp,amount)
#
# How does actor a's cash-on-hand compare with some amount?

condition type define CASH {
    typemethod narrative {cdict} {
        dict with cdict {
            set comp   [ecomparator longname $text1]
            set amount [moneyfmt $x1]
            return "Actor $a's cash-on-hand is $comp \$$amount"
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
            # Get the actor's cash reserves
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

    parm co_id     key   "Tactic/Goal ID" -context yes         \
                                          -table   cond_owners \
                                          -keys    co_id
    parm a         actor "Actor"
    parm text1     enum  "Comparison"     -enumtype ecomparator \
                                          -displaylong yes
    parm x1        text  "Amount"
} {
    # FIRST, prepare and validate the parameters
    prepare co_id                -required -type cond_owner
    prepare a          -toupper  -required -type actor
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
        -sendstates {PREP PAUSED}                              \
        -refreshcmd {orderdialog refreshForKey condition_id *}

    parm condition_id key   "Condition ID"  -context yes          \
                                            -table   conditions   \
                                            -keys    condition_id
    parm a            actor "Actor"         -table actors -keys a
    parm text1        enum  "Comparison"    -enumtype ecomparator \
                                            -displaylong yes
    parm x1           text  "Amount"
                
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare a                       -toupper  -type actor
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

