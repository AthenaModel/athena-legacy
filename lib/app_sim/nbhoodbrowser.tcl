#-----------------------------------------------------------------------
# TITLE:
#    nbhoodbrowser.tcl
#
# AUTHORS:
#    Dave Hanks,
#    Will Duquette
#
# DESCRIPTION:
#    nbhoodbrowser(sim) package: Neighborhood browser.
#
#    This widget displays a formatted list of neighborhood records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor nbhoodbrowser {

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
        { local          "Local?"                                        }
        { urbanization   "Urbanization"                                  }
        { population     "Population"   -sortmode integer -foreground %D }
        { mood0          "Mood at T0"   -sortmode real                   }
        { mood           "Mood Now"     -sortmode real    -foreground %D }
        { vtygain        "VtyGain"      -sortmode real                   }
        { volatility     "Vty"          -sortmode integer -foreground %D }
        { stacking_order "StkOrd"       -sortmode integer -foreground %D } 
        { obscured_by    "ObscuredBy"   -foreground %D                   }
        { refpoint       "RefPoint"                                      }
        { polygon        "Polygon"      -stretchable yes                 }
    }

    #-------------------------------------------------------------------
    # Components

    component editbtn     ;# The "Edit" button
    component raisebtn    ;# The "Bring to Front" button
    component lowerbtn    ;# The "Send to Back" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_nbhoods                 \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
                ::demog <Update>
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
            order   NBHOOD:UPDATE                \
            browser $win


        install raisebtn using mktoolbutton $bar.raise \
            ::projectgui::icon::totop                  \
            "Bring Neighborhood to Front"              \
            -state   disabled                          \
            -command [mymethod RaiseSelected]

        cond::orderIsValidSingle control $raisebtn \
            order   NBHOOD:RAISE                   \
            browser $win


        install lowerbtn using mktoolbutton $bar.lower \
            ::projectgui::icon::tobottom               \
            "Send Neighborhood to Back"                \
            -state   disabled                          \
            -command [mymethod LowerSelected]

        cond::orderIsValidSingle control $lowerbtn \
            order   NBHOOD:LOWER                   \
            browser $win


        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected Neighborhood"                 \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::orderIsValidSingle control $deletebtn \
            order   NBHOOD:DELETE                   \
            browser $win

        pack $editbtn   -side left
        pack $raisebtn  -side left
        pack $lowerbtn  -side left
        pack $deletebtn -side right

        # NEXT, Respond to simulation updates
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
        cond::orderIsValidSingle update [list $deletebtn $lowerbtn $raisebtn]
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

            order enter NBHOOD:UPDATE n $id
        } else {
            order enter NBHOOD:UPDATE:MULTI ids $ids
        }
    }


    # RaiseSelected
    #
    # Called when the user wants to raise the selected neighborhood.

    method RaiseSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, bring it to the front.
        order send gui NBHOOD:RAISE [list n $id]
    }


    # LowerSelected
    #
    # Called when the user wants to lower the selected neighborhood.

    method LowerSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, bring it to the front.
        order send gui NBHOOD:LOWER [list n $id]
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Send the order.
        order send gui NBHOOD:DELETE n $id
    }
}


