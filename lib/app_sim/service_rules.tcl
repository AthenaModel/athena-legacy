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

        # Handle signature explicitly, since [dam guard] requires a
        # full fledges situation.
        set signature [format "%.1f %.1f" $expectf $needs]

        if {$signature eq [dict get $gdict signature]} {
            return
        }

        # Save the signature; we know the rule is going to fire.
        rdb eval {
            UPDATE service_g SET signature=$signature
            WHERE g=$g
        }

        dam ruleset ENI [dict get $gdict driver] \
            -f  $g                               \
            -n  $n

        detail "Expectations Factor:" [format %4.2f $expectf]
        detail "Needs Factor:"        [format %4.2f $needs]

        dam rule ENI-1-1 {
            true
        } {
            # While ENI is affecting group g
            # Then for CIV group g
            dam sat slope \
                AUT [mag* $expectf M+ $needs M+] \
                SFT [mag* $expectf M+ $needs M+] \
                CUL [mag* $expectf M+ $needs M+] \
                QOL [mag* $expectf M+ $needs M+]
        }
    }

    #-------------------------------------------------------------------
    # Utility Procs
    
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







