#-----------------------------------------------------------------------
# TITLE:
#    tacticx_assign.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, ASSIGN
#
#    An ASSIGN tactic assigns deployed force or organization personnel
#    to perform particular activities in a neighborhood.
#
# TBD:
#    * We might want to use a gofer to choose the group to assign
#    * We might want to use a gofer to choose the nbhood to assign it in.
#    * We might want to use a gofer to choose the number of people to deploy.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
tacticx define ASSIGN "Assign Personnel" {actor} -onlock {
    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    variable g           ;# A FRC or ORG group
    variable n           ;# The neighborhood in which g is deployed.
    variable activity    ;# The activity to assign them to do.
    variable personnel   ;# Number of personnel.

    # Transient Arrays
    variable trans

    #-------------------------------------------------------------------
    # Constructor

    # constructor ?block_?
    #
    # block_  - The block that owns the tactic
    #
    # Creates a new tactic for the given block.

    constructor {{block_ ""}} {
        # Initialize as tactic bean.
        next $block_

        # Initialize state variables
        set g              ""
        set n              ""
        set activity       ""
        set personnel      0

        # Initial state is invalid (no g, n, activity)
        my set state invalid

        # Transient data
        set trans(cost) 0.0
    }

    #-------------------------------------------------------------------
    # Operations

    method SanityCheck {errdict} {
        # Check g
        if {$g eq ""} {
            dict set errdict g "No group selected."
        } elseif {$g ni [group ownedby [my agent]]} {
            dict set errdict g \
                "Force/organization group \"$g\" is not owned by [my agent]."
        }

        # Check n
        if {[llength $n] == 0} {
            dict set errdict n \
                "No neighborhood selected."
        } elseif {$n ni [nbhood names]} {
            dict set errdict n \
                "Non-existent neighborhood: $n"
        }

        # Check activity
        if {$activity eq ""} {
            dict set errdict activity "No activity selected."
        } elseif {[catch {activity check $g $activity}]} {
            dict set errdict activity \
                "Invalid activity for selected group: \"$activity\"" 
        }

        return [next $errdict]
    }

    method narrative {} {
        let s(g)        {$g        ne "" ? $g        : "???"}
        let s(n)        {$n        ne "" ? $n        : "???"}
        let s(activity) {$activity ne "" ? $activity : "???"}

        return "In $s(n), assign $personnel $s(g) personnel to do $s(activity)."
    }

    # obligate coffer
    #
    # coffer  - A coffer object with the owning agent's current
    #           resources
    #
    # Obligates the personnel and cash required for the assignment.

    method obligate {coffer} {
        # FIRST, compute the cost.
        set trans(cost) [my AssignmentCost]

        # NEXT, obligate the resources on tick
        if {[strategyx ontick]} {
            # FIRST, are there enough people available?
            if {$personnel > [$coffer troops $g $n]} {
                return 0
            }

            # NEXT, can we afford to assign them?
            if {$trans(cost) > [$coffer cash]} {
                return 0
            }
        }

        # NEXT, obligate the resources
        $coffer spend $trans(cost)
        $coffer assign $g $n $personnel

        return 1
    }

    # AssignmentCost
    #
    # Assuming that the state is normal, returns the cost of the assignment.

    method AssignmentCost {} {
        set gtype [group gtype $g]
        set costPerTroop [parm get activity.$gtype.$activity.cost]
        let cost {$costPerTroop * $personnel}

        return $cost
    }

    method execute {} {
        # FIRST, Pay the maintenance cost and assign the troops.
        cash spend [my agent] ASSIGN $trans(cost)
        personnel assign [my id] $g $n $activity $personnel

        sigevent log 2 tactic "
            ASSIGN: Actor {actor:[my agent]} assigns $personnel {group:$g} 
            personnel to $activity in {nbhood:$n}
        " [my agent] $n $g

    }

    #-------------------------------------------------------------------
    # Order Helpers
    
    # activitiesFor g
    #
    # g  - A force or organization group
    #
    # Returns a list of the valid activities for this group.

    typemethod activitiesFor {g} {
        if {$g ne ""} {
            set gtype [string tolower [group gtype $g]]
            if {$gtype ne ""} {
                return [::activity $gtype names]
            }
        }

        return ""
    }

}

#-----------------------------------------------------------------------
# TACTICX:* orders

# TACTICX:ASSIGN:UPDATE
#
# Updates existing ASSIGN tactic.

order define TACTICX:ASSIGN:UPDATE {
    title "Update Tactic: Assign Personnel"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Group:" -for g
        enum g -listcmd {tacticx groupsOwnedByAgent $tactic_id}

        rcc "Neighborhood:" -for n
        nbhood n

        rcc "Activity:" -for activity
        enum activity -listcmd {tacticx::ASSIGN activitiesFor $g}

        rcc "Personnel:" -for personnel
        text personnel
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -oneof [tacticx::ASSIGN ids]
    returnOnError

    # NEXT, get the tactic
    set tactic [tacticx get $parms(tactic_id)]

    prepare g                   -oneof [group ownedby [$tactic agent]]
    prepare n         -toupper  -type nbhood
    prepare activity  -toupper  -type {activity asched}
    prepare personnel -num      -type ipositive
 
    returnOnError

    # NEXT, do the cross checks
    fillparms parms [$tactic view]

    if {$parms(activity) ni [tacticx::ASSIGN activitiesFor $parms(g)]} {
        reject activity \
            "Invalid activity for group $parms(g): \"$parms(activity)\""
    }

    if {$parms(personnel) == 0} {
        reject personnel "Personnel must be positive"
    }

    returnOnError -final

    # NEXT, update the tactic, saving the undo script, and clearing
    # historical state data.
    set undo [$tactic update_ {g n activity personnel} [array get parms]]

    # NEXT, save the undo script
    setundo $undo
}


