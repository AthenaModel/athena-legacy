#-----------------------------------------------------------------------
# TITLE:
#    coopbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    coopbrowser(sim) package: Cooperation browser, Scenario Mode.
#
#    This widget displays a formatted list of coop_fg records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor coopbrowser {
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
        { f        "Of Group"                   }
        { g        "With Group"                 }
        { base     "Baseline"    -sortmode real }
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
            -view         gui_coop_view               \
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
            order   COOP:UPDATE           \
            browser $win

        pack $editbtn   -side left

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <coop_fg> $self [mymethod uid]
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
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            order enter COOP:UPDATE id [lindex $ids 0]
        } else {
            order enter COOP:UPDATE:MULTI ids $ids
        }
    }
}




