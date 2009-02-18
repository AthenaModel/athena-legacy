#-----------------------------------------------------------------------
# TITLE:
#    multifield.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    A multifield is an order parameter field displaying a multi-selection
#    message.  It is not editable.
#
#-----------------------------------------------------------------------

snit::widgetadaptor multifield {
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -state state
    #
    # state must be "normal" or "disabled"; however, it's ignored.

    option -state          \
        -default  "normal"

    #-------------------------------------------------------------------
    # Instance variables

    variable theValue    ;# List of selected item IDs

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, install the hull
        installhull using ttk::label        \
            -width           20             \
            -text            ""

        # NEXT, set the initial value
        $self set {}

        # NEXT, configure the arguments
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # set value
    #
    # value    A list of multiply-selected item IDs
    #
    # Saves the value and updates the display

    method set {value} {
        set theValue $value

        $hull configure -text "[llength $theValue] Selected"
    }

    # get
    #
    # Returns the list of selected item IDs

    method get {} {
        return $theValue
    }
}
