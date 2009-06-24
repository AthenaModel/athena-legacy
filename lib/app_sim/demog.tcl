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
    # Computes demog_ng(n,g) and demog_n(n) for all n, g.
    #
    # This pretends to be a mutator, to make it easier to use
    # in undo scripts.

    typemethod analyze {} {
        $type ComputeNG
        $type ComputeN

        # Notify the GUI that demographics may have changed.
        notifier send $type <Update>

        return [mytypemethod analyze]
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

    #-------------------------------------------------------------------
    # Queries

    # getng n g ?parm?
    #
    # n     A neighborhood
    # g     A group in the neighborhood
    # parm  A demog_ng column
    #
    # Retrieves a row dictionary, or a particular column value.

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


    # getn n ?parm?
    #
    # n     A neighborhood
    # parm  A demog_n column
    #
    # Retrieves a row dictionary, or a particular column value.

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
}

