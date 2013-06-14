#-----------------------------------------------------------------------
# TITLE:
#    tactic_aaaa.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): AAAA(amount, glist)
#
#    This module implements the AAAA tactic, which is used to test
#    data entry for gofer types we've not used yet.
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: AAAA

tactic type define AAAA {alist flist glist on_lock} actor {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {}

        return "Test tactic"
    }

    typemethod check {tdict} {
        return ""
    }

    typemethod execute {tdict} {
        dict with tdict {}

        # TBD: Nothing to do yet.

        return 1
    }

}

# TACTIC:AAAA:CREATE
#
# Creates a new AAAA tactic.

order define TACTIC:AAAA:CREATE {
    title "Create Tactic: AAAA"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Actors:" -for alist
        gofer alist -typename gofer::ACTORS

        rcc "Force Groups:" -for flist
        gofer flist -typename gofer::FRCGROUPS

        rcc "Groups:" -for glist
        gofer glist -typename gofer::GROUPS

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock -defvalue 1

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare alist               -required -type gofer::ACTORS
    prepare flist               -required -type gofer::FRCGROUPS
    prepare glist               -required -type gofer::GROUPS
    prepare on_lock                       -type boolean
    prepare priority -tolower             -type ePrioSched
 
    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) AAAA

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:AAAA:UPDATE
#
# Updates existing AAAA tactic.

order define TACTIC:AAAA:UPDATE {
    title "Update Tactic: Fund ENI Services"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_AAAA -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Actors:" -for alist
        gofer alist -typename gofer::ACTORS

        rcc "Force Groups:" -for flist
        gofer flist -typename gofer::FRCGROUPS

        rcc "Groups:" -for glist
        gofer glist -typename gofer::GROUPS

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type   tactic
    prepare alist                -type   gofer::ACTORS
    prepare flist                -type   gofer::FRCGROUPS
    prepare glist                -type   gofer::GROUPS
    prepare on_lock              -type   boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType AAAA $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}



