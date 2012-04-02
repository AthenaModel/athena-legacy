#-----------------------------------------------------------------------
# TITLE:
#    tactic_defroe.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Athena Attrition Model: Defending Rules of Engagement
#
#    This module implements the Defending ROE tactic and entity.  
#    Every uniformed force group has a defending ROE of 
#    FIRE_BACK_IF_PRESSED by default.  The default is overridden by 
#    the DEFROE tactic, which inserts an entry into the defroe_ng table
#    on execution.  The override lasts until the next strategy execution 
#    tock.
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: DEFROE

tactic type define DEFROE {n g text1} actor {
    #-------------------------------------------------------------------
    # Public Methods

    # clear
    #
    # Deletes all entries from defroe_ng.

    typemethod reset {} {
        rdb eval { DELETE FROM defroe_ng }
    }

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.


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

    # execute
    #
    # Places an entry in the defroe_ng table to override the
    # default Defending ROE.

    typemethod execute {tdict} {
        dict with tdict {
            rdb eval {
                INSERT OR REPLACE INTO defroe_ng(n, g, roe)
                VALUES($n, $g, $text1);
            }

            sigevent log 2 tactic "
                DEFROE: Group {group:$g} defends in {nbhood:$n} 
                with ROE $text1.
            " $owner $n $g

            return 1
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
    # Refreshes the TACTIC:DEFROE:CREATE dialog fields when field values
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

# TACTIC:DEFROE:CREATE
#
# Creates a new DEFROE tactic.

order define TACTIC:DEFROE:CREATE {
    title "Create Tactic: Defensive ROE"

    options \
        -sendstates {PREP PAUSED}       \
        -refreshcmd {tactic::DEFROE RefreshCREATE}

    parm owner    actor "Owner"            -context yes
    parm g        enum  "Defending Group"   
    parm n        enum  "In Neighborhood"  -enumtype nbhood
    parm text1    enum  "ROE"              -enumtype edefroeuf \
                                           -defval FIRE_BACK_IMMEDIATELY
    parm priority enum "Priority"          -enumtype ePrioSched  \
                                           -displaylong yes      \
                                           -defval bottom
    parm on_lock   enum  "Exec On Lock?"   -enumtype eyesno \
                                           -defval NO
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare g        -toupper   -required -type frcgroup
    prepare n        -toupper   -required -type nbhood
    prepare text1    -toupper   -required -type edefroeuf
    prepare priority -tolower             -type ePrioSched
    prepare on_lock             -required -type boolean

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
    set parms(tactic_type) DEFROE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:DEFROE:UPDATE
#
# Updates existing DEFROE tactic.

order define TACTIC:DEFROE:UPDATE {
    title "Update Tactic: Defensive ROE"
    options \
        -sendstates {PREP PAUSED}                           \
        -refreshcmd {orderdialog refreshForKey tactic_id *}

    parm tactic_id key  "Tactic ID"       -context yes            \
                                          -table   tactics_DEFROE \
                                          -keys    tactic_id
    parm owner     disp "Owner"
    parm g         disp "Defending Group"
    parm n         disp "In Neighborhood"
    parm text1     enum "ROE"             -enumtype edefroeuf
    parm on_lock   enum "Exec On Lock?"   -enumtype eyesno 
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required           -type tactic
    prepare text1      -required -toupper  -type edefroeuf
    prepare on_lock                        -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType DEFROE $parms(tactic_id)  }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}
