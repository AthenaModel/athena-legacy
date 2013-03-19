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

    # scenarioTables
    #
    # A list of the tables that are part of the scenario proper.
    # All other (non-sqlite) tables will be purged as part of 
    # doing a [scenario rebase].

    typevariable scenarioTables {
        activity
        activity_gtype
        actors
        bookmarks
        cap_kg
        cap_kn
        caps
        cif
        civgroups
        concerns
        cond_collections
        conditions
        coop_fg
        drivers
        econ_n
        ensits_t
        eventq_etype_ensitAutoResolve
        eventq_queue
        frcgroups
        goals
        groups
        hook_topics
        hooks
        hrel_fg
        ioms
        mads_t
        mam_affinity
        mam_belief
        mam_entity
        mam_playbox
        mam_topic
        mam_undo
        maps
        nbhoods
        nbrel_mn
        orggroups
        payloads
        sat_gc
        scenario
        situations
        tactics
        undostack_stack
        vrel_ga
    }

    # nonSnapshotTables
    #
    # A list of the tables that are excluded from snapshots.
    #
    # WARNING: The excluded tables should not define foreign key
    # constraints with cascading deletes on non-excluded tables.
    # On import, all tables in the exported data will be cleared
    # before being re-populated, and cascading deletes would
    # depopulated the excluded tables.

    typevariable nonSnapshotTables {
        snapshots
        maps
        bookmarks
        hist_control
        hist_coop
        hist_econ
        hist_econ_i
        hist_econ_ij
        hist_hrel
        hist_mood
        hist_nbcoop
        hist_nbmood
        hist_sat
        hist_security
        hist_support
        hist_volatility
        hist_vrel
        reports
        rule_firings
        rule_inputs
        sigevents
        sigevent_tags
        ucurve_adjustments_t
        ucurve_contribs_t
        ucurve_effects_t
        uram_civrel_t
        uram_frcrel_t
    }

    # Info Array: most scalars are stored here
    #
    # dbfile              Name of the current scenario file
    # saveable            List of saveables.

    typevariable info -array {
        dbfile             ""
        saveables          {}
    }

    #-------------------------------------------------------------------
    # Singleton Initializer

    # init
    #
    # Initializes the scenario RDB.

    typemethod init {} {
        log normal scenario "init"

        # FIRST, create a clean working RDB.
        scenariodb ::rdb \
            -clock      ::simclock \
            -explaincmd [mytypemethod ExplainCmd]
        set rdb ::rdb

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

    # ExplainCmd query explanation
    #
    # query       - An sql query
    # explanation -  Result of calling EXPLAIN QUERY PLAN on the query.
    #
    # Logs the query and its explanation.

    typemethod ExplainCmd {query explanation} {
        log normal rdb "EXPLAIN QUERY PLAN {$query}\n---\n$explanation"
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

        # NEXT, get the tick
        if {$opt eq "-prep"} {
            assert {[sim now] == [simclock cget -tick0]}
            set tick -1
        } else {
            set tick [sim now]
        }

        # NEXT, get the snapshot text
        set snapshot [GrabAllBut $nonSnapshotTables]

        # NEXT, save it into the RDB
        rdb eval {
            INSERT OR REPLACE INTO snapshots(tick,snapshot)
            VALUES($tick,$snapshot)
        }

        log normal scenario "snapshot saved: [string length $snapshot] bytes"
    }

    # GrabAllBut exclude
    #
    # exclude  - Names of tables to exclude from the snapshot.
    #
    # Grabs all but the named tables.

    proc GrabAllBut {exclude} {
        # FIRST, Get the list of tables to include
        set tables [list]

        rdb eval {
            SELECT name FROM sqlite_master WHERE type='table'
        } {
            if {$name ni $exclude} {
                lappend tables $name
            }
        }

        # NEXT, export each of the required tables.
        set snapshot [list]

        foreach name $tables {
            lassign [rdb grab $name {}] grabbedName content

            # grab returns the empty list if there was nothing to
            # grab; we want to have the table name present with
            # an empty content string, indicated that the table
            # should be empty.  Adds the INSERT tag, so that
            # ungrab will do the right thing.
            lappend snapshot [list $name INSERT] $content
        }

        # NEXT, return the document
        return $snapshot
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
        log normal scenario \
            "Loading snapshot for tick $tick: [string length $snapshot] bytes"

        rdb transaction {
            # NEXT, clear the tables being loaded.
            foreach {tableSpec content} $snapshot {
                lassign $tableSpec table tag
                rdb eval "DELETE FROM $table;"
            }

            # NEXT, import the tables
            rdb ungrab $snapshot
        }

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
            DELETE FROM rule_firings WHERE t > $t;
            DELETE FROM rule_inputs WHERE t > $t;
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
    # Save current simulation state as new baseline scenario.
    
    typemethod rebase {} {
        # FIRST, allow all modules to rebase.
        rebase save
        
        # NEXT, purge history.  (Do this second, in case the modules
        # needed the history to do their work.)
        scenario snapshot purge -unlock
        sigevent purge 0

        # NEXT, update the clock
        simclock configure -tick0 [simclock now]

        # NEXT, reinitialize modules that depend on the time.

        aram clear

        # NEXT, purge simulation tables
        foreach table [rdb tables] {
            if {$table ni $scenarioTables} {
                rdb eval "DELETE FROM $table"
            } 
        }
        
        # NEXT, this is a new scenario; it has no name.
        set info(dbfile) ""
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

        # NEXT, Reset the model parameters to their defaults, and
        # mark them saved.
        parm reset

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
        rdb function locked               [myproc Locked]
        rdb function m2ref                [myproc M2Ref]
        rdb function qsecurity            ::projectlib::qsecurity
        rdb function moneyfmt             ::marsutil::moneyfmt
        rdb function mklinks              [list ::sigevent mklinks]
        rdb function uram_gamma           [myproc UramGamma]

        # NEXT, define the GUI Views
        RdbEvalFile gui_scenario.sql    ;# Scenario Entities
        RdbEvalFile gui_attitude.sql    ;# Attitude Area
        RdbEvalFile gui_econ.sql        ;# Economics Area
        RdbEvalFile gui_ground.sql      ;# Ground Area
        RdbEvalFile gui_info.sql        ;# Information Area
        RdbEvalFile gui_politics.sql    ;# Politics Area
        RdbEvalFile gui_application.sql ;# Application Views

        # NEXT, define tactic and condition type views
        rdb eval [tactic tempschema]
        rdb eval [condition tempschema]

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

    # Locked
    #
    # Returns 1 if the scenario is locked, and 0 otherwise.

    proc Locked {} {
        expr {[sim state] ne "PREP"}
    }

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
