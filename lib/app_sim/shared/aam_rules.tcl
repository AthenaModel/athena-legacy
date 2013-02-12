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
    
    # civsat fdict
    #
    # fdict - Dictionary of aggregate event attributes:
    #
    #       n          - The neighborhood
    #       f          - The CIV group, resident in n
    #       casualties - The number of casualties
    #
    # Calls CIVCAS-1 to assess the satisfaction implications of the event.

    typemethod civsat {fdict} {
        log normal aamr "event CIVCAS-1 [list $fdict]"

        if {![dam isactive CIVCAS]} {
            log warning aamr "event CIVCAS-1: ruleset has been deactivated"
            return
        }
    
        dict with fdict {}
        
        aam_rules CIVCAS-1 [GetDriver $n $f] $fdict
    }


    # civcoop fdict
    #
    # fdict - Dictionary of aggregate event attributes:
    #
    #       n          - The neighborhood
    #       f          - The CIV group, resident in n
    #       g          - The force group
    #       casualties - The number of casualties
    #
    # Calls CIVCAS-2 to assess the cooperation implications of the event.

    typemethod civcoop {fdict} {
        log normal aamr "event CIVCAS-2 [list $fdict]"

        if {![dam isactive CIVCAS]} {
            log warning aamr "event CIVCAS-2: ruleset has been deactivated"
            return
        }

        dict with fdict {}
        aam_rules CIVCAS-2 [GetDriver $n $f] $fdict
    }
    
    # GetDriver n f
    #
    # n - The neighborhood
    # f - The civilian group
    #
    # Returns the driver ID, using signature "$f".
    
    proc GetDriver {n f} {
        driver create CIVCAS "Casualties to group $f in $n" $f
    }

    #-------------------------------------------------------------------
    # Rule Set: CIVCAS: Civilian Casualties
    #
    # Aggregate Event.  This rule set determines the effect of a week's
    # worth of civilian casualties on a neighborhood group.
    #
    # CIVCAS-1 assess the satisfaction effects, and CIVCAS-2 assesses
    # the cooperation effects.
    
    typemethod CIVCAS-1 {driver_id fdict} {
        dict with fdict {}

        # FIRST, compute the casualty multiplier
        set zsat [parmdb get dam.CIVCAS.Zsat]
        set mult [zcurve eval $zsat $casualties]
        dict set fdict mult $mult
            
        # NEXT, The rule fires trivially
        dam rule CIVCAS-1-1 $driver_id $fdict {1} {
            dam sat P $f \
                AUT [mag* $mult L-]  \
                SFT [mag* $mult XL-] \
                QOL [mag* $mult L-]
        }
    }

    typemethod CIVCAS-2 {driver_id fdict} {
        dict with fdict {}

        # FIRST, compute the casualty multiplier
        set zsat [parmdb get dam.CIVCAS.Zcoop]
        set cmult [zcurve eval $zsat $casualties]
        set rmult [rmf enmore [hrel.fg $f $g]]
        let mult {$cmult * $rmult}

        dict set fdict mult $cmult
        
        # NEXT, The rule fires trivially
        dam rule CIVCAS-2-1 $driver_id $fdict {1} {
            dam coop P $f $g [mag* $mult M-]
        }
    }
}






