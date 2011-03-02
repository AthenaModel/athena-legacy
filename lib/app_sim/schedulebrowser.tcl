#-----------------------------------------------------------------------
# TITLE:
#    schedulebrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    schedulebrowser(sim) package: Unit browser.
#
#    This widget displays a formatted list of unit records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor schedulebrowser {
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
        { cid       "CID"                                            }
        { priority  "Prio"       -sortmode integer                   }
        { g         "Group"                                          }
        { n         "From"                                           }
        { a         "Activity"                                       }
        { tn        "In"                                             }
        { personnel "Personnel"  -sortmode integer                   }
        { narrative "When"       -width 60 -wrap 1                   }
        { u         "Unit"                                           }
    }

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add Item" button
    component editbtn     ;# The "Edit Item" button
    component topbtn      ;# The "Top Priority" button
    component raisebtn    ;# The "Raise Priority" button
    component lowerbtn    ;# The "Lower Priority" button
    component bottombtn   ;# The "Bottom Priority" button
    component cancelbtn   ;# The "Cancel" button.
    component nbox        ;# Nbhood menu box
    component gbox        ;# Group menu box
    component frombox     ;# From time
    component tobox       ;# To time

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_calendar                \
            -uid          cid                         \
            -titlecolumns 1                           \
            -selectmode   browse                      \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
                ::activity <Staffing>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add \
            "Add Schedule Item"                   \
            -state   normal                       \
            -command [mymethod AddItem]

        cond::available control $addbtn        \
            order ACTIVITY:SCHEDULE


        install editbtn using mkeditbutton $bar.edit \
            "Edit Schedule Item"                     \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::availableSingle control $editbtn    \
            order   ACTIVITY:UPDATE                  \
            browser $win


        install topbtn using mktoolbutton $bar.top \
            ::marsgui::icon::totop              \
            "Top Priority"                         \
            -state   disabled                      \
            -command [mymethod SetPriority top]

        cond::availableSingle control $topbtn   \
            order   ACTIVITY:PRIORITY              \
            browser $win


        install raisebtn using mktoolbutton $bar.raise \
            ::marsgui::icon::raise                  \
            "Raise Priority"                           \
            -state   disabled                          \
            -command [mymethod SetPriority raise]

        cond::availableSingle control $raisebtn     \
            order   ACTIVITY:PRIORITY                  \
            browser $win


        install lowerbtn using mktoolbutton $bar.lower \
            ::marsgui::icon::lower                  \
            "Lower Priority"                           \
            -state   disabled                          \
            -command [mymethod SetPriority lower]

        cond::availableSingle control $lowerbtn     \
            order   ACTIVITY:PRIORITY                  \
            browser $win


        install bottombtn using mktoolbutton $bar.bottom \
            ::marsgui::icon::tobottom                 \
            "Bottom Priority"                            \
            -state   disabled                            \
            -command [mymethod SetPriority bottom]

        cond::availableSingle control $bottombtn      \
            order   ACTIVITY:PRIORITY                    \
            browser $win


        install cancelbtn using mkdeletebutton $bar.cancel \
            "Cancel Selected Item"                         \
            -state   disabled                              \
            -command [mymethod CancelSelected]

        cond::availableSingle control $cancelbtn \
            order   ACTIVITY:CANCEL                 \
            browser $win
        

        # Nbhood/Group Pulldowns
        ttk::label $bar.glab \
            -text "Grp"
        
        install gbox using enumfield $bar.gbox \
            -width     8                       \
            -valuecmd  {::ptype g+all names}   \
            -changecmd [mymethod FilterChanged]

        ttk::label $bar.nlab \
            -text "Nb"

        install nbox using enumfield $bar.nbox  \
            -width     8                        \
            -valuecmd  {::ptype n+all names}    \
            -changecmd [mymethod FilterChanged]

        # Time Interval Entries
        ttk::label $bar.fromlab \
            -text "From"
        
        install frombox using textfield $bar.from \
            -width     12                         \
            -changecmd [mymethod FilterChanged]

        $frombox set T0
        
        ttk::label $bar.tolab \
            -text "To"
        
        install tobox using textfield $bar.to  \
            -width     12                      \
            -changecmd [mymethod FilterChanged]
        
        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $topbtn    -side left
        pack $raisebtn  -side left
        pack $lowerbtn  -side left
        pack $bottombtn -side left


        pack $tobox       -side right -padx {0 5}
        pack $bar.tolab   -side right
        pack $frombox     -side right -padx {0 5}
        pack $bar.fromlab -side right
        pack $nbox        -side right -padx {0 5}
        pack $bar.nlab    -side right
        pack $gbox        -side right -padx {0 5}
        pack $bar.glab    -side right
        pack $cancelbtn   -side right -padx {0 5}

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <calendar> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

    # FilterChanged
    #
    # args    Ignored
    #
    # Filter on the selected neighborhood, group, and time interval.

    method FilterChanged {args} {
        # FIRST, get the filter values.
        set n    [$nbox get]
        set g    [$gbox get]
        set from [$self GetTime $frombox]
        set to   [$self GetTime $tobox]

        # NEXT, prepare to build up the queries
        set conds [list]

        if {$n ni {"ALL" ""}} {
            lappend conds "n='$n'"
        }

        if {$g ni {"ALL" ""}} {
            lappend conds "g='$g'"
        }

        if {$from ni {0 ""}} {
            lappend conds "(finish_tick == '' OR finish_tick >= $from)"
        }

        if {$to ne ""} {
            lappend conds "start_tick <= $to"
        }

        if {[llength $conds] > 0} {
            $hull configure -where [join $conds " AND "]
        } else {
            $hull configure -where ""
        }
    }

    # GetTime w
    #
    # w        The entry widget
    #
    # Gets and validates a time value from the frombox or tobox.

    method GetTime {w} {
        if {$w eq ""} {
            return ""
        }

        # FIRST, validate the time, and set it to RED if
        # invalid.
        set spec [string trim [string toupper [$w get]]]

        set tick ""

        if {$spec ne ""} {
            if {![catch {simclock timespec validate $spec}]} {
                $w configure -foreground black
                set tick [simclock fromTimeSpec $spec]
            } else {
                $w configure -foreground red
            }
        }

        return $tick
    }



    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::availableSingle update \
            [list $editbtn $topbtn $raisebtn $lowerbtn $bottombtn $cancelbtn]

        # NEXT, notify the app of the selection.
        if {[llength [$hull uid curselection]] == 1} {
            set cid [lindex [$hull uid curselection] 0]

            notifier send ::app <Puck> \
                [list cid $cid]
        }
    }

    # AddItem
    #
    # Called when the user wants to add a new schedule item

    method AddItem {} {
        set g [$gbox get]
        set n [$nbox get]

        set parmdict [dict create]

        if {$g ne ""} {
            dict set parmdict g $g
        }

        if {$n ne ""} {
            dict set parmdict n $n
            dict set parmdict tn $n
        }

        order enter ACTIVITY:SCHEDULE $parmdict
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        # FIRST, there should be only one selected.
        set cid [lindex [$hull uid curselection] 0]

        order enter ACTIVITY:UPDATE cid $cid
    }


    # SetPriority prio
    #
    # prio    A token indicating the new priority.
    #
    # Sets the selected item's priority.

    method SetPriority {prio} {
        # FIRST, there should be only one selected.
        set cid [lindex [$hull uid curselection] 0]

        # NEXT, Set its priority.
        order send gui ACTIVITY:PRIORITY cid $cid priority $prio
    }
    


    # CancelSelected
    #
    # Called when the user wants to cancel the selected calendar item.

    method CancelSelected {} {
        # FIRST, there should be only one selected.
        set cid [lindex [$hull uid curselection] 0]

        # NEXT, Delete it.
        order send gui ACTIVITY:CANCEL cid $cid
    }
}




