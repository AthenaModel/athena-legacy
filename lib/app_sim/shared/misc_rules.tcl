#-----------------------------------------------------------------------
# TITLE:
#    misc_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n): Driver Assessment Model, Miscellaneous Rule Sets
#
#    ::misc_rules is a singleton object implemented as a snit::type.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# misc_rules

snit::type misc_rules {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Public Typemethods

    # assess
    #
    # Executes all rule sets against the current state of the 
    # simulation.

    typemethod assess {} {
        $type monitor MOOD
    }

    # monitor MOOD 
    #
    # Monitors the mood of each civilian group relative to the last
    # control shift in the group's neighborhood; triggers the MOOD
    # rule set, if the mode has changed sufficiently.  Assigns
    # a driver if needed.
    
    typemethod {monitor MOOD} {} {
        # FIRST, if the rule set is inactive, skip it.
        if {![parmdb get dam.MOOD.active]} {
            log warning miscr \
                "monitor MOOD: ruleset has been deactivated"
            return
        }

        # NEXT, get a driver ID.  Use signature "MOOD", so that we
        # always get the same one.
        set driver_id [driver create MOOD "Group mood changes" MOOD]

        # NEXT, look for groups for which the rule set should fire.

        set threshold [parm get dam.MOOD.threshold]

        rdb eval {
            SELECT G.g                AS g,
                   G.n                AS n,
                   UM.mood            AS moodNow,
                   HM.mood            AS moodThen,
                   UM.mood - HM.mood  AS delta,
                   C.controller       AS controller,
                   C.since            AS tc
            FROM civgroups AS G
            JOIN demog_g   AS D USING (g)
            JOIN control_n AS C  ON (C.n = G.n)
            JOIN uram_mood AS UM ON (G.g = UM.g)
            JOIN hist_mood AS HM ON (HM.g = G.g AND HM.t = C.since)
            WHERE D.population > 0
            AND abs(UM.mood - HM.mood) >= CAST ($threshold AS REAL)
        } row {
            unset -nocomplain row(*)
            
            log normal miscr [array get row]
            bgcatch {
                # Run the rule set.
                misc_rules MOOD $driver_id [array get row]
            }
        }
        
    }

    #-------------------------------------------------------------------
    # Rule Set: MOOD -- significant changes in mood

    # MOOD driver_id fdict
    #
    # fdict - Dictionary containing group mood data:
    #
    #    g          - The civilian group
    #    n          - The group's neighborhood
    #    controller - Actor in control of n
    #    moodNow    - The group's mood right now
    #    moodThen   - The group's mood at time tc
    #    delta      - The difference between the two
    #    tc         - When control of n last shifted
    #
    # This method is called each tick to assess changes in vertical
    # relationships due to group mood.

    typemethod MOOD {driver_id fdict} {
        dict with fdict {}
        log detail miscr [list MOOD $g]

        # We already know that delta exceeds the threshold; all
        # we care about now is the sign.

        dam rule MOOD-1-1 $driver_id $fdict {
            $delta < 0.0
        } {
            foreach a [actor names] {
                if {$a eq $controller} {
                    dam vrel T $g $a [mag/ $delta S-] "has control"
                } else {
                    dam vrel T $g $a [mag/ $delta L+] "no control"
                }
            }
        }

        dam rule MOOD-1-2 $driver_id $fdict {
            $delta > 0.0
        } {
            foreach a [actor names] {
                if {$a eq $controller} {
                    dam vrel T $g $a [mag/ $delta S+] "has control"
                } else {
                    dam vrel T $g $a [mag/ $delta L-] "no control"
                }
            }
        }
    }

    #-------------------------------------------------------------------
    # Utility methods

    # mag/ factor mag
    #
    # factor   - A numeric value
    # mag      - A magnitude symbol
    #
    # Divides |factor| by the value of the magnitude symbol.
    # We use the absolute value so that the magnitude symbol controls
    # the sign.

    proc mag/ {factor mag} {
        expr {abs($factor) / [qmag value $mag]}
    }


}








