#-----------------------------------------------------------------------
# TITLE:
#    sim.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Simulation Ensemble
#
#    This module manages the overall simulation, as distinct from the 
#    the purely scenario-data oriented work done by sim(sim).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# sim ensemble

snit::type sim {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent ticker    ;# The timeout(n) instance that makes the
                             # simulation go.

    #-------------------------------------------------------------------
    # Non-checkpointed Type Variables

    # constants -- scalar array
    #
    # ticksize  - The simclock tick size
    # startdata - The initial date of time 0
    # tickDelay - The delay between ticks
    
    typevariable constants -array {
        ticksize  {1 day}
        startdate 100000ZJAN10
        tickDelay 50
    }

    # info -- scalar info array
    #
    # changed        - 1 if saveable(i) data has changed, and 0 
    #                  otherwise.
    # state          - The current simulation state, a simstate value
    # stoptime       - The time tick at which the simulation should 
    #                  pause, or 0 if there's no limit.

    typevariable info -array {
        changed        0
        state          PREP
        stoptime       0
    }

    # trans -- transient data array
    #
    #  buffer  - Buffer used to build up long strings.

    typevariable trans -array {
        buffer {}
    }

    #-------------------------------------------------------------------
    # Singleton Initializer

    # init
    #
    # Initializes the simulation proper, to the extent that this can
    # be done at application initialization.  True initialization
    # happens when scenario preparation is locked, when 
    # the simulation state moves from PREP to PAUSED.

    typemethod init {} {
        log normal sim "init"

        # FIRST, register with scenario(sim) as a saveable
        scenario register $type

        # NEXT, set the simulation state
        set info(state)    PREP
        set info(changed)  0
        set info(stoptime) 0

        order state $info(state)

        # NEXT, configure the simclock.
        # TBD: The tick size and the start date should be parmdb parms.
        simclock configure              \
            -tick $constants(ticksize)  \
            -t0   $constants(startdate)

        # NEXT, create the ticker
        set ticker [timeout ${type}::ticker                \
                        -interval   $constants(tickDelay) \
                        -repetition yes                    \
                        -command    {profile sim Tick}]

        # NEXT, initialize the event queue
        eventq init ::rdb
        scenario register ::marsutil::eventq

        # NEXT, create ARAM and register it as a saveable
        gram ::aram \
            -clock        ::simclock              \
            -rdb          ::rdb                   \
            -logger       ::log                   \
            -logcomponent "aram"                  \
            -loadcmd      [mytypemethod LoadAram]

        scenario register ::aram

       # NEXT, initialize the simulation modules
        bsystem   init
        econ      init
        situation init


        log normal sim "init complete"
    }

    # LoadAram gram
    #
    # Loads scenario data into ARAM when it's initialized.

    typemethod LoadAram {gram} {
        $gram load nbhoods {*}[rdb eval {
            SELECT n FROM nbhoods
            ORDER BY n
        }]

        $gram load nbrel {*}[rdb eval {
            SELECT m, n, proximity, effects_delay 
            FROM nbrel_mn
            ORDER BY m,n
        }]

        $gram load civg {*}[rdb eval {
            SELECT g,n,basepop FROM civgroups_view
            ORDER BY g
        }]

        $gram load civrel {*}[rdb eval {
            SELECT R.f,
                   R.g,
                   R.rel
            FROM rel_view AS R
            JOIN civgroups AS F ON (F.g = R.f)
            JOIN civgroups as G on (G.g = R.g)
            ORDER BY R.f, R.g
        }]

        $gram load concerns {*}[rdb eval {
            SELECT c FROM concerns
            ORDER BY c
        }]

        $gram load sat {*}[rdb eval {
            SELECT g, c, sat0, saliency
            FROM sat_gc
            ORDER BY g, c
        }]

        $gram load frcg {*}[rdb eval {
            SELECT g FROM frcgroups
            ORDER BY g
        }]

        $gram load frcrel {*}[rdb eval {
            SELECT R.f,
                   R.g,
                   R.rel
            FROM rel_view AS R
            JOIN frcgroups AS F ON (F.g = R.f)
            JOIN frcgroups as G on (G.g = R.g)
            ORDER BY R.f, R.g
        }]

        $gram load coop {*}[rdb eval {
            SELECT f,
                   g,
                   coop0
            FROM coop_fg
            ORDER BY f, g
        }]
    }

    # new
    #
    # Reinitializes the module when a new scenario is created.

    typemethod new {} {
        # FIRST, configure the simclock.
        simclock reset
        simclock configure              \
            -tick $constants(ticksize)  \
            -t0   $constants(startdate)

        # NEXT, clear the event queue
        eventq restart

        # NEXT, clear the belief system
        bsystem clear

        # NEXT, set the simulation status
        set info(changed) 0
        set info(state)   PREP

        $type dbsync
    }

    # restart
    #
    # Reloads snapshot 0, and enters.

    typemethod restart {} {
        sim mutate unlock
    }

    #-------------------------------------------------------------------
    # Snapshot Navigation

    # snapshot first
    #
    # Loads the tick 0 snapshot, which resets the simulation as a 
    # whole to the moment before it first 
    # transitioned from PAUSED to RUNNING.

    typemethod {snapshot first} {} {
        $type LoadSnapshot 0

        return
    }


    # snapshot prev
    #
    # Loads the previous snapshot, if any.

    typemethod {snapshot prev} {} {
        # FIRST, get the tick of the previous snapshot
        set now [simclock now]

        foreach tick [lreverse [scenario snapshot list]] {
            if {$tick < $now} {
                break
            }
        }

        # NEXT, Load the snapshot
        $type LoadSnapshot $tick

        return
    }


    # snapshot next
    #
    # Loads the next snapshot, if any.

    typemethod {snapshot next} {} {
        # FIRST, get the tick of the next snapshot
        set now [simclock now]

        foreach tick [scenario snapshot list] {
            if {$tick > $now} {
                break
            }
        }

        assert {$tick > $now}

        # NEXT, Load the snapshot
        $type LoadSnapshot $tick

        return
    }


    # snapshot last
    #
    # Loads the latest snapshot.

    typemethod {snapshot last} {} {
        set tick [scenario snapshot latest]

        assert {[simclock now] < $tick}

        $type LoadSnapshot $tick

        return
    }

    # LoadSnapshot tick
    #
    # tick        The timestamp of the snapshot to load
    #
    # Loads the snapshot.  If the time now is later than 
    # the latest checkpoint, saves one so that we can return.

    typemethod LoadSnapshot {tick} {
        assert {[sim state] in {PAUSED SNAPSHOT}}

        # FIRST, if the time is greater than the last snapshot, 
        # save one.
        if {[simclock now] > [scenario snapshot latest]} {
            scenario snapshot save
        }

        # NEXT, restore to the tick 
        scenario snapshot load $tick

        # NEXT, PAUSED if we're at the 
        # last snapshot, and SNAPSHOT otherwise.
        if {$tick == [scenario snapshot latest]} {
            $type SetState PAUSED
            log newlog latest
        } else {
            $type SetState SNAPSHOT
            log newlog snapshot
        }

        # NEXT, log the change
        set message \
            "Loaded snapshot [scenario snapshot current] at [simclock asZulu] (tick [simclock now])"

        log normal sim $message
        app puts $message

        # NEXT, resync the app with the RDB
        $type dbsync

        return
    }

    # snapshot enter
    #
    # Re-enters the time-stream as of the current snapshot; purges
    # later snapshots.

    typemethod {snapshot enter} {} {
        # FIRST, must be in SNAPSHOT mode.
        assert {[sim state] eq "SNAPSHOT"}

        # NEXT, purge future snapshots
        set now [simclock now]
        scenario snapshot purge $now

        # NEXT, set state
        $type SetState PAUSED

        # NEXT, log it.
        log newlog latest
        
        set message \
       "Re-entered the timestream at [simclock asZulu] (tick [simclock now])"

        log normal sim $message
        app puts $message

        # NEXT, resync the app with the RDB
        $type dbsync
    }

    #-------------------------------------------------------------------
    # RDB Synchronization

    # dbsync
    #
    # Database synchronization occurs when the RDB changes out from under
    # the application, i.e., brand new scenario is created or
    # loaded.  All application modules must re-initialize themselves
    # at this time.
    #
    # * Non-GUI modules subscribe to the <DbSyncA> event.
    # * GUI modules subscribe to the <DbSyncB> event.
    #
    # This guarantees that the "model" is in a consistent state
    # before the "view" is updated.

    typemethod dbsync {} {
        # FIRST, Sync the simulation
        notifier send $type <DbSyncA>

        # NEXT, Sync the GUI
        notifier send $type <DbSyncB>
        notifier send $type <Time>
        notifier send $type <State>
    }

    #-------------------------------------------------------------------
    # Queries

    delegate typemethod now using {::simclock %m}

    # state
    #
    # Returns the current simulation state

    typemethod state {} {
        return $info(state)
    }

    # stoptime
    #
    # Returns the current stop time in ticks

    typemethod stoptime {} {
        return $info(stoptime)
    }


    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # the change cannot be undone, the mutator returns the empty string.


    # mutate startdate startdate
    #
    # startdate   The date of T0 as a zulu-time string
    #
    # Sets the simclock's -t0 start date

    typemethod {mutate startdate} {startdate} {
        set oldDate [simclock cget -t0]

        simclock configure -t0 $startdate

        # NEXT, saveable(i) data has changed
        set info(changed) 1

        # NEXT, notify the app
        notifier send $type <Time>

        # NEXT, set the undo command
        return [mytypemethod mutate startdate $oldDate]
    }

    # mutate lock
    #
    # Causes the simulation to transition from PREP to PAUSED in time 0.

    typemethod {mutate lock} {} {
        assert {$info(state) eq "PREP"}

        # FIRST, save a PREP checkpoint.
        scenario snapshot save -prep

        # NEXT, do initial analyses, and initialize modules that
        # begin to work at this time.
        aram     init -reload
        activity analyze staffing      ;# TBD: should be controlled by 
                                        # strategy.
        demog    analyze pop
        sat      start                 ;# TBD: check results (need trends)
        coop     start                 ;# TBD: check results (need trends)
        nbstat   start
        econ     start
        demog    analyze econ
        demsit   assess                ;# TBD
        mad      getdrivers
        control  start
        strategy tock

        # NEXT, execute events scheduled at time 0.
        eventq advance 0

        # NEXT, set the state to PAUSED
        $type SetState PAUSED

        # NEXT, resync the GUI, since much has changed.
        notifier send $type <DbSyncB>

        # NEXT, return "", as this can't be undone.
        return ""
    }

    # mutate unlock
    #
    # Causes the simulation to transition from PAUSED or SNAPSHOT
    # to PREP.

    typemethod {mutate unlock} {} {
        assert {$info(state) in {PAUSED SNAPSHOT}}

        # FIRST, load the PREP snapshot
        scenario snapshot load -prep

        # NEXT, purge future snapshots
        scenario snapshot purge 0

        # NEXT, set state
        $type SetState PREP

        # NEXT, log it.
        log newlog prep
        log normal sim "Unlocked Scenario Preparation"

        # NEXT, resync the sim with the RDB
        $type dbsync

        # NEXT, return "", as this can't be undone.
        return ""
    }

    # mutate run ?options...?
    #
    # -ticks ticks       Run until now + ticks
    # -until tick        Run until tick
    # -block flag        If true, block until run completed.
    #
    # Causes the simulation to run time forward until the specified
    # time, or until "mutate pause" is called.
    #
    # Time proceeds by ticks.  Normally, each tick is run in the 
    # context of the Tcl event loop, as controlled by a timeout(n) 
    # object called "ticker".  The timeout interval is called the 
    # inter-tick delay; it determines how fast the simulation runs.
    # If -block is specified, then this routine runs time forward
    # until the stoptime, and then returns.  Thus, -block requires
    # -ticks or -until.

    typemethod {mutate run} {args} {
        assert {$info(state) eq "PAUSED"}

        # FIRST, get the pause time
        set info(stoptime) 0
        set blocking 0

        while {[llength $args] > 0} {
            set opt [lshift args]
            
            switch -exact -- $opt {
                -ticks {
                    set val [lshift args]

                    set info(stoptime) [expr {[simclock now] + $val}]
                }

                -until {
                    set info(stoptime) [lshift args]
                }

                -block {
                    set blocking [lshift args]
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # The SIM:RUN order should have guaranteed this, but let's
        # check it to make sure.
        assert {$info(stoptime) == 0 || $info(stoptime) > [simclock now]}
        assert {!$blocking || $info(stoptime) != 0}

        # NEXT, save a snapshot, purging any later snapshots.
        scenario snapshot purge [simclock now]
        scenario snapshot save

        # NEXT, set the state to running.  This will initialize the
        # models, if need be.
        $type SetState RUNNING

        # NEXT, Either execute the first tick and schedule the next,
        # or run in blocking mode until the stop time.
        if {!$blocking} {
            # FIRST, run a tick immediately.
            $type Tick

            # NEXT, if we didn't pause as a result of the first
            # tick, schedule the next one.
            if {$info(state) eq "RUNNING"} {
                $ticker schedule
            }
        } else {
            while {$info(state) eq "RUNNING"} {
                $type Tick
            }

            set info(stoptime) 0
        }

        # NEXT, return "", as this can't be undone.
        return ""
    }

    # mutate pause
    #
    # Pauses the simulation from running.

    typemethod {mutate pause} {} {
        # FIRST, cancel the ticker, so that the next tick doesn't occur.
        $ticker cancel

        # NEXT, set the state to paused, if we're running
        if {$info(state) eq "RUNNING"} {
            set info(stoptime) 0
            $type SetState PAUSED
        }

        # NEXT, cannot be undone.
        return ""
    }

    #-------------------------------------------------------------------
    # Tick

    # Tick
    #
    # This command invokes TickWork to do the tick work, wrapped in an
    # RDB transaction.

    typemethod Tick {} {
        if {[parm get sim.tickTransaction]} {
            rdb transaction {
                $type TickWork
            }
        } else {
            $type TickWork
        }
    }

    # TickWork
    #
    # This command is executed at each time tick.

    typemethod TickWork {} {
        # FIRST, advance models
        profile demog analyze pop
        profile ensit assess
        profile nbstat analyze
        profile actsit assess
        
        if {[simclock now] % [parmdb get aam.ticksPerTock] == 0} {
            profile aam assess
        }

        if {[simclock now] % [parmdb get econ.ticksPerTock] == 0} {
            set econOK [profile econ tock]

            if {$econOK} {
                profile demog analyze econ
            }
        }

        profile demsit assess

        # NEXT, advance GRAM (if t > 0); but first give it the latest
        # population data.
        #
        # TBD: This mechanism is nuts.
        if {[simclock now] > 0} {
            aram update population {*}[rdb eval {
                SELECT n,g,population 
                FROM demog_g
                JOIN civgroups USING (g)
            }]

            profile aram advance
        }

        # NEXT, save the history for this tick.
        profile hist tick

        if {[simclock now] % [parmdb get econ.ticksPerTock] == 0} {
            profile hist econ
        }

        # NEXT, advance time one tick.
        simclock tick

        notifier send $type <Time>
        log normal sim "Tick [simclock now]"
        set info(changed) 1
        
        # NEXT, execute eventq events
        profile eventq advance [simclock now]

        # NEXT, assess actor influence and execute actor strategies.
        if {[simclock now] % [parmdb get strategy.ticksPerTock] == 0} {
            profile control tock
            profile strategy tock
        }

        # NEXT, do staffing.
        # TBD: It's not yet clear how staffing relates to tactics.
        profile activity analyze staffing

        # NEXT, pause if it's the pause time, or checks failed.
        set stopping 0

        if {![sanity ontick check]} {
            app show my://app/sanity/ontick

            if {[winfo exists .main]} {
                messagebox popup \
                    -parent  [app topwin]         \
                    -icon    error                \
                    -title   "Simulation Stopped" \
                    -message [normalize {
            On-tick sanity check failed; simulation stopped.
            Please see the On-Tick Sanity Check report for details.
                    }]
            }

            set stopping 1
        }

        if {$info(stoptime) != 0 &&
            [simclock now] >= $info(stoptime)
        } {
            log normal sim "Stop time reached"
            set stopping 1
        }

        if {$stopping} {
            $type mutate pause

            # Update demographics and nbstats, in case the user
            # wants to look at them.
            profile demog    analyze pop
            profile nbstat   analyze
        }

        # NEXT, notify the application that the tick has occurred.
        notifier send $type <Tick>
    }

    #-------------------------------------------------------------------
    # Utility Routines

    # SetState state
    #
    # state    The simulation state
    #
    # Sets the current simulation state, and reports it as <State>.

    typemethod SetState {state} {
        # FIRST, transition to the new state.
        set info(state) $state
        log normal sim "Simulation state is $info(state)"

        notifier send $type <State>
    }

    #-------------------------------------------------------------------
    # saveable(i) interface

    # checkpoint ?-saved?
    #
    # Returns a checkpoint of the non-RDB simulation data.

    typemethod checkpoint {{option ""}} {
        assert {$info(state) ne "RUNNING"}

        if {$option eq "-saved"} {
            set info(changed) 0
        }

        set checkpoint [dict create]
        
        dict set checkpoint state $info(state)
        dict set checkpoint t0    [simclock cget -t0]
        dict set checkpoint now   [simclock now]

        return $checkpoint
    }

    # restore checkpoint ?-saved?
    #
    # checkpoint     A string returned by the checkpoint typemethod
    
    typemethod restore {checkpoint {option ""}} {
        # FIRST, restore the checkpoint data
        dict with checkpoint {
            simclock configure -t0 $t0
            simclock reset
            simclock advance $now

            if {[info exists state]} {
                set info(state) $state
            } elseif {$now == 0} {
                # Fix up older scenario files, in which state was not
                # checkpointed.
                set info(state) PREP
            } else {
                set info(state) PAUSED
            }
        }

        if {$option eq "-saved"} {
            set info(changed) 0
        }
    }

    # changed
    #
    # Returns 1 if saveable(i) data has changed, and 0 otherwise.

    typemethod changed {} {
        return $info(changed)
    }


    #-------------------------------------------------------------------
    # Order Helper Routines

    # Refresh_SS dlg fields fdict
    #
    # Initializes the startdate parameter of SIM:STARTDATE when the
    # the order is cleared.
    
    typemethod Refresh_SS {dlg fields fdict} {
        dict with fdict {
            if {$startdate eq ""} {
                $dlg set startdate [simclock cget -t0]
            }
        }
    }
}

# SIM:STARTDATE
#
# Sets the zulu-time corresponding to time 0

order define SIM:STARTDATE {
    title "Set Start Date"
    options -sendstates PREP \
        -refreshcmd {::sim Refresh_SS}

    parm startdate  text "Start Date"
} {
    # FIRST, prepare the parameters
    prepare startdate -toupper -required -type zulu

    returnOnError -final

    # NEXT, set the start date
    lappend undo [sim mutate startdate $parms(startdate)]

    setundo [join $undo \n]
}

# SIM:LOCK
#
# Locks scenario preparation and transitions from PREP to PAUSED.

order define SIM:LOCK {
    title "Lock Scenario Preparation"
    options -sendstates {PREP}
} {
    # FIRST, do the scenario sanity check.
    if {![sanity onlock check]} {
        app show my://app/sanity/onlock

        reject * {
            Scenario sanity check failed; time cannot advance.
            Fix the error, and try again.
            Please see the Detail Browser for details.
        }

        returnOnError
    }

    returnOnError -final

    # NEXT, do the strategy sanity check.
    if {![strategy sanity check]} {
        app show my://app/sanity/strategy

        set answer \
            [messagebox popup \
                 -title         "Strategy Sanity Check Failed"   \
                 -icon          warning                          \
                 -buttons       {ok "Continue" cancel "Cancel"}  \
                 -default       cancel                           \
                 -ignoretag     strategy_check_failed            \
                 -ignoredefault ok                               \
                 -parent        [app topwin]                     \
                 -message       [normalize {
                     The Strategy sanity check has failed; one or
                     more tactics or conditions are invalid.  See the 
                     Detail Browser for details.  Press "Cancel" and
                     fix the problems, or press "Continue" to 
                     go ahead and lock the scenario, in which 
                     case the invalid tactics and conditions will be 
                     ignored as the simulation runs.
                 }]]

        if {$answer eq "cancel"} {
            # Don't do anything.
            return
        }
    }

    # NEXT, lock scenario prep.
    lappend undo [sim mutate lock]

    setundo [join $undo \n]
}


# SIM:UNLOCK
#
# Locks scenario preparation and transitions from PREP to PAUSED.

order define SIM:UNLOCK {
    title "Unlock Scenario Preparation"
    options \
        -sendstates {PAUSED SNAPSHOT} \
        -monitor    no
} {
    returnOnError -final

    # NEXT, unlock scenario prep.
    lappend undo [sim mutate unlock]

    setundo [join $undo \n]
}


# SIM:RUN
#
# Starts the simulation going.

order define SIM:RUN {
    title "Run Simulation"
    options -sendstates {PAUSED}

    parm days  text "Days to Run"
    parm block enum "Block?"         -enumtype eyesno -defval NO

    # TBD Need to indicate valid states
} {
    # FIRST, prepare the parameters
    prepare days  -toupper -type idays
    prepare block -toupper -type boolean

    returnOnError

    # NEXT, if block is yes, then days must be greater than 0
    validate block {
        if {$parms(block) && ($parms(days) eq "" || $parms(days) == 0)} {
            reject block "Cannot block without specifying the days to run"
        }
    }

    returnOnError -final

    if {$parms(block) eq ""} {
        set parms(block) 0
    }

    # NEXT, start the simulation and return the undo script

    if {$parms(days) eq "" || $parms(days) == 0} {
        lappend undo [sim mutate run]
    } else {
        set ticks [simclock fromDays $parms(days)]

        lappend undo [sim mutate run -ticks $ticks -block $parms(block)]
    }

    setundo [join $undo \n]
}


# SIM:PAUSE
#
# Pauses the simulation.  It's an error if the simulation is not
# running.

order define SIM:PAUSE {
    title "Pause Simulation"
    options -sendstates RUNNING
} {
    returnOnError -final

    # FIRST, pause the simulation and return the undo script
    lappend undo [sim mutate pause]

    setundo [join $undo \n]
}


