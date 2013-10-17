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

        case MOOD "mood(g)" {
            rc
            rc "Mood of civilian group"
            rc
            enumlong g -showkeys yes -dictcmd {::civgroup namedict}
        }

        case NBMOOD "nbmood(n)" {
            rc
            rc "Mood of neighborhood"
            rc
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}
        }

        case SAT "sat(g,c)" {
            rc
            rc "Satisfaction of civilian group"
            rc
            enumlong g -showkeys yes -dictcmd {::civgroup namedict}

            rc "with concern"
            rc
            enumlong c -showkeys yes -dictcmd {::econcern deflist}
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
# coop(f,g)

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

        return "coop(\"$f\",\"$g\")"
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

# Rule: MOOD
#
# mood(g)

gofer rule NUMBER MOOD {g} {
    typemethod construct {g} {
        return [$type validate [dict create g $g]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create g [civgroup validate [string toupper $g]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return "mood(\"$g\")"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT mood FROM uram_mood WHERE g=$g
        } {
            return [format %.1f $mood]
        }

        return 0.0
    }
}

# Rule: NBMOOD
#
# nbmood(n)

gofer rule NUMBER NBMOOD {n} {
    typemethod construct {n} {
        return [$type validate [dict create n $n]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create n [nbhood validate [string toupper $n]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return "nbmood(\"$n\")"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT nbmood FROM uram_n WHERE n=$n
        } {
            return [format %.1f $nbmood]
        }

        return 0.0
    }
}


# Rule: SAT
#
# sat(g,c)

gofer rule NUMBER SAT {g c} {
    typemethod construct {g c} {
        return [$type validate [dict create g $g c $c]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            g [civgroup validate [string toupper $g]] \
            c [econcern validate [string toupper $c]]

    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return "sat(\"$g\",\"$c\")"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT sat FROM uram_sat WHERE g=$g AND c=$c
        } {
            return [format %.1f $sat]
        }

        return 0.0
    }
}

