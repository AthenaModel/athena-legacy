#-----------------------------------------------------------------------
# TITLE:
#    nbcoopbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    nbcoopbrowser(sim) package: Nbhood Cooperation browser.
#
#    This widget displays a formatted list of gram_frc_ng records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor nbcoopbrowser {
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
        { n     "Nbhood"                                   }
        { g     "With Group"                               }
        { coop0 "Coop at T0" -sortmode real                }
        { coop  "Coop Now"   -sortmode real -foreground %D }
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
            -view         gui_coop_ng                 \
            -uid          id                          \
            -titlecolumns 2                           \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
                ::coop <Entity>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}


