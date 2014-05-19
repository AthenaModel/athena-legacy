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

gofer define CIVGROUPS group {
    rc "" -width 3in -span 3
    label {
        Enter a rule for selecting a set of civilian groups:
    }
    rc

    rc
    selector _rule {
        case BY_VALUE "By name" {
            rc "Select groups from the following list:"
            rc
            enumlonglist raw_value -dictcmd {::civgroup namedict} \
                -width 30 -height 10 
        }

        case RESIDENT_IN "Resident in Neighborhood(s)" {
            rc "Select groups that reside in any of the following neighborhoods:"
            rc
            enumlonglist nlist -dictcmd {::nbhood namedict} \
                -width 30 -height 10
        }

        case SA_IN "Subsistence in Neighborhood(s)" {
            rc "Select subsistence agriculture groups that reside in any of the following neighborhoods:"
            rc
            enumlonglist nlist -dictcmd {::nbhood namedict} \
                -width 30 -height 10
        }

        case NON_SA_IN "Non-Subsistence in Neighborhood(s)" {
            rc "Select non-subsistence agriculture groups that reside in any of the following neighborhoods:"
            rc
            enumlonglist nlist -dictcmd {::nbhood namedict} \
                -width 30 -height 10
        }

        case NOT_RESIDENT_IN "Not Resident in Neighborhood(s)" {
            rc "Select groups that do not reside in any of the following neighborhoods:"
            rc
            enumlonglist nlist -dictcmd {::nbhood namedict} \
                -width 30 -height 10
        }

        case MOOD_IS_GOOD "Mood is Good" { 
            rc "Select groups whose mood is good."
            rc
            rc {
                A group's mood is good if it is Satisfied or Very
                Satisfied, i.e., it is greater than 20.0.
            }
        }

        case MOOD_IS_BAD "Mood is Bad" { 
            rc "Select groups whose mood is bad."
            rc
            rc {
                A group's mood is bad if it is Dissatisfied or Very
                Dissatisfied, i.e., it is less than &minus;20.0.
            }
        }

        case MOOD_IS_AMBIVALENT "Mood is Ambivalent" { 
            rc "Select groups whose mood is ambivalent."
            rc
            rc {
                A group's mood is ambivalent if it is between
                &minus;20.0 and 20.0.
            }
        }

        case SUPPORTING_ACTOR "Supporting Actor(s)" {
            rc "Select groups that actively support "
            enumlong anyall -defvalue ANY -dictcmd {::eanyall deflist}
            label " the following actors:"

            rc
            enumlonglist alist -dictcmd {::actor namedict} \
                -width 30 -height 10

            rc {
                A group supports an actor if it contributes to the actor's 
                influence in some neighborhood.
            }
        }

        case LIKING_ACTOR "Liking Actor(s)" {
            rc "Select groups that like "
            enumlong anyall -defvalue ANY -dictcmd {::eanyall deflist}
            label " the following actors:"

            rc
            enumlonglist alist -dictcmd {::actor namedict} \
                -width 30 -height 10

            rc {
                A group likes an actor if its vertical relationship 
                with the actor is LIKE or SUPPORT (i.e., the 
                relationship is greater than or equal to 0.2).
            }
        }

        case DISLIKING_ACTOR "Disliking Actor(s)" {
            rc "Select groups that dislike "
            enumlong anyall -defvalue ANY -dictcmd {::eanyall deflist}
            label " the following actors:"

            rc
            enumlonglist alist -dictcmd {::actor namedict} \
                -width 30 -height 10

            rc {
                A group dislikes an actor if its vertical relationship 
                with the actor is DISLIKE or OPPOSE (i.e., the 
                relationship is less than or equal to &minus;0.2).
            }
        }

        case LIKING_GROUP "Liking Group(s)" {
            rc "Select groups that like "
            enumlong anyall -defvalue ANY -dictcmd {::eanyall deflist}
            label " the following groups:"

            rc
            enumlonglist glist -dictcmd {::group namedict} \
                -width 30 -height 10

            rc {
                Group F likes group G if its horizontal relationship 
                with G is LIKE or SUPPORT (i.e., the 
                relationship is greater than or equal to 0.2).
            }
        }

        case DISLIKING_GROUP "Disliking Group(s)" {
            rc "Select groups that dislike "
            enumlong anyall -defvalue ANY -dictcmd {::eanyall deflist}
            label " the following groups:"

            rc
            enumlonglist glist -dictcmd {::group namedict} \
                -width 30 -height 10

            rc {
                Group F dislikes group G if its horizontal relationship 
                with G is DISLIKE or OPPOSE (i.e., the 
                relationship is less than or equal to &minus;0.2).
            }
        }

        case LIKED_BY_GROUP "Liked by Group(s)" {
            rc "Select groups that are liked by "
            enumlong anyall -defvalue ANY -dictcmd {::eanyall deflist}
            label " the following groups:"

            rc
            enumlonglist glist -dictcmd {::group namedict} \
                -width 30 -height 10

            rc {
                Group F is liked by group G if G's horizontal relationship 
                with F is LIKE or SUPPORT (i.e., the 
                relationship is greater than or equal to 0.2).
            }
        }

        case DISLIKED_BY_GROUP "Disliked by Group(s)" {
            rc "Select groups that are disliked by "
            enumlong anyall -defvalue ANY -dictcmd {::eanyall deflist}
            label " the following groups:"

            rc
            enumlonglist glist -dictcmd {::group namedict} \
                -width 30 -height 10

            rc {
                Group F is disliked by group G if G's horizontal relationship 
                with F is DISLIKE or OPPOSE (i.e., the 
                relationship is less than or equal to &minus;0.2).
            }
        }
    }
}

