#-----------------------------------------------------------------------
# TITLE:
#    firings.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Rule Firings Report Manager
#
#    This module wraps reporter(n), and integrates it into the app,
#    solely for the purpose of displaying rule firings.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# firings

snit::type ::firings {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Components

    typecomponent reporter  ;# For delegation to reporter(n).

    #-------------------------------------------------------------------
    # Initialization
    
    typemethod init {} {
        log normal report "init"

        # FIRST, support delegation to reporter(n)
        set reporter ::projectlib::reporter

        # NEXT, configure the reporter
        reporter configure \
            -db        ::rdb                                \
            -clock     ::simclock                           \
            -deletecmd [list notifier send $type <Update>]  \
            -reportcmd [list notifier send $type <Report>]

        # NEXT, define the bins.

        reporter bin define all "All Reports" "" {
            SELECT * FROM reports
        }

        reporter bin define hotlist "Hot List" "" {
            SELECT * FROM reports WHERE hotlist=1
        }

        reporter bin define dam "DAM Rule Firings" "" {
            SELECT * FROM reports WHERE rtype='DAM'
        }

        set count 0
        foreach ruleset [edamruleset names] {
            set bin "dam[incr count]"

            reporter bin define $bin $ruleset dam "
                SELECT * FROM reports WHERE rtype='DAM' AND subtype='$ruleset'
            "
        }

        log normal report "init complete"
    }

    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod save to reporter
}








