#-----------------------------------------------------------------------
# TITLE:
#    aam.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Athena Attrition Model
#
#    This module is responsible for computing and applying attritions
#    to units and neighborhood groups.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module Singleton

snit::type aam {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Attrition Assessment

    # assess
    #
    # This routine is to be called every aam.ticksPerTock to do the 
    # attrition assessment.

    typemethod assess {} {
        log normal aam "assess"

        # FIRST, Clear the pending attrition data, if any.
        rdb eval {
            DELETE FROM aam_pending_nf;
            DELETE FROM aam_pending_n;
        }

        # NEXT, compute all normal attrition for this interval,
        # and then apply it all at once.
        $type UFvsNF
        $type NFvsUF
        $type ApplyAttrition

        # NEXT, assess the attitude implications of all normal
        # and magic attrition for this interval.
        $type AssessAttitudeImplications
        $type ClearAttitudeStatistics
    }

    # ApplyAttrition
    #
    # Applies the attrition accumulated by the normal attrition
    # algorithms.

    typemethod ApplyAttrition {} {
        # FIRST, apply the force group attrition
        rdb eval {
            SELECT n, 
                   f, 
                   total(casualties) AS casualties,
                   ''                AS g1,
                   ''                AS g2
            FROM aam_pending_nf
            GROUP BY n,f
        } row {
            $type mutate attritnf [array get row]
        }


        # NEXT, apply the collateral damage.
        rdb eval {
            SELECT n,
                   casualties,
                   attacker    AS g1,
                   defender    AS g2
            FROM aam_pending_n
        } row {
            $type mutate attritn [array get row]
        }
    }

    # AssessAttitudeImplications
    #
    # Assess the satisfaction and cooperation implications of all
    # magic and normal attrition for this attrition interval.

    typemethod AssessAttitudeImplications {} {
        # FIRST, assess the satisfaction implications
        rdb eval {
            SELECT n,
                   f,
                   gtype,
                   total(casualties) AS casualties
            FROM attrit_nf
            JOIN groups ON attrit_nf.f = groups.g
            GROUP BY n,f
        } row {
            unset -nocomplain row(*)

            # TBD: Consider defining a driver -name, using some kind of
            # serial number, e.g., "Evt 1" or "Att 1" or "AAM 1"
            set row(driver) \
                [aram driver add      \
                     -dtype    CIVCAS \
                     -oneliner "Casualties to nbhood group $row(n) $row(f)"]

            set driver([list $row(n) $row(f)]) $row(driver)
            aam_rules civsat [array get row]
        }

        # NEXT, assess the cooperation implications
        rdb eval {
            SELECT n,
                   f,
                   g,
                   total(casualties) AS casualties
            FROM attrit_nfg
            GROUP BY n,f,g
        } row {
            unset -nocomplain row(*)

            # Use the same driver as for the satisfaction effects.
            set row(driver) $driver([list $row(n) $row(f)])

            aam_rules civcoop [array get row]
        }
    }

    # ClearAttitudeStatistics
    #
    # Clears the tables used to store attrition for use in
    # assessing attitudinal effects.

    typemethod ClearAttitudeStatistics {} {
        # FIRST, clear the accumulated attrition statistics, in preparation
        # for the next tock.
        rdb eval {
            DELETE FROM attrit_nf;
            DELETE FROM attrit_nfg;
        }
    }

    #-------------------------------------------------------------------
    # UF vs. NF Attrition

    # UFvsNF
    #
    # Computes the attrition, if any, due to Uniformed Force attacks
    # on Non-uniformed Force personnel.

    typemethod UFvsNF {} {
        # FIRST, get the relevant parameter values
        set deltaT    [simclock toDays [parmdb get aam.ticksPerTock]]
        set ufCovFunc [parmdb get aam.UFvsNF.UF.coverageFunction]
        set ufCovNom  [parmdb get aam.UFvsNF.UF.nominalCoverage]
        set ufCoopNom [parmdb get aam.UFvsNF.UF.nominalCooperation]
        set nfCovFunc [parmdb get aam.UFvsNF.NF.coverageFunction]
        set nfCovNom  [parmdb get aam.UFvsNF.NF.nominalCoverage]
        set tf        [parmdb get aam.UFvsNF.UF.timeToFind]
        set cellSize  [parmdb get aam.UFvsNF.NF.cellSize]

        # NEXT, step over all attacking ROEs.
        rdb eval {
            SELECT A.n                       AS n,
                   A.f                       AS uf, 
                   A.g                       AS nf,
                   A.cooplimit               AS coopLimit,
                   N.urbanization            AS urbanization,
                   DN.population             AS pop,
                   UP.personnel              AS ufPersonnel,
                   UC.coop                   AS ufCoop,
                   NP.personnel              AS nfPersonnel,
                   NC.coop                   AS nfCoop
            FROM attroe_nfg    AS A
            JOIN nbhoods       AS N  ON (N.n  = A.n)
            JOIN demog_n       AS DN ON (DN.n = A.n)
            JOIN force_ng      AS UP ON (UP.n = A.n AND UP.g = A.f)
            JOIN gram_frc_ng   AS UC ON (UC.n = A.n AND UC.g = A.f)
            JOIN force_ng      AS NP ON (NP.n = A.n AND NP.g = A.g)
            JOIN gram_frc_ng   AS NC ON (NC.n = A.n AND NC.g = A.g)
            WHERE A.uniformed =  1
            AND   A.roe       =  'ATTACK'
        } {
            # FIRST, if the attack cannot be carried out, log it.
            set prefix "no $uf attacks on $nf in $n:"

            if {$ufPersonnel == 0} {
                log detail aam "$prefix No $uf personnel in $n"
                continue
            } elseif {$nfPersonnel == 0} {
                log detail aam "$prefix No $nf personnel in $n"
                continue
            } elseif {$ufCoop < $coopLimit} {
                log detail aam "$prefix $n coop with $uf < $coopLimit"
                continue
            }

            # NEXT, the attack occurs.  Get the coverage fractions.
            set ufCov     [coverage eval $ufCovFunc $ufPersonnel $pop]
            set nfCov     [coverage eval $nfCovFunc $nfPersonnel $pop]

            # NEXT, compute the possible number of attacks:
            let Np { 
                round( ($ufCoop           * $ufCov    * $nfCov    * $deltaT)/
                       (max($nfCoop,10.0) * $ufCovNom * $nfCovNom * $tf ) )
            }

            if {$Np == 0} {
                log detail aam \
                  "$prefix UF can't find NF"
                continue
            }

            # NEXT, compute the actual number of attacks
            
            # Number of NF cells
            let Ncells { ceil(double($nfPersonnel) / $cellSize) }

            # Each attack kills an entire cell
            let Na { entier(min($Np, $Ncells)) }

            # Number of NF troops killed
            let Nkilled { min($Na * $cellSize, $nfPersonnel) }

            rdb eval {
                INSERT INTO aam_pending_nf(n,f,casualties)
                VALUES($n,$nf,$Nkilled);
            }

            # NEXT, compute the collateral damage.  Get the ECDA.
            set ecda [parmdb get aam.UFvsNF.ECDA.$urbanization]

            let Ncivcas {
                entier( $Na * $ecda * $ufCoopNom / max($ufCoop, 10.0))
            }

            if {$Ncivcas > 0} {
                rdb eval {
                    INSERT INTO aam_pending_n(n,attacker,defender,casualties)
                    VALUES($n,$uf,$nf,$Ncivcas);
                }
            }

            # NEXT, log the results
            log normal aam \
                "UF $uf attacks NF $nf in $n: NF $Nkilled CIV $Ncivcas"
            log detail aam [tsubst {
                |<--
                UF $uf attacks NF $nf in $n:
                    coopLimit:    $coopLimit
                    urbanization: $urbanization
                    pop:          $pop
                    ufPersonnel:  $ufPersonnel
                    ufCov         $ufCov
                    ufCoop:       $ufCoop
                    nfPersonnel:  $nfPersonnel
                    nfCov         $nfCov
                    nfCoop:       $nfCoop
                    Np:           $Np
                    Ncells:       $Ncells
                    Na:           $Na
            }]

        }
    }

    #-------------------------------------------------------------------
    # NF vs. UF Attrition

    # NFvsUF
    #
    # Computes the attrition, if any, due to Non-uniformed Force attacks
    # on Uniformed Force personnel.

    typemethod NFvsUF {} {
        # FIRST, get the relevant constant parameter values
        set deltaT    [simclock toDays [parmdb get aam.ticksPerTock]]
        set ufCovFunc [parmdb get aam.NFvsUF.UF.coverageFunction]
        set ufCovNom  [parmdb get aam.NFvsUF.UF.nominalCoverage]

        # NEXT, step over all attacking ROEs, gathering the related
        # data as needed.
        rdb eval {
            SELECT A.n                             AS n,
                   A.f                             AS nf,
                   A.g                             AS uf,
                   A.roe                           AS nfRoe,
                   A.cooplimit                     AS coopLimit,
                   A.rate                          AS rate,
                   N.urbanization                  AS urbanization,
                   DN.population                   AS pop,
                   NP.personnel                    AS nfPersonnel,
                   NC.coop                         AS nfCoop,
                   UP.personnel                    AS ufPersonnel,
                   UP.security                     AS ufSecurity,
                   UC.coop                         AS ufCoop,
                   UD.roe                          AS ufRoe
            FROM attroe_nfg     AS A
            JOIN nbhoods        AS N  ON (N.n = A.n)
            JOIN demog_n        AS DN ON (DN.n = A.n)
            JOIN force_ng       AS NP ON (NP.n = A.n AND NP.g = A.f)
            JOIN gram_frc_ng    AS NC ON (NC.n = A.n AND NC.g = A.f)
            JOIN force_ng       AS UP ON (UP.n = A.n AND UP.g = A.g)
            JOIN gram_frc_ng    AS UC ON (UC.n = A.n AND UC.g = A.g)
            JOIN defroe_ng      AS UD ON (UD.n = A.n AND UD.g = A.g)
            WHERE A.uniformed =  0
            AND   A.roe       != 'DO_NOT_ATTACK'
        } {
            # FIRST, if the attack cannot be carried out, log it.
            set prefix "no $nf attacks on $uf in $n:"

            if {$nfPersonnel == 0} {
                log detail aam "$prefix No $nf personnel in $n"
                continue
            } elseif {$ufPersonnel == 0} {
                log detail aam "$prefix No $uf personnel in $n"
                continue
            } elseif {$nfCoop < $coopLimit} {
                log detail aam "$prefix $n coop with $nf < $coopLimit"
                continue
            }

            # NEXT, get the UF coverage
            set ufCov     [coverage eval $ufCovFunc $ufPersonnel $pop]

            # NEXT, get the NF parameters that depend on ROE
            set nfCoopNom [parmdb get aam.NFvsUF.$nfRoe.nominalCooperation]
            set ELER      [parmdb get aam.NFvsUF.$nfRoe.ELER]
            set MAXLER    [parmdb get aam.NFvsUF.$nfRoe.MAXLER]

            # NEXT, compute the potential number of attacks:
            let Np { 
                round( 
                 ($rate * (100 - $ufSecurity) * $nfCoop    * $ufCov * $deltaT)
                 / (             100          * $nfCoopNom * $ufCovNom))
            }

            if {$Np == 0} {
                log detail aam \
                  "$prefix $nf has no $uf target opportunities"
                continue
            }

            # NEXT, compute loss exchange rate, and determine whether
            # the NF is willing to attack.
            
            let ler {
                $ELER * $ufCoop / max($nfCoop,10.0)
            }

            if {$ler > $MAXLER} {
                log detail aam \
                    "$prefix LER [format %.2f $ler] exceeds MAXLER $MAXLER"
                continue
            }

            # NEXT, The number of casualties per attack depends on 
            # the NF's attacking ROE.
            if {$nfRoe eq "HIT_AND_RUN"} {
                set ufCas [parmdb get aam.NFvsUF.HIT_AND_RUN.ufCasualties]
                
                let nfCas {$ufCas * $ler}
            } elseif {$nfRoe eq "STAND_AND_FIGHT"} {
                set nfCas [parmdb get aam.NFvsUF.STAND_AND_FIGHT.nfCasualties]

                let ufCas {$nfCas / max($ler,0.01)}
            } else {
                error "Unknown ROE: \"$roe\""
            }

            # NEXT, compute the actual number of attacks.
            let NFmax {double($nfPersonnel)/max($nfCas,0.1)}
            let UFmax {double($ufPersonnel)/max($ufCas,0.1)}

            let Na {
                entier(min($Np, $NFmax, $UFmax))
            }

            # NEXT, they always attack at least once.
            if {$Na == 0} {
                set Na 1
            }

            # NEXT, compute the total number of UF casualties
            let totalUFcas {
                round(min($Na * $ufCas, $ufPersonnel))
            }

            # NEXT, compute the total number of UF casualties
            if {[ufFiresBack $nfRoe $ufRoe]} {
                let totalNFcas {
                    round(min($totalUFcas * $ler, $nfPersonnel))
                }
            } else {
                set totalNFcas 0
            }

            # NEXT, compute the civilian collateral damage
            set ecdc [parmdb get aam.NFvsUF.ECDC.$urbanization]

            let Ncivcas { round($ecdc * $totalNFcas) }
            
            # NEXT, save the casualties
            rdb eval {
                INSERT INTO aam_pending_nf(n,f,casualties)
                VALUES($n,$uf,$totalUFcas);

                INSERT INTO aam_pending_nf(n,f,casualties)
                VALUES($n,$nf,$totalNFcas);

                INSERT INTO aam_pending_n(n,attacker,defender,casualties)
                VALUES($n,$nf,$uf,$Ncivcas);
            }

            # NEXT, log the results
            log normal aam \
                "NF $nf attacks UF $uf in $n: UF $totalUFcas NF $totalNFcas CIV $Ncivcas"
            log detail aam [tsubst {
                |<--
                NF $nf attacks UF $uf in $n:
                    nfRoe:        $nfRoe
                    coopLimit:    $coopLimit
                    rate:         $rate
                    urbanization: $urbanization
                    pop:          $pop
                    nfPersonnel:  $nfPersonnel
                    nfCoop:       $nfCoop
                    ufPersonnel:  $ufPersonnel
                    ufSecurity:   $ufSecurity
                    ufCoop:       $ufCoop
                    ufCov:        $ufCov
                    ufRoe:        $ufRoe
                    Np:           $Np
                    LER:          $ler
                    Na:           $Na
                    ufCas:        $ufCas
                    nfCas:        $nfCas
            }]
        }
    }

    # ufFiresBack nfRoe ufRoe
    #
    # nfRoe       The NF's attacking ROE
    # ufRoe       The UF's defending ROE
    #
    # Returns 1 if UF fires back, and 0 otherwise.

    proc ufFiresBack {nfRoe ufRoe} {
        if {$nfRoe eq "HIT_AND_RUN"} {
            if {$ufRoe eq "FIRE_BACK_IMMEDIATELY"} {
                return 1
            }
        } elseif {$nfRoe eq "STAND_AND_FIGHT"} {
            if {$ufRoe ne "HOLD_FIRE"} {
                return 1
            }
        }

        return 0
    }


    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # the change cannot be undone, the mutator returns the empty string.


    # mutate attritnf parmdict
    #
    # parmdict      Dictionary of order parms
    #
    #   n           Neighborhood in which attrition occurs
    #   f           Group taking attrition.
    #   casualties  Number of casualties taken by the group.
    #   g1          Responsible force group, or ""
    #   g2          Responsible force group, or "".
    #
    # Attrits the specified group in the specified neighborhood
    # by the specified number of casualties (all of which are kills).
    #
    # The group's units are attrited in proportion to their size.
    #
    # g1 and g2 are used only for attrition to a civilian group.

    typemethod {mutate attritnf} {parmdict} {
        dict with parmdict {
            log normal aam "mutate attritnf $n $f $casualties $g1 $g2"

            # FIRST, determine the set of units to attrit.
            set units [rdb eval {
                UPDATE units
                SET attrit_flag = 0;

                UPDATE units
                SET attrit_flag = 1
                WHERE n=$n 
                AND   g=$f
                AND   personnel > 0
            }]

            # NEXT, attrit the units
            return [$type AttritUnits $casualties $g1 $g2]
        }
    }

    # mutate attritn parmdict
    #
    # parmdict      Dictionary of order parms
    #
    #   n           Neighborhood in which attrition occurs
    #   casualties  Number of casualties taken by the group.
    #   g1          Responsible force group, or "".
    #   g2          Responsible force group, or "".
    #
    # Attrits all civilian units in the specified neighborhood
    # by the specified number of casualties (all of which are kills).
    # Units are attrited in proportion to their size.

    typemethod {mutate attritn} {parmdict} {
        dict with parmdict {
            log normal aam "mutate attritn $n $casualties $g1 $g2"

            # FIRST, determine the set of units to attrit (all
            # the CIV units in the neighborhood).
            set units [rdb eval {
                UPDATE units
                SET attrit_flag = 0;

                UPDATE units
                SET attrit_flag = 1
                WHERE n=$n 
                AND   gtype='CIV'
                AND   personnel > 0
            }]

            # NEXT, attrit the units
            return [$type AttritUnits $casualties $g1 $g2]
        }
    }

    # mutate attritunit parmdict
    #
    # parmdict      Dictionary of order parms
    #
    #   u           Unit to be attrited.
    #   casualties  Number of casualties taken by the unit.
    #   g1          Responsible group
    #   g2          Responsible group
    #
    # Attrits the specified unit by the specified number of 
    # casualties (all of which are kills).

    typemethod {mutate attritunit} {parmdict} {
        dict with parmdict {
            log normal aam "mutate attritunit $u $casualties $g1 $g2"

            # FIRST, prepare to undo
            set undo [list]

            # NEXT, retrieve the unit.
            set unit [unit get $u]

            dict with unit {
                # FIRST, get the actual number of casualties the
                # unit can take.
                let actual {min($casualties,$personnel)}

                if {$actual == 0} {
                    log normal aam \
                        "Overkill; no casualties can be inflicted."
                    return "# Nothing to undo"
                } elseif {$actual < $casualties} {
                    log normal aam \
                        "Overkill; only $actual casualties can be inflicted."
                }

                set casualties $actual
            }
        }

        # NEXT, attrit the unit
        set parmdict [dict merge $parmdict $unit]
        lappend undo [$type AttritUnit $parmdict]

        return [join $undo \n]
    }

    # AttritUnits casualties g1 g2
    #
    # casualties  Number of casualties taken by the group.
    # g1          Responsible force group, or "".
    # g2          Responsible force group, or "".
    #
    # Attrits the units marked with the attrition flag 
    # proportional to their size until
    # all casualites are inflicted or the units have no personnel.
    # The actual work is performed by mutate attritunit.

    typemethod AttritUnits {casualties g1 g2} {
        # FIRST, determine the number of personnel in the attrited units
        set total [rdb eval {
            SELECT total(personnel) FROM units
            WHERE attrit_flag
        }]

        # NEXT, compute the actual number of casualties.
        let actual {min($casualties, $total)}

        if {$actual == 0} {
            log normal aam \
                "Overkill; no casualties can be inflicted."
            return "# Nothing to undo"
        } elseif {$actual < $casualties} {
            log normal aam \
                "Overkill; only $actual casualties can be inflicted."
        }
        
        # NEXT, apply attrition to the units, in order of size.
        set remaining $actual

        rdb eval {
            SELECT u                                   AS u,
                   g                                   AS g,
                   gtype                               AS gtype,
                   personnel                           AS personnel,
                   n                                   AS n,
                   origin                              AS origin,
                   $actual*(CAST (personnel AS REAL)/$total) 
                                                       AS share
            FROM units
            WHERE attrit_flag
            ORDER BY share DESC
        } row {
            # FIRST, allocate the share to this body of people.
            let kills     {int(min($remaining, ceil($row(share))))}
            let remaining {$remaining - $kills}

            # NEXT, compute the attrition.
            let take {int(min($row(personnel), $kills))}

            # NEXT, attrit the unit
            set row(g1)         $g1
            set row(g2)         $g2
            set row(casualties) $take

            lappend undo [$type AttritUnit [array get row]]

            # NEXT, we might have finished early
            if {$remaining == 0} {
                break
            }
        }

        return [join $undo \n]
    }

    # AttritUnit parmdict
    #
    # parmdict      Dictionary of unit data, plus g1 and g2
    #
    # Attrits the specified unit by the specified number of 
    # casualties (all of which are kills); also decrements
    # the unit's staffing pool.  This is the fundamental attrition
    # routine; the others all flow down to this.
    #
    # CIV Attrition
    #
    # If u is a CIV unit, the attrition is counted against the
    # unit's neighborhood of origin.

    typemethod AttritUnit {parmdict} {
        dict with parmdict {
            # FIRST, prepare to undo
            set undo [list]

            # NEXT, log the attrition
            let personnel {$personnel - $casualties}

            log normal aam \
          "Unit $u takes $casualties casualties, leaving $personnel personnel"
            
            # NEXT, update the unit.
            lappend undo [unit mutate personnel $u $personnel]

            # NEXT, if this is a CIV unit, attrit the unit's
            # group of origin.
            if {$gtype eq "CIV"} {
                # FIRST, attrit the group of origin
                set parms [list n $origin g $g casualties $casualties]

                if {$n eq $origin} {
                    lappend undo [demog mutate attritResident $parms]
                } else {
                    lappend undo [demog mutate attritDisplaced $parms]
                }

                # NEXT, save the attrition for attitude assessment
                lappend undo \
                    [$type SaveCivAttrition $origin $g $casualties $g1 $g2] 
            } else {
                # FIRST, It's a force or org unit.  Attrit its pool in
                # its neighborhood of origin.

                set parms [list id [list $origin $g] delta -$casualties]

                lappend undo [personnel mutate adjust $parms]
            }
        }

        return [join $undo \n]
    }

    
    # SaveCivAttrition n f casualties g1 g2
    #
    # n           The neighborhood in which the attrition took place.
    # f           The CIV group receiving the attrition
    # casualties  The number of casualties
    # g1          A responsible force group, or ""
    # g2          A responsible force group, g2 != g1, or ""
    #
    # Accumulates the attrition for later attitude assessment.

    typemethod SaveCivAttrition {n f casualties g1 g2} {
        # FIRST, prepare to accumulated undo info
        set undo [list]

        # NEXT, save nf casualties for satisfaction.
        rdb eval {
            INSERT INTO attrit_nf(n,f,casualties)
            VALUES($n,$f,$casualties);
        }

        set id [rdb last_insert_rowid]

        lappend undo [mytypemethod DeleteAttritNF $id]

        # NEXT, save nfg casualties for cooperation
        if {$g1 ne ""} {
            rdb eval {
                INSERT INTO attrit_nfg(n,f,casualties,g)
                VALUES($n,$f,$casualties,$g1);
            }
            
            set id [rdb last_insert_rowid]
            
            lappend undo [mytypemethod DeleteAttritNFG $id]
        }

        if {$g2 ne ""} {
            rdb eval {
                INSERT INTO attrit_nfg(n,f,casualties,g)
                VALUES($n,$f,$casualties,$g2);
            }
            
            set rowId [rdb last_insert_rowid]
            
            lappend undo [mytypemethod DeleteAttritNFG $rowId]
        }

        return [join $undo \n]
    }

    # DeleteAttritNF id
    #
    # id     Row ID of a record
    #
    # Deletes the row on undo.

    typemethod DeleteAttritNF {id} {
        rdb eval {
            DELETE FROM attrit_nf WHERE id=$id
        }
    }

    # DeleteAttritNFG id
    #
    # id     Row ID of a record
    #
    # Deletes the row on undo.

    typemethod DeleteAttritNFG {id} {
        rdb eval {
            DELETE FROM attrit_nfg WHERE id=$id
        }
    }


    #-------------------------------------------------------------------
    # Order Helpers

    # Refresh_AN dlg fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes g2 when g1 changes, so that g2 doesn't
    # contain the value of g1.

    typemethod Refresh_AN {dlg fields fdict} {
        if {"g1" in $fields} {
            dict with fdict {
                if {$g1 eq ""} {
                    $dlg disabled g2
                    $dlg set g2 ""
                } else {
                    set groups [frcgroup names]
                    ldelete groups $g1
                    
                    $dlg field configure g2 -values $groups
                    $dlg disabled {}
                }
            }
        }
    }

    # Refresh_AG dlg fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the ATTRIT:GROUP dialog fields when field values
    # change.

    typemethod Refresh_AG {dlg fields fdict} {
        set disabled [list]

        dict with fdict {
            if {"n" in $fields} {
                # Update the list of groups to attrit
                set groups [rdb eval {
                    SELECT DISTINCT g
                    FROM units
                    WHERE n=$n
                    ORDER BY g
                }]
                
                $dlg field configure f -values $groups

                if {[llength $groups] == 0} {
                    lappend disabled f
                }

                # Get value, as it might have changed.
                set f [$dlg field get f]
                ladd fields f
            }

            if {"f" in $fields} {
                # Update g1
                if {$f eq "" || [group gtype $f] ne "CIV"} {
                    lappend disabled g1
                    set g1 ""
                    $dlg set g1 $g1
                }
            }

            # Update g2
            if {$g1 eq ""} {
                lappend disabled g2
                $dlg set g2 ""
            } else {
                set groups [frcgroup names]
                ldelete groups $g1
                
                $dlg field configure g2 -values $groups
            }
        }

        $dlg disabled $disabled
    }

    # Refresh_AU dlg fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the ATTRIT:UNIT dialog fields when field values
    # change.

    typemethod Refresh_AU {dlg fields fdict} {
        set disabled [list]

        dict with fdict {
            if {"u" in $fields} {
                # Update g1
                if {$u eq "" || [unit get $u gtype] ne "CIV"} {
                    lappend disabled g1
                    set g1 ""
                    $dlg set g1 $g1
                    ladd fields g1
                }
            }

            if {"g1" in $fields} {
                # Update g2
                if {$g1 eq ""} {
                    lappend disabled g2
                    $dlg set g2 ""
                } else {
                    set groups [frcgroup names]
                    ldelete groups $g1
                    
                    $dlg field configure g2 -values $groups
                }
            }
        }

        $dlg disabled $disabled
    }
}

