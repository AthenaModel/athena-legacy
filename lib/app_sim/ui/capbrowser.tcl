#-----------------------------------------------------------------------
# TITLE:
#    capbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    capbrowser(sim) package: Communications Asset Package (CAP) browser.
#
#    This widget displays a formatted list of gui_caps records.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor capbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Look-up Tables

    # Layout
    #
    # %D is replaced with the color for derived columns.

    typevariable layout {
        { k              "ID"                               }
        { longname       "Long Name"                        }
        { owner          "Owner"                            }
        { capacity       "Capacity"                         }
        { cost           "Cost, $/message/week" 
                         -sortmode command 
                         -sortcommand ::marsutil::moneysort }
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
            -view         gui_caps               \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add \
            "Add Comm. Asset Package"             \
            -state   normal                       \
            -command [mymethod AddEntity]

        cond::available control $addbtn \
            order CAP:CREATE


        install editbtn using mkeditbutton $bar.edit \
            "Edit Selected CAP"                      \
            -state   disabled                        \
            -command [mymethod EditSelected]

        # CAP:CAPACITY is used when CAP:UPDATE is not available.
        cond::availableMulti control $editbtn \
            order   CAP:CAPACITY              \
            browser $win


        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected CAP"                          \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::availableSingle control $deletebtn \
            order   CAP:DELETE              \
            browser $win

        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <caps> $self [mymethod uid]
    }

    destructor {
        notifier forget $self
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
        cond::availableSingle update $deletebtn
        cond::availableMulti  update $editbtn
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity.

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter CAP:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[sim state] eq "PREP"} {
            set root CAP:UPDATE
        } else {
            set root CAP:CAPACITY
        }

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter $root k $id
        } else {
            order enter ${root}:MULTI ids $ids
        }
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the dialog, and select this entity
        order send gui CAP:DELETE k $id
    }
}




