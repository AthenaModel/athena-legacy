#-----------------------------------------------------------------------
# TITLE:
#    demsit_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n): Athena Driver Assessment, Demographic Situation Rule Sets
#
#    ::demsit_rules is a singleton object implemented as a snit::type.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# demsit_rules

snit::type demsit_rules {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Public Typemethods

    # assess
    #
    # Assesses any existing demographic situations, which it finds for
    # itself.
    
    typemethod assess {} {
        # FIRST, all existing demsits depend on the outputs of the
        # Economic model.  If the Economic model is disabled, don't
        # bother running them.
        if {[parm get econ.disable]} {
            log warning demr \
                "assess: demsits disabled because economic model is disabled"
            return
        }
         
        $type monitor UNEMP
    }
    
    # monitor UNEMP
    #
    # Looks for and assesses UNEMP situations.
    
    typemethod {monitor UNEMP} {} {
        # FIRST, skip if the rule set is inactive.
        if {![dam isactive UNEMP]} {
            log warning demr \
                "assess: UNEMP ruleset has been deactivated"
            return
        }
        
        # NEXT, look for and assess unemployment
        rdb eval {
            SELECT n, g, ngfactor, nfactor
            FROM demog_context
            WHERE population > 0
            AND (ngfactor > 0.0 OR nfactor > 0.0)
        } row {
            unset -nocomplain row(*)
            set fdict [array get row]
            dict with fdict {}
            
            set driver_id [driver create UNEMP "$g UNEMP in $n" $g]
            
            bgcatch {
                demsit_rules UNEMP $driver_id $fdict
            }
        }
    }
    
    #===================================================================
    # Demographic Situations

    #-------------------------------------------------------------------
    # Rule Set: UNEMP:  Unemployment
    #
    # Demographic Situation: unemployment is affecting a neighborhood
    # group

    typemethod UNEMP {driver_id fdict} {
        dict with fdict {}
        log detail demr [list UNEMP $driver_id]

        dam rule UNEMP-1-1 $driver_id $fdict {
            $ngfactor > 0.0 || $nfactor > 0.0
        } {
            # While there is an UNEMP situation affecting group g
            #     with ngfactor > 0.0
            # Then for CIV group g in the nbhood,
            if {$ngfactor > 0.0} {
                dam sat T $g QOL [mag* $ngfactor L-]
            }

            # While there is an UNEMP situation affecting group g
            #     with nfactor > 0.0
            # Then for CIV group g in the nbhood,
            if {$nfactor > 0.0} {
                dam sat T $g SFT [mag* $nfactor M-]
                dam sat T $g AUT [mag* $nfactor S-]
            }
        }
    }
}