#-------------------------------------------------------------------
# Orders


# ATTRIT:NBHOOD
#
# Attrits all civilians in a neighborhood.

order define ATTRIT:NBHOOD {
    title "Magic Attrit Neighborhood"
    options \
        -schedulestates {PREP PAUSED} \
        -sendstates     {PAUSED}      \
        -refreshcmd     [list ::aam Refresh_AN]

    parm n          key  "Neighborhood"      -table nbhoods   \
                                             -key n           \
                                             -tags nbhood
    parm casualties text "Casualties" 
    parm g1         key  "Responsible Group" -table frcgroups -key g \
        -tags group
    parm g2         enum "Responsible Group" -tags group
} {
    # FIRST, prepare the parameters
    prepare n          -toupper -required -type nbhood
    prepare casualties -toupper -required -type iquantity
    prepare g1         -toupper           -type frcgroup
    prepare g2         -toupper           -type frcgroup

    returnOnError -final

    # NEXT, g1 != g2
    if {$parms(g1) eq $parms(g2)} {
        set parms(g2) ""
    }

    # NEXT, attrit the civilians in the neighborhood
    lappend undo [aam mutate attritn [array get parms]]

    setundo [join $undo \n]
}


# ATTRIT:GROUP
#
# Attrits a group in a neighborhood.

