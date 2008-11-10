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

    # Info Array: most scalars are stored here
    #
    # TBD

    typevariable info -array {
    }

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

        # NEXT, create the GUI.  Withdraw ., and create the new
        # main window.
        wm withdraw .
        mainwin .main

        # NEXT, Create the working scenario RDB
        scenario init

        # NEXT, if a scenario file is specified on the command line,
        # open it.

        if {[llength $argv] == 1} {
            scenario open [file normalize [lindex $argv 0]]
        }
    }

    #-------------------------------------------------------------------
    # Map Importing
    #
    # TBD: It's not clear where this should live.  Possibly in 
    # scenario(sim), but possibly not.

    # importmap filename
    #
    # filename     An image file
    #
    # Attempts to import the image into the RDB.

    typemethod importmap {filename} {
        # FIRST, is it a real image?
        if {[catch {
            set map [image create photo -file $filename]
        } result]} {
            app error {
                |<--
                Could not open the specified file as a map image:

                $filename
            }

            return
        }
        
        # NEXT, get the image data, and save it in the RDB
        set tail [file tail $filename]
        set data [$map data -format jpeg]

        rdb eval {
            INSERT OR REPLACE
            INTO maps(id, filename, data)
            VALUES(1,$tail,$data);
        }

        image delete $map

        # NEXT, Notify the application.
        notifier send ::app <AppImportedMap> $filename
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
    # Writes the text to the message line

    typemethod puts {text} {
        .main puts $text
    }

    # error text
    #
    # text       A tsubst'd text string
    #
    # Displays the error in a message box

    typemethod error {text} {
        uplevel 1 [list .main error $text]
    }

    # exit ?text?
    #
    # Optional error message, tsubst'd
    #
    # Exits the program

    typemethod exit {{text ""}} {
        if {$text ne ""} {
            puts [uplevel 1 [list tsubst $text]]
        }

        exit
    }
}







