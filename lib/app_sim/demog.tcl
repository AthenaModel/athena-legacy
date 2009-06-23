#-----------------------------------------------------------------------
# TITLE:
#    demog.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Demographic Model, main module.
#
#    This module is responsible for computing demographics for neighborhoods
#    and neighborhood groups.  The data is stored in the demog_n and
#    demog_ng tables; entries in these tables are created and deleted by
#    nbhood(sim) and nbgroups(sim) respectively, as neighborhoods and
#    neighborhood groups come and go.
#
#-----------------------------------------------------------------------

snit::type demog {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Initialization

    # init
    #
    # Initializes the module before the simulation first starts to run.

    typemethod init {} {
        # NEXT, Demog is up.
        log normal demog "Initialized"
    }

    #-------------------------------------------------------------------
    # Analysis

    # analyze
    #
    # Computes demog_ng(n,g) and demog_n(n) for all n, g

    typemethod analyze {} {
        profile $type ComputeNG
        profile $type ComputeN

        return
    }

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
            SELECT n, g, population AS base
            FROM nbgroups
        } {
            rdb eval {
                UPDATE demog_ng
                SET implicit   = $base - explicit  - attrition,
                    population = $base - displaced - attrition
                WHERE n=$n AND g=$g
            }
        }
    }

    typemethod ComputeN {} {
        # FIRST, get total implicit population and labor force
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
            WHERE gtype='CIV'
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
}