order define ATTRIT:GROUP {
    title "Magic Attrit Group"
    options \
        -schedulestates {PREP PAUSED} \
        -sendstates     {PAUSED}      \
        -refreshcmd     [list ::aam Refresh_AG]

    parm n          key   "Neighborhood"      -table nbhoods -key n \
                                              -tags nbhood
    parm f          enum  "To Group"          -tags group 
    parm casualties text  "Casualties" 
    parm g1         key   "Responsible Group" -table frcgroups -key g \
                                              -tags group
    parm g2         enum  "Responsible Group" -tags group
} {
    # FIRST, prepare the parameters
    prepare n          -toupper -required -type nbhood
    prepare f          -toupper -required -type group
    prepare casualties -toupper -required -type iquantity
    prepare g1         -toupper           -type frcgroup
    prepare g2         -toupper           -type frcgroup

    returnOnError

    # NEXT, get the group type
    set gtype [group gtype $parms(f)]

    # NEXT, g1 and g2 should be "" unless f is a CIV
    if {$gtype ne "CIV"} {
        validate g1 {
            reject g1 \
                "Responsible groups only matter when civilians are attrited"
        }

        validate g2 {
            reject g2 \
                "Responsible groups only matter when civilians are attrited"
        }
    }

    returnOnError -final

    # NEXT, g1 != g2
    if {$parms(g1) eq $parms(g2)} {
        set parms(g2) ""
    }

    # NEXT, attrit the group
    lappend undo [aam mutate attritnf [array get parms]]

    setundo [join $undo \n]
}


