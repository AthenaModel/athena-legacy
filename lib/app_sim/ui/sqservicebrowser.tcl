#-----------------------------------------------------------------------
# TITLE:
#    sqservicebrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    sqservicebrowser(sim) package: sqservice_ga browser.
#
#    This widget displays a formatted list of sqservice_ga records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor sqservicebrowser {
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
        { g        "Group"                                       }
        { a        "Actor"                                       }
        { funding  "Funding"  -sortmode command
                              -sortcommand ::marsutil::moneysort }
    }

    #-------------------------------------------------------------------
    # Components

    component setbtn    ;# The "Set" button
    component resetbtn  ;# The "Reset" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_sqservice_ga             \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::rdb <civgroups>
                ::rdb <actors>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install setbtn using mktoolbutton $bar.set \
            ::marsgui::icon::pencil22              \
            "Set Funding Level"                    \
            -state   disabled                      \
            -command [mymethod SetSelected]

        cond::availableSingle control $setbtn \
            order   SQSERVICE:SET              \
            browser $win
       
        install resetbtn using mkdeletebutton $bar.reset \
            "Reset Funding Level to Zero"                \
            -state   disabled                            \
            -command [mymethod ResetSelected]

        cond::availableSingle control $resetbtn \
            order   SQSERVICE:RESET             \
            browser $win

        pack $resetbtn -side right
        pack $setbtn   -side left

        # NEXT, Respond to simulation updates
        notifier bind ::rdb <sqservice_ga> $self [mymethod uid]
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
        cond::availableSingle  update [list $setbtn $resetbtn]
    }


    # SetSelected
    #
    # Called when the user wants to set the funding

    method SetSelected {} {
        set ids [$hull uid curselection]

        order enter SQSERVICE:SET id [lindex $ids 0]
    }

    # ResetSelected
    #
    # Called when the user wants to reset to zero.

    method ResetSelected {} {
        set ids [$hull uid curselection]

        order send gui SQSERVICE:RESET id [lindex $ids 0]
    }
}




