#-----------------------------------------------------------------------
# TITLE:
#    zuluspinbox.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Mars marsgui(n) package: Zulu-Time Spinbox widget
#
#    A Zulu-Time spinbox is a spinbox customized for the entry of
#    of zulu-time strings.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export zuluspinbox
}


#-----------------------------------------------------------------------
# The zuluspinbox Widget Type

snit::widget ::marsgui::zuluspinbox {
    widgetclass ZuluSpinbox

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # TBD
    }

    #-------------------------------------------------------------------
    # Components

    component spinbox   ;# The real spinbox

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the real spinbox

    delegate option -font         to spinbox
    delegate option -textvariable to spinbox
    delegate option -width        to spinbox
    delegate option -state        to spinbox

    # Other options

    # -earliest zulu
    #
    # zulu      A Zulu-time string
    #
    # Sets the earliest zulu-time allowed.

    option -earliest \
        -default 0                   \
        -configuremethod CfgZuluTime \
        -cgetmethod      CgetZuluTime

    # -latest zulu
    #
    # zulu      A Zulu-time string
    #
    # Sets the latest zulu-time allowed.

    option -latest \
        -default         0           \
        -configuremethod CfgZuluTime \
        -cgetmethod      CgetZuluTime

    # -increment minutes
    #
    # minutes     Some number of minutes
    #
    # Sets the increment value for the spin buttons.
    
    option -increment -default 1

    # -validitycmd cmd
    # 
    # A command to execute whenever the value in the spinbox changes
    # between valid and invalid.  The current validity value is appended
    # as an arguement. 1 for valid, 0 for invalid.
    option -validitycmd -default ""

    #-------------------------------------------------------------------
    # Instance variables

    variable valid 1;# Boolean flag

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the spinbox.
        install spinbox using spinbox $win.spinbox \
            -command [mymethod SpinHandler %s %d]  \
            -validate "key"                        \
            -vcmd    [mymethod ValidateCmd %P]
        
        # NEXT, get the options
        $self configurelist $args

        # NEXT, initialize the spinbox value, unless there's a text
        # variable
        if {[$spinbox cget -textvariable] eq ""} {
            $spinbox set [$self cget -earliest]
        }

        # NEXT, pack the widget
        pack $win.spinbox -fill both -expand 1
    }

    #-------------------------------------------------------------------
    # Private Methods

    # CfgZuluTime opt val
    #
    # opt      -earliest or -latest
    # val      A zulu-time string
    #
    # Validates that val is a zulu-time string; converts it to seconds and
    # saves it.

    method CfgZuluTime {opt val} {
        if {$val ne ""} {
            set options($opt) [::marsutil::zulu tosec $val]
        } else {
            set options($opt) 0
        }
    }

    # CgetZuluTime opt
    #
    # opt      -earliest or -latest
    # val      A zulu-time string
    #
    # Converts the option's value back to a zulu-time string and returns
    # it.

    method CgetZuluTime {opt} {
        if {$options($opt) != 0} {
            return [::marsutil::zulu fromsec $options($opt)]
        } else {
            return ""
        }
    }

    # SpinHandler value direction
    #
    # value      The value in the spinbox
    # direction  up or down
    #
    # Updates the value in the spinbox given the options

    method SpinHandler {value direction} {
        if {[catch {::marsutil::zulu tosec $value} seconds]} {
            bell
            return
        }

        if {$direction eq "up"} {
            incr seconds [expr {60*$options(-increment)}]
        } else {
            incr seconds [expr {-60*$options(-increment)}]
        }

        if {$seconds < $options(-earliest)} {
            set seconds $options(-earliest)
        } elseif {$options(-latest) > 0 &&
                  $seconds > $options(-latest)} {
            set seconds $options(-latest)
        }

        $spinbox set [::marsutil::zulu fromsec $seconds]
    }
    
    # ValidateCmd value 
    #
    # value      The value in the spinbox
    #
    # Validates the value in the spinbox.  Note that this always returns
    # true so the user can see what they're doing.

    method ValidateCmd {value} {

        if {[catch {::marsutil::zulu tosec $value} result]} {
            if {$valid} {
                set valid 0
                $spinbox configure -bg yellow
                callwith $options(-validitycmd) $valid
            }
         } else {
             if {!$valid} {
                 set valid 1
                 $spinbox configure -bg white
                 callwith $options(-validitycmd) $valid
             }
         }

        # Always return 1 to allow unobstructed editing
        return 1
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to spinbox
}





