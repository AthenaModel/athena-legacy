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

    typecomponent rdb                ;# The scenario RDB

    #-------------------------------------------------------------------
    # Type Variables

    # Info Array: most scalars are stored here
    #
    # dbfile      Name of the current scenario file
    # saved       1 if the current data has been saved, and 0 otherwise.

    typevariable info -array {
        dbfile  ""
        saved   1
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
    #
    # TBD: A number of these methods explicitly display errors.  It's 
    # likely that they should just throw relevant errors, and let the 
    # caller display the errors.  We'd want to distinguish between
    # environmental and programming errors.

    # new
    #
    # Creates a new, blank scenario.

    typemethod new {} {
        # FIRST, clear the current scenario data.
        rdb clear

        # NEXT, there is no dbfile.
        set info(dbfile) ""

        # NEXT, there are no changes to save
        set info(saved) 1

        # NEXT, notify the app
        notifier send ::app <AppNew>
    }

    # open filename
    #
    # filename       A .mdb scenario file
    #
    # Opens the specified file name, replacing the existing file.

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

        # NEXT, no changes yet.
        set info(saved)  1

        # NEXT, notify the app
        notifier send ::app <AppOpened>
    }

    # save ?filename?
    #
    # filename       Name for the new save file
    #
    # Saves the file, notify the application on success.  If no
    # file name is specified, the dbfile is used.  Returns 1 if
    # the save is successful and 0 otherwise.

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
            return 0
        }

        # NEXT, save the name
        set info(dbfile) $filename

        # NEXT, no changes yet.
        set info(saved)  1

        # NEXT, Notify the app
        notifier send ::app <AppSaved>

        return 1
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
        set tail [file tail $filename]
        set data [$map data -format jpeg]

        rdb eval {
            INSERT OR REPLACE
            INTO maps(id, filename, data)
            VALUES(1,$tail,$data);
        }

        image delete $map

        # NEXT, change has not been saved.
        set info(saved)  0

        # NEXT, Notify the application.
        notifier send ::app <AppImportedMap> $filename
    }

    # dbfile
    #
    # Returns the name of the current scenario file

    typemethod dbfile {} {
        return $info(dbfile)
    }

    # saved
    #
    # Returns 1 if the current changes have been saved, and 0 otherwise.

    typemethod saved {} {
        return $info(saved)
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







