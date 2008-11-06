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

    typecomponent cli                ;# The cli(n) pane
    typecomponent msgline            ;# The messageline(n)
    typecomponent viewer             ;# The mapviewer(n)
    typecomponent rdb                ;# The scenario RDB

    #-------------------------------------------------------------------
    # Type Variables

    # Info Array: most scalars are stored here
    #
    # dbfile      Name of the current scenario file

    typevariable info -array {
        dbfile ""
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

        # NEXT, open the RDB.
        scenario ::rdb
        set rdbfile [workdir join rdb working.rdb]
        file delete -force $rdbfile
        rdb open $rdbfile
        rdb clear

        # NEXT, if a scenario file is specified on the command line,
        # open it.

        if {[llength $argv] == 1} {
            app open [file normalize [lindex $argv 0]]
        }
    }

    #-------------------------------------------------------------------
    # Scenario Management Methods

    # open filename
    #
    # filename       A .mdb scenario file
    #
    # Opens the specified file name, replacing the existing file.
    #
    # TBD: Should really check that there's no data that needs to
    # be saved.

    typemethod open {filename} {
        # FIRST, load the file.
        if {[catch {
            rdb load $filename
        } result]} {
            app error {
                |<--
                Could not open scenario
                
                    $filename

                $result
            }
            return
        }
        
        # NEXT, save the name.
        set info(dbfile) $filename

        # NEXT, notify the app
        notifier send ::app <AppOpened>
    }

    # save ?filename?
    #
    # filename       Name for the new save file
    #
    # Saves the file, notify the application on success.  If no
    # file name is specified, the dbfile is used.

    typemethod save {{filename ""}} {
        # FIRST, if filename is not specified, get the dbfile
        if {$filename eq ""} {
            if {$info(dbfile) eq ""} {
                error "Cannot save: no file name"
            }

            set filename $info(dbfile)
        }

        # FIRST, Save, and check for errors.
        if {[catch {
            if {[file exists $filename]} {
                file rename -force $filename [file rootname $filename].bak
            }

            rdb saveas $filename
        } result]} {
            app error {
                |<--
                Could not save as
                
                    $filename

                $result
            }
            return
        }

        # NEXT, save the name
        set info(dbfile) $filename

        # NEXT, Notify the app
        notifier send ::app <AppSaved>
    }

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
        set data [$map data -format jpeg]

        rdb eval {
            INSERT OR REPLACE
            INTO maps(zoom, data)
            VALUES(100,$data);
        }

        image delete $map

        # NEXT, Notify the application.
        notifier send ::app <AppImportedMap> $filename
    }

    # dbfile
    #
    # Returns the name of the current scenario file

    typemethod dbfile {} {
        return $info(dbfile)
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







