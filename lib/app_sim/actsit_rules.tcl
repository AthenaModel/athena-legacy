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
    # Public Typemethods

    # monitor sit
    #
    # sit     actsit object
    #
    # An actsit's status has changed; run its monitor rule set.
    
    typemethod {monitor} {sit} {
        set ruleset [$sit get stype]

        if {![parmdb get dam.$ruleset.active]} {
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
        set n       [dam rget -n]
        set g       [dam rget -doer]
        set nomCov  [parmdb get dam.actsit.nominalCoverage]

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

        dam sat slope -f $f {*}$result
    }


    # coopslope f cov rmf slope
    #
    # f          The affected group
    # cov        The coverage fraction
    # rmf        The RMF to apply
    # slope      The nominal slope
    #
    # Enters cooperation slope inputs for -n, "f", and acting 
    # group "g"  -doer, for the force activity situations.

    proc coopslope {f cov rmf slope} {
        set ruleset [dam get ruleset]
        set n       [dam rget -n]
        set g       [dam rget -doer]
        set nomCov  [parmdb get dam.actsit.nominalCoverage]

        set rel [rel $n $f $g]

        let mult {[rmf $rmf $rel] * $cov / $nomCov}

        let slope {[qmag value $slope] * $mult}


        # Get rid of -0's
        if {$slope == 0.0} {
            set slope 0.0
        }
        
        dam coop slope -f $f -- $slope
    }


    # detail label value
    #
    # Adds a detail to the input details
   
    proc detail {label value} {
        dam details [format "%-21s %s\n" $label $value]
    }


    #===================================================================
    # Civilian Activity Situations
    #
    # The following rule sets are for situations which depend
    # on the stated ACTIVITY of CIV units.

    #-------------------------------------------------------------------
    # Rule Set: DISPLACED:  Displaced Persons
    #
    # Activity Situation: Units belonging to a civilian group have
    # been displaced from their homes.

    # DISPLACED sit
    #
    # sit       The actsit object for this situation
    #
    # This method is called when monitoring civilian units
    # with an activity of DISPLACED in a neighborhood.

    typemethod DISPLACED {sit} {
        log detail actr [list DISPLACED [$sit id]]

        set g   [$sit get g]
        set n   [$sit get n]
        set cov [$sit get coverage]

        dam ruleset DISPLACED [$sit get driver]                    \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule DISPLACED-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a DISPLACED situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f      \
                    AUT enmore   S-   \
                    SFT enmore   L-   \
                    CUL enquad   S-   \
                    QOL constant M- 
            }
        }

        dam rule DISPLACED-2-1 {
            $cov == 0.0 
        } {
            dam guard

            # While there is a DISPLACED situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
        }
    }


    #===================================================================
    # Explicit Force Situations
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

        dam ruleset PRESENCE [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]
        
        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule PRESENCE-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a PRESENCE situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad XXS+ \
                    SFT quad XXS+ \
                    QOL quad XXS+

                coopslope $f $cov quad XXS+
            }

        }

        dam rule PRESENCE-2-1 {
            $cov == 0.0
        } { 
            dam guard
            # While there is a PRESENCE situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT QOL
            dam coop clear
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

        dam ruleset CHKPOINT [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CHKPOINT-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

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

                coopslope $f $cov quad XXXS+
            }
        }

        dam rule CHKPOINT-2-1 {
            $cov == 0.0 
        } {
            dam guard
            # While there is a CHKPOINT situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CMOCONST [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CMOCONST-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOCONST $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
            }

            dam guard [format "%.2f %s" $cov $stops]

            # While there is a CMOCONST situation
            #     with COVERAGE > 0.0
            # For each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad     [mag+ $stops S+]  \
                    SFT constant [mag+ $stops S+]  \
                    CUL constant [mag+ $stops XS+] \
                    QOL constant [mag+ $stops L+] 

                coopslope $f $cov frmore [mag+ $stops M+]
            }
        }

        dam rule CMOCONST-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMOCONST situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CMODEV [$sit get driver]                   \
            -sit       $sit                                      \
            -doer      $g                                        \
            -n         $n                                        \
            -f         [nbgroup gIn $n]
        
        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CMODEV-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a CMODEV situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f  \
                    AUT quad M+   \
                    SFT quad S+   \
                    CUL quad S+   \
                    QOL quad L+

                coopslope $f $cov frmore M+
            }
        }

        dam rule CMODEV-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMODEV situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CMOEDU [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CMOEDU-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOEDU $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
            }

            dam guard [format "%.2f %s" $cov $stops]

            # While there is a CMOEDU situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad     [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL quad     [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops L+]

                coopslope $f $cov frmore [mag+ $stops M+]
            }
        }

        dam rule CMOEDU-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMOEDU situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CMOEMP [$sit get driver]                       \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]
       
        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CMOEMP-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOEMP $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
            }

            dam guard [format "%.2f %s" $cov $stops]

            # While there is a CMOEMP situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad     [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops L+]

                coopslope $f $cov frmore [mag+ $stops M+]
            }
        }

        dam rule CMOEMP-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMOEMP situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CMOIND [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CMOIND-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOIND $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
            }

            dam guard [format "%.2f %s" $cov $stops]

            # While there is a CMOIND situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad     [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops L+]

                coopslope $f $cov frmore [mag+ $stops M+]
            }
        }

        dam rule CMOIND-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMOIND situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CMOINF [$sit get driver]                       \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CMOINF-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOINF $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
            }

            dam guard [format "%.2f %s" $cov $stops]

            # While there is a CMOINF situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad     [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops M+]

                coopslope $f $cov frmore [mag+ $stops M+]
            }
        }

        dam rule CMOINF-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMOINF situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CMOLAW [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

       dam rule CMOLAW-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a CMOLAW situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad M+  \
                    SFT quad S+

                coopslope $f $cov quad M+
            }
        }

        dam rule CMOLAW-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMOLAW situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT
            dam coop clear
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
    # with an activity of CMO_HEALTHCARE in a neighborhood.

    typemethod CMOMED {sit} {
        log detail actr [list CMOMED [$sit id]]

        set g            [$sit get g]
        set n            [$sit get n]
        set cov          [$sit get coverage]
        set stops        0
        set mitigating   0

        dam ruleset CMOMED [$sit get driver]                       \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CMOMED-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOMED $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
            }

            dam guard [format "%.2f %s" $cov $stops]

            # While there is a CMOMED situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad     [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops L+]

                coopslope $f $cov frmore [mag+ $stops L+]
            }
        }

        dam rule CMOMED-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMOMED situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CMOOTHER [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CMOOTHER-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOOTHER $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
            }

            dam guard [format "%.2f %s" $cov $stops]

            # While there is a CMOOTHER situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT quad     [mag+ $stops S+]  \
                    SFT constant [mag+ $stops S+]  \
                    CUL constant [mag+ $stops XS+] \
                    QOL constant [mag+ $stops L+]

                coopslope $f $cov frmore [mag+ $stops M+]
            }
        }

        dam rule CMOOTHER-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CMOOTHER situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset COERCION [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule COERCION-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a COERCION situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT enquad XL-  \
                    SFT enquad XXL- \
                    CUL enquad XS-  \
                    QOL enquad M-

                coopslope $f $cov enmore XXXL+
            }
        }

        dam rule COERCION-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a COERCION situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset CRIMINAL [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CRIMINAL-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a CRIMINAL situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT enquad L-  \
                    SFT enquad XL- \
                    QOL enquad L-
            }
        }

        dam rule CRIMINAL-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CRIMINAL situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT QOL
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

        dam ruleset CURFEW [$sit get driver]                       \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule CURFEW-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a CURFEW situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set rel [rel $n $f $g]

                if {$rel >= 0} {
                    # Friends
                    satslope $cov $f \
                        AUT constant S- \
                        SFT frquad   S+ \
                        CUL constant S- \
                        QOL constant S-
                } else {
                    # Enemies
                    
                    # NOTE: Because $rel < 0, and the expected RMF
                    # is "quad", the SFT input turns into a minus.
                    satslope $cov $f \
                        AUT constant S- \
                        SFT enquad   M- \
                        CUL constant S- \
                        QOL constant S-
                }

                coopslope $f $cov quad M+
            }
        }

        dam rule CURFEW-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a CURFEW situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset GUARD [$sit get driver]                        \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule GUARD-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a GUARD situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f  \
                    AUT enmore L- \
                    SFT enmore L- \
                    CUL enmore L- \
                    QOL enmore M-

                coopslope $f $cov quad S+
            }
        }

        dam rule GUARD-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a GUARD situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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

        dam ruleset PATROL [$sit get driver]                       \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule PATROL-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a PATROL situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f  \
                    AUT enmore M- \
                    SFT enmore M- \
                    CUL enmore S- \
                    QOL enmore L-

                coopslope $f $cov quad S+
            }
        }

        dam rule PATROL-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a PATROL situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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
        
        dam ruleset PSYOP [$sit get driver]                      \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule PSYOP-1-1 {
            $cov > 0.0
        } {
            dam guard [format %.2f $cov]

            # While there is a PSYOP situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                set rel [rel $n $f $g]

                if {$rel >= 0} {
                    # Friends
                    satslope $cov $f \
                        AUT constant S+ \
                        SFT constant S+ \
                        CUL constant S+ \
                        QOL constant S+
                } else {
                    # Enemies
                    satslope $cov $f \
                        AUT constant XS+ \
                        SFT constant XS+ \
                        CUL constant XS+ \
                        QOL constant XS+
                }


                coopslope $f $cov frmore XL+
            }
        }

        dam rule PSYOP-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a PSYOP situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
            dam coop clear
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
        set stops        0
 
        dam ruleset ORGCONST [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule ORGCONST-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGCONST $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr stops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            dam guard [format "%.2f %d" $cov $stops]

            # While there is a ORGCONST situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT constant [mag+ $stops S+]  \
                    SFT constant [mag+ $stops S+]  \
                    CUL constant [mag+ $stops XS+] \
                    QOL constant [mag+ $stops L+]
            }
        }

        dam rule ORGCONST-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a ORGCONST situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
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
        set stops        0

        dam ruleset ORGEDU [$sit get driver]                       \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule ORGEDU-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGEDU $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr stops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            dam guard [format "%.2f %d" $cov $stops]

            # While there is a ORGEDU situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT constant [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops L+]
            }
        }

        dam rule ORGEDU-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a ORGEDU situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
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
        set stops        0

        dam ruleset ORGEMP [$sit get driver]                       \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule ORGEMP-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGEMP $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr stops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }
            
            dam guard [format "%.2f %d" $cov $stops]

            # While there is a ORGEMP situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT constant [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops L+]
            }
        }

        dam rule ORGEMP-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a ORGEMP situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
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
        set stops        0

        dam ruleset ORGIND [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule ORGIND-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGIND $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr stops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            dam guard [format "%.2f %d" $cov $stops]

            # While there is a ORGIND situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT constant [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops L+]
            }
        }

        dam rule ORGIND-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a ORGIND situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
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
        set stops        0

        dam ruleset ORGINF [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule ORGINF-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGINF $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr stops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            dam guard [format "%.2f %d" $cov $stops]

            # While there is a ORGINF situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT constant [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops M+]
            }
        }

        dam rule ORGINF-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a ORGINF situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
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
        set stops        0

        dam ruleset ORGMED [$sit get driver]                     \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule ORGMED-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGMED $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr stops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            dam guard [format "%.2f %d" $cov $stops]

            # While there is a ORGMED situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT constant [mag+ $stops S+]   \
                    SFT constant [mag+ $stops XXS+] \
                    CUL constant [mag+ $stops XXS+] \
                    QOL constant [mag+ $stops L+]
            }
        }

        dam rule ORGMED-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a ORGMED situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
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
        set stops        0

        dam ruleset ORGOTHER [$sit get driver]                   \
            -sit       $sit                                        \
            -doer      $g                                          \
            -n         $n                                          \
            -f         [nbgroup gIn $n]

        detail "Nbhood Coverage:" [string trim [percent $cov]]

        dam rule ORGOTHER-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGOTHER $n]

            if {[llength $ensitsMitigated] > 0} {
                detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
            }

            # -1 stops if g's CAS=D.
            if {[orgsat $n $g CAS] eq "D"} {
                incr stops -1
                detail "Mood:" "$g is dissatisfied with its CAS concern"
            }

            dam guard [format "%.2f %d" $cov $stops]

            # While there is a ORGOTHER situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f [nbgroup gIn $n] {
                satslope $cov $f \
                    AUT constant [mag+ $stops S+]  \
                    SFT constant [mag+ $stops S+]  \
                    CUL constant [mag+ $stops XS+] \
                    QOL constant [mag+ $stops L+]
            }
        }

        dam rule ORGOTHER-2-1 {
            $cov == 0.0
        } {
            dam guard
            # While there is a ORGOTHER situation
            #     with COVERAGE = 0.0
            # Then for each CIV group in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
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
            WHERE n=$n AND f=$f AND g=$g
        }]

        require {[string is double -strict $rel]} \
            "Invalid group pair f=$f, g=$g"

        return $rel
    }

    # mitigates ruleset nbhood
    #
    # ruleset     A CIV or ORG activity rule set
    # nbhood      The affected nbhood
    #
    # Returns a list of the ensits present 
    # in nbhood which are mitigated by this rule set's activity.  
    # If none, returns the empty list.

    proc mitigates {ruleset nbhood} {
        # FIRST, get the mitigated ensits and form them into an 
        # "IN" list.  If none, just return immediately.
        set ensits [parmdb get dam.$ruleset.mitigates]

        if {[llength $ensits] == 0} {
            return {} 
        }

        set inList "('[join $ensits ',']')"

        # NEXT, check for active ensits, collecting the affected groups as
        # we go.
        return [rdb eval "
            SELECT stype FROM ensits
            WHERE n     = \$nbhood
            AND   state = 'ACTIVE'
            AND   stype IN $inList
        "]
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
            set sat [rdb eval {
                SELECT sat FROM gram_gc 
                WHERE g=$g AND c=$c
            }]
        } else {
            set sat [rdb eval {
                SELECT sat FROM gram_sat 
                WHERE n=$n AND g=$g AND c=$c
            }]
        }

        return [qsat name $sat]
    }
}








