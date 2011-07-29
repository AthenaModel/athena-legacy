#-----------------------------------------------------------------------
# TITLE:
#    sqdeploybrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    sqdeploybrowser(sim) package: sqdeploy_ng browser.
#
#    This widget displays a formatted list of sqdeploy_ng records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor sqdeploybrowser {
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
    component deletebtn  ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_sqdeploy_ng             \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install setbtn using mktoolbutton $bar.set \
            ::marsgui::icon::pencil22              \
            "Set Deployment"                       \
            -state   disabled                      \
            -command [mymethod SetSelected]

        cond::availableSingle control $setbtn \
            order   SQDEPLOY:SET              \
            browser $win
       
        install deletebtn using mkdeletebutton $bar.delete \
            "Clear Deployment"                             \
            -state   disabled                              \
            -command [mymethod ClearSelected]

        cond::availableSingle control $deletebtn \
            order   SQDEPLOY:DELETE              \
            browser $win

        pack $deletebtn -side right
        pack $setbtn    -side left

        # NEXT, Respond to simulation updates
        notifier bind ::rdb <sqdeploy_ng> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # When records are deleted, treat it like an update.
    delegate method {uid *}      to hull using {%c uid %m}
    delegate method {uid delete} to hull using {%c uid update}


    #-------------------------------------------------------------------
    # Private Methods

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::availableSingle  update [list $setbtn $deletebtn]
    }


    # SetSelected
    #
    # Called when the user wants to set the personnel

    method SetSelected {} {
        set ids [$hull uid curselection]

        order enter SQDEPLOY:SET id [lindex $ids 0]
    }

    # ClearSelected
    #
    # Called when the user wants to clear a deployment.

    method ClearSelected {} {
        set ids [$hull uid curselection]

        order send gui SQDEPLOY:DELETE id [lindex $ids 0]
    }
}