#-----------------------------------------------------------------------
# Helper Commands

# nonempty glist
#
# glist   - A list of groups
#
# Returns the list, filtering out empty civilian groups.

proc gofer::CIVGROUPS::nonempty {glist} {
    array set pop [rdb eval {
        SELECT g, population FROM gui_civgroups
    }]

    set result [list]
    foreach g $glist {
        if {[info exists pop($g)] && $pop($g) > 0} {
            lappend result $g
        }
    }

    return $result
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

        return [nonempty $raw_value]
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
        return [nonempty $out]
    }

}

# Rule: SA_IN
#
# Non-empty civilian groups who live by subsistence
# agriculture, resident in some set of neighborhoods.

gofer rule CIVGROUPS SA_IN {nlist} {
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

        return "non-empty subsistence agriculture groups resident in $text"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        set out [list]
        foreach n $nlist {
            lappend out {*}[demog saIn $n]
        }
        return $out
    }
}

# Rule: NON_SA_IN
#
# Non-empty civilian groups who DO NOT live by subsistence
# agriculture, resident in some set of neighborhoods.

gofer rule CIVGROUPS NON_SA_IN {nlist} {
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

        return "non-empty non-subsistence agriculture groups resident in $text"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        set out [list]
        foreach n $nlist {
            lappend out {*}[demog nonSaIn $n]
        }
        return $out
    }
}


# Rule: NOT_RESIDENT_IN
#
# Non-empty civilian groups not resident in any of some set of neighborhoods.

gofer rule CIVGROUPS NOT_RESIDENT_IN {nlist} {
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

        set text [listnar "" "any of these neighborhoods" $nlist $opt]

        return "non-empty civilian groups not resident in $text"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        set out [civgroup names]
        foreach n $nlist {
            foreach g [demog gIn $n] {
                ldelete out $g
            }
        }
        return [nonempty $out]
    }

}

# Rule: MOOD_IS_GOOD
#
# Civilian groups whose mood is Satisfied or Very Satisfied.

gofer rule CIVGROUPS MOOD_IS_GOOD {} {
    typemethod validate {gdict} {
        return [dict create]
    }

    typemethod construct {} {
        return [$type validate {}]
    }

    typemethod narrative {gdict {opt ""}} {
        return "civilian groups whose mood is good"
    }

    typemethod eval {gdict} {
        return [nonempty [rdb eval {
            SELECT g FROM uram_mood
            WHERE mood >= 20.0
        }]]
    }
}

# Rule: MOOD_IS_BAD
#
# Civilian groups whose mood is Dissatisfied or Very Dissatisfied.

gofer rule CIVGROUPS MOOD_IS_BAD {} {
    typemethod validate {gdict} {
        return [dict create]
    }

    typemethod construct {} {
        return [$type validate {}]
    }

    typemethod narrative {gdict {opt ""}} {
        return "civilian groups whose mood is bad"
    }

    typemethod eval {gdict} {
        return [nonempty [rdb eval {
            SELECT g FROM uram_mood
            WHERE mood <= -20.0
        }]]
    }
}

# Rule: MOOD_IS_AMBIVALENT
#
# Civilian groups whose mood is neither satisfied nor dissatisfied.

