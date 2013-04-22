#-----------------------------------------------------------------------
# TITLE:
#    driver_actsit.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Driver Assessment Model (DAM): Activity Situations
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# actsit: family ensemble

snit::type driver::actsit {
    # Make it an ensemble
    pragma -hasinstances 0

    #------------------------------------------------------------------
    # Public Typemethods

    # assess
    #
    # Assess all activities, and run the relevant rule sets as needed.
    # The rule set fdict is defined as follows:
    #
    #    dtype         - The driver type, as always
    #    n             - The nbhood in which the activity takes place
    #    g             - The group performing the activity (FRC or ORG)
    #    a             - The activity being performed
    #    personnel     - The number of effective personnel
    #    coverage      - The coverage fraction of the activity, > 0.0.
    #
    # The individual driver type can add the following fields to the fdict:
    #
    #    mitigates     - A list of ensit types actually being mitigated by
    #                    this activity.
    
    typemethod assess {} {
        # FIRST, find the activities with coverage greater than 0.
        rdb eval {
            SELECT stype        AS dtype,
                   n            AS n,
                   g            AS g,
                   effective    AS personnel,
                   coverage     AS coverage
            FROM activity_nga
            WHERE coverage > 0.0
        } {
            if {![dam isactive $dtype]} {
                log warning $dtype \
                    "driver type has been deactivated"
                continue
            }
            
            set fdict [dict create]
            dict set fdict dtype     $dtype
            dict set fdict n         $n
            dict set fdict g         $g
            dict set fdict personnel $personnel
            dict set fdict coverage  $coverage

            bgcatch {
                # Run the monitor rule set.
                driver::$dtype ruleset $fdict
            }
        }
    }

    #-------------------------------------------------------------------
    # Situation definition

    # define name defscript
    #
    # name        - The situation driver type name
    # defscript   - The definition script
    #
    # Defines a single situation driver type.  All required public
    # subcommands are defined automatically.  The driver type must
    # define the "ruleset" subcommand containing the actual rule set.
    #
    # Note that rule sets can make use of procs defined in the
    # driver::actsit namespace.

    typemethod define {name defscript} {
        # FIRST, define the shared definitions
        set footer "
            delegate typemethod sigline   using {driver::actsit %m $name}
            delegate typemethod narrative using {driver::actsit %m}
            delegate typemethod detail    using {driver::actsit %m}

            typeconstructor {
                namespace path ::driver::actsit::
            }
        "

        driver type define $name {n g} "$defscript\n$footer" 
    }

    #-------------------------------------------------------------------
    # Narrative Type Methods

    # sigline dtype signature
    #
    # dtype     - The driver type
    # signature - The driver signature, {n g}
    #
    # Returns a one-line description of the driver given its signature
    # values.

    typemethod sigline {dtype signature} {
        lassign $signature n g
        return "$g $dtype in $n"
    }

    # narrative fdict
    #
    # fdict - Firing dictionary; see [assess], above.
    #
    # Produces a one-line narrative text string for a given rule firing

    typemethod narrative {fdict} {
        dict with fdict {}

        set pcov [string trim [percent $coverage]]
        return "{group:$g} $dtype in {nbhood:$n} ($pcov)"
    }
    
    # detail fdict 
    #
    # fdict - Firing dictionary; see rulesets, below.
    # ht    - An htools(n) buffer
    #
    # Produces a narrative HTML paragraph including all fdict information.

    typemethod detail {fdict ht} {
        dict with fdict {}

        # FIRST, get the actual activity
        set a [rdb onecolumn {
            SELECT a FROM activity_gtype WHERE stype=$dtype LIMIT 1
        }]

        # NEXT, get the coverage function for that activity.
        set gtype [group gtype $g]
        lassign [parm get activity.$gtype.$a.coverage] P T

        # NEXT, produce the narrative detail.
        $ht putln "Group "
        $ht link my://app/group/$g $g
        $ht putln "is performing the $a activity"
        $ht putln "in neighborhood\n"
        $ht link my://app/nbhood/$n $n
        $ht putln "with $personnel effective personnel."
        $ht putln "yielding [string trim [percent $coverage]] coverage."
        $ht para

        if {[dict exists $fdict mitigates] && [llength $mitigates] > 0} {
            $ht putln "The activity is mitigating the following ensits:"
            $ht putln [join $mitigates ", "].
            $ht para
        }

 
        $ht putln "Note: The coverage function is $P/$T"
        $ht putln "(2/3rds coverage at $P personnel per $T in the population)."
        $ht para
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

    # mitigates fdictVar
    #
    # fdictVar    A variable containing the fdict.
    #
    # Sets fdict.mitigates to a list of the ensits present in the 
    # neighborhood that are mitigated by the current activity.
    # Returns 1 if there are any, and 0 otherwise.

    proc mitigates {fdictVar} {
        upvar 1 $fdictVar fdict

        set ruleset [dict get $fdict dtype]
        set n       [dict get $fdict n]

        # FIRST, get the mitigated ensits and form them into an 
        # "IN" list.  If none, just return immediately.
        set ensits [parmdb get dam.$ruleset.mitigates]

        if {[llength $ensits] == 0} {
            dict set fdict mitigates {}
            return 0
        }

        set inList "('[join $ensits ',']')"

        # NEXT, check for active ensits, collecting the affected groups as
        # we go.
        set elist [rdb eval "
            SELECT stype FROM ensits
            WHERE n     = \$n
            AND   state = 'ONGOING'
            AND   stype IN $inList
        "]

        dict set fdict mitigates $elist

        return [expr {[llength $elist] > 0}] 
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
# the civilian activity it models is obsolete.  Later on in
# Athena 5 development, it will become the starting point for a new 
# demsit rule set.

driver::actsit define DISPLACED {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail DISPLACED $fdict

        dam rule DISPLACED-1-1 $fdict {
            $coverage > 0.0
        } {
            satinput [demog gIn $n] $g $coverage ""  \
                    AUT enmore   S-   \
                    SFT enmore   L-   \
                    CUL enquad   S-   \
                    QOL constant M- 
        }
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
#
# TBD: This rule set is currently disabled.  In current use it has
# been shown to be too strong; moreover, it is focussed on foreign
# forces, and causes problems when used with local forces (i.e.,
# police).  We need to reconsider it.

driver::actsit define PRESENCE {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail PRESENCE $fdict

        dam rule PRESENCE-1-1 $fdict {
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

driver::actsit define CHKPOINT {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CHKPOINT $fdict

        dam rule CHKPOINT-1-1 $fdict {
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
}

#-------------------------------------------------------------------
# Rule Set: CMOCONST:  CMO -- Construction
#
# Activity Situation: Units belonging to a FRC group are 
# doing CMO_CONSTRUCTION in a neighborhood.

driver::actsit define CMOCONST {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMOCONST $fdict

        set mitigates [mitigates fdict]

        dam rule CMOCONST-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: CMODEV:  CMO -- Development (Light)
#
# Activity Situation: Units belonging to a force group are 
# encouraging light development in a neighborhood.

driver::actsit define CMODEV {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMODEV $fdict

        dam rule CMODEV-1-1 $fdict {
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
}

#-------------------------------------------------------------------
# Rule Set: CMOEDU:  CMO -- Education
#
# Activity Situation: Units belonging to a FRC group are 
# doing CMO_EDUCATION in a neighborhood.

driver::actsit define CMOEDU {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMOEDU $fdict

        set mitigates [mitigates fdict]

        dam rule CMOEDU-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: CMOEMP:  CMO -- Employment
#
# Activity Situation: Units belonging to a FRC group are 
# doing CMO_EMPLOYMENT in a neighborhood.

driver::actsit define CMOEMP {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMOEMP $fdict

        set mitigates [mitigates fdict]

        dam rule CMOEMP-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: CMOIND:  CMO -- Industry
#
# Activity Situation: Units belonging to a FRC group are 
# doing CMO_INDUSTRY in a neighborhood.

driver::actsit define CMOIND {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMOIND $fdict

        set mitigates [mitigates fdict]

        dam rule CMOIND-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: CMOINF:  CMO -- Infrastructure
#
# Activity Situation: Units belonging to a FRC group are 
# doing CMO_INFRASTRUCTURE in a neighborhood.

driver::actsit define CMOINF {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMOINF $fdict

        set mitigates [mitigates fdict]

        dam rule CMOINF-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: CMOLAW:  CMO -- Law Enforcement
#
# Activity Situation: Units belonging to a force group are 
# enforcing the law in a neighborhood.

driver::actsit define CMOLAW {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMOLAW $fdict

        dam rule CMOLAW-1-1 $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]
            
            satinput $flist $g $coverage "" \
                AUT quad M+  \
                SFT quad S+

            coopinput $flist $g $coverage quad M+
        }
    }
}

#-------------------------------------------------------------------
# Rule Set: CMOMED:  CMO -- Healthcare
#
# Activity Situation: Units belonging to a FRC group are 
# doing CMO_HEALTHCARE in a neighborhood.

driver::actsit define CMOMED {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMOMED $fdict

        set mitigates [mitigates fdict]

        dam rule CMOMED-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: CMOOTHER:  CMO -- Other
#
# Activity Situation: Units belonging to a CMO group are 
# doing CMO_OTHER in a neighborhood.

driver::actsit define CMOOTHER {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CMOOTHER $fdict

        set mitigates [mitigates fdict]

        dam rule CMOOTHER-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: COERCION:  Coercion
#
# Activity Situation: Units belonging to a force group are 
# coercing local civilians to cooperate with them through threats
# of violence.

driver::actsit define COERCION {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail COERCION $fdict

        dam rule COERCION-1-1 $fdict {
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
}


#-------------------------------------------------------------------
# Rule Set: CRIMINAL:  Criminal Activities
#
# Activity Situation: Units belonging to a force group are 
# engaging in criminal activities in a neighborhood.

driver::actsit define CRIMINAL {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CRIMINAL $fdict

        dam rule CRIMINAL-1-1 $fdict {
            $coverage > 0.0
        } {
            set flist [demog gIn $n]

            satinput $flist $g $coverage "" \
                AUT enquad L-  \
                SFT enquad XL- \
                QOL enquad L-
        }
    }
}

#-------------------------------------------------------------------
# Rule Set: CURFEW:  Curfew
#
# Activity Situation: Units belonging to a force group are 
# enforcing a curfew in a neighborhood.

driver::actsit define CURFEW {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CURFEW $fdict

        dam rule CURFEW-1-1 $fdict {
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
}

#-------------------------------------------------------------------
# Rule Set: GUARD:  Guard
#
# Activity Situation: Units belonging to a force group are 
# guarding sites in a neighborhood.

driver::actsit define GUARD {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail GUARD $fdict

        dam rule GUARD-1-1 $fdict {
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
}

    
#-------------------------------------------------------------------
# Rule Set: PATROL:  Patrol
#
# Activity Situation: Units belonging to a force group are 
# patrolling a neighborhood.

driver::actsit define PATROL {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail PATROL $fdict

        dam rule PATROL-1-1 $fdict {
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
}

#-------------------------------------------------------------------
# Rule Set: PSYOP:  Psychological Operations
#
# Activity Situation: Units belonging to a force group are 
# doing PSYOP in a neighborhood.

driver::actsit define PSYOP {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail PSYOP $fdict
        
        dam rule PSYOP-1-1 $fdict {
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

driver::actsit define ORGCONST {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail ORGCONST $fdict

        set mitigates [mitigates fdict]

        dam rule ORGCONST-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: ORGEDU:  CMO -- Education
#
# Activity Situation: Units belonging to an ORG group are 
# doing CMO_EDUCATION in a neighborhood.

driver::actsit define ORGEDU {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail ORGEDU $fdict

        set mitigates [mitigates fdict]

        dam rule ORGEDU-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: ORGEMP:  CMO -- Employment
#
# Activity Situation: Units belonging to an ORG group are 
# doing CMO_EMPLOYMENT in a neighborhood.

driver::actsit define ORGEMP {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail ORGEMP $fdict

        set mitigates [mitigates fdict]

        dam rule ORGEMP-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: ORGIND:  CMO -- Industry
#
# Activity Situation: Units belonging to an ORG group are 
# doing CMO_INDUSTRY in a neighborhood.

driver::actsit define ORGIND {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail ORGIND $fdict

        set mitigates [mitigates fdict]

        dam rule ORGIND-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: ORGINF:  CMO -- Infrastructure
#
# Activity Situation: Units belonging to an ORG group are 
# doing CMO_INFRASTRUCTURE in a neighborhood.

driver::actsit define ORGINF {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail ORGINF $fdict

        set mitigates [mitigates fdict]

        dam rule ORGINF-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: ORGMED:  CMO -- Healthcare
#
# Activity Situation: Units belonging to an ORG group are 
# doing CMO_HEALTHCARE in a neighborhood.

driver::actsit define ORGMED {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail ORGMED $fdict

        set mitigates [mitigates fdict]

        dam rule ORGMED-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}

#-------------------------------------------------------------------
# Rule Set: ORGOTHER:  CMO -- Other
#
# Activity Situation: Units belonging to an ORG group are 
# doing CMO_OTHER in a neighborhood.

driver::actsit define ORGOTHER {
    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail ORGOTHER $fdict

        set mitigates [mitigates fdict]

        dam rule ORGOTHER-1-1 $fdict {
            $coverage > 0.0
        } {
            # +1 stops if g is mitigating a situation for any f
            set flist           [demog gIn $n]
            set stops           0

            if {$mitigates} {
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
}



