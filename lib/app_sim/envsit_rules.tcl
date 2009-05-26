#-----------------------------------------------------------------------
# TITLE:
#    envsit_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(n) ADA (Athena Driver Assessment) Module, 
#    Environmental Situation Rule Sets
#
#    ::envsit_rules is a singleton object implemented as a snit::type.  To
#    initialize it, call "::envsit_rules init".
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# envsit_rules

snit::type envsit_rules {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Type Constructor
    
    typeconstructor {
        # Import needed commands

        namespace import ::marsutil::* 
        namespace import ::marsutil::* ::projectlib::* 
    }

    #-------------------------------------------------------------------
    # Lookup Tables

    # Envsit Rule Subsets
    #
    # Identifies the inception ("begin"), monitoring ("monitor") and
    # termination ("resolve") subsets for each envsit rule set.
    #
    #  <ruleset>.setup         Command to call prior to invoking any subset
    #  <ruleset>.begin         List of subset names to call when the envsit
    #                          begins
    #  <ruleset>.monitor       List of subset names to call when the envsit's
    #                          state changes (except on full resolution).
    #  <ruleset>.resolution       List of subset names to call when the
    #                          envsit is fully or partially resolved.


    typevariable subsets -array {
        BADFOOD.setup           setup
        BADFOOD.inception       BADFOOD-1
        BADFOOD.monitor         BADFOOD-2
        BADFOOD.resolution      BADFOOD-3

        BADWATER.setup          setup
        BADWATER.inception      BADWATER-1
        BADWATER.monitor        BADWATER-2
        BADWATER.resolution     BADWATER-3

        BIO.setup               setup
        BIO.inception           BIO-1
        BIO.monitor             BIO-2
        BIO.resolution          BIO-3

        CHEM.setup              setup
        CHEM.inception          CHEM-1
        CHEM.monitor            CHEM-2
        CHEM.resolution         CHEM-3

        COMMOUT.setup           setup
        COMMOUT.inception       COMMOUT-1
        COMMOUT.monitor         COMMOUT-2
        COMMOUT.resolution      COMMOUT-3

        DISASTER.setup          setup
        DISASTER.inception      DISASTER-1
        DISASTER.monitor        DISASTER-2
        DISASTER.resolution     DISASTER-3

        DISEASE.setup           setup
        DISEASE.inception       DISEASE-1
        DISEASE.monitor         DISEASE-2
        DISEASE.resolution      DISEASE-3

        EPIDEMIC.setup          setup
        EPIDEMIC.inception      EPIDEMIC-1
        EPIDEMIC.monitor        EPIDEMIC-2
        EPIDEMIC.resolution     EPIDEMIC-3

        FOODSHRT.setup          setup
        FOODSHRT.inception      {}
        FOODSHRT.monitor        FOODSHRT-1
        FOODSHRT.resolution     FOODSHRT-2

        FUELSHRT.setup          setup
        FUELSHRT.inception      FUELSHRT-1
        FUELSHRT.monitor        FUELSHRT-2
        FUELSHRT.resolution     FUELSHRT-3

        GARBAGE.setup           setup
        GARBAGE.inception       GARBAGE-1
        GARBAGE.monitor         GARBAGE-2
        GARBAGE.resolution      GARBAGE-3

        INDSPILL.setup          setup
        INDSPILL.inception      INDSPILL-1
        INDSPILL.monitor        INDSPILL-2
        INDSPILL.resolution     INDSPILL-3

        MOSQUE.setup            setup
        MOSQUE.inception        MOSQUE-1
        MOSQUE.monitor          MOSQUE-2
        MOSQUE.resolution       MOSQUE-3

        NOWATER.setup           setup
        NOWATER.inception       NOWATER-1
        NOWATER.monitor         NOWATER-2
        NOWATER.resolution      NOWATER-3

        ORDNANCE.setup          setup
        ORDNANCE.inception      ORDNANCE-1
        ORDNANCE.monitor        ORDNANCE-2
        ORDNANCE.resolution     ORDNANCE-3

        PIPELINE.setup          setup
        PIPELINE.inception      PIPELINE-1
        PIPELINE.monitor        PIPELINE-2
        PIPELINE.resolution     PIPELINE-3

        POWEROUT.setup          setup
        POWEROUT.inception      POWEROUT-1
        POWEROUT.monitor        POWEROUT-2
        POWEROUT.resolution     POWEROUT-3

        REFINERY.setup          setup
        REFINERY.inception      REFINERY-1
        REFINERY.monitor        REFINERY-2
        REFINERY.resolution     REFINERY-3

        SEWAGE.setup            setup
        SEWAGE.inception        SEWAGE-1
        SEWAGE.monitor          SEWAGE-2
        SEWAGE.resolution       SEWAGE-3
    }

    #-------------------------------------------------------------------
    # Initialization method

    typemethod init {} {
        # FIRST, check requirements
        require {[info commands log]  ne ""} "log is not defined."

        # NEXT, ADA Rules is up.
        log normal envr "Initialized"
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # isactive ruleset
    #
    # ruleset    a Rule Set name
    #
    # Returns 1 if the result is active, and 0 otherwise.

    typemethod isactive {ruleset} {
        return [parmdb get ada.$ruleset.active]
    }

    # setup calltype sit
    #
    # calltype  inception|monitor|resolution
    # sit       Envsit object
    #
    # Ruleset setup.  This is the default setup; specific rule sets
    # can override it.

    typemethod setup {calltype sit} {
        set ruleset  [$sit get stype]
        set n        [$sit get n]
        set location [$sit get location]

        if {$calltype ne "resolution"} {
            set driver [$sit get driver]
            set g      [$sit get g]
        } else {
            set driver [$sit get rdriver]
            set g      [$sit get resolver]
        }

        ada ruleset $ruleset $driver    \
            -sit       $sit             \
            -doer      $g               \
            -location  $location        \
            -n         $n               \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent [$sit get coverage]]]
    }

    # inception sit
    #
    # sit     Envsit object
    # 
    # An envsit has begun.  Run the "inception" rule set for
    # the envsit.

    typemethod inception {sit} {
        set ruleset [$sit get stype]

        if {![envsit_rules isactive $ruleset]} {
            log warning envr \
                "envsit inception $ruleset: ruleset has been deactivated"
            return
        }

        bgcatch {
            # Set up the rule set
            envsit_rules $subsets($ruleset.setup) inception $sit

            # Run the inception rule sets.
            foreach subset $subsets($ruleset.inception) {
                envsit_rules $subset $sit
            }
        }
    }

    # monitor sit
    #
    # sit     Envsit object
    #
    # An envsit is on-going; run its monitor rule set(s).
    
    typemethod monitor {sit} {
        set ruleset [$sit get stype]

        if {![envsit_rules isactive $ruleset]} {
            log warning envr \
                "envsit monitor $ruleset: ruleset has been deactivated"
            return
        }

        bgcatch {
            # Set up the rule set
            envsit_rules $subsets($ruleset.setup) monitor $sit

            # Run the monitor rule sets.
            foreach subset $subsets($ruleset.monitor) {
                envsit_rules $subset $sit
            }
        }
    }

    # resolution sit
    #
    # sit     Envsit object
    #
    # An envsit has been resolved.  Run its resolution rule set(s).

    typemethod resolution {sit} {
        set ruleset [$sit get stype]

        if {![envsit_rules isactive $ruleset]} {
            log warning envr \
                "envsit resolution $ruleset: ruleset has been deactivated"
            return
        }

        bgcatch {
            # Set up the rule set
            envsit_rules $subsets($ruleset.setup) resolution $sit

            # Run the resolve rule sets.
            foreach subset $subsets($ruleset.resolution) {
                envsit_rules $subset $sit
            }
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: BADFOOD: Contaminated Food Supply
    #
    # Environmental Situation: The local food supply has been contaminated.


    # BADFOOD-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod BADFOOD-1 {sit} {
        log detail envr [list BADFOOD-1 [$sit get s]]

        # BADFOOD-1-1:
        #
        # If there is a new BADFOOD situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADFOOD-1-1 {
            1
        } {
            satlevel $sit   \
                AUT L-   2  \
                QOL XXL- 2
        }
    }

    # BADFOOD-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod BADFOOD-2 {sit} {
        # BADFOOD-2-1:
        #
        # While there is a BADFOOD situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADFOOD-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit \
                AUT L-    \
                QOL XXL- 
        }

        # BADFOOD-2-2:
        #
        # When there is no longer a BADFOOD situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADFOOD-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada guard

            ada sat clear AUT QOL
        }
    }

    # BADFOOD-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod BADFOOD-3 {sit} {
        log detail envr [list BADFOOD-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # BADFOOD-3-1:
        #
        # If there is a BADFOOD situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADFOOD-3-1 {
            !$gIsLocal
        } {
            satlevel $sit    \
                AUT XL+   2  \
                QOL XXXL+ 2
        }

        # BADFOOD-3-2:
        #
        # If there is a BADFOOD situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADFOOD-3-2 {
            $gIsLocal
        } {
            satlevel $sit    \
                AUT XXXL+ 2  \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: BADWATER: Contaminated Water Supply
    #
    # Environmental Situation: The local water supply has been contaminated.
 
    # BADWATER-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod BADWATER-1 {sit} {
        log detail envr [list BADWATER-1 [$sit get s]]

        # BADWATER-1-1:
        #
        # If there is a new BADWATER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-1-1 {
            1
        } {
            satlevel $sit \
                AUT L-    2   \
                QOL XXXL- 2
        }
    }

    # BADWATER-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod BADWATER-2 {sit} {
        # BADWATER-2-1:
        #
        # While there is a BADWATER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT L-     \
                QOL XXL-
        }

        # BADWATER-2-2:
        #
        # When there is no longer a BADWATER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada guard

            ada sat clear AUT QOL
        }
    }

    # BADWATER-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod BADWATER-3 {sit} {
        log detail envr [list BADWATER-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # BADWATER-3-1:
        #
        # If there is a BADWATER situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT XL+   2 \
                QOL XXXL+ 2
        }

        # BADWATER-3-2:
        #
        # If there is a BADWATER situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-3-2 {
            $gIsLocal
        } {
            satlevel $sit \
                AUT XXXL+ 2   \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: BIO: Biological Hazard
    #
    # Environmental Situation: Active Biological agents
 
    # BIO-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod BIO-1 {sit} {
        log detail envr [list BIO-1 [$sit get s]]

        # BIO-1-1:
        #
        # If there is a new BIO situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-1-1 {
            1
        } {
            satlevel $sit     \
                SFT XXXL-  2  \
                QOL XXL-   2
        }
    }

    # BIO-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod BIO-2 {sit} {
        # BIO-2-1:
        #
        # While there is a BIO situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT L-     \
                SFT XXXL-  \
                QOL XXL-
        }

        # BIO-2-2:
        #
        # When there is no longer a BIO situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # BIO-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod BIO-3 {sit} {
        log detail envr [list BIO-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # BIO-3-1:
        #
        # If there is a BIO situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-3-1 {
            !$gIsLocal
        } {
            satlevel $sit  \
                AUT XL+  2 \
                SFT XL+  2 \
                QOL L+   2
        }

        # BIO-3-2:
        #
        # If there is a BIO situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXXL+ 2 \
                SFT XL+   2 \
                QOL L+    2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CHEM: Chemical Hazard
    #
    # Environmental Situation: Active Chemical agents
 
    # CHEM-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod CHEM-1 {sit} {
        log detail envr [list CHEM-1 [$sit get s]]

        # CHEM-1-1:
        #
        # If there is a new CHEM situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-1-1 {
            1
        } {
            satlevel $sit     \
                SFT XXXL-  2  \
                QOL XXL-   2
        }
    }

    # CHEM-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod CHEM-2 {sit} {
        # CHEM-2-1:
        #
        # While there is a CHEM situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT L-     \
                SFT XXXL-  \
                QOL XXL-
        }

        # CHEM-2-2:
        #
        # While there is a CHEM situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # CHEM-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod CHEM-3 {sit} {
        log detail envr [list CHEM-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # CHEM-3-1:
        #
        # If there is a CHEM situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT XL+   2 \
                SFT XL+   2 \
                QOL L+    2
        }

        # CHEM-3-2:
        #
        # If there is a CHEM situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXXL+ 2 \
                SFT XL+   2 \
                QOL L+    2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: COMMOUT: Communications Outage
    #
    # Environmental Situation: Communications are out in the neighborhood.
 
    # COMMOUT-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod COMMOUT-1 {sit} {
        log detail envr [list COMMOUT-1 [$sit get s]]

        # COMMOUT-1-1:
        #
        # If there is a new COMMOUT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-1-1 {
            1
        } {
            satlevel $sit   \
                AUT M-   2  \
                SFT S-   2  \
                QOL XL-  2
        }
    }

    # COMMOUT-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod COMMOUT-2 {sit} {
        # COMMOUT-2-1:
        #
        # While there is a COMMOUT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT M-     \
                SFT S-     \
                QOL L-
        }

        # COMMOUT-2-2:
        #
        # When there is no longer a COMMOUT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # COMMOUT-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod COMMOUT-3 {sit} {
        log detail envr [list COMMOUT-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # COMMOUT-3-1:
        #
        # If there is a COMMOUT situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT L+   2  \
                SFT XL+  2  \
                QOL XXL+ 2
        }

        # COMMOUT-3-2:
        #
        # If there is a COMMOUT situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXL+ 2  \
                SFT XL+  2  \
                QOL XXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: DISASTER: Disaster
    #
    # Environmental Situation: Disaster
 
    # DISASTER-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod DISASTER-1 {sit} {
        log detail envr [list DISASTER-1 [$sit get s]]

        # DISASTER-1-1:
        #
        # If there is a new DISASTER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-1-1 {
            1
        } {
            satlevel $sit     \
                SFT L-     2  \
                QOL XXL-   2
        }
    }

    # DISASTER-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod DISASTER-2 {sit} {
        # DISASTER-2-1:
        #
        # While there is a DISASTER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT L-     \
                SFT L-     \
                QOL XXL-
        }

        # DISASTER-2-2:
        #
        # When there is no longer a DISASTER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # DISASTER-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod DISASTER-3 {sit} {
        log detail envr [list DISASTER-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # DISASTER-3-1:
        #
        # If there is a DISASTER situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT L+    2 \
                SFT XL+   2 \
                QOL L+    2
        }

        # DISASTER-3-2:
        #
        # If there is a DISASTER situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XL+   2 \
                SFT XL+   2 \
                QOL L+    2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: DISEASE: Disease
    #
    # Environmental Situation: General disease due to unhealthy conditions.
 
    # DISEASE-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod DISEASE-1 {sit} {
        log detail envr [list DISEASE-1 [$sit get s]]

        # DISEASE-1-1:
        #
        # If there is a new DISEASE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-1-1 {
            1
        } {
            satlevel $sit  \
                AUT S-   2 \
                SFT L-   2 \
                QOL XL-  2
        }
    }

    # DISEASE-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod DISEASE-2 {sit} {
        # DISEASE-2-1:
        #
        # While there is a DISEASE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT S-     \
                SFT L-     \
                QOL XL-
        }

        # DISEASE-2-2:
        #
        # When there is no longer a DISEASE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # DISEASE-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod DISEASE-3 {sit} {
        log detail envr [list DISEASE-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # DISEASE-3-1:
        #
        # If there is a DISEASE situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT XL+   2 \
                SFT XXXL+ 2 \
                QOL XXXL+ 2
        }

        # DISEASE-3-2:
        #
        # If there is a DISEASE situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXXL+ 2 \
                SFT XXXL+ 2 \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: EPIDEMIC: Epidemic
    #
    # Environmental Situation: Epidemic disease
 
    # EPIDEMIC-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod EPIDEMIC-1 {sit} {
        log detail envr [list EPIDEMIC-1 [$sit get s]]

        # EPIDEMIC-1-1:
        #
        # If there is a new EPIDEMIC situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-1-1 {
            1
        } {
            satlevel $sit     \
                AUT L-    2   \
                SFT L-    2   \
                QOL XXXL- 2
        }
    }

    # EPIDEMIC-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod EPIDEMIC-2 {sit} {
        # EPIDEMIC-2-1:
        #
        # While there is a EPIDEMIC situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT L-     \
                SFT L-     \
                QOL XL-
        }

        # EPIDEMIC-2-2:
        #
        # When there is no longer an EPIDEMIC situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # EPIDEMIC-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod EPIDEMIC-3 {sit} {
        log detail envr [list EPIDEMIC-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # EPIDEMIC-3-1:
        #
        # If there is an EPIDEMIC situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT XXL+  2 \
                SFT XXXL+ 2 \
                QOL XXXL+ 2
        }

        # EPIDEMIC-3-2:
        #
        # If there is an EPIDEMIC situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXXL+ 2 \
                SFT XXXL+ 2 \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: FOODSHRT: Food Shortage
    #
    # Environmental Situation: There is a food shortage in the neighborhood.
 
    # FOODSHRT-1 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod FOODSHRT-1 {sit} {
        # FOODSHRT-1-1:
        #
        # While there is a FOODSHRT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FOODSHRT-1-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit \
                AUT M-    \
                QOL XL-
        }

        # FOODSHRT-1-2:
        #
        # When there is no longer a FOODSHRT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FOODSHRT-1-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT QOL
        }
    }

    # FOODSHRT-2 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod FOODSHRT-2 {sit} {
        log detail envr [list FOODSHRT-2 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # FOODSHRT-2-1:
        #
        # If there is a FOODSHRT situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FOODSHRT-2-1 {
            !$gIsLocal
        } {
            satlevel $sit  \
                AUT L+  2  \
                QOL XL+ 2
        }

        # FOODSHRT-2-2:
        #
        # If there is a FOODSHRT situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FOODSHRT-2-2 {
            $gIsLocal
        } {
            satlevel $sit \
                AUT XXL+ 2    \
                QOL XL+  2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: FUELSHRT: Fuel Shortage
    #
    # Environmental Situation: There is a fuel shortage in the neighborhood.
 
    # FUELSHRT-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod FUELSHRT-1 {sit} {
        log detail envr [list FUELSHRT-1 [$sit get s]]

        # FUELSHRT-1-1:
        #
        # If there is a new FUELSHRT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-1-1 {
            1
        } {
            satlevel $sit \
                AUT M- 2  \
                SFT S- 2  \
                QOL L- 2
        }
    }

    # FUELSHRT-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod FUELSHRT-2 {sit} {
        # FUELSHRT-2-1:
        #
        # While there is a FUELSHRT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT M-     \
                SFT S-     \
                QOL XL-
        }

        # FUELSHRT-2-2:
        #
        # When there is no longer a FUELSHRT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # FUELSHRT-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod FUELSHRT-3 {sit} {
        log detail envr [list FUELSHRT-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # FUELSHRT-3-1:
        #
        # If there is a FUELSHRT situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-3-1 {
            !$gIsLocal
        } {
            satlevel $sit  \
                AUT L+   2 \
                SFT XL+  2 \
                QOL XXL+ 2
        }

        # FUELSHRT-3-2:
        #
        # If there is a FUELSHRT situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-3-2 {
            $gIsLocal
        } {
            satlevel $sit  \
                AUT XXL+ 2 \
                SFT XL+  2 \
                QOL XXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: GARBAGE: Garbage in the Streets
    #
    # Environmental Situation: Garbage is piling up in the streets.
 
    # GARBAGE-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod GARBAGE-1 {sit} {
        log detail envr [list GARBAGE-1 [$sit get s]]

        # GARBAGE-1-1:
        #
        # If there is a new GARBAGE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-1-1  {
            1
        } {
            satlevel $sit  \
                AUT S- 2   \
                SFT S- 2   \
                QOL S- 2
        }
    }

    # GARBAGE-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod GARBAGE-2 {sit} {
        # GARBAGE-2-1:
        #
        # While there is a GARBAGE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT XS-    \
                SFT M-     \
                QOL S-
        }

        # GARBAGE-2-2:
        #
        # When there is no longer a GARBAGE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-2-2  {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # GARBAGE-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod GARBAGE-3 {sit} {
        log detail envr [list GARBAGE-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # GARBAGE-3-1:
        #
        # If there is a GARBAGE situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-3-1 {
            !$gIsLocal
        } {
            satlevel $sit  \
                AUT L+   2 \
                SFT XL+  2 \
                QOL XL+  2
        }

        # GARBAGE-3-2:
        #
        # If there is a GARBAGE situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-3-2 {
            $gIsLocal
        } {
            satlevel $sit  \
                AUT XXL+ 2 \
                SFT XL+  2 \
                QOL XL+  2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: INDSPILL: Industrial Spill
    #
    # Environmental Situation: Damage to an industrial facility has released
    # possibly toxic substances into the surrounding area.
 
    # INDSPILL-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod INDSPILL-1 {sit} {
        log detail envr [list INDSPILL-1 [$sit get s]]

        # INDSPILL-1-1:
        #
        # If there is a new INDSPILL situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-1-1 {
            1
        } {
            satlevel $sit  \
                AUT S-  2  \
                SFT M-  2  \
                QOL XL- 2
        }
    }

    # INDSPILL-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod INDSPILL-2 {sit} {
        # INDSPILL-2-1:
        #
        # While there is a INDSPILL situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT S-     \
                SFT M-     \
                QOL L-
        }

        # INDSPILL-2-2:
        #
        # When there is no longer a INDSPILL situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # INDSPILL-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod INDSPILL-3 {sit} {
        log detail envr [list INDSPILL-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # INDSPILL-3-1:
        #
        # If there is an INDSPILL situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT XL+   2 \
                SFT XXL+  2 \
                QOL XXXL+ 2
        }

        # INDSPILL-3-2:
        #
        # If there is an INDSPILL situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXXL+ 2 \
                SFT XXL+  2 \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: MOSQUE: Damage to Mosque
    #
    # Environmental Situation: A mosque (or other religious site) is
    # damaged, presumably due to kinetic action.
 
    # MOSQUE-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod MOSQUE-1 {sit} {
        log detail envr [list MOSQUE-1 [$sit get s]]

        # MOSQUE-1-1:
        #
        # If there is a new MOSQUE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-1-1 {
            1
        } {
            satlevel $sit   \
                AUT S-    2 \
                SFT M-    2 \
                CUL XXL-  2 \
                QOL S-    2
        }

    }

    # MOSQUE-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod MOSQUE-2 {sit} {
        # MOSQUE-2-1:
        #
        # While there is a MOSQUE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT S-     \
                SFT M-     \
                CUL XL-    \
                QOL S-
        }

        # MOSQUE-2-2:
        #
        # When there is no longer a MOSQUE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT CUL QOL
        }
    }

    # MOSQUE-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod MOSQUE-3 {sit} {
        log detail envr [list MOSQUE-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # MOSQUE-3-1:
        #
        # If there is a MOSQUE situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT L+    2 \
                SFT XL+   2 \
                CUL XXXL+ 2 \
                QOL XL+   2
        }

        # MOSQUE-3-2:
        #
        # If there is a MOSQUE situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXL+  2 \
                SFT XL+   2 \
                CUL XXXL+ 2 \
                QOL XL+   2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: NOWATER: No Water Supply
    #
    # Environmental Situation: The local water supply is non-functional;
    # no water is available.
 
    # NOWATER-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod NOWATER-1 {sit} {
        log detail envr [list NOWATER-1 [$sit get s]]

        # NOWATER-1-1:
        #
        # If there is a new NOWATER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-1-1 {
            1
        } {
            satlevel $sit   \
                AUT XL-  2  \
                QOL XXL- 2
        }
    }

    # NOWATER-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod NOWATER-2 {sit} {
        # NOWATER-2-1:
        #
        # While there is a NOWATER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit \
                AUT XL-   \
                QOL XL-
        }

        # NOWATER-2-2:
        #
        # When there is no longer a NOWATER situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT QOL
        }
    }

    # NOWATER-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod NOWATER-3 {sit} {
        log detail envr [list NOWATER-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # NOWATER-3-1:
        #
        # If there is a NOWATER situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT XL+   2 \
                QOL XXXL+ 2
        }

        # NOWATER-3-2:
        #
        # If there is a NOWATER situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXXL+ 2 \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORDNANCE: Unexploded Ordnance
    #
    # Environmental Situation: The residents of this neighborhood know that
    # there is unexploded ordnance in the neighborhood.
 
    # ORDNANCE-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod ORDNANCE-1 {sit} {
        log detail envr [list ORDNANCE-1 [$sit get s]]

        # ORDNANCE-1-1:
        #
        # If there is a new ORDNANCE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-1-1 {
            1
        } {
            satlevel $sit   \
                AUT L-    2 \
                SFT XXL-  2 \
                QOL XXXL- 2
        }
    }

    # ORDNANCE-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod ORDNANCE-2 {sit} {
        # ORDNANCE-2-1:
        #
        # While there is an ORDNANCE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit \
                AUT L-    \
                SFT XXL-  \
                QOL XXL-
        }

        # ORDNANCE-2-2:
        #
        # When there is no longer an ORDNANCE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # ORDNANCE-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod ORDNANCE-3 {sit} {
        log detail envr [list ORDNANCE-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # ORDNANCE-3-1:
        #
        # If there is an ORDNANCE situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT M+    2 \
                SFT XXXL+ 2 \
                QOL XXXL+ 2
        }

        # ORDNANCE-3-2:
        #
        # If there is an ORDNANCE situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXXL+ 2 \
                SFT XXXL+ 2 \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: PIPELINE: Oil Pipeline Fire
    #
    # Environmental Situation: Damage to an oil pipeline has caused to catch
    # fire.
 
    # PIPELINE-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod PIPELINE-1 {sit} {
        log detail envr [list PIPELINE-1 [$sit get s]]

        # PIPELINE-1-1:
        #
        # If there is a new PIPELINE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-1-1 {
            1
        } {
            satlevel $sit \
                AUT S-  2 \
                SFT S-  2 \
                QOL XL- 2
        }
    }

    # PIPELINE-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod PIPELINE-2 {sit} {
        # PIPELINE-2-1:
        #
        # While there is a PIPELINE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit \
                AUT S-    \
                SFT S-    \
                QOL L-
        }

        # PIPELINE-2-2:
        #
        # When there is no longer a PIPELINE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # PIPELINE-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod PIPELINE-3 {sit} {
        log detail envr [list PIPELINE-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # PIPELINE-3-1:
        #
        # If there is a PIPELINE situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT L+    2 \
                SFT XXL+  2 \
                QOL XXXL+ 2
        }

        # PIPELINE-3-2:
        #
        # If there is a PIPELINE situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXL+  2 \
                SFT XXL+  2 \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: POWEROUT: Power Outage
    #
    # Environmental Situation: Electrical power is off in the local area.
 
    # POWEROUT-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod POWEROUT-1 {sit} {
        log detail envr [list POWEROUT-1 [$sit get s]]

        # POWEROUT-1-1:
        #
        # If there is a new POWEROUT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-1-1 {
            1
        } {
            satlevel $sit \
                AUT S-  2 \
                SFT S-  2 \
                QOL L-  2
        }
    }

    # POWEROUT-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod POWEROUT-2 {sit} {
        # POWEROUT-2-1:
        #
        # While there is a POWEROUT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT S-     \
                SFT S-     \
                QOL L-
        }

        # POWEROUT-2-2:
        #
        # When there is no longer a POWEROUT situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # POWEROUT-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod POWEROUT-3 {sit} {
        log detail envr [list POWEROUT-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # POWEROUT-3-1:
        #
        # If there is a POWEROUT situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT L+    2 \
                SFT XL+   2 \
                QOL XL+   2
        }

        # POWEROUT-3-2:
        #
        # If there is a POWEROUT situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXL+  2 \
                SFT XL+   2 \
                QOL XL+   2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: REFINERY: Oil Refinery Fire
    #
    # Environmental Situation: Damage to an oil refinery has caused it to
    # catch fire.
 
    # REFINERY-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod REFINERY-1 {sit} {
        log detail envr [list REFINERY-1 [$sit get s]]

        # REFINERY-1-1:
        #
        # If there is a new REFINERY situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-1-1 {
            1
        } {
            satlevel $sit   \
                AUT S-   2  \
                SFT S-   2  \
                QOL XL-  2
        }
    }

    # REFINERY-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod REFINERY-2 {sit} {
        # REFINERY-2-1:
        #
        # While there is a REFINERY situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit  \
                AUT S-     \
                SFT S-     \
                QOL L-
        }

        # REFINERY-2-2:
        #
        # When there is no longer a REFINERY situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # REFINERY-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod REFINERY-3 {sit} {
        log detail envr [list REFINERY-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # REFINERY-3-1:
        #
        # If there is a REFINERY situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT XL+   2 \
                SFT XL+   2 \
                QOL XXL+  2
        }

        # REFINERY-3-2:
        #
        # If there is a REFINERY situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-3-2 {
            $gIsLocal
        } {
            satlevel $sit    \
                AUT XXXL+  2 \
                SFT XL+    2 \
                QOL XXL+   2
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: SEWAGE: Sewage Spill
    #
    # Environmental Situation: Sewage is pooling in the streets.
 
    # SEWAGE-1 sit
    #
    # sit     Envsit object
    #
    # Situation inception rules; level effects only.

    typemethod SEWAGE-1 {sit} {
        log detail envr [list SEWAGE-1 [$sit get s]]

        # SEWAGE-1-1:
        #
        # If there is a new SEWAGE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-1-1 {
            1
        } {
            satlevel $sit \
                AUT S-  2 \
                QOL XL- 2
        }
    }

    # SEWAGE-2 sit
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod SEWAGE-2 {sit} {
        # SEWAGE-2-1:
        #
        # While there is a SEWAGE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-2-1 {
            [$sit get state] ne "ENDED"
        } {
            ada guard

            satslope $sit \
                AUT XS-   \
                QOL L-
        }

        # SEWAGE-2-2:
        #
        # When there is no longer a SEWAGE situation
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-2-2 {
            [$sit get state] eq "ENDED"
        } {
            ada sat clear AUT QOL
        }
    }

    # SEWAGE-3 sit
    #
    # sit         Envsit object 
    #
    # Situation resolution

    typemethod SEWAGE-3 {sit} {
        log detail envr [list SEWAGE-3 [$sit get s]]

        # FIRST, make the data available
        set g        [$sit get resolver]
        set gIsLocal [resolverIsLocal $g]

        # SEWAGE-3-1:
        #
        # If there is a SEWAGE situation
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-3-1 {
            !$gIsLocal
        } {
            satlevel $sit   \
                AUT XL+   2 \
                QOL XXXL+ 2
        }

        # SEWAGE-3-2:
        #
        # If there is a SEWAGE situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-3-2 {
            $gIsLocal
        } {
            satlevel $sit   \
                AUT XXXL+ 2 \
                QOL XXXL+ 2
        }
    }

    #-------------------------------------------------------------------
    # Helper Routines

    # detail label value
    #
    # Adds a detail to the input details
   
    proc detail {label value} {
        ada details [format "%-21s %s\n" $label $value]
    }

    # resolverIsLocal g
    #
    # g    A group
    #
    # Returns 1 if g is known and local, and 0 otherwise.
    proc resolverIsLocal {g} {
        expr {$g ne "" && [group isLocal $g]}
    }

    # satlevel con limit days ?con limit days...?
    #
    # sit        The situation
    # con        The affected concern
    # limit      The nominal magnitude
    # days       The realization time in days
    #
    # Enters satisfaction level inputs for -n, the -f groups, and acting 
    # group "g"  -doer.

    proc satlevel {sit args} {
        set cov     [$sit get coverage]
        set nomCov  [parmdb get ada.envsit.nominalCoverage]

        assert {[llength $args] != 0 && [llength $args] % 3 == 0}

        set result [list]

        foreach {con limit days} $args {
            let limit {[qmag value $limit] * ($cov/$nomCov)}

            # Get rid of -0's
            if {$limit == 0.0} {
                set limit 0.0
            }

            lappend result $con $limit $days
        }

        ada sat level {*}$result
    }


    # satslope con slope ?con slope...?
    #
    # sit        The situation
    # con        The affected concern
    # slope      The nominal slope
    #
    # Enters satisfaction slope inputs for -n, the -f groups, and acting 
    # group "g"  -doer.

    proc satslope {sit args} {
        set cov     [$sit get coverage]
        set nomCov  [parmdb get ada.envsit.nominalCoverage]

        assert {[llength $args] != 0 && [llength $args] % 2 == 0}

        set result [list]

        foreach {con slope} $args {
            let slope {[qmag value $slope] * ($cov/$nomCov)}

            # Get rid of -0's
            if {$slope == 0.0} {
                set slope 0.0
            }

            lappend result $con $slope
        }

        ada sat slope {*}$result
    }
}






