#-----------------------------------------------------------------------
# TITLE:
#    tactic_broadcast.tcl
#
# AUTHOR:
#    Will Duquette
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, BROADCAST tactic
#
#    This module implements the BROADCAST tactic, which broadcasts 
#    an Info Ops Message (IOM) via a particular Communications Asset
#    Package (CAP).  The message is attributed to actor a, which
#    might be the true source, some other actor, or null.  Preparing
#    the message will have the stated cost, which is separate from
#    the CAP's transmission cost.  The broadcast will have its effect
#    during the subsequent week.
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: BROADCAST

tactic define BROADCAST "Broadcast an Info Ops Message" {actor} -onlock {
    #-------------------------------------------------------------------
    # Typemethods
    # 
    # These typemethods are used to accumulate the broadcast of IOMs by
    # actors; the effects of the broadcasts are all applied at once.

    # reset
    # 
    # Clears any pending broadcasts.  This command is for use at the
    # beginning of strategy execution, to make sure that there are no
    # pending broadcasts hanging around to cause trouble.
    #
    # Note that the [assess] typemethod should always leave the list
    # empty; nevertheless, it is better to be sure.

    typemethod reset {} {
        my variable pending
        set pending [list]
    }

    # broadcast cap owner a iom cost
    #
    # cap   - CAP from which the broadcast is made
    # owner - The actor sending the broadcast
    # a     - The actor attributed to the broadcast
    # iom   - The message being broadcast
    # cost  - The cost of the broadcast, this may get refunded if for some
    #         reason the owning actor no longer has access to the CAP
    #
    # Saves the pending broadcast until later

    typemethod broadcast {cap owner a iom cost} {
        my variable pending
        lappend pending $cap $owner $a $iom $cost
    }

    # assess
    #
    # Assesses the attitude effects of all pending broadcasts by
    # calling the IOM rule set for each pending broadcast.
    #
    # This command is called at the end of strategy execution, once
    # all actors have made their decisions and CAP access is clear.

    typemethod assess {} {
        my variable pending

        # FIRST, assess each of the pending broadcasts
        foreach {cap owner a iom fullcost} $pending {
            # FIRST, does the owner have access to the CAP?
            # If not, refund his money; we're through here.
            if {![cap hasaccess $cap $owner]} {
                cash refund $owner BROADCAST $fullcost 

                # NEXT, log the event
                sigevent log 2 tactic "
                    BROADCAST: Actor {actor:$owner} failed to broadcast
                    IOM {iom:$iom} via CAP {cap:$cap}: access denied. 
                " $owner $iom $cap

                continue
            }
            
            # NEXT, Get the entity tags, for when we log the sigevent.
            set tags [list $owner $iom $cap]

            if {$a eq "SELF"} {
                set attribution ", attributing it to self"
                set asource $owner
            } elseif {$a eq "NONE"} {
                set attribution " without attribution"
                set asource ""
            } else {
                set attribution ", attributing it to $a"
                set asource $a
                lappend tags $a
            }

            lappend tags \
                [rdb eval {SELECT hook_id FROM ioms WHERE iom_id=$iom}]
            lappend tags {*}[rdb eval {
                SELECT g,n FROM capcov 
                WHERE k=$cap AND capcov > 0.0
            }]

            # NEXT, set up the dict needed by the IOM rule set.
            set rdict [dict create]
            dict set rdict tsource $owner
            dict set rdict cap     $cap
            dict set rdict iom     $iom
            dict set rdict asource $asource

            # NEXT, log the event
            sigevent log 2 tactic "
                BROADCAST: Actor {actor:$owner} broadcast
                IOM {iom:$iom} via CAP {cap:$cap}$attribution. 
            " {*}$tags

            # NEXT, assess the broadcast.
            driver::IOM assess $rdict
        }

        # NEXT, clear the list.
        my reset
    }

    #-------------------------------------------------------------------
    # Instance Variables

    variable cap    ;# A Communication Asset Package
    variable a      ;# An actor
    variable iom    ;# An Information Operations Message
    variable cost   ;# The cost of the broadcast

    variable trans  ;# Transient variables
    
    #------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Initialize as a tactic bean.
        next

        # Initialize state variables
        set cap ""
        set a   ""
        set iom ""
        set cost 0.0

        set trans(cost) 0.0

        my set state invalid

        my configure {*}$args
    }

    #----------------------------------------------------------------
    # Operations

    method SanityCheck {errdict} {
        # cap
        if {$cap eq ""} {
            dict set errdict cap "No CAP selected."
        } elseif {$cap ni [cap names]} {
            dict set errdict cap "No such CAP: \"$cap\"."
        }

        # a
        if {$a eq ""} {
            dict set errdict a "No actor selected."
        } elseif {$a ni [ptype a+self+none names]} {
            dict set errdict a "No such actor: \"$a\"."
        }

        # iom
        set gotIOM [expr {$iom in [iom names]}]

        if {$iom eq ""} {
            dict set errdict iom "No IOM selected."            
        } elseif {!$gotIOM} {
            dict set errdict iom "No such IOM: \"$iom\"."
        } elseif {[iom get $iom state] eq "disabled"} {
            dict set errdict iom "IOM is disabled: \"$iom\"."
        } elseif {[iom get $iom state] eq "invalid"} {
            dict set errdict iom "IOM is invalid: \"$iom\"."
        }

        # NEXT, does the IOM have any valid payloads?
        if {$gotIOM && ![rdb onecolumn { 
            SELECT count(payload_num) FROM payloads
            WHERE iom_id=$iom AND state='normal'
        }]} {
            dict set errdict iom "IOM has no valid payloads: \"$iom\"."     
        }

        # NEXT, does the IOM's hook have any valid topics?
        if {$gotIOM && ![rdb onecolumn { 
            SELECT count(HT.topic_id) 
            FROM hook_topics AS HT
            JOIN ioms AS I USING (hook_id)
            WHERE I.iom_id=$iom AND HT.state='normal'
        }]} {
            dict set errdict iom "IOM's hook has no valid topics: \"$iom\"."
        }

        return [next $errdict]
    }

    method narrative {} {
        set s(cap) [link make cap $cap]
        set s(a)   [link make actor $a]
        set s(iom) [link make iom $iom]
        set s(cost) "\$[commafmt $cost]"

        set text "Broadcast $s(iom) via $s(cap) with prep cost of $s(cost)"

        if {$a eq "SELF"} {
            append text " and attribute it to self."
        } elseif {$a eq "NONE"} {
            append text " and no attribution."
        } else {
            append text " and attribute it to $s(a)."
        }

        return $text
    }

    method ObligateResources {coffer} {
        # has access to cap?
        if {![cap hasaccess $cap [my agent]]} {
            my Fail CAP "[my agent] has no access to CAP $cap."
            return
        }

        set cash [$coffer cash]
        
        # Total cost is prep cost plus cost to use CAP
        set trans(cost) [expr {$cost + [cap get $cap cost]}]

        if {[my InsufficientCash $cash $trans(cost)]} {
            return
        }

        $coffer spend $trans(cost)
    }

    method execute {} {
        # FIRST, spend the cash
        cash spend [my agent] BROADCAST $trans(cost)

        # NEXT, Save the broadcast.  It can't take effect yet,
        # as CAP access might be changed by other tactics.
        tactic::BROADCAST broadcast $cap [my agent] $a $iom $trans(cost)
    }
}

# TACTIC:BROADCAST
#
# Updates a BROADCAST tactic.

order define TACTIC:BROADCAST {
    title "Tactic: Broadcast IOM"

    options \
        -sendstates PREP

    form {
        rcc "Tactic ID:" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "CAP:" -for cap
        cap cap
        
        rcc "Attr. Source:" -for a
        enum a -listcmd {ptype a+self+none names} -defvalue SELF

        rcc "Message ID:" -for iom
        enumlong iom -showkeys yes -dictcmd {iom normal namedict}

        rcc "Prep. Cost:"
        text cost
        label "$/week"
    }
} {
    # FIRST, there must be a tactic ID
    prepare tactic_id  -required -type tactic::BROADCAST
    returnOnError

    # NEXT, get the tactic
    set tactic [tactic get $parms(tactic_id)]

    # NEXT, the parameters
    prepare cap      -toupper   
    prepare a        -toupper  
    prepare iom      -toupper   
    prepare cost     -toupper -type money

    returnOnError -final

    fillparms parms [$tactic view]

    # NEXT, create the tactic
    setundo [$tactic update_ {cap a iom cost} [array get parms]]
}




