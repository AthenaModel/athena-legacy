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
# DESCRIPTION:
#
# History is saved for t=0 on lock and for t > 0 at the end of each
# time-step's activities.  [hist tick] saves all history that is
# saved at every tick; [hist econ] saves all history that is saved
# at each econ tock.
#
#-----------------------------------------------------------------------

snit::type hist {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # purge t
    #
    # t   - The sim time in ticks at which to purge
    #
    # Removes "future history" from the history tables when going
    # backwards in time.  We are paused at time t; all time t 
    # history is behind us.  So purge everything later.
    #
    # On unlock, this will be used to purge all history, including
    # time 0 history, by setting t to -1.

    typemethod purge {t} {
        rdb eval {
            DELETE FROM hist_sat        WHERE t > $t;
            DELETE FROM hist_mood       WHERE t > $t;
            DELETE FROM hist_nbmood     WHERE t > $t;
            DELETE FROM hist_coop       WHERE t > $t;
            DELETE FROM hist_nbcoop     WHERE t > $t;
            DELETE FROM hist_econ       WHERE t > $t;
            DELETE FROM hist_econ_i     WHERE t > $t;
            DELETE FROM hist_econ_ij    WHERE t > $t;
            DELETE FROM hist_control    WHERE t > $t;
            DELETE FROM hist_security   WHERE t > $t;
            DELETE FROM hist_support    WHERE t > $t;
            DELETE FROM hist_volatility WHERE t > $t;
            DELETE FROM hist_vrel       WHERE t > $t;
        }
    }

    # tick
    #
    # This method is called at each time tick, and preserves data values
    # that change tick-by-tick.  History data can be disabled.

    typemethod tick {} {
        if {[parm get hist.control]} {
            rdb eval {
                INSERT INTO hist_control
                SELECT now(),n,controller
                FROM control_n;
            }
        }

        if {[parm get hist.coop]} {
            rdb eval {
                INSERT INTO hist_coop
                SELECT now() AS t, f, g, coop
                FROM uram_coop;
            }
        }

        if {[parm get hist.mood]} {
            rdb eval {
                INSERT INTO hist_mood
                SELECT now() AS t, g, mood
                FROM uram_mood;
            }
        }

        if {[parm get hist.nbcoop]} {
            rdb eval {
                INSERT INTO hist_nbcoop
                SELECT now() AS t, n, g, nbcoop
                FROM uram_nbcoop;
            }
        }

        if {[parm get hist.nbmood]} {
            rdb eval {
                INSERT INTO hist_nbmood
                SELECT now() AS t, n, nbmood
                FROM uram_n;
            }
        }

        if {[parm get hist.sat]} {
            rdb eval {
                INSERT INTO hist_sat
                SELECT now() AS t, g, c, sat 
                FROM uram_sat;
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
                FROM uram_vrel;
            }
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
}
