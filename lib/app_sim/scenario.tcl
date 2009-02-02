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
    # saveable    List of saveables.

    typevariable info -array {
        dbfile    ""
        saveables {}
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
        InitializeRuntimeData
    }

    #-------------------------------------------------------------------
    # Scenario Management Methods

    # new
    #
    # Creates a new, blank scenario.

    typemethod new {} {
        # FIRST, initialize the runtime data
        InitializeRuntimeData

        # NEXT, there is no dbfile.
        set info(dbfile) ""

        # NEXT, log it.
        log newlog new
        log normal scenario "New Scenario: Untitled"
        
        app puts "New scenario created"

        # NEXT, Reconfigure the app
        $type reconfigure
    }

    # open filename
    #
    # filename       An .adb scenario file
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

        # NEXT, define the temporary schema definitions
        DefineTempSchema

        # NEXT, restore the saveables
        $type RestoreSaveables

        # NEXT, save the name.
        set info(dbfile) $filename

        # NEXT, log it.
        log newlog open
        log normal scenario "Open Scenario: $filename"

        app puts "Opened Scenario [file tail $filename]"

        # NEXT, Reconfigure the app
        $type reconfigure
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

        # NEXT, save the saveables
        $type SaveSaveables

        # NEXT, notify the simulation that we're saving, so other 
        # modules can prepare.
        notifier send ::scenario <Saving>

        # NEXT, Save, and check for errors.
        if {[catch {
            if {[file exists $dbfile]} {
                file rename -force $dbfile [file rootname $dbfile].bak
            }

            rdb saveas $dbfile
        } result opts]} {
            log warning scenario "Could not save: $result"
            log error scenario [dict get $opts -errorinfo]
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
        if {$filename ne ""} {
            log newlog saveas
        }

        log normal scenario "Save Scenario: $info(dbfile)"

        app puts "Saved Scenario [file tail $info(dbfile)]"

        notifier send $type <ScenarioSaved>

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

    typemethod unsaved {} {
        if {[rdb unsaved]} {
            return 1
        }
        
        foreach saveable $info(saveables) {
            if {[{*}$saveable changed]} {
                return 1
            }
        }

        return 0
    }

    #-------------------------------------------------------------------
    # Simulation Reconfiguration

    # reconfigure
    #
    # Reconfiguration occurs when a brand new scenario is created or
    # loaded.  All application modules must re-initialize themselves
    # at this time.
    #
    # * Simulation modules are reconfigured directly by this routine.
    # * User interface modules are reconfigured on receipt of the
    #   <Reconfigure> event.

    typemethod reconfigure {} {
        # FIRST, Reconfigure the simulation
        cif      reconfigure
        map      reconfigure
        nbhood   reconfigure
        group    reconfigure
        civgroup reconfigure
        frcgroup reconfigure
        orggroup reconfigure
        nbgroup  reconfigure
        sat      reconfigure
        rel      reconfigure

        # NEXT, Reconfigure the GUI
        notifier send $type <Reconfigure>
    }

    #-------------------------------------------------------------------
    # Configure RDB

    # InitializeRuntimeData
    #
    # Clears the RDB, inserts the schema, and loads initial data:
    # 
    # * Blank map
    # * Concern definitions

    proc InitializeRuntimeData {} {
        # FIRST, clear the RDB
        rdb clear

        # NEXT, define the temp schema
        DefineTempSchema

        # NEXT, load the blank map
        map load [file join $::app_sim::library blank.png]

        # NEXT, insert the concern definitions
        foreach {c longname gtype} {
            AUT "Autonomy"        CIV
            SFT "Physical Safety" CIV
            CUL "Culture"         CIV
            QOL "Quality of Life" CIV
            CAS "Casualties"      ORG
        } {
            rdb eval {
                INSERT INTO concerns(c,longname,gtype)
                VALUES($c,$longname,$gtype)
            }
        }

        # NEXT, mark it saved; having the blank map is neither 
        # here nor there.
        rdb marksaved
    }

    # DefineTempSchema
    #
    # Adds the temporary schema definitions into the RDB

    proc DefineTempSchema {} {
        # FIRST, define SQL functions
        rdb function m2ref [myproc M2Ref]

        # NEXT, define the GUI Views
        rdb eval [readfile [file join $::app_sim::library gui_views.sql]]
    }


    #-------------------------------------------------------------------
    # SQL Functions

    # M2Ref args
    #
    # args    map coordinates of one or more points as a flat list
    #
    # Returns a list of one or more map reference strings corrresponding
    # to the coords

    proc M2Ref {args} {
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        map m2ref {*}$args
    }



    #-------------------------------------------------------------------
    # Registration of saveable objects

    # register saveable
    #
    # saveable     A saveable(i) command or command prefix
    #
    # Registers the saveable(i); its data will be included in 
    # the scenario and restored as appropriate.

    typemethod register {saveable} {
        if {$saveable ni $info(saveables)} {
            lappend info(saveables) $saveable
        }
    }

    # SaveSaveables
    #
    # Save all saveable data to the checkpoint table

    typemethod SaveSaveables {} {
        foreach saveable $info(saveables) {
            set checkpoint [{*}$saveable checkpoint]

            rdb eval {
                INSERT OR REPLACE 
                INTO checkpoint(saveable,checkpoint)
                VALUES($saveable,$checkpoint)
            }
        }
    }

    # RestoreSaveables
    #
    # Restore all saveable data from the checkpoint table

    typemethod RestoreSaveables {} {
        rdb eval {
            SELECT saveable,checkpoint FROM checkpoint
        } {
            if {$saveable in $info(saveables)} {
                {*}$saveable restore $checkpoint
            } else {
                log warning scenario \
                    "Unknown saveable found in checkpoint: \"$saveable\""
            }
        }
    }

}








