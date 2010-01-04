#-----------------------------------------------------------------------
# TITLE:
#    securitybrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    securitybrowser(sim) package: Group Security browser.
#
#    This widget displays a formatted list of force_ng records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor securitybrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull


    #-------------------------------------------------------------------
    # Lookup Tables

    # Layout
    #
    # %D is replaced with the color for derived columns.

    typevariable layout {
        { n                  "Nbhood"                                      }
        { g                  "Group"                                       }
        { security           "Security"   -sortmode integer -foreground %D }
        { symbol             "Symbol"                                      }
        { pct_force          "%Force"     -sortmode integer -foreground %D }
        { pct_enemy          "%Enemy"     -sortmode integer -foreground %D }
        { volatility         "Volatility" -sortmode integer -foreground %D }
        { volatility_gain    "VtyGain"    -sortmode real                   }
        { nominal_volatility "NomVty"     -sortmode integer                }
    }

    #-------------------------------------------------------------------
    # Components

    # None

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_security                \
            -uid          id                          \
            -titlecolumns 2                           \
            -reloadon {
                ::sim <Reconfigure>
                ::sim <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # FIRST, get the options.
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}

