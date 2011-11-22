#-----------------------------------------------------------------------
# TITLE:
#    coopbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    coopbrowser(sim) package: Cooperation browser.
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
        { f        "Of Group"                                 }
        { g        "With Group"                               }
        { coop0    "Coop at T0" -sortmode real                }
        { coop     "Coop Now"   -sortmode real -foreground %D }
        { atrend   "ATrend"     -sortmode real                }
        { athresh  "AThresh"    -sortmode real                }
        { dtrend   "DTrend"     -sortmode real                }
        { dthresh  "DThresh"    -sortmode real                }

    }

    #-------------------------------------------------------------------
    # Components

    component editbtn     ;# The "Edit" button
    component setbtn      ;# The "Set" button
    component adjbtn      ;# The "Adjust" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_coop_fg                 \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using mktoolbutton $bar.edit \
            ::projectgui::icon::pencil022            \
            "Edit Selected Curve"                    \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::availableMulti control $editbtn \
            order   COOP:UPDATE           \
            browser $win


        install setbtn using mktoolbutton $bar.set \
            ::projectgui::icon::pencils22          \
            "Magic Set Cooperation Level"          \
            -state   disabled                      \
            -command [mymethod SetSelected]

        cond::availableSingle control $setbtn \
            order   MAD:COOP:SET                 \
            browser $win
       

        install adjbtn using mktoolbutton $bar.adj \
            ::projectgui::icon::pencila22          \
            "Magic Adjust Cooperation Level"       \
            -state   disabled                      \
            -command [mymethod AdjustSelected]

        cond::availableSingle control $adjbtn \
            order   MAD:COOP:ADJUST              \
            browser $win

       
        pack $editbtn   -side left
        pack $setbtn    -side left
        pack $adjbtn    -side left

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <coop_fg> $self [mymethod uid]
        notifier bind ::mad <Coop>    $self [mymethod uid]
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
        cond::availableSingle update [list $setbtn $adjbtn]
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

    # SetSelected
    #
    # Called when the user wants to set the selected level

    method SetSelected {} {
        set ids [$hull uid curselection]

        order enter MAD:COOP:SET id [lindex $ids 0]
    }

    # AdjustSelected
    #
    # Called when the user wants to adjust the selected level

    method AdjustSelected {} {
        set ids [$hull uid curselection]

        order enter MAD:COOP:ADJUST id [lindex $ids 0]
    }
}




