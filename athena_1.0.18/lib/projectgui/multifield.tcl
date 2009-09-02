#-----------------------------------------------------------------------
# TITLE:
#    multifield.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Multi-entity data entry field
#
#    A multifield is a pseudo-field which displays the number of
#    selected entities upon which the dialog will operate, e.g.,
#    "5 Selected".  It is not editable by the user.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export multifield
}

#-------------------------------------------------------------------
# multifield

snit::widgetadaptor ::projectgui::multifield {
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -state state
    #
    # state must be "normal" or "disabled"; however, it's ignored.

    option -state          \
        -default  "normal"

    # -changecmd command
    # 
    # Specifies a command to call whenever the field's content changes
    # for any reason.  The new text is appended to the command as a 
    # single argument.

    option -changecmd \
        -default ""

    #-------------------------------------------------------------------
    # Instance variables

    variable theValue {}  ;# List of selected item IDs

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
        set oldValue $theValue
        set theValue $value

        $hull configure -text "[llength $theValue] Selected"

        # Detect any change
        if {$oldValue ne $value &&
            $options(-changecmd) ne ""} {
            {*}$options(-changecmd) $value
        }
    }

    # get
    #
    # Returns the list of selected item IDs

    method get {} {
        return $theValue
    }
}

