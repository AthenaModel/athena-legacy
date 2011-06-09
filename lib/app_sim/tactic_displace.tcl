#-----------------------------------------------------------------------
# TITLE:
#    tactic_displace.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): DISPLACE(g,n,activity,personnel) tactic
#
#    This module implements the DISPLACE tactic, which displaces 
#    civilian personnel from their home neighborhoods.  The activity
#    may be DISPLACED or IN_CAMPS.  The troops remain displaced until the 
#    next strategy tock.
#
#    This tactic can be used only by the SYSTEM agent.
#
# PARAMETER MAPPING:
#
#    g     <= g
#    n     <= n
#    text1 <= activity; DISPLACED or IN_CAMP
#    int1  <= personnel
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: DISPLACE

tactic type define DISPLACE {g n text1 int1} system {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            return "Displace $int1 $g personnel to $n with activity $text1."
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
            if {$g ni [civgroup names]} {
                lappend errors "Civilian group $g no longer exists."
            }
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        dict with tdict {
            # FIRST, retrieve relevant data.
            set origin [civgroup getg $g n]
            set unassigned [personnel unassigned $origin $g]

            # NEXT, are there enough people available?
            if {$int1 > $unassigned} {
                return 0
            }

            # NEXT, displace them.
            personnel assign $tactic_id $g $origin $n $text1 $int1

            sigevent log 2 tactic "
                DISPLACE: The $owner displaces
                $int1 {group:$g} personnel to {nbhood:$n} 
                with activity $text1
            " $origin $n $g
        }

        return 1
    }
}

# TACTIC:DISPLACE:CREATE
#
# Creates a new DISPLACE tactic.

order define TACTIC:DISPLACE:CREATE {
    title "Create Tactic: Displace Civilians"

    options \
        -sendstates {PREP PAUSED}

    parm owner     enum   "Owner"           -enumtype {agent system} \
                                            -context yes
    parm g         enum   "Group"           -enumtype civgroup
    parm n         enum   "Neighborhood"    -enumtype nbhood
    parm text1     enum   "Activity"        -enumtype {activity civ}
    parm int1      text   "Personnel"
    parm priority  enum   "Priority"        -enumtype ePrioSched  \
                                            -displaylong yes      \
                                            -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type {agent system}
    prepare g        -toupper   -required -type civgroup
    prepare n        -toupper   -required -type nbhood
    prepare text1    -toupper   -required -type {activity civ}
    prepare int1                -required -type ingpopulation
    prepare priority -tolower             -type ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) DISPLACE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:DISPLACE:UPDATE
#
# Updates existing DISPLACE tactic.

order define TACTIC:DISPLACE:UPDATE {
    title "Update Tactic: Displace Activity"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id key  "Tactic ID"       -context yes            \
                                          -table   tactics_DISPLACE \
                                          -keys    tactic_id
    parm owner     disp  "Owner"
    parm g         enum  "Group"          -enumtype civgroup
    parm n         enum  "Neighborhood"   -enumtype nbhood
    parm text1     enum  "Activity"       -enumtype {activity civ}
    parm int1      text  "Personnel"
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare g          -toupper  -type civgroup
    prepare n          -toupper  -type nbhood
    prepare text1      -toupper  -type {activity civ}
    prepare int1                 -type ingpopulation

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType DISPLACE $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


