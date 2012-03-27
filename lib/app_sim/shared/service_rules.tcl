#-----------------------------------------------------------------------
# TITLE:
#    service_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n): Athena Driver Assessment, Service Sets
#
#    ::service_rules is a singleton object implemented as a snit::type.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# service_rules

snit::type service_rules {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Public Typemethods

    # monitor gdict
    #
    # gdict    A dict of service data about a civilian group
    #
    # Monitors the level of service provided to group g.  The dict
    # contains the table columns from civgroups and service_g for one
    # group.
    
    typemethod {monitor} {gdict} {
        if {![parmdb get dam.ENI.active]} {
            log warning servr \
                "monitor ENI: ruleset has been deactivated"
            return
        }

        bgcatch {
            # If there's no driver, get one.
            if {[dict get $gdict driver] eq ""} {
                dict with gdict {
                    set driver [aram driver add                            \
                                    -dtype    ENI                          \
                                    -name     "ENI $g"                     \
                                    -oneliner "Provision of ENI services"]
                    rdb eval {
                        UPDATE service_g SET driver=$driver
                        WHERE g=$g
                    }
                }                
            }

            # Run the monitor rule set.
            service_rules ENI $gdict
        }
    }

    #-------------------------------------------------------------------
    # Rule Set Tools

    # detail label value
    #
    # Adds a detail to the input details
   
    proc detail {label value} {
        dam details [format "%-21s %s\n" $label $value]
    }


    #===================================================================
    # Service Situations
    #

    #-------------------------------------------------------------------
    # Rule Set: ENI:  Essential Non-Infrastructure Services
    #
    # Service Situation: effect of provision/non-provision of service
    # on a civilian group.

    # ENI gdict
    #
    # gdict - Array containing group service data.
    #
    # This method is called each strategy tock to assess the satisfaction
    # effects of ENI services on group g.

    typemethod ENI {gdict} {
        log detail servr [list ENI [dict get $gdict g]]

        set g        [dict get $gdict g]
        set n        [dict get $gdict n]
        set expectf  [dict get $gdict expectf]
        set needs    [dict get $gdict needs]
        set oldSig   [dict get $gdict signature]

        dam ruleset ENI [dict get $gdict driver] \
            -p  0.0                              \
            -f  $g                               \
            -n  $n

        detail "Expectations Factor:" [format %4.2f $expectf]
        detail "Needs Factor:"        [format %4.2f $needs]

        dam rule ENI-1-1 {
            $needs > 0.0
        } {
            myguard $oldSig [format "%.1f %.1f" $expectf $needs]

            # While ENI is less than required for CIV group g
            # Then for group g
            dam sat slope \
                AUT [mag* $expectf XXS+ $needs XXS-] \
                QOL [mag* $expectf XXS+ $needs XXS-]
        }

        dam rule ENI-1-2 {
            $needs == 0.0 && $expectf < 0.0
        } {
            myguard $oldSig [format "%.1f" $expectf]

            # While ENI is less than expected for CIV group g
            # Then for group g
            dam sat slope \
                AUT [mag* $expectf XXS+] \
                QOL [mag* $expectf XXS+]
        }

        dam rule ENI-1-3 {
            $needs == 0.0 && $expectf == 0.0
        } {
            myguard $oldSig [format "%.1f" $expectf]

            # While ENI is as expected for CIV group g
            # Then for group g
            dam sat clear AUT QOL
        }

        dam rule ENI-1-4 {
            $needs == 0.0 && $expectf > 0.0
        } {
            myguard $oldSig [format "%.1f" $expectf]

            # While ENI is better than expected for CIV group g
            # Then for group g
            dam sat slope \
                AUT [mag* $expectf XXS+] \
                QOL [mag* $expectf XXS+]
        }
    }

    #-------------------------------------------------------------------
    # Utility Procs

    # myguard oldSig newSig
    #
    # oldSig - The old signature string
    # newSig - The new signature string (less the rule name)
    #
    # Compares the current signature with the previous rule and
    # signature; if they match, the rule breaks.

    proc myguard {oldSig newSig} {
        # FIRST, get the group and rule from the metadata
        set rule [dam get rule]
        set g    [dam rget -f]

        # NEXT, add the rule to the new signature
        set newSig "$rule $newSig"

        # NEXT, if the signatures match, break; the rule shouldn't fire.
        if {$oldSig eq $newSig} {
            return -code break
        }

        # NEXT, save the new signature
        rdb eval {
            UPDATE service_g SET signature=$newSig
            WHERE g=$g
        }
    }
    
    
    # mag* multiplier mag ?multiplier mag...?
    #
    # multiplier    A numeric multiplier
    # mag           A qmag value
    #
    # Returns the numeric value of the sum of mag times multiplier.

    proc mag* {args} {
        set result 0.0
        
        foreach {multiplier mag} $args {
            let result {$result + $multiplier * [qmag value $mag]}
        }

        if {$result == -0.0} {
            set result 0.0
        }

        return $result
    }

}







