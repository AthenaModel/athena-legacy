#-----------------------------------------------------------------------
# TITLE:
#    tactic_executive.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): EXECUTIVE(command,once) tactic
#
#    This module implements the EXECUTIVE tactic, which executes a 
#    single Athena executive command.
#
# PARAMETER MAPPING:
#
#    text1   <= command
#    once    <= once
#    on_lock <= on_lock
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: EXECUTIVE

tactic type define EXECUTIVE {text1 once on_lock} {actor system} {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            return  "Executive command: $text1"
        }
    }

    typemethod execute {tdict} {
        dict with tdict {
            # FIRST, set the order state to TACTIC, so that
            # relevant orders can be executed.

            set oldState [order state]
            order state TACTIC
                
            # NEXT, create a savepoint, so that we can back out
            # the command's changes on error.
            rdb eval {SAVEPOINT executive}
                

            # NEXT, attempt to run the user's command.
            if {[catch {
                executive eval $text1
            } result eopts]} {
                # FAILURE 

                # FIRST, roll back any changes made by the script; 
                # it threw an error, and we don't want any garbage
                # left behind.
                rdb eval {ROLLBACK TO executive}

                # NEXT, restore the old order state
                order state $oldState

                # NEXT, log failure.
                sigevent log error tactic "
                    EXECUTIVE: Failed to execute command {$text1}: $result
                " $owner

                executive errtrace
                return 0
            }
        }

        # SUCCESS

        # NEXT, release the savepoint; the script ran without
        # error.
        rdb eval {RELEASE executive}

        # NEXT, restore the old order state
        order state $oldState

        # NEXT, log success
        sigevent log 1 tactic "
            EXECUTIVE: $text1
        " $owner

        return 1
    }
}

# TACTIC:EXECUTIVE:CREATE
#
# Creates a new EXECUTIVE tactic.

order define TACTIC:EXECUTIVE:CREATE {
    title "Create Tactic: Executive Command"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Command:" -for text1
        text text1 -width 40
        
        rcc "Once Only?" -for once
        yesno once -defvalue 1

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock -defvalue 0

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type agent
    prepare text1
    prepare priority -tolower             -type ePrioSched
    prepare once     -toupper   -required -type boolean
    prepare on_lock                       -type boolean

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) EXECUTIVE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:EXECUTIVE:UPDATE
#
# Updates existing EXECUTIVE tactic.

order define TACTIC:EXECUTIVE:UPDATE {
    title "Update Tactic: Executive Command"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_EXECUTIVE -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Command:" -for text1
        text text1 -width 40
        
        rcc "Once Only?" -for once
        yesno once

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare text1
    prepare once       -toupper  -type boolean
    prepare on_lock              -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType EXECUTIVE $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}



