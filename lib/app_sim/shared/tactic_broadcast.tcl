#-----------------------------------------------------------------------
# TITLE:
#    tactic_broadcast.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): BROADCAST(cap,a,iom,cost) tactic
#
#    This module implements the BROADCAST tactic, which broadcasts 
#    an Info Ops Message (IOM) via a particular Communications Asset
#    Package (CAP).  The message is attributed to actor a, which
#    might be the true source, some other actor, or null.  Preparing
#    the message will have the stated cost, which is separate from
#    the CAP's transmission cost.  The broadcast will have its effect
#    during the subsequent week.
#
# PARAMETER MAPPING:
#
#    cap     <= cap
#    a       <= a
#    iom     <= iom
#    x1      <= cost
#    on_lock <= on_lock
#    once    <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: BROADCAST

tactic type define BROADCAST {cap a iom x1 on_lock once} {system actor} {
    #-------------------------------------------------------------------
    # Type Variables

    # Pending broadcasts
    typevariable pending ""

    #-------------------------------------------------------------------
    # Public Methods

    # clear
    # 
    # Clears any pending broadcasts.  This command is for use at the
    # beginning of strategy execution, to make sure that there are no
    # pending broadcasts hanging around to cause trouble.
    #
    # Note that the [assess] typemethod should always leave the list
    # empty; nevertheless, it is better to be sure.

    typemethod clear {} {
        set pending [list]
    }

    # assess
    #
    # Assesses the attitude effects of all pending broadcasts by
    # calling the IOM rule set for each pending broadcast.
    #
    # This command is called at the end of strategy execution, once
    # all actors have made their decisions and CAP access is clear.

    typemethod assess {} {
        # TBD
    }

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            set text "Broadcast $iom via $cap with prep cost of \$$x1"
            if {$a eq "SELF"} {
                append text " and attribute it to self."
            } elseif {$a eq "NONE"} {
                append text " and no attribution."
            } else {
                append text " and attribute it to $a."
            }

            return $text
        }
    }

    typemethod dollars {tdict} {
        set est [$type ComputeCost $tdict]
        
        if {$est ne ""} {
            return [moneyfmt [$type ComputeCost $tdict]]
        } else {
            return "???"
        }
    }

    # ComputeCost tdict
    #
    # Computes the actual cost of this tactic: the preparation cost,
    # plus the CAP cost.

    typemethod ComputeCost {tdict} {
        dict with tdict {
            set capCost [cap get $cap cost]
            if {$x1 ne "" && $capCost ne ""} {
                return [expr {$x1 + $capCost}]
            } else {
                return ""
            }
        }
    }

    typemethod check {tdict} {
        set errors [list]

        dict with tdict {
            # cap
            if {$cap ni [cap names]} {
                lappend errors "CAP $cap no longer exists."
            }

            # a
            if {$a ni [ptype a+self+none names]} {
                lappend errors "Actor $a no longer exists."
            }

            # iom
            if {$iom ni [iom names]} {
                lappend errors "IOM $iom no longer exists."
            }

            # TBD: Should do more checking on IOM.  If it is invalid
            # or disabled, the tactic is invalid or disabled.  Also,
            # need to check for non-zero hook topics and IOM
            # payloads.
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        # FIRST, compute the cost of this tactic.  Add a "fullcost"
        # item to the tactic dictionary, so that we can more easily
        # return the money to the owner if the message cannot be
        # broadcast (e.g., because the actor has no access to the
        # CAP).
        dict set tdict fullcost [$type ComputeCost $tdict]

        dict with tdict {
            # FIRST, If the tactic is valid the cost should never be "".
            assert {$fullcost ne ""}

            # NEXT, can we afford it?  We can always afford it on 
            # scenario lock.

            if {![strategy locking] && ![cash spend $owner $fullcost]} {
                return 0
            }

            # NEXT, log it.

            # Get the entity tags
            set tags [list $owner $iom $cap]

            if {$a eq "SELF"} {
                set attribution ", attributing it to self"
            } elseif {$a eq "NONE"} {
                set attribution " without attribution"
            } else {
                lappend tags $a
                set attribution ", attributing it to $a"
            }

            set groups [rdb eval {SELECT g FROM capcov WHERE capcov > 0.0}]
            set nbhoods [rdb eval {SELECT n FROM capcov WHERE capcov > 0.0}]

            sigevent log 2 tactic "
                BROADCAST: Actor {actor:$owner} attempts to broadcast
                IOM {iom:$iom} via CAP {cap:$cap}$attribution. 
            " {*}$tags {*}$groups {*}$nbhoods
        }

        # NEXT, Save the broadcast.  It can't take effect yet,
        # as CAP access might be changed by other tactics.
        lappend pending $tdict

        return 1
    }
}

# TACTIC:BROADCAST:CREATE
#
# Creates a new BROADCAST tactic.

order define TACTIC:BROADCAST:CREATE {
    title "Create Tactic: Broadcast IOM"

    options \
        -sendstates {PREP PAUSED}

    parm owner     actor "Owner"           -context yes
    parm cap       enum  "CAP"             -enumtype cap \
                                           -displaylong yes \
                                           -width 40
    parm a         enum  "Attr. Source"    -enumtype {ptype a+self+none} \
                                           -defval SELF
    parm iom       enum  "Message ID"      -enumtype iom \
                                           -displaylong yes \
                                           -width 40
    parm x1        text  "Prep. Cost"    
    parm priority  enum  "Priority"        -enumtype ePrioSched  \
                                           -displaylong yes      \
                                           -defval bottom
    parm on_lock   enum  "Exec On Lock?"   -enumtype eyesno      \
                                           -defval YES
    parm once      enum  "Once Only?"      -enumtype eyesno      \
                                           -defval NO
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare cap      -toupper   -required -type cap
    prepare a        -toupper   -required -type {ptype a+self+none}
    prepare iom      -toupper   -required -type iom
    prepare x1       -toupper   -required -type money
    prepare priority -tolower             -type ePrioSched
    prepare on_lock             -required -type boolean
    prepare once                -required -type boolean

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) BROADCAST

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:BROADCAST:UPDATE
#
# Updates existing BROADCAST tactic.

order define TACTIC:BROADCAST:UPDATE {
    title "Update Tactic: Broadcast IOM"
    options \
        -sendstates {PREP PAUSED}                  \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id key  "Tactic ID"       -context yes                \
                                          -table   gui_tactics_BROADCAST \
                                          -keys    tactic_id
    parm owner     disp  "Owner"
    parm cap       enum  "CAP"            -enumtype cap \
                                          -displaylong yes
    parm a         enum  "Attr. Source"   -enumtype {ptype a+self+none} \
                                          -defval SELF
    parm iom       enum  "Message ID"     -enumtype iom \
                                          -displaylong yes
    parm x1        text  "Prep. Cost"    
    parm on_lock   enum  "Exec On Lock?"  -enumtype eyesno 
    parm once      enum  "Once Only?"     -enumtype eyesno 
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare cap        -toupper  -type cap
    prepare a          -toupper  -type {ptype a+self+none}
    prepare iom        -toupper  -type iom
    prepare x1         -toupper  -type money
    prepare on_lock              -type boolean
    prepare once                 -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType BROADCAST $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