# ATTRIT:UNIT
#
# Attrits a single unit.

order define ATTRIT:UNIT {
    title "Magic Attrit Unit"
    options \
        -schedulestates {PREP PAUSED}           \
        -sendstates     {PAUSED}                \
        -refreshcmd     [list ::aam Refresh_AU]

    parm u          key   "Unit"              -table units     -key u \
                                              -tags unit
    parm casualties text  "Casualties" 
    parm g1         key   "Responsible Group" -table frcgroups -key g \
                                              -tags  group
    parm g2         enum  "Responsible Group" -tags  group
} {
    # FIRST, prepare the parameters
    prepare u          -toupper -required -type unit
    prepare casualties -toupper -required -type iquantity
    prepare g1         -toupper           -type frcgroup
    prepare g2         -toupper           -type frcgroup

    returnOnError

    # NEXT, get the unit's group type
    set gtype [unit get $parms(u) gtype]

    # NEXT, g1 and g2 should be "" unless u is a CIV unit
    if {$gtype ne "CIV"} {
        validate g1 {
            reject g1 \
                "Responsible groups only matter when civilians are attrited"
        }

        validate g2 {
            reject g2 \
                "Responsible groups only matter when civilians are attrited"
        }
    }

    returnOnError -final


    # NEXT, attrit the unit
    lappend undo [aam mutate attritunit [array get parms]]

    setundo [join $undo \n]
}



