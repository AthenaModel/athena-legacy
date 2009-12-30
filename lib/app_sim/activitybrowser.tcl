#-----------------------------------------------------------------------
# TITLE:
#    activitybrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    activitybrowser(sim) package: Unit Activity browser.
#
#    This widget displays a formatted list of activity_nga records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor activitybrowser {
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
        {n              "Nbhood"                                     }
        {g              "Group"                                      }
        {a              "Activity"                                   }
        {coverage       "Coverage"  -sortmode real    -foreground %D }
        {security_flag  "SecFlag"                     -foreground %D }
        {nominal        "NomPers"   -sortmode integer -foreground %D }
        {active         "ActPers"   -sortmode integer -foreground %D }
        {effective      "EffPers"   -sortmode integer -foreground %D }
        {stype          "SitType"                     -foreground %D }
        {s              "Situation" -sortmode integer -foreground %D }
    }

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser              \
            -db                 ::rdb             \
            -view               gui_activity_nga  \
            -uid                id                \
            -titlecolumns       4                 \
            -reloadon {
                ::sim <Tick>
                ::sim <Reconfigure
            } -layout [string map [list %D $::app::derivedfg] $layout]


        # NEXT, get the options.
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}

