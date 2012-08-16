#-----------------------------------------------------------------------
# TITLE:
#    tactic_save.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): SAVE Tactic Definition
#
# This module defines the SAVE tactic.  See tactic(i) for the interface that
# each tactic type must provide.
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Tactic: SAVE
#
# int1 - Integer percentage of income to save to the actor's reserve.


tactic type define SAVE {int1} actor {
    typemethod narrative {tdict} {
        dict with tdict {
            return "Save $int1% of income for later use"
        }
    }

    typemethod dollars {tdict} {
        dict with tdict {
            set income [actor income $owner]
            return [moneyfmt [expr {$income*$int1/100.0}]]
        }
    }

    typemethod execute {tdict} {
        # FIRST, if there's no cash_on_hand, return 0.
        dict with tdict {
            array set cinfo [cash get $owner]

            let amount {min($cinfo(cash_on_hand), $cinfo(income)*$int1/100.0)}

            if {$amount == 0.0} {
                return 0
            }

            cash deposit $owner $amount

            sigevent log 2 tactic "
                SAVE: $owner saves \$[moneyfmt $amount] to reserve.
            " $owner

            return 1
        }
    }
}

# TACTIC:SAVE:CREATE
#
# Creates a new SAVE tactic.

order define TACTIC:SAVE:CREATE {
    title "Create Tactic: Save Money"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Percentage:"
        percent int1 -defvalue 10
        label "% of income"

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare int1                -required -type ipercent
    prepare priority -tolower             -type ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parm dict
    set parms(tactic_type) SAVE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:SAVE:UPDATE
#
# Updates existing SAVE tactic.

order define TACTIC:SAVE:UPDATE {
    title "Update Tactic: Save Money"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_SAVE -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Percentage:"
        percent int1 -defvalue 10
        label "% of income"
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id   -required -type tactic
    prepare int1        -required -type ipercent

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType SAVE $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


