#-----------------------------------------------------------------------
# TITLE:
#    personnelbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    personnelbrowser(sim) package: deploy_ng browser.
#
#    This widget displays a formatted list of deploy_ng records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor personnelbrowser {
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
        { n          "Nbhood"                      }
        { g          "Group"                       }
        { personnel  "Personnel" -sortmode integer }
    }

    #-------------------------------------------------------------------
    # Components

    component setbtn     ;# The "Set" button
    component adjbtn     ;# The "Adjust" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_deploy_ng               \
            -uid          id                          \
            -titlecolumns 2                           \
            -reloadon {
                ::sim <DbSyncB>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, Respond to simulation updates
        notifier bind ::rdb <deploy_ng> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

}





