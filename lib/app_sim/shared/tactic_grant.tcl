#-----------------------------------------------------------------------
# TITLE:
#    tactic_grant.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): GRANT(klist,alist,on_lock) tactic
#
#    This module implements the GRANT tactic, which grants 
#    actors access to CAPs.  By default, only a CAP's owner has
#    access; however, the actor can grant access to anyone.
#
#    The bookkeeping is handled by the cap(sim) module.
#
# PARAMETER MAPPING:
#
#    klist   <= klist
#    alist   <= alist
#    on_lock <= on_lock
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: GRANT

tactic type define GRANT {klist alist on_lock} actor {
    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            set atext [AndList actor $alist]
            set ktext [AndList CAP $klist]

            return "Grant $atext access to $ktext."
        }
    }

    typemethod check {tdict} {
        set errors [list]

        dict with tdict {
            # klist
            foreach cap $klist {
                if {$cap ni [cap names]} {
                    lappend errors "CAP $cap no longer exists."
                }
            }

            # alist
            foreach a $alist {
                if {$a ni [actor names]} {
                    lappend errors "Actor $a no longer exists."
                }
            }
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        dict with tdict {
            # FIRST, grant the access
            cap access grant $klist $alist

            # NEXT, log it.
            sigevent log 2 tactic "
                GRANT: Actor {actor:$owner} grants access to 
                [AndList CAP $klist] to [AndList actor $alist]
            " $owner {*}$klist {*}$alist 
        }

        return 1
    }

    #-------------------------------------------------------------------
    # Tactic Helpers

    # AndList noun list
    #
    # noun   - The noun for the list
    # list   - A list of things
    #
    # Formats the list nicely, whether it contains one, two, or more
    # elements.

    proc AndList {noun list} {
        if {[llength $list] == 0} {
            error "No entries in list"
        } elseif {[llength $list] == 1} {
            return "$noun [lindex $list 0]"
        } elseif {[llength $list] == 2} {
            return "${noun}s [lindex $list 0] and [lindex $list 1]"
        } else {
            set last [lindex $list end]
            set list [lrange $list 0 end-1]

            set text "${noun}s "
            append text [join $list ", "]
            append text " and $last"

            return $text
        }
    }
    
    #-------------------------------------------------------------------
    # Order Helpers


    # RefreshCREATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the lists of CAPs and actors when the owner field changes. 

    typemethod RefreshCREATE {dlg fields fdict} {
        dict with fdict {
            if {"owner" in $fields} {
                set kdict [rdb eval {
                    SELECT k,longname FROM caps
                    WHERE owner=$owner
                    ORDER BY k
                }]
                
                $dlg field configure klist -itemdict $kdict

                set adict [rdb eval {
                    SELECT a,longname FROM actors
                    WHERE a != $owner
                    ORDER BY a
                }]
                
                $dlg field configure alist -itemdict $adict
            }

        }
    }

    # RefreshUPDATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the lists of CAPs and actors when the tactic_id changes.

    typemethod RefreshUPDATE {dlg fields fdict} {
        if {"tactic_id" in $fields} {
            $dlg loadForKey tactic_id *
            set fdict [$dlg get]

            dict with fdict {
                set kdict [rdb eval {
                    SELECT k,longname FROM caps
                    WHERE owner=$owner
                    ORDER BY k
                }]
                
                $dlg field configure klist -itemdict $kdict

                set adict [rdb eval {
                    SELECT a,longname FROM actors
                    WHERE a != $owner
                    ORDER BY a
                }]
                
                $dlg field configure alist -itemdict $adict
            }

            $dlg loadForKey tactic_id *
        }
    }
}


# TACTIC:GRANT:CREATE
#
# Creates a new GRANT tactic.

order define TACTIC:GRANT:CREATE {
    title "Create Tactic: Grant Access to CAP"

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {tactic::GRANT RefreshCREATE}

    parm owner     actor "Owner"           -context yes
    parm klist     klist "CAP List" 
    parm alist     alist "Actor List"
    parm priority  enum  "Priority"        -enumtype ePrioSched  \
                                           -displaylong yes      \
                                           -defval bottom
    parm on_lock   enum  "Exec On Lock?"   -enumtype eyesno      \
                                           -defval YES
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   actor
    prepare klist    -toupper   -required -listof cap
    prepare alist    -toupper   -required -listof actor
    prepare priority -tolower             -type   ePrioSched
    prepare on_lock             -required -type   boolean

    returnOnError

    # NEXT, does the owner own all of the CAPs?
    set capsOwned [rdb eval {SELECT k FROM caps WHERE owner=$parms(owner)}]

    foreach k $parms(klist) {
        if {$k ni $capsOwned} {
            reject klist "CAP $k is not owned by actor $parms(owner)."
        }
    }

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) GRANT

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:GRANT:UPDATE
#
# Updates existing GRANT tactic.

order define TACTIC:GRANT:UPDATE {
    title "Update Tactic: Grant Access to CAP"
    options \
        -sendstates {PREP PAUSED}                  \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id key  "Tactic ID"       -context yes                \
                                          -table   gui_tactics_GRANT \
                                          -keys    tactic_id
    parm owner     disp  "Owner"
    parm klist     klist "CAP List"
    parm alist     alist "Actor List"
    parm on_lock   enum  "Exec On Lock?"  -enumtype eyesno 
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare klist      -toupper  -listof cap
    prepare alist      -toupper  -listof actor
    prepare on_lock              -type boolean

    returnOnError

    # NEXT, does the owner own all of the CAPs?
    set owner [rdb onecolumn {
        SELECT owner FROM tactics WHERE tactic_id = $parms(tactic_id)
    }]
    
    set capsOwned [rdb eval {SELECT k FROM caps WHERE owner=$owner}]

    foreach k $parms(klist) {
        if {$k ni $capsOwned} {
            reject klist "CAP $k is not owned by actor $owner."
        }
    }
    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType GRANT $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


