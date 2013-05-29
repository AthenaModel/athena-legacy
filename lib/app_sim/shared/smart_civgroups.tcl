#-----------------------------------------------------------------------
# TITLE:
#    smart_civgroups.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Smart Civgroup List
#    
#    smart_civgroups: A list of civilian groups produced according to 
#    various criteria.  The value dictionary (vdict) contains these
#    keys, by rule:
#    
#    rule = by_name (list the groups explicitly)
#      glist - An explicit list of civilian group names
#    
#    rule = by_nbhood (non-empty groups living in a neighborhood)
#      n     - A neighborhood

smart_type smart_civgroups {
    rc "" -width 3in -span 3
    label {
        Enter a rule for selecting a set of civilian groups.
    }

    rc "" -for rule
    selector rule {
        case by_name "By name" {
            cc "  " -for glist
            enumlonglist glist -dictcmd {::civgroup namedict} \
                -width 30 -height 10 
        }

        case by_nbhood "Resident in" {
            cc "  " -for n
            enumlong n -showkeys yes -dictcmd {::nbhood namedict}
        }
    }
} {
    # narrative vdict ?-brief?
    #
    # vdict   - A valid vdict
    # -brief  - If given, constrains lists to the first few members.
    #
    # Returns a narrative string for the vdict as a phrase to be inserted
    # in a sentence, i.e., "all non-empty groups resident in $n".

    typemethod narrative {vdict {opt ""}} {
        if {![dict exists $vdict rule]} {
            return ""
        }

        dict with vdict {}

        switch -exact -- $rule {
            "" {
                return ""
            }

            by_name {
                return "these groups ([JoinList $glist $opt])" 
            }

            by_nbhood {
                # Non-empty civilian groups in n
                return "non-empty civilian groups resident in $n"
            }

            default {
                return "Unknown rule: \"$rule\""
            }
        }
    }

    # JoinList list opt
    #
    # list   - A list
    # opt    - -brief or ""
    #
    # Joins the elements of the list using ", ".  If -brief, only
    # the first 8 elements of the list are included, followed by "..."

    proc JoinList {list opt} {
        if {$opt eq "-brief" && [llength $list] > 8} {
            set list [lrange $list 0 7]
            lappend list ...
        }

        return [join $list ", "]
    }



    # validate vdict
    #
    # vdict   - Possibly, a smart_civgroups vdict
    #
    # Validates the vdict and returns it in canonical form.  Only
    # keys relevant to the rule are checked or included in the result.
    # Throws INVALID if the vdict is invalid.

    typemethod validate {vdict} {
        set out [dict create]

        # FIRST, get the rule and prepare to build up the canonical
        # vdict
        if {![dict exists $vdict rule]} {
            throw INVALID "No rule specified"
        }

        set rule [string tolower [dict get $vdict rule]]
        dict set out rule $rule

        switch -exact -- $rule {
            by_name {
                set glist [list]
                foreach g [dict get $vdict glist] {
                    lappend glist [civgroup validate $g]
                }

                if {[llength $glist] == 0} {
                    throw INVALID "No groups selected"
                }

                dict set out glist $glist
            }

            by_nbhood {
                dict set out n [nbhood validate [dict get $vdict n]]
            }

            default {
                throw INVALID "Unknown rule: \"$rule\""
            }
        }

        return $out
    }

    # eval vdict
    #
    # vdict   - A valid smart_civgroups vdict
    #
    # Evaluates the vdict and returns a list of civilian groups.

    typemethod eval {vdict} {
        dict with vdict {}

        require {[dict exists $vdict rule]} \
            "invalid $type value, no rule specified"

        switch -exact -- $rule {
            by_name {
                # The listed civilian groups
                return $glist
            }

            by_nbhood {
                # Non-empty civilian groups in n
                return [demog gIn $n]
            }

            default {
                error "Unknown rule: \"$rule\""
            }
        }
    }

    # by_name glist
    #
    # glist   - A list of civilian groups
    #
    # Returns a valid vdict.

    typemethod by_name {glist} {
        return [$type validate [dict create rule by_name glist $glist]]
    }

    # by_nbhood n
    #
    # n  - A neighborhood
    #
    # Returns a valid vdict.

    typemethod by_nbhood {n} {
        return [$type validate [dict create rule by_nbhood n $n]]
    }
}







