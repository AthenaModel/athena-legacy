#-----------------------------------------------------------------------
# TITLE:
#    tactic_deploy.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): DEPLOY(g,mode,personnel,nlist,reinforce) tactic
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
# PARAMETER MAPPING:
#
#    g         <= g
#    text1     <= mode: ALL|SOME
#    int1      <= personnel
#    nlist     <= nlist
#    reinforce <= reinforce
#    on_lock   <= on_lock
#    once      <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: DEPLOY

tactic type define DEPLOY {g text1 int1 nlist reinforce once on_lock} actor {
    #-------------------------------------------------------------------
    # Public Methods

    # reset
    #
    # Prepares the module to support strategy execution.  The last
    # tick's deployments are pulled into the past() array, and the
    # deploy_tng table is cleared.

    typemethod reset {} {
        rdb eval {
            DROP TABLE IF EXISTS working_deploy_tng;

            CREATE TABLE working_deploy_tng AS SELECT * FROM deploy_tng;
            DELETE FROM deploy_tng;
        }
    }

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {}

        if {$text1 eq "ALL"} {
            set output "Deploy all of group $g's remaining personnel"
        } else {
            set output "Deploy $int1 of group $g's personnel"
        }

        if {[llength $nlist] == 1} {
            append output " into neighborhood [lindex $nlist 0]"
        } else {
            append output " into neighborhoods [join $nlist {, }]"
        }

        if {$text1 eq "SOME"} {
            if {$reinforce} {
                append output " with reinforcement."
            } else {
                append output " without reinforcement."
            }
        } else {
            append output "."
        }
    }

    typemethod dollars {tdict} {
        dict with tdict {
            rdb eval {
                SELECT cost FROM agroups WHERE g=$g
            } {
                if {$text1 eq "SOME"} {
                    return [moneyfmt [expr {$cost * $int1}]]
                } elseif {$cost == 0.0} {
                    return [moneyfmt 0.0]
                }
            }
        
            # If the mode is "ALL" and the $cost is not zero, we
            # don't know what the total cost will be; and if 
            # g no longer exists, we don't know what the cost per
            # person is anyway.  So mark it unknown.

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
        dict with tdict {}

        # FIRST, retrieve relevant data.
        set available    [personnel available $g]
        set cash_on_hand [cash get $owner cash_on_hand]

        set costPerPerson [rdb onecolumn {
            SELECT cost FROM agroups WHERE g=$g
        }]

        if {$text1 eq "ALL" || $reinforce} {
            set alreadyDeployed 0
        } else {
            rdb eval {
                SELECT count(*)                        AS alreadyDeployed,
                       coalesce(sum(personnel), $int1) AS int1
                       FROM working_deploy_tng
                       WHERE tactic_id = $tactic_id
            } {}
        }


        # NEXT, if they want ALL personnel, we'll take as many as
        # we can afford.  If they want SOME, we'll take the 
        # requested amount, *if* we can afford it.
        if {$text1 eq "ALL"} {
            # FIRST, how many troops can we afford? All of them if we
            # are locking or they are free.
            if {[strategy locking] || $costPerPerson == 0.0} {
                set int1 $available
            } else {
                let maxTroops {double($cash_on_hand)/$costPerPerson}

                # int1 needs to be an integer.  int() truncates to
                # machine integer, not a bignum.  round() rounds to
                # a bignum; but we want to truncate.  Hence, 
                # round(floor(x)).
                let int1 {round(floor(min($available,$maxTroops)))}
            }

            # NEXT, if there are no troops left, we're done.
            if {$int1 == 0} {
                return 0
            }
        } else {
            # FIRST, we're only deploying SOME.  If there are 
            # insufficient troops available, we're done.
            if {$int1 > $available} {
                return 0
            }
        }

        # NEXT, Pay the maintenance cost, if we can.
        let cost {$costPerPerson * $int1}

        if {![cash spend $owner DEPLOY $cost]} {
            return 0
        }

        # NEXT, determine the deployment to each neighborhood.
        if {$alreadyDeployed} {
            array set byNbhood [rdb eval {
                SELECT n, personnel 
                FROM working_deploy_tng
                WHERE tactic_id=$tactic_id
            }]
        } else {
            set num       [llength $nlist]
            let each      {$int1 / $num}
            let remainder {$int1 % $num}

            set count 0
            foreach n $nlist {
                set troops $each

                if {[incr count] <= $remainder} {
                    incr troops
                }

                set byNbhood($n) $troops
            }
        }

        # NEXT, deploy the troops to those neighborhoods.
        foreach n $nlist {
            set troops $byNbhood($n)

            personnel deploy $n $g $troops

            rdb eval {
                INSERT INTO deploy_tng(tactic_id, n, g, personnel)
                VALUES($tactic_id, $n, $g, $troops)
            }
            
            sigevent log 2 tactic "
                DEPLOY: Actor {actor:$owner} deploys $troops {group:$g} 
                personnel to {nbhood:$n}
            " $owner $n $g
        }

        return 1
    }
}

