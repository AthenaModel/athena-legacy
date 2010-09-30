#-----------------------------------------------------------------------
# TITLE:
#    zulufield.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Zulu-time entry field
#
#    An zulufield is a zuluspinbox(n) packages as an order entry field.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export zulufield
}

#-------------------------------------------------------------------
# zulufield

snit::widgetadaptor ::projectgui::zulufield {
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -state state
    #
    # state must be "normal" or "disabled".

    option -state                     \
        -default         "normal"     \
        -configuremethod ConfigState

    method ConfigState {opt val} {
        set options($opt) $val
        
        if {$val eq "normal"} {
            $hull configure -state readonly
        } elseif {$val eq "disabled"} {
            $hull configure -state disabled
        } else {
            error "Invalid -state: \"$val\""
        }
    }

    # -changecmd command
    # 
    # Specifies a command to call whenever the field's content changes
    # for any reason.  The new value is appended to the command as a 
    # single argument.

    option -changecmd \
        -default ""

    #-------------------------------------------------------------------
    # Instance Variables

    variable oldValue ""   ;# Used to detect changes.

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, install the hull
        installhull using zuluspinbox             \
            -state           readonly             \
            -font            codefont             \
            -increment       1440

        # NEXT, configure the arguments
        $self configurelist $args

        # NEXT, prepare to signal changes
        bind $win <ButtonRelease-1> [mymethod DetectChange]
        bind $win <KeyRelease>      [mymethod DetectChange]
    }

    #-------------------------------------------------------------------
    # Event Handlers

    # DetectChange
    #
    # Calls the change command if the field's value has changed.

    method DetectChange {} {
        set value [$self get]

        if {$value eq $oldValue} {
            return
        }

        set oldValue $value

        if {$options(-changecmd) ne ""} {
            {*}$options(-changecmd) $value
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method get to hull
    delegate method * to hull

    # set value
    #
    # value    A new value
    #
    # Sets the combobox value, first retrieving valid values.  If 
    # the new value isn't one of the valid values, it's ignored.

    method set {value} {
        # FIRST, set the value
        $hull set $value

        # NEXT, detect changes
        $self DetectChange
    }
}

#-------------------------------------------------------------------
# Register the field.

::formlib::form register zulu ::projectgui::zulufield
