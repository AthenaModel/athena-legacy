#-----------------------------------------------------------------------
# TITLE:
#    tactic_demob.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): DEMOB(g,mode,personnel,nlist,once) tactic
#
#    This module implements the DEMOB tactic, which demobilizes
#    force or ORG group personnel, i.e., moves them out of the playbox.
#
# PARAMETER MAPPING:
#
#    g     <= g
#    text1 <= mode: ALL|SOME
#    int1  <= personnel
#    once  <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: DEMOB

tactic type define DEMOB {g text1 int1 once} {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {
            if {$text1 eq "ALL"} {
                return "Demobilize all of group $g's available personnel."
            } else {
                return "Demobilize $int1 of group $g's available personnel."
            }
        }
    }

    typemethod dollars {tdict} {
        return [moneyfmt 0.0]
    }

    typemethod check {tdict} {
        set errors [list]

        dict with tdict {
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
            set available [rdb onecolumn {
                SELECT available FROM personnel_g WHERE g=$g
            }]

            # NEXT, if they want ALL personnel, we'll take all available.
            # If they want SOME, we'll take the requested amount, *if* 
            # they are available.
            if {$text1 eq "ALL" || $int1 > $available} {
                set int1 $available
            }

            if {$int1 == 0} {
                return 0
            }

            personnel demob $g $int1
                
            sigevent log 1 tactic "
                DEMOB: Actor {actor:$owner} demobilizes $int1 {group:$g} 
                personnel.
            " $owner $g
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
    # Refreshes the TACTIC:DEMOB:CREATE dialog fields when field values
    # change.

    typemethod RefreshCREATE {dlg fields fdict} {
        dict with fdict {
            if {"owner" in $fields} {
                set groups [rdb eval {
                    SELECT g FROM frcgroups
                    WHERE a=$owner
                }]
                
                $dlg field configure g -values $groups
            }

            if {"text1" in $fields} {
                if {$text1 eq "ALL"} {
                    $dlg disabled int1
                } else {
                    $dlg disabled {}
                }
            }
        }
    }

    # RefreshUPDATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the TACTIC:DEMOB:UPDATE dialog fields when field values
    # change.

    typemethod RefreshUPDATE {dlg fields fdict} {
        if {"tactic_id" in $fields} {
            $dlg loadForKey tactic_id *
            set fdict [$dlg get]

            dict with fdict {
                set groups [rdb eval {
                    SELECT g FROM frcgroups
                    WHERE a=$owner
                }]
                
                $dlg field configure g -values $groups
            }

            $dlg loadForKey tactic_id *
        }

        dict with fdict {
            if {"text1" in $fields} {
                if {$text1 eq "ALL"} {
                    $dlg disabled int1
                } else {
                    $dlg disabled {}
                }
            }
        }
    }
}

# TACTIC:DEMOB:CREATE
#
# Creates a new DEMOB tactic.

order define TACTIC:DEMOB:CREATE {
    title "Create Tactic: Demobilize Forces"

    options \
        -sendstates {PREP PAUSED}       \
        -refreshcmd {tactic::DEMOB RefreshCREATE}

    parm owner     actor "Owner"           -context yes
    parm g         enum  "Group"   
    parm text1     enum  "Mode"            -enumtype edemobmode  \
                                           -defval SOME          \
                                           -displaylong yes
    parm int1      text  "Personnel"
    parm once      enum  "Once Only?"      -enumtype eyesno      \
                                           -defval   YES
    parm priority  enum  "Priority"        -enumtype ePrioSched  \
                                           -displaylong yes      \
                                           -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   actor
    prepare g        -toupper   -required -type   {ptype fog}
    prepare text1    -toupper   -required -type   edemobmode
    prepare int1                          -type   ingpopulation
    prepare once     -toupper   -required -type   boolean
    prepare priority -tolower             -type   ePrioSched

    returnOnError

    # NEXT, cross-checks

    # text1 vs int1
    if {$parms(text1) eq "SOME" && $parms(int1) eq ""} {
        reject int1 "Required value when mode is SOME."
    }

    # g vs owner
    set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$parms(g)}]

    if {$a ne $parms(owner)} {
        reject g "Group $parms(g) is not owned by actor $parms(owner)."
    }

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) DEMOB

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:DEMOB:UPDATE
#
# Updates existing DEMOB tactic.

order define TACTIC:DEMOB:UPDATE {
    title "Update Tactic: Demob Forces"
    options \
        -sendstates {PREP PAUSED}                  \
        -refreshcmd {tactic::DEMOB RefreshUPDATE}

    parm tactic_id key  "Tactic ID"       -context yes           \
                                          -table   tactics_DEMOB \
                                          -keys    tactic_id
    parm owner     disp  "Owner"
    parm g         enum  "Group"
    parm text1     enum  "Mode"           -enumtype edemobmode   \
                                          -displaylong yes
    parm int1      text  "Personnel"
    parm once      enum  "Once Only?"     -enumtype eyesno       \
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare g          -toupper  -type {ptype fog}
    prepare text1      -toupper  -type edemobmode
    prepare int1                 -type ingpopulation
    prepare once       -toupper  -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType DEMOB $parms(tactic_id) }

    returnOnError

    # NEXT, cross-checks
    validate g {
        set owner [rdb onecolumn {
            SELECT owner FROM tactics WHERE tactic_id = $parms(tactic_id)
        }]

        set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$parms(g)}]

        if {$a ne $owner} {
            reject g "Group $parms(g) is not owned by actor $owner."
        }
    }

    # If text1 is now SOME, then int1 must be defined, either by
    # this order or in the RDB.
    set oldInt1 [rdb onecolumn {
        SELECT int1 FROM tactics WHERE tactic_id = $parms(tactic_id)
    }]

    if {$parms(text1) eq "SOME"} {
        if {$parms(int1) eq "" && $oldInt1 eq ""} {
            reject int1 "Required value when mode is SOME."
        }
    }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


