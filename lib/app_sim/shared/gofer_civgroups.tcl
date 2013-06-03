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

gofer create gofer_civgroups {
    by_value         ::gofer_civgroups::by_value
    resident_in      ::gofer_civgroups::resident_in
    supporting_actor ::gofer_civgroups::supporting_actor
} {
    rc "" -width 3in -span 3
    label {
        Enter a rule for selecting a set of civilian groups.
    }

    rc "" -for _rule
    selector _rule {
        case by_value "By name" {
            cc "  " -for raw_value
            enumlonglist raw_value -dictcmd {::civgroup namedict} \
                -width 30 -height 10 
        }

        case resident_in "Resident in" {
            cc "  " -for nlist
            enumlonglist nlist -dictcmd {::nbhood namedict} \
                -width 30 -height 10
        }

        case supporting_actor "Supporting Actor(s)" {
            cc " " -for alist
            enumlonglist alist -dictcmd {::actor namedict} \
                -width 30 -height 10
        }
    }
}

# Rule: by_value
#
# Some set of civilian groups chosen by the user.

snit::type ::gofer_civgroups::by_value {
    # keys
    #
    # Returns the names of the rule-specific keys.

    typemethod keys {} {
        return {raw_value}
    }

    # validate gdict
    #
    # gdict   - Possibly, a civgroups_by_value gdict
    #
    # Validates the gdict and returns it in canonical form.  Only
    # keys relevant to the rule are checked or included in the result.
    # Throws INVALID if the gdict is invalid.

    typemethod validate {gdict} {
        dict with gdict {}

        dict create raw_value \
            [gofer listval "groups" {civgroup validate} $raw_value]
    }

    # narrative gdict ?-brief?
    #
    # gdict   - A valid gdict
    # -brief  - If given, constrains lists to the first few members.
    #
    # Returns a narrative string for the gdict as a phrase to be inserted
    # in a sentence, i.e., "all non-empty groups resident in $n".

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        return [gofer listnar "group" "these groups" $raw_value $opt]
    }

    # eval gdict
    #
    # gdict   - A valid gdict
    #
    # Evaluates the gdict and returns a list of civilian groups.

    typemethod eval {gdict} {
        dict with gdict {}

        return $raw_value
    }

    # construct raw_value
    #
    # raw_value   - A list of civilian groups
    #
    # Returns a valid gdict.

    typemethod construct {raw_value} {
        return [$type validate [dict create raw_value $raw_value]]
    }
}

# Rule: resident_in
#
# Non-empty civilian groups resident in some set of neighborhoods.

snit::type ::gofer_civgroups::resident_in {
    # keys
    #
    # Returns the names of the rule-specific keys.

    typemethod keys {} {
        return {nlist}
    }

    # validate gdict
    #
    # gdict   - Possibly, a resident_in gdict
    #
    # Validates the gdict and returns it in canonical form.  Only
    # keys relevant to the rule are checked or included in the result.
    # Throws INVALID if the gdict is invalid.

    typemethod validate {gdict} {
        dict with gdict {}

        dict create nlist \
            [gofer listval "neighborhoods" {nbhood validate} $nlist]
    }

    # narrative gdict ?-brief?
    #
    # gdict   - A valid gdict
    # -brief  - If given, constrains lists to the first few members.
    #
    # Returns a narrative string for the gdict as a phrase to be inserted
    # in a sentence, i.e., "all non-empty groups resident in $n".

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        set text [gofer listnar "" "these neighborhoods" $nlist $opt]

        return "non-empty civilian groups resident in $text"
    }

    # eval gdict
    #
    # gdict   - A valid gdict
    #
    # Evaluates the gdict and returns a list of civilian groups.

    typemethod eval {gdict} {
        dict with gdict {}

        set out [list]
        foreach n $nlist {
            lappend out {*}[demog gIn $n]
        }
        return $out
    }

    # construct nlist
    #
    # nlist   - A list of neighborhoods
    #
    # Returns a valid gdict.

    typemethod construct {nlist} {
        return [$type validate [dict create nlist $nlist]]
    }
}

# Rule: supporting_actor
#
# Civilian groups who contribute to the actor's support.

snit::type ::gofer_civgroups::supporting_actor {
    # keys
    #
    # Returns the names of the rule-specific keys.

    typemethod keys {} {
        return {alist}
    }

    # validate gdict
    #
    # gdict   - Possibly, a rule gdict
    #
    # Validates the gdict and returns it in canonical form.  Only
    # keys relevant to the rule are checked or included in the result.
    # Throws INVALID if the gdict is invalid.

    typemethod validate {gdict} {
        dict with gdict {}

        dict create alist \
            [gofer listval "actors" {actor validate} $alist]
    }

    # narrative gdict ?-brief?
    #
    # gdict   - A valid gdict
    # -brief  - If given, constrains lists to the first few members.
    #
    # Returns a narrative string for the gdict as a phrase to be inserted
    # in a sentence, i.e., "all non-empty groups resident in $n".

    typemethod narrative {gdict {opt ""}} {
        dict with gdict {}

        set text [gofer listnar "actor" "any of these actors" $alist $opt]

        return "civilian groups that actively support $text"
    }

    # eval gdict
    #
    # gdict   - A valid gdict
    #
    # Evaluates the gdict and returns a list of civilian groups.

    typemethod eval {gdict} {
        set alist [dict get $gdict alist]

        set groups [dict create]

        return [rdb eval "
            SELECT DISTINCT g
            FROM civgroups
            JOIN support_nga USING (g)
            WHERE a IN ('[join $alist {','}]') 
            AND support > 0
        "]
    }

    # construct alist
    #
    # alist   - A list of actors
    #
    # Returns a valid gdict.

    typemethod construct {alist} {
        return [$type validate [dict create alist $alist]]
    }
}


