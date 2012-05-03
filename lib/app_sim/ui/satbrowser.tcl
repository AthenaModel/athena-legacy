#-----------------------------------------------------------------------
# TITLE:
#    satbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    satbrowser(sim) package: Satisfaction browser.
#
#    This widget displays a formatted list of satisfaction curve records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor satbrowser {
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
        { g        "Group"                     }
        { c        "Concern"                   }
        { n        "Nbhood"                    }
        { base     "Baseline"  -sortmode real  }
        { saliency "Saliency"  -sortmode real  }
    }

    #-------------------------------------------------------------------
    # Components

    component editbtn     ;# The "Edit" button
    component adjbtn      ;# The "Adjust" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_sat_view                \
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

        install editbtn using mkeditbutton $bar.edit \
            "Edit Initial Curve"                     \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::availableMulti control $editbtn \
            order   SAT:UPDATE          \
            browser $win

        pack $editbtn   -side left

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <sat_gc> $self [mymethod uid]
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
        cond::availableMulti update $editbtn
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter SAT:UPDATE id $id
        } else {
            order enter SAT:UPDATE:MULTI ids $ids
        }
    }
}






