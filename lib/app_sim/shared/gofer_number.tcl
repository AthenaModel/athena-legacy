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

        case AFFINITY "affinity(x,y)" {
            rc
            rc "Affinity of group or actor"
            rc
            enumlong x -showkeys yes -dictcmd {::ptype goa namedict}

            rc "with group or actor"
            rc
            enumlong y -showkeys yes -dictcmd {::ptype goa namedict}
        }

        case ASSIGNED "assigned(g,activity,n)" {
            rc
            rc "Number of personnel of force or org group "
            rc
            enumlong g -showkeys yes -dictcmd {::ptype fog namedict}


            rc "assigned to do activity"
            rc
            enum activity -listcmd {::activity asched names $g}

            rc "in neighborhood"
            rc
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}
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

        case COVERAGE "coverage(g,activity,n)" {
            rc
            rc "Coverage fraction for force or org group"
            rc
            enumlong g -showkeys yes -dictcmd {::ptype fog namedict}

            rc "assigned to activity"
            rc
            enum activity -listcmd {::activity withcov names [group gtype $g]}

            rc "in neighborhood"
            rc
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}
        }

        case GDP "gdp()" {
            rc
            rc "The value of the Gross Domestic Product of the regional economy \
                in base-year dollars."
            rc
       }

        case HREL "hrel(f,g)" {
            rc
            rc "The horizontal relationship of group"
            rc
            enumlong f -showkeys yes -dictcmd {::group namedict}

            rc "with group"
            rc
            enumlong g -showkeys yes -dictcmd {::group namedict}
        }

        case INFLUENCE "influence(a,n)" {
            rc
            rc "Influence of actor"
            rc
            enumlong a -showkeys yes -dictcmd {::actor namedict}

            rc "in neighborhood"
            rc
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

        case NBSUPPORT "nbsupport(a,n)" {
            rc
            rc "Support of actor"
            rc
            enumlong a -showkeys yes -dictcmd {::actor namedict}
            
            rc "in neighborhood"
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

        case SECURITY_CIV "security(g)" {
            rc
            rc "Security of civilian group"
            rc
            enumlong g -showkeys yes -dictcmd {::civgroup namedict}         
        }

        case SECURITY "security(g,n)" {
            rc
            rc "Security of group"
            rc
            enumlong g -showkeys yes -dictcmd {::group namedict}

            rc "in neighborhood"
            rc
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}            
        }

        case SUPPORT_CIV "support(a,g)" {
            rc
            rc "Support for actor"
            rc
            enumlong a -showkeys yes -dictcmd {::actor namedict}
            
            rc "by group"
            rc
            enumlong g -showkeys yes -dictcmd {::civgroup namedict}
        }

        case SUPPORT "support(a,g,n)" {
            rc
            rc "Support for actor"
            rc
            enumlong a -showkeys yes -dictcmd {::actor namedict}
            
            rc "by group"
            rc
            enumlong g -showkeys yes -dictcmd {::group namedict}
            
            rc "in neighborhood"
            rc
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}    
        }

        case VREL "vrel(g,a)" {
            rc
            rc "The vertical relationship of group"
            rc
            enumlong g -showkeys yes -dictcmd {::group namedict}

            rc "with actor"
            rc
            enumlong a -showkeys yes -dictcmd {::actor namedict}
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

# Rule: AFFINITY
#
# affinity(x,y)

gofer rule NUMBER AFFINITY {x y} {
    typemethod construct {x y} {
        return [$type validate [dict create x $x y $y]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            x [ptype goa validate [string toupper $x]] \
            y [ptype goa validate [string toupper $y]]

    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {affinity("%s","%s")} $x $y]
    }

    typemethod eval {gdict} {
        dict with gdict {}
        
        if {$x in [group names]} {
            set x [rdb eval {
                SELECT rel_entity FROM groups WHERE g=$x
            }]
        }
        if {$y in [group names]} {
            set y [rdb eval {
                SELECT rel_entity FROM groups WHERE g=$y
            }]
        } {

        }
        rdb eval {
            SELECT affinity FROM mam_affinity WHERE f=$x AND g=$y
        } {
            return [format %.2f $affinity]
        }

        return  0.00
    }
}

# Rule: ASSIGNED
#
# assigned(g,activity,n)

gofer rule NUMBER ASSIGNED {g activity n} {
    typemethod construct {g activity n} {
        return [$type validate [dict create g $g activity $activity n $n]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        set valid [dict create]

        dict set valid g [ptype fog validate [string toupper $g]]

        dict set valid activity [string toupper $activity]

        if {$activity eq ""} {
            return -code error -errorcode INVALID \
                "Invalid activity \"\"."
        } else {
            activity check [string toupper $g] [string toupper $activity]
        }

        dict set valid n [nbhood validate [string toupper $n]]

        return $valid
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {assigned("%s","%s","%s")} $g $activity $n]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT total(personnel) AS assigned FROM units WHERE n=$n AND g=$g AND a=$activity
        } {
            return [format %.0f $assigned]
        }

        return 0
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

        return [format {coop("%s","%s")} $f $g]
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

# Rule: COVERAGE
#
# coverage(g,activity,n)

gofer rule NUMBER COVERAGE {g activity n} {
    typemethod construct {g activity n} {
        return [$type validate [dict create g $g activity $activity n $n]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        set valid [dict create]

        dict set valid g [ptype fog validate [string toupper $g]]
        dict set valid activity [string toupper $activity]

        set gtype [group gtype $g]
        if {$gtype eq "FRC"} {
            activity withcov frc validate [string toupper $activity]
        } elseif {$gtype eq "ORG"} {
            activity withcov org validate [string toupper $activity]
        }

        dict set valid n [nbhood validate [string toupper $n]]

        return $valid
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {coverage("%s","%s","%s")} $g $activity $n]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT coverage FROM activity_nga WHERE n=$n AND g=$g AND a=$activity
        } {
            return [format %.1f $coverage]
        }

        return 0.0
    }
}

# Rule: GDP
#
# gdp()

gofer rule NUMBER GDP {} {
    typemethod construct {} {
        return [$type validate [dict create]]
    }

    typemethod validate {gdict} {
        dict create
    }

    typemethod narrative {gdict {opt ""}} {
        return "gdp()"
    }

    typemethod eval {gdict} {
        if {[parm get econ.disable]} {
            return 0.00
        } else {
            return [format %.2f [econ value Out::DGDP]]
        }
    }
}

# Rule: HREL
#
# hrel(f,g)

gofer rule NUMBER HREL {f g} {
    typemethod construct {f g} {
        return [$type validate [dict create f $f g $g]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            f [group validate [string toupper $f]] \
            g [group validate [string toupper $g]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {hrel("%s","%s")} $f $g]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT hrel FROM uram_hrel WHERE f=$f AND g=$g AND tracked
        } {
            return [format %.1f $hrel]
        }

        return 0.0
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

        return [format {influence("%s","%s")} $a $n]
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

        return [format {mood("%s")} $g]
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

        return [format {nbcoop("%s","%s")} $n $g]
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

        return [format {nbmood("%s")} $n]
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

# Rule: NBSUPPORT
#
# nbsupport(a,n)

gofer rule NUMBER NBSUPPORT {a n} {
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

        return [format {nbsupport("%s","%s")} $a $n]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT support FROM influence_na WHERE n=$n AND a=$a
        } {
            return [format %.2f $support]
        }

        return 0.00
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

        return [format {pctcontrol("%s")} [join $alist \",\"]]
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

        return [format {sat("%s","%s")} $g $c]
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

#
# Rule: SECURITY_CIV
#
# security(g)

gofer rule NUMBER SECURITY_CIV {g} {
    typemethod construct {g} {
        return [$type validate [dict create g $g]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            g [civgroup validate [string toupper $g]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {security("%s")} $g]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        set n [rdb eval {
            SELECT n FROM civgroups WHERE g=$g
        }]
        rdb eval {
            SELECT security FROM force_ng WHERE n=$n AND g=$g
        } {
            return $security
        }

        return 0
    }
}
#
# Rule: SECURITY
#
# security(g,n)

gofer rule NUMBER SECURITY {g n} {
    typemethod construct {g n} {
        return [$type validate [dict create g $g n $n]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            g [group validate [string toupper $g]] \
            n [nbhood validate [string toupper $n]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {security("%s","%s")} $g $n]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT security FROM force_ng WHERE n=$n AND g=$g
        } {
            return $security
        }

        return 0
    }
}

# Rule: SUPPORT_CIV
#
# support(a,g)

gofer rule NUMBER SUPPORT_CIV {a g} {
    typemethod construct {a g} {
        return [$type validate [dict create a $a g $g]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            a [actor validate [string toupper $a]] \
            g [civgroup validate [string toupper $g]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {support("%s","%s")} $a $g]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT support FROM support_nga WHERE g=$g AND a=$a
        } {
            return [format %.2f $support]
        }

        return 0.00
    }
}

# Rule: SUPPORT
#
# support(a,g,n)

gofer rule NUMBER SUPPORT {a g n} {
    typemethod construct {a g n} {
        return [$type validate [dict create a $a g $g n $n]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            a [actor validate [string toupper $a]] \
            g [group validate [string toupper $g]] \
            n [nbhood validate [string toupper $n]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {support("%s","%s","%s")} $a $g $n]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT support FROM support_nga WHERE n=$n AND g=$g AND a=$a
        } {
            return [format %.2f $support]
        }

        return 0.00
    }
}

# Rule: VREL
#
# vrel(g,a)

gofer rule NUMBER VREL {g a} {
    typemethod construct {g a} {
        return [$type validate [dict create g $g a $a]]
    }

    typemethod validate {gdict} {
        dict with gdict {}

        dict create \
            g [group validate [string toupper $g]] \
            a [actor validate [string toupper $a]]
    }

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [format {vrel("%s","%s")} $g $a]
    }

    typemethod eval {gdict} {
        dict with gdict {}

        rdb eval {
            SELECT vrel FROM uram_vrel WHERE g=$g AND a=$a AND tracked
        } {
            return [format %.1f $vrel]
        }

        return 0.0
    }
}