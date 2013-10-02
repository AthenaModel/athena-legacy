#-----------------------------------------------------------------------
# TITLE:
#    tactic_stance.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): STANCE(f,mode,glist,nlist,drel) tactic
#
#    This module implements the STANCE tactic, which allows an
#    actor to tell his force groups to adopt a particular stance
#    (designated relationship) toward particular groups or neighborhoods.
#    The designated relationship is taken into account when computing
#    neighborhood security.
#    
# PARAMETER MAPPING:
#
#    f       <= f
#    text1   <= mode
#    glist   <= glist
#    nlist   <= nlist
#    x1      <= drel
#    on_lock <= on_lock
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: STANCE

tactic type define STANCE {f text1 glist nlist x1 on_lock} actor {
    #-------------------------------------------------------------------
    # Public Methods

    # reset
    #
    # Clears the stance_* tables prior to the beginning of strategy
    # execution.

    typemethod reset {} {
        rdb eval {
            DELETE FROM stance_fg;
            DELETE FROM stance_nfg;
        }
    }

    # assess
    #
    # This command overrides the actor-specified/default stance
    # on a neighborhood by neighborhood basis.
    #
    # At present, if group f is attacking group g in n, the maximum
    # stance is force.maxAttackingStance.

    typemethod assess {} {
        # FIRST, get the max stance
        set maxStance [parm get force.maxAttackingStance]

        rdb eval {
            SELECT A.n                        AS n,
                   A.f                        AS f,
                   A.g                        AS g,
                   coalesce(S.stance, H.hrel) AS stance
            FROM attroe_nfg AS A
            JOIN uram_hrel  AS H USING (f,g)
            LEFT OUTER JOIN stance_fg AS S USING (f,g)
        } {
            if {$maxStance < $stance} {
                rdb eval {
                    INSERT INTO stance_nfg(n,f,g,stance)
                    VALUES($n,$f,$g,$maxStance)
                }
            }
        }
    }

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {}

        append result \
            "Group $f adopts a stance of [format %.2f $x1] " \
            "([qaffinity longname $x1]) toward "

        switch -exact -- $text1 {
            GROUP {
                if {[llength $glist] == 1} {
                    append result "this group: $glist."
                } else {
                    append result "these groups: [join $glist {, }]."
                }
            }

            NBHOOD {
                append result "the civilians in "

                if {[llength $nlist] == 1} {
                    append result "this neighborhood: $nlist."
                } else {
                    append result "these neighborhoods: [join $nlist {, }]."
                }
            }

            default { error "Unknown mode: \"$text1\"" }
        }
    }

    typemethod check {tdict} {
        dict with tdict {}
        set errors [list]

        # f
        if {$f ni [group ownedby $owner]} {
            lappend errors \
                "Group $f does not exist, or actor $owner no longer owns it."
        }

        # glist/nlist
        switch -exact -- $text1 {
            GROUP {
                foreach g $glist {
                    if {$g ni [group names]} {
                        lappend errors "Group $g no longer exists."
                    }
                }
            }

            NBHOOD {
                foreach n $nlist {
                    if {$n ni [nbhood names]} {
                        lappend errors "Neighborhood $n no longer exists."
                    }
                }
            }

            default { error "Unknown mode: \"$text1\"" }
        }

        return [join $errors "  "]
    }

    typemethod execute {tdict} {
        dict with tdict {}

        # FIRST, get the groups.
        if {$text1 eq "NBHOOD"} {
            set glist [list]
            foreach n $nlist {
                set glist [concat $glist [civgroup gIn $n]]
            }
        }

        # NEXT, determine which groups to ignore.
        set gIgnored [rdb eval "
            SELECT g 
            FROM stance_fg
            WHERE f=\$f AND g IN ('[join $glist ',']')
        "]

        # NEXT, set f's designated relationship with each g
        set gSet [list]

        foreach g $glist {
            if {$g ni $gIgnored} {
                lappend gSet $g

                rdb eval {
                    INSERT OR IGNORE INTO stance_fg(f,g,stance)
                    VALUES($f,$g,$x1)
                }
            }
        }

        # NEXT, log what happened.
        set logIds [concat $nlist $gSet] 

        if {[llength $gSet] == 0} {
            set msg "
                STANCE: Actor {actor:$owner} directed group {group:$f} to 
                adopt a stance of [format %.2f $x1] ([qaffinity longname $x1])
                toward a number of groups; however, $f's stances toward these
                groups were already set by higher-priority tactics.
            "

            sigevent log 2 tactic $msg $owner {*}$logIds

            return 0
        }

        set msg "
            STANCE: Actor {actor:$owner}'s group {group:$f} adopts stance
            of [format %.2f $x1] ([qaffinity longname $x1]) toward 
        "

        append msg "group(s): [join $gSet {, }]."

        if {[llength $gIgnored] > 0} {
            append msg " 
                Group {group:$f}'s stance toward these group(s) was
                already set by a prior tactic: [join $gIgnored {, }].
            "
        }

        sigevent log 2 tactic $msg $owner {*}$logIds

        return 1
    }


    #-------------------------------------------------------------------
    # Helpers

    # OtherThan f
    #
    # f   - A group
    #
    # Returns a shortname/longname dictionary of all groups other than
    # f.

    typemethod OtherThan {f} {
        return [rdb eval {
            SELECT g,longname FROM groups
            WHERE g != $f
            ORDER BY g
        }]
    }
}

