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
#    x1    <= amount
#    glist <= glist
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: FUNDENI

tactic type define FUNDENI {x1 glist} actor {
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

            set glist [FilterForInfluence $owner $glist]

            if {[llength $glist] == 0} {
                return 0
            }

            # NEXT, Consume the money, if we can.
            if {![cash spend $owner $x1]} {
                return 0
            }

            # NEXT, fund the service
            service fundeni $owner $x1 $glist

            # NEXT, get the related neighborhoods.
            set nbhoods [rdb eval "
                SELECT DISTINCT n 
                FROM civgroups
                WHERE g IN ('[join $glist ',']')
            "]

            # NEXT, Log it.
            if {[llength $glist] == 1} {
                set gtext "{group:[lindex $glist 0]}"
            } else {
                set grps [list]
     
                foreach g $glist {
                    lappend grps "{group:$g}"
                }

                set gtext [join $grps ", "]
            }

            

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

    # FilterForInfluence owner glist
    #
    # owner   - An actor
    # glist   - A list of groups
    #
    # Returns a list of the groups in glist that reside in neighborhoods
    # in which the actor has positive influence.

    proc FilterForInfluence {owner glist} {
        # FIRST, make an "IN" clause
        set inClause "IN ('[join $glist ',']')"

        # NEXT, get the list groups that reside in neighborhoods in
        # which the owner has positive influence

        rdb eval "
            SELECT g 
            FROM civgroups
            JOIN influence_na USING (n)
            WHERE a=\$owner
            AND   influence > 0
            AND   g $inClause 
        "
    }


    #-------------------------------------------------------------------
    # Order Helpers


    # RefreshCREATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the TACTIC:FUNDENI:CREATE dialog fields when field values
    # change.

    typemethod RefreshCREATE {dlg fields fdict} {
        dict with fdict {
            if {"owner" in $fields} {
                set gdict [rdb eval {
                    SELECT g,longname FROM civgroups_view
                    ORDER BY g
                }]
                
                $dlg field configure glist -itemdict $gdict
            }
        }
    }

    # RefreshUPDATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the TACTIC:FUNDENI:UPDATE dialog fields when field values
    # change.

    typemethod RefreshUPDATE {dlg fields fdict} {
        if {"tactic_id" in $fields} {
            $dlg loadForKey tactic_id *
            set fdict [$dlg get]

            dict with fdict {
                set gdict [rdb eval {
                    SELECT g,longname FROM civgroups_view
                    ORDER BY g
                }]
                
                $dlg field configure glist -itemdict $gdict
            }

            $dlg loadForKey tactic_id *
        }
    }
}

# TACTIC:FUNDENI:CREATE
#
# Creates a new FUNDENI tactic.

order define TACTIC:FUNDENI:CREATE {
    title "Create Tactic: Fund ENI Services"

    options \
        -sendstates {PREP PAUSED}       \
        -refreshcmd {tactic::FUNDENI RefreshCREATE}

    parm owner     actor "Owner"             -context yes
    parm glist     glist "Groups"  
    parm x1        text  "Amount, $/week"
    parm priority  enum  "Priority"          -enumtype ePrioSched  \
                                             -displaylong yes      \
                                             -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   actor
    prepare glist    -toupper   -required -listof civgroup
    prepare x1                  -required -type   money
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
    options \
        -sendstates {PREP PAUSED}                  \
        -refreshcmd {tactic::FUNDENI RefreshUPDATE}

    parm tactic_id key  "Tactic ID"       -context yes            \
                                          -table   tactics_FUNDENI \
                                          -keys    tactic_id
    parm owner     disp  "Owner"
    parm glist     glist "Groups"  
    parm x1        text  "Amount, $/week"
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type   tactic
    prepare glist      -toupper  -listof civgroup
    prepare x1                   -type   money

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType FUNDENI $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}

