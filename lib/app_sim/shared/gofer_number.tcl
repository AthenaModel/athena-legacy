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

gofer define NUMBER "" {
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

        case INFLUENCE "influence(a,n)" {
            rc
            rc "Influence of actor"
            rc
            enumlong a -showkeys yes -dictcmd {::actor namedict}

            rc "in neighborhood"
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}
        }

        case MOOD "mood(g)" {
            rc
            rc "Mood of civilian group"
            rc
            enumlong g -showkeys yes -dictcmd {::civgroup namedict}
        }

        case NBCOOP "nbcoop(n,g)" {
            rc
            rc "Cooperation of neighborhood"
            rc
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}

            rc "with force group"
            rc
            enumlong g -showkeys yes -dictcmd {::frcgroup namedict}
        }

        case NBMOOD "nbmood(n)" {
            rc
            rc "Mood of neighborhood"
            rc
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}
        }

        case PCTCONTROL "pctcontrol(a,...)" {
            rc 
            rc "Percentage of neighborhood controlled by these actors"
            rc
            enumlonglist alist -showkeys yes -dictcmd {::actor namedict} \
                -width 30 -height 10
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

        return 50.0
    }
}

# Rule: INFLUENCE
#
# influence(a,n)

gofer rule NUMBER INFLUENCE {a n} {
    typemethod construct {a n} {
        return [$type validate [dict create a $a n $n]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            a [actor validate [string toupper $a]] \
            n [nbhood validate [string toupper $n]]

    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return "influence(\"$a\",\"$n\")"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT influence FROM influence_na WHERE n=$n AND a=$a
        } {
            return [format %.2f $influence]
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

# Rule: NBCOOP
#
# nbcoop(n,g)

gofer rule NUMBER NBCOOP {n g} {
    typemethod construct {n g} {
        return [$type validate [dict create n $n g $g]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            n [nbhood validate [string toupper $n]] \
            g [frcgroup validate [string toupper $g]]

    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return "nbcoop(\"$n\",\"$g\")"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT nbcoop FROM uram_nbcoop WHERE n=$n AND g=$g
        } {
            return [format %.1f $nbcoop]
        }

        return 50.0
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

# Rule: PCTCONTROL
#
# pctcontrol(a,...)

gofer rule NUMBER PCTCONTROL {alist} {
    typemethod construct {alist} {
        return [$type validate [dict create alist $alist]]
    }

    typemethod validate {gdict} {
        dict with gdict {}
        dict create alist \
            [listval actors {actor validate} [string toupper $alist]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return "pctcontrol(\"[join $alist \",\"]\")"
    }

    typemethod eval {gdict} {
        dict with gdict {}

        # FIRST, create the inClause.
        set inClause "('[join $alist ',']')"

        # NEXT, query the number of neighborhoods controlled by
        # actors in the list.
        set count [rdb onecolumn "
            SELECT count(n) 
            FROM control_n
            WHERE controller IN $inClause
        "]

        set total [llength [nbhood names]]

        if {$total == 0.0} {
            return 0.0
        }

        return [expr {100.0*$count/$total}]
    }
}

#
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

