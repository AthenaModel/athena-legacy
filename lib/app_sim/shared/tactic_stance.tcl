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
        return 0

        dict with tdict {}

        # FIRST, get the groups.
        if {$text1 eq "NBHOOD"} {
            foreach n $nlist {
                set glist [concat $glist [civgroup gIn $n]]
            }
        }

        # NEXT, set f's designated relationship with each g
        foreach g $glist {
            # TBD: Need a new table, drel_fg.
            # TBD: Cleared at the beginning of every strategy tock.
            # If entry already present, do not set it; but make a note.

            # gset: groups for which drel_fg is set
            # gignored: groups for which drel_fg is not set

            set gset $glist ;# Until infrastructure is in place
        }

        # NEXT, log what happened.
        set logIds [concat $nlist $glist] 

        set msg "
            STANCE: Actor {actor:$owner}'s group {group:$f} adopts stance
            of [format %.2f $x1] ([qaffinity longname $x1]) toward 
        "

        if {$mode eq "GROUP"} {
            append msg "group(s): [join $gset {, }]."
        } else {
            append msg "civilians in: [join $nlist {, }]."
        }

        if {[llength $gignored] > 0} {
            append msg " 
                Group {group:$f}'s stance toward these group(s) was
                set by a prior tactic: [join $gignored {, }].
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

    prepare x1       -toupper -required -type   qaffinity
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

    prepare x1 -toupper -required -type qaffinity
    prepare on_lock -type boolean

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}



