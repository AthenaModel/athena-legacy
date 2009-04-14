#-----------------------------------------------------------------------
# TITLE:
#    nbstat.tcl
#
# AUTHOR:
#    Will Duquette
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1) Simulation Module: Neighborhood Status
#
#    This module contains code which analyzes the status of each
#    neighborhood, including force, volatility, security, force presence,
#    and group activities.  The results are used by the DAM rule sets, as
#    well as by other modules.
#
#    ::nbstat is a singleton object implemented as a snit::type.  To
#    initialize it, call "::nbstat init".  It can be re-initialized
#    on demand.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# nbstat

snit::type nbstat {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Initialization method

    typemethod init {} {
        # FIRST, check requirements
        require {[info commands ::log]  ne ""} "log is not defined."
        require {[info commands ::rdb]  ne ""} "rdb is not defined."

        # NEXT, Initialize the RDB tables used.
        rdb eval {
            DELETE FROM force_n;
            
            INSERT INTO force_n(n)
            SELECT n FROM nbhoods;
        }

        # TBD: Presumes that there's only one instance of GRAM.
        # TBD: If populations begin to vary, we'll need to recompute
        # this during each analysis.
        rdb eval {
            SELECT n, total(population) AS pop
            FROM gram_ng JOIN gram_g USING (g)
            WHERE gram_g.gtype = 'CIV'
            GROUP BY n
        } {
            rdb eval {
                UPDATE force_n
                SET population = $pop
                WHERE n=$n
            }
        }

        rdb eval {
            DELETE FROM force_ng;

            INSERT INTO force_ng(n,g)
            SELECT n, g
            FROM nbhoods JOIN groups;
        }


        if 0 {
            # Initialize activity_nga.
            rdb eval {
                DELETE FROM activity_nga;
            }

            # Add FRC groups and FRC activities for each neighborhood.
            rdb eval {
                SELECT nbhoods.name AS n, pgroups.name AS g
                FROM nbhoods JOIN pgroups
                WHERE pgroups.type = 'FRC';
            } {
                foreach act [efrcactivity longnames] {
                    set type [efrcactivity name $act]

                    rdb eval {
                        INSERT INTO activity_nga(n,g,a,actsit_type)
                        VALUES($n,$g,$act,$type)
                    }
                }
            }

            # Add ORG groups and ORG activities for each neighborhood
            rdb eval {
                SELECT nbhoods.name AS n, pgroups.name AS g
                FROM nbhoods JOIN pgroups
                WHERE pgroups.type = 'ORG';
            } {
                foreach act [eorgactivity longnames] {

                    set type [eorgactivity name $act]

                    rdb eval {
                        INSERT INTO activity_nga(n,g,a,actsit_type)
                        VALUES($n,$g,$act,$type)
                    }
                }
            }
        }

        # NEXT, do an initial analysis.
        nbstat analyze

        # NEXT, Nbstat is up.
        log normal nbstat "Initialized"
    }

    #-------------------------------------------------------------------
    # analyze

    # analyze
    #
    # Analyzes neighborhood status, as of the present
    # time, given the current contents of the RDB.

    typemethod analyze {} {
        # FIRST, compute the "force" values for each group in each 
        # neighborhood.
        nbstat ComputeOwnForce
        nbstat ComputeLocalFriendsAndEnemies
        nbstat ComputeAllFriendsAndEnemies
        nbstat ComputeTotalForce
        nbstat ComputePercentForce

        # NEXT, compute the volatility for each neighborhood.
        nbstat ComputeVolatility

        # NEXT, compute the security for each group in each nbhood.
        nbstat ComputeSecurity

        if 0 {
            # NEXT, compute activity coverage fractions for all force
            # and ORG groups in all neighborhoods.
            nbstat InitializeActivityTable

            ::sim::profile nbstat ComputeForceActivityFlags
            ::sim::profile nbstat ComputeOrgActivityFlags
            ::sim::profile nbstat ComputeActivityPersonnel
            ::sim::profile nbstat ComputeCoverage
        }
    }

    # ComputeOwnForce
    #
    # Compute Q.ng, each group g's "own force" in neighborhood n,
    # for all n and g.

    typemethod ComputeOwnForce {} {
        rdb eval {
            UPDATE force_ng
            SET own_force = 0,
                personnel = 0
        }

        #---------------------------------------------------------------
        # CIV Groups

        # population force
        rdb eval {
            SELECT gram_ng.n               AS n,
                   gram_ng.g               AS g,
                   gram_ng.population      AS population,
                   gram_ng.sat             AS mood,
                   nbgroups.demeanor       AS demeanor
            FROM gram_ng 
            JOIN nbgroups USING (n,g)
        } {
            set a [parmdb get force.population]
            set D [parmdb get force.demeanor.$demeanor]
            
            set b    [parmdb get force.mood]
            let M    {1.0 - $b*$mood/100.0}

            let pop_force {int(ceil($a*$D*$M*$population))}

            rdb eval {
                UPDATE force_ng
                SET own_force = $pop_force
                WHERE n = $n AND g = $g
            }
        }
        
        # unit force
        #
        # TBD: At present, there are no civilian units.
        # If we add some, we'll need to look up the relevant
        # algorithm.

        #---------------------------------------------------------------
        # FRC Groups
        rdb eval {
            SELECT n, 
                   g,
                   total(personnel) AS P,
                   demeanor,
                   forcetype
            FROM units JOIN frcgroups USING (g)
            WHERE n != ''
            GROUP BY n, g 
        } {
            set D [parmdb get force.demeanor.$demeanor]
            set E [parmdb get force.forcetype.$forcetype]

            let own_force {int(ceil($E*$D*$P))}

            rdb eval {
                UPDATE force_ng
                SET own_force=$own_force,
                    personnel=$P
                WHERE n = $n AND g = $g
            }
        }

        #---------------------------------------------------------------
        # ORG Groups
        rdb eval {
            SELECT n,
                   g,
                   total(personnel) AS P,
                   demeanor,
                   orgtype
            FROM units JOIN orggroups USING (g)
            WHERE n != ''
            GROUP BY n, g 
        } {
            set D [parmdb get force.demeanor.$demeanor]
            set E [parmdb get force.orgtype.$orgtype]
            let own_force {int(ceil($E*$D*$P))}
            
            rdb eval {
                UPDATE force_ng
                SET own_force=$own_force,
                    personnel=$P
                WHERE n = $n AND g = $g
            }
        }
    }

    # ComputeLocalFriendsAndEnemies
    #
    # Computes LocalFriends.ng and LocalEnemies.ng for each n and g.

    typemethod ComputeLocalFriendsAndEnemies {} {
        # FIRST, initialize the accumulators
        rdb eval {
            UPDATE force_ng
            SET local_force = 0,
                local_enemy = 0
        }

        # NEXT, iterate of all pairs of groups in each neighborhood.
        # TBD: Assumes that there's only one GRAM!
        rdb eval {
            SELECT gram_nfg.n           AS n, 
                   gram_nfg.f           AS f,
                   gram_nfg.g           AS g,
                   gram_nfg.rel         AS rel,
                   force_ng.own_force   AS f_own_force
            FROM gram_nfg 
            JOIN force_ng 
            ON (force_ng.n = gram_nfg.n AND force_ng.g = gram_nfg.f)
            WHERE rel != 0.0
        } {
            if {$rel > 0} {
                let friends {int(ceil($f_own_force*$rel))}

                rdb eval {
                    UPDATE force_ng
                    SET local_force = local_force + $friends
                    WHERE n = $n AND g = $g
                }
            } elseif {$rel < 0} {
                let enemies {int(ceil($f_own_force*abs($rel)))}

                rdb eval {
                    UPDATE force_ng
                    SET local_enemy = local_enemy + $enemies
                    WHERE n = $n AND g = $g
                }
            }
        }
    }

    # ComputeAllFriendsAndEnemies
    #
    # Computes Force.ng and Enemy.ng for each n and g.

    typemethod ComputeAllFriendsAndEnemies {} {
        # FIRST, initialize the accumulators
        rdb eval {
            UPDATE force_ng
            SET force = local_force,
                enemy = local_enemy;
        }

        # NEXT, get the proximity multiplier
        set h [parmdb get force.proximity]

        # NEXT, iterate over all pairs of nearby neighborhoods.
        rdb eval {
            SELECT nbrel_mn.m                AS m,
                   nbrel_mn.n                AS n,
                   mforce_ng.local_force     AS m_friends,
                   mforce_ng.local_enemy     AS m_enemies,
                   nforce_ng.g               AS g
            FROM nbrel_mn 
            JOIN force_ng AS mforce_ng
            JOIN force_ng AS nforce_ng
            WHERE nbrel_mn.proximity = 'NEAR'
            AND   mforce_ng.n = nbrel_mn.m
            AND   nforce_ng.n = nbrel_mn.n
            AND   mforce_ng.g = nforce_ng.g
        } {
            let friends {int(ceil($h*$m_friends))}
            let enemies {int(ceil($h*$m_enemies))}

            rdb eval {
                UPDATE force_ng
                SET force = force + $friends,
                    enemy = enemy + $enemies
                WHERE n = $n AND g = $g
            }
        }
    }

    # ComputeTotalForce
    #
    # Computes TotalForce.n.

    typemethod ComputeTotalForce {} {
        # FIRST, initialize the accumulators
        rdb eval {
            UPDATE force_n
            SET total_force = 0;
        }

        # NEXT, get the force in each neighborhood
        rdb eval {
            SELECT n, g, own_force FROM force_ng
        } {
            rdb eval {
                UPDATE force_n
                SET total_force = total_force + $own_force
                WHERE n = $n
            }
        }

        # NEXT, get the proximity multiplier
        set h [parmdb get force.proximity]

        # NEXT, iterate over all pairs of nearby neighborhoods.
        rdb eval {
            SELECT nbrel_mn.n              AS n,
                   mforce_ng.own_force     AS m_own_force
            FROM nbrel_mn 
            JOIN force_ng AS mforce_ng 
            JOIN force_ng AS nforce_ng
            WHERE nbrel_mn.proximity = 'NEAR'
            AND   mforce_ng.n = nbrel_mn.m
            AND   nforce_ng.n = nbrel_mn.n
            AND   mforce_ng.g = nforce_ng.g
        } {
            let force {int(ceil($h*$m_own_force))}

            rdb eval {
                UPDATE force_n
                SET total_force = total_force + $force
                WHERE n = $n
            }
        }
    }

    # ComputePercentForce
    #
    # Computes %Force.ng, %Enemy.ng

    typemethod ComputePercentForce {} {
        rdb eval {
            SELECT n, total_force
            FROM force_n
        } {
            rdb eval {
                UPDATE force_ng
                SET pct_force = 100*force/$total_force,
                    pct_enemy = 100*enemy/$total_force
                WHERE n = $n
            }
        }
    }

    # ComputeVolatility
    #
    # Computes Volatility.n

    typemethod ComputeVolatility {} {
        rdb eval {
            SELECT force_ng.n                   AS n,
                   total(enemy*force)           AS conflicts,
                   total_force                  AS total_force,
                   vtygain                      AS vtygain
            FROM force_ng JOIN force_n USING (n) JOIN nbhoods USING (n)
            GROUP BY n
        } { 
            # Avoid integer overflow
            let total_force {double($total_force)}
            let tfSquared {$total_force * $total_force}

            let nominal_volatility {
                int(ceil(100*$conflicts/$tfSquared))
            }

            let volatility {
                min(100, int($vtygain * $nominal_volatility))
            }
            
            rdb eval {
                UPDATE force_n
                SET volatility_gain    = $vtygain,
                    nominal_volatility = $nominal_volatility,
                    volatility         = $volatility
                WHERE n = $n
            }
        }
    }

    # ComputeSecurity
    #
    # Computes Security.ng

    typemethod ComputeSecurity {} {
        # FIRST, get the volatility attenuator.
        set v [parmdb get force.volatility]

        rdb eval {
            SELECT n, g, pct_force, pct_enemy, volatility
            FROM force_ng JOIN force_n USING (n)
        } {
            let vol {$v*$volatility}
            let realSecurity {
                100.0*($pct_force - $pct_enemy - $vol)/(100.0 + $vol)
            }
            
            let security {int(ceil($realSecurity))}
            
            rdb eval {
                UPDATE force_ng
                SET security = $security
                WHERE n = $n AND g = $g
            }
        }
    }

    # InitializeActivityTable
    #
    # Initializes the activity_nga table prior to computing FRC and ORG
    # activities.

    typemethod InitializeActivityTable {} {
        # FIRST, clear the previous results.
        rdb eval {
            UPDATE activity_nga
            SET security_flag = 1,
                can_be_moving     = 1,
                group_can_do      = 1,
                security_flag     = 1,
                nominal_personnel = 0,
                moving_personnel  = 0,
                combat_personnel  = 0,
                actual_personnel  = 0,
                detail            = '',
                coverage          = 0.0;
        }
    }


    # ComputeForceActivity
    #
    # Computes the presence and activity personnel for all FRC groups.

    typemethod ComputeForceActivityFlags {} {
        # FIRST, get a list of the FRC-related abstract activities
        set actList [efrcactivity longnames]
        ldelete actList PRESENCE
        ldelete actList COMBAT

        # FIRST, clear security flags when security is too low, and 
        # determine whether units can be moving.
        rdb eval "
            SELECT n, g, a, 
                   security
            FROM activity_nga JOIN force_ng USING (n, g)
            WHERE a IN ('[join $actList ',']') 
        " {
            if {[parmdb get activity.FRC.$a.canBeMoving]} {
                set canBeMoving 1
            } else {
                set canBeMoving 0
            }

            set minSecurity \
                [qsecurity value [parmdb get activity.FRC.$a.minSecurity]]

            # Compare using the symbolic values.
            set security [qsecurity strictvalue $security]

            if {$security >= $minSecurity} {
                set security_flag 1
            } else {
                set security_flag 0
            }

            rdb eval {
                UPDATE activity_nga
                SET can_be_moving = $canBeMoving,
                    security_flag = $security_flag
                WHERE n=$n AND g=$g AND a=$a
            }
        }
    }

    # ComputeOrgActivityFlags
    #
    # Computes personnel engaged in activities for all ORG groups.

    typemethod ComputeOrgActivityFlags {} {
        # FIRST, Set the can_be_moving, group_can_do, and security_flag
        # flags.
        rdb eval {
            SELECT n, g, a, 
                   force_ng.security  AS security,
                   pgroups.orgtype    AS orgtype,
                   pgroups.medical    AS medical,
                   pgroups.engineer   AS engineer,
                   pgroups.support    AS support

            FROM activity_nga JOIN force_ng USING (n, g) JOIN pgroups
            WHERE pgroups.name = g
            AND   pgroups.type = 'ORG'
        } {
            # can_be_moving
            if {[parmdb get activity.ORG.$a.canBeMoving]} {
                set can_be_moving 1
            } else {
                set can_be_moving 0
            }

            # group_can_do
            set needed [parmdb get activity.ORG.$a.capability]

            if {[jout initialized]} {
                set orgIsActive [jout orgIsActive $n $g]
            } else {
                # For now, assume that it is.
                set orgIsActive 1
            }

            if {$orgIsActive &&
                (($medical  && $needed eq "MEDICAL")  ||
                 ($engineer && $needed eq "ENGINEER") ||
                 ($support  && $needed eq "SUPPORT"))} {
                set group_can_do 1
            } else {
                set group_can_do 0
            }

            # security
            set minSecurity \
                [qsecurity value [parmdb get \
                    activity.ORG.$a.minSecurity.$orgtype]]

            set security [qsecurity strictvalue $security]

            if {$security < $minSecurity} {
                set security_flag 0
            } else {
                set security_flag 1
            }

            # Save values
            rdb eval {
                UPDATE activity_nga
                SET can_be_moving = $can_be_moving,
                    group_can_do  = $group_can_do,
                    security_flag = $security_flag
                WHERE n=$n AND g=$g AND a=$a
            }
        }
    }


    # ComputeActivityPersonnel
    #
    # Computes the activity personnel for both group types.

    typemethod ComputeActivityPersonnel {} {
        # FIRST, Presence and Combat personnel
        rdb eval {
            SELECT nbhood                            AS n,
                   PGROUP                            AS g, 
                   COMBAT_STATUS                     AS combat,
                   moving                            AS moving,
                   total(live_units.TOTAL_PERSONNEL) AS troops
            FROM live_units
            WHERE group_type == 'FRC'
            AND   nbhood != ''
            GROUP BY n, g, combat, moving
        } {
            log detail nbstat \
                "n=$n g=$g com=$combat moving=$moving troops=$troops"

            if {$combat eq "COMBAT"} {
                rdb eval {
                    UPDATE activity_nga
                    SET nominal_personnel = nominal_personnel + $troops,
                        combat_personnel  = combat_personnel  + $troops,
                        actual_personnel  = actual_personnel  + $troops
                    WHERE n=$n AND g=$g AND a='COMBAT';

                    UPDATE activity_nga
                    SET combat_personnel  = combat_personnel  + $troops
                    WHERE n=$n AND g=$g AND a='PRESENCE';
                }

                if {$moving} {
                    rdb eval {
                        UPDATE activity_nga
                        SET moving_personnel = moving_personnel + $troops
                        WHERE n=$n AND g=$g AND a='COMBAT'
                    }
                }
            }

            rdb eval {
                UPDATE activity_nga
                SET nominal_personnel = nominal_personnel + $troops,
                    actual_personnel  = actual_personnel  + $troops
                WHERE n=$n AND g=$g AND a='PRESENCE'
            }

            if {$moving} {
                rdb eval {
                    UPDATE activity_nga
                    SET moving_personnel = moving_personnel + $troops
                    WHERE n=$n AND g=$g AND a='PRESENCE'
                }
            }
        }

        # NEXT, Determine which units are tasked with an activity but are
        # ineffective.  Begin by clearing the ineffective flag
        rdb eval {
            UPDATE units
            SET ineffective = 0
            WHERE alive = 1;
        }

        # NEXT, set the flag when appropriate. Note: MILITARY_TRAINING is
        # always ineffective because it does not effect satisfaction or
        # cooperation ever.
        rdb eval {
            UPDATE units
            SET ineffective = 1
            WHERE alive = 1
            AND ACTIVITY != ''
            AND ACTIVITY != 'NONE'
            AND (
              (COMBAT_STATUS = 'COMBAT')
              OR EXISTS(
                SELECT a FROM activity_nga
                WHERE activity_nga.n = units.nbhood
                AND   activity_nga.g = units.PGROUP
                AND   activity_nga.a = units.ACTIVITY
                AND   (
                  (activity_nga.can_be_moving = 0 AND units.moving = 1)
                  OR (activity_nga.security_flag = 0)
                  OR (activity_nga.group_can_do = 0)))
              OR (ACTIVITY = 'MILITARY_TRAINING'));
        }


        # NEXT, compute the personnel statistics
        rdb eval {
            SELECT PGROUP                            AS g, 
                   nbhood                            AS n,
                   activity                          AS a,
                   moving                            AS moving,
                   COMBAT_STATUS                     AS combat,
                   ineffective                       AS ineffective,
                   total(live_units.TOTAL_PERSONNEL) AS troops
            FROM live_units JOIN activity_nga
            WHERE nbhood     = activity_nga.n
            AND   PGROUP     = activity_nga.g
            AND   activity   = activity_nga.a
            AND   activity   NOT IN ('PRESENCE','COMBAT')
            GROUP BY n, g, activity, moving
        } {
            log detail nbstat "n=$n g=$g act=$a ineff=$ineffective combat=$combat moving=$moving troops=$troops"

            # Accumulate what the troops are doing.

            if {$moving} {
                set movingTroops $troops
            } else {
                set movingTroops 0
            }

            if {$combat eq "COMBAT"} {
                set combatTroops $troops
            } else {
                set combatTroops 0
            }

            if {$ineffective} {
                set actualTroops 0
            } else {
                set actualTroops $troops
            }

            # Update the nominal and actual troops
            rdb eval {
                UPDATE activity_nga
                SET nominal_personnel = nominal_personnel + $troops,
                    moving_personnel  = moving_personnel  + $movingTroops,
                    combat_personnel  = combat_personnel  + $combatTroops,
                    actual_personnel  = actual_personnel  + $actualTroops
                WHERE n=$n AND g=$g AND a=$a
            }
        }

        # NEXT, determine the location  of the activity by 
        # neighborhood and group; it is the location of the unit 
        # with the most TOTAL_PERSONNEL doing the activity.

        # TBD: I don't know that these are defined.
        set nn        [nbhoods size]
        set ngfrc     [frcgroups size]
        set na        [efrcactivity size]

        set maxtroops_nga [mat3d new $nn $ngfrc $na 0]

        # NEXT, COMBAT and PRESENCE
        set pidx [efrcactivity index PRESENCE]
        set cidx [efrcactivity index COMBAT]
        rdb eval {
            SELECT nbhood                            AS n,
                   PGROUP                            AS g, 
                   TOTAL_PERSONNEL                   AS troops,
                   COMBAT_STATUS                     AS combat,
                   moving                            AS moving,
                   location                          AS loc,
                   nbhoods.indx                      AS nidx,
                   pgroups.indx                      AS gidx
            FROM live_units JOIN nbhoods JOIN pgroups
            WHERE group_type == 'FRC'
            AND   nbhood != ''
            AND   nbhood = nbhoods.name
            AND   PGROUP = pgroups.name
        } {
            if {$troops > [lindex $maxtroops_nga $nidx $gidx $pidx]} { 
                lset maxtroops_nga $nidx $gidx $pidx $troops
                rdb eval {
                    UPDATE activity_nga
                    SET location = $loc
                    WHERE n = $n
                    AND   g = $g
                    AND   a = 'PRESENCE'
                }
            }
            if {$combat eq "COMBAT"} {
                if {$troops > [lindex $maxtroops_nga $nidx $gidx $cidx]} { 
                    lset maxtroops_nga $nidx $gidx $cidx $troops
                    rdb eval {
                        UPDATE activity_nga
                        SET location = $loc
                        WHERE n = $n
                        AND   g = $g
                        AND   a = 'COMBAT'
                    }
                }
            }
        }
        
        # NEXT, any other activities
        rdb eval {
            SELECT live_units.location AS loc,
                   nbhood              AS n,
                   PGROUP              AS g,
                   TOTAL_PERSONNEL     AS troops,
                   activity            AS a,
                   nbhoods.indx        AS nidx,
                   pgroups.indx        AS gidx
            FROM live_units JOIN activity_nga JOIN nbhoods JOIN pgroups
            WHERE nbhood   = activity_nga.n
            AND   PGROUP   = activity_nga.g
            AND   activity = activity_nga.a
            AND   nbhood = nbhoods.name
            AND   PGROUP = pgroups.name
        } {
            set aidx [efrcactivity index $a]
            if {$troops > [lindex $maxtroops_nga $nidx $gidx $aidx]} { 
                lset maxtroops_nga $nidx $gidx $aidx $troops
                rdb eval {
                    UPDATE activity_nga
                    SET location = $loc
                    WHERE n = $n
                    AND   g = $g
                    AND   a = $a
                }
            }
        }
    }


    # ComputeCoverage
    #
    # Computes activity coverage for all activities, both FRC and ORG>

    typemethod ComputeCoverage {} {
        rdb eval {
            SELECT activity_nga.n AS n,
                   activity_nga.g AS g,
                   activity_nga.a AS a,
                   actual_personnel,
                   force_n.population AS population,
                   pgroups.type AS type
            FROM activity_nga JOIN force_n JOIN pgroups
            WHERE force_n.n=activity_nga.n
            AND   activity_nga.g=pgroups.name
            AND   actual_personnel > 0
        } {
            set cov [CoverageFrac \
                         [parmdb get activity.$type.$a.coverage] \
                         $actual_personnel                 \
                         $population]

            rdb eval {
                UPDATE activity_nga
                SET coverage = $cov
                WHERE n=$n AND g=$g AND a=$a
            }
        }
    }


    # CoverageFrac covFunc troops population
    #
    # covFunc     The coverage function parameters: max, denominator
    # troops      The number of troops
    # pop         The neighborhood's total civilian population
    #
    # Computes the coverage fraction, i.e., the fraction of the
    # neighborhood covered by the activity.
    
    proc CoverageFrac {covFunc troops pop} {
        foreach {c d} $covFunc {}

        let td {double($troops)*$d/$pop}

        let exponent {-($td)*log(3)/($c)}

        let cf {1 - exp($exponent)}

        return $cf
    }

    #-------------------------------------------------------------------
    # Output Methods

    # total_force.n
    # volatility.n
    #
    # Return the vector

    typemethod total_force.n {} {
        rdb eval {
            SELECT total_force 
            FROM force_n JOIN nbhoods
            WHERE force_n.n = nbhoods.name
            ORDER BY nbhoods.indx
        }
    }

    typemethod volatility.n {} {
        rdb eval {
            SELECT volatility 
            FROM force_n JOIN nbhoods
            WHERE force_n.n = nbhoods.name
            ORDER BY nbhoods.indx
        }
    }

    # own_force.ng
    # local_force.ng
    # local_enemy.ng
    # force.ng
    # %force.ng
    # enemy.ng
    # %enemy.ng
    # security.ng
    #
    # Return the contents of the matrix.

    typemethod own_force.ng {} {
        rdb mat force_ng n g own_force \
            -ikeys [nbhoods names]     \
            -jkeys [pgroups names]
    }

    typemethod local_force.ng {} {
        rdb mat force_ng n g local_force \
            -ikeys [nbhoods names]       \
            -jkeys [pgroups names]
    }

    typemethod local_enemy.ng {} {
        rdb mat force_ng n g local_enemy \
            -ikeys [nbhoods names]       \
            -jkeys [pgroups names]
    }

    typemethod force.ng {} {
        rdb mat force_ng n g force \
            -ikeys [nbhoods names] \
            -jkeys [pgroups names]
    }

    typemethod %force.ng {} {
        rdb mat force_ng n g pct_force \
            -ikeys [nbhoods names]     \
            -jkeys [pgroups names]
    }

    typemethod enemy.ng {} {
        rdb mat force_ng n g enemy \
            -ikeys [nbhoods names] \
            -jkeys [pgroups names]
    }

    typemethod %enemy.ng {} {
        rdb mat force_ng n g pct_enemy \
            -ikeys [nbhoods names]     \
            -jkeys [pgroups names]
    }

    typemethod security.ng {} {
        rdb mat force_ng n g security \
            -ikeys [nbhoods names]    \
            -jkeys [pgroups names]
    }


    #-------------------------------------------------------------------
    # Debugging Typemethods

    # dump total_force.n
    # dump volatility.n

    typemethod {dump total_force.n} {} {
        vec pprintf [nbstat total_force.n] [nbhoods names] "%7d" 
    }

    typemethod {dump volatility.n} {} {
        vec pprintf [nbstat volatility.n] [nbhoods names] "%3d" 
    }

    # dump own_force.ng
    # dump local_force.ng
    # dump local_enemy.ng
    # dump force.ng
    # dump %force.ng
    # dump enemy.ng
    # dump %enemy.ng
    # dump security.ng
    #
    # Dumps the matrix.

    typemethod {dump own_force.ng} {} {
        mat pprintf [nbstat own_force.ng] "%7d" \
            [nbhoods names] [pgroups names]
    }

    typemethod {dump local_force.ng} {} {
        mat pprintf [nbstat local_force.ng] "%7d" \
            [nbhoods names] [pgroups names]
    }

    typemethod {dump local_enemy.ng} {} {
        mat pprintf [nbstat local_enemy.ng] "%7d" \
            [nbhoods names] [pgroups names]
    }

    typemethod {dump force.ng} {} {
        mat pprintf [nbstat force.ng] "%7d" \
            [nbhoods names] [pgroups names]
    }

    typemethod {dump %force.ng} {} {
        mat pprintf [nbstat %force.ng] "%3d" \
            [nbhoods names] [pgroups names]
    }

    typemethod {dump enemy.ng} {} {
        mat pprintf [nbstat enemy.ng] "%7d" \
            [nbhoods names] [pgroups names]
    }

    typemethod {dump %enemy.ng} {} {
        mat pprintf [nbstat %enemy.ng] "%3d" \
            [nbhoods names] [pgroups names]
    }

    typemethod {dump security.ng} {} {
        mat pprintq [nbstat security.ng] qsecurity \
            [nbhoods names] [pgroups names]
    }

    # dump coverage gtype ?options?
    #
    # gtype      ORG or FRC
    #
    # -nbhood    Which neighborhood (all if omitted)
    # -group     Which group (all if omitted)
    # -activity  Which activity (all if omitted)
    # -zeroes    Include activities with zero assets allocated.
    #
    # Dumps a table of coverage fractions with ancillary data.

    typemethod {dump coverage} {gtype args} {
        # FIRST, get and validate the group type
        egrouptype validate $gtype
        set gtype [egrouptype name $gtype]

        require {$gtype ne "CIV"} "invalid value \"CIV\""
        
        # NEXT, get and validate the options
        array set opts {
            -nbhood       *
            -group        *
            -activity     *
            -zeroes       0
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -nbhood {
                    set val [lshift args]

                    if {$val eq "*"} {
                        set opts(-nbhood) "*"
                    } else {
                        nbhoods validate $val
                        set opts(-nbhood) [nbhoods name $val]
                    }
                }

                -group {
                    set val [lshift args]

                    if {$val eq "*"} {
                        set opts(-group) "*"
                    } else {
                        if {$gtype eq "FRC"} {
                            frcgroups validate $val
                        } else {
                            org g validate $val
                        }
                        
                        set opts(-group) [pgroups name $val]
                    }
                }

                -activity {
                    set val [lshift args]

                    if {$val eq "*"} {
                        set opts(-activity) "*"
                    } else {
                        if {$gtype eq "FRC"} {
                            efrcactivity validate $val
                            set opts(-activity) [efrcactivity longname $val]
                        } else {
                            eorgactivity validate $val
                            set opts(-activity) [eorgactivity longname $val]
                        }
                    }
                }

                -zeroes {
                    set opts(-zeroes) 1
                }

                default {
                    error \
        "Unknown option name, \"$opt\", should be one of: [array names opts]"
                }
            }
        }

        # NEXT, set the conditions based on the inputs

        set narrative  [list "Report includes:"]
        set conditions {}

        # -nbhood
        if {$opts(-nbhood) eq "*"} {
            lappend narrative "All neighborhoods"
        } else {
            lappend narrative \
                "Neighborhood: $opts(-nbhood), [nbhoods longname $opts(-nbhood)]"
            lappend conditions "n='$opts(-nbhood)'"
        }

        # -group
        if {$opts(-group) eq "*"} {
            lappend narrative "All $gtype groups"
        } else {
            lappend narrative "Group: $opts(-group), [pgroups longname $opts(-group)]"
            lappend conditions "g='$opts(-group)'"
        }

        # -activity
        if {$opts(-activity) eq "*"} {
            lappend narrative "All $gtype activities"
        } else {
            lappend narrative "Activity: $opts(-activity)"
            lappend conditions "a='$opts(-activity)'"
        }

        # -zeroes
        if {$opts(-zeroes)} {
            lappend narrative \
                "Includes activities to which no personnel have been assigned."
            set coverageComp ">="
        } else {
            set coverageComp ">"
        }

        # NEXT, create a query to get just the desired data.
        if {[llength $conditions] > 0} {
            set whereClause "AND [join $conditions { AND }]"
        } else {
            set whereClause ""
        }

        # NEXT, do the query and return the result if not empty.
        set result [rdb query "
            SELECT n,
                   g,
                   CASE WHEN a == 'CHECKPOINT' AND detail == 'SCP' 
                       THEN 'CHECKPOINT (Explicit)' 
                        WHEN a == 'CHECKPOINT' AND detail != 'SCP'
                       THEN 'CHECKPOINT (Activity)'
                        ELSE a END,
                   CASE WHEN a == 'CHECKPOINT' AND detail == 'SCP' THEN 'n/a'
                        WHEN security_flag == 1 THEN 'Yes' 
                        ELSE 'No' END,
                   nominal_personnel,
                   actual_personnel,
                   format('%7s', percent(coverage))
            FROM activity_nga JOIN pgroups
            WHERE activity_nga.g = pgroups.name
            AND   pgroups.type = '$gtype'
            AND   nominal_personnel $coverageComp 0
            $whereClause
            ORDER BY n, g, a
        " -labels {
            "Nbhd" "Group" "Activity" "Secure?" "Nom.Pers." 
            "Act.Pers." "Coverage"
        } -headercols 3]
        
        if {$result eq ""} {
            set result \
         "There are no activities to which personnel have been assigned."
        }

        set narrative [join $narrative "\n  "]

        return "$narrative\n\n$result"
    }

    # dump security ?options?
    #
    # -nbhood    Which neighborhood, or "*"
    # -group     Which group, or "*"
    #
    # Dumps a table of group security by nbhood.

    typemethod {dump security} {args} {
        # FIRST, get and validate the options
        array set opts {
            -group   * 
            -nbhood  *
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -nbhood {
                    set val [lshift args]

                    if {$val eq "*"} {
                        set opts(-nbhood) "*"
                    } else {
                        nbhoods validate $val
                        set opts(-nbhood) [nbhoods name $val]
                    }
                }

                -group {
                    set val [lshift args]

                    if {$val eq "*"} {
                        set opts(-group) "*"
                    } else {
                        pgroups validate $val
                        set opts(-group) [pgroups name $val]
                    }
                }

                default {
                    error \
        "Unknown option name, \"$opt\", should be one of: [array names opts]"
                }
            }
        }

        # NEXT, set the conditions based on the inputs

        set narrative  [list "Report includes:"]
        set conditions {}

        # -nbhood
        if {$opts(-nbhood) eq "*"} {
            lappend narrative "All neighborhoods"
        } else {
            lappend narrative \
             "Neighborhood: $opts(-nbhood), [nbhoods longname $opts(-nbhood)]"
            lappend conditions "n='$opts(-nbhood)'"
        }

        # -group
        if {$opts(-group) eq "*"} {
            lappend narrative "All groups"
        } else {
            lappend narrative \
                "Group: $opts(-group), [pgroups longname $opts(-group)]"
            lappend conditions "g='$opts(-group)'"
        }

        # NEXT, create a query to get just the desired data.
        if {[llength $conditions] > 0} {
            set whereClause "WHERE [join $conditions { AND }]"
        } else {
            set whereClause ""
        }

        # NEXT, do the query and return the result if not empty.
        set result [rdb query "
            SELECT n,
                   g,
                   format('%4d, %s',
                          security,
                          qsecurity('longname',security)),
                   format('  %3d%%', pct_force),
                   format('  %3d%%', pct_enemy),
                   format('  %3d%%', volatility),
                   format('%7.2f', volatility_gain),
                   format('  %3d%%', nominal_volatility)
            FROM force_ng JOIN force_n USING (n)
            $whereClause
            ORDER BY n, g
        " -labels {
            "Nbhd" "Group" "Security" "%Force" "%Enemy" "EffVty"
            "VtyGain" "NomVty"
        } -headercols 2]

        set narrative [join $narrative "\n  "]

        return "$narrative\n\n$result"
    }
}








