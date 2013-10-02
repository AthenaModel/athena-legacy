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

    # CapsOwnedBy a
    #
    # a     - An actor
    #
    # Returns a namedict of CAPs owned by a.
    
    typemethod CapsOwnedBy {a} {
        return [rdb eval {
            SELECT k,longname FROM caps
            WHERE owner=$a
            ORDER BY k
        }]
    }

    # ActorsOtherThan a
    #
    # a   - An actor
    #
    # Returns a namedict of actors other than a.

    typemethod ActorsOtherThan {a} {
        return [rdb eval {
            SELECT a,longname FROM actors
            WHERE a != $a
            ORDER BY a
        }]
    }
}


# TACTIC:GRANT:CREATE
#
# Creates a new GRANT tactic.

order define TACTIC:GRANT:CREATE {
    title "Create Tactic: Grant Access to CAP"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes
    
        rcc "CAP List:" -for klist
        enumlonglist klist \
            -dictcmd {tactic::GRANT CapsOwnedBy $owner} \
            -width   40 \
            -height  8

        rcc "Actor List:" -for alist
        enumlonglist alist \
            -dictcmd {tactic::GRANT ActorsOtherThan $owner} \
            -width   40 \
            -height  8

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock -defvalue 1

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   actor
    prepare klist    -toupper   -required -listof cap
    prepare alist    -toupper   -required -listof actor
    prepare on_lock             -required -type   boolean
    prepare priority -tolower             -type   ePrioSched

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
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_GRANT -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "CAP List:" -for klist
        enumlonglist klist \
            -dictcmd {tactic::GRANT CapsOwnedBy $owner} \
            -width   40 \
            -height  8

        rcc "Actor List:" -for alist
        enumlonglist alist \
            -dictcmd {tactic::GRANT ActorsOtherThan $owner} \
            -width   40 \
            -height  8

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
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


