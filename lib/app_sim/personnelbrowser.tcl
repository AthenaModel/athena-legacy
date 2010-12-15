#-----------------------------------------------------------------------
# TITLE:
#    personnelbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    personnelbrowser(sim) package: personnel_ng browser.
#
#    This widget displays a formatted list of personnel_ng records.
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
            -view         gui_personnel_ng            \
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
            ::projectgui::icon::pencils22          \
            "Set Group Personnel"                  \
            -state   disabled                      \
            -command [mymethod SetSelected]

        cond::orderIsValidSingle control $setbtn \
            order   PERSONNEL:SET                \
            browser $win
       

        install adjbtn using mktoolbutton $bar.adj \
            ::projectgui::icon::pencila22          \
            "Adjust Group Personnel by a Delta"    \
            -state   disabled                      \
            -command [mymethod AdjustSelected]

        cond::orderIsValidSingle control $adjbtn \
            order   PERSONNEL:ADJUST             \
            browser $win

        pack $setbtn   -side left
        pack $adjbtn   -side left

        # NEXT, Respond to simulation updates
        notifier bind ::rdb <personnel_ng> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidSingle  update [list $setbtn $adjbtn]

        # NEXT, notify the app of the selection.
        if {[llength [$hull uid curselection]] == 1} {
            set id [lindex [$hull uid curselection] 0]
            lassign $id n g

            notifier send ::app <ObjectSelect> \
                [list ng $id nbhood $n group $g]
        }
    }


    # SetSelected
    #
    # Called when the user wants to set the personnel

    method SetSelected {} {
        set ids [$hull uid curselection]

        order enter PERSONNEL:SET id [lindex $ids 0]
    }

    # AdjustSelected
    #
    # Called when the user wants to adjust the personnel

    method AdjustSelected {} {
        set ids [$hull uid curselection]

        order enter PERSONNEL:ADJUST id [lindex $ids 0]
    }
}


