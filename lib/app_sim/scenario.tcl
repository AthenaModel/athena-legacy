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
    # Look-up Tables

    # Dictionary by table of RDB initialization dicts
    #
    # TBD: Consider reading these lists from registered modules.

    typevariable rdbInitializers {
        concerns {
            { c AUT longname "Autonomy"        gtype CIV }
            { c SFT longname "Physical Safety" gtype CIV }
            { c CUL longname "Culture"         gtype CIV }
            { c QOL longname "Quality of Life" gtype CIV }
            { c CAS longname "Casualties"      gtype ORG }
        }

        activity {
            { a NONE                 longname "None"                       }
            { a CHECKPOINT           longname "Checkpoint/Control Point"   }
            { a CMO_CONSTRUCTION     longname "CMO -- Construction"        }
            { a CMO_DEVELOPMENT      longname "CMO -- Development (Light)" }
            { a CMO_EDUCATION        longname "CMO -- Education"           }
            { a CMO_EMPLOYMENT       longname "CMO -- Employment"          }
            { a CMO_HEALTHCARE       longname "CMO -- Healthcare"          }
            { a CMO_INDUSTRY         longname "CMO -- Industry"            }
            { a CMO_INFRASTRUCTURE   longname "CMO -- Infrastructure"      }
            { a CMO_LAW_ENFORCEMENT  longname "CMO -- Law Enforcement"     }
            { a CMO_OTHER            longname "CMO -- Other"               }
            { a COERCION             longname "Coercion"                   }
            { a CRIMINAL_ACTIVITIES  longname "Criminal Activities"        }
            { a CURFEW               longname "Curfew"                     }
            { a GUARD                longname "Guard"                      }
            { a PATROL               longname "Patrol"                     }
            { a PRESENCE             longname "Presence"                   }
            { a PSYOP                longname "PSYOP"                      }
        }

        activity_gtype {
            { a NONE                 gtype FRC assignable 1 stype {}       }
            { a CHECKPOINT           gtype FRC assignable 1 stype CHKPOINT }
            { a CMO_CONSTRUCTION     gtype FRC assignable 1 stype CMOCONST }
            { a CMO_DEVELOPMENT      gtype FRC assignable 1 stype CMODEV   }
            { a CMO_EDUCATION        gtype FRC assignable 1 stype CMOEDU   }
            { a CMO_EMPLOYMENT       gtype FRC assignable 1 stype CMOEMP   }
            { a CMO_HEALTHCARE       gtype FRC assignable 1 stype CMOMED   }
            { a CMO_INDUSTRY         gtype FRC assignable 1 stype CMOIND   }
            { a CMO_INFRASTRUCTURE   gtype FRC assignable 1 stype CMOINF   }
            { a CMO_LAW_ENFORCEMENT  gtype FRC assignable 1 stype CMOLAW   }
            { a CMO_OTHER            gtype FRC assignable 1 stype CMOOTHER }
            { a COERCION             gtype FRC assignable 1 stype COERCION }
            { a CRIMINAL_ACTIVITIES  gtype FRC assignable 1 stype CRIMINAL }
            { a CURFEW               gtype FRC assignable 1 stype CURFEW   }
            { a GUARD                gtype FRC assignable 1 stype GUARD    }
            { a PATROL               gtype FRC assignable 1 stype PATROL   }
            { a PRESENCE             gtype FRC assignable 0 stype PRESENCE }
            { a PSYOP                gtype FRC assignable 1 stype PSYOP    }
            
            { a NONE                 gtype ORG assignable 1 stype {}       }
            { a CMO_CONSTRUCTION     gtype ORG assignable 1 stype ORGCONST }
            { a CMO_EDUCATION        gtype ORG assignable 1 stype ORGEDU   }
            { a CMO_EMPLOYMENT       gtype ORG assignable 1 stype ORGEMP   }
            { a CMO_HEALTHCARE       gtype ORG assignable 1 stype ORGMED   }
            { a CMO_INDUSTRY         gtype ORG assignable 1 stype ORGIND   }
            { a CMO_INFRASTRUCTURE   gtype ORG assignable 1 stype ORGINF   }
            { a CMO_OTHER            gtype ORG assignable 1 stype ORGOTHER }
        }
    }
    
    #-------------------------------------------------------------------
    # Type Components

    typecomponent rdb                ;# The scenario RDB

    #-------------------------------------------------------------------
    # Type Variables

    # Info Array: most scalars are stored here
    #
    # dbfile              Name of the current scenario file
    # saveable            List of saveables.
    # ignoreDefaultParms  If yes, won't load defaults.parmdb when 
    #                     creating a new scenario.

    typevariable info -array {
        dbfile             ""
        saveables          {}
        ignoreDefaultParms no
    }

    #-------------------------------------------------------------------
    # Singleton Initializer

    # init ?-ignoredefaultparms flag?
    #
    # Initializes the scenario RDB.

    typemethod init {args} {
        # FIRST, process options
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -ignoredefaultparms { 
                    set info(ignoreDefaultParms) [lshift args]
                }

                default { 
                    error "Unknown option \"$opt\""  
                }
            }
        }

        # NEXT, create the a clean working RDB.
        set rdb [scenariodb ::rdb \
                    -clock ::marsutil::simclock]

        InitializeRuntimeData
    }

    #-------------------------------------------------------------------
    # Scenario Management Methods

    # new
    #
    # Creates a new, blank scenario.

    typemethod new {} {
        assert {[sim state] ne "RUNNING"}

        # FIRST, Create a blank scenario
        $type MakeBlankScenario

        # NEXT, log it.
        log newlog new
        log normal scenario "New Scenario: Untitled"
        
        app puts "New scenario created"
    }

    # MakeBlankScenario
    #
    # Creates a new, blank, scenario.  This is used on 
    # "scenario new", and when "scenario open" tries and fails.

    typemethod MakeBlankScenario {} {
        # FIRST, initialize the runtime data
        InitializeRuntimeData

        # NEXT, there is no dbfile.
        set info(dbfile) ""

        # NEXT, Restart the simulation.  This also reconfigures
        # the app.
        sim new
    }

    # open filename
    #
    # filename       An .adb scenario file
    #
    # Opens the specified file name, replacing the existing file.

    typemethod open {filename} {
        assert {[sim state] ne "RUNNING"}

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

            $type MakeBlankScenario
            return
        }

        # NEXT, define the temporary schema definitions
        DefineTempSchema

        # NEXT, restore the saveables
        $type RestoreSaveables -saved

        # NEXT, save the name.
        set info(dbfile) $filename

        # NEXT, log it.
        log newlog open
        log normal scenario "Open Scenario: $filename"

        app puts "Opened Scenario [file tail $filename]"

        # NEXT, Reconfigure the app
        sim reconfigure
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
        $type SaveSaveables -saved

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
    # Snapshot Management

    # snapshot save
    #
    # Saves a snapshot as of the current sim time.  The snapshot is
    # an XML string of everything but the "maps" and "snapshots" tables.
    # The "maps" are excluded because of the size, and the "snapshots"
    # are excluded for obvious reasons.

    typemethod {snapshot save} {} {
        # FIRST, save the saveables
        $type SaveSaveables

        # NEXT, get the snapshot text
        set snapshot [rdb export -exclude {snapshots maps}]

        # NEXT, save it into the RDB
        set tick [sim now]

        rdb eval {
            INSERT OR REPLACE INTO snapshots(tick,snapshot)
            VALUES($tick,$snapshot)
        }

        log normal scenario "snapshot saved"
    }


    # snapshot load tick
    #
    # tick     The tick of the snapshot to load
    #
    # Loads the specified snapshot, and reconfigures the sim.

    typemethod {snapshot load} {tick} {
        require {$tick in [scenario snapshot list]} \
            "No snapshot at tick $tick"

        # FIRST, get the snapshot
        set snapshot [rdb onecolumn {
            SELECT snapshot FROM snapshots 
            WHERE tick=$tick
        }]

        # NEXT, import it.
        log normal scenario "Loading snapshot for tick $tick"
        rdb import $snapshot -logcmd [list log detail scenario]

        # NEXT, restore the saveables
        $type RestoreSaveables
        
        # NEXT, Reconfigure the app
        sim reconfigure
    }


    # snapshot list
    #
    # Returns a list of the ticks for which snapshots are available.

    typemethod {snapshot list} {} {
        rdb eval {
            SELECT tick FROM snapshots
            ORDER BY tick
        }
    }

    
    # snapshot purge t
    #
    # t     A sim time in ticks
    #
    # Purges all snapshots with ticks greater than or equal to t

    typemethod {snapshot purge} {t} {
        rdb eval {
            DELETE FROM snapshots WHERE tick >= $t;
        }
    }

    # snapshot current
    #
    # Returns the index of the current snapshot, or -1 if we're
    # not on a snapshot.

    typemethod {snapshot current} {} {
        # TBD: Consider storing the index in the RDB.
        lsearch -exact [scenario snapshot list] [simclock now]
    }

    # snapshot latest
    #
    # Returns the tick of the latest snapshot.

    typemethod {snapshot latest} {} {
        lindex [scenario snapshot list] end
    }

    #-------------------------------------------------------------------
    # Scenario Reconciliation

    # mutate reconcile
    #
    # This routine aggregates the various "mutate reconcile" routines,
    # returning the accumulated undo script, so that order handlers
    # don't need to be aware of which other modules require reconciliation.

    typemethod {mutate reconcile} {} {
        set undo [list]

        lappend undo [nbrel   mutate reconcile]
        lappend undo [nbgroup mutate reconcile]
        lappend undo [sat     mutate reconcile]
        lappend undo [rel     mutate reconcile]
        lappend undo [coop    mutate reconcile]
        lappend undo [unit    mutate reconcile]
        lappend undo [envsit  mutate reconcile]

        notifier send $type <Reconcile>

        return [join $undo \n]
    }

    #-------------------------------------------------------------------
    # Configure RDB

    # InitializeRuntimeData
    #
    # Clears the RDB, inserts the schema, and loads initial data:
    # 
    # * Blank map
    # * Concern definitions
    # * Activity definitions

    proc InitializeRuntimeData {} {
        # FIRST, create and clear the RDB
        if {[rdb isopen]} {
            rdb close
        }

        set rdbfile [workdir join rdb working.rdb]
        file delete -force $rdbfile
        rdb open $rdbfile
        rdb clear

        # NEXT, define the temp schema
        DefineTempSchema

        # NEXT, load the blank map
        map load [file join $::app_sim::library blank.png]

        # NEXT, insert the standard tables
        scenario InsertStandardTables

        # NEXT, if there's a default parameter file, load it; and
        # mark the parameters saved.

        if {$info(ignoreDefaultParms)} {
            parm reset
        } else {
            parm defaults load
        }

        parm checkpoint -saved

        # NEXT, mark it saved; there's no reason to save a scenario
        # that has only these things in it.
        rdb marksaved
    }

    # InsertStandardTables
    #
    # Inserts the standard tables into the RDB, erasing previous
    # entries in those tables.

    typemethod InsertStandardTables {} {
        dict for {table rows} $rdbInitializers {
            rdb eval "DELETE FROM $table;"

            foreach row $rows {
                rdb insert $table $row
            }
        }
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

    # SaveSaveables ?-saved?
    #
    # Save all saveable data to the checkpoint table, optionally
    # clearing the "changed" flag for all of the saveables.

    typemethod SaveSaveables {{option ""}} {
        foreach saveable $info(saveables) {
            # Forget and skip saveables that no longer exist
            if {[llength [info commands [lindex $saveable 0]]] == 0} {
                ldelete info(saveables) $saveable
                continue
            }

            set checkpoint [{*}$saveable checkpoint $option]

            rdb eval {
                INSERT OR REPLACE 
                INTO saveables(saveable,checkpoint)
                VALUES($saveable,$checkpoint)
            }
        }
    }

    # RestoreSaveables ?-saved?
    #
    # Restore all saveable data from the checkpoint table, optionally
    # clearing the "changed" flag for all of the saveables.

    typemethod RestoreSaveables {{option ""}} {
        rdb eval {
            SELECT saveable,checkpoint FROM saveables
        } {
            if {[llength [info commands [lindex $saveable 0]]] != 0} {
                {*}$saveable restore $checkpoint $option
            } else {
                log warning scenario \
                    "Unknown saveable found in checkpoint: \"$saveable\""
            }
        }
    }
}








