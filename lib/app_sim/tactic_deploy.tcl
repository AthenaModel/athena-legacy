#-----------------------------------------------------------------------
# TITLE:
#    tactic_deploy.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): DEPLOY(g,personnel,nlist) tactic
#
#    This module implements the DEPLOY tactic, which deploys a 
#    force or ORG group's personnel into one or more neighborhoods.
#    The troops remain as deployed until the next strategy tock, when
#    troops may be redeployed.
#
# TBD:
#
#    * Can we arrange for redeployments to be ignored if nothing's
#      changed, like the "once only" activity?
#
#    * We'd like to be able to deploy all remaining personnel.
#
# PARAMETER MAPPING:
#
#    g     <= g
#    int1  <= personnel
#    nlist <= nlist
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: DEPLOY

tactic type define DEPLOY {
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

            return "Deploy $int1 of group $g's available personnel into $ntext."
        }
    }

    typemethod dollars {tdict} {
        dict with tdict {
            rdb eval {
                SELECT cost FROM agroups WHERE g=$g
            } {
                return [moneyfmt [expr {$cost * $int1}]]
            }

            return "?"
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
            # FIRST, if there are insufficient troops available,
            # return 0.
            set available [rdb onecolumn {
                SELECT available FROM personnel_g WHERE g=$g
            }]

            if {$int1 > $available} {
                return 0
            }

            # NEXT, Pay the maintenance cost.
            set costPerPerson [rdb onecolumn {
                SELECT cost FROM agroups WHERE g=$g
            }]
            
            let cost {$costPerPerson * $int1}

            if {![actor spend $owner $cost]} {
                return 0
            }

            # NEXT, compute the number of troops to put in each
            # neighborhood: np($n -> $personnel).

            set num       [llength $nlist]
            let each      {$int1 / $num}
            let remainder {$int1 % $num}

            # NEXT, deploy the troops to those neighborhoods.
            set count 0
            foreach n $nlist {
                set troops $each

                if {[incr count] <= $remainder} {
                    incr troops
                }

                personnel deploy $n $g $troops
            }
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
    # Refreshes the TACTIC:DEPLOY:CREATE dialog fields when field values
    # change.

    typemethod RefreshCREATE {dlg fields fdict} {
        dict with fdict {
            if {"owner" in $fields} {
                set groups [rdb eval {
                    SELECT g FROM frcgroups
                    WHERE a=$owner
                }]
                
                $dlg field configure g -values $groups

                set ndict [rdb eval {
                    SELECT n,n FROM nbhoods
                    ORDER BY n
                }]
                
                $dlg field configure nlist -itemdict $ndict
            }
        }
    }

    # RefreshUPDATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the TACTIC:DEPLOY:UPDATE dialog fields when field values
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

                set ndict [rdb eval {
                    SELECT n,n FROM nbhoods
                    ORDER BY n
                }]
                
                $dlg field configure nlist -itemdict $ndict
            }

            $dlg loadForKey tactic_id *
        }
    }
}

# TACTIC:DEPLOY:CREATE
#
# Creates a new DEPLOY tactic.

order define TACTIC:DEPLOY:CREATE {
    title "Create Tactic: Deploy Forces"

    options \
        -sendstates {PREP PAUSED}       \
        -refreshcmd {tactic::DEPLOY RefreshCREATE}

    parm owner     actor "Owner"            -context yes
    parm g         enum  "Group"   
    parm int1      text  "Personnel"
    parm nlist     nlist "In Neighborhoods"
    parm priority  enum  "Priority"          -enumtype ePrioSched  \
                                             -displaylong yes      \
                                             -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type   actor
    prepare g        -toupper   -required -type   {ptype fog}
    prepare int1                -required -type   ingpopulation
    prepare nlist    -toupper   -required -listof nbhood
    prepare priority -tolower             -type   ePrioSched

    returnOnError

    # NEXT, cross-checks
    set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$parms(g)}]

    if {$a ne $parms(owner)} {
        reject g "Group $parms(g) is not owned by actor $parms(owner)."
    }

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) DEPLOY

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:DEPLOY:UPDATE
#
# Updates existing DEPLOY tactic.

order define TACTIC:DEPLOY:UPDATE {
    title "Update Tactic: Deploy Forces"
    options \
        -sendstates {PREP PAUSED}                  \
        -refreshcmd {tactic::DEPLOY RefreshUPDATE}

    parm tactic_id key  "Tactic ID"       -context yes            \
                                          -table   tactics_DEPLOY \
                                          -keys    tactic_id
    parm owner     disp  "Owner"
    parm g         enum  "Group"
    parm int1      text  "Personnel"
    parm nlist     nlist "In Neighborhoods"
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type   tactic
    prepare g          -toupper  -type   {ptype fog}
    prepare int1                 -type   ingpopulation
    prepare nlist      -toupper  -listof nbhood

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType DEPLOY $parms(tactic_id) }

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

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}

