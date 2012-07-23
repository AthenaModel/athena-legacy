#-----------------------------------------------------------------------
# TITLE:
#    tactic_assign.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): ASSIGN(g,n,activity,personnel) tactic
#
#    This module implements the ASSIGN tactic, which assigns 
#    deployed personnel to do an abstract activity in a neighborhood.
#    The troops remain as assigned until the next strategy tock.
#
# PARAMETER MAPPING:
#
#    g       <= g
#    n       <= n
#    text1   <= activity; list depends on whether g is FRC or ORG
#    int1    <= personnel
#    on_lock <= on_lock
#    once    <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: ASSIGN

tactic type define ASSIGN {g n text1 int1 once on_lock} actor {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            return "In $n, assign $int1 $g personnel to do $text1."
        }
    }

    typemethod dollars {tdict} {
        return [moneyfmt [$type ComputeCost $tdict]]
    }

    # ComputeCost tdict
    #
    # Computes the actual cost of this tactic: the number of personnel,
    # times the cost of having one person of this group doing this
    # activity for one strategy tock.

    typemethod ComputeCost {tdict} {
        dict with tdict {
            set gtype [group gtype $g]
            set costPerTroop [parm get activity.$gtype.$text1.cost]
            let cost {$costPerTroop * $int1}

            return $cost
        }
    }

    typemethod check {tdict} {
        set errors [list]

        dict with tdict {
            # n
            if {$n ni [nbhood names]} {
                lappend errors "Neighborhood $n no longer exists."
            }

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
        # FIRST, compute the cost of this tactic.
        set cost [$type ComputeCost $tdict]

        dict with tdict {
            # FIRST, retrieve relevant data.
            set unassigned [personnel unassigned $n $g]

            # NEXT, are there enough people available?
            if {$int1 > $unassigned} {
                return 0
            }

            # NEXT, can we afford it? We can always afford it on scenario
            # lock.
            if {![strategy locking] && ![cash spend $owner $cost]} {
                return 0
            }

            # NEXT, assign them.  All assignments are currently
            # into the neighborhood of origin.
            personnel assign $tactic_id $g $n $n $text1 $int1

            sigevent log 2 tactic "
                ASSIGN: Actor {actor:$owner} assigns
                $int1 {group:$g} personnel to $text1
                in {nbhood:$n} 
            " $owner $n $g
        }

        return 1
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # ActivitiesFor g
    #
    # g  - A force or organization group
    #
    # Returns a list of the valid activities for this group.

    typemethod ActivitiesFor {g} {
        if {$g ne ""} {
            set gtype [string tolower [group gtype $g]]
            return [::activity $gtype names]
        } else {
            return ""
        }
    }
}

# TACTIC:ASSIGN:CREATE
#
# Creates a new ASSIGN tactic.

order define TACTIC:ASSIGN:CREATE {
    title "Create Tactic: Assign Activity"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Group:" -for g
        enum g -listcmd {group ownedby $owner}

        rcc "Neighborhood:" -for n
        nbhood n

        rcc "Activity:" -for n
        enum text1 -listcmd {tactic::ASSIGN ActivitiesFor $g}

        rcc "Personnel:" -for int1
        text int1

        rcc "Once Only?" -for once
        yesno once -defvalue 0

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock -defvalue 1

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare g        -toupper   -required -type {ptype fog}
    prepare n        -toupper   -required -type nbhood
    prepare text1    -toupper   -required -type {activity asched}
    prepare int1                -required -type ingpopulation
    prepare once                -required -type boolean
    prepare on_lock             -required -type boolean
    prepare priority -tolower             -type ePrioSched

    returnOnError

    # NEXT, cross-checks

    # g vs owner
    set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$parms(g)}]

    if {$a ne $parms(owner)} {
        reject g "Group $parms(g) is not owned by actor $parms(owner)."
    }

    # g and text1 are consistent
    validate text1 {
        activity check $parms(g) $parms(text1)
    }
    
    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) ASSIGN

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:ASSIGN:UPDATE
#
# Updates existing ASSIGN tactic.

order define TACTIC:ASSIGN:UPDATE {
    title "Update Tactic: Assign Activity"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_ASSIGN -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Group:" -for g
        enum g -listcmd {group ownedby $owner}

        rcc "Neighborhood:" -for n
        nbhood n

        rcc "Activity:" -for n
        enum text1 -listcmd {tactic::ASSIGN ActivitiesFor $g}

        rcc "Personnel:" -for int1
        text int1

        rcc "Once Only?" -for once
        yesno once

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare g          -toupper  -type {ptype fog}
    prepare n          -toupper  -type nbhood
    prepare text1      -toupper  -type {activity asched}
    prepare int1                 -type ingpopulation
    prepare once                 -type boolean
    prepare on_lock              -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType ASSIGN $parms(tactic_id) }

    returnOnError

    # NEXT, cross-checks
    tactic delta parms
    
    validate g {
        set owner [rdb onecolumn {
            SELECT owner FROM tactics WHERE tactic_id = $parms(tactic_id)
        }]

        set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$parms(g)}]

        if {$a ne $owner} {
            reject g "Group $parms(g) is not owned by actor $owner."
        }
    }

    returnOnError

    # g and text1 are consistent
    validate text1 {
        activity check $parms(g) $parms(text1)
    }
    
    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


