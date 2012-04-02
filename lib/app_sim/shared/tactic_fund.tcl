#-----------------------------------------------------------------------
# TITLE:
#    tactic_fund.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): FUND(a, amount)
#
#    This module implements the FUND tactic, which gives some amount
#    of funds to another actor.
#
# PARAMETER MAPPING:
#
#    a     <= a
#    x1    <= amount
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: FUND

tactic type define FUND {a x1} actor {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            return "Fund actor $a with \$[moneyfmt $x1]/week."
        }
    }

    typemethod dollars {tdict} {
        dict with tdict {
            return [moneyfmt $x1]
        }
    }

    typemethod check {tdict} {
        set errors [list]

        dict with tdict {
            # a
            if {$a ni [actor names]} {
                lappend errors "Actor $a no longer exists."
            }
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        dict with tdict {
            # FIRST, Consume the money, if we can.
            if {![cash spend $owner $x1]} {
                return 0
            }

            # NEXT, give the money to the other actor.
            cash give $a $x1
           
            sigevent log 2 tactic "
                FUND: Actor {actor:$owner} funds {actor:$a}
                with \$[moneyfmt $x1]/week.
            " $owner $a
        }

        return 1
    }
}

# TACTIC:FUND:CREATE
#
# Creates a new FUND tactic.

order define TACTIC:FUND:CREATE {
    title "Create Tactic: Fund Actor"

    options \
        -sendstates {PREP PAUSED}

    parm owner     actor "Owner"             -context yes
    parm a         actor "Actor"  
    parm x1        text  "Amount, $/week"
    parm priority  enum  "Priority"          -enumtype ePrioSched  \
                                             -displaylong yes      \
                                             -defval bottom
    parm on_lock   enum  "Exec On Lock?"     -enumtype eyesno \
                                             -defval NO
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   actor
    prepare a        -toupper   -required -type   actor
    prepare x1                  -required -type   money
    prepare priority -tolower             -type   ePrioSched
    prepare on_lock             -required -type   boolean

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) FUND

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:FUND:UPDATE
#
# Updates existing FUND tactic.

order define TACTIC:FUND:UPDATE {
    title "Update Tactic: Fund ENI Services"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id key  "Tactic ID"       -context yes            \
                                          -table   tactics_FUND \
                                          -keys    tactic_id
    parm owner     disp  "Owner"
    parm a         actor "Actor"  
    parm x1        text  "Amount, $/week"
    parm on_lock   enum  "Exec On Lock?"  -enumtype eyesno 
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type   tactic
    prepare a          -toupper  -type   actor
    prepare x1                   -type   money
    prepare on_lock              -type   boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType FUND $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


