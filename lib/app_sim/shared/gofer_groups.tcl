#-----------------------------------------------------------------------
# TITLE:
#    gofer_groups.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Groups gofer
#    
#    gofer_groups: A list of groups produced according to 
#    various rules

#-----------------------------------------------------------------------
# gofer::GROUPS

gofer define GROUPS {
    rc "" -width 3in -span 3
    label {
        Enter a rule for selecting a set of groups.
    }

    rc "" -for _rule
    selector _rule {
        case BY_VALUE "By name" {
            cc "  " -for raw_value
            enumlonglist raw_value -dictcmd {::group namedict} \
                -width 30 -height 10 
        }
    }
}

#-----------------------------------------------------------------------
# Helper Commands

# TBD

#-----------------------------------------------------------------------
# Gofer Rules

# Rule: BY_VALUE
#
# Some set of groups chosen by the user.

gofer rule GROUPS BY_VALUE {raw_value} {
    typemethod construct {raw_value} {
        return [$type validate [dict create raw_value $raw_value]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create raw_value \
            [listval "groups" {group validate} $raw_value]
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

