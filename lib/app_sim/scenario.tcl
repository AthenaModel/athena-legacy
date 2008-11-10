#-----------------------------------------------------------------------
# TITLE:
#    scenario.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Scenario Ensemble
#
#    This module does all scenario file for the application.  It is
#    responsible for the open/save/save as/new scenario functionality;
#    as such, it manages the scenariodb(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# scenario ensemble

snit::type scenario {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent rdb                ;# The scenario RDB

    #-------------------------------------------------------------------
    # Type Variables

    # Info Array: most scalars are stored here
    #
    # dbfile      Name of the current scenario file

    typevariable info -array {
        dbfile  ""
    }

    #-------------------------------------------------------------------
    # Singleton Initializer

    # init
    #
    # Initializes the scenario RDB.

    typemethod init {} {
        # FIRST, create the a clean working RDB.
        set rdb [scenariodb ::rdb]

        set rdbfile [workdir join rdb working.rdb]

        file delete -force $rdbfile
        rdb open $rdbfile
        rdb clear
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

        # NEXT, log it.
        log newlog new
        log normal scn "New Scenario: $filename"

        # NEXT, notify the app
        notifier send ::scenario <ScenarioNew>
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

        # NEXT, log it.
        log newlog open
        log normal scn "Open Scenario: $filename"

        # NEXT, notify the app
        notifier send ::scenario <ScenarioOpened>
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

            set dbfile $info(dbfile)
        } else {
            set dbfile $filename
        }

        # FIRST, Save, and check for errors.
        if {[catch {
            if {[file exists $dbfile]} {
                file rename -force $dbfile [file rootname $dbfile].bak
            }

            rdb saveas $dbfile
        } result]} {
            app error {
                |<--
                Could not save as
                
                    $dbfile

                $result
            }
            return 0
        }

        # NEXT, save the name
        set info(dbfile) $dbfile

        # NEXT, log it.
        if {$filename eq ""} {
            log normal scn "Save Scenario: $filename"
        } else {
            log newlog saveas
            log normal scn "Save Scenario As: $filename"
        }

        # NEXT, Notify the app
        notifier send ::scenario <ScenarioSaved>

        return 1
    }

    # dbfile
    #
    # Returns the name of the current scenario file

    typemethod dbfile {} {
        return $info(dbfile)
    }

    # unsaved
    #
    # Returns 1 if there are unsaved changes, and 0 otherwise.
    #
    # TBD: We need to handle significant in-memory changes, if any.
    # scenariodb(n) handles the RDB chagnes.

    typemethod unsaved {} {
        return [rdb unsaved]
    }
}







