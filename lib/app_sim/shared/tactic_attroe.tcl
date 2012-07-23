#-----------------------------------------------------------------------
# TITLE:
#    tactic_attroe.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Athena Attrition Model: Attacking Rules of Engagement
#
#    This module implements the Attacking ROE tactic.
#    Every force group has an attacking ROE of DO_NOT_ATTACK by
#    default with respect to every other force group.  This default 
#    is overridden by the ATTROE tactic, which inserts an entry into 
#    the attroe_nfg table on execution.  The override lasts until the next
#    strategy execution tock.
#
#    ATTROE(n,f,g,roe,max_attacks)
#
#    n           <= n
#    f           <= f
#    g           <= g
#    roe         <= text1
#    max_attacks <= int1
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: ATTROE

tactic type define ATTROE {n f g text1 int1} actor {
    #-------------------------------------------------------------------
    # Public Methods

    # clear
    #
    # Deletes all entries from attroe_nfg.

    typemethod reset {} {
        # FIRST, reimburse the owning actor for the unused attacks
        rdb eval {
            SELECT F.a                                         AS a,
                   F.attack_cost * (A.max_attacks - A.attacks) AS extra
            FROM attroe_nfg AS A
            JOIN frcgroups AS F ON (A.f = F.g)
            WHERE F.attack_cost > 0
            AND   A.max_attacks > A.attacks
        } {
            log normal attroe "Return \$$extra to $a"
            cash refund $a $extra
        }

        # NEXT, delete the old ROEs in preparation for next time.
        rdb eval { DELETE FROM attroe_nfg }
    }

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.


    typemethod narrative {tdict} {
        dict with tdict {
            if {$text1 eq "DO_NOT_ATTACK"} {
                return "Group $f will not attack $g in $n."
            } elseif {$text1 eq "ATTACK"} {
                return [normalize "
                    Group $f attacks $g in $n up to $int1 times/week.
                "]
            } else {
                return [normalize "
                    Group $f attacks $g in $n with ROE $text1
                    up to $int1 times/week.
                "]
            }
        }
    }
    
    typemethod check {tdict} {
        set errors [list]

        # Force group g's owning actor and uniformed flag can both
        # change after the tactic is created.
        dict with tdict {
            rdb eval {
                SELECT uniformed,a FROM frcgroups WHERE g=$f
            } fdata {}

            rdb eval {
                SELECT uniformed FROM frcgroups WHERE g=$g
            } gdata {}


            # n
            if {$n ni [nbhood names]} {
                lappend errors "Neighborhood $n no longer exists."
            }

            # f
            if {$f ni [frcgroup names]} {
                lappend errors "Force group $f no longer exists."
            } else {
                # f owned by a
                if {$fdata(a) ne $owner} {
                    lappend errors \
                        "Force group $f is no longer owned by actor $owner."
                }

                # ROE consistent with f
                if {$fdata(uniformed)} {
                    if {$text1 ni [eattroeuf names]} {
                        lappend errors \
                            "ROE is invalid for a uniformed group: \"$text1\"."
                    }
                } else {
                    if {$text1 ni [eattroenf names]} {
                        lappend errors \
                      "ROE is invalid for a non-uniformed group: \"$text1\"."
                    }
                }
            }

            # g
            if {$g ni [frcgroup names]} {
                lappend errors "Force group $g no longer exists."
            }

            if {$f in [frcgroup names] && $g in [frcgroup names]} {
                if {$fdata(uniformed) == $gdata(uniformed)} {
                    if {$fdata(uniformed)} {
                        lappend errors \
                            "Groups $f and $g are both uniformed."
                    } else {
                        lappend errors \
                            "Groups $f and $g are both non-uniformed."
                    }
                }
            }
        }

        return [join $errors " "]
    }

    # dollars
    #
    # Computes the expected cost for the max number of attacks.

    typemethod dollars {tdict} {
        dict with tdict {
            rdb eval {
                SELECT attack_cost FROM frcgroups WHERE g=$f
            } {
                return [moneyfmt [expr {$attack_cost * $int1}]]
            }
        }

        # In case f has been deleted.
        return "?"
    }

    # execute
    #
    # Places an entry in the attroe_nfg table to override the
    # default Attacking ROE.

    typemethod execute {tdict} {
        dict with tdict {
            # FIRST, get needed data.
            rdb eval {
                SELECT attack_cost,uniformed FROM frcgroups WHERE g=$f
            } {}

            rdb eval {SELECT a AS gOwner FROM frcgroups WHERE g=$g} {}
            
            # FIRST, can we afford it?
            let cost {$attack_cost * $int1}

            if {![cash spend $owner $cost]} {
                return 0
            }

            # NEXT, create the ROE.
            rdb eval {
                INSERT OR REPLACE 
                INTO attroe_nfg(n,f,g,uniformed,roe,max_attacks)
                VALUES($n, $f, $g, $uniformed, $text1, $int1);
            }

            if {$text1 eq "DO_NOT_ATTACK"} {
                sigevent log 2 tactic "
                    ATTROE: Group {group:$f} will not attack {group:$g} 
                    in {nbhood:$n}.
                " $owner $n $f $g $gOwner
            } else {
                sigevent log 2 tactic "
                    ATTROE: Group {group:$f} attacks {group:$g} in {nbhood:$n} 
                    with ROE $text1 up to $int1 times/week.
                " $owner $n $f $g $gOwner
            }

            return 1
        }
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # OppositeTo f
    #
    # f   - A force group
    #
    # Returns a list of the groups whose uniformed flag is opposite that
    # of f.

    typemethod OppositeTo {f} {
        rdb eval {SELECT uniformed FROM frcgroups WHERE g=$f} {}

        return [rdb eval {
            SELECT g FROM frcgroups
            WHERE uniformed != $uniformed
        }]
    }
}

# TACTIC:ATTROE:CREATE
#
# Creates a new ATTROE tactic.

order define TACTIC:ATTROE:CREATE {
    title "Create Tactic: Attacking ROE"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Attacking Group:" -for f
        enum f -listcmd {group ownedby $owner}

        rcc "Defending Group:" -for g
        enum g -listcmd {tactic::ATTROE OppositeTo $f}

        rcc "In Neighborhood:" -for n
        nbhood n
       
        rcc "ROE" -for text1
        when {$f in [frcgroup uniformed names]} {
            enumlong text1 -dictcmd {eattroeuf deflist} -defvalue DO_NOT_ATTACK
        } else {
            enumlong text1 -dictcmd {eattroenf deflist} -defvalue DO_NOT_ATTACK
        }

        rcc "Max Attacks" -for int1
        text int1 -defvalue 1
        label "per week"

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type actor
    prepare f        -toupper   -required -type frcgroup
    prepare g        -toupper   -required -type frcgroup
    prepare n        -toupper   -required -type nbhood
    prepare text1    -toupper   -required
    prepare int1                -required -type ipositive
    prepare priority -tolower             -type ePrioSched

    returnOnError

    # NEXT, cross-checks
    rdb eval {SELECT uniformed,a FROM frcgroups WHERE g=$parms(f)} fdata {}
    rdb eval {SELECT uniformed   FROM frcgroups WHERE g=$parms(g)} gdata {}

    if {$fdata(a) ne $parms(owner)} {
        reject f "Group $parms(f) is not owned by actor $parms(owner)."
    }

    if {$fdata(uniformed) == $gdata(uniformed)} {
        if {$fdata(uniformed)} {
            reject g "Groups $parms(f) and $parms(g) are both uniformed"
        } else {
            reject g "Groups $parms(f) and $parms(g) are both non-uniformed"
        }
    }

    validate text1 {
        if {$fdata(uniformed)} {
            eattroeuf validate $parms(text1)
        } else {
            eattroenf validate $parms(text1)
        }
    }

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) ATTROE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:ATTROE:UPDATE
#
# Updates existing ATTROE tactic.

order define TACTIC:ATTROE:UPDATE {
    title "Update Tactic: Attacking ROE"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_ATTROE -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Attacking Group:" -for f
        enum f -listcmd {group ownedby $owner}

        rcc "Defending Group:" -for g
        enum g -listcmd {tactic::ATTROE OppositeTo $f}

        rcc "In Neighborhood:" -for n
        nbhood n
       
        rcc "ROE" -for text1
        when {$f in [frcgroup uniformed names]} {
            enumlong text1 -dictcmd {eattroeuf deflist}
        } else {
            enumlong text1 -dictcmd {eattroenf deflist}
        }

        rcc "Max Attacks" -for int1
        text int1
        label "per week"

    }
} {
    # FIRST, validate the tactic ID.
    prepare tactic_id  -required           -type tactic
    returnOnError
    
    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType ATTROE $parms(tactic_id)  }
    returnOnError

    # NEXT, get the old data
    tactic delta parms

    # NEXT, prepare the remaining parameters
    prepare f                     -toupper -type frcgroup
    prepare g                     -toupper -type frcgroup
    prepare n                     -toupper -type nbhood
    prepare text1                 -toupper
    prepare int1                           -type ipositive

    returnOnError


    # NEXT, cross-checks
    rdb eval {SELECT uniformed,a FROM frcgroups WHERE g=$parms(f)} fdata {}
    rdb eval {SELECT uniformed   FROM frcgroups WHERE g=$parms(g)} gdata {}

    if {$fdata(a) ne $parms(owner)} {
        reject f "Group $parms(f) is not owned by actor $parms(owner)."
    }

    if {$fdata(uniformed) == $gdata(uniformed)} {
        if {$fdata(uniformed)} {
            reject g "Groups $parms(f) and $parms(g) are both uniformed"
        } else {
            reject g "Groups $parms(f) and $parms(g) are both non-uniformed"
        }
    }

    validate text1 {
        if {$fdata(uniformed)} {
            eattroeuf validate $parms(text1)
        } else {
            eattroenf validate $parms(text1)
        }
    }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}
