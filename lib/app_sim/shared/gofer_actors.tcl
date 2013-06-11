#-----------------------------------------------------------------------
# TITLE:
#    gofer_actors.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Actors gofer
#    
#    gofer_actors: A list of actors produced according to 
#    various rules

#-----------------------------------------------------------------------
# gofer::ACTORS

gofer define ACTORS {
    rc "" -width 3in -span 3
    label {
        Enter a rule for selecting a set of actors.
    }

    rc "" -for _rule
    selector _rule {
        case BY_VALUE "By name" {
            cc "  " -for raw_value
            enumlonglist raw_value -dictcmd {::actor namedict} \
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
# Some set of actors chosen by the user.

gofer rule ACTORS BY_VALUE {raw_value} {
    typemethod construct {raw_value} {
        return [$type validate [dict create raw_value $raw_value]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create raw_value \
            [listval "actors" {actor validate} $raw_value]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [listnar "actor" "these actors" $raw_value $opt]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        return $raw_value
    }
}

