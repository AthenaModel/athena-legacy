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
        } {
            if {![dam isactive $ruleset]} {
                log warning actr \
                    "monitor $ruleset: ruleset has been deactivated"
                continue
            }
            
            set oneliner "$g $ruleset in $n"
            set signature [list $n $g]
            
            set driver_id [driver create $ruleset $oneliner $signature]
    
            set fdict [dict create n $n g $g coverage $coverage]            
            bgcatch {
                # Run the monitor rule set.
                actsit_rules $ruleset $driver_id $fdict
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
    
    typemethod DISPLACED {driver_id fdict} {
        dict with fdict {}
        log detail actr [list DISPLACED $driver_id]

        dam rule DISPLACED-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            satinput [demog gIn $n] $g $coverage ""  \
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

    #-------------------------------------------------------------------
    # Rule Set: PRESENCE:  Mere Presence of Force Units
    #
    # Activity Situation: This rule set determines the effect of the 
    # presence of force units on the local population.

    typemethod PRESENCE {driver_id fdict} {
        dict with fdict {}
        log detail actr [list PRESENCE $driver_id]

        dam rule PRESENCE-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]
            
            satinput $flist $g $coverage "" \
                AUT quad XXS+ \
                SFT quad XXS+ \
                QOL quad XXS+

            coopinput $flist $g $coverage quad XXS+
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

    typemethod CHKPOINT {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CHKPOINT $driver_id]

        dam rule CHKPOINT-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            foreach f $flist {
                set hrel [hrel.fg $f $g]

                if {$hrel >= 0} {
                    # FRIENDS
                    satinput $f $g $coverage "friends" \
                        AUT quad     S+   \
                        SFT quad     S+   \
                        CUL constant XXS- \
                        QOL constant XS- 
                } elseif {$hrel < 0} {
                    # ENEMIES
                    # Note: RMF=quad for AUT, SFT, which will
                    # reverse the sign in this case.
                    satinput $f $g $coverage "enemies" \
                        AUT quad     S+  \
                        SFT quad     S+  \
                        CUL constant S-  \
                        QOL constant S-
                }
            }

            coopinput $flist $g $coverage quad XXXS+
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

    typemethod CMOCONST {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMOCONST $driver_id]

        dam rule CMOCONST-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates CMOCONST $n]

            if {[llength $ensitsMitigated] > 0} {
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            # While there is a CMOCONST situation
            #     with COVERAGE > 0.0
            # For each CIV group f in the nbhood,
            satinput $flist $g $coverage $note      \
                AUT quad     [mag+ $stops S+]  \
                SFT constant [mag+ $stops S+]  \
                CUL constant [mag+ $stops XS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $coverage frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMODEV:  CMO -- Development (Light)
    #
    # Activity Situation: Units belonging to a force group are 
    # encouraging light development in a neighborhood.

    typemethod CMODEV {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMODEV $driver_id]

        dam rule CMODEV-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            satinput $flist $g $coverage "" \
                AUT quad M+   \
                SFT quad S+   \
                CUL quad S+   \
                QOL quad L+

            coopinput $flist $g $coverage frmore M+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOEDU:  CMO -- Education
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_EDUCATION in a neighborhood.

    typemethod CMOEDU {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMOEDU $driver_id]

        dam rule CMOEDU-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates CMOEDU $n]

            if {[llength $ensitsMitigated] > 0} {
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage "$note" \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL quad     [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $coverage frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOEMP:  CMO -- Employment
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_EMPLOYMENT in a neighborhood.

    typemethod CMOEMP {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMOEMP $driver_id]

        dam rule CMOEMP-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates CMOEMP $n]

            if {[llength $ensitsMitigated] > 0} {
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $coverage frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOIND:  CMO -- Industry
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_INDUSTRY in a neighborhood.

    typemethod CMOIND {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMOIND $driver_id]

        dam rule CMOIND-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates CMOIND $n]

            if {[llength $ensitsMitigated] > 0} {
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $coverage frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOINF:  CMO -- Infrastructure
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_INFRASTRUCTURE in a neighborhood.

    typemethod CMOINF {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMOINF $driver_id]

        dam rule CMOINF-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates CMOINF $n]

            if {[llength $ensitsMitigated] > 0} {
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                CUL constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops M+]

            coopinput $flist $g $coverage frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOLAW:  CMO -- Law Enforcement
    #
    # Activity Situation: Units belonging to a force group are 
    # enforcing the law in a neighborhood.

    typemethod CMOLAW {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMOLAW $driver_id]

        dam rule CMOLAW-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]
            
            satinput $flist $g $coverage "" \
                AUT quad M+  \
                SFT quad S+

            coopinput $flist $g $coverage quad M+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOMED:  CMO -- Healthcare
    #
    # Activity Situation: Units belonging to a FRC group are 
    # doing CMO_HEALTHCARE in a neighborhood.

    typemethod CMOMED {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMOMED $driver_id]

        dam rule CMOMED-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates CMOMED $n]

            if {[llength $ensitsMitigated] > 0} {
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
                AUT quad     [mag+ $stops S+]   \
                SFT constant [mag+ $stops XXS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $coverage frmore [mag+ $stops L+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: CMOOTHER:  CMO -- Other
    #
    # Activity Situation: Units belonging to a CMO group are 
    # doing CMO_OTHER in a neighborhood.

    typemethod CMOOTHER {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CMOOTHER $driver_id]

        dam rule CMOOTHER-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates CMOOTHER $n]

            if {[llength $ensitsMitigated] > 0} {
                set stops 1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note      \
                AUT quad     [mag+ $stops S+]  \
                SFT constant [mag+ $stops S+]  \
                CUL constant [mag+ $stops XS+] \
                QOL constant [mag+ $stops L+]

            coopinput $flist $g $coverage frmore [mag+ $stops M+] $note
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: COERCION:  Coercion
    #
    # Activity Situation: Units belonging to a force group are 
    # coercing local civilians to cooperate with them through threats
    # of violence.

    typemethod COERCION {driver_id fdict} {
        dict with fdict {}
        log detail actr [list COERCION $driver_id]

        dam rule COERCION-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            satinput $flist $g $coverage "" \
                AUT enquad XL-  \
                SFT enquad XXL- \
                CUL enquad XS-  \
                QOL enquad M-

            coopinput $flist $g $coverage enmore XXXL+
        }
    }


    #-------------------------------------------------------------------
    # Rule Set: CRIMINAL:  Criminal Activities
    #
    # Activity Situation: Units belonging to a force group are 
    # engaging in criminal activities in a neighborhood.

    typemethod CRIMINAL {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CRIMINAL $driver_id]

        dam rule CRIMINAL-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            satinput $flist $g $coverage "" \
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

    typemethod CURFEW {driver_id fdict} {
        dict with fdict {}
        log detail actr [list CURFEW $driver_id]

        dam rule CURFEW-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            foreach f $flist {
                set rel [hrel.fg $f $g]

                if {$rel >= 0} {
                    # Friends
                    satinput $f $g $coverage "friends" \
                        AUT constant S- \
                        SFT frquad   S+ \
                        CUL constant S- \
                        QOL constant S-
                } else {
                    # Enemies
                    
                    # NOTE: Because $rel < 0, and the expected RMF
                    # is "quad", the SFT input turns into a minus.
                    satinput $f $g $coverage "enemies" \
                        AUT constant S- \
                        SFT enquad   M- \
                        CUL constant S- \
                        QOL constant S-
                }
            }

            coopinput $flist $g $coverage quad M+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: GUARD:  Guard
    #
    # Activity Situation: Units belonging to a force group are 
    # guarding sites in a neighborhood.

    typemethod GUARD {driver_id fdict} {
        dict with fdict {}
        log detail actr [list GUARD $driver_id]

        dam rule GUARD-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            satinput $flist $g $coverage "" \
                AUT enmore L- \
                SFT enmore L- \
                CUL enmore L- \
                QOL enmore M-

            coopinput $flist $g $coverage quad S+
        }
    }

    
    #-------------------------------------------------------------------
    # Rule Set: PATROL:  Patrol
    #
    # Activity Situation: Units belonging to a force group are 
    # patrolling a neighborhood.

    typemethod PATROL {driver_id fdict} {
        dict with fdict {}
        log detail actr [list PATROL $driver_id]

        dam rule PATROL-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            satinput $flist $g $coverage "" \
                AUT enmore M- \
                SFT enmore M- \
                CUL enmore S- \
                QOL enmore L-

            coopinput $flist $g $coverage quad S+
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: PSYOP:  Psychological Operations
    #
    # Activity Situation: Units belonging to a force group are 
    # doing PSYOP in a neighborhood.

    typemethod PSYOP {driver_id fdict} {
        dict with fdict {}
        log detail actr [list PSYOP $driver_id]
        
        dam rule PSYOP-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            foreach f $flist {
                set rel [hrel.fg $f $g]

                if {$rel >= 0} {
                    # Friends
                    satinput $f $g $coverage "friends" \
                        AUT constant S+ \
                        SFT constant S+ \
                        CUL constant S+ \
                        QOL constant S+
                } else {
                    # Enemies
                    satinput $f $g $coverage "enemies" \
                        AUT constant XS+ \
                        SFT constant XS+ \
                        CUL constant XS+ \
                        QOL constant XS+
                }
            }

            coopinput $flist $g $coverage frmore XL+
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

    typemethod ORGCONST {driver_id fdict} {
        dict with fdict {}
        log detail actr [list ORGCONST $driver_id]

        dam rule ORGCONST-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates ORGCONST $n]

            if {[llength $ensitsMitigated] > 0} {
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note      \
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

    typemethod ORGEDU {driver_id fdict} {
        dict with fdict {}
        log detail actr [list ORGEDU $driver_id]

        dam rule ORGEDU-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates ORGEDU $n]

            if {[llength $ensitsMitigated] > 0} {
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
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

    typemethod ORGEMP {driver_id fdict} {
        dict with fdict {}
        log detail actr [list ORGEMP $driver_id]

        dam rule ORGEMP-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates ORGEMP $n]

            if {[llength $ensitsMitigated] > 0} {
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
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

    typemethod ORGIND {driver_id fdict} {
        dict with fdict {}
        log detail actr [list ORGIND $driver_id]

        dam rule ORGIND-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates ORGIND $n]

            if {[llength $ensitsMitigated] > 0} {
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
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

    typemethod ORGINF {driver_id fdict} {
        dict with fdict {}
        log detail actr [list ORGINF $driver_id]

        dam rule ORGINF-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates ORGINF $n]

            if {[llength $ensitsMitigated] > 0} {
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
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

    typemethod ORGMED {driver_id fdict} {
        dict with fdict {}
        log detail actr [list ORGMED $driver_id]

        dam rule ORGMED-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates ORGMED $n]

            if {[llength $ensitsMitigated] > 0} {
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note       \
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

    typemethod ORGOTHER {driver_id fdict} {
        dict with fdict {}
        log detail actr [list ORGOTHER $driver_id]

        dam rule ORGOTHER-1-1 $driver_id $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0
            set ensitsMitigated [mitigates ORGOTHER $n]

            if {[llength $ensitsMitigated] > 0} {
                incr stops +1
                set note "mitigates"
            } else {
                set note ""
            }

            satinput $flist $g $coverage $note      \
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
