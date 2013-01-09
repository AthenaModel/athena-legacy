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
            INSERT INTO demog_g(g) SELECT g FROM civgroups;
            INSERT INTO demog_n(n) SELECT n FROM nbhoods;
        }
        
        # NEXT, do the initial population analysis
        $type analyze pop
    }

    #-------------------------------------------------------------------
    # Group: Analysis of Population

    # analyze pop
    #
    # Computes the population statistics in demog_g(g), demog_n(n), 
    # and demog_local for all n, g.  This routine depends on the
    # units staffed by activity(sim).

    typemethod {analyze pop} {} {
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
        # FIRST, get resident and subsistence population
        rdb eval {
            SELECT civgroups.n            AS n,
                   civgroups.g            AS g,
                   civgroups.sa_flag      AS sa_flag,
                   total(units.personnel) AS population
            FROM civgroups JOIN units USING (g)
            WHERE units.personnel > 0
            GROUP BY civgroups.g
        } {
            if {$sa_flag} {
                let consumers   0
                let subsistence $population
            } else {
                set consumers   $population
                set subsistence 0
            }

            rdb eval {
                UPDATE demog_g
                SET population  = $population,
                    subsistence = $subsistence,
                    consumers   = $consumers,
                    labor_force = 0
                WHERE g=$g;
            }
        }

        # NEXT, accumulate labor force.
        # TBD: Once groups can be displaced, we'll need to
        # retrieve it and use the correct LFF here.
        rdb eval {
            SELECT civgroups.n             AS n,
                   civgroups.g             AS g, 
                   total(units.personnel)  AS personnel
            FROM civgroups JOIN units USING (g)
            WHERE NOT civgroups.sa_flag
            GROUP BY g
        } {
            set LFF [parm get demog.laborForceFraction.NONE]

            if {$LFF == 0} {
                continue
            }

            let LF {round($LFF * $personnel)}

            rdb eval {
                UPDATE demog_g
                SET labor_force = $LF
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
    # Analysis of Economic Effects on the Population

    # analyze econ
    #
    # Computes the effects of the economy on the population.

    typemethod {analyze econ} {} {
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

    # attrit parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g                Group ID
    #    casualties       A number of casualites to attrit
    #
    # Updates a demog_g record given the parms, which are presumed to be
    # valid.
    #
    # This is not an order mutator, in the usual sense; it cannot
    # be undone.

    typemethod attrit {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
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
                    population = population - $casualties
                WHERE g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::demog <Update>
        }
    }
}

