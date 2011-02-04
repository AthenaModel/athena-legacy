#-----------------------------------------------------------------------
# TITLE:
#    tactic_types.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Tactic Type Definitions
#
# Every Tactic Type defines an ensemble, ::tactic::<type>, with the
# following subcommands, each of which operates on a dictionary of 
# the tactic's parameters (and possibly other arguments):
#
#     narrative tdict
#         Creates a narrative description of the tactic
#
#     check tdict
#         Sanity-checks the tactic.  Note that this routine only needs 
#         to look for things that can change after the tactic was 
#         created., e.g., a force group that is no longer owned by
#         an appropriate actor.  Returns a message describing the
#         error if the tactic is invalid, and the empty string
#         otherwise.
#
#     dollars tdict
#         Returns a list of costs {minDollars desiredDollars} for
#         the tactic.  The tactic will execute if there's at least
#         minDollars available, and will consume up to desiredDollars
#         or whatever's left.
#
#     estdollars tdict
#         Returns the estimated cost in dollars of executing the tactic
#         once.
#    
#     estpersonnel tdict
#         Returns the estimated number of personnel required to execute the
#         tactic once.
#    
#     personnel_by_group tdict
#         Returns a dictionary of the number of personnel required to 
#         execute the tactic once, by owned FRC/ORG group.
#    
#     execute tdict dollars
#         Executions the tactic, given its parameters, and the actual
#         cost in dollars.
#
# In addition, each tactic type defines two orders,
# TACTIC:<type>:CREATE and TACTIC:<type>:UPDATE.
#
#-----------------------------------------------------------------------


#-------------------------------------------------------------------
# Tactic: DEFEND

snit::type ::tactic::DEFEND {
    pragma -hasinstances no

    typemethod narrative {tdict} {
        dict with tdict {
            return "Group $g defends in $n with ROE $text1"
        }
    }
    
    typemethod check {tdict} {
        set errors [list]

        # Force group g's owning actor and uniformed flag can both
        # change after the tactic is created.
        dict with tdict {
            # n
            if {$n ni [nbhood names]} {
                lappend errors "Neighborhood $n no longer exists."
            }

            # g
            if {$g ni [frcgroup names]} {
                lappend errors "Force group $g no longer exists."
            } else {
                rdb eval {SELECT uniformed,a FROM frcgroups WHERE g=$g} {}

                if {$a ne $owner} {
                    lappend errors \
                        "Force group $g is no longer owned by actor $owner."
                }

                if {!$uniformed} {
                    lappend errors \
                        "Force group $g is no longer a uniformed force group."
                }
            }
        }

        return [join $errors "  "]
    }

    typemethod dollars {tdict} {
        return [list 0.0 0.0]
    }

    typemethod estdollars {tdict} {
        return 0.0
    }

    typemethod estpersonnel {tdict} {
        return 0
    }

    typemethod personnel_by_group {tdict} {
        return {}
    }

    typemethod execute {tdict dollars} {
        log normal tactic "DEFEND($tdict): TBD"
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # RefreshCREATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the TACTIC:DEFEND:CREATE dialog fields when field values
    # change.

    typemethod RefreshCREATE {dlg fields fdict} {
        dict with fdict {
            if {"owner" in $fields} {
                set groups [rdb eval {
                    SELECT g FROM frcgroups
                    WHERE a=$owner AND uniformed=1
                }]
                
                $dlg field configure g -values $groups
            }
        }
    }
}

# TACTIC:DEFEND:CREATE
#
# Creates a new DEFEND tactic.

order define TACTIC:DEFEND:CREATE {
    title "Create Tactic: Set Defensive ROE"

    options \
        -sendstates {PREP PAUSED}       \
        -refreshcmd {tactic::DEFEND RefreshCREATE}

    parm owner    key  "Owner"             -table actors -key a
    parm g        enum "Defending Group"   
    parm n        enum "In Neighborhood"   -type nbhood
    parm text1    enum "ROE"               -type edefroeuf \
                                           -defval FIRE_BACK_IMMEDIATELY
    parm priority enum "Priority"          -type ePrioSched  \
                                           -displaylong      \
                                           -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare g        -toupper   -required -type frcgroup
    prepare n        -toupper   -required -type nbhood
    prepare text1    -toupper   -required -type edefroeuf
    prepare priority -tolower             -type ePrioSched

    returnOnError

    # NEXT, cross-checks
    rdb eval {SELECT uniformed,a FROM frcgroups WHERE g=$parms(g)} {}

    if {$a ne $parms(owner)} {
        reject g "Group $parms(g) is not owned by actor $parms(owner)."
    } elseif {!$uniformed} {
        reject g "Group $parms(g) is not a uniformed force group."
    }

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) DEFEND

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:DEFEND:UPDATE
#
# Updates existing DEFEND tactic.

order define TACTIC:DEFEND:UPDATE {
    title "Update Tactic: Set Defensive ROE"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {tactic RefreshUPDATE}

    parm tactic_id key  "Tactic ID"  -table tactics_DEFEND -key tactic_id
    parm owner     disp "Owner"
    parm g         disp "Defending Group"
    parm n         disp "In Neighborhood"
    parm text1     enum "ROE"             -type edefroeuf
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required           -type tactic
    prepare text1      -required -toupper  -type edefroeuf

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType DEFEND $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


#-------------------------------------------------------------------
# Tactic: SAVEMONEY

snit::type ::tactic::SAVEMONEY {
    pragma -hasinstances no

    typemethod narrative {tdict} {
        dict with tdict {
            return "Save $int1% of income for later use"
        }
    }

    typemethod check {tdict} {
        # Nothing to check
        return
    }

    typemethod estdollars {tdict} {
        return [lindex [$type dollars $tdict] 1]
    }

    typemethod dollars {tdict} {
        dict with tdict {
            set income [actor get $owner income]
            return [list 0.0 [expr {$income*$int1/100.0}]]
        }

        return 0
    }

    typemethod estpersonnel {tdict} {
        return 0
    }

    typemethod personnel_by_group {tdict} {
        return {}
    }

    typemethod execute {tdict dollars} {
        log normal tactic "SAVEMONEY($tdict): \$$dollars"
        
        dict with tdict {
            rdb eval {
                UPDATE actors 
                SET cash = cash + $dollars
                WHERE a=$owner;
            }
        }
    }
}

# TACTIC:SAVEMONEY:CREATE
#
# Creates a new SAVEMONEY tactic.

order define TACTIC:SAVEMONEY:CREATE {
    title "Create Tactic: Save Money"

    options -sendstates {PREP PAUSED}

    parm owner    key  "Owner"             -table actors -key a
    parm int1     text "Percent of Income" -defval 10
    parm priority enum "Priority"          -type ePrioSched \
                                           -displaylong     \
                                           -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare int1                -required -type ipercent
    prepare priority -tolower             -type ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parm dict
    set parms(tactic_type) SAVEMONEY

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:SAVEMONEY:UPDATE
#
# Updates existing SAVEMONEY tactic.

order define TACTIC:SAVEMONEY:UPDATE {
    title "Update Tactic: Save Money"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {tactic RefreshUPDATE}

    parm tactic_id key  "Tactic ID"  -table tactics_SAVEMONEY -key tactic_id
    parm owner     disp "Owner"
    parm int1      text "Percent"
} {
    # FIRST, prepare the parameters
    prepare tactic_id   -required -type tactic
    prepare int1        -required -type ipercent

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType SAVEMONEY $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


