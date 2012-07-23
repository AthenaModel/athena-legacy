#-----------------------------------------------------------------------
# TITLE:
#    tactic_mobilize.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): MOBILIZE(g,personnel,once) tactic
#
#    This module implements the MOBILIZE tactic, which mobilizes
#    force or ORG group personnel, i.e., moves them into of the playbox.
#
# PARAMETER MAPPING:
#
#    g     <= g
#    int1  <= personnel
#    once  <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: MOBILIZE

tactic type define MOBILIZE {g int1 once} actor {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            return "Mobilize $int1 new $g personnel."
        }
    }

    typemethod dollars {tdict} {
        return [moneyfmt 0.0]
    }

    typemethod check {tdict} {
        set errors [list]

        dict with tdict {
            # g
            if {$g ni [ptype fog names]} {
                lappend errors "Force/organization group $g no longer exists."
            } else {
                rdb eval {SELECT a FROM agroups WHERE g=$g} {}

                if {$a ne $owner} {
                    lappend errors \
                        "Force/organization group $g is no longer owned by actor $owner."
                }
            }
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        dict with tdict {
            personnel mobilize $g $int1
                
            sigevent log 1 tactic "
                MOBILIZE: Actor {actor:$owner} mobilizes $int1 new {group:$g} 
                personnel.
            " $owner $g
        }

        return 1
    }
}

# TACTIC:MOBILIZE:CREATE
#
# Creates a new MOBILIZE tactic.

order define TACTIC:MOBILIZE:CREATE {
    title "Create Tactic: Mobilize Forces"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Group:" -for g
        enum g -listcmd {group ownedby $owner}

        rcc "Personnel:" -for int1
        text int1

        rcc "Once Only?" -for once
        yesno once -defvalue 1

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   actor
    prepare g        -toupper   -required -type   {ptype fog}
    prepare int1                          -type   ingpopulation
    prepare once     -toupper   -required -type   boolean
    prepare priority -tolower             -type   ePrioSched

    returnOnError

    # NEXT, cross-checks

    # g vs owner
    set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$parms(g)}]

    if {$a ne $parms(owner)} {
        reject g "Group $parms(g) is not owned by actor $parms(owner)."
    }

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) MOBILIZE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:MOBILIZE:UPDATE
#
# Updates existing MOBILIZE tactic.

order define TACTIC:MOBILIZE:UPDATE {
    title "Update Tactic: Mobilize Forces"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_MOBILIZE -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Group:" -for g
        enum g -listcmd {group ownedby $owner}

        rcc "Personnel:" -for int1
        text int1

        rcc "Once Only?" -for once
        yesno once
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare g          -toupper  -type {ptype fog}
    prepare int1                 -type ingpopulation
    prepare once       -toupper  -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType MOBILIZE $parms(tactic_id) }

    returnOnError

    # NEXT, cross-checks
    validate g {
        set owner [rdb onecolumn {
            SELECT owner FROM tactics WHERE tactic_id = $parms(tactic_id)
        }]

        set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$parms(g)}]

        if {$a ne $owner} {
            reject g "Group $parms(g) is not owned by actor $owner."
        }
    }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


