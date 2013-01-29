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

    #------------------------------------------------------------------
    # Public Typemethods

    # assess
    #
    # Assess all activities, and run the relevant rule sets as needed.
    
    typemethod assess {} {
        # FIRST, find the activities with coverage greater than 0.
        rdb eval {
            SELECT stype AS ruleset,
                   n,
                   g,
                   coverage
            FROM activity_nga
            WHERE coverage > 0.0
        } row {
            unset -nocomplain row(*)
            
            set sit [array get row]
            dict with sit {}
    
            if {![dam isactive $ruleset]} {
                log warning actr \
                    "monitor $ruleset: ruleset has been deactivated"
                return
            }
            
            set oneliner "$g $ruleset in $n"
            set signature [list $n $g]
            
            dict set sit driver_id \
                [driver create $ruleset $oneliner $signature]
    
            bgcatch {
                # Run the monitor rule set.
                actsit_rules $ruleset $sit
            }
        }
    }

    #-------------------------------------------------------------------
    # Rule Set Tools

    # satinput flist g cov note con rmf mag ?con rmf mag...?
    #
    # flist    - The affected group(s)
    # g        - The doing group
    # cov      - The coverage fraction
    # note     - A brief descriptive note
    # con      - The affected concern
    # rmf      - The RMF to apply
    # mag      - The nominal magnitude
    #
    # Enters satisfaction inputs.

    proc satinput {flist g cov note args} {
        set nomCov [parmdb get dam.actsit.nominalCoverage]

        assert {[llength $args] != 0 && [llength $args] % 3 == 0}

        foreach f $flist {
            set hrel [hrel.fg $f $g]

            set result [list]

            foreach {con rmf mag} $args {
                let mult {[rmf $rmf $hrel] * $cov / $nomCov}
                
                lappend result $con [mag* $mult $mag]
            }
            
            dam sat T $f {*}$result $note
        }
    }


    # coopinput flist g cov rmf mag note
    #
    # flist    - The affected CIV groups
    # g        - The acting force group
    # cov      - The coverage fraction
    # rmf      - The RMF to apply
    # mag      - The nominal slope
    # note     - A brief descriptive note
    #
    # Enters cooperation inputs.

    proc coopinput {flist g cov rmf mag {note ""}} {
        set ruleset [dam get ruleset]
        set nomCov  [parmdb get dam.actsit.nominalCoverage]

        foreach f $flist {
            set hrel [hrel.fg $f $g]

            let mult {[rmf $rmf $hrel] * $cov / $nomCov}
        
            dam coop T $f $g [mag* $mult $mag] $note
        }
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
    #
    # TBD: This rule set has been marked inactive in parmdb(5);
    # the civilian activity it models is obsolete.  Later in
    # Later in Athena 5 development, it will become the basis
    # for a new demsit rule set.
    
    # DISPLACED sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring civilian units
    # with an activity of DISPLACED in a neighborhood.

    typemethod DISPLACED {sit} {
        log detail actr [list DISPLACED [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]

        dam ruleset DISPLACED [dict get $sit driver_id]

        dam detail "Civ. Group:"    $g
        dam detail "Displaced in:"  $n
        dam detail "Coverage:"      [string trim [percent $cov]]

        dam rule DISPLACED-1-1 {
            $cov > 0.0
        } {
            # While there is a DISPLACED situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput [demog gIn $n] $g $cov ""  \
                    AUT enmore   S-   \
                    SFT enmore   L-   \
                    CUL enquad   S-   \
                    QOL constant M- 
        }
    }


    #===================================================================
    # Explicit Force Situations
    #
    # The following rule sets are for situations which do not depend
    # on the unit's stated ACTIVITY.

    proc frcdetails {sit} {
        dam detail "Force Group:"   [dict get $sit g]
        dam detail "Acting In:"     [dict get $sit n]
        dam detail "With Coverage:" \
            [string trim [percent [dict get $sit coverage]]]
    }

    #-------------------------------------------------------------------
    # Rule Set: PRESENCE:  Mere Presence of Force Units
    #
    # Activity Situation: This rule set determines the effect of the 
    # presence of force units on the local population.

    # PRESENCE sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring the PRESENCE of a force
    # group's units in a neighborhood.

    typemethod PRESENCE {sit} {
        log detail actr [list PRESENCE [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset PRESENCE [dict get $sit driver_id]
        
        frcdetails $sit

        dam rule PRESENCE-1-1 {
            $cov > 0.0
        } {
            # While there is a PRESENCE situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov "" \
                AUT quad XXS+ \
                SFT quad XXS+ \
                QOL quad XXS+

            coopinput $flist $g $cov quad XXS+
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
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CHECKPOINT in a neighborhood.

    typemethod CHKPOINT {sit} {
        log detail actr [list CHKPOINT [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset CHKPOINT [dict get $sit driver_id]

        frcdetails $sit

        dam rule CHKPOINT-1-1 {
            $cov > 0.0
        } {
            # While there is a CHKPOINT situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f $flist {
                set hrel [hrel.fg $f $g]

                if {$hrel >= 0} {
                    # FRIENDS
                    satinput $f $g $cov "friends" \
                        AUT quad     S+   \
                        SFT quad     S+   \
                        CUL constant XXS- \
                        QOL constant XS- 
                } elseif {$hrel < 0} {
                    # ENEMIES
                    # Note: RMF=quad for AUT, SFT, which will
                    # reverse the sign in this case.
                    satinput $f $g $cov "enemies" \
                        AUT quad     S+  \
                        SFT quad     S+  \
                        CUL constant S-  \
                        QOL constant S-
                }
            }

            coopinput $flist $g $cov quad XXXS+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOCONST:  CMO -- Construction
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_CONSTRUCTION in a neighborhood.

    # CMOCONST sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOCONST in a neighborhood.

    typemethod CMOCONST {sit} {
        log detail actr [list CMOCONST [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset CMOCONST [dict get $sit driver_id]

        frcdetails $sit

        dam rule CMOCONST-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOCONST $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a CMOCONST situation
            #     with COVERAGE > 0.0
            # For each CIV group f in the nbhood,
            satinput $flist $g $cov $note      \
                AUT quad     [mag+ $stops S+]  \
                SFT constant [mag+ $stops S+]  \
                CUL constant [mag+ $stops XS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $cov frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMODEV:  CMO -- Development (Light)
    #
    # Activity Situation: Units belonging to a force group are 
    # encouraging light development in a neighborhood.

    # CMODEV sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CMO_DEVELOPMENT in a neighborhood.

    typemethod CMODEV {sit} {
        log detail actr [list CMODEV [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset CMODEV [dict get $sit driver_id]

        frcdetails $sit

        dam rule CMODEV-1-1 {
            $cov > 0.0
        } {
            # While there is a CMODEV situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov "" \
                AUT quad M+   \
                SFT quad S+   \
                CUL quad S+   \
                QOL quad L+

            coopinput $flist $g $cov frmore M+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOEDU:  CMO -- Education
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_EDUCATION in a neighborhood.

    # CMOEDU sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOEDU in a neighborhood.

    typemethod CMOEDU {sit} {
        log detail actr [list CMOEDU [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset CMOEDU [dict get $sit driver_id]

        frcdetails $sit

        dam rule CMOEDU-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOEDU $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a CMOEDU situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov "$note" \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL quad     [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $cov frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOEMP:  CMO -- Employment
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_EMPLOYMENT in a neighborhood.

    # CMOEMP sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOEMP in a neighborhood.

    typemethod CMOEMP {sit} {
        log detail actr [list CMOEMP [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset CMOEMP [dict get $sit driver_id]

        frcdetails $sit

        dam rule CMOEMP-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOEMP $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a CMOEMP situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $cov frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOIND:  CMO -- Industry
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_INDUSTRY in a neighborhood.

    # CMOIND sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOIND in a neighborhood.

    typemethod CMOIND {sit} {
        log detail actr [list CMOIND [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset CMOIND [dict get $sit driver_id]

        frcdetails $sit

        dam rule CMOIND-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOIND $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a CMOIND situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $cov frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOINF:  CMO -- Infrastructure
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_INFRASTRUCTURE in a neighborhood.

    # CMOINF sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOINF in a neighborhood.

    typemethod CMOINF {sit} {
        log detail actr [list CMOINF [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset CMOINF [dict get $sit driver_id]

        frcdetails $sit

        dam rule CMOINF-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOINF $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a CMOINF situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops M+]

            coopinput $flist $g $cov frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOLAW:  CMO -- Law Enforcement
    #
    # Activity Situation: Units belonging to a force group are 
    # enforcing the law in a neighborhood.

    # CMOLAW sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CMO_LAW_ENFORCEMENT in a neighborhood.

    typemethod CMOLAW {sit} {
        log detail actr [list CMOLAW [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset CMOLAW [dict get $sit driver_id]

        frcdetails $sit

       dam rule CMOLAW-1-1 {
            $cov > 0.0
        } {
            # While there is a CMOLAW situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov "" \
                AUT quad M+  \
                SFT quad S+

            coopinput $flist $g $cov quad M+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOMED:  CMO -- Healthcare
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_HEALTHCARE in a neighborhood.

    # CMOMED sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMO_HEALTHCARE in a neighborhood.

    typemethod CMOMED {sit} {
        log detail actr [list CMOMED [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset CMOMED [dict get $sit driver_id]

        frcdetails $sit

        dam rule CMOMED-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOMED $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a CMOMED situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $cov frmore [mag+ $stops L+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOOTHER:  CMO -- Other
    #
    # Activity Situation: Units belonging to a CMO group are 
    # doing CMO_OTHER in a neighborhood.

    # CMOOTHER sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring FRC group units
    # with an activity of CMOOTHER in a neighborhood.

    typemethod CMOOTHER {sit} {
        log detail actr [list CMOOTHER [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset CMOOTHER [dict get $sit driver_id]

        frcdetails $sit

        dam rule CMOOTHER-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates CMOOTHER $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a CMOOTHER situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note      \
                AUT quad     [mag+ $stops S+]  \
                SFT constant [mag+ $stops S+]  \
                CUL constant [mag+ $stops XS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $cov frmore [mag+ $stops M+] $note
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
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of COERCION in a neighborhood.

    typemethod COERCION {sit} {
        log detail actr [list COERCION [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset COERCION [dict get $sit driver_id]

        frcdetails $sit

        dam rule COERCION-1-1 {
            $cov > 0.0
        } {
            # While there is a COERCION situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov "" \
                AUT enquad XL-  \
                SFT enquad XXL- \
                CUL enquad XS-  \
                QOL enquad M-

            coopinput $flist $g $cov enmore XXXL+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: CRIMINAL:  Criminal Activities
    #
    # Activity Situation: Units belonging to a force group are 
    # engaging in criminal activities in a neighborhood.

    # CRIMINAL sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CRIMINAL in a neighborhood.

    typemethod CRIMINAL {sit} {
        log detail actr [list CRIMINAL [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset CRIMINAL [dict get $sit driver_id]

        frcdetails $sit

        dam rule CRIMINAL-1-1 {
            $cov > 0.0
        } {
            # While there is a CRIMINAL situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov "" \
                AUT enquad L-  \
                SFT enquad XL- \
                QOL enquad L-
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CURFEW:  Curfew
    #
    # Activity Situation: Units belonging to a force group are 
    # enforcing a curfew in a neighborhood.

    # CURFEW sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of CURFEW in a neighborhood.

    typemethod CURFEW {sit} {
        log detail actr [list CURFEW [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset CURFEW [dict get $sit driver_id]

        frcdetails $sit

        dam rule CURFEW-1-1 {
            $cov > 0.0
        } {
            # While there is a CURFEW situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f $flist {
                set rel [hrel.fg $f $g]

                if {$rel >= 0} {
                    # Friends
                    satinput $f $g $cov "friends" \
                        AUT constant S- \
                        SFT frquad   S+ \
                        CUL constant S- \
                        QOL constant S-
                } else {
                    # Enemies
                    
                    # NOTE: Because $rel < 0, and the expected RMF
                    # is "quad", the SFT input turns into a minus.
                    satinput $f $g $cov "enemies" \
                        AUT constant S- \
                        SFT enquad   M- \
                        CUL constant S- \
                        QOL constant S-
                }
            }

            coopinput $flist $g $cov quad M+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: GUARD:  Guard
    #
    # Activity Situation: Units belonging to a force group are 
    # guarding sites in a neighborhood.

    # GUARD sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of GUARD in a neighborhood.

    typemethod GUARD {sit} {
        log detail actr [list GUARD [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset GUARD [dict get $sit driver_id]

        frcdetails $sit

        dam rule GUARD-1-1 {
            $cov > 0.0
        } {
            # While there is a GUARD situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov "" \
                AUT enmore L- \
                SFT enmore L- \
                CUL enmore L- \
                QOL enmore M-

            coopinput $flist $g $cov quad S+
        }
    }

    
    #-------------------------------------------------------------------
    # Rule Set: PATROL:  Patrol
    #
    # Activity Situation: Units belonging to a force group are 
    # patrolling a neighborhood.

    # PATROL sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of PATROL in a neighborhood.

    typemethod PATROL {sit} {
        log detail actr [list PATROL [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset PATROL [dict get $sit driver_id]

        frcdetails $sit

        dam rule PATROL-1-1 {
            $cov > 0.0
        } {
            # While there is a PATROL situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov "" \
                AUT enmore M- \
                SFT enmore M- \
                CUL enmore S- \
                QOL enmore L-

            coopinput $flist $g $cov quad S+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: PSYOP:  Psychological Operations
    #
    # Activity Situation: Units belonging to a force group are 
    # doing PSYOP in a neighborhood.

    # PSYOP sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring force group units
    # with an activity of PSYOP in a neighborhood.

    typemethod PSYOP {sit} {
        log detail actr [list PSYOP [dict get $sit driver_id]]

        set g     [dict get $sit g]
        set n     [dict get $sit n]
        set cov   [dict get $sit coverage]
        set flist [demog gIn $n]

        dam ruleset PSYOP [dict get $sit driver_id]

        frcdetails $sit

        dam rule PSYOP-1-1 {
            $cov > 0.0
        } {
            # While there is a PSYOP situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            foreach f $flist {
                set rel [hrel.fg $f $g]

                if {$rel >= 0} {
                    # Friends
                    satinput $f $g $cov "friends" \
                        AUT constant S+ \
                        SFT constant S+ \
                        CUL constant S+ \
                        QOL constant S+
                } else {
                    # Enemies
                    satinput $f $g $cov "enemies" \
                        AUT constant XS+ \
                        SFT constant XS+ \
                        CUL constant XS+ \
                        QOL constant XS+
                }
            }

            coopinput $flist $g $cov frmore XL+
        }
    }



    #===================================================================
    # ORG Activity Situations
    #
    # The following rule sets are for situations which depend
    # on the stated ACTIVITY of ORG units.

    proc orgdetails {sit} {
        dam detail "Org. Group:"    [dict get $sit g]
        dam detail "Acting In:"     [dict get $sit n]
        dam detail "With Coverage:" \
            [string trim [percent [dict get $sit coverage]]]
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGCONST:  CMO -- Construction
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_CONSTRUCTION in a neighborhood.

    # ORGCONST sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGCONST in a neighborhood.

    typemethod ORGCONST {sit} {
        log detail actr [list ORGCONST [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0
 
        dam ruleset ORGCONST [dict get $sit driver_id]

        orgdetails $sit

        dam rule ORGCONST-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGCONST $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a ORGCONST situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note      \
                AUT constant [mag+ $stops S+]  \
                SFT constant [mag+ $stops S+]  \
                CUL constant [mag+ $stops XS+] \
                QOL constant [mag+ $stops L+]
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGEDU:  CMO -- Education
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_EDUCATION in a neighborhood.

    # ORGEDU sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGEDU in a neighborhood.

    typemethod ORGEDU {sit} {
        log detail actr [list ORGEDU [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset ORGEDU [dict get $sit driver_id]

        orgdetails $sit

        dam rule ORGEDU-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGEDU $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a ORGEDU situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT constant [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGEMP:  CMO -- Employment
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_EMPLOYMENT in a neighborhood.

    # ORGEMP sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGEMP in a neighborhood.

    typemethod ORGEMP {sit} {
        log detail actr [list ORGEMP [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset ORGEMP [dict get $sit driver_id]

        orgdetails $sit

        dam rule ORGEMP-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGEMP $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a ORGEMP situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT constant [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGIND:  CMO -- Industry
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_INDUSTRY in a neighborhood.

    # ORGIND sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGIND in a neighborhood.

    typemethod ORGIND {sit} {
        log detail actr [list ORGIND [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset ORGIND [dict get $sit driver_id]

        orgdetails $sit

        dam rule ORGIND-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGIND $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a ORGIND situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT constant [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGINF:  CMO -- Infrastructure
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_INFRASTRUCTURE in a neighborhood.

    # ORGINF sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGINF in a neighborhood.

    typemethod ORGINF {sit} {
        log detail actr [list ORGINF [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset ORGINF [dict get $sit driver_id]

        orgdetails $sit

        dam rule ORGINF-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGINF $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a ORGINF situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT constant [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops M+]
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGMED:  CMO -- Healthcare
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_HEALTHCARE in a neighborhood.

    # ORGMED sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGMED in a neighborhood.

    typemethod ORGMED {sit} {
        log detail actr [list ORGMED [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset ORGMED [dict get $sit driver_id]

        orgdetails $sit

        dam rule ORGMED-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGMED $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a ORGMED situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note       \
                AUT constant [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: ORGOTHER:  CMO -- Other
    #
    # Activity Situation: Units belonging to an ORG group are 
    # doing CMO_OTHER in a neighborhood.

    # ORGOTHER sit
    #
    # sit       The actsit dict for this situation
    #
    # This method is called when monitoring ORG group units
    # with an activity of ORGOTHER in a neighborhood.

    typemethod ORGOTHER {sit} {
        log detail actr [list ORGOTHER [dict get $sit driver_id]]

        set g            [dict get $sit g]
        set n            [dict get $sit n]
        set cov          [dict get $sit coverage]
        set flist        [demog gIn $n]
        set stops        0

        dam ruleset ORGOTHER [dict get $sit driver_id]

        orgdetails $sit

        dam rule ORGOTHER-1-1 {
            $cov > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set ensitsMitigated [mitigates ORGOTHER $n]

            if {[llength $ensitsMitigated] > 0} {
                dam detail "Mitigates:"  [join $ensitsMitigated ", "]
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a ORGOTHER situation
            #     with COVERAGE > 0.0
            # Then for each CIV group f in the nbhood,
            satinput $flist $g $cov $note      \
                AUT constant [mag+ $stops S+]  \
                SFT constant [mag+ $stops S+]  \
                CUL constant [mag+ $stops XS+] \
                QOL constant [mag+ $stops L+]
        }
    }

    #-------------------------------------------------------------------
    # Utility Procs

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
}
