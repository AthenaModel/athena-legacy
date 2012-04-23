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
    
    # civsat dict
    #
    # dict  Dictionary of aggregate event attributes:
    #
    #       n            The neighborhood
    #       f            The CIV group, resident in n
    #       casualties   The number of casualties
    #       driver_id    The URAM driver ID
    #
    # Calls CIVCAS-1 to assess the satisfaction implications of the event.

    typemethod civsat {dict} {
        log normal aamr "event CIVCAS-1 [list $dict]"

        if {![dam isactive CIVCAS]} {
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
    #       driver_id    The URAM driver ID
    #
    # Calls CIVCAS-2 to assess the cooperation implications of the event.

    typemethod civcoop {dict} {
        log normal aamr "event CIVCAS-2 [list $dict]"

        if {![dam isactive CIVCAS]} {
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
    #       driver_id    The URAM driver ID
    #
    # Assesses the satisfaction implications of the casualties

    typemethod CIVCAS-1 {dict} {
        dict with dict {
            dam ruleset CIVCAS $driver_id

            # NEXT, computed the casualty multiplier
            set zsat [parmdb get dam.CIVCAS.Zsat]
            set mult [zcurve eval $zsat $casualties]

            # NEXT, add the details
            dam detail "Neighborhood:" $n
            dam detail "Civ. Group:"   $f
            dam detail "Casualties:"   $casualties
            dam detail "Cas. Mult.:"   [format "%.2f" $mult]

            # The rule fires trivially
            dam rule CIVCAS-1-1 {1} {
                # FIRST, apply the satisfaction effects
                dam sat P $f \
                    AUT [mag* $mult L-]  \
                    SFT [mag* $mult XL-] \
                    QOL [mag* $mult L-]
            }
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
    #       driver_id    The URAM driver ID
    #
    # Assesses the cooperation implications of the casualties
    # in which force group g was involved.

    typemethod CIVCAS-2 {dict} {
        dict with dict {
            dam ruleset CIVCAS $driver_id

            # NEXT, compute the multiplier
            set zsat [parmdb get dam.CIVCAS.Zcoop]
            set cmult [zcurve eval $zsat $casualties]
            set rmult [rmf enmore [hrel.fg $f $g]]
            let mult {$cmult * $rmult}

            # NEXT, add the details
            dam detail "Neighborhood:" $n
            dam detail "Civ. Group:"   $f
            dam detail "Frc. Group:"   $g
            dam detail "Casualties:"   $casualties
            dam detail "Cas. Mult.:"   [format "%.2f" $cmult]
            dam detail "RMF Mult.:"    [format "%.2f" $rmult]

            # The rule fires trivially
            dam rule CIVCAS-2-1 {1} {
                # FIRST, apply the cooperation effects
                dam coop P $f $g [mag* $mult M-]
            }
        }
    }
}