# TACTIC:DEPLOY:CREATE
#
# Creates a new DEPLOY tactic.

order define TACTIC:DEPLOY:CREATE {
    title "Create Tactic: Deploy Forces"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Group:" -for g
        enum g -listcmd {group ownedby $owner}

        rcc "Mode:" -for text1
        selector text1 {
            case SOME "Deploy some of the group's personnel" {
                rcc "Personnel:" -for int1
                text int1

                rcc "Reinforce?" -for reinforce
                yesno reinforce -defvalue 0
            }

            case ALL "Deploy all of the group's remaining personnel" {}
        }

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
    prepare owner     -toupper   -required -type   actor
    prepare g         -toupper   -required -type   {ptype fog}
    prepare text1     -toupper   -required -selector
    prepare int1      -num                 -type   ipositive
    prepare nlist     -toupper   -required -listof nbhood
    prepare reinforce                      -type   boolean
    prepare priority  -tolower             -type   ePrioSched
    prepare once                           -type   boolean
    prepare on_lock                        -type   boolean

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
    set parms(tactic_type) DEPLOY

    # And make sure we have a reinforce flag.
    if {$parms(reinforce) eq ""} {
        set parms(reinforce) 0
    }

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:DEPLOY:UPDATE
#
# Updates existing DEPLOY tactic.

order define TACTIC:DEPLOY:UPDATE {
    title "Update Tactic: Deploy Forces"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_DEPLOY -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Group:" -for g
        enum g -listcmd {group ownedby $owner}

        rcc "Mode:" -for text1
        selector text1 {
            case SOME "Deploy some of the group's personnel" {
                rcc "Personnel:" -for int1
                text int1

                rcc "Reinforce?" -for reinforce
                yesno reinforce
            }

            case ALL "Deploy all of the group's remaining personnel" {}
        }

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
    prepare g          -toupper  -type   {ptype fog}
    prepare text1      -toupper  -selector
    prepare int1       -num      -type   ipositive
    prepare nlist      -toupper  -listof nbhood
    prepare reinforce            -type   boolean
    prepare once                 -type   boolean
    prepare on_lock              -type   boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType DEPLOY $parms(tactic_id) }

    returnOnError

    # NEXT, cross-checks
    tactic delta parms
    
    validate g {
        set a [rdb onecolumn {SELECT a FROM agroups WHERE g=$parms(g)}]

        if {$a ne $parms(owner)} {
            reject g "Group $parms(g) is not owned by actor $parms(owner)."
        }
    }

    # If text1 is now SOME, then int1 must be defined, either by
    # this order or in the RDB.
    if {$parms(text1) eq "SOME"} {
        if {$parms(int1) eq ""} {
            reject int1 "Required value when mode is SOME."
        }
    }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}


