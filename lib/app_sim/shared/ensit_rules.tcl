#-----------------------------------------------------------------------
# TITLE:
#    ensit_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(n) DAM (Athena Driver_Id Assessment) Module, 
#    Environmental Situation Rule Sets
#
#    ::ensit_rules is a singleton object implemented as a snit::type.  To
#    initialize it, call "::ensit_rules init".
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# ensit_rules

snit::type ensit_rules {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Lookup Tables

    # Ensit Rule Subsets
    #
    # Identifies the inception ("begin"), monitoring ("monitor") and
    # termination ("resolve") subsets for each ensit rule set.
    #
    #  <ruleset>.setup         Command to call prior to invoking any subset
    #  <ruleset>.monitor       List of subset names to call while the
    #                          ensit is on-going.
    #  <ruleset>.resolution    List of subset names to call when the
    #                          ensit is resolved.
    #
    # Note: This structure is really absurdly complicated for what 
    # we're doing.  Ah, history.


    typevariable subsets -array {
        BADFOOD.monitor         BADFOOD-1
        BADFOOD.resolution      BADFOOD-2

        BADWATER.monitor        BADWATER-1
        BADWATER.resolution     BADWATER-2

        COMMOUT.monitor         COMMOUT-1
        COMMOUT.resolution      {}

        CULSITE.monitor         CULSITE-1
        CULSITE.resolution      {}

        DISASTER.monitor        DISASTER-1
        DISASTER.resolution     DISASTER-2

        DISEASE.monitor         DISEASE-1
        DISEASE.resolution      DISEASE-2

        EPIDEMIC.monitor        EPIDEMIC-1
        EPIDEMIC.resolution     EPIDEMIC-2

        FOODSHRT.monitor        FOODSHRT-1
        FOODSHRT.resolution     FOODSHRT-2

        FUELSHRT.monitor        FUELSHRT-1
        FUELSHRT.resolution     FUELSHRT-2

        GARBAGE.monitor         GARBAGE-1
        GARBAGE.resolution      GARBAGE-2

        INDSPILL.monitor        INDSPILL-1
        INDSPILL.resolution     INDSPILL-2

        MINEFIELD.monitor       MINEFIELD-1
        MINEFIELD.resolution    MINEFIELD-2

        NOWATER.monitor         NOWATER-1
        NOWATER.resolution      NOWATER-2

        ORDNANCE.monitor        ORDNANCE-1
        ORDNANCE.resolution     ORDNANCE-2

        PIPELINE.monitor        PIPELINE-1
        PIPELINE.resolution     PIPELINE-2

        POWEROUT.monitor        POWEROUT-1
        POWEROUT.resolution     POWEROUT-2

        REFINERY.monitor        REFINERY-1
        REFINERY.resolution     REFINERY-2

        RELSITE.monitor         RELSITE-1
        RELSITE.resolution      RELSITE-2

        SEWAGE.monitor          SEWAGE-1
        SEWAGE.resolution       SEWAGE-2
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # monitor sit
    #
    # sit     Ensit object
    #
    # An ensit is on-going; run its monitor rule set(s).
    
    typemethod monitor {sit} {
        set ruleset [$sit get stype]

        if {![dam isactive $ruleset]} {
            log warning envr \
                "ensit monitor $ruleset: ruleset has been deactivated"
            return
        }

        set n [$sit get n]

        if {[demog getn $n population] == 0} {
            log normal envr \
                "ensit monitor $ruleset: skipping, nbhood $n is empty."
            return
        }

        bgcatch {
            # Set up the rule set
            set driver_id [$sit get driver_id]
            set fdict [dict create]
            dict set fdict s [$sit get s]
            dict set fdict n $n
            dict set fdict inception [$sit get inception]
            dict set fdict coverage [$sit get coverage]

            # Run the monitor rule sets.
            foreach subset $subsets($ruleset.monitor) {
                ensit_rules $subset $driver_id $fdict
            }
        }
    }

    # resolution sit
    #
    # sit     Ensit object
    #
    # An ensit has been resolved.  Run its resolution rule set(s).

    typemethod resolution {sit} {
        set ruleset [$sit get stype]

        if {![dam isactive $ruleset]} {
            log warning envr \
                "ensit resolution $ruleset: ruleset has been deactivated"
            return
        }

        bgcatch {
            # Set up the rule set
            set driver_id [$sit get rdriver_id]
            set fdict [dict create]
            dict set fdict s [$sit get s]
            dict set fdict n [$sit get n]
            dict set fdict coverage [$sit get coverage]
            dict set fdict resolver [$sit get resolver]

            # Run the resolve rule sets.
            foreach subset $subsets($ruleset.resolution) {
                ensit_rules $subset $driver_id $fdict
            }
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: BADFOOD: Contaminated Food Supply
    #
    # Environmental Situation: The local food supply has been contaminated.


    typemethod BADFOOD-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list BADFOOD-1 $s]

        set flist [demog gIn $n]

        dam rule BADFOOD-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XXXS- \
                QOL XXL-
        }

        dam rule BADFOOD-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XXXS- \
                QOL L-
        }
    }

    typemethod BADFOOD-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list BADFOOD-2 $s]

        set flist [demog gIn $n]

        dam rule BADFOOD-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: BADWATER: Contaminated Water Supply
    #
    # Environmental Situation: The local water supply has been contaminated.
 
    # monitor
    typemethod BADWATER-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list BADWATER-1 $s]

        set flist [demog gIn $n]

        dam rule BADWATER-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XXXS- \
                QOL XXL-
        }

        dam rule BADWATER-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XXXS- \
                QOL L-
        }
    }

    # resolve
    typemethod BADWATER-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list BADWATER-2 $s]

        set flist [demog gIn $n]

        dam rule BADWATER-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: COMMOUT: Communications Outage
    #
    # Environmental Situation: Communications are out in the neighborhood.
 
    # monitor
    typemethod COMMOUT-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list COMMOUT-1 $s]

        set flist [demog gIn $n]

        dam rule COMMOUT-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                SFT L-    \
                CUL M-    \
                QOL XXL-
        }

        dam rule COMMOUT-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                SFT S-    \
                CUL S-    \
                QOL XL-
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: CULSITE: Damage to Cultural Site/Artifact
    #
    # Environmental Situation: A cultural site or artifact is
    # damaged, presumably due to kinetic action.
 
    # monitor
    typemethod CULSITE-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list CULSITE-1 $s]

        set flist [demog gIn $n]

        dam rule CULSITE-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                CUL XXXXL- \
                QOL XXXS-
        }

        dam rule CULSITE-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                CUL XL-
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: DISASTER: Disaster
    #
    # Environmental Situation: Disaster

    # monitor
    typemethod DISASTER-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list DISASTER-1 $s]

        set flist [demog gIn $n]

        dam rule DISASTER-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                SFT XXL-   \
                QOL XXXXL-
        }

        dam rule DISASTER-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                SFT L-    \
                QOL XXL-
        }
    }

    # resolve
    typemethod DISASTER-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list DISASTER-2 $s]

        set flist [demog gIn $n]

        dam rule DISASTER-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: DISEASE: Disease
    #
    # Environmental Situation: General disease due to unhealthy conditions.
 
    # monitor
    typemethod DISEASE-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list DISEASE-1 $s]

        set flist [demog gIn $n]

        dam rule DISEASE-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT L-    \
                SFT XXL-  \
                QOL XXXL-
        }

        dam rule DISEASE-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT S-    \
                SFT L-    \
                QOL XL-
        }
    }

    # resolve
    typemethod DISEASE-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list DISEASE-2 $s]

        set flist [demog gIn $n]

        dam rule DISEASE-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT L+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: EPIDEMIC: Epidemic
    #
    # Environmental Situation: Epidemic disease
 
    # monitor
    typemethod EPIDEMIC-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list EPIDEMIC-1 $s]

        set flist [demog gIn $n]

        dam rule EPIDEMIC-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT XXL-   \
                SFT XL-    \
                QOL XXXXL-
        }

        dam rule EPIDEMIC-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT L-    \
                SFT L-    \
                QOL XXL-
        }
    }

    # resolve
    typemethod EPIDEMIC-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list EPIDEMIC-2 $s]

        set flist [demog gIn $n]

        dam rule EPIDEMIC-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT M+
        }
    }



    #-------------------------------------------------------------------
    # Rule Set: FOODSHRT: Food Shortage
    #
    # Environmental Situation: There is a food shortage in the neighborhood.
 
    # monitor
    typemethod FOODSHRT-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list FOODSHRT-1 $s]

        set flist [demog gIn $n]

        dam rule FOODSHRT-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT M-  \
                QOL XL-
        }

        dam rule FOODSHRT-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-  \
                QOL L-
        }
    }

    # resolve
    typemethod FOODSHRT-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list FOODSHRT-2 $s]

        set flist [demog gIn $n]

        dam rule FOODSHRT-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT L+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: FUELSHRT: Fuel Shortage
    #
    # Environmental Situation: There is a fuel shortage in the neighborhood.
 
    # monitor
    typemethod FUELSHRT-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list FUELSHRT-1 $s]

        set flist [demog gIn $n]

        dam rule FUELSHRT-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT M-           \
                QOL XXXL-
        }

        dam rule FUELSHRT-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-  \
                QOL XL-
        }
    }

    # resolve
    typemethod FUELSHRT-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list FUELSHRT-2 $s]

        set flist [demog gIn $n]

        dam rule FUELSHRT-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: GARBAGE: Garbage in the Streets
    #
    # Environmental Situation: Garbage is piling up in the streets.
 
    # monitor
    typemethod GARBAGE-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list GARBAGE-1 $s]

        set flist [demog gIn $n]

        dam rule GARBAGE-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT L-   \
                SFT XL-  \
                QOL XL-
        }

        dam rule GARBAGE-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-   \
                SFT M-   \
                QOL L-
        }
    }

    # resolve
    typemethod GARBAGE-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list GARBAGE-2 $s]

        set flist [demog gIn $n]

        dam rule GARBAGE-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }



    #-------------------------------------------------------------------
    # Rule Set: INDSPILL: Industrial Spill
    #
    # Environmental Situation: Damage to an industrial facility has released
    # possibly toxic substances into the surrounding area.
 
    # monitor
    typemethod INDSPILL-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list INDSPILL-1 $s]

        set flist [demog gIn $n]

        dam rule INDSPILL-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT M-   \
                SFT XL-  \
                QOL XXL-
        }

        dam rule INDSPILL-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-   \
                SFT S-   \
                QOL L-
        }
    }

    # resolve
    typemethod INDSPILL-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list INDSPILL-2 $s]

        set flist [demog gIn $n]

        dam rule INDSPILL-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT M+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: MINEFIELD: Minefield
    #
    # Environmental Situation: The residents of this neighborhood know that
    # there is a minefield in the neighborhood.
 
    # monitor
    typemethod MINEFIELD-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list MINEFIELD-1 $s]

        set flist [demog gIn $n]

        dam rule MINEFIELD-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT XXL-    \
                SFT XXXXL-  \
                QOL XXXXL-
        }

        dam rule MINEFIELD-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT L-    \
                SFT XXL-  \
                QOL XXL-
        }
    }

    # resolve
    typemethod MINEFIELD-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list MINEFIELD-2 $s]

        set flist [demog gIn $n]

        dam rule MINEFIELD-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT XXL+
        }
    }



    #-------------------------------------------------------------------
    # Rule Set: NOWATER: No Water Supply
    #
    # Environmental Situation: The local water supply is non-functional;
    # no water is available.
 
    # monitor
    typemethod NOWATER-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list NOWATER-1 $s]

        set flist [demog gIn $n]

        dam rule NOWATER-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT XXL-    \
                QOL XXXXL-
        }

        dam rule NOWATER-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT L-     \
                QOL XXXL-
        }
    }

    # resolve
    typemethod NOWATER-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list NOWATER-2 $s]

        set flist [demog gIn $n]

        dam rule NOWATER-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT M+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: ORDNANCE: Unexploded Ordnance
    #
    # Environmental Situation: The residents of this neighborhood know that
    # there is unexploded ordnance (probably from cluster munitions)
    # in the neighborhood.
 
    # monitor
    typemethod ORDNANCE-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list ORDNANCE-1 $s]

        set flist [demog gIn $n]

        dam rule ORDNANCE-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT XL-    \
                SFT XXXXL- \
                QOL XXXL-
        }

        dam rule ORDNANCE-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT L-   \
                SFT XXL- \
                QOL XXL-
        }
    }

    # resolve
    typemethod ORDNANCE-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list ORDNANCE-2 $s]

        set flist [demog gIn $n]

        dam rule ORDNANCE-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }



    #-------------------------------------------------------------------
    # Rule Set: PIPELINE: Oil Pipeline Fire
    #
    # Environmental Situation: Damage to an oil pipeline has caused to catch
    # fire.
 
    # monitor
    typemethod PIPELINE-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list PIPELINE-1 $s]

        set flist [demog gIn $n]

        dam rule PIPELINE-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT L-     \
                SFT S-     \
                QOL XXXXL-
        }

        dam rule PIPELINE-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-     \
                SFT XXS-   \
                QOL XXL-
        }
    }

    # resolve
    typemethod PIPELINE-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list PIPELINE-2 $s]

        set flist [demog gIn $n]

        dam rule PIPELINE-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }



    #-------------------------------------------------------------------
    # Rule Set: POWEROUT: Power Outage
    #
    # Environmental Situation: Electrical power is off in the local area.
 
    # monitor
    typemethod POWEROUT-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list POWEROUT-1 $s]

        set flist [demog gIn $n]

        dam rule POWEROUT-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT L-   \
                SFT M-   \
                QOL XXL-
        }

        dam rule POWEROUT-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-   \
                SFT S-   \
                QOL L-
        }
    }

    # resolve
    typemethod POWEROUT-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list POWEROUT-2 $s]


        dam rule POWEROUT-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT L+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: REFINERY: Oil Refinery Fire
    #
    # Environmental Situation: Damage to an oil refinery has caused it to
    # catch fire.
 
    # monitor
    typemethod REFINERY-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list REFINERY-1 $s]

        set flist [demog gIn $n]

        dam rule REFINERY-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT XXL-   \
                SFT L-     \
                QOL XXXXL-
        }

        dam rule REFINERY-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT L-   \
                SFT M-   \
                QOL XXL-
        }
    }

    # resolve
    typemethod REFINERY-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list REFINERY-2 $s]

        set flist [demog gIn $n]

        dam rule REFINERY-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT XL+
        }
    }



    #-------------------------------------------------------------------
    # Rule Set: RELSITE: Damage to Religious Site/Artifact
    #
    # Environmental Situation: A religious site or artifact is
    # damaged, presumably due to kinetic action.
 
    # monitor
    typemethod RELSITE-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list RELSITE-1 $s]

        set flist [demog gIn $n]

        dam rule RELSITE-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XL-   \
                CUL XXXL- \
                QOL L-
        }

        dam rule RELSITE-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT S-   \
                SFT S-   \
                CUL XL-  \
                QOL XS-
        }
    }

    # resolve
    typemethod RELSITE-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list RELSITE-2 $s]

        set flist [demog gIn $n]

        dam rule RELSITE-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT M+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: SEWAGE: Sewage Spill
    #
    # Environmental Situation: Sewage is pooling in the streets.
 
    # monitor
    typemethod SEWAGE-1 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list SEWAGE-1 $s]

        set flist [demog gIn $n]

        dam rule SEWAGE-1-1 $driver_id $fdict {
            $inception
        } {
            satinput $flist $coverage \
                AUT L-    \
                QOL XXXL-
        }

        dam rule SEWAGE-1-2 $driver_id $fdict {
            !$inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                QOL XL-
        }
    }

    # resolve
    typemethod SEWAGE-2 {driver_id fdict} {
        dict with fdict {}
        log detail envr [list SEWAGE-2 $s]

        set flist [demog gIn $n]

        dam rule SEWAGE-2-1 $driver_id $fdict {
            [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }


    #-------------------------------------------------------------------
    # Helper Routines

    # resolverIsLocal g
    #
    # g    A group
    #
    # Returns 1 if g is known and local, and 0 otherwise.
    proc resolverIsLocal {g} {
        expr {$g ne "" && [group isLocal $g]}
    }

    # satinput flist cov con mag ?con mag...?
    #
    # flist - The groups affected
    # cov   - The coverage fraction
    # con   - The affected concern
    # mag   - The nominal magnitude
    #
    # Enters satisfaction inputs for flist and cov.

    proc satinput {flist cov args} {
        assert {[llength $args] != 0 && [llength $args] % 2 == 0}

        set nomCov [parmdb get dam.ensit.nominalCoverage]
        let mult   {$cov/$nomCov}

        set result [list]
        foreach {con mag} $args {
            lappend result $con [mag* $mult $mag]
        }

        dam sat T $flist {*}$result
    }
}
