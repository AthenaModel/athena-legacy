#-----------------------------------------------------------------------
# TITLE:
#    madbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    madbrowser(sim) package: Magic Attitude Driver browser.
#
#    This widget displays a formatted list of MADs.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor madbrowser {
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
        { id       "ID"              -sortmode integer                }
        { oneliner "Description"                                      }
        { cause    "Cause "                                           }
        { s        "Here Factor (s)" -sortmode real                   }
        { p        "Near Factor (p)" -sortmode real                   }
        { q        "Far Factor (q)"  -sortmode real                   }
        { driver   "Driver"          -sortmode integer -foreground %D }
        { inputs   "Inputs"          -sortmode integer -foreground %D }
    }

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component editbtn     ;# The "Edit" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_mads                    \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add \
            "Add Driver"                          \
            -state   normal                       \
            -command [mymethod AddEntity]

        cond::available control $addbtn \
            order MAD:CREATE


        install editbtn using mkeditbutton $bar.edit \
            "Edit Selected Driver"                   \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::availableSingle control $editbtn   \
            order   MAD:UPDATE \
            browser $win


        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected Driver"                       \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::availableCanDelete control $deletebtn \
            order   MAD:DELETE  \
            browser $win


        pack $addbtn     -side left
        pack $editbtn    -side left
        pack $deletebtn  -side right

        # NEXT, update individual entities when they change.
        # We get most changes from table monitoring, but 
        # gram_driver-related changes come through mad.tcl
        notifier bind ::rdb <mads>        $self [mymethod uid]
        notifier bind ::rdb <gram_driver> $self [mymethod gd_uid]
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

            if {$id in [mad initial names]} {
                return 1
            }
        }

        return 0
    }

    # gd_uid op uid
    #
    # op     create, update, delete
    # uid    A gram_driver ID
    #
    # Converts the driver ID into a mad ID, and calls uid *
    
    method gd_uid {op uid} {
        set id [rdb onecolumn {
            SELECT id FROM mads WHERE driver=$uid 
        }]

        $hull uid $op $id
    }


    #-------------------------------------------------------------------
    # Private Methods

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::availableSingle     update $editbtn
        cond::availableCanDelete  update $deletebtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull uid curselection]] == 1} {
            set s [lindex [$hull uid curselection] 0]

            notifier send ::app <Puck> [list mad $s]
        }
    }

    # AddEntity
    #
    # Called when the user wants to add a new entity

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter MAD:CREATE
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected entity

    method EditSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the order dialog.
        order enter MAD:UPDATE id $id
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Send the delete order.
        order send gui MAD:DELETE id $id
    }

}




