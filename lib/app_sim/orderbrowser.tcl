#-----------------------------------------------------------------------
# TITLE:
#    orderbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    orderbrowser(sim) package: Order browser.
#
#    This widget displays a formatted list of scheduled orders.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor orderbrowser {
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
        { id       "ID"         -sortmode integer }
        { tick     "Tick"       -sortmode integer }
        { zulu     "Zulu"                         }
        { name     "Order"                        }
        { parmdict "Parameters" -stretchable yes  }
    }

    #-------------------------------------------------------------------
    # Components

    component cancelbtn   ;# The "Cancel" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_orders                  \
            -uid          id                          \
            -titlecolumns 3                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
                ::order <Queue>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        # Cancel Button
        install cancelbtn using mkdeletebutton $bar.cancel \
            "Cancel Selected Order"                        \
            -state   disabled                              \
            -command [mymethod CancelSelected]

        cond::orderIsValidSingle control $cancelbtn \
            order   ORDER:CANCEL                     \
            browser $win

        pack $cancelbtn -side right
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
        cond::orderIsValidSingle update \
            [list $cancelbtn]
    }


    # CancelSelected
    #
    # Called when the user wants to cancel the selected entity.

    method CancelSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Send the cancel order.
        order send gui ORDER:CANCEL id $id
    }
}


