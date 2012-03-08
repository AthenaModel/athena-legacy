#-----------------------------------------------------------------------
# FILE: hist.tcl
#
#   Athena History Module
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
# Module: hist
#
# This module is responsible for saving historical data as time 
# progresses.  Because different things happen at different times,
# there are several methods: <tick>, which is called at every time
# tick, and methods like <aam> and <econ> which are called at each
# AAM and Econ model tock.  The sim(sim) module is responsible for
# calling these routines.  When re-entering the time-stream at a
# snapshot, the <purge> method deletes the "future history".

snit::type hist {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Group: Public Type Methods

    # Type Method: purge
    #
    # Removes "future history" from the history tables when going
    # backwards in time.
    #
    # Syntax:
    #   purge _t_
    #
    #   t - The time from which to purge.

    typemethod purge {t} {
        rdb eval {
            DELETE FROM hist_sat        WHERE t >= $t;
            DELETE FROM hist_mood       WHERE t >= $t;
            DELETE FROM hist_nbmood     WHERE t >= $t;
            DELETE FROM hist_coop       WHERE t >= $t;
            DELETE FROM hist_nbcoop     WHERE t >= $t;
            DELETE FROM hist_econ       WHERE t >= $t;
            DELETE FROM hist_econ_i     WHERE t >= $t;
            DELETE FROM hist_econ_ij    WHERE t >= $t;

            -- These are recorded after the simclock advances.
            DELETE FROM hist_control    WHERE t >  $t;
            DELETE FROM hist_security   WHERE t >  $t;
            DELETE FROM hist_support    WHERE t >  $t;
            DELETE FROM hist_volatility WHERE t >  $t;
            DELETE FROM hist_vrel       WHERE t >  $t;
        }
    }

    # Type Method: tick
    #
    # This method is called at each time tick, and preserves data values
    # that change tick-by-tick.

    typemethod tick {} {
        rdb eval {
            -- sat.g.c
            INSERT INTO hist_sat
            SELECT now() AS t, g, c, sat 
            FROM gram_sat;

            -- mood.g
            INSERT INTO hist_mood
            SELECT now() AS t, g, sat
            FROM gram_g;

            -- nbmood.n
            INSERT INTO hist_nbmood
            SELECT now() AS t, n, sat
            FROM gram_n;

            -- coop.n.f.g
            INSERT INTO hist_coop
            SELECT now() AS t, f, g, coop
            FROM gram_coop;

            -- nbcoop.n.g
            INSERT INTO hist_nbcoop
            SELECT now() AS t, n, g, coop
            FROM gram_frc_ng;
        }
    }

    # Type Method: econ
    #
    # This method is called at each econ tock, and preserves data
    # values that change tock-by-tock.

    typemethod econ {} {
        # FIRST, if the econ model has been disabled we're done.
        if {[parm get econ.disable]} {
            return
        }

        # NEXT, get the data and save it.
        array set inputs  [econ get In  -bare]
        array set outputs [econ get Out -bare]

        rdb eval {
            -- hist_econ
            INSERT INTO hist_econ(t, consumers, labor, 
                                  lsf, cpi, dgdp, ur)
            VALUES(now(), 
                   $inputs(Consumers), $inputs(WF), $inputs(LSF), 
                   $outputs(CPI), $outputs(DGDP), $outputs(UR));
        }

        foreach i {goods pop else} {
            rdb eval "
                -- hist_econ_i
                INSERT INTO hist_econ_i(t, i, p, qs, rev)
                VALUES(now(), upper(\$i), \$outputs(P.$i), \$outputs(QS.$i), 
                       \$outputs(REV.$i));
            "

            foreach j {goods pop else} {
                rdb eval "
                    -- hist_econ_ij
                    INSERT INTO hist_econ_ij(t, i, j, x, qd)
                    VALUES(now(), upper(\$i), upper(\$j), 
                           \$outputs(X.$i.$j), \$outputs(QD.$i.$j)); 
                "
            }
        }
    }

    # tock
    #
    # This method is called at each 7-day tock, and collects various
    # data.

    typemethod tock {} {
        if {[parm get hist.control]} {
            rdb eval {
                INSERT INTO hist_control
                SELECT now(),n,controller
                FROM control_n;
            }
        }

        if {[parm get hist.security]} {
            rdb eval {
                INSERT INTO hist_security
                SELECT now(), n, g, security
                FROM force_ng;
            }
        }

        if {[parm get hist.support]} {
            rdb eval {
                INSERT INTO hist_support
                SELECT now(), n, a, direct_support, support, influence
                FROM influence_na;
            }
        }

        if {[parm get hist.volatility]} {
            rdb eval {
                INSERT INTO hist_volatility
                SELECT now(), n, volatility
                FROM force_n;
            }
        }

        if {[parm get hist.vrel]} {
            rdb eval {
                INSERT INTO hist_vrel
                SELECT now(), g, a, vrel
                FROM vrel_ga;
            }
        }
    }
}
