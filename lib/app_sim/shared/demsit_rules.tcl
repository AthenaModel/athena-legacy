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
    
    # monitor CONSUMP
    #
    # Looks for and assesses CONSUMP situations
    
    typemethod {monitor CONSUMP} {} {
        # FIRST, skip if the rule set is inactive.
        if {![dam isactive CONSUMP]} {
            log warning demr \
                "assess: CONSUMP ruleset has been deactivated"
            return
        }
        
        # NEXT, look for and assess consumption
        rdb eval {
            SELECT G.g, G.aloc, G.eloc, G.povfrac, C.n, N.controller AS a
            FROM demog_g AS G
            JOIN civgroups AS C USING (g)
            JOIN control_n AS N USING (n)
            WHERE consumers > 0
        } row {
            # FIRST, get the data.
            unset -nocomplain row(*)
            set fdict [array get row]
            dict with fdict {}
            
            # NEXT, compute the expectations factor, rounding it to
            # one decimal place.
            set ge [parm get demog.consump.expectfGain]
            
            let expectf {$ge*min(1.0, ($aloc - $eloc)/max(1.0, $eloc))}
            
            dict set fdict expectf [format "%.1f" $expectf]
            
            # NEXT, compute the poverty factor, again rounding it to two
            # decimal places.
            set Zpovf [parm get demog.consump.Zpovf]
            set povf [zcurve eval $Zpovf $povfrac]
            
            dict set fdict povf [format "%.2f" $povf]
            
            # NEXT, get the driver
            set driver_id [driver create CONSUMP "$g CONSUMP in $n" $g]
            
            bgcatch {
                demsit_rules CONSUMP $driver_id $fdict
            }
        }
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
            SELECT n, g, nuaf AS uaf
            FROM demog_context
            WHERE population > 0
            AND nuaf > 0
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
    # Rule Set: CONSUMP:  Unemployment
    #
    # Demographic Situation: unemployment is affecting a neighborhood
    # group

    typemethod CONSUMP {driver_id fdict} {
        dict with fdict {}
        log detail demr [list CONSUMP $driver_id]

        dam rule CONSUMP-1-1 $driver_id $fdict {
            $expectf != 0.0 || $povf > 0.0
        } {
            dam sat T $g AUT [expr {[mag* $expectf S+] + [mag* $povf S-]}]
            dam sat T $g QOL [expr {[mag* $expectf M+] + [mag* $povf M-]}]
        }
        
        dam rule CONSUMP-2-1 $driver_id $fdict {
            $a ne "" && $expectf >= 0.0 && $povf > 0.0
        } {
            dam vrel T $g $a [mag* $povf S-]
        }
        
        dam rule CONSUMP-2-2 $driver_id $fdict {
            $a ne "" && $expectf < 0.0 && $povf > 0.0
        } {
            # Note: mag symbol for expectf is positive, but result will
            # be negative.
            dam vrel T $g $a [expr {[mag* $expectf L+] + [mag* $povf S-]}]
        }
    }
    
    
    #-------------------------------------------------------------------
    # Rule Set: UNEMP:  Unemployment
    #
    # Demographic Situation: unemployment is affecting a neighborhood
    # group

    typemethod UNEMP {driver_id fdict} {
        dict with fdict {}
        log detail demr [list UNEMP $driver_id]

        dam rule UNEMP-1-1 $driver_id $fdict {
            $uaf > 0.0
        } {
            dam sat T $g SFT [mag* $uaf M-]
            dam sat T $g AUT [mag* $uaf S-]
        }
    }
}

