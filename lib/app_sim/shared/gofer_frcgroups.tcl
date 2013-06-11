#-----------------------------------------------------------------------
# TITLE:
#    gofer_frcgroups.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Force groups gofer
#    
#    gofer_frcgroups: A list of force groups produced according to 
#    various rules

#-----------------------------------------------------------------------
# gofer::FRCGROUPS

gofer define FRCGROUPS {
    rc "" -width 3in -span 3
    label {
        Enter a rule for selecting a set of force groups.
    }

    rc "" -for _rule
    selector _rule {
        case BY_VALUE "By name" {
            cc "  " -for raw_value
            enumlonglist raw_value -dictcmd {::frcgroup namedict} \
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
# Some set of force groups chosen by the user.

gofer rule FRCGROUPS BY_VALUE {raw_value} {
    typemethod construct {raw_value} {
        return [$type validate [dict create raw_value $raw_value]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create raw_value \
            [listval "groups" {frcgroup validate} $raw_value]
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

