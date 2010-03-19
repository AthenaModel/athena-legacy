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
            SET explicit =  0,
                displaced = 0
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
            GROUP BY origin, g
        } {
            rdb eval {
                UPDATE demog_ng
                SET explicit  = $explicit,
                    displaced = $displaced
                WHERE n=$origin AND g=$g
            }
        }

        # NEXT, compute implicit and population
        rdb eval {
            SELECT n, g, basepop
            FROM nbgroups
        } {
            rdb eval {
                UPDATE demog_ng
                SET implicit   = $basepop - explicit  - attrition,
                    population = $basepop - displaced - attrition
                WHERE n=$n AND g=$g
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
        # FIRST, initialize the pop() and labor() arrays
        set dict [rdb eval {SELECT n, 0 FROM nbhoods}]
        array set pop $dict
        array set labor $dict

        # NEXT, get total implicit population and labor force
        set lff [parmdb get demog.laborForceFraction.NONE]

        rdb eval {
            SELECT n, total(implicit) AS implicit
            FROM demog_ng
            GROUP BY n
        } {
            set pop($n) $implicit
            set labor($n) [expr {$lff * $implicit}]
        }

        # NEXT, get total personnel
        rdb eval {
            SELECT n, a, total(personnel) AS personnel
            FROM units
            WHERE gtype='CIV' AND n != ''
            GROUP BY n, a
        } {
            set pop($n) [expr {$pop($n) + $personnel}]
            set lff [parmdb get demog.laborForceFraction.$a]
            set labor($n) [expr {$labor($n) + $lff * $personnel}]
        }

        # NEXT, save pop and labor
        foreach n [array names pop] {
            set P $pop($n)
            set L $labor($n)

            rdb eval {
                UPDATE demog_n
                SET population  = $P,
                    labor_force = $L
                WHERE n = $n
            }
        }
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
            SELECT total(population), total(labor_force)
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

