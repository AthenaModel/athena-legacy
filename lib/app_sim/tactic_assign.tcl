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
#    g     <= g
#    n     <= n
#    text1 <= activity; list depends on whether g is FRC or ORG
#    int1  <= personnel
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: ASSIGN

tactic type define ASSIGN {g n text1 int1} actor {
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

    # No cost, yet

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
        dict with tdict {
            # FIRST, retrieve relevant data.
            set unassigned [personnel unassigned $n $g]

            # NEXT, are there enough people available?
            if {$int1 > $unassigned} {
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


    # RefreshCREATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the TACTIC:ASSIGN:CREATE dialog fields when field values
    # change.

    typemethod RefreshCREATE {dlg fields fdict} {
        set disabled [list]
        
        dict with fdict {
            if {"owner" in $fields} {
                set groups [rdb eval {
                    SELECT g FROM agroups
                    WHERE a=$owner
                }]
                
                $dlg field configure g -values $groups
            }

            if {$g ne ""} {
                set gtype [string tolower [group gtype $g]]
                $dlg field configure text1 -values [activity $gtype names]
            } else {
                lappend disabled text1
                $dlg set text1 ""
            }
        }

        $dlg disabled $disabled
    }

    # RefreshUPDATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the TACTIC:ASSIGN:UPDATE dialog fields when field values
    # change.

    typemethod RefreshUPDATE {dlg fields fdict} {
        set disabled [list]
        
        if {"tactic_id" in $fields} {
            # Expand the enums to every conceivable value, so that
            # loadForKey won't fail.  We'll narrow it down in a moment.
            $dlg field configure g -values [group names]
            $dlg field configure text1 -values [activity frc names]

            $dlg loadForKey tactic_id *
            set fdict [$dlg get]

            dict with fdict {
                set groups [rdb eval {
                    SELECT g FROM agroups
                    WHERE a=$owner
                }]
                
                $dlg field configure g -values $groups

                if {$g ne ""} {
                    set gtype [string tolower [group gtype $g]]
                    $dlg field configure text1 -values [activity $gtype names]
                }
            }
        }

        if {"g" in $fields && "tactic_id" ni $fields} {
            dict with fdict {
                if {$g ne ""} {
                    set gtype [string tolower [group gtype $g]]
                    $dlg field configure text1 -values [activity $gtype names]
                } else {
                    lappend disabled text1
                    $dlg set text1 ""
                }
            }
        }

        $dlg disabled $disabled
    }
}

# TACTIC:ASSIGN:CREATE
#
# Creates a new ASSIGN tactic.

order define TACTIC:ASSIGN:CREATE {
    title "Create Tactic: Assign Activity"

    options \
        -sendstates {PREP PAUSED}       \
        -refreshcmd {tactic::ASSIGN RefreshCREATE}

    parm owner     actor "Owner"           -context yes
    parm g         enum  "Group"   
    parm n         enum  "Neighborhood"    -enumtype nbhood
    parm text1     enum  "Activity"    
    parm int1      text  "Personnel"
    parm priority  enum  "Priority"        -enumtype ePrioSched  \
                                           -displaylong yes      \
                                           -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare g        -toupper   -required -type {ptype fog}
    prepare n        -toupper   -required -type nbhood
    prepare text1    -toupper   -required -type {activity asched}
    prepare int1                -required -type ingpopulation
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
    options \
        -sendstates {PREP PAUSED}                  \
        -refreshcmd {tactic::ASSIGN RefreshUPDATE}

    parm tactic_id key  "Tactic ID"       -context yes            \
                                          -table   tactics_ASSIGN \
                                          -keys    tactic_id
    parm owner     disp  "Owner"
    parm g         enum  "Group"
    parm n         enum  "Neighborhood"   -enumtype nbhood
    parm text1     enum  "Activity"
    parm int1      text  "Personnel"
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare g          -toupper  -type {ptype fog}
    prepare n          -toupper  -type nbhood
    prepare text1      -toupper  -type {activity asched}
    prepare int1                 -type ingpopulation

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


