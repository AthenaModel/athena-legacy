#-----------------------------------------------------------------------
# TITLE:
#    demsitbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    demsitbrowser(sim) package: Demographic Situation browser.
#
#    This widget displays a formatted list of demsits.
#    It is a wrapper around sqlbrowser(n)
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor demsitbrowser {
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
        {id       "ID"         -sortmode integer                }
        {change   "Change"                       -foreground %D }
        {state    "State"                        -foreground %D }
        {stype    "Type"                                        }
        {n        "Nbhood"                                      }
        {g        "Group"                                       }
        {ngfactor "NG UAF"     -sortmode real    -foreground %D }
        {nfactor  "N UAF"      -sortmode real    -foreground %D }
        {ts       "Began At"                     -foreground %D }
        {tc       "Changed At"                   -foreground %D }
        {driver   "Driver"     -sortmode integer -foreground %D }
    }

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                 \
            -db                 ::rdb                \
            -view               gui_demsits_current  \
            -uid                id                   \
            -titlecolumns       1                    \
            -reloadon {
                ::sim <Tick>
                ::sim <DbSyncB>
            } -views        {
                gui_demsits          "All"
                gui_demsits_current  "Current"
                gui_demsits_ended    "Ended"
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}

