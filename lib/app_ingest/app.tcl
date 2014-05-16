#-----------------------------------------------------------------------
# FILE: app.tcl
#
#   Application Ensemble.
#
# PACKAGE:
#   app_ingest(n) -- athena_ingest(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Required Packages

# All needed packages are required in app_ingest.tcl.
 
#-----------------------------------------------------------------------
# app
#
# app_ingest(n) Application Ensemble
#
# This module defines app, the application ensemble.  app encapsulates 
# all of the functionality of athena_sim(1), including the application's 
# start-up behavior.  To invoke the  application,
#
# > package require app_ingest
# > app init $argv
#
# The app_ingest(n) package can be invoked by athena(1) and by 
# athena_test(1).

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Application Initialization

    # init argv
    #
    # argv - Command line arguments (if any)
    #
    # Initializes the application.  This routine should be called once
    # at application start-up, and passed the arguments from the
    # shell command line.
    
    typemethod init {argv} {
        # FIRST, withdraw the "." window, so that we don't display a blank
        # window during initialization.
        wm withdraw .

        # NEXT, get the application directory
        appdir init

        # NEXT, initialize the non-GUI modules
        rdb      init
        tigr     init
        ingester init

        # NEXT, create the real main window.
        appwin .main

        # NEXT, if there's an .adb file on the command line, open it.
        if {[llength $argv] == 1} {
            # TBD: open it now
        }
    }

    # exit ?text?
    #
    # text - Optional error message, tsubst'd
    #
    # Exits the program,writing the text (if any) to standard output.

    typemethod exit {{text ""}} {
        if {$text ne ""} {
            puts $text
            exit 1
        } else {
            exit
        }
    }

    # puts text
    #
    # text - A text string
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
    # text - A tsubst'd text string
    #
    # Normally, displays the error text in a message box.

    typemethod error {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            uplevel 1 [list [app topwin] error $text]
        } else {
            error $text
        }
    }

    # topwin ?subcommand?
    #
    # subcommand - A subcommand of the topwin, as one argument or many
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



