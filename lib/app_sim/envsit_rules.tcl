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

    # setup sit
    #
    # sit     Envsit object
    #
    # Ruleset setup.  This is the default setup; specific rule sets
    # can override it.

    typemethod setup {sit} {
        set ruleset [$sit get stype]
        set n       [$sit get n]

        ada ruleset $ruleset [$sit get driver]  \
            -sit       $sit                     \
            -doer      [$sit get g]             \
            -location  [$sit get location]      \
            -n         $n                       \
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
            envsit_rules $subsets($ruleset.setup) $sit

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
            envsit_rules $subsets($ruleset.setup) $sit

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
            envsit_rules $subsets($ruleset.setup) $sit

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
            1
        } {
            ada guard

            satslope $sit \
                AUT L-    \
                QOL XXL- 
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

        ada rule BADFOOD-3-1 -doer $g {
            !$gIsLocal
        } {
            satlevel $sit    \
                AUT XL+   2  \
                QOL XXXL+ 2

            ada sat clear AUT QOL
        }

        # BADFOOD-3-2:
        #
        # If there is a BADFOOD situation
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADFOOD-3-2 -doer $g {
            $gIsLocal
        } {
            satlevel $sit    \
                AUT XXXL+ 2  \
                QOL XXXL+ 2

            ada sat clear AUT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT L-    S   \
                QOL XXXL- S
        }
    }

    # BADWATER-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod BADWATER-2 {sit} {
        log detail envr [list BADWATER-2 [$sit get s]]

        # BADWATER-2-1:
        #
        # While there is a BADWATER situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT L-    -100 \
                QOL XXL-  -100
        }

        # BADWATER-2-2:
        #
        # While there is a BADWATER situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT QOL
        }
    }

    # BADWATER-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod BADWATER-3 {sit} {
        log detail envr [list BADWATER-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # BADWATER-3-1:
        #
        # If there is an enabled BADWATER situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XL+   S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT QOL
        }

        # BADWATER-3-2:
        #
        # If there is an enabled BADWATER situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BADWATER-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                SFT XXXL-  S  \
                QOL XXL-   S
        }
    }

    # BIO-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod BIO-2 {sit} {
        log detail envr [list BIO-2 [$sit get s]]

        # BIO-2-1:
        #
        # While there is a BIO situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope   \
                AUT L-     -100 \
                SFT XXXL-  -100 \
                QOL XXL-   -100
        }

        # BIO-2-2:
        #
        # While there is a BIO situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # BIO-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod BIO-3 {sit} {
        log detail envr [list BIO-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # BIO-3-1:
        #
        # If there is an enabled BIO situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XL+  S   \
                SFT XL+  S   \
                QOL L+   S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # BIO-3-2:
        #
        # If there is an enabled BIO situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule BIO-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                SFT XL+   S   \
                QOL L+    S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                SFT XXXL-  S  \
                QOL XXL-   S
        }
    }

    # CHEM-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod CHEM-2 {sit} {
        log detail envr [list CHEM-2 [$sit get s]]

        # CHEM-2-1:
        #
        # While there is a CHEM situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope   \
                AUT L-     -100 \
                SFT XXXL-  -100 \
                QOL XXL-   -100
        }

        # CHEM-2-2:
        #
        # While there is a CHEM situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # CHEM-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod CHEM-3 {sit} {
        log detail envr [list CHEM-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # CHEM-3-1:
        #
        # If there is an enabled CHEM situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XL+   S   \
                SFT XL+   S   \
                QOL L+    S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # CHEM-3-2:
        #
        # If there is an enabled CHEM situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule CHEM-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                SFT XL+   S   \
                QOL L+    S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT M-   S    \
                SFT S-   S    \
                QOL XL-  S
        }
    }

    # COMMOUT-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod COMMOUT-2 {sit} {
        log detail envr [list COMMOUT-2 [$sit get s]]

        # COMMOUT-2-1:
        #
        # While there is a COMMOUT situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT M-    -100 \
                SFT S-    -100 \
                QOL L-    -100
        }

        # COMMOUT-2-2:
        #
        # While there is a COMMOUT situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # COMMOUT-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod COMMOUT-3 {sit} {
        log detail envr [list COMMOUT-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # COMMOUT-3-1:
        #
        # If there is an enabled COMMOUT situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT L+   S    \
                SFT XL+  S    \
                QOL XXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # COMMOUT-3-2:
        #
        # If there is an enabled COMMOUT situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule COMMOUT-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXL+ S    \
                SFT XL+  S    \
                QOL XXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                SFT L-     S  \
                QOL XXL-   S
        }
    }

    # DISASTER-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod DISASTER-2 {sit} {
        log detail envr [list DISASTER-2 [$sit get s]]

        # DISASTER-2-1:
        #
        # While there is a DISASTER situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope   \
                AUT L-     -100 \
                SFT L-     -100 \
                QOL XXL-   -100
        }

        # DISASTER-2-2:
        #
        # While there is a DISASTER situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # DISASTER-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod DISASTER-3 {sit} {
        log detail envr [list DISASTER-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # DISASTER-3-1:
        #
        # If there is an enabled DISASTER situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT L+    S   \
                SFT XL+   S   \
                QOL L+    S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # DISASTER-3-2:
        #
        # If there is an enabled DISASTER situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISASTER-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XL+   S   \
                SFT XL+   S   \
                QOL L+    S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT S-   S    \
                SFT L-   S    \
                QOL XL-  S
        }
    }

    # DISEASE-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod DISEASE-2 {sit} {
        log detail envr [list DISEASE-2 [$sit get s]]

        # DISEASE-2-1:
        #
        # While there is a DISEASE situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT S-    -100 \
                SFT L-    -100 \
                QOL XL-   -100
        }

        # DISEASE-2-2:
        #
        # While there is a DISEASE situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # DISEASE-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod DISEASE-3 {sit} {
        log detail envr [list DISEASE-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # DISEASE-3-1:
        #
        # If there is an enabled DISEASE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XL+   S   \
                SFT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # DISEASE-3-2:
        #
        # If there is an enabled DISEASE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule DISEASE-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                SFT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT L-    S   \
                SFT L-    S   \
                QOL XXXL- S
        }
    }

    # EPIDEMIC-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod EPIDEMIC-2 {sit} {
        log detail envr [list EPIDEMIC-2 [$sit get s]]

        # EPIDEMIC-2-1:
        #
        # While there is a EPIDEMIC situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT L-    -100 \
                SFT L-    -100 \
                QOL XL-   -100
        }

        # EPIDEMIC-2-2:
        #
        # While there is a EPIDEMIC situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # EPIDEMIC-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod EPIDEMIC-3 {sit} {
        log detail envr [list EPIDEMIC-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # EPIDEMIC-3-1:
        #
        # If there is an enabled EPIDEMIC situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XXL+  S   \
                SFT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # EPIDEMIC-3-2:
        #
        # If there is an enabled EPIDEMIC situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule EPIDEMIC-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                SFT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: FOODSHRT: Food Shortage
    #
    # Environmental Situation: There is a food shortage in the neighborhood.
 
    # FOODSHRT-1 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod FOODSHRT-1 {sit} {
        log detail envr [list FOODSHRT-1 [$sit get s]]

        # FOODSHRT-1-1:
        #
        # While there is a FOODSHRT situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FOODSHRT-1-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope \
                AUT M-   -100 \
                QOL XL-  -100
        }

        # FOODSHRT-1-2:
        #
        # While there is a FOODSHRT situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FOODSHRT-1-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT QOL
        }
    }

    # FOODSHRT-2 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod FOODSHRT-2 {sit} {
        log detail envr [list FOODSHRT-2 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # FOODSHRT-2-1:
        #
        # If there is an enabled FOODSHRT situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FOODSHRT-2-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT L+  S     \
                QOL XL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT QOL
        }

        # FOODSHRT-2-2:
        #
        # If there is an enabled FOODSHRT situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FOODSHRT-2-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXL+ S    \
                QOL XL+  S

            # Cancel the ongoing slope effects
            ada sat clear AUT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT M- S      \
                SFT S- S      \
                QOL L- S
        }
    }

    # FUELSHRT-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod FUELSHRT-2 {sit} {
        log detail envr [list FUELSHRT-2 [$sit get s]]

        # FUELSHRT-2-1:
        #
        # While there is a FUELSHRT situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT M-    -100 \
                SFT S-    -100 \
                QOL XL-   -100
        }

        # FUELSHRT-2-2:
        #
        # While there is a FUELSHRT situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # FUELSHRT-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod FUELSHRT-3 {sit} {
        log detail envr [list FUELSHRT-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # FUELSHRT-3-1:
        #
        # If there is an enabled FUELSHRT situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT L+   S    \
                SFT XL+  S    \
                QOL XXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # FUELSHRT-3-2:
        #
        # If there is an enabled FUELSHRT situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule FUELSHRT-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXL+ S    \
                SFT XL+  S    \
                QOL XXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT S- S      \
                SFT S- S      \
                QOL S- S
        }
    }

    # GARBAGE-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod GARBAGE-2 {sit} {
        log detail envr [list GARBAGE-2 [$sit get s]]

        # GARBAGE-2-1:
        #
        # While there is a GARBAGE situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT XS-   -100 \
                SFT M-    -100 \
                QOL S-    -100
        }

        # GARBAGE-2-2:
        #
        # While there is a GARBAGE situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-2-2  {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # GARBAGE-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod GARBAGE-3 {sit} {
        log detail envr [list GARBAGE-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # GARBAGE-3-1:
        #
        # If there is an enabled GARBAGE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT L+   S    \
                SFT XL+  S    \
                QOL XL+  S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # GARBAGE-3-2:
        #
        # If there is an enabled GARBAGE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule GARBAGE-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXL+ S    \
                SFT XL+  S    \
                QOL XL+  S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT S-  S     \
                SFT M-  S     \
                QOL XL- S
        }
    }

    # INDSPILL-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod INDSPILL-2 {sit} {
        log detail envr [list INDSPILL-2 [$sit get s]]

        # INDSPILL-2-1:
        #
        # While there is a INDSPILL situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT S-    -100 \
                SFT M-    -100 \
                QOL L-    -100
        }

        # INDSPILL-2-2:
        #
        # While there is a INDSPILL situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # INDSPILL-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod INDSPILL-3 {sit} {
        log detail envr [list INDSPILL-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # INDSPILL-3-1:
        #
        # If there is an enabled INDSPILL situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XL+   S   \
                SFT XXL+  S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # INDSPILL-3-2:
        #
        # If there is an enabled INDSPILL situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule INDSPILL-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                SFT XXL+  S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT S-    S   \
                SFT M-    S   \
                CUL XXL-  S   \
                QOL S-    S
        }

    }

    # MOSQUE-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod MOSQUE-2 {sit} {
        log detail envr [list MOSQUE-2 [$sit get s]]

        # MOSQUE-2-1:
        #
        # While there is a MOSQUE situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT S-    -100 \
                SFT M-    -100 \
                CUL XL-   -100 \
                QOL S-    -100
        }

        # MOSQUE-2-2:
        #
        # While there is a MOSQUE situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT CUL QOL
        }
    }

    # MOSQUE-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod MOSQUE-3 {sit} {
        log detail envr [list MOSQUE-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # MOSQUE-3-1:
        #
        # If there is an enabled MOSQUE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT L+    S   \
                SFT XL+   S   \
                CUL XXXL+ S   \
                QOL XL+   S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT CUL QOL
        }

        # MOSQUE-3-2:
        #
        # If there is an enabled MOSQUE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule MOSQUE-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXL+  S   \
                SFT XL+   S   \
                CUL XXXL+ S   \
                QOL XL+   S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT CUL QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT XL-  S    \
                QOL XXL- S
        }
    }

    # NOWATER-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod NOWATER-2 {sit} {
        log detail envr [list NOWATER-2 [$sit get s]]

        # NOWATER-2-1:
        #
        # While there is a NOWATER situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope \
                AUT XL-  -100 \
                QOL XL-  -100
        }

        # NOWATER-2-2:
        #
        # While there is a NOWATER situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT QOL
        }
    }

    # NOWATER-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod NOWATER-3 {sit} {
        log detail envr [list NOWATER-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # NOWATER-3-1:
        #
        # If there is an enabled NOWATER situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XL+   S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT QOL
        }

        # NOWATER-3-2:
        #
        # If there is an enabled NOWATER situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule NOWATER-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT L-    S   \
                SFT XXL-  S   \
                QOL XXXL- S
        }
    }

    # ORDNANCE-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod ORDNANCE-2 {sit} {
        log detail envr [list ORDNANCE-2 [$sit get s]]

        # ORDNANCE-2-1:
        #
        # While there is a ORDNANCE situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT L-    -100 \
                SFT XXL-  -100 \
                QOL XXL-  -100
        }

        # ORDNANCE-2-2:
        #
        # While there is a ORDNANCE situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # ORDNANCE-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod ORDNANCE-3 {sit} {
        log detail envr [list ORDNANCE-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # ORDNANCE-3-1:
        #
        # If there is an enabled ORDNANCE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT M+    S   \
                SFT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # ORDNANCE-3-2:
        #
        # If there is an enabled ORDNANCE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule ORDNANCE-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                SFT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT S-  S     \
                SFT S-  S     \
                QOL XL- S
        }
    }

    # PIPELINE-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod PIPELINE-2 {sit} {
        log detail envr [list PIPELINE-2 [$sit get s]]

        # PIPELINE-2-1:
        #
        # While there is a PIPELINE situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT S-    -100 \
                SFT S-    -100 \
                QOL L-    -100
        }

        # PIPELINE-2-2:
        #
        # While there is a PIPELINE situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # PIPELINE-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod PIPELINE-3 {sit} {
        log detail envr [list PIPELINE-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # PIPELINE-3-1:
        #
        # If there is an enabled PIPELINE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT L+    S   \
                SFT XXL+  S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # PIPELINE-3-2:
        #
        # If there is an enabled PIPELINE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule PIPELINE-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXL+  S   \
                SFT XXL+  S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT S-  S     \
                SFT S-  S     \
                QOL L-  S
        }
    }

    # POWEROUT-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod POWEROUT-2 {sit} {
        log detail envr [list POWEROUT-2 [$sit get s]]

        # POWEROUT-2-1:
        #
        # While there is a POWEROUT situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT S-    -100 \
                SFT S-    -100 \
                QOL L-    -100
        }

        # POWEROUT-2-2:
        #
        # While there is a POWEROUT situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # POWEROUT-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod POWEROUT-3 {sit} {
        log detail envr [list POWEROUT-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # POWEROUT-3-1:
        #
        # If there is an enabled POWEROUT situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT L+    S   \
                SFT XL+   S   \
                QOL XL+   S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # POWEROUT-3-2:
        #
        # If there is an enabled POWEROUT situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule POWEROUT-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXL+  S   \
                SFT XL+   S   \
                QOL XL+   S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT S-   S    \
                SFT S-   S    \
                QOL XL-  S
        }
    }

    # REFINERY-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod REFINERY-2 {sit} {
        log detail envr [list REFINERY-2 [$sit get s]]

        # REFINERY-2-1:
        #
        # While there is a REFINERY situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope  \
                AUT S-    -100 \
                SFT S-    -100 \
                QOL L-    -100
        }

        # REFINERY-2-2:
        #
        # While there is a REFINERY situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT SFT QOL
        }
    }

    # REFINERY-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod REFINERY-3 {sit} {
        log detail envr [list REFINERY-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # REFINERY-3-1:
        #
        # If there is an enabled REFINERY situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XL+   S   \
                SFT XL+   S   \
                QOL XXL+  S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
        }

        # REFINERY-3-2:
        #
        # If there is an enabled REFINERY situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule REFINERY-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+  S  \
                SFT XL+    S  \
                QOL XXL+   S

            # Cancel the ongoing slope effects
            ada sat clear AUT SFT QOL
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
            [$sit get FRACTION_RESOLVED] == 0.0
        } {
            ada sat level \
                AUT S-  S   \
                QOL XL- S
        }
    }

    # SEWAGE-2 dict
    #
    # sit       Envsit object
    #
    # The situation continues.

    typemethod SEWAGE-2 {sit} {
        log detail envr [list SEWAGE-2 [$sit get s]]

        # SEWAGE-2-1:
        #
        # While there is a SEWAGE situation
        #     with FRACTION_RESOLVED < 1.0
        #     and  ENABLED = 1
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-2-1 {
            [$sit get FRACTION_RESOLVED] < 1.0    &&
            [$sit get ENABLED]
        } {
            ada sat slope \
                AUT XS-  -100 \
                QOL L-   -100
        }

        # SEWAGE-2-2:
        #
        # While there is a SEWAGE situation
        #     with ENABLED == 0
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-2-2 {
            ![$sit get ENABLED]
        } {
            ada sat clear AUT QOL
        }
    }

    # SEWAGE-3 sit
    #
    # sit         Envsit object 
    # dict        MAGIC:RESOLVE dictionary
    #
    # Situation resolution

    typemethod SEWAGE-3 {sit} {
        log detail envr [list SEWAGE-3 [$sit get s] $dict]

        # FIRST, make the data available
        array set evt $dict

        set g $evt(RESOLVED_BY)

        if {$g ne ""
            && [rdb pgroup $g local]} {
            set gIsLocal 1
        } else {
            set gIsLocal 0
        }

        # SEWAGE-3-1:
        #
        # If there is an enabled SEWAGE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is unknown or not local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-3-1 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            !$gIsLocal
        } {
            ada sat level \
                AUT XL+   S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT QOL
        }

        # SEWAGE-3-2:
        #
        # If there is an enabled SEWAGE situation
        #     with FRACTION_RESOLVED == 1.0
        #     and resolving group g is local,
        # Then for each CIV pgroup f with non-zero population in the nbhood,

        ada rule SEWAGE-3-2 -doer $g {
            [$sit get ENABLED] &&
            [$sit get FRACTION_RESOLVED] == 1.0 &&
            $gIsLocal
        } {
            ada sat level \
                AUT XXXL+ S   \
                QOL XXXL+ S

            # Cancel the ongoing slope effects
            ada sat clear AUT QOL
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






