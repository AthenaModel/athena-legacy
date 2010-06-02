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
# entry in the demog_local table is created/replaced on <analyze>.
#
#-----------------------------------------------------------------------

snit::type demog {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Group: Analysis

    # Type Method: analyze
    #
    # Computes demog_ng(n,g), demog_n(n), and demog_local for all n, g.
    # This routine is called by other modules when something happens to
    # neighborhood population.
    #
    # This command acts as a mutator, to make it easier to use
    # in undo scripts.
    #
    # Syntax:
    #   analyze

    typemethod analyze {} {
        $type ComputeNG
        $type ComputeN
        $type ComputeLocal

        # Notify the GUI that demographics may have changed.
        notifier send $type <Update>

        return [mytypemethod analyze]
    }

    # Type Method: ComputeNG
    #
    # Computes the population statistics for each neighborhood group.
    #
    # Syntax:
    #   ComputeNG

    typemethod ComputeNG {} {
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

    # Type Method: ComputeN
    #
    # Computes the population statistics and labor force for each
    # neighborhood.
    #
    # Syntax:
    #   ComputeN

    typemethod ComputeN {} {
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

    # Type Method: ComputeLocal
    #
    # Computes the population statistics and labor force for the
    # local region of interest.
    #
    # Syntax:
    #   ComputeLocal

    typemethod ComputeLocal {} {
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

