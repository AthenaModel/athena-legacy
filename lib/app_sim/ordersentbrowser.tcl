#-----------------------------------------------------------------------
# TITLE:
#    ordersentbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    ordersentbrowser(sim) package: Order History browser.
#
#    This widget displays a formatted list of the orders that have
#    already been executed.
#
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor ordersentbrowser {
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
            -table        "gui_cif"                   \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 3                           \
            -displaycmd   [mymethod DisplayData]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the columns and labels.
        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Tick}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Zulu}
        $hull insertcolumn end 0 {Undo?}
        $hull insertcolumn end 0 {Order}
        $hull insertcolumn end 0 {Parameters}

        $hull sortbycolumn 0 -decreasing

        # NEXT, update individual entities when they change.
        notifier bind ::cif <Update> $self [mymethod reload]
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
                [list $id $tick $zulu $canUndo $name $parmdict]
        }
    }
}


