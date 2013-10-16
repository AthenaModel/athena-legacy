#-----------------------------------------------------------------------
# TITLE:
#    gofer_number.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Number gofer
#    
#    gofer::NUMBER: A number, floating-or-integer, produced according to
#    one of various rules

#-----------------------------------------------------------------------
# gofer::NUMBER

gofer define NUMBER {
    rc "" -width 3in -span 3
    label {
        Enter a rule for retrieving a particular number.
    }
    rc

    rc
    selector _rule {
        case BY_VALUE "specific number" {
            rc
            rc "Enter the desired number:"
            rc
            text raw_value 
        }

        case COOP "coop(f,g)" {
            rc
            rc "Cooperation of civilian group"
            rc
            enumlong f -showkeys yes -dictcmd {::civgroup namedict}

            rc "with force group"
            rc
            enumlong g -showkeys yes -dictcmd {::frcgroup namedict}
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
# Some number chosen by the user.

gofer rule NUMBER BY_VALUE {raw_value} {
    typemethod construct {raw_value} {
        return [$type validate [dict create raw_value $raw_value]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create raw_value [snit::double validate $raw_value]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return "$raw_value"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        return $raw_value
    }
}

# Rule: COOP
#
# coop.fg

gofer rule NUMBER COOP {f g} {
    typemethod construct {f g} {
        return [$type validate [dict create f $f g $g]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            f [civgroup validate [string toupper $f]] \
            g [frcgroup validate [string toupper $g]]

    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return "cooperation of $f with $g"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT coop FROM uram_coop WHERE f=$f AND g=$g
        } {
            return [format %.1f $coop]
        }

        return 0.0
    }
}
