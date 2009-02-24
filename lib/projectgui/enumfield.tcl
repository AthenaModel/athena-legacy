#-----------------------------------------------------------------------
# TITLE:
#    enumfield.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Enum data entry field
#
#    An enumfield is a combobox with a (possibly dynamic) set of values.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export enumfield
}

#-------------------------------------------------------------------
# enumfield

snit::widgetadaptor ::projectgui::enumfield {
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

    # -enumtype enumtype
    #
    # Specifies an enumeration type to provide values.  This option
    # overrides -valuecmd.

    option -enumtype

    # -valuecmd command
    #
    # Specifies a command to be called dynamically to provide values.

    option -valuecmd

    #-------------------------------------------------------------------
    # Instance Variables

    variable oldValue ""   ;# Used to detect changes.

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, install the hull
        installhull using ttk::combobox           \
            -exportselection yes                  \
            -state           readonly             \
            -takefocus       1                    \
            -width           20                   \
            -postcommand     [mymethod GetValues]

        # NEXT, configure the arguments
        $self configurelist $args

        # NEXT, prepare to signal changes
        bind $win <<ComboboxSelected>> [mymethod DetectChange]
    }

    #-------------------------------------------------------------------
    # Event Handlers

    # GetValues
    #
    # Retrieves the valid values when a -valuecmd or -enumtype is 
    # specified (otherwise, does nothing).
    #
    # This is called when the dropdown list is posted, and when 
    # the value is to be set explicitly.
    
    method GetValues {} {
        if {$options(-enumtype) ne ""} {
            # TBD: We can do something fancier than this!
            $self configure -values [{*}$options(-enumtype) names]
        } elseif {$options(-valuecmd) ne ""} {
            $self configure -values [uplevel \#0 $options(-valuecmd)]
        }
    }

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
        # FIRST, retrieve valid values if need be
        $self GetValues

        # NEXT, is this value valid?  If not, set the value to ""
        if {$value ni [$self cget -values]} {
            $hull set ""
        } else {
            $hull set $value
        }

        # NEXT, detect changes
        $self DetectChange
    }
}

