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
    # This routine is to be called every tick to do the 
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
        driver::CIVCAS assess
        $type ClearAttitudeStatistics

        # NEXT, Refund unspent attack funds to actors.
        tactic::ATTROE refund
    }

    # ApplyAttrition
    #
    # Applies the attrition from magic attrition and then that
    # accumulated by the normal attrition algorithms.

    typemethod ApplyAttrition {} {
        # FIRST, apply the magic attrition
        rdb eval {
            SELECT mode,
                   n,
                   f,
                   casualties,
                   g1,
                   g2
            FROM magic_attrit
        } {
            switch -exact -- $mode {
                NBHOOD {
                    $type AttritNbhood $n $casualties $g1 $g2
                }

                GROUP {
                    $type AttritGroup $n $f $casualties $g1 $g2
                }

                default {error "Unrecognized attrition mode: \"$mode\""}
            }
        }

        # NEXT, clear out the magic attrition, we're done.
        rdb eval {
            DELETE FROM magic_attrit;
        }

        # NEXT, apply the force group attrition
        rdb eval {
            SELECT n, 
                   f, 
                   total(casualties) AS casualties,
                   ''                AS g1,
                   ''                AS g2
            FROM aam_pending_nf
            GROUP BY n,f
        } {
            $type AttritGroup $n $f $casualties $g1 $g2
        }


        # NEXT, apply the collateral damage.
        rdb eval {
            SELECT n,
                   casualties,
                   attacker    AS g1,
                   defender    AS g2
            FROM aam_pending_n
        } {
            $type AttritNbhood $n $casualties $g1 $g2
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
        set deltaT    7.0 ;# 1 tick in days.
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
                   A.max_attacks             AS max,
                   N.urbanization            AS urbanization,
                   DN.population             AS pop,
                   UP.personnel              AS ufPersonnel,
                   UC.nbcoop                 AS ufCoop,
                   NP.personnel              AS nfPersonnel,
                   NC.nbcoop                 AS nfCoop
            FROM attroe_nfg    AS A
            JOIN nbhoods       AS N  ON (N.n  = A.n)
            JOIN demog_n       AS DN ON (DN.n = A.n)
            JOIN force_ng      AS UP ON (UP.n = A.n AND UP.g = A.f)
            JOIN uram_nbcoop   AS UC ON (UC.n = A.n AND UC.g = A.f)
            JOIN force_ng      AS NP ON (NP.n = A.n AND NP.g = A.g)
            JOIN uram_nbcoop   AS NC ON (NC.n = A.n AND NC.g = A.g)
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
            }

            # NEXT, the attack occurs.  Get the coverage fractions.
            set ufCov     [coverage eval $ufCovFunc $ufPersonnel $pop]
            set nfCov     [coverage eval $nfCovFunc $nfPersonnel $pop]

            # NEXT, compute the possible number of attacks:
            let Np { 
                round( ($ufCoop           * $ufCov    * $nfCov * $deltaT)/
                       (max($nfCoop,10.0) * $ufCovNom * $nfCovNom * $tf ) )
            }

            # But no more than max_attacks
            if {$Np > $max} {
                set Np $max
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

            # Save the actual number of attacks
            set actual([list $n $uf $nf]) $Na

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

            rdb eval {SELECT a AS ufOwner FROM frcgroups WHERE g=$uf} {}
            rdb eval {SELECT a AS nfOwner FROM frcgroups WHERE g=$nf} {}

            sigevent log 1 attrit "
                Uniformed force {group:$uf} attacks non-uniformed force
                {group:$nf} in {nbhood:$n} $Na times, 
                killing $Nkilled personnel,
                with $Ncivcas civilian casualties.
            " $uf $nf $n $ufOwner $nfOwner
        }

        # NEXT, save the actual number of attacks in the attroe_nfg 
        # table, so that unused funds can be returned.
        foreach id [array names actual] {
            lassign $id n f g

            set value $actual($id)

            rdb eval {
                UPDATE attroe_nfg
                SET    attacks = $value
                WHERE n=$n AND f=$f AND g=$g;
            }            
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
        set ufCovFunc [parmdb get aam.NFvsUF.UF.coverageFunction]
        set ufCovNom  [parmdb get aam.NFvsUF.UF.nominalCoverage]

        # NEXT, step over all attacking ROEs, gathering the related
        # data as needed.
        rdb eval {
            SELECT A.n                             AS n,
                   A.f                             AS nf,
                   A.g                             AS uf,
                   A.roe                           AS nfRoe,
                   A.max_attacks                   AS max,
                   N.urbanization                  AS urbanization,
                   DN.population                   AS pop,
                   NP.personnel                    AS nfPersonnel,
                   NC.nbcoop                       AS nfCoop,
                   UP.personnel                    AS ufPersonnel,
                   UP.security                     AS ufSecurity,
                   UC.nbcoop                       AS ufCoop,
                   UD.roe                          AS ufRoe
            FROM attroe_nfg     AS A
            JOIN nbhoods        AS N  ON (N.n = A.n)
            JOIN demog_n        AS DN ON (DN.n = A.n)
            JOIN force_ng       AS NP ON (NP.n = A.n AND NP.g = A.f)
            JOIN uram_nbcoop    AS NC ON (NC.n = A.n AND NC.g = A.f)
            JOIN force_ng       AS UP ON (UP.n = A.n AND UP.g = A.g)
            JOIN uram_nbcoop    AS UC ON (UC.n = A.n AND UC.g = A.g)
            JOIN defroe_view    AS UD ON (UD.n = A.n AND UD.g = A.g)
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
            }

            # NEXT, get the UF coverage
            set ufCov     [coverage eval $ufCovFunc $ufPersonnel $pop]

            # NEXT, get the NF parameters that depend on ROE
            set nfCoopNom [parmdb get aam.NFvsUF.$nfRoe.nominalCooperation]
            set ELER      [parmdb get aam.NFvsUF.$nfRoe.ELER]
            set MAXLER    [parmdb get aam.NFvsUF.$nfRoe.MAXLER]

            # NEXT, compute the potential number of attacks.  max_attacks
            # is the rate of attacks per strategy tock, so it can serve
            # as the base rate.
            let Np { 
                round( 
                 ($max * (100 - $ufSecurity) * $nfCoop    * $ufCov)
                 / (            100          * $nfCoopNom * $ufCovNom))
            }

            # But no more than max_attacks
            if {$Np > $max} {
                set Np $max
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

            # Save the actual number of attacks
            set actual([list $n $nf $uf]) $Na

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
                    max_attacks:  $max
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

            rdb eval {SELECT a AS ufOwner FROM frcgroups WHERE g=$uf} {}
            rdb eval {SELECT a AS nfOwner FROM frcgroups WHERE g=$nf} {}

            sigevent log 1 attrit "
                Non-uniformed force {group:$nf} attacks uniformed force
                {group:$uf} in {nbhood:$n} $Na times, 
                killing $totalUFcas {group:$uf} personnel
                at a cost of $totalNFcas {group:$nf} personnel
                with $Ncivcas civilian casualties.
            " $nf $uf $n $nfOwner $ufOwner
        }

        # NEXT, save the actual number of attacks in the attroe_nfg 
        # table, so that unused funds can be returned.
        foreach id [array names actual] {
            lassign $id n f g

            set value $actual($id)

            rdb eval {
                UPDATE attroe_nfg
                SET    attacks = $value
                WHERE n=$n AND f=$f AND g=$g;
            }            
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


    # attrit parmdict
    #
    # parmdict
    # 
    # mode          Mode of attrition: GROUP or NBHOOD 
    # casualties    Number of casualties taken by GROUP or NBHOOD
    # n             The neighborhood 
    # f             The group if mode is GROUP
    # g1            Responsible force group, or ""
    # g2            Responsible force group, or ""
    # 
    # Adds a record to the magic attrit table for adjudication at the
    # next aam assessment.
    #
    # g1 and g2 are used only for attrition to a civilian group

    typemethod attrit {parmdict} {
        dict with parmdict {
            # FIRST add a record to the table
            rdb eval {
                INSERT INTO magic_attrit(mode,casualties,n,f,g1,g2)
                VALUES($mode,
                       $casualties,
                       $n,
                       nullif($f,  ''),
                       nullif($g1, ''),
                       nullif($g2, ''));
            }
        }
    }

    # AttritGroup n f casualties g1 g2
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
    # For FRC/ORG groups, their deployments in deploy_tng are
    # attrited as well, to support deployment without reinforcement.
    #
    # g1 and g2 are used only for attrition to a civilian group.

    typemethod AttritGroup {n f casualties g1 g2} {
        log normal aam "AttritGroup $n $f $casualties $g1 $g2"

        # FIRST, determine the set of units to attrit.
        rdb eval {
            UPDATE units
            SET attrit_flag = 0;

            UPDATE units
            SET attrit_flag = 1
            WHERE n=$n 
            AND   g=$f
            AND   personnel > 0
        }

        # NEXT, attrit the units
        $type AttritUnits $casualties $g1 $g2

        # NEXT, attrit FRC/ORG deployments.
        if {[group gtype $f] in {FRC ORG}} {
            $type AttritDeployments $n $f $casualties
        }
    }

    # AttritNbhood n casualties g1 g2
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

    typemethod AttritNbhood {n casualties g1 g2} {
        log normal aam "AttritNbhood $n $casualties $g1 $g2"

        # FIRST, determine the set of units to attrit (all
        # the CIV units in the neighborhood).
        rdb eval {
            UPDATE units
            SET attrit_flag = 0;

            UPDATE units
            SET attrit_flag = 1
            WHERE n=$n 
            AND   gtype='CIV'
            AND   personnel > 0
        }

        # NEXT, attrit the units
        $type AttritUnits $casualties $g1 $g2
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
    # The actual work is performed by AttritUnit.

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
            return 
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
                   $actual*(CAST (personnel AS REAL)/$total) 
                                                       AS share
            FROM units
            WHERE attrit_flag
            ORDER BY share DESC
        } row {
            # FIRST, allocate the share to this body of people.
            let kills     {entier(min($remaining, ceil($row(share))))}
            let remaining {$remaining - $kills}

            # NEXT, compute the attrition.
            let take {entier(min($row(personnel), $kills))}

            # NEXT, attrit the unit
            set row(g1)         $g1
            set row(g2)         $g2
            set row(casualties) $take

            $type AttritUnit [array get row]

            # NEXT, we might have finished early
            if {$remaining == 0} {
                break
            }
        }
    }

    # AttritUnit parmdict
    #
    # parmdict      Dictionary of unit data, plus g1 and g2
    #
    # Attrits the specified unit by the specified number of 
    # casualties (all of which are kills); also decrements
    # the unit's staffing pool.  This is the fundamental attrition
    # routine; the others all flow down to this.
 
    typemethod AttritUnit {parmdict} {
        dict with parmdict {
            # FIRST, log the attrition
            let personnel {$personnel - $casualties}

            log normal aam \
          "Unit $u takes $casualties casualties, leaving $personnel personnel"
            
            # NEXT, update the unit.
            unit mutate personnel $u $personnel

            # NEXT, if this is a CIV unit, attrit the unit's
            # group.
            if {$gtype eq "CIV"} {
                # FIRST, attrit the group 
                demog attrit $g $casualties

                # NEXT, save the attrition for attitude assessment
                $type SaveCivAttrition $n $g $casualties $g1 $g2
            } else {
                # FIRST, It's a force or org unit.  Attrit its pool in
                # its neighborhood.
                personnel attrit $n $g $casualties
            }
        }

        return
    }

    # AttritDeployments n g casualties
    #
    # n           The neighborhood in which the attrition took place.
    # g           The FRC or ORG group that was attrited.
    # casualties  Number of casualties taken by the group.
    #
    # Attrits the deployment of the given group in the given neighborhood, 
    # spreading the attrition across all DEPLOY tactics active during
    # the current tick.
    #
    # This is to support DEPLOY without reinforcement.  The deploy_tng
    # table lists the actual troops deployed during the last
    # tick by each DEPLOY tactic, broken down by neighborhood and group.
    # This routine removes casualties from this table, so that the 
    # attrited troop levels can inform the next round of deployments.

    typemethod AttritDeployments {n g casualties} {
        # FIRST, determine the number of personnel in the attrited units
        set total [rdb eval {
            SELECT total(personnel) FROM deploy_tng
            WHERE n=$n AND g=$g
        }]

        # NEXT, compute the actual number of casualties.
        let actual {min($casualties, $total)}

        if {$actual == 0} {
            return 
        }

        # NEXT, apply attrition to the tactics, in order of size.
        set remaining $actual

        foreach {tactic_id personnel share} [rdb eval {
            SELECT tactic_id,
                   personnel,
                   $actual*(CAST (personnel AS REAL)/$total) AS share
            FROM deploy_tng
            WHERE n=$n AND g=$g
            ORDER BY share DESC
        }] {
            # FIRST, allocate the share to this body of troops.
            let kills     {entier(min($remaining, ceil($share)))}
            let remaining {$remaining - $kills}

            # NEXT, compute the attrition.
            let take {entier(min($personnel, $kills))}

            # NEXT, attrit the tactic's deployment.
            rdb eval {
                UPDATE deploy_tng
                SET personnel = personnel - $take
                WHERE tactic_id = $tactic_id AND n = $n AND g = $g
            }

            # NEXT, we might have finished early
            if {$remaining == 0} {
                break
            }
        }
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
        # FIRST, save nf casualties for satisfaction.
        rdb eval {
            INSERT INTO attrit_nf(n,f,casualties)
            VALUES($n,$f,$casualties);
        }

        # NEXT, save nfg casualties for cooperation
        if {$g1 ne ""} {
            rdb eval {
                INSERT INTO attrit_nfg(n,f,casualties,g)
                VALUES($n,$f,$casualties,$g1);
            }
        }

        if {$g2 ne ""} {
            rdb eval {
                INSERT INTO attrit_nfg(n,f,casualties,g)
                VALUES($n,$f,$casualties,$g2);
            }
        }

        return 
    }

    #-------------------------------------------------------------------
    # Tactic Order Helpers

    # AllButG1 g1
    #
    # g1 - A force group
    #
    # Returns a list of all force groups but g1 and puts "NONE" at the
    # beginning of the list.

    typemethod AllButG1 {g1} {
        set groups [ptype frcg+none names]
        ldelete groups $g1

        return $groups
    }
}



