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
#    It is a variation of browser_base(n).
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
    # Components

    component cancelbtn   ;# The "Cancel" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   yes                         \
            -table        "gui_orders"                \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 3                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        # Cancel Button
        install cancelbtn using button $bar.cancel \
            -image      ::projectgui::icon::x22    \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod CancelSelected]

        DynamicHelp::add $cancelbtn -text "Cancel Selected Order"

        cond::orderIsValidSingle control $cancelbtn \
            order   ORDER:CANCEL                     \
            browser $win

        pack $cancelbtn -side right


        # NEXT, create the columns and labels.
        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Tick}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Zulu}
        $hull insertcolumn end 0 {Order}
        $hull insertcolumn end 0 {Parameters}

        $hull sortbycolumn 1 -increasing

        # NEXT, update individual entities when they change.
        notifier bind ::order <Queue> $self [mymethod reload]
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

    # DisplayData dict
    # 
    # dict   the data dictionary that contains the entity information
    #
    # This method converts the entity data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            $hull setdata $id \
                [list $id $tick $zulu $name $parmdict]
        }
    }


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
        set id [lindex [$hull curselection] 0]

        # NEXT, Send the cancel order.
        order send gui ORDER:CANCEL id $id
    }
}

