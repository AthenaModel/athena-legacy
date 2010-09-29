#-----------------------------------------------------------------------
# TITLE:
#    lazyupdater.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsutil(n) lazy update manager
#
#    It's often useful to update an object in a lazy fashion.  Suppose
#    that any 10 option settings might trigger an object to update itself,
#    but that you only want to update it once, no matter how many of 
#    the option settings are set.  Define a lazyupdater with a -command;
#    each option update should call the lazyupdater's "update" method.
#    Later, once things have stabilized, the -command will be called.
#
#    If the object in question is a Tk widget, the lazyupdater will
#    call -command only when the window is mapped, and will automatically
#    schedule an update when the <Map> event is received.
#
#    lazyupdater(n) is a wrapper around timeout(n).
#
#-----------------------------------------------------------------------

namespace eval ::marsutil:: {
    namespace export lazyupdater
}

snit::type ::marsutil::lazyupdater {
    #-------------------------------------------------------------------
    # Components

    component timeout ;# timeout(n)

    #-------------------------------------------------------------------
    # Options

    delegate option -delay to timeout as -interval

    # -command
    #
    # The script to call when an update is executed.

    option -command

    # -window
    #
    # Name of related window. (Requires Tk)
    
    option -window \
        -configuremethod ConfigureWindow

    method ConfigureWindow {opt val} {
        if {$val eq "" && $options(-window) ne ""} {
            bind $options(-window) <Map> ""
        } elseif {$val ne ""} {
            bind $val <Map> [mymethod update]
        }

        set options(-window) $val
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the timeout
        install timeout using timeout ${selfns}::timeout \
            -command    [mymethod Execute]               \
            -interval   1                                \
            -repetition no 

        # NEXT, process the options
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Private Methods

    # Execute
    #
    # Calls the user's -command unless there's a -window and it's 
    # unmapped.

    method Execute {} {
        if {$options(-window) ne "" &&
            [winfo ismapped $options(-window)]
        } {
            uplevel \#0 $options(-command)
        }
    }


    #-------------------------------------------------------------------
    # Public methods

    # update
    #
    # Schedules the lazyupdater to call its -command.

    method update {} {
        if {$options(-window) eq "" ||
            [winfo ismapped $options(-window)]
        } {
            $timeout schedule -nocomplain
        }
    }
}




