#-----------------------------------------------------------------------
# TITLE:
#    gofer_civgroups.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Civilian groups gofer
#    
#    gofer_civgroups: A list of civilian groups produced according to 
#    various rules

#-----------------------------------------------------------------------
# gofer::CIVGROUPS

gofer define CIVGROUPS {
    rc "" -width 3in -span 3
    label {
        Enter a rule for selecting a set of civilian groups.
    }

    rc "" -for _rule
    selector _rule {
        case BY_VALUE "By name" {
            cc "  " -for raw_value
            enumlonglist raw_value -dictcmd {::civgroup namedict} \
                -width 30 -height 10 
        }

        case RESIDENT_IN "Resident in Neighborhood(s)" {
            cc "  " -for nlist
            enumlonglist nlist -dictcmd {::nbhood namedict} \
                -width 30 -height 10
        }

        case SUPPORTING_ACTOR "Supporting Actor(s)" {
            cc "" -for anyall
            enumlong anyall -dictcmd {::eanyall deflist}

            cc " " -for alist
            enumlonglist alist -dictcmd {::actor namedict} \
                -width 30 -height 10
        }

        case LIKING_ACTOR "Liking Actor(s)" {
            cc "" -for anyall
            enumlong anyall -dictcmd {::eanyall deflist}

            cc " " -for alist
            enumlonglist alist -dictcmd {::actor namedict} \
                -width 30 -height 10
        }

        case DISLIKING_ACTOR "Disliking Actor(s)" {
            cc "" -for anyall
            enumlong anyall -dictcmd {::eanyall deflist}

            cc " " -for alist
            enumlonglist alist -dictcmd {::actor namedict} \
                -width 30 -height 10
        }
    }
}

#-----------------------------------------------------------------------
# Helper Commands


# validateAnyAllAlist gdict
#
# gdict - A gdict with keys anyall, alist
#
# Validates a gdict that allows the user to specify any/all of 
# a list of actors.

proc ::gofer::CIVGROUPS::validateAnyAllAlist {gdict} {
    dict with gdict {}

    set result [dict create]

    dict set result anyall [eanyall validate $anyall]
    dict set result alist [listval "actors" {actor validate} $alist]
    return $result
}

# narrativeAnyAllAlist gdict ?opt?
#
# gdict - A gdict with keys anyall, alist
# opt   - Possibly "-brief"
#
# produces narrative

proc ::gofer::CIVGROUPS::narrativeAnyAllAlist {gdict {opt ""}} {
    dict with gdict {}

    if {[llength $alist] > 1} {
        if {$anyall eq "ANY"} {
            append result "any of "
        } else {
            append result "all of "
        }
    }

    append result [listnar "actor" "these actors" $alist $opt]

    return "$result"
}



#-----------------------------------------------------------------------
# Gofer Rules

# Rule: BY_VALUE
#
# Some set of civilian groups chosen by the user.

gofer rule CIVGROUPS BY_VALUE {raw_value} {
    typemethod construct {raw_value} {
        return [$type validate [dict create raw_value $raw_value]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create raw_value \
            [listval "groups" {civgroup validate} $raw_value]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [listnar "group" "these groups" $raw_value $opt]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        return $raw_value
    }
}

# Rule: RESIDENT_IN
#
# Non-empty civilian groups resident in some set of neighborhoods.

gofer rule CIVGROUPS RESIDENT_IN {nlist} {
    typemethod construct {nlist} {
        return [$type validate [dict create nlist $nlist]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create nlist \
            [listval "neighborhoods" {nbhood validate} $nlist]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        set text [listnar "" "these neighborhoods" $nlist $opt]

        return "non-empty civilian groups resident in $text"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        set out [list]
        foreach n $nlist {
            lappend out {*}[demog gIn $n]
        }
        return $out
    }

}

# Rule: SUPPORTING_ACTOR
#
# Civilian groups who have the desire and ability (i.e.,
# security) to contribute to the actor's support.

gofer rule CIVGROUPS SUPPORTING_ACTOR {anyall alist} {
    delegate typemethod validate using ::gofer::CIVGROUPS::validateAnyAllAlist

    typemethod construct {anyall alist} {
        return [$type validate [dict create anyall $anyall alist $alist]]
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that actively support "
        append result [::gofer::CIVGROUPS::narrativeAnyAllAlist $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        # Get keys
        dict with gdict {}

        set groups [dict create]

        if {$anyall eq "ANY"} {
            set num [expr {1}]
        } else {
            set num [llength $alist]
        }

        return [rdb eval "
            SELECT g FROM (
                SELECT g, count(support) AS num
                FROM civgroups
                JOIN support_nga USING (g)
                WHERE a IN ('[join $alist {','}]') 
                AND support > 0
                GROUP BY g 
            ) WHERE num >= \$num 
        "]
    }

}

# Rule: LIKING_ACTOR
#
# Civilian groups who have a positive (LIKE or SUPPORT) vertical
# relationship with any or all of a set of actors.

gofer rule CIVGROUPS LIKING_ACTOR {anyall alist} {
    delegate typemethod validate using ::gofer::CIVGROUPS::validateAnyAllAlist

    typemethod construct {anyall alist} {
        return [$type validate [dict create anyall $anyall alist $alist]]
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that like "
        append result [::gofer::CIVGROUPS::narrativeAnyAllAlist $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        # Get keys
        dict with gdict {}

        set groups [dict create]

        if {$anyall eq "ANY"} {
            set num [expr {1}]
        } else {
            set num [llength $alist]
        }

        return [rdb eval "
            SELECT g FROM (
                SELECT g, count(vrel) AS num
                FROM civgroups
                JOIN uram_vrel USING (g)
                WHERE a IN ('[join $alist {','}]') 
                AND vrel >= 0.2
                GROUP BY g 
            ) WHERE num >= \$num 
        "]
    }
}

# Rule: DISLIKING_ACTOR
#
# Civilian groups who have a negative (DISLIKE or OPPOSE) vertical
# relationship with any or all of a set of actors.

gofer rule CIVGROUPS DISLIKING_ACTOR {anyall alist} {
    delegate typemethod validate using ::gofer::CIVGROUPS::validateAnyAllAlist

    typemethod construct {anyall alist} {
        return [$type validate [dict create anyall $anyall alist $alist]]
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that dislike "
        append result [::gofer::CIVGROUPS::narrativeAnyAllAlist $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        # Get keys
        dict with gdict {}

        set groups [dict create]

        if {$anyall eq "ANY"} {
            set num [expr {1}]
        } else {
            set num [llength $alist]
        }

        return [rdb eval "
            SELECT g FROM (
                SELECT g, count(vrel) AS num
                FROM civgroups
                JOIN uram_vrel USING (g)
                WHERE a IN ('[join $alist {','}]') 
                AND vrel <= -0.2
                GROUP BY g 
            ) WHERE num >= \$num 
        "]
    }
}



