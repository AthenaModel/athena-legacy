#-----------------------------------------------------------------------
# FILE: demog.tcl
#
#   Athena Demographics Model singleton
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# demog
#
# athena_sim(1): Demographic Model, main module.
#
# This module is responsible for computing demographics for neighborhoods
# and neighborhood groups.  The data is stored in the demog_g, demog_n,
# and demog_local tables.  Entries in the demog_n and demog_g tables
# are created and deleted by nbhood(sim) and civgroups(sim) respectively, 
# as neighborhoods and civilian groups come and go.  The (single)
# entry in the demog_local table is created/replaced on <analyze pop>.
#
#-----------------------------------------------------------------------

snit::type demog {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Initialization

    # start
    # 
    # Computes population statistics at scenario lock.

    typemethod start {} {
        # FIRST, populate the demog_g and demog_n tables.

        rdb eval {
            INSERT INTO demog_g(g,real_pop,population)
            SELECT g, basepop, basepop FROM civgroups;
            
            INSERT INTO demog_n(n)
            SELECT n FROM nbhoods;
        }
        
        # NEXT, do the initial population analysis
        $type stats
    }

    #-------------------------------------------------------------------
    # Population Stats

    # stats
    #
    # Computes the population statistics, both breakdowns and
    # rollups, in demog_g(g), demog_n(n), and demog_local for all n, g.
    #
    # This routine can be called at any time after scenario lock.

    typemethod stats {} {
        $type ComputePopG
        $type ComputePopN
        $type ComputePopLocal

        # Notify the GUI that demographics may have changed.
        notifier send $type <Update>

        return
    }

    # ComputePopG
    #
    # Computes the population statistics for each civilian group.

    typemethod ComputePopG {} {
        # FIRST, get the labor force fraction.
        set LFF [parm get demog.laborForceFraction.NONE]
   
        # NEXT, compute the breakdown for all groups.
        foreach {g population sa_flag} [rdb eval {
            SELECT g, population, sa_flag
            FROM demog_g JOIN civgroups USING (g)
        }] {
            if {$sa_flag} {
                let subsistence $population
                let consumers   0
                let labor_force 0
            } else {
                let subsistence 0
                let consumers   $population
                let labor_force {round($LFF * $consumers)}
            }

            rdb eval {
                UPDATE demog_g
                SET subsistence = $subsistence,
                    consumers   = $consumers,
                    labor_force = $labor_force
                WHERE g=$g;
            }
        }
    }

    # ComputePopN
    #
    # Computes the population statistics and labor force for each
    # neighborhood.

    typemethod ComputePopN {} {
        # FIRST, compute neighborhood population, consumers, and
        # labor force given the neighborhood groups.
        rdb eval {
            SELECT n,
                   total(population)  AS population,
                   total(subsistence) AS subsistence,
                   total(consumers)   AS consumers, 
                   total(labor_force) AS labor_force
            FROM demog_g
            JOIN civgroups USING (g)
            GROUP BY n
        } {
            rdb eval {
                UPDATE demog_n
                SET population  = $population,
                    subsistence = $subsistence,
                    consumers   = $consumers,
                    labor_force = $labor_force
                WHERE n=$n
            }
        }

        return
    }

    # ComputePopLocal
    #
    # Computes the population statistics and labor force for the
    # local region of interest.

    typemethod ComputePopLocal {} {
        # FIRST, compute and save the total population and
        # labor force in the local region.

        rdb eval {
            DELETE FROM demog_local;

            INSERT INTO demog_local
            SELECT total(population), total(consumers), total(labor_force)
            FROM demog_n
            JOIN nbhoods USING (n)
            WHERE nbhoods.local = 1;
        }
    }


    #-------------------------------------------------------------------
    # Population Growth/Change
    
    # growth
    #
    # Computes the adjustment to each civilian group's population
    # based on its change rate.
    
    typemethod growth {} {
        foreach {g real_pop pop_cr} [rdb eval {
            SELECT g, real_pop, pop_cr
            FROM civgroups JOIN demog_g USING (g)
            WHERE pop_cr != 0.0
        }] {
            # FIRST, compute the delta.  Note that pop_cr is an
            # annual rate expressed as a percentage; we need a
            # weekly fraction.  Thus, we divide by 100*52.
            let delta {$real_pop * $pop_cr/5200.0}
            log detail demog "Group $g's population changes by $delta"
            demog adjust $g $delta
        }
    }
    
    
    #-------------------------------------------------------------------
    # Analysis of Economic Effects on the Population

    # econstats
    #
    # Computes the effects of the economy on the population.

    typemethod econstats {} {
        # FIRST, get the unemployment rate and the Unemployment
        # Factor Z-curve.  Assume no unemployment if the econ
        # model is disabled.

        if {![parmdb get econ.disable]} {
            set ur [econ value Out::UR]
        } else {
            set ur 0
        }

        set zuaf [parmdb get demog.Zuaf]

        # NEXT, compute the neighborhood group statistics
        foreach {n g population labor_force} [rdb eval {
            SELECT n, g, population, labor_force
            FROM demog_g
            JOIN civgroups USING (g)
            JOIN nbhoods USING (n)
            WHERE nbhoods.local
            GROUP BY g
        }] {
            if {$population > 0} {
                # number of unemployed workers
                let unemployed {round($labor_force * $ur / 100.0)}

                # unemployed per capita
                let upc {100.0 * $unemployed / $population}

                # Unemployment Attitude Factor
                set uaf [zcurve eval $zuaf $upc]
            } else {
                let unemployed 0
                let upc        0.0
                let uaf        0.0
            }

            # Save results
            rdb eval {
                UPDATE demog_g
                SET unemployed = $unemployed,
                    upc        = $upc,
                    uaf        = $uaf
                WHERE g=$g;
            }
        }

        # NEXT, compute the neighborhood statistics.
        foreach {n population labor_force} [rdb eval {
            SELECT n, population, labor_force
            FROM demog_n
            JOIN nbhoods USING (n)
            WHERE nbhoods.local
        }] {
            if {$population > 0.0} {
                # number of unemployed workers
                let unemployed {round($labor_force * $ur / 100.0)}

                # unemployed per capita
                let upc {100.0 * $unemployed / $population}

                # Unemployment Attitude Factor
                set uaf [zcurve eval $zuaf $upc]
            } else {
                let unemployed 0
                let upc        0.0
                let uaf        0.0
            }

            # Save results
            rdb eval {
                UPDATE demog_n
                SET unemployed = $unemployed,
                    upc        = $upc,
                    uaf        = $uaf
                WHERE n=$n;
            }
        }


        # NEXT, Notify the GUI that demographics may have changed.
        notifier send $type <Update>

        return
    }

    #-------------------------------------------------------------------
    # Queries

    # getg g ?parm?
    #
    #   g    - A group in the neighborhood
    #   parm - A demog_g column name
    # Retrieves a row dictionary, or a particular column value, from
    # demog_g.

    typemethod getg {g {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM demog_g WHERE g=$g} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }


    # getn n ?parm?
    #
    #   n    - A neighborhood
    #   parm - A demog_n column name
    #
    # Retrieves a row dictionary, or a particular column value, from
    # demog_n.

    typemethod getn {n {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM demog_n WHERE n=$n} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }

    # getlocal ?parm?
    #
    #   parm - A demog_local column name
    #
    # Retrieves a row dictionary, or a particular column value, from
    # demog_local.

    typemethod getlocal {{parm ""}} {
        # FIRST, get the data
        rdb eval {
            SELECT * FROM demog_local LIMIT 1
        } row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }
    
    # gIn n
    #
    # n  - A neighborhood ID
    #
    # Returns a list of the NON-EMPTY civ groups that reside 
    # in the neighborhood.

    typemethod gIn {n} {
        rdb eval {
            SELECT g 
            FROM demog_g 
            JOIN civgroups USING (g)
            WHERE n=$n AND population > 0
            ORDER BY g
        }
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Note: these are not mutators in the sense of an order mutator.

    # adjust g delta
    #
    # g      - Group ID
    # delta  - Some change to population
    #
    # Adjusts a population figure by some amount, which may be positive
    # or negative, and may include a fractional part.  Fractional
    # parts are accumulated over time.  The integer population is
    # the rounded "real_pop".  If the "real_pop" is less than 1,
    # it is set to zero.
    #
    # Note that this routine doesn't recompute all of the breakdowns
    # and roll-ups; call [demog stats] as needed.

    typemethod adjust {g delta} {
        set real_pop [$type getg $g real_pop]
        
        let real_pop {max(0.0, $real_pop + $delta)}
        
        # If it's less than 1.0, make it zero
        if {$real_pop < 1.0} {
            let real_pop {0.0}
        }
        
        let population {floor(round($real_pop))}
        
        rdb eval {
            UPDATE demog_g
            SET population = $population,
                real_pop   = $real_pop
            WHERE g=$g
        } {}
    }

    # flow f g delta
    #
    # f     - A civilian group
    # g     - Another civilian group
    # delta - Some number of people
    #
    # Flows up to delta people from group f to group g.  The
    # delta can include fractional flows.
    
    typemethod flow {f g delta} {
        # FIRST, Make sure delta's not too big.
        set fpop [demog getg $f population]
        let delta {min($fpop, $delta)}
        
        # NEXT, Adjust the two groups
        demog adjust $f -$delta
        demog adjust $g $delta
    
        # NEXT, Record the change
        if {[parm get hist.pop]} {
            rdb eval {
                INSERT OR IGNORE INTO hist_flow(t,f,g)
                VALUES(now(), $f, $g);
                
                UPDATE hist_flow
                SET flow = flow + $delta
                WHERE t=now() AND f=$f AND g=$g;
            }
        }
    }
    
    # attrit g casualties
    #
    # g           - Group ID
    # casualties  - A number of casualites to attrit
    #
    # Attrits a civilian group's population.  Note that it doesn't
    # recompute all of the breakdowns and roll-ups; call
    # [demog stats] as needed.  Casualties never have a fractional
    # part.
    #
    # TBD: This routine could be simplified

    typemethod attrit {g casualties} {
        # FIRST, get the undo information
        rdb eval {
            SELECT population,attrition FROM demog_g
            WHERE g=$g
        } {}

        assert {$casualties >= 0}
        let casualties {min($casualties, $population)}
        let undoCasualties {-$casualties}
        set undoing 0

        # NEXT, Update the group
        rdb eval {
            UPDATE demog_g
            SET attrition = attrition + $casualties,
                population = population - $casualties,
                real_pop = real_pop - $casualties
            WHERE g=$g
        }
    }
}

