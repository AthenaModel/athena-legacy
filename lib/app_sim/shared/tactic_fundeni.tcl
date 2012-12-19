#-----------------------------------------------------------------------
# TITLE:
#    tactic_fundeni.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): FUNDENI(amount, glist)
#
#    This module implements the FUNDENI tactic, which funds 
#    Essential Non-Infrastructure services aimed at particular
#    groups.  The services are funded for the following week.
#
# PARAMETER MAPPING:
#
#    x1      <= amount
#    glist   <= glist
#    on_lock <= on_lock
#    once    <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: FUNDENI

tactic type define FUNDENI {x1 glist once on_lock} actor {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            if {[llength $glist] == 1} {
                set gtext "civilian group [lindex $glist 0]"
            } else {
                set gtext "civilian groups [join $glist {, }]"
            }

            return "Fund \$[moneyfmt $x1] worth of Essential Non-Infrastructure services for $gtext."
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
            # glist
            foreach g $glist {
                if {$g ni [civgroup names]} {
                    lappend errors "Civilian Group $g no longer exists."
                }
            }
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        dict with tdict {
            # FIRST, retrieve relevant data.
            set cash_on_hand [cash get $owner cash_on_hand]

            # NEXT, Ensure that the group has influence in the
            # relevant neighborhood, neighborhoods.  If insufficient
            # influence, don't execute.
            set glist [FilterForSupport $owner $glist]

            if {[llength $glist] == 0} {
                return 0
            }

            # NEXT, can we afford it?
            if {![cash spend $owner FUNDENI $x1]} {
                return 0
            }

            # NEXT, Compute strings needed for logging.
            if {[llength $glist] == 1} {
                set gtext "{group:[lindex $glist 0]}"
            } else {
                set grps [list]
     
                foreach g $glist {
                    lappend grps "{group:$g}"
                }

                set gtext [join $grps ", "]
            }

            
            # NEXT, try to fund the service.  This will fail if
            # all of the groups are empty.
            if {![service fundeni $owner $x1 $glist]} {
                cash refund $x1
                sigevent log 2 tactic "
                    FUNDENI: Actor {actor:$owner} could not fund
                    \$[moneyfmt $x1] worth of Essential Non-Infrastructure 
                    services to $gtext, because all of those groups 
                    are empty.
                " $owner {*}$glist {*}$nbhoods
                return 0
            }

            # NEXT, get the related neighborhoods.
            set nbhoods [rdb eval "
                SELECT DISTINCT n 
                FROM civgroups
                WHERE g IN ('[join $glist ',']')
            "]


            # TBD: Do I need to include neighborhoods in here?
            sigevent log 2 tactic "
                FUNDENI: Actor {actor:$owner} funds \$[moneyfmt $x1]
                worth of Essential Non-Infrastructure services to
                $gtext.
            " $owner {*}$glist {*}$nbhoods
        }

        return 1
    }

    #-------------------------------------------------------------------
    # Tactic Helpers

    # FilterForSupport owner glist
    #
    # owner   - An actor
    # glist   - A list of groups
    #
    # Returns a list of the groups in glist that reside in neighborhoods
    # in which the actor has positive direct support.

    proc FilterForSupport {owner glist} {
        # FIRST, make an "IN" clause
        set inClause "IN ('[join $glist ',']')"

        # NEXT, get the list of groups that reside in neighborhoods in
        # which the owner has positive direct support

        set minSupport [parm get service.ENI.minSupport]

        rdb eval "
            SELECT g 
            FROM civgroups
            JOIN influence_na USING (n)
            WHERE a=\$owner
            AND   direct_support >= $minSupport
            AND   g $inClause 
        "
    }
}

# TACTIC:FUNDENI:CREATE
#
# Creates a new FUNDENI tactic.

order define TACTIC:FUNDENI:CREATE {
    title "Create Tactic: Fund ENI Services"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Groups:" -for glist
        civlist glist

        rcc "Amount:" -for x1
        text x1
        label "$/week"

        rcc "Once Only?" -for once
        yesno once -defvalue 0

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock -defvalue 1

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   actor
    prepare glist    -toupper   -required -listof civgroup
    prepare x1                  -required -type   money
    prepare once                          -type   boolean
    prepare on_lock                       -type   boolean
    prepare priority -tolower             -type   ePrioSched
 
    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) FUNDENI

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:FUNDENI:UPDATE
#
# Updates existing FUNDENI tactic.

order define TACTIC:FUNDENI:UPDATE {
    title "Update Tactic: Fund ENI Services"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_FUNDENI -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Groups:" -for glist
        civlist glist

        rcc "Amount:" -for x1
        text x1
        label "$/week"

        rcc "Once Only?" -for once
        yesno once

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type   tactic
    prepare glist      -toupper  -listof civgroup
    prepare x1                   -type   money
    prepare once                 -type   boolean
    prepare on_lock              -type   boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType FUNDENI $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}



