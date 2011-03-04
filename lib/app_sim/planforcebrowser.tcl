#-----------------------------------------------------------------------
# TITLE:
#    planforcebrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    planforcebrowser(sim) package: Plan/Force Level browser.
#
#    This widget displays a formatted list of scheduled PERSONNEL:* orders.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget planforcebrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Lookup Tables

    # Plan Layout
    #
    # %D is replaced with the color for derived columns.

    typevariable planLayout {
        { zulu      "Zulu"                                          }
        { tick      "Day"        -sortmode integer                  }
        { narrative "Narrative"  -width 60 -wrap 1                  }
    }

    # Current Status Layout
    #
    # %D is replaced with the color for derived columns.

    typevariable statusLayout {
        { g          "Group"                       }
        { n          "In Nbhood"                   }
        { personnel  "Personnel" -sortmode integer }
    }

    #-------------------------------------------------------------------
    # Components
    
    component plan        ;# sqlbrowser; planned orders
    component status      ;# sqlbrowser; force level status

    component setbtn      ;# The "Set" button
    component adjbtn      ;# The "Adjust" button
    component cancelbtn   ;# The "Cancel" button
    component nbox        ;# Nbhood menu box
    component gbox        ;# Group menu box

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create a paned window
        ttk::panedwindow $win.pw

        pack $win.pw -fill both -expand yes

        # NEXT, Install the plan widget
        install plan using sqlbrowser $win.pw.plan        \
            -db           ::rdb                           \
            -view         gui_plan_force_level_orders     \
            -uid          id                              \
            -titlecolumns 2                               \
            -selectioncmd [mymethod PlanSelectionChanged] \
            -reloadon {
                ::order <Queue>
            } -layout [string map [list %D $::app::derivedfg] $planLayout]

        $win.pw add $plan -weight 1

        set bar [$plan toolbar]

        ttk::label $bar.title \
            -text "Planned Force Level Changes"

        # Set Button
        install setbtn using mktoolbutton $bar.set \
            ::marsgui::icon::pluss22            \
            "Set Personnel"                        \
            -command [mymethod ActOnSelected PERSONNEL:SET]

        # Adjust Button
        install adjbtn using mktoolbutton $bar.adj \
            ::marsgui::icon::plusa22            \
            "Adjust Personnel by a Delta"          \
            -command [mymethod ActOnSelected PERSONNEL:ADJUST]

        # Cancel Button
        install cancelbtn using mkdeletebutton $bar.cancel \
            "Cancel Selected Order"                        \
            -state   disabled                              \
            -command [mymethod CancelSelected]
            
        cond::availableSingle control $cancelbtn \
            order   ORDER:CANCEL                     \
            browser $plan

        # Nbhood/Group Pulldowns
        ttk::label $bar.glab \
            -text "Group"
        
        install gbox using enumfield $bar.gbox \
            -width     8                       \
            -valuecmd  {::ptype fog+all names} \
            -changecmd [mymethod FilterChanged]

        ttk::label $bar.nlab \
            -text "In"

        install nbox using enumfield $bar.nbox  \
            -width     8                        \
            -valuecmd  {::ptype n+all names}    \
            -changecmd [mymethod FilterChanged]

        pack $bar.title -side left
        pack $setbtn    -side left -padx {5 0}
        pack $adjbtn    -side left

        pack $nbox      -side right -padx {0 5}
        pack $bar.nlab  -side right
        pack $gbox      -side right -padx {0 5} 
        pack $bar.glab  -side right
        pack $cancelbtn -side right


        # NEXT, install the status widget
        install status using sqlbrowser $win.pw.status      \
            -db           ::rdb                             \
            -view         gui_personnel_ng                  \
            -uid          id                                \
            -titlecolumns 2                                 \
            -selectioncmd [mymethod StatusSelectionChanged] \
            -layout [string map [list %D $::app::derivedfg] $statusLayout]

        $win.pw add $status -weight 1

        set bar [$status toolbar]

        ttk::label $bar.title \
            -text "Current Force Levels"

        pack $bar.title -side left

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, bind to notifier events, to update the widgets.
        notifier bind ::sim <DbSyncB>       $self [mymethod reload]
        notifier bind ::sim <Tick>          $self [mymethod reload]
        notifier bind ::rdb <personnel_ng>  $self [mymethod uid]
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # reload
    #
    # args   Ignored; allows command to be used as callback
    #
    # Reloads the sqlbrowsers when various events occur.

    method reload {args} {
        # Make the filter pulldowns refresh themselves
        $nbox set [$nbox get]
        $gbox set [$gbox get]

        # Next, update the filters incase the nbox or gbox values
        # changed.
        $self FilterChanged

        # Make the browsers refresh themselves.
        $plan   reload
        $status reload
    }

    # uid args...
    #
    # Updates filter pulldowns, then delegates to the status pane.

    method uid {args} {
        # Update the status browser
        $status uid {*}$args

        # Reload everything
        $self reload
    }
    

    #-------------------------------------------------------------------
    # Private Methods

    # FilterChanged
    #
    # args    Ignored
    #
    # Filter on the selected neighborhood and group.

    method FilterChanged {args} {
        # FIRST, if both are set to ALL, clear the filters.
        set n [$nbox get]
        set g [$gbox get]

        if {$n in {"ALL" ""} && $g in {"ALL" ""}} {
            $plan configure -where ""
            $status configure -where ""
            return
        }

        # NEXT, prepare to build up the queries
        set pconds [list]
        set sconds [list]

        if {$n ni {"ALL" ""}} {
            lappend pconds "'n','$n'"
            lappend sconds "n='$n'"
        }

        if {$g ni {"ALL" ""}} {
            lappend pconds "'g','$g'"
            lappend sconds "g='$g'"
        }

        $plan   configure -where "dicteq(parmdict,[join $pconds ,])"
        $status configure -where [join $sconds " AND "]
    }

    # PlanSelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method PlanSelectionChanged {} {
        # FIRST, update buttons
        cond::availableSingle update \
            [list $cancelbtn]
    }

    # ActOnSelected order
    #
    # order     An order name.
    #
    # Called when the user wants to invoke the order.  First, if
    # a row is selected in the status pane then we get n and g
    # from that row.  Otherwise, we get them from the filter boxes.

    method ActOnSelected {order} {
        # FIRST, get g and n.
        set rids [$status curselection]

        if {[llength $rids] == 1} {
            # FIRST, there's a row selected in the status pane; use
            # its g and n.
            set rid [lindex $rids 0]
            lassign [$status get $rid] g n

            set parmlist [list id [list $n $g]]
        } else {
            # Otherwise, look at the filter boxes.
            set parmlist [list id [list [$nbox get] [$gbox get]]]
        }

        # NEXT, enter the order dialog.
        order enter $order {*}$parmlist
    }

    # CancelSelected
    #
    # Called when the user wants to cancel the selected entity.

    method CancelSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$plan uid curselection] 0]

        # NEXT, Send the cancel order.
        order send gui ORDER:CANCEL id $id
    }

    # StatusSelectionChanged
    #
    # Notifies the app of the selected n and g

    method StatusSelectionChanged {} {
        if {[llength [$status uid curselection]] == 1} {
            set id [lindex [$status uid curselection] 0]
            lassign $id n g

            notifier send ::app <Puck> \
                [list ng $id nbhood $n group $g]
        }
    }
}




