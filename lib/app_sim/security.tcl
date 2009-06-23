#-----------------------------------------------------------------------
# TITLE:
#    security.tcl
#
# AUTHOR:
#    Will Duquette
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1) Simulation Module: Force & Security
#
#    This module contains code which analyzes the status of each
#    neighborhood, including group force, neighborhood volatility, 
#    and group security.  The results are used by the DAM rule sets, as
#    well as by other modules.
#
#    ::security is a singleton object implemented as a snit::type.  To
#    initialize it, call "::security init".  It can be re-initialized
#    on demand.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# security

snit::type security {
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

        # TBD: force_n.population should probably be removed.
        # It's not used by security(sim), and other modules
        # should be using demog(sim).
        rdb eval {
            SELECT n, total(basepop) AS pop
            FROM nbgroups
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

        # NEXT, do an initial analysis.
        security analyze

        # NEXT, Security is up.
        log normal security "Initialized"
    }

    # clear
    #
    # Clears the data from the activity_nga table

    typemethod clear {} {
        rdb eval { 
            DELETE FROM force_n;
            DELETE FROM force_ng;
        }
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
        security ComputeOwnForce
        security ComputeLocalFriendsAndEnemies
        security ComputeAllFriendsAndEnemies
        security ComputeTotalForce
        security ComputePercentForce

        # NEXT, compute the volatility for each neighborhood.
        security ComputeVolatility

        # NEXT, compute the security for each group in each nbhood.
        security ComputeSecurity
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
}








