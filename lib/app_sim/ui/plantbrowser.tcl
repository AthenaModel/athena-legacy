#-----------------------------------------------------------------------
# TITLE:
#    plantbrowser.tcl
#
# AUTHORS:
#    Dave Hanks
#
# DESCRIPTION:
#
#    This browser displays the allocation of manufacturing plants among
# the actors who have them along with their initial repair level.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor plantbrowser {
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
        { n      "Neighborhood"                                    }
        { a      "Owning Agent"                                    }
        { rho    "Average Repair Level"           -sortmode real    }
        { num    "Shares of Manufacturing Plants" -sortmode integer }
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
            -view         gui_plants_na               \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim  <DbSyncB>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add \
            "Add Plant Ownership"                 \
            -state normal                         \
            -command [mymethod AddOwnership]

        cond::available control $addbtn \
            order PLANT:SHARES:CREATE
            
        install editbtn using mkeditbutton $bar.edit \
            "Edit Plant Ownership"             \
            -state   disabled                        \
            -command [mymethod EditSelected]

        # Assumes that *:UPDATE and *:UPDATE:MULTI always have the
        # the same validity.
        cond::availableMulti control $editbtn \
            order   PLANT:SHARES:UPDATE       \
            browser $win

        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Plant Ownership" \
            -state disabled          \
            -command [mymethod DeleteSelected]

        cond::availableSingle control $deletebtn \
            order PLANT:SHARES:DELETE \
            browser $win

        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right

        notifier bind ::rdb <plants_shares> $self [mymethod uid]
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

    # AddOwnership
    #
    # Called when the user want to specify ownership of manufacturing plants
    # for an agent

    method AddOwnership {} {
        order enter PLANT:SHARES:CREATE
    }

    # EditSelected
    #
    # Called when the user wants to edit ownership

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter PLANT:SHARES:UPDATE id $id
        } else {
            order enter PLANT:SHARES:UPDATE:MULTI ids $ids
        }
    }

    # DeleteSelected
    #
    # Called when the user wants to remove ownership

    method DeleteSelected {} {
        set id [lindex [$hull uid curselection] 0]

        order send gui PLANT:SHARES:DELETE id $id
    }
}



