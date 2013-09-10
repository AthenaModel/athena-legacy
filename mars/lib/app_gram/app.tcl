#-----------------------------------------------------------------------
# FILE: app.tcl
#
# Main Application Module
#
# PACKAGE:
#   app_gram(n) -- mars_gram(1) implementation package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#   Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module: app
#
# This module defines app, the application ensemble.  app contains
# the application start-up code, as well a variety of subcommands
# available to the application as a whole.  To invoke the 
# application,
#
# > package require app_gram
# > app init $argv
#
# Note that app_gram is usually invoked by mars(1).

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Components

    typecomponent cli               ;# The executive shell
    typecomponent msgline           ;# The application message line.
    typecomponent rdb               ;# The runtime database, for nsat(n)
                                     # inputs.
                                     
    #-------------------------------------------------------------------
    # Group: Application Initialization

    # Type method: init
    #
    # Initializes the application.
    #
    # Syntax:
    #   app init _argv_
    #
    #   argv - Command line arguments

    typemethod init {argv} {
        # FIRST, handle the command line.
        set gramdbFile  ""
        set initScript ""

        while {[string match "-*" [lindex $argv 0]]} {
            set opt [lshift argv]

            switch -exact -- $opt {
                -help {
                    app usage
                    exit 0
                }
                -script {
                    set initScript [lshift argv]
                }
                default {
                    puts "Unknown option: $opt"
                    app usage
                    exit 1
                }
            }
        }

        if {[llength $argv] == 1} {
            set gramdbFile [lindex $argv 0]
        } elseif {[llength $argv] != 0} {
            app usage
            exit 1
        }
        
        # NEXT, allow the developer to pop up the debugger window
        # no matter what window they are in.
        bind all <Control-F12> [list debugger new]

        # NEXT, initialize the application.
        app CreateLogger               ;# Creates ::log, allowing logging
        app CreateRdb                  ;# Creates ::rdb.
        executive init                 ;# Initialize the command executive
        parmdb init                    ;# Initialize the parameter database
        sim init                       ;# Initialize the simulation manager

        # NEXT, define global conditions
        namespace eval ::cond {
            statecontroller dbloaded -events {
                ::app <Init>
                ::sim <Reset>
            } -condition {
                [::sim dbloaded]
            }
        }
        
        # NEXT, Withdraw the default toplevel window, and create 
        # the main GUI window
        wm withdraw .
        appwin .main -main yes

        # NEXT, prepare to receive simulation events
        notifier trace [myproc NotifierTrace]

        # NEXT, load the database, if any.
        if {$gramdbFile ne ""} {
            executive evalsafe [list load $gramdbFile]
        } else {
            notifier send ::app <Init>
        }

        # NEXT, run the initial script, if any.
        if {$initScript ne ""} {
            executive evalsafe [list call $initScript]
        }

        app puts "Welcome to GRAM Workbench!"
    }

    # Type method: CreateLogger
    #
    # Creates and configures the logger, ::log, for this application.

    typemethod CreateLogger {} {
        set logdir [file normalize [file join . log mars_gram]]
        
        file mkdir $logdir
        
        logger ::log \
            -simclock ::simclock                              \
            -logdir    $logdir                                \
            -newlogcmd [list notifier send $type <AppLogNew>]

        log normal app "mars_gram(1)"
    }

    # Type method: CreateRdb
    #
    # Creates and initializes an in-memory database to be the
    # Run-Time Database (RDB); it includes the schemas for
    # gramdb(5) and gram(n).

    typemethod CreateRdb {} {
        set rdb [sqldocument ::rdb -clock ::simclock]
        rdb register ::simlib::gramdb
        rdb register ::simlib::gram
        rdb open :memory:
        rdb clear
    }

    #-------------------------------------------------------------------
    # Group: Event Handlers
    
    # Proc: NotifierTrace
    #
    # A notifier(n) trace command; it simply logs all notifier events.

    proc NotifierTrace {subject event eargs objects} {
        set objects [join $objects ", "]
        log detail notify "send $subject $event [list $eargs] to $objects"
    }
    
    #-------------------------------------------------------------------
    # Group: Public Type Methods
    
    # Type method: usage
    #
    # Outputs the application's command line syntax to stdout.

    typemethod usage {} {
        puts {Usage: mars gram [options...] [file.gramdb]}
        puts ""
        puts "    -script script.tcl     Execute the named script file."
        puts "    -help                  Display this text."
        puts ""
        puts "See mars_gram(1) for more information."
    }

    # Type method: puts
    #
    # Writes the text to the message line of the topmost <appwin>.
    #
    # Syntax:
    #   app puts _text_
    #
    #   text - A text string

    typemethod puts {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            $topwin puts $text
        }
    }

    # Type method: error
    #
    # Displays an error message in a messagebox(n) message box.
    #
    # Syntax:
    #   app error _text_
    #
    #   text - A tsubst'd text string

    typemethod error {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            uplevel 1 [list [app topwin] error $text]
        } else {
            error $text
        }
    }

    # Type method: exit 
    #
    # Exits the program, writing an optional message to stdout.
    # Saves the CLI history and the parmdb settings to ~/.mars_gram/.
    #
    # Syntax:
    #   app exit _?text?_
    #
    #   text - Optional error message, tsubst'd

    typemethod exit {{text ""}} {
        # FIRST, output the text.
        if {$text ne ""} {
            puts [uplevel 1 [list tsubst $text]]
        }

        # NEXT, save preferences and parameters.
        .main savehistory
        parmdb save
    
        # NEXT, exit
        exit
    }

    # Type method: topwin
    #
    # Provides access to the topmost <appwin>.
    #
    # If there's no subcommand, returns the name of the topmost <appwin>
    # window. Otherwise, delegates the subcommand to the topmost window.
    # If there is no topmost window, this is a no-op.
    #
    # Syntax:
    #   app topwin _?subcommand...?_
    #
    #   subcommand... - A subcommand of the topwin, expanded or
    #                   unexpanded.

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
# Section: Miscellaneous Commands

# proc: bgerror 
#
# Customized bgerror handler; Logs background error messages.
#
# Syntax:
#   bgerror _message_
#
#   message - An error message

proc bgerror {message} {
    global errorInfo
    global bgErrorInfo

    set bgErrorInfo $errorInfo

    log error app "bgerror: $message"
}








