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
    # Look-up tables

    # vmags: VREL magnitudes for ENI rule set given these variables:
    #
    # Control: C, NC
    #
    #   C   - Actor is in control of group's neighborhood.
    #   NC  - Actor is not in control of group's neighborhood.
    #
    # case: R-, E-, E, E+
    #
    #   R-  - actual LOS is less than required.
    #   E-  - actual LOS is at least the required amount, but less than
    #         expected.
    #   E   - actual LOS is approximately the same as expected
    #   E+  - actual LOS is more than expected.
    #
    # Credit: N, S, M
    #
    #   N   - Actor's contribution is a Negligible fraction of total
    #   S   - Actor has contributed Some of the total
    #   M   - Actor has contributed Most of the total

    typevariable vmags -array {
        C,E+,M  XL+
        C,E+,S  XL+
        C,E+,N  XL+

        C,E,M   L+
        C,E,S   L+
        C,E,N   L+

        C,E-,M  M-
        C,E-,S  L-
        C,E-,N  XL-

        C,R-,M  L-
        C,R-,S  XL-
        C,R-,N  XXL-

        NC,E+,M XXL+
        NC,E+,S XL+
        NC,E+,N 0

        NC,E,M  XL+
        NC,E,S  L+
        NC,E,N  0

        NC,E-,M L+
        NC,E-,S M+
        NC,E-,N 0

        NC,R-,M M+
        NC,R-,S S+
        NC,R-,N 0
    }


   
    #-------------------------------------------------------------------
    # Public Typemethods

    # monitor
    #
    # Monitors the level of service provided to civilian groups.
    
    typemethod monitor {} {
        if {![parmdb get dam.ENI.active]} {
            log warning servr \
                "monitor ENI: ruleset has been deactivated"
            return
        }

        # NEXT, call the ENI rule set.
        rdb eval {
            SELECT * FROM civgroups 
            JOIN demog_g USING (g)
            JOIN service_g USING (g)
            JOIN control_n ON (civgroups.n = control_n.n)
            WHERE demog_g.population > 0
            ORDER BY g
        } gdata {
            unset -nocomplain gdata(*)

            # TBD: Can we easily get all data here?

            bgcatch {
                service_rules ENI [array get gdata]
            }
        }
    }

    #===================================================================
    # Service Situations

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
        # FIRST, get some data
        set case [GetCase $gdict]
        set cdict [GetCreditDict [dict get $gdict g]]

        dict with gdict {
            log detail servr [list ENI $g]
            
            dam ruleset ENI \
                [driver create ENI "Provision of ENI services to $g" $g]

            dam detail "Civilian Group:"      $g
            dam detail "In Neighborhood:"     $n
            dam detail "Controlled By:"       $controller
            dam detail "Service Case:"        $case
            dam detail "Expectations Factor:" [format %4.2f $expectf]
            dam detail "Needs Factor:"        [format %4.2f $needs]

            # ENI-1: Satisfaction Effects
            dam rule ENI-1-1 {
                $case eq "R-"
            } {
                # While ENI is less than required for CIV group g
                # Then for group g
                dam sat T $g \
                    AUT [expr {[mag* $expectf XXS+] + [mag* $needs XXS-]}] \
                    QOL [expr {[mag* $expectf XXS+] + [mag* $needs XXS-]}]

                # And for g with each actor a
                dict for {a credit} $cdict {
                    if {$a eq $controller} {
                        dam vrel T $g $a $vmags(C,R-,$credit) \
                            "credit=$credit, has control"
                    } else {
                        dam vrel T $g $a $vmags(NC,R-,$credit) \
                            "credit=$credit, no control"
                    }
                }
            }

            dam rule ENI-1-2 {
                $case eq "E-"
            } {
                # While ENI is less than expected for CIV group g
                # Then for group g
                dam sat T $g \
                    AUT [mag* $expectf XXS+] \
                    QOL [mag* $expectf XXS+]

                # And for g with each actor a
                dict for {a credit} $cdict {
                    if {$a eq $controller} {
                        dam vrel T $g $a $vmags(C,E-,$credit) \
                            "credit=$credit, has control"
                    } else {
                        dam vrel T $g $a $vmags(NC,E-,$credit) \
                            "credit=$credit, no control"
                    }
                }
            }

            dam rule ENI-1-3 {
                $case eq "E"
            } {
                # While ENI is as expected for CIV group g
                # Then for group g

                # Nothing

                # And for g with each actor a
                dict for {a credit} $cdict {
                    if {$a eq $controller} {
                        dam vrel T $g $a $vmags(C,E,$credit) \
                            "credit=$credit, has control"
                    } else {
                        dam vrel T $g $a $vmags(NC,E,$credit) \
                            "credit=$credit, no control"
                    }
                }
            }

            dam rule ENI-1-4 {
                $case eq "E+"
            } {
                # While ENI is better than expected for CIV group g
                # Then for group g
                dam sat T $g \
                    AUT [mag* $expectf XXS+] \
                    QOL [mag* $expectf XXS+]

                # And for g with each actor a
                dict for {a credit} $cdict {
                    if {$a eq $controller} {
                        dam vrel T $g $a $vmags(C,E+,$credit) \
                            "credit=$credit, has control"
                    } else {
                        dam vrel T $g $a $vmags(NC,E+,$credit) \
                            "credit=$credit, no control"
                    }
                }
            }
        }
    }

    # GetCase gdict
    #
    # gdict   - The civgroups/service_g group dictionary
    #
    # Returns the case symbol, E+, E, E-, R-, for the provision
    # of service to the group.
    
    proc GetCase {gdict} {
        # FIRST, get the delta parameter
        set delta [parmdb get service.ENI.delta]

        # NEXT, compute the case
        dict with gdict {
            if {$actual < $required} {
                return R-
            } elseif {abs($actual - $expected) < $delta * $expected} {
                return E
            } elseif {$actual < $expected} {
                return E-
            } else {
                return E+
            }
        }
    }

    # GetCreditDict g
    #
    # g   - The civilian group
    #
    # Gets the credit symbol by actor.
    
    proc GetCreditDict {g} {
        set cdict [dict create]

        rdb eval {
            SELECT a, credit
            FROM service_ga WHERE g=$g
        } {
            dict set cdict $a [qcredit name $credit]
        }

        return $cdict
    }
}







