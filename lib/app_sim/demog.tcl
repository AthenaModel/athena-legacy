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
# Module: demog
#
# athena_sim(1): Demographic Model, main module.
#
# This module is responsible for computing demographics for neighborhoods
# and neighborhood groups.  The data is stored in the demog_ng, demog_n,
# and demog_local tables.  Entries in the demog_n and demog_ng tables
# are created and deleted by nbhood(sim) and nbgroups(sim) respectively, 
# as neighborhoods and neighborhood groups come and go.  The (single)
# entry in the demog_local table is created/replaced on <analyze pop>.
#
#-----------------------------------------------------------------------

snit::type demog {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Group: Analysis of Population

    # Type Method: analyze pop
    #
    # Computes the population statistics in demog_ng(n,g), demog_n(n), 
    # and demog_local for all n, g.  This routine is called by other 
    # modules when something happens to neighborhood population.
    #
    # This command acts as a mutator, to make it easier to use
    # in undo scripts.
    #
    # Syntax:
    #   analyze pop

    typemethod "analyze pop" {} {
        $type ComputePopNG
        $type ComputePopN
        $type ComputePopLocal

        # Notify the GUI that demographics may have changed.
        notifier send $type <Update>

        return [mytypemethod analyze pop]
    }

    # Type Method: ComputePopNG
    #
    # Computes the population statistics for each neighborhood group.
    #
    # Syntax:
    #   ComputePopNG

    typemethod ComputePopNG {} {
        # FIRST, get explicit and displaced personnel.
        rdb eval {
            UPDATE demog_ng
            SET explicit    = 0,
                displaced   = 0,
                labor_force = 0;
        }

        rdb eval {
            SELECT origin                            AS origin,
                   g                                 AS g,
                   total(personnel)                  AS explicit,
                   total(
                       CASE WHEN n != origin
                       THEN personnel ELSE 0 END
                   )                                 AS displaced
            FROM units
            WHERE origin != 'NONE'
            GROUP BY origin, g
        } {
            rdb eval {
                UPDATE demog_ng
                SET explicit  = $explicit,
                    displaced = $displaced
                WHERE n=$origin AND g=$g
            }
        }

        # NEXT, Add labor force in units.  Don't adjust for
        # subsistence; we'll do that when we add in the 
        # implicit population's contribution.
        rdb eval {
            SELECT n, g, total(personnel) AS personnel, a
            FROM units
            WHERE origin = n
            GROUP by n, g, a
        } {
            set LFF [parm get demog.laborForceFraction.$a]

            if {$LFF == 0} {
                continue
            }

            rdb eval {
                UPDATE demog_ng
                SET labor_force = labor_force + $personnel*$LFF
                WHERE n=$n AND g=$g;
            }
        }


        # NEXT, compute implicit, population, subsistence, 
        # consumers, and implicit labor force.
        set LFF [parm get demog.laborForceFraction.NONE]

        rdb eval {
            SELECT n, g, basepop, sap
            FROM nbgroups
        } {
            rdb eval {
                UPDATE demog_ng
                SET implicit   = $basepop - explicit  - attrition,
                    population = $basepop - displaced - attrition
                WHERE n=$n AND g=$g;

                UPDATE demog_ng
                SET subsistence = population*$sap/100.0,
                    consumers   = population - population*$sap/100.0,
                    labor_force = (labor_force + implicit * $LFF) *
                                  (100.0 - $sap)/100.0
                WHERE n=$n AND g=$g;
            }
        }
    }

    # Type Method: ComputePopN
    #
    # Computes the population statistics and labor force for each
    # neighborhood.
    #
    # Syntax:
    #   ComputePopN

    typemethod ComputePopN {} {
        # FIRST, compute the displaced populationa and displaced 
        # labor force for each neighborhood.
        rdb eval {
            UPDATE demog_n
            SET displaced             = 0,
                displaced_labor_force = 0;
        }

        rdb eval {
            SELECT n, a, total(personnel) AS personnel
            FROM units
            WHERE gtype='CIV' AND n != origin AND n != ''
            GROUP BY n, a
        } {
            set LFF [parm get demog.laborForceFraction.$a]

            rdb eval {
                UPDATE demog_n
                SET displaced = displaced + $personnel,
                    displaced_labor_force = 
                        displaced_labor_force + $LFF*$personnel
                WHERE n=$n
            }
        }

        # NEXT, compute neighborhood population, consumers, and
        # labor force given the neighborhood groups and the
        # displaced personnel.
        rdb eval {
            SELECT n,
                   total(population)  AS population,
                   total(subsistence) AS subsistence,
                   total(consumers)   AS consumers, 
                   total(labor_force) AS labor_force
            FROM demog_ng
            GROUP BY n
        } {
            rdb eval {
                UPDATE demog_n
                SET population  = displaced + $population,
                    subsistence = $subsistence,
                    consumers   = displaced + $consumers,
                    labor_force = displaced_labor_force + $labor_force
                WHERE n=$n
            }
        }

        return
    }

    # Type Method: ComputePopLocal
    #
    # Computes the population statistics and labor force for the
    # local region of interest.
    #
    # Syntax:
    #   ComputePopLocal

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
    # Group: Analysis of Economic Effects on the Population

    # Type Method: analyze econ
    #
    # Computes the effects of the economy on the population.
    #
    # Syntax:
    #   analyze econ

    typemethod "analyze econ" {} {
        # FIRST, get the unemployment rate and the Unemployment
        # Factor Z-curve.
        set ur   [econ value Out::UR]
        set zuaf [parmdb get demog.Zuaf]

        # NEXT, compute the neighborhood group statistics
        foreach {n g population labor_force} [rdb eval {
            SELECT n, g, population, labor_force
            FROM demog_ng
            JOIN nbhoods USING (n)
            WHERE nbhoods.local
        }] {
            # number of unemployed workers
            let unemployed {round($labor_force * $ur / 100.0)}

            # unemployed per capita
            let upc {100.0 * $unemployed / $population}

            # Unemployment Attitude Factor
            set uaf [zcurve eval $zuaf $upc]

            # Save results
            rdb eval {
                UPDATE demog_ng
                SET unemployed = $unemployed,
                    upc        = $upc,
                    uaf        = $uaf
                WHERE n=$n AND g=$g;
            }
        }

        # NEXT, compute the neighborhood statistics.  These aren't
        # simply a roll-up of the nbgroup stats because the nbhood
        # might contain displaced personnel.
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
                set unemployed 0
                set upc        0.0
                set uaf        0.0
                
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
    # Group: Queries

    # Type Method: getng
    #
    # Retrieves a row dictionary, or a particular column value, from
    # demog_ng.
    #
    # Syntax:
    #   getng _n g ?parm?_
    #
    #   n    - A neighborhood
    #   g    - A group in the neighborhood
    #   parm - A demog_ng column name

    typemethod getng {n g {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM demog_ng WHERE n=$n AND g=$g} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }


    # Type Method: getn
    #
    # Retrieves a row dictionary, or a particular column value, from
    # demog_n.
    #
    # Syntax:
    #   getn _n ?parm?_
    #
    #   n    - A neighborhood
    #   parm - A demog_n column name

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

    # Type Method: getlocal
    #
    # Retrieves a row dictionary, or a particular column value, from
    # demog_local.
    #
    # Syntax:
    #   getlocal _?parm?_
    #
    #   parm - A demog_local column name

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
}

