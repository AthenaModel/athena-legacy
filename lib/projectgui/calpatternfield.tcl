#-----------------------------------------------------------------------
# TITLE:
#    calpatternfield.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: calpattern(n) data entry field
#
#    A calpattern(n) field is an ecalpattern combobox followed by 
#    entry widgets specific to the chosen ecalpattern.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export calpatternfield
}

#-----------------------------------------------------------------------
# enumfield

snit::widget ::projectgui::calpatternfield {
    #-------------------------------------------------------------------
    # Components

    component combo   ;# The combobox

    #-------------------------------------------------------------------
    # Instance Variables

    variable flagwin     {}   ;# List of day checkbox widgets
    variable flag -array {}   ;# Array of day flags
    variable oldValue    ""   ;# Used to detect changes.


    #-------------------------------------------------------------------
    # Options

    # -state state
    #
    # state must be "normal" or "disabled".

    option -state                     \
        -default         "normal"     \
        -configuremethod ConfigState

    method ConfigState {opt val} {
        set options($opt) $val
        
        if {$val eq "normal"} {
            $combo configure -state readonly
        } elseif {$val eq "disabled"} {
            $combo configure -state disabled
        } else {
            error "Invalid -state: \"$val\""
        }

        $self SetDaysState
    }

    # -changecmd command
    # 
    # Specifies a command to call whenever the field's content changes
    # for any reason.  The new value is appended to the command as a 
    # single argument.

    option -changecmd \
        -default ""


    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, install the hull
        install combo using menubox $win.combo                     \
            -exportselection yes                                   \
            -takefocus       1                                     \
            -width           12                                    \
            -values          [::projectlib::ecalpattern longnames] \
            -command         [mymethod ComboChange]

        grid $combo -row 0 -column 0 -sticky e -padx {0 8}

        set f [ttk::frame $win.f]
        grid $f -row 0 -column 1 -sticky ew

        set col 1

        foreach day [edayname names] {
            set w $f.[string tolower $day]
            set lab ${w}lab
            set flag($day) 1
            lappend flagwin $w

            ttk::label $lab \
                -text       $day

            ttk::checkbutton $w                  \
                -takefocus 0                     \
                -onvalue   1                     \
                -offvalue  0                     \
                -variable  [myvar flag($day)]    \
                -command   [mymethod FlagChange]

            grid $lab -row 0 -column $col -sticky sew
            grid $w   -row 1 -column $col -sticky new

            incr col
        }

        # NEXT, configure the arguments
        $self configurelist $args

        # NEXT, set the days state
        $self SetDaysState
    }

    #-------------------------------------------------------------------
    # Event Handlers

    # ComboChange
    #
    # Called when the combobox changes

    method ComboChange {} {
        $self SetDaysState
        $self DetectChange
    }


    # FlagChange
    #
    # Called when any flag changes

    method FlagChange {} {
        # FIRST, if no flags are set, set the first one.
        set sum 0

        foreach day [array names flag] {
            incr sum $flag($day)
        }

        if {$sum == 0} {
            set flag(Su) 1
        }

        # NEXT, detect any changes.
        $self DetectChange
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

    # SetDaysState
    #
    # Sets the state of the day flag widgets based on -state and 
    # the selected pattern name.

    method SetDaysState {} {
        if {[$combo get] ne "By Week Day"} {
            set state disabled
            grid forget $win.f
        } else {
            set state $options(-state)
            grid $win.f -row 0 -column 1 -sticky ew
        }

        foreach w $flagwin {
            $w configure -state $state

            if {$state eq "disabled"} {
                ${w}lab configure -foreground gray
            } else {
                ${w}lab configure -foreground black
            }
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # get
    #
    # Retrieves the current value.

    method get {} {
        set value [ecalpattern name [$combo get]]

        if {$value eq "byweekday"} {
            foreach day [::projectlib::edayname names] {
                if {$flag($day)} {
                    lappend value $day
                }
            }
        }

        return $value
    }

    # set value
    #
    # value    A new value
    #
    # Sets the combobox value, first retrieving valid values.  If 
    # the new value isn't one of the valid values, it's ignored.

    method set {value} {
        set name [lindex $value 0]
        set parms [lrange $value 1 end]

        $combo set [ecalpattern longname $name]

        if {$name eq "byweekday"} {
            foreach day [edayname names] {
                set flag($day) 0
            }

            foreach day $parms {
                set flag($day) 1
            }
        }

        # NEXT, detect changes
        $self SetDaysState
        $self DetectChange
    }
}

#-------------------------------------------------------------------
# Register the field.

::formlib::form register cpat ::projectgui::calpatternfield