# TACTIC:STANCE:CREATE
#
# Creates a new STANCE tactic.

order define TACTIC:STANCE:CREATE {
    title "Create Tactic: Force Group Stance"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "Force Group:" -for f
        enum f -listcmd {frcgroup ownedby $owner}

        rcc "Mode:" -for text1
        selector text1 {
            case GROUP "By Group" {
                rcc "Groups:" -for glist
                enumlonglist glist -width 30 \
                    -dictcmd {tactic::STANCE OtherThan $f}
            }

            case NBHOOD "By Neighborhood" {
                rcc "Neighborhoods:" -for nlist
                nlist nlist
            }
        }

        rcc "Designated Rel.:" -for x1
        rel x1 -showsymbols yes

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock -defvalue 1

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner -toupper -required -type actor

    returnOnError

    prepare f     -toupper -required -oneof [frcgroup ownedby $parms(owner)]
    prepare text1 -toupper -required -selector

    returnOnError

    if {$parms(text1) eq "GROUP"} {
        prepare glist -toupper \
            -someof [dict keys [tactic::STANCE OtherThan $parms(f)]]
    } elseif {$parms(text1) eq "NBHOOD"} {
        prepare nlist -toupper -listof nbhood
    }

    prepare x1  -num -toupper -required -type   qaffinity
    prepare on_lock                     -type   boolean
    prepare priority -tolower           -type   ePrioSched

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) STANCE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:STANCE:UPDATE
#
# Updates existing STANCE tactic.

order define TACTIC:STANCE:UPDATE {
    title "Update Tactic: Force Group Stance"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_STANCE -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "Force Group:" -for f
        enum f -listcmd {frcgroup ownedby $owner}

        rcc "Mode:" -for text1
        selector text1 {
            case GROUP "By Group" {
                rcc "Groups:" -for glist
                enumlonglist glist -width 30 \
                    -dictcmd {tactic::STANCE OtherThan $f}
            }

            case NBHOOD "By Neighborhood" {
                rcc "Neighborhoods:" -for nlist
                nlist nlist
            }
        }

        rcc "Designated Rel.:" -for x1
        rel x1 -showsymbols yes

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, Make sure this is a valid tactic.
    prepare tactic_id -required -type tactic
    validate tactic_id { tactic RequireType STANCE $parms(tactic_id) }
    returnOnError

    # NEXT, load the unspecified attributes from the database.
    tactic delta parms 

    # NEXT, validate the remaining parameters
    prepare f     -toupper -required -oneof  [frcgroup ownedby $parms(owner)]
    prepare text1 -toupper -required -selector

    returnOnError

    if {$parms(text1) eq "GROUP"} {
        prepare glist -toupper \
            -someof [dict keys [tactic::STANCE OtherThan $parms(f)]]
    } elseif {$parms(text1) eq "NBHOOD"} {
        prepare nlist -toupper -listof nbhood
    }

    prepare x1 -num -toupper -required -type qaffinity
    prepare on_lock -type boolean

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}



