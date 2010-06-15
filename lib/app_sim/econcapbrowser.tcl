#-----------------------------------------------------------------------
# TITLE:
#    econcapbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    econcapbrowser(sim) package: Neighborhood browser.
#
#    This widget displays a formatted list of neighborhood economic
#    data.  It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor econcapbrowser {
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
        { n              "ID"                                            }
        { longname       "Neighborhood"                                  }
        { urbanization   "Urbanization"                                  }
        { pcf            "Prod. Cap."   -sortmode real                   }
        { ccf            "Cap. Cal."    -sortmode real    -foreground %D }
        { cap0           "Cap at T0"    -sortmode real    -foreground %D }
        { cap            "Cap Now"      -sortmode real    -foreground %D }
    }

    #-------------------------------------------------------------------
    # Components

    component editbtn     ;# The "Edit" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_econ_n                  \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim  <DbSyncB>
                ::sim  <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using mkeditbutton $bar.edit \
            "Edit Selected Neighborhood"             \
            -state   disabled                        \
            -command [mymethod EditSelected]

        # Assumes that *:UPDATE and *:UPDATE:MULTI always have the
        # the same validity.
        cond::orderIsValidMulti control $editbtn \
            order   ECON:UPDATE                  \
            browser $win

        pack $editbtn   -side left

        # NEXT, Respond to simulation updates
        notifier bind ::econ   <Entity> $self [mymethod uid]
        notifier bind ::nbhood <Entity> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
    delegate method {uid *} to hull using "%c uid %m"

    # uid stack
    #
    # Reloads all data items when the neighborhood stacking order
    # changes in response to "<Entity> stack".  This is needed only 
    # because the module binds to the ::nbhood <Entity> command.

    method {uid stack} {} {
        $self reload
    }

    #-------------------------------------------------------------------
    # Private Methods

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidMulti  update $editbtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull uid curselection]] == 1} {
            set n [lindex [$hull uid curselection] 0]

            notifier send ::app <ObjectSelect> \
                [list nbhood $n]
        }
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entity

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter ECON:UPDATE n $id
        } else {
            order enter ECON:UPDATE:MULTI ids $ids
        }
    }
}


