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
        { n        "Nbhood"                                  }
        { g        "Group"                                   }
        { c        "Concern"                                 }
        { sat0     "Sat at T0" -sortmode real                }
        { sat      "Sat Now"   -sortmode real -foreground %D }
        { saliency "Saliency"  -sortmode real                }
        { atrend   "ATrend"    -sortmode real                }
        { athresh  "AThresh"   -sortmode real                }
        { dtrend   "DTrend"    -sortmode real                }
        { dthresh  "DThresh"   -sortmode real                }
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
            -view         gui_sat_ngc                 \
            -uid          id                          \
            -titlecolumns 3                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using mkeditbutton $bar.edit \
            "Edit Initial Curve"                     \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::orderIsValidMulti control $editbtn \
            order   SAT:UPDATE          \
            browser $win

       
        install setbtn using mktoolbutton $bar.set \
            ::projectgui::icon::pencils22          \
            "Magic Set Satisfaction Level"         \
            -state   disabled                      \
            -command [mymethod SetSelected]

        cond::orderIsValidSingle control $setbtn \
            order   MAD:SAT:SET                  \
            browser $win
       

        install adjbtn using mktoolbutton $bar.adj \
            ::projectgui::icon::pencila22          \
            "Magic Adjust Satisfaction Level"      \
            -state   disabled                      \
            -command [mymethod AdjustSelected]

        cond::orderIsValidSingle control $adjbtn \
            order   MAD:SAT:ADJUST               \
            browser $win
       
        pack $editbtn   -side left
        pack $setbtn    -side left
        pack $adjbtn    -side left

        # NEXT, update individual entities when they change.
        notifier bind ::sat <Entity> $self [mymethod uid]
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
        cond::orderIsValidMulti update $editbtn
        cond::orderIsValidSingle update [list $setbtn $adjbtn]

        # NEXT, if there's exactly one item selected, notify the
        # the app.
        if {[llength [$hull uid curselection]] == 1} {
            set id [lindex [$hull uid curselection] 0]
            lassign $id n g c

            notifier send ::app <ObjectSelect> \
                [list ngc $id  nbhood $n group $g concern $c]
        }
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


    # SetSelected
    #
    # Called when the user wants to set the selected level

    method SetSelected {} {
        set ids [$hull uid curselection]

        lassign [lindex $ids 0] n g c

        order enter MAD:SAT:SET n $n g $g c $c
    }

    # AdjustSelected
    #
    # Called when the user wants to adjust the selected level

    method AdjustSelected {} {
        set ids [$hull uid curselection]

        lassign [lindex $ids 0] n g c

        order enter MAD:SAT:ADJUST n $n g $g c $c
    }
}






