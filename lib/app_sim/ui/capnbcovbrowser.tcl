#-----------------------------------------------------------------------
# TITLE:
#   capnbcovbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    capnbcovbrowser(sim) package: CAP nbhood coverage browser
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor capnbcovbrowser {
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
        {k        "Of CAP"                      }
        {n        "In Nbhood"                   }
        {nbcov    "Coverage"     -sortmode real }
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
            -view         gui_cap_kn_nonzero          \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::rdb <caps>
                ::sim <DbSyncB>
            } -views {
                gui_cap_kn         "All"
                gui_cap_kn_nonzero "Non-Zero"
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using mkeditbutton $bar.edit \
            "Set CAP Neighborhood Coverage"          \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::availableMulti control $editbtn \
            order   CAP:NBCOV:SET              \
            browser $win

        pack $editbtn   -side left

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <cap_kn> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # When cap_kn records are deleted, treat it like an update.
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
        cond::availableMulti update $editbtn
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            order enter CAP:NBCOV:SET id [lindex $ids 0]
        } else {
            order enter CAP:NBCOV:SET:MULTI ids $ids
        }
    }
}


