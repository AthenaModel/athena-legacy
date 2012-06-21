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
        log normal scenario "init"

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

        # NEXT, create a clean working RDB.
        set rdb [scenariodb ::rdb \
                    -clock ::marsutil::simclock]
        rdb register ::dam
        rdb register ::service

        # NEXT, monitor tables. 
        rdb monitor add actors        {a}
        rdb monitor add attroe_nfg    {n f g}
        rdb monitor add bookmarks     {bookmark_id}
        rdb monitor add caps          {k}
        rdb monitor add cap_kn        {k n}
        rdb monitor add cap_kg        {k g}
        rdb monitor add civgroups     {g}
        rdb monitor add conditions    {condition_id}
        rdb monitor add coop_fg       {f g}
        rdb monitor add defroe_ng     {n g}
        rdb monitor add deploy_ng     {n g}
        rdb monitor add drivers       {driver_id}
        rdb monitor add econ_n        {n}
        rdb monitor add ensits_t      {s}
        rdb monitor add frcgroups     {g}
        rdb monitor add goals         {goal_id}
        rdb monitor add groups        {g}
        rdb monitor add hooks         {hook_id}
        rdb monitor add hook_topics   {hook_id topic_id}
        rdb monitor add hrel_fg       {f g}
        rdb monitor add ioms          {iom_id}
        rdb monitor add mads_t        {driver_id}
        rdb monitor add magic_attrit  {id}
        rdb monitor add mam_playbox   {pid}
        rdb monitor add mam_belief    {eid tid}
        rdb monitor add mam_entity    {eid}
        rdb monitor add mam_topic     {tid}
        rdb monitor add nbhoods       {n}
        rdb monitor add nbrel_mn      {m n}
        rdb monitor add orggroups     {g}
        rdb monitor add payloads      {iom_id payload_num}
        rdb monitor add sat_gc        {g c}
        rdb monitor add situations    {s}
        rdb monitor add tactics       {tactic_id}
        rdb monitor add units         {u}
        rdb monitor add vrel_ga       {g a}

        InitializeRuntimeData

        log normal scenario "init complete"
    }

    #-------------------------------------------------------------------
    # Scenario Management Methods

    # new
    #
    # Creates a new, blank scenario.

    typemethod new {} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, unlock the scenario if it is locked; this
        # will reinitialize modules like URAM.
        if {[sim state] ne "PREP"} {
            sim mutate unlock
        }

        # NEXT, Create a blank scenario
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

        # NEXT, Restart the simulation.  This also resyncs the app
        # with the RDB.
        sim new
    }

    # open filename
    #
    # filename       An .adb scenario file
    #
    # Opens the specified file name, replacing the existing file.

    typemethod open {filename} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, which kind of file is it?
        set ftype [file extension $filename]

        # FIRST, load the file.
        if {[catch {
            rdb load $filename
        } result]} {
            $type MakeBlankScenario

            app error {
                |<--
                Could not open scenario
                
                    $filename

                $result
            }

            return
        }

        $type FinishOpeningScenario $filename

        return
    }

    # FinishOpeningScenario filename
    #
    # filename       Name of the file being opened.
    #
    # Once the data has been loaded into the RDB, this routine
    # completes the process.

    typemethod FinishOpeningScenario {filename} {
        # FIRST, set the current working directory to the scenario
        # file location.
        catch {cd [file dirname [file normalize $filename]]}

        # NEXT, define the temporary schema definitions
        DefineTempSchema

        # NEXT, restore the saveables
        $type RestoreSaveables -saved

        # NEXT, An Egregiously Ugly Hack.  In Bug 2399, eventq
        # was modified so that the initial time was -1, allowing
        # events to be scheduled at time 0.  But older scenario files
        # have it checkpointed as 0.  If the scenario is in
        # the PREP state, this hack puts the eventq time to -1.

        if {[sim state] eq "PREP"} {
            set ::marsutil::eventq::info(time) -1
        }

        # NEXT, save the name.
        set info(dbfile) $filename

        # NEXT, log it.
        log newlog open
        log normal scenario "Open Scenario: $filename"

        app puts "Opened Scenario [file tail $filename]"

        # NEXT, Resync the app with the RDB.
        sim dbsync
    }

    # save ?filename?
    #
    # filename       Name for the new save file
    #
    # Saves the file, notify the application on success.  If no
    # file name is specified, the dbfile is used.  Returns 1 if
    # the save is successful and 0 otherwise.

    typemethod save {{filename ""}} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, if filename is not specified, get the dbfile
        if {$filename eq ""} {
            if {$info(dbfile) eq ""} {
                error "Cannot save: no file name"
            }

            set dbfile $info(dbfile)
        } else {
            set dbfile $filename
        }

        # NEXT, make sure it has a .adb extension.
        if {[file extension $dbfile] ne ".adb"} {
            append dbfile ".adb"
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

        # NEXT, set the current working directory to the scenario
        # file location.
        catch {cd [file dirname [file normalize $filename]]}

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

    # snapshot save ?-prep?
    #
    # Saves a snapshot as of the current sim time.  The snapshot is
    # a Tcl string of everything but "maps" and "snapshots" tables.
    # The "maps" are excluded because of the size, and the "snapshots"
    # are excluded for obvious reasons.
    #
    # In addition, exclude the URAM influence and history tables.
    # The URAM influence tables never change after time 0 (for now,
    # anyway) and the URAM history table entries never change after they
    # are written.  We can leave them in place, and truncate the tables
    # if we re-enter the time-stream.
    #
    # Finally, the bookmarks table is excluded; bookmarks do not affect
    # the simulation, and can be edited at any time.
    #
    # If the -prep flag is given, then the snapshot is saved for
    # time "-1", indicating that it's a PREP-state snapshot.

    typemethod {snapshot save} {{opt -now}} {
        # FIRST, save the saveables
        $type SaveSaveables

        # NEXT, get the snapshot text
        #
        # WARNING: The excluded tables should not define foreign key 
        # constraints with cascading deletes on non-excluded tables.
        # On import, all tables in the exported data will be cleared 
        # before being re-populated, and cascading deletes would 
        # depopulated the excluded tables.

        set snapshot [rdb tclexport -exclude {
            snapshots 
            maps 
            bookmarks
            hist_control
            hist_coop
            hist_econ
            hist_econ_ij
            hist_mood
            hist_nbcoop
            hist_nbmood
            hist_sat
            hist_security
            hist_support
            hist_volatility
            hist_vrel
            sigevents
            sigevent_tags
            ucurve_contribs_t
            uram_civrel_t
            uram_frcrel_t
        }]

        log detail scenario "Snapshot size=[string length $snapshot]"

        # NEXT, save it into the RDB
        if {$opt eq "-prep"} {
            assert {[sim now] == 0}
            set tick -1
        } else {
            set tick [sim now]
        }

        rdb eval {
            INSERT OR REPLACE INTO snapshots(tick,snapshot)
            VALUES($tick,$snapshot)
        }

        log normal scenario "snapshot saved"
    }


    # snapshot load tick
    #
    # tick     The tick of the snapshot to load, or -prep.
    #
    # Loads the specified snapshot.  The caller should
    # dbsync the sim.

    typemethod {snapshot load} {tick} {
        require {$tick eq "-prep" || $tick in [scenario snapshot list]} \
            "No snapshot at tick $tick"

        # FIRST, get the snapshot
        if {$tick eq "-prep"} {
            set t -1
        } else {
            set t $tick
        }

        set snapshot [rdb onecolumn {
            SELECT snapshot FROM snapshots 
            WHERE tick=$t
        }]

        # NEXT, import it.
        log normal scenario "Loading snapshot for tick $tick"
        rdb tclimport $snapshot

        # NEXT, restore the saveables
        $type RestoreSaveables
    }


    # snapshot list
    #
    # Returns a list of the ticks for which snapshots are available.
    # Skip the -prep snapshot.

    typemethod {snapshot list} {} {
        rdb eval {
            SELECT tick FROM snapshots
            WHERE tick >= 0
            ORDER BY tick
        }
    }

    
    # snapshot purge t
    #
    # t     A sim time in ticks, or "-unlock"
    #
    # Purges all snapshots with ticks greater than or equal to t,
    # and all history with ticks greater than t.  If t is "unlock",
    # then we're returning to PREP and all non-PREP data is purge.

    typemethod {snapshot purge} {t} {
        if {$t ne "-unlock"} {
            set hist_t $t
        } else {
            set t      0
            set hist_t -1
        }

        rdb eval {
            DELETE FROM snapshots WHERE tick >= $t;
            DELETE FROM ucurve_contribs_t WHERE t > $t;
        }

        hist purge $hist_t
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
    # Configure RDB

    # InitializeRuntimeData
    #
    # Clears the RDB, inserts the schema, and loads initial data:
    # 
    # * Blank map

    proc InitializeRuntimeData {} {
        # FIRST, create and clear the RDB
        if {[rdb isopen]} {
            rdb close
        }

        set rdbfile [workdir join rdb working.rdb]
        file delete -force $rdbfile
        rdb open $rdbfile
        rdb clear

        # NEXT, enable write-ahead logging on the RDB
        rdb eval { PRAGMA journal_mode = WAL; }

        # NEXT, define the temp schema
        DefineTempSchema

        # NEXT, load the blank map
        map load [file join $::app_sim::library blank.png]

        # NEXT, create the "Adjustments" MAD.
        mad mutate create {
            narrative "Adjustments" 
            cause     UNIQUE
            s         1.0
            p         0.0
            q         0.0
        }

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

    # DefineTempSchema
    #
    # Adds the temporary schema definitions into the RDB

    proc DefineTempSchema {} {
        # FIRST, define SQL functions
        # TBD: qsecurity should be added to scenariodb(n).
        # TBD: moneyfmt should be added to sqldocument(n).
        rdb function m2ref                [myproc M2Ref]
        rdb function qsecurity            ::projectlib::qsecurity
        rdb function moneyfmt             ::marsutil::moneyfmt
        rdb function mklinks              [list ::sigevent mklinks]
        rdb function uram_gamma           [myproc UramGamma]

        # NEXT, define the GUI Views
        RdbEvalFile gui_scenario.sql    ;# Scenario Entities
        RdbEvalFile gui_attitude.sql    ;# Attitude Area
        RdbEvalFile gui_demog.sql       ;# Demographics Area
        RdbEvalFile gui_econ.sql        ;# Economics Area
        RdbEvalFile gui_ground.sql      ;# Ground Area
        RdbEvalFile gui_info.sql        ;# Information Area
        RdbEvalFile gui_politics.sql    ;# Politics Area
        RdbEvalFile gui_application.sql ;# Application Views

        # NEXT, define tactic and condition type views
        set sql ""
        set once 0
        set on_lock 0

        foreach ttype [tactic type names] {
            set parms [tactic type parms $ttype]

            # NEXT, look for optional flags in tactic type specific parms.
            # Need to replace the flags with user-friendly text
            if {"on_lock" in $parms} {
                set on_lock 1
                ldelete parms on_lock
            }

            if {"once" in $parms} {
                set once 1
                ldelete parms once
            }

            # NEXT, set the two parmlists identical, one for each type of view.
            # parmlist2 may change
            set parmlist1 [join $parms ", "]
            set parmlist2 [join $parms ", "]

            # NEXT, if "on_lock" is present set up the user-friendly SQL in 
            # parmlist2
            if {$on_lock} {
                append parmlist2 \
                    ", CASE on_lock WHEN 1 THEN 'YES' ELSE 'NO' END AS on_lock"
                # NEXT, "once" should always appear when "on_lock" appears, but
                # do not want to assume that
                if {$once} {
                    append parmlist2 \
                        ", CASE once WHEN 1 THEN 'YES' ELSE 'NO' END AS once"
                } 
            } elseif {$once} {
                # NEXT, the "once" flag is present, convert to user-friendly
                # SQL
                append parmlist2 \
                    ", CASE once WHEN 1 THEN 'YES' ELSE 'NO' END AS once"
            }

            # NEXT, create the two views. The order dialogs that use these
            # will need to chose which one is appropriate, but both are
            # available
            append sql "
                CREATE VIEW tactics_$ttype AS
                SELECT tactic_id, tactic_type, owner, narrative, priority,
                       state, exec_ts, exec_flag, $parmlist1
                FROM tactics WHERE tactic_type='$ttype';

                CREATE VIEW gui_tactics_$ttype AS
                SELECT tactic_id, tactic_type, owner, narrative, priority,
                       state, exec_ts, exec_flag, 
                       $parmlist2
                FROM tactics WHERE tactic_type='$ttype';
            "
        }

        foreach ctype [condition type names] {
            set parms [join [condition type parms $ctype] ", "]

            append sql "
                CREATE VIEW conditions_$ctype AS
                SELECT condition_id, condition_type, cc_id, narrative,
                       state, flag, $parms
                FROM conditions WHERE condition_type='$ctype';
            "
        }
        

        rdb eval $sql
    }

    # RdbEvalFile filename
    #
    # filename   - An SQL file
    #
    # Reads the file from the application library directory and
    # passes it to the RDB for evaluation.

    proc RdbEvalFile {filename} {
        rdb eval [readfile [file join $::app_sim::library $filename]]
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

    # UramGamma ctype
    #
    # ctype - A URAM curve type: HREL, VREL, COOP, AUT, CUL, QOL.
    #
    # Returns the "gamma" parameter for curves of that type from
    # parmdb(5).
    
    proc UramGamma {ctype} {
        # The [expr] converts it to a number.
        return [expr [lindex [parm get uram.factors.$ctype] 1]]
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











