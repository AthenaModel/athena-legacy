#-----------------------------------------------------------------------
# TITLE:
#    econpopbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    econpopbrowser(sim) package: Neighborhood browser, 
#    Population Statistics.
#
#    This widget displays a formatted list of neighborhood economic
#    data.  It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor econpopbrowser {
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
        { n              "ID"                                             }
        { longname       "Neighborhood"                                   }
        { population     "Population"    -sortmode integer -foreground %D }
        { subsistence    "Subsistence"   -sortmode integer -foreground %D }
        { consumers      "Consumers"     -sortmode integer -foreground %D }
        { labor_force    "Labor Force"   -sortmode integer -foreground %D }
        { unemployed     "Unemployed"    -sortmode integer -foreground %D }
        { upc            "UnempPerCap%"  -sortmode real    -foreground %D }
        { uaf            "UAFactor"      -sortmode real    -foreground %D }
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
        cond::availableMulti control $editbtn \
            order   ECON:UPDATE                  \
            browser $win

        pack $editbtn   -side left

        # NEXT, Respond to simulation updates
        notifier bind ::rdb <econ_n>  $self [mymethod uid]
        notifier bind ::rdb <nbhoods> $self [mymethod uid]
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
        cond::availableMulti  update $editbtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull uid curselection]] == 1} {
            set n [lindex [$hull uid curselection] 0]

            notifier send ::app <Puck> \
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



