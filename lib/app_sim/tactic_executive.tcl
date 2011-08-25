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
#    text1 <= command
#    once  <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: EXECUTIVE

tactic type define EXECUTIVE {text1 once} {actor system} {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            set msg "Executive command: $text1"
            if {$once} {
                append msg " (once only)"
            }
            return $msg
        }
    }

    typemethod execute {tdict} {
        dict with tdict {
            if {[catch {
                rdb eval {SAVEPOINT executive}
                executive eval $text1
                rdb eval {RELEASE executive}
            } result eopts]} {
                rdb eval {ROLLBACK TO executive}

                sigevent log warning tactic "
                    EXECUTIVE: Failed to execute command {$text1}: $result
                " $owner

                executive errtrace
                return 0
            }

            sigevent log 1 tactic "
                EXECUTIVE: $text1
            " $owner
        }

        return 1
    }

}

# TACTIC:EXECUTIVE:CREATE
#
# Creates a new EXECUTIVE tactic.

order define TACTIC:EXECUTIVE:CREATE {
    title "Create Tactic: Executive Command"

    options \
        -sendstates {PREP PAUSED}

    parm owner     enum    "Owner"         -enumtype agent       \
                                           -context yes
    parm text1     command "Command"       -width 40
    parm once      enum    "Once Only?"    -enumtype eyesno      \
                                           -defval   YES
    parm priority  enum    "Priority"      -enumtype ePrioSched  \
                                           -displaylong yes      \
                                           -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   agent
    prepare text1
    prepare once     -toupper   -required -type   boolean
    prepare priority -tolower             -type   ePrioSched

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
    options \
        -sendstates {PREP PAUSED}                            \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id key  "Tactic ID"         -context yes               \
                                            -table   tactics_EXECUTIVE \
                                            -keys    tactic_id
    parm owner     disp    "Owner"
    parm text1     command "Command"        -width 40
    parm once      enum    "Once Only?"     -enumtype eyesno
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare text1
    prepare once       -toupper  -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType EXECUTIVE $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


