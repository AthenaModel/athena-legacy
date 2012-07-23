#-----------------------------------------------------------------------
# TITLE:
#    tactic_support.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): SUPPORT(a,nlist) tactic
#
#    This module implements the SUPPORT tactic, which allows an
#    actor to give political support to another actor in one or more
#    neighborhoods.  The support continues until the next strategy tock, 
#    when it must be explicitly renewed.
#
# PARAMETER MAPPING:
#
#    a       <= a
#    nlist   <= nlist
#    on_lock <= on_lock
#    once    <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: SUPPORT

tactic type define SUPPORT {a nlist once on_lock} actor {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            if {[llength $nlist] == 1} {
                set ntext "neighborhood [lindex $nlist 0]"
            } else {
                set ntext "neighborhoods [join $nlist {, }]"
            }

            if {$a eq "SELF"} {
                return "Support self in $ntext"
            } elseif {$a eq "NONE"} {
                return "Support no one in $ntext"
            } else {
                return "Support actor $a in $ntext"
            }
        }
    }

    typemethod check {tdict} {
        set errors [list]

        dict with tdict {
            # nlist
            foreach n $nlist {
                if {$n ni [nbhood names]} {
                    lappend errors "Neighborhood $n no longer exists."
                }
            }

            # a
            if {$a ni [ptype a+self+none names]} {
                lappend errors "Actor $a no longer exists."
            }
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        dict with tdict {
            # FIRST, support a in the neighborhoods.
            control support $owner $a $nlist

            # NEXT, log what happened.
            set logIds $nlist

            if {$a eq "SELF"} {
                set supports "{actor:$owner}"
            } elseif {$a eq "NONE"} {
                set supports "no actor"
            } else {
                set supports "{actor:$a}"
                set logIds [linsert $logIds 0 $a]
            }

            set ntext [list]

            foreach n $nlist {
                lappend ntext "{nbhood:$n}"
            }

            sigevent log 2 tactic "
                SUPPORT: Actor {actor:$owner} supports $supports 
                in [join $ntext {, }]
            " $owner {*}$logIds
        }

        return 1
    }
}

# TACTIC:SUPPORT:CREATE
#
# Creates a new SUPPORT tactic.

order define TACTIC:SUPPORT:CREATE {
    title "Create Tactic: Support Actor"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Supported Actor:" -for a
        enum a -listcmd {ptype a+self+none names} -defvalue SELF

        rcc "In Neighborhoods:" -for nlist
        nlist nlist

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
    prepare a        -toupper   -required -type   {ptype a+self+none}
    prepare nlist    -toupper   -required -listof nbhood
    prepare once                          -type   boolean
    prepare on_lock                       -type   boolean
    prepare priority -tolower             -type   ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) SUPPORT

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:SUPPORT:UPDATE
#
# Updates existing SUPPORT tactic.

order define TACTIC:SUPPORT:UPDATE {
    title "Update Tactic: Support Actor"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_SUPPORT -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Supported Actor:" -for a
        enum a -listcmd {ptype a+self+none names}

        rcc "In Neighborhoods:" -for nlist
        nlist nlist

        rcc "Once Only?" -for once
        yesno once

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type   tactic
    prepare a          -toupper  -type   {ptype a+self+none}
    prepare nlist      -toupper  -listof nbhood
    prepare once                 -type   boolean
    prepare on_lock              -type   boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType SUPPORT $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}



