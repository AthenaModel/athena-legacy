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
#    all of the functionality of minerva_sim(1), including the application's 
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
        logger ::log                                                  \
            -simclock     ::simclock                                  \
            -logdir       [workdir join log app_sim]                  \
            -overflowcmd  [list notifier send $type <AppLogOverflow>]

        # NEXT, enable notifier(n) tracing
        notifier trace [myproc NotifierTrace]

        # NEXT, Create the working scenario RDB and initialize simulation
        # components
        scenario init
        map      init
        nbhood   init

        # NEXT, Withdraw the default toplevel window, and create 
        # the main GUI components.
        wm withdraw .
        appwin .main -main yes

        # NEXT, set the icon for this and subsequent windows.
        set icon [image create photo \
                      -file [file join $::app_sim::library icon.png]]
        wm iconphoto .main -default $icon

        # NEXT, prepare to handle orders
        order       init
        ordergui init

        ordergui entrytype enum urbanization \
            -values [eurbanization names]

        # NEXT, log that we're up.
        log normal app "Minerva [version]"

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
        log detail ntfy "send $subject $event [list $eargs] to $objects"
    }

    #-------------------------------------------------------------------
    # Utility Type Methods

    # usage
    #
    # Displays the application's command-line syntax
    
    typemethod usage {} {
        puts "Usage: minerva sim"
        puts ""
        puts "See minerva_sim(1) for more information."
    }

    # puts text
    #
    # text     A text string
    #
    # Writes the text to the message line of the topmost appwin.

    typemethod puts {text} {
        [app topwin] puts $text
    }

    # error text
    #
    # text       A tsubst'd text string
    #
    # Displays the error in a message box

    typemethod error {text} {
        uplevel 1 [list [app topwin] error $text]
    }

    # ask mode text
    #
    # mode       yesno| yesnocancel
    # text       A tsubst'd text string
    #
    # Asks a question in a message box

    typemethod ask {mode text} {
        uplevel 1 [list [app topwin] ask $mode $text]
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

    # topwin
    #
    # Returns the name of the topmost appwin

    typemethod topwin {} {
        foreach w [lreverse [wm stackorder .]] {
            if {[winfo class $w] eq "Appwin"} {
                return $w
            }
        }

        return ""
    }
}








