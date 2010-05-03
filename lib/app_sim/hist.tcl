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
            DELETE FROM hist_sat    WHERE t >= $t;
            DELETE FROM hist_mood   WHERE t >= $t;
            DELETE FROM hist_nbmood WHERE t >= $t;
            DELETE FROM hist_coop   WHERE t >= $t;
            DELETE FROM hist_nbcoop WHERE t >= $t;
        }
    }

    # Type Method: tick
    #
    # This method is called at each time tick, and preserves data values
    # that change tick-by-tick.

    typemethod tick {} {
        rdb eval {
            -- sat.n.g.c
            INSERT INTO hist_sat
            SELECT now() AS t, n, g, c, sat 
            FROM gram_sat;

            -- mood.n.g
            INSERT INTO hist_mood
            SELECT now() AS t, n, g, sat
            FROM gram_ng
            WHERE sat_tracked = 1;

            -- nbmood.n
            INSERT INTO hist_nbmood
            SELECT now() AS t, n, sat
            FROM gram_n;

            -- coop.n.f.g
            INSERT INTO hist_coop
            SELECT now() AS t, n, f, g, coop
            FROM gram_coop;

            -- nbcoop.n.g
            INSERT INTO hist_nbcoop
            SELECT now() AS t, n, g, coop
            FROM gram_frc_ng;
        }
    }


}
