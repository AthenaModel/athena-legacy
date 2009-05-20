#-----------------------------------------------------------------------
# TITLE:
#    actsit_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n): Athena Driver Assessment, Activity Situation Rule Sets
#
#    ::actsit_rules is a singleton object implemented as a snit::type.  To
#    initialize it, call "::actsit_rules init".
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# actsit_rules

snit::type actsit_rules {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Type Constructor
    
    typeconstructor {
        # Import needed commands

        namespace import ::marsutil::* 
        namespace import ::simlib::* 
        namespace import ::projectlib::* 
    }

    #-------------------------------------------------------------------
    # Initialization method

    typemethod init {} {
        # FIRST, check requirements
        require {[info commands log] ne ""} "log is not defined."

        # NEXT, Actsit Rules is up.
        log normal actr "Initialized"
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # monitor sit
    #
    # sit     actsit object
    #
    # An actsit's status has changed; run its monitor rule set.
    
    typemethod {monitor} {sit} {
        set ruleset [$sit get stype]

        if {![parmdb get ada.$ruleset.active]} {
            log warning actr \
                "monitor $ruleset: ruleset has been deactivated"
            return
        }

        bgcatch {
            # Run the monitor rule set.
            actsit_rules $ruleset $sit
        }
    }

    #-------------------------------------------------------------------
    # Control Structures

    #-------------------------------------------------------------------
    # Rule Set Tools

    # satslope cov f con rmf slope ?con rmf slope...?
    #
    # cov        The coverage fraction
    # f          The affected group
    # con        The affected concern
    # rmf        The RMF to apply
    # slope      The nominal slope
    #
    # Enters satisfaction slope inputs for -n, the -f groups, and acting 
    # group "g"  -doer, for the force activity situations.

    proc satslope {cov f args} {
        set ruleset [ada get ruleset]
        set n       [ada rget -n]
        set g       [ada rget -doer]
        set nomCov  [parmdb get ada.nominalCoverage]

        assert {[llength $args] != 0 && [llength $args] % 3 == 0}

        set rel [rel $n $f $g]

        set result [list]

        foreach {con rmf slope} $args {
            let mult {[rmf $rmf $rel] * $cov / $nomCov}

            let slope {[qmag value $slope] * $mult}

            # Get rid of -0's
            if {$slope == 0.0} {
                set slope 0.0
            }

            lappend result $con $slope
        }

        ada sat slope -f $f {*}$result
    }


    # coopslope cov f slope
    #
    # cov        The coverage fraction
    # rmf        The RMF to apply
    # f          The affected group
    # slope      The nominal slope
    #
    # Enters cooperation slope inputs for -n, "f", and acting 
    # group "g"  -doer, for the force activity situations.

    proc coopslope {cov rmf f slope} {
        set ruleset [ada get ruleset]
        set n       [ada rget -n]
        set g       [ada rget -doer]
        set nomCov  [parmdb get ada.nominalCoverage]

        set rel [rel $n $f $g]

        let mult {[rmf $rmf $rel] * $cov / $nomCov}

        let slope {[qmag value $slope] * $mult}


        # Get rid of -0's
        if {$slope == 0.0} {
            set slope 0.0
        }
        
        ada coop slope -f $f -- $slope
    }


    # detail label value
    #
    # Adds a detail to the input details
   
    proc detail {label value} {
        ada details [format "%-21s %s\n" $label $value]
    }

    #===================================================================
    # Explicit Situations
    #
    # The following rule sets are for situations which do not depend
    # on the unit's stated ACTIVITY.

    #-------------------------------------------------------------------
    # Rule Set: PRESENCE:  Mere Presence of Force Units
    #
    # Activity Situation: This rule set determines the effect of the 
    # presence of force units on the local population.

    # PRESENCE sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring the PRESENCE of a force
    # group's units in a neighborhood.

    typemethod PRESENCE {sit} {
        log detail actr [list PRESENCE [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset PRESENCE [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]
        
        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule PRESENCE-1-1 {
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a PRESENCE situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad S+ \
                    SFT quad S+ \
                    QOL quad S+

                coopslope $cov quad $f S+
            }

        }

        ada rule PRESENCE-2-1 {
            $cov == 0.0
        } { 
            ada guard
            # While there is a PRESENCE situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT QOL
            ada coop clear
        }
    }


    #===================================================================
    # Force Activity Situations
    #
    # The following rule sets are for situations which depend
    # on the stated ACTIVITY of FRC units.

    #-------------------------------------------------------------------
    # Rule Set: CHKPOINT:  Checkpoint/Control Point
    #
    # Activity Situation: Units belonging to a force group are 
    # operating checkpoints in a neighborhood.

    # CHKPOINT sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CHECKPOINT in a neighborhood.

    typemethod CHKPOINT {sit} {
        log detail actr [list CHKPOINT [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset CHKPOINT [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CHKPOINT-1-1 {
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a CHKPOINT situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set rel [rel $n $f $g]

                if {$rel >= 0} {
                    # FRIENDS
                    satslope $cov $f      \
                        AUT quad     S+   \
                        SFT quad     S+   \
                        CUL constant XXS- \
                        QOL constant XS- 
                } elseif {$rel < 0} {
                    # ENEMIES
                    # Note: by default, RMF=quad for AUT, SFT, which will
                    # reverse the sign in this case.
                    satslope $cov $f     \
                        AUT quad     S+  \
                        SFT quad     S+  \
                        CUL constant S-  \
                        QOL constant S-        
                }

                coopslope $cov quad $f XXXS+
            }
        }

        ada rule CHKPOINT-2-1 {
            $cov == 0.0 
        } {
            ada guard
            # While there is a CHKPOINT situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOCONST:  CMO -- Construction
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_CONSTRUCTION in a neighborhood.

    # CMOCONST sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOCONST in a neighborhood.

    typemethod CMOCONST {sit} {
        log detail actr [list CMOCONST [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set stops        0
        set mitigating   0

        ada ruleset CMOCONST [$sit get driver]                   \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CMOCONST.nearFactor]        \
            -q         [parmdb get ada.CMOCONST.farFactor]         \
            -cause     [parmdb get ada.CMOCONST.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CMOCONST-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates CMOCONST $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
            }

            ada guard [format "%.1f %s" $cov $groupList]

            # While there is a CMOCONST situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # For each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$f in $groupList ? 1 : 0}]
                
                satslope $cov $f \
                    AUT [mag+ $stops S+]  100 \
                    SFT [mag+ $stops S+]  100 \
                    CUL [mag+ $stops XS+] 100 \
                    QOL [mag+ $stops L+]  100

                coopslope $cov $f [mag+ $stops M+] 100
            }
        }

        ada rule CMOCONST-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMOCONST situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule CMOCONST-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMOCONST situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMODEV:  CMO -- Development (Light)
    #
    # Activity Situation: Units belonging to a force group are 
    # encouraging light development in a neighborhood.

    # CMODEV sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CMO_DEVELOPMENT in a neighborhood.

    typemethod CMODEV {sit} {
        log detail actr [list CMODEV [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset CMODEV [$sit get driver]                   \
            -sit       $sit                                      \
            -doer      $g                                        \
            -n         $n                                        \
            -f         [nbgroup gIn $n]                    \
            -p         [parmdb get ada.CMODEV.nearFactor]        \
            -q         [parmdb get ada.CMODEV.farFactor]         \
            -cause     [parmdb get ada.CMODEV.cause] 

        
        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CMODEV-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a CMODEV situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f  \
                    AUT M+ 100 \
                    SFT S+ 100 \
                    CUL S+ 100 \
                    QOL L+ 100

                coopslope $cov $f M+ 100
            }
        }

        ada rule CMODEV-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMODEV situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule CMODEV-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMODEV situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOEDU:  CMO -- Education
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_EDUCATION in a neighborhood.

    # CMOEDU sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOEDU in a neighborhood.

    typemethod CMOEDU {sit} {
        log detail actr [list CMOEDU [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set stops        0
        set mitigating   0

        ada ruleset CMOEDU [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CMOEDU.nearFactor]          \
            -q         [parmdb get ada.CMOEDU.farFactor]           \
            -cause     [parmdb get ada.CMOEDU.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CMOEDU-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates CMOEDU $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
            }

            ada guard [format "%.1f %s" $cov $groupList]

            # While there is a CMOEDU situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$f in $groupList ? 1 : 0}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops L+]   100 \

                coopslope $cov $f [mag+ $stops M+] 100
            }
        }

        ada rule CMOEDU-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMOEDU situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule CMOEDU-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMOEDU situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOEMP:  CMO -- Employment
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_EMPLOYMENT in a neighborhood.

    # CMOEMP sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOEMP in a neighborhood.

    typemethod CMOEMP {sit} {
        log detail actr [list CMOEMP [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set stops        0
        set mitigating   0

        ada ruleset CMOEMP [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CMOEMP.nearFactor]          \
            -q         [parmdb get ada.CMOEMP.farFactor]           \
            -cause     [parmdb get ada.CMOEMP.cause] 
       
        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CMOEMP-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates CMOEMP $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
            }

            ada guard [format "%.1f %s" $cov $groupList]

            # While there is a CMOEMP situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$f in $groupList ? 1 : 0}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops L+]   100

                coopslope $cov $f [mag+ $stops M+] 100
            }
        }

        ada rule CMOEMP-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMOEMP situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
         }

        ada rule CMOEMP-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMOEMP situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOIND:  CMO -- Industry
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_INDUSTRY in a neighborhood.

    # CMOIND sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOIND in a neighborhood.

    typemethod CMOIND {sit} {
        log detail actr [list CMOIND [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set stops        0
        set mitigating   0

        ada ruleset CMOIND [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CMOIND.nearFactor]          \
            -q         [parmdb get ada.CMOIND.farFactor]           \
            -cause     [parmdb get ada.CMOIND.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CMOIND-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates CMOIND $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
            }

            ada guard [format "%.1f %s" $cov $groupList]

            # While there is a CMOIND situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$f in $groupList ? 1 : 0}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops L+]   100

                coopslope $cov $f [mag+ $stops M+] 100
            }
        }

        ada rule CMOIND-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMOIND situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule CMOIND-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMOIND situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOINF:  CMO -- Infrastructure
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_INFRASTRUCTURE in a neighborhood.

    # CMOINF sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOINF in a neighborhood.

    typemethod CMOINF {sit} {
        log detail actr [list CMOINF [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set stops        0
        set mitigating   0

        ada ruleset CMOINF [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CMOINF.nearFactor]          \
            -q         [parmdb get ada.CMOINF.farFactor]           \
            -cause     [parmdb get ada.CMOINF.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CMOINF-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates CMOINF $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
            }

            ada guard [format "%.1f %s" $cov $groupList]

            # While there is a CMOINF situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$f in $groupList ? 1 : 0}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops M+]   100

                coopslope $cov $f [mag+ $stops M+] 100
            }
        }

        ada rule CMOINF-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMOINF situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule CMOINF-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMOINF situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOLAW:  CMO -- Law Enforcement
    #
    # Activity Situation: Units belonging to a force group are 
    # enforcing the law in a neighborhood.

    # CMOLAW sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CMO_LAW_ENFORCEMENT in a neighborhood.

    typemethod CMOLAW {sit} {
        log detail actr [list CMOLAW [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset CMOLAW [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CMOLAW.nearFactor]          \
            -q         [parmdb get ada.CMOLAW.farFactor]           \
            -cause     [parmdb get ada.CMOLAW.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

       ada rule CMOLAW-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a CMOLAW situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT M+ 100 \
                    SFT S+ 100

                coopslope $cov $f M+ 100
            }
        }

        ada rule CMOLAW-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMOLAW situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT
            ada coop clear
        }

        ada rule CMOLAW-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMOLAW situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOMED:  CMO -- Healthcare
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_HEALTHCARE in a neighborhood.

    # CMOMED sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOMED in a neighborhood.

    typemethod CMOMED {sit} {
        log detail actr [list CMOMED [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set stops        0
        set mitigating   0

        ada ruleset CMOMED [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CMOMED.nearFactor]          \
            -q         [parmdb get ada.CMOMED.farFactor]           \
            -cause     [parmdb get ada.CMOMED.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CMOMED-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates CMOMED $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
            }

            ada guard [format "%.1f %s" $cov $groupList]

            # While there is a CMOMED situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$f in $groupList ? 1 : 0}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops L+]   100

                coopslope $cov $f [mag+ $stops L+] 100
            }
        }

        ada rule CMOMED-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMOMED situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule CMOMED-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMOMED situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOOTHER:  CMO -- Other
    #
    # Activity Situation: Units belonging to a CMO group are 
    # doing CMO_OTHER in a neighborhood.

    # CMOOTHER sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOOTHER in a neighborhood.

    typemethod CMOOTHER {sit} {
        log detail actr [list CMOOTHER [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set stops        0
        set mitigating   0

        ada ruleset CMOOTHER [$sit get driver]                   \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CMOOTHER.nearFactor]        \
            -q         [parmdb get ada.CMOOTHER.farFactor]         \
            -cause     [parmdb get ada.CMOOTHER.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CMOOTHER-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates CMOOTHER $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
            }

            ada guard [format "%.1f %s" $cov $groupList]

            # While there is a CMOOTHER situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$f in $groupList ? 1 : 0}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops S+]   100 \
                    CUL [mag+ $stops XS+]  100 \
                    QOL [mag+ $stops L+]   100

                coopslope $cov $f [mag+ $stops M+] 100
            }
        }

        ada rule CMOOTHER-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CMOOTHER situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule CMOOTHER-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CMOOTHER situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: COERCION:  Coercion
    #
    # Activity Situation: Units belonging to a force group are 
    # coercing local civilians to cooperate with them through threats
    # of violence.

    # COERCION sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of COERCION in a neighborhood.

    typemethod COERCION {sit} {
        log detail actr [list COERCION [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset COERCION [$sit get driver]                   \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.COERCION.nearFactor]        \
            -q         [parmdb get ada.COERCION.farFactor]         \
            -cause     [parmdb get ada.COERCION.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule COERCION-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a COERCION situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT XL-  -100 \
                    SFT XXL- -100 \
                    CUL XS-  -100 \
                    QOL M-   -100

                coopslope $cov $f XXXL+ 100
            }
        }

        ada rule COERCION-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a COERCION situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule COERCION-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a COERCION situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: CRIMINAL:  Criminal Activities
    #
    # Activity Situation: Units belonging to a force group are 
    # engaging in criminal activities in a neighborhood.

    # CRIMINAL sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CRIMINAL in a neighborhood.

    typemethod CRIMINAL {sit} {
        log detail actr [list CRIMINAL [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset CRIMINAL [$sit get driver]                   \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CRIMINAL.nearFactor]        \
            -q         [parmdb get ada.CRIMINAL.farFactor]         \
            -cause     [parmdb get ada.CRIMINAL.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CRIMINAL-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a CRIMINAL situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT L-   -100 \
                    SFT XL-  -100 \
                    QOL L-   -100
            }
        }

        ada rule CRIMINAL-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CRIMINAL situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT QOL
        }

        ada rule CRIMINAL-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CRIMINAL situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT QOL
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CURFEW:  Curfew
    #
    # Activity Situation: Units belonging to a force group are 
    # enforcing a curfew in a neighborhood.

    # CURFEW sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CURFEW in a neighborhood.

    typemethod CURFEW {sit} {
        log detail actr [list CURFEW [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset CURFEW [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.CURFEW.nearFactor]          \
            -q         [parmdb get ada.CURFEW.farFactor]           \
            -cause     [parmdb get ada.CURFEW.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule CURFEW-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a CURFEW situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set rel [rel $n $f $g]

                if {$rel >= 0} {
                    # Friends
                    satslope $cov $f \
                        AUT S-  -100 \
                        SFT S+   100 \
                        CUL S-  -100 \
                        QOL S-  -100
                } else {
                    # Enemies
                    
                    # NOTE: Because $rel < 0, and the expected RMF
                    # is "quad", the SFT input turns into a minus.
                    satslope $cov $f \
                        AUT S-  -100 \
                        SFT M+   100 \
                        CUL S-  -100 \
                        QOL S-  -100 \
                }

                coopslope $cov $f M+ 100
            }
        }

        ada rule CURFEW-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a CURFEW situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule CURFEW-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a CURFEW situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: GUARD:  Guard
    #
    # Activity Situation: Units belonging to a force group are 
    # guarding sites in a neighborhood.

    # GUARD sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of GUARD in a neighborhood.

    typemethod GUARD {sit} {
        log detail actr [list GUARD [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset GUARD [$sit get driver]                      \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.GUARD.nearFactor]           \
            -q         [parmdb get ada.GUARD.farFactor]            \
            -cause     [parmdb get ada.GUARD.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule GUARD-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a GUARD situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT L-  -100 \
                    SFT L-  -100 \
                    CUL L-  -100 \
                    QOL M-  -100

                coopslope $cov $f S+ 100
            }
        }

        ada rule GUARD-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a GUARD situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule GUARD-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a GUARD situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    
    #-------------------------------------------------------------------
    # Rule Set: PATROL:  Patrol
    #
    # Activity Situation: Units belonging to a force group are 
    # patrolling a neighborhood.

    # PATROL sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of PATROL in a neighborhood.

    typemethod PATROL {sit} {
        log detail actr [list PATROL [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        ada ruleset PATROL [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.PATROL.nearFactor]          \
            -q         [parmdb get ada.PATROL.farFactor]           \
            -cause     [parmdb get ada.PATROL.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule PATROL-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a PATROL situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT M-  -100 \
                    SFT M-  -100 \
                    CUL S-  -100 \
                    QOL L-  -100

                coopslope $cov $f S+ 100
            }
        }

        ada rule PATROL-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a PATROL situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule PATROL-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a PATROL situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: PSYOP:  Psychological Operations
    #
    # Activity Situation: Units belonging to a force group are 
    # doing PSYOP in a neighborhood.

    # PSYOP sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of PSYOP in a neighborhood.

    typemethod PSYOP {sit} {
        log detail actr [list PSYOP [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]
        
        ada ruleset PSYOP [$sit get driver]                      \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.PSYOP.nearFactor]           \
            -q         [parmdb get ada.PSYOP.farFactor]            \
            -cause     [parmdb get ada.PSYOP.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule PSYOP-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            ada guard [format %.1f $cov]

            # While there is a PSYOP situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set rel [rel $n $f $g]

                if {$rel >= 0} {
                    # Friends
                    satslope $cov $f \
                        AUT S+  100 \
                        SFT S+  100 \
                        CUL S+  100 \
                        QOL S+  100
                } else {
                    # Enemies
                    satslope $cov $f \
                        AUT XS+ 100 \
                        SFT XS+ 100 \
                        CUL XS+ 100 \
                        QOL XS+ 100
                }


                coopslope $cov $f XL+ 100
            }
        }

        ada rule PSYOP-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a PSYOP situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }

        ada rule PSYOP-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a PSYOP situation
            #     with ENABLED = 0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
            ada coop clear
        }
    }



    #===================================================================
    # ORG Activity Situations
    #
    # The following rule sets are for situations which depend
    # on the stated ACTIVITY of ORG units.

    #-------------------------------------------------------------------
    # Rule Set: ORGCONST:  CMO -- Construction
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_CONSTRUCTION in a neighborhood.

    # ORGCONST sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGCONST in a neighborhood.

    typemethod ORGCONST {sit} {
        log detail actr [list ORGCONST [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set fstops       0
        set gstops       0

        ada ruleset ORGCONST [$sit get driver]                   \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.ORGCONST.nearFactor]        \
            -q         [parmdb get ada.ORGCONST.farFactor]         \
            -cause     [parmdb get ada.ORGCONST.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule ORGCONST-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates ORGCONST $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
                incr gstops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr fstops -1
                incr gstops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            ada guard [format "%.1f %s %d" $cov $groupList $gstops]

            # While there is a ORGCONST situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            service [mag+ $gstops M+] 100

            # And for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$fstops + ($f in $groupList ? 1 : 0)}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]  100 \
                    SFT [mag+ $stops S+]  100 \
                    CUL [mag+ $stops XS+] 100 \
                    QOL [mag+ $stops L+]  100
            }
        }

        ada rule ORGCONST-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a ORGCONST situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }

        ada rule ORGCONST-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a ORGCONST situation
            #     with ENABLED = 0
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGEDU:  CMO -- Education
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_EDUCATION in a neighborhood.

    # ORGEDU sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGEDU in a neighborhood.

    typemethod ORGEDU {sit} {
        log detail actr [list ORGEDU [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set fstops       0
        set gstops       0

        ada ruleset ORGEDU [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.ORGEDU.nearFactor]          \
            -q         [parmdb get ada.ORGEDU.farFactor]           \
            -cause     [parmdb get ada.ORGEDU.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule ORGEDU-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates ORGEDU $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
                incr gstops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr fstops -1
                incr gstops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            ada guard [format "%.1f %s %d" $cov $groupList $gstops]

            # While there is a ORGEDU situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            service [mag+ $gstops M+] 100

            # And for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$fstops + ($f in $groupList ? 1 : 0)}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops L+]   100
            }
        }

        ada rule ORGEDU-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a ORGEDU situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }

        ada rule ORGEDU-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a ORGEDU situation
            #     with ENABLED = 0
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGEMP:  CMO -- Employment
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_EMPLOYMENT in a neighborhood.

    # ORGEMP sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGEMP in a neighborhood.

    typemethod ORGEMP {sit} {
        log detail actr [list ORGEMP [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set fstops       0
        set gstops       0

        ada ruleset ORGEMP [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.ORGEMP.nearFactor]          \
            -q         [parmdb get ada.ORGEMP.farFactor]           \
            -cause     [parmdb get ada.ORGEMP.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule ORGEMP-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates ORGEMP $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
                incr gstops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr fstops -1
                incr gstops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }
            
            ada guard [format "%.1f %s %d" $cov $groupList $gstops]

            # While there is a ORGEMP situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            service [mag+ $gstops M+] 100

            # And for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$fstops + ($f in $groupList ? 1 : 0)}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops L+]   100
            }
        }

        ada rule ORGEMP-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a ORGEMP situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }

        ada rule ORGEMP-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a ORGEMP situation
            #     with ENABLED = 0
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGIND:  CMO -- Industry
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_INDUSTRY in a neighborhood.

    # ORGIND sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGIND in a neighborhood.

    typemethod ORGIND {sit} {
        log detail actr [list ORGIND [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set fstops       0
        set gstops       0

        ada ruleset ORGIND [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.ORGIND.nearFactor]          \
            -q         [parmdb get ada.ORGIND.farFactor]           \
            -cause     [parmdb get ada.ORGIND.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule ORGIND-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates ORGIND $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
                incr gstops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr fstops -1
                incr gstops -1                
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            ada guard [format "%.1f %s %d" $cov $groupList $gstops]

            # While there is a ORGIND situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            service [mag+ $gstops M+] 100

            # And for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$fstops + ($f in $groupList ? 1 : 0)}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops L+]   100
            }
        }

        ada rule ORGIND-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a ORGIND situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }

        ada rule ORGIND-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a ORGIND situation
            #     with ENABLED = 0
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGINF:  CMO -- Infrastructure
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_INFRASTRUCTURE in a neighborhood.

    # ORGINF sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGINF in a neighborhood.

    typemethod ORGINF {sit} {
        log detail actr [list ORGINF [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set fstops       0
        set gstops       0        

        ada ruleset ORGINF [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.ORGINF.nearFactor]          \
            -q         [parmdb get ada.ORGINF.farFactor]           \
            -cause     [parmdb get ada.ORGINF.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule ORGINF-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates ORGINF $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
                incr gstops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr fstops -1
                incr gstops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            ada guard [format "%.1f %s %d" $cov $groupList $gstops]

            # While there is a ORGINF situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            service [mag+ $gstops M+] 100

            # And for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$fstops + ($f in $groupList ? 1 : 0)}]
                
                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops M+]   100
            }
        }

        ada rule ORGINF-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a ORGINF situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }

        ada rule ORGINF-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a ORGINF situation
            #     with ENABLED = 0
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGMED:  CMO -- Healthcare
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_HEALTHCARE in a neighborhood.

    # ORGMED sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGMED in a neighborhood.

    typemethod ORGMED {sit} {
        log detail actr [list ORGMED [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set fstops       0
        set gstops       0

        ada ruleset ORGMED [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.ORGMED.nearFactor]          \
            -q         [parmdb get ada.ORGMED.farFactor]           \
            -cause     [parmdb get ada.ORGMED.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule ORGMED-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates ORGMED $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
                incr gstops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr fstops -1
                incr gstops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            ada guard [format "%.1f %s %d" $cov $groupList $gstops]

            # While there is a ORGMED situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            service [mag+ $gstops M+] 100

            # And for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$fstops + ($f in $groupList ? 1 : 0)}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops XXS+] 100 \
                    CUL [mag+ $stops XXS+] 100 \
                    QOL [mag+ $stops L+]   100
            }
        }

        ada rule ORGMED-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a ORGMED situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }

        ada rule ORGMED-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a ORGMED situation
            #     with ENABLED = 0
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGOTHER:  CMO -- Other
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_OTHER in a neighborhood.

    # ORGOTHER sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGOTHER in a neighborhood.

    typemethod ORGOTHER {sit} {
        log detail actr [list ORGOTHER [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set fstops       0
        set gstops       0

        ada ruleset ORGOTHER [$sit get driver]                   \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]                      \
            -p         [parmdb get ada.ORGOTHER.nearFactor]        \
            -q         [parmdb get ada.ORGOTHER.farFactor]         \
            -cause     [parmdb get ada.ORGOTHER.cause] 

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        ada rule ORGOTHER-1-1 {
            [$sit get enabled] &&
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set groupList       [list]
            set envsitsMitigated [mitigates ORGOTHER $n groupList]

            if {[llength $envsitsMitigated] > 0} {
                detail "Mitigates:"  [join $envsitsMitigated ", "]
                detail "For groups:" [join $groupList ", "]
                incr gstops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr fstops -1
                incr gstops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            ada guard [format "%.1f %s %d" $cov $groupList $gstops]

            # While there is a ORGOTHER situation
            #     with COVERAGE > 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            service [mag+ $gstops M+] 100

            # And for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set stops [expr {$fstops + ($f in $groupList ? 1 : 0)}]

                satslope $cov $f \
                    AUT [mag+ $stops S+]   100 \
                    SFT [mag+ $stops S+]   100 \
                    CUL [mag+ $stops XS+]  100 \
                    QOL [mag+ $stops L+]   100
            }
        }

        ada rule ORGOTHER-2-1 {
            [$sit get enabled] &&
            $cov == 0.0
        } {
            ada guard
            # While there is a ORGOTHER situation
            #     with COVERAGE = 0.0
            #     and  ENABLED = 1
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }

        ada rule ORGOTHER-2-2 {
            ![$sit get enabled]
        } {
            ada guard
            # While there is a ORGOTHER situation
            #     with ENABLED = 0
            # Then for the acting group,
            ada sat clear -f $g SVC

            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            ada sat clear AUT SFT CUL QOL
        }
    }

    #-------------------------------------------------------------------
    # Utility Procs

    # rel n f g
    #
    # n    A neighborhood
    # f    A CIV group f
    # g    A FRC or ORG group g
    #
    # Returns the relationship between the groups.

    proc rel {n f g} {
        set rel [rdb eval {
            SELECT rel FROM gram_nfg
            WHERE object='::aram' AND n=$n AND f=$f AND g=$g
        }]

        require {[string is double -strict $rel]} \
            "Invalid group pair f=$f, g=$g"

        return $rel
    }

    # mitigates ruleset nbhood groupvar
    #
    # ruleset     A CIV or ORG activity rule set
    # nbhood      The affected nbhood
    # groupvar    Name of var to contain groups affected by ongoing envsits
    #
    # Returns a list of the envsits present and sorted list of affected groups 
    # in nbhood which are mitigated by this rule set's activity.  
    # If none, returns the empty list and sets groupvar to {}.

    proc mitigates {ruleset nbhood groupvar} {
        # FIRST, initialize the groups list
        upvar $groupvar groups
        set groups [list]

        # NEXT, get the mitigated envsits and form them into an 
        # "IN" list.  If none, just return immediately.
        set envsits [parmdb get ada.$ruleset.mitigates]

        if {[llength $envsits] == 0} {
            return {} 
        }

        set inList "('[join $envsits ',']')"
        set envsits [list]
        set done   0

        # NEXT, check for active envsits, collecting the affected groups as
        # we go.
        rdb eval "
            SELECT TYPE, GROUPS FROM live_envsits
            WHERE NEIGHBORHOOD = \$nbhood
            AND   TYPE IN $inList
        " row {
            if {!$done} {
                if {$row(GROUPS) eq ""} {
                    set groups [nbgroup gIn $nbhood]
                    set done 1;    # no need to process additional groups
                } else {
                    lmerge groups $row(GROUPS)
                }
            }

            lappend envsits $row(TYPE)
        }
        
        # NEXT, sort the groups for consitency and return the envsits
        set groups [lsort $groups]
        
        return $envsits
    }

    #-------------------------------------------------------------------
    # Utility Procs

    # mag+ stops mag
    #
    # stops      Some number of "stops"
    # mag        A qmag symbol
    #
    # Returns the symbolic value of mag, moved up or down the specified
    # number of stops, or 0.  I.e., XL +1 stop is XXL; XL -1 stop is L.  
    # Stopping up or down never changes the sign.  Stopping down from
    # from XXXS returns 0; stopping up from XXXXL returns the value
    # of XXXXL.

    proc mag+ {stops mag} {
        set symbols [qmag names]
        set index [qmag index $mag]

        if {$index <= 9} {
            # Sign is positive; 0 is XXXXL+, 9 is XXXS+

            let index {$index - $stops}

            if {$index < 0} {
                return [lindex $symbols 0]
            } elseif {$index > 9} {
                return 0
            } else {
                return [lindex $symbols $index]
            }
        } else {
            # Sign is negative; 10 is XXXS-, 19 is XXXXL-

            let index {$index + $stops}

            if {$index > 19} {
                return [lindex $symbols 19]
            } elseif {$index < 10} {
                return 0
            } else {
                return [lindex $symbols $index]
            }
        }


        expr {$stops * [qmag value $mag]}
    }

    # orgsat n g c
    #
    # n    A nbhood name or "*"
    # g    A group name
    # c    A concern name
    #
    # Returns the ORG group's current satisfaction with the concern as a
    # qsat symbol.  If n is "*", the toplevel satisfaction is used.

    proc orgsat {n g c} {
        set sat ""

        if {$n eq "*"} {
            set sat [jram sat.gc $g $c]
        } else {
            set sat [jram sat.ngc $n $g $c]
        }

        return [qsat name $sat]
    }
}





