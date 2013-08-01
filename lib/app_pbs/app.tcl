#-----------------------------------------------------------------------
# FILE: app.tcl
#
#   Application Ensemble.
#
# PACKAGE:
#   app_pbs(n) -- athena_pbs(1) implementation package
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

# All needed packages are required in app_cell.tcl.
 
#-----------------------------------------------------------------------
# app
#
# app_pbs(n) Application Ensemble
#
# This module defines app, the application ensemble.  app encapsulates 
# all of the functionality of athena_sim(1), including the application's 
# start-up behavior.  To invoke the  application,
#
# > package require app_pbs
# > app init $argv
#
# The app_pbs(n) package can be invoked by athena(1).

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Global Lookup Variables

    # Type Variable derivedfg
    #
    # The foreground color for derived data (as opposed to input data).
    # This color is used by a variety of data browsers throughout the
    # application.  TBD: Consider making this a preference.

    typevariable derivedfg "#008800"

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

        # NEXT, see if PBS is available, take into account the which
        # command may be undefined
        set qsub ""
        set pbs_exists 1

        if {[catch {set qsub [exec which qsub]}]} {
            set pbs_exists 0
        } elseif {$qsub eq ""} {
            set pbs_exists 0
        }
                
        if {!$pbs_exists} {
            app exit \
                "This application is not available on systems that do not have PBS"
        }

        # NEXT, initialize the non-GUI modules

        # NEXT, create statecontrollers.
        namespace eval ::sc {}

        # Have a syntactically correct model
        statecontroller ::sc::notrunning -events {
            ::main <State>
        } -condition {
            [.main jobstate] ne "RUNNING"
        }

        # NEXT, create the real main window.
        appwin .main
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


