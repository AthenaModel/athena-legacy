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
            if {[dict get $gdict driver_id] eq ""} {
                dict with gdict {
                    set driver_id [driver create ENI \
                                       "Provision of ENI services to $g"]

                    rdb eval {
                        UPDATE service_g SET driver_id=$driver_id
                        WHERE g=$g
                    }
                }                
            }

            # Run the monitor rule set.
            service_rules ENI $gdict
        }
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

        dam ruleset ENI [dict get $gdict driver_id]

        dam detail "Civilian Group:"      $g
        dam detail "In Neighborhood:"     $n
        dam detail "Expectations Factor:" [format %4.2f $expectf]
        dam detail "Needs Factor:"        [format %4.2f $needs]

        dam rule ENI-1-1 {
            $needs > 0.0
        } {
            # While ENI is less than required for CIV group g
            # Then for group g
            dam sat T $g \
                AUT [expr {[mag* $expectf XXS+] + [mag* $needs XXS-]}] \
                QOL [expr {[mag* $expectf XXS+] + [mag* $needs XXS-]}]
        }

        dam rule ENI-1-2 {
            $needs == 0.0 && $expectf < 0.0
        } {
            # While ENI is less than expected for CIV group g
            # Then for group g
            dam sat T $g \
                AUT [mag* $expectf XXS+] \
                QOL [mag* $expectf XXS+]
        }

        # ENI-1-3 -- nothing happens in this case

        dam rule ENI-1-4 {
            $needs == 0.0 && $expectf > 0.0
        } {
            # While ENI is better than expected for CIV group g
            # Then for group g
            dam sat T $g \
                AUT [mag* $expectf XXS+] \
                QOL [mag* $expectf XXS+]
        }
    }
}







