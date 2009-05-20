#-----------------------------------------------------------------------
# TITLE:
#    report.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Report Manager
#
#    This module wraps reporter(n), and integrates it into the app.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# report

snit::type report {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Components

    typecomponent reporter  ;# For delegation to reporter(n).

    #-------------------------------------------------------------------
    # Initialization
    
    typemethod init {} {
        log normal report "Initializing"

        # FIRST, support delegation to reporter(n)
        set reporter ::projectlib::reporter

        # NEXT, configure the reporter
        reporter configure \
            -db        ::rdb                   \
            -clock     ::simclock              \
            -reportcmd [list notifier send $type <Report>]

        # NEXT, define the bins.

        reporter bin define all "All Reports" "" {
            SELECT * FROM reports
        }

        reporter bin define requested "Requested" "" {
            SELECT * FROM reports WHERE requested=1
        }

        reporter bin define hotlist "Hot List" "" {
            SELECT * FROM reports WHERE hotlist=1
        }

        reporter bin define ada "ADA Rule Firings" "" {
            SELECT * FROM reports WHERE rtype='ADA'
        }

        set count 0
        foreach ruleset [eadaruleset names] {
            set bin "ada[incr count]"

            reporter bin define $bin $ruleset ada "
                SELECT * FROM reports WHERE rtype='ADA' AND subtype='$ruleset'
            "
        }
    }

    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod save to reporter
}

