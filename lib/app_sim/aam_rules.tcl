#------------------------------------------------------------------------
# TITLE:
#    aam_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Driver Assessment Model (DAM): Attrition rule sets
#
#    ::aam_rules is a singleton object implemented as a snit::type.  To
#    initialize it, call "::aam_rules init".
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# aam_rules

snit::type aam_rules {
    # Make it an ensemble
    pragma -hasinstances 0
    
    #-------------------------------------------------------------------
    # Public Typemethods

    # isactive ruleset
    #
    # ruleset    a Rule Set name
    #
    # Returns 1 if the result is active, and 0 otherwise.

    typemethod isactive {ruleset} {
        return [parmdb get dam.$ruleset.active]
    }

    # detail label value
    #
    # Adds a detail to the input details
   
    proc detail {label value} {
        dam details [format "%-21s %s\n" $label $value]
    }

    
    # civsat dict
    #
    # dict  Dictionary of aggregate event attributes:
    #
    #       n            The neighborhood
    #       f            The CIV group, resident in n
    #       casualties   The number of casualties
    #       driver       The GRAM driver ID
    #
    # Calls CIVCAS-1 to assess the satisfaction implications of the event.

    typemethod civsat {dict} {
        log normal aamr "event CIVCAS-1 [list $dict]"

        if {![aam_rules isactive CIVCAS]} {
            log warning aamr "event CIVCAS-1: ruleset has been deactivated"
            return
        }

        aam_rules CIVCAS-1 $dict
    }


    # civcoop dict
    #
    # dict  Dictionary of aggregate event attributes:
    #
    #       n            The neighborhood
    #       f            The CIV group, resident in n
    #       g            The force group
    #       casualties   The number of casualties
    #       driver       The GRAM driver ID
    #
    # Calls CIVCAS-2 to assess the cooperation implications of the event.

    typemethod civcoop {dict} {
        log normal aamr "event CIVCAS-2 [list $dict]"

        if {![aam_rules isactive CIVCAS]} {
            log warning aamr "event CIVCAS-2: ruleset has been deactivated"
            return
        }

        aam_rules CIVCAS-2 $dict
    }

    #-------------------------------------------------------------------
    # Rule Set: CIVCAS: Civilian Casualties
    #
    # Aggregate Event.  This rule set determines the effect of a week's
    # worth of civilian casualties on a neighborhood group.


    # CIVCAS-1 dict
    #
    # dict  Dictionary of input parameters
    #
    #       n            The neighborhood
    #       f            The CIV group, resident in n
    #       casualties   The number of casualties
    #       driver       The GRAM driver ID
    #
    # Assesses the satisfaction implications of the casualties

    typemethod CIVCAS-1 {dict} {
        array set data $dict

        dam ruleset CIVCAS $data(driver)                   \
            -n        $data(n)                             \
            -f        $data(f)

        # NEXT, computed the casualty multiplier
        set zsat [parmdb get dam.CIVCAS.Zsat]
        set mult [zcurve eval $zsat $data(casualties)]

        # NEXT, add the details

        detail "Casualties:" $data(casualties)
        detail "Cas. Mult.:" [format "%.2f" $mult]

        # The rule fires trivially
        dam rule CIVCAS-1-1 {1} {
            # FIRST, apply the satisfaction effects
            dam sat level AUT [mag* $mult L-]  2
            dam sat level SFT [mag* $mult XL-] 2
            dam sat level QOL [mag* $mult L-]  2
        }
    }


    # CIVCAS-2 dict
    #
    # dict  Dictionary of input parameters
    #
    #       n            The neighborhood
    #       f            The CIV group, resident in n
    #       g            The FRC group
    #       casualties   The number of casualties
    #       driver       The GRAM driver ID
    #
    # Assesses the cooperation implications of the casualties
    # in which force group g was involved.

    typemethod CIVCAS-2 {dict} {
        array set data $dict

        dam ruleset CIVCAS $data(driver)                   \
            -n        $data(n)                             \
            -f        $data(f)                             \
            -doer     $data(g)

        # NEXT, compute the multiplier
        set zsat [parmdb get dam.CIVCAS.Zcoop]
        set cmult [zcurve eval $zsat $data(casualties)]
        set rmult [rmf enmore [rel $data(f) $data(g)]]
        let mult {$cmult * $rmult}

        # NEXT, add the details

        detail "Casualties:" $data(casualties)
        detail "Cas. Mult.:" [format "%.2f" $cmult]
        detail "RMF Mult.:"  [format "%.2f" $rmult]

        # The rule fires trivially
        dam rule CIVCAS-2-1 {1} {
            # FIRST, apply the satisfaction effects
            dam coop level -- [mag* $mult M-] 2
        }
    }

    #-------------------------------------------------------------------
    # Utility Procs

    #
    # multiplier    A numeric multiplier
    # mag           A qmag value
    #
    # Returns the numeric value of mag times the multiplier.

    proc mag* {multiplier mag} {
        set result [expr {$multiplier * [qmag value $mag]}]

        if {$result == -0.0} {
            set result 0.0
        }

        return $result
    }

    # rel f g
    #
    # f    A CIV group f
    # g    A FRC or ORG group g
    #
    # Returns the relationship between the groups.

    proc rel {f g} {
        set rel [rdb eval {
            SELECT rel FROM rel_fg
            WHERE f=$f AND g=$g
        }]

        return $rel
    }
}






