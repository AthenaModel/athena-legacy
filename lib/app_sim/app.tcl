#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Application Ensemble
#
#    This module defines app, the application ensemble.  app encapsulates 
#    all of the functionality of athena_sim(1), including the application's 
#    start-up behavior.  To invoke the  application,
#
#        package require app_sim
#        app init $argv
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Required Packages

# All needed packages are required in app_sim.tcl.
 
#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # TBD

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv  Command line arguments (if any)
    #
    # Initializes the application.
    typemethod init {argv} {
        # FIRST, "Process" the command line.
        if {[llength $argv] > 1} {
            app usage
            exit 1
        }

        # NEXT, creating the working directory.
        if {[catch {workdir init} result]} {
            app exit {
                |<--
                Error, could not create working directory: 

                    [workdir join]

                Reason: $result
            }
        }

        # NEXT, open the debugging log.
        logger ::log                                           \
            -simclock   ::simclock                             \
            -logdir     [workdir join log app_sim]             \
            -newlogcmd  [list notifier send $type <AppLogNew>]
            

        # NEXT, enable notifier(n) tracing
        notifier trace [myproc NotifierTrace]

        # NEXT, Create the working scenario RDB and initialize simulation
        # components
        map      init
        scenario init
        cif      init
        order    init
        nbhood   init
        nbrel    init
        group    init
        civgroup init
        frcgroup init
        orggroup init
        nbgroup  init
        sat      init
        rel      init
        coop     init

        # NEXT, Withdraw the default toplevel window, and create 
        # the main GUI components.
        wm withdraw .
        appwin .main -main yes

        # NEXT, set the icon for this and subsequent windows.
        set icon [image create photo \
                      -file [file join $::app_sim::library icon.png]]
        wm iconphoto .main -default $icon

        # NEXT, initialize the order GUI
        orderdialog init
        
        # NEXT, log that we're up.
        log normal app "Athena [version]"

        # NEXT, if a scenario file is specified on the command line,
        # open it.
        if {[llength $argv] == 1} {
            scenario open [file normalize [lindex $argv 0]]
        }
    }

    # NotifierTrace subject event eargs objects
    #
    # A notifier(n) trace command

    proc NotifierTrace {subject event eargs objects} {
        set objects [join $objects ", "]
        log detail notify "send $subject $event [list $eargs] to $objects"
    }

    #-------------------------------------------------------------------
    # Utility Type Methods

    # usage
    #
    # Displays the application's command-line syntax
    
    typemethod usage {} {
        puts "Usage: athena sim"
        puts ""
        puts "See athena_sim(1) for more information."
    }

    # puts text
    #
    # text     A text string
    #
    # Writes the text to the message line of the topmost appwin.

    typemethod puts {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            $topwin puts $text
        }
    }

    # error text
    #
    # text       A tsubst'd text string
    #
    # Displays the error in a message box

    typemethod error {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            uplevel 1 [list [app topwin] error $text]
        } else {
            error $text
        }
    }

    # exit ?text?
    #
    # Optional error message, tsubst'd
    #
    # Exits the program

    typemethod exit {{text ""}} {
        # FIRST, output the text.
        if {$text ne ""} {
            puts [uplevel 1 [list tsubst $text]]
        }

        # NEXT, clean up the working files
        workdir cleanup

        # NEXT, exit
        exit
    }

    # topwin ?subcommand...?
    #
    # subcommand    A subcommand of the topwin, as one argument or many
    #
    # If there's no subcommand, returns the name of the topmost appwin.
    # Otherwise, delegates the subcommand to the top win.  If there is
    # no top win, this is a noop.

    typemethod topwin {args} {
        # FIRST, determine the topwin
        set topwin ""

        foreach w [lreverse [wm stackorder .]] {
            if {[winfo class $w] eq "Appwin"} {
                set topwin $w
                break
            }
        }

        if {[llength $args] == 0} {
            return $topwin
        } elseif {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        return [$topwin {*}$args]
    }
}


#-------------------------------------------------------------------
# Miscellaneous Application Utilities

# bgerror msg
#
# Logs background errors; the errorInfo is stored in ::bgErrorInfo

proc bgerror {msg} {
    global errorInfo
    global bgErrorInfo

    set bgErrorInfo $errorInfo
    log error app "bgerror: $msg"
    log error app "Stack Trace:\n$bgErrorInfo"

    app error {
        |<--
        An unexpected error has occurred;
        please see the log for details.
    }
}




