#-----------------------------------------------------------------------
# TITLE:
#    ensitbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    ensitbrowser(sim) package: Environmental Situation browser.
#
#    This widget displays a formatted list of ensits.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor ensitbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    # Layout
    #
    # %D is replaced with the color for derived columns.

    typevariable layout {
        { id        "ID"          -sortmode integer                }
        { change    "Change"                        -foreground %D }
        { state     "State"                         -foreground %D }
        { stype     "Type"                                         }
        { n         "Nbhood"                        -foreground %D }
        { location  "Location"                                     }
        { coverage  "Coverage"    -sortmode real    -foreground %D }
        { ts        "Began At"                      -foreground %D }
        { tc        "Changed At"                    -foreground %D }
        { g         "Caused By"                                    }
        { resolver  "Resolved By"                                  }
        { tr        "Resolve At"                    -foreground %D }
        { driver_id "Driver"      -sortmode integer -foreground %D }
    }

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component editbtn     ;# The "Edit" button
    component resolvebtn  ;# The "Resolve" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_ensits_current          \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout] \
            -views {
                gui_ensits         "All"
                gui_ensits_current "Current"
                gui_ensits_ended   "Ended"
            }

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add \
            "Add Situation"                       \
            -state   normal                       \
            -command [mymethod AddEntity]

        cond::available control $addbtn \
            order ENSIT:CREATE


        install editbtn using mkeditbutton $bar.edit \
            "Edit Selected Situation"                \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::availableCanUpdate control $editbtn \
            order   ENSIT:UPDATE   \
            browser $win

        install resolvebtn using mktoolbutton $bar.resolve \
            ::marsgui::icon::check22                    \
            "Resolve Selected Situation"                   \
            -state   disabled                              \
            -command [mymethod ResolveSelected]

        cond::availableCanResolve control $resolvebtn  \
            order   ENSIT:RESOLVE   \
            browser $win

        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected Situation"                    \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::availableCanDelete control $deletebtn \
            order   ENSIT:DELETE  \
            browser $win


        pack $addbtn     -side left
        pack $editbtn    -side left
        pack $deletebtn  -side right
        pack $resolvebtn -side right

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <situations> $self [mymethod uid]
        notifier bind ::rdb <ensit_t>    $self [mymethod uid]
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # candelete
    #
    # Returns 1 if the current selection is deletable.
    
    method candelete {} {
        if {[llength [$self uid curselection]] == 1} {
            set id [lindex [$self uid curselection] 0]

            if {$id in [ensit initial names]} {
                return 1
            }
        }

        return 0
    }


    # canupdate
    #
    # Returns 1 if the current selection is updateable.
    
    method canupdate {} {
        if {[llength [$self uid curselection]] == 1} {
            set id [lindex [$self uid curselection] 0]

            if {$id in [ensit initial names]} {
                return 1
            }
        }

        return 0
    }


    # canresolve
    #
    # Returns 1 if the current selection is resolveable.
    
    method canresolve {} {
        if {[llength [$self uid curselection]] == 1} {
            set id [lindex [$self uid curselection] 0]

            if {$id in [ensit live names]} {
                return 1
            }
        }

        return 0
    }

    #-------------------------------------------------------------------
    # Private Methods

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::availableCanUpdate  update $editbtn
        cond::availableCanResolve update $resolvebtn
        cond::availableCanDelete  update $deletebtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull uid curselection]] == 1} {
            set s [lindex [$hull uid curselection] 0]

            notifier send ::app <Puck> [list situation $s]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter ENSIT:CREATE
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected entity

    method EditSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the order dialog.
        order enter ENSIT:UPDATE s $id
    }


    # ResolveSelected
    #
    # Called when the user wants to resolve the selected entity

    method ResolveSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the order dialog.
        order enter ENSIT:RESOLVE s $id
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Send the delete order.
        order send gui ENSIT:DELETE s $id
    }

}