gofer rule CIVGROUPS MOOD_IS_AMBIVALENT {} {
    typemethod validate {gdict} {
        return [dict create]
    }

    typemethod construct {} {
        return [$type validate {}]
    }

    typemethod narrative {gdict {opt ""}} {
        return "civilian groups whose mood is ambivalent"
    }

    typemethod eval {gdict} {
        return [nonempty [rdb eval {
            SELECT g FROM uram_mood
            WHERE mood > -20.0 AND mood < 20.0
        }]]
    }
}

# Rule: SUPPORTING_ACTOR
#
# Civilian groups who have the desire and ability (i.e.,
# security) to contribute to the actor's support.

gofer rule CIVGROUPS SUPPORTING_ACTOR {anyall alist} {
    typemethod construct {anyall alist} {
        return [$type validate [dict create anyall $anyall alist $alist]]
    }

    typemethod validate {gdict} { 
        return [anyall_alist validate $gdict] 
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that actively support "
        append result [anyall_alist narrative $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        return [nonempty [anyall_alist supportingActor CIV $gdict]]
    }
}

# Rule: LIKING_ACTOR
#
# Civilian groups who have a positive (LIKE or SUPPORT) vertical
# relationship with any or all of a set of actors.

gofer rule CIVGROUPS LIKING_ACTOR {anyall alist} {
    typemethod construct {anyall alist} {
        return [$type validate [dict create anyall $anyall alist $alist]]
    }

    typemethod validate {gdict} { 
        return [anyall_alist validate $gdict] 
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that like "
        append result [anyall_alist narrative $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        return [nonempty [anyall_alist likingActor CIV $gdict]]
    }
}

# Rule: DISLIKING_ACTOR
#
# Civilian groups who have a negative (DISLIKE or OPPOSE) vertical
# relationship with any or all of a set of actors.

gofer rule CIVGROUPS DISLIKING_ACTOR {anyall alist} {
    typemethod construct {anyall alist} {
        return [$type validate [dict create anyall $anyall alist $alist]]
    }

    typemethod validate {gdict} { 
        return [anyall_alist validate $gdict] 
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that dislike "
        append result [anyall_alist narrative $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        return [nonempty [anyall_alist dislikingActor CIV $gdict]]
    }
}

# Rule: LIKING_GROUP
#
# Civilian groups who have a positive (LIKE or SUPPORT) horizontal
# relationship with any or all of a set of groups.

gofer rule CIVGROUPS LIKING_GROUP {anyall glist} {
    typemethod construct {anyall glist} {
        return [$type validate [dict create anyall $anyall glist $glist]]
    }

    typemethod validate {gdict} { 
        return [anyall_glist validate $gdict] 
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that like "
        append result [anyall_glist narrative $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        return [nonempty [anyall_glist likingGroup CIV $gdict]]
    }
}

# Rule: DISLIKING_GROUP
#
# Civilian groups who have a negative (DISLIKE or OPPOSE) horizontal
# relationship with any or all of a set of groups.

gofer rule CIVGROUPS DISLIKING_GROUP {anyall glist} {
    typemethod construct {anyall glist} {
        return [$type validate [dict create anyall $anyall glist $glist]]
    }

    typemethod validate {gdict} { 
        return [anyall_glist validate $gdict] 
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that dislike "
        append result [anyall_glist narrative $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        return [nonempty [anyall_glist dislikingGroup CIV $gdict]]
    }
}

# Rule: LIKED_BY_GROUP
#
# Civilian groups for whom any or all of set of groups have a positive 
# (LIKE or SUPPORT) horizontal relationship.

gofer rule CIVGROUPS LIKED_BY_GROUP {anyall glist} {
    typemethod construct {anyall glist} {
        return [$type validate [dict create anyall $anyall glist $glist]]
    }

    typemethod validate {gdict} { 
        return [anyall_glist validate $gdict] 
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that are liked by "
        append result [anyall_glist narrative $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        return [nonempty [anyall_glist likedByGroup CIV $gdict]]
    }
}

# Rule: DISLIKED_BY_GROUP
#
# Civilian groups for whom any or all of set of groups have a negative 
# (DISLIKE or OPPOSE) horizontal relationship.

gofer rule CIVGROUPS DISLIKED_BY_GROUP {anyall glist} {
    typemethod construct {anyall glist} {
        return [$type validate [dict create anyall $anyall glist $glist]]
    }

    typemethod validate {gdict} { 
        return [anyall_glist validate $gdict] 
    }

    typemethod narrative {gdict {opt ""}} {
        set result "civilian groups that are disliked by "
        append result [anyall_glist narrative $gdict $opt]
        return "$result"
    }

    typemethod eval {gdict} {
        return [nonempty [anyall_glist dislikedByGroup CIV $gdict]]
    }
}


