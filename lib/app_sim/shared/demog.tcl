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
        $type analyze pop
    }

    #-------------------------------------------------------------------
    # Group: Analysis of Population

    # Type Method: analyze pop
    #
    # Computes the population statistics in demog_g(g), demog_n(n), 
    # and demog_local for all n, g.  This routine depends on the
    # units staffed by activity(sim).
    #
    # Syntax:
    #   analyze pop

    typemethod {analyze pop} {} {
        $type ComputePopG
        $type ComputePopN
        $type ComputePopLocal

        # Notify the GUI that demographics may have changed.
        notifier send $type <Update>

        return
    }

    # Type Method: ComputePopG
    #
    # Computes the population statistics for each civilian group.
    #
    # Syntax:
    #   ComputePopG

    typemethod ComputePopG {} {
        # FIRST, get resident and subsistence population
        rdb eval {
            SELECT civgroups.n            AS n,
                   civgroups.g            AS g,
                   civgroups.sa_flag      AS sa_flag,
                   total(units.personnel) AS population
            FROM civgroups
            JOIN units
            ON (civgroups.n=units.origin AND civgroups.g=units.g)
            WHERE units.n = units.origin AND units.personnel > 0
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

        # NEXT, get displaced population.
        rdb eval {
            SELECT origin, g, total(personnel) AS displaced
            FROM units
            WHERE gtype='CIV' AND n != origin AND personnel > 0
            GROUP BY origin, g
        } {
            rdb eval {
                UPDATE demog_g
                SET displaced  = $displaced
                WHERE g=$g;
            }
        }

        # NEXT, accumulate labor force.
        rdb eval {
            SELECT civgroups.n             AS n,
                   civgroups.g             AS g, 
                   units.a                 AS a, 
                   total(units.personnel)  AS personnel
            FROM civgroups 
            JOIN units ON (civgroups.n=units.origin AND civgroups.g=units.g)
            WHERE NOT civgroups.sa_flag AND units.n=units.origin
            GROUP BY g,a
        } {
            set LFF [parm get demog.laborForceFraction.$a]

            if {$LFF == 0} {
                continue
            }

            let LF {round($LFF * $personnel)}

            rdb eval {
                UPDATE demog_g
                SET labor_force = labor_force + $LF
                WHERE g=$g;
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
            WHERE gtype='CIV' AND n != origin
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
            FROM demog_g
            JOIN civgroups USING (g)
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
            # number of unemployed workers
            let unemployed {round($labor_force * $ur / 100.0)}

            # unemployed per capita
            let upc {100.0 * $unemployed / $population}

            # Unemployment Attitude Factor
            set uaf [zcurve eval $zuaf $upc]

            # Save results
            rdb eval {
                UPDATE demog_g
                SET unemployed = $unemployed,
                    upc        = $upc,
                    uaf        = $uaf
                WHERE g=$g;
            }
        }

        # NEXT, compute the neighborhood statistics.  These aren't
        # simply a roll-up of the civgroup stats because the nbhood
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

    # Type Method: getg
    #
    # Retrieves a row dictionary, or a particular column value, from
    # demog_g.
    #
    # Syntax:
    #   getg _g ?parm?_
    #
    #   g    - A group in the neighborhood
    #   parm - A demog_g column name

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

    #-------------------------------------------------------------------
    # Mutators

    # mutate attritResident parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g                Group ID
    #    casualties       A number of casualites to attrit
    #
    # Updates a demog_g record given the parms, which are presumed to be
    # valid.

    typemethod {mutate attritResident} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT population,attrition FROM demog_g
                WHERE g=$g
            } {}

            if {$casualties >= 0} {
                let casualties {min($casualties, $population - 1)}
                let undoCasualties {-$casualties}
                set undoing 0
            } else {
                set undoing 1
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE demog_g
                SET attrition = attrition + $casualties,
                    population = population - $casualties
                WHERE g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::demog <Update>

            # NEXT, If we're not undoing, return the undo command.
            if {!$undoing} {
                return [mytypemethod mutate attritResident \
                        [list g $g casualties $undoCasualties]]
            } else {
                return
            }
        }
    }
    
    # mutate attritDisplaced parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g                Group ID
    #    casualties       A number of casualites to attrit
    #
    # Updates a demog_g record given the parms, which are presumed to be
    # valid.

    typemethod {mutate attritDisplaced} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT displaced,attrition FROM demog_g
                WHERE g=$g
            } {}

            if {$casualties >= 0} {
                let casualties {min($casualties, $displaced)}
                let undoCasualties {-$casualties}
                set undoing 0
            } else {
                set undoing 1
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE demog_g
                SET attrition = attrition + $casualties,
                    displaced = displaced - $casualties
                WHERE g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::demog <Update>

            # NEXT, If we're not undoing, return the undo command.
            if {!$undoing} {
                return [mytypemethod mutate attritDisplaced \
                        [list g $g casualties $undoCasualties]]
            } else {
                return
            }
        }
    }
}

