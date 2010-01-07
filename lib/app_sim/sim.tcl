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
    
    typevariable constants -array {
        ticksize  {1 day}
        startdate 100000ZJAN10
    }

    # speeds -- array of inter-tick delays in milliseconds, by
    #           simulation speed.

    typevariable speeds -array {
        1  10000
        2   5000
        3   3000
        4   2000
        5   1000
        6    600
        7    400
        8    200
        9    100
        10    50
    }

    # info -- scalar info array
    #
    # changed    1 if saveable(i) data has changed, and 0 otherwise.
    # state      The current simulation state, a simstate value
    # stoptime   The time tick at which the simulation should pause,
    #            or 0 if there's no limit.
    # speed      The speed at which the simulation should run.
    #            (This should probably be saved with the GUI settings.)

    typevariable info -array {
        changed   0
        state     PREP
        stoptime  0
        speed     5
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
        set ticker [timeout ${type}::ticker              \
                        -interval   $speeds($info(speed)) \
                        -repetition yes                  \
                        -command    [mytypemethod Tick]]

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

        # NEXT, initialize the situation modules
        situation init

        log normal sim "Initialized"
    }

    # LoadAram gram
    #
    # Loads scenario data into ARAM when it's initialized.

    typemethod LoadAram {gram} {
        $gram load nbhoods {*}[rdb eval {
            SELECT n FROM nbhoods
            ORDER BY n
        }]

        $gram load groups {*}[rdb eval {
            SELECT g, gtype FROM groups
            ORDER BY gtype,g
        }]

        $gram load concerns {*}[rdb eval {
            SELECT c, gtype FROM concerns
            ORDER BY gtype,c
        }]

        $gram load nbrel {*}[rdb eval {
            SELECT m, n, proximity, effects_delay 
            FROM nbrel_mn
            ORDER BY m,n
        }]

        # Only need to load civ nbgroups with non-zero population.
        $gram load nbgroups {*}[rdb eval {
            SELECT n, g, basepop, rollup_weight, effects_factor
            FROM nbgroups
            ORDER BY n,g
        }]

        $gram load sat {*}[rdb eval {
            SELECT n, g, c, sat0, saliency, trend0
            FROM sat_ngc JOIN groups USING (g)
            ORDER BY n, gtype, g, c
        }]

        # relationships are difficult: need to convert PLAYBOX
        # to all nbhoods
        set records [list]
        set nbhoods [nbhood names]

        rdb eval {
            SELECT n, f, g, rel
            FROM rel_nfg
            ORDER BY n, f, g
        } {
            if {$n ne "PLAYBOX"} {
                lappend records $n $f $g $rel
            } else {
                foreach n $nbhoods {
                    lappend records $n $f $g $rel
                }
            }
        }

        $gram load rel {*}$records

        $gram load coop {*}[rdb eval {
            SELECT n, f, g, coop0
            FROM coop_nfg
            ORDER BY n, f, g
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

        # NEXT, set the simulation status
        set info(changed) 0
        set info(state)   PREP

        $type reconfigure
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

        # NEXT, reconfigure the app.
        $type reconfigure

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

        # NEXT, reconfigure the app.
        # TBD: Is this needed?
        $type reconfigure
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
        cif       reconfigure
        map       reconfigure
        nbhood    reconfigure
        nbrel     reconfigure
        group     reconfigure
        civgroup  reconfigure
        frcgroup  reconfigure
        orggroup  reconfigure
        nbgroup   reconfigure
        sat       reconfigure
        rel       reconfigure
        coop      reconfigure
        unit      reconfigure
        situation reconfigure

        # NEXT, Reconfigure the GUI
        notifier send $type <Reconfigure>
        notifier send $type <Time>
        notifier send $type <Speed>
        notifier send $type <State>
    }


    #-------------------------------------------------------------------
    # Speed Control
    #
    # The inter-tick delay controls how fast the sim appears to run.
    # There's no order for this, as it has no effect on the simulation 
    # proper.  It can be set and reset at any time, including when the
    # simulation is running.

    # speed ?speed?
    #
    # speed     The simulation speed, 1 through 10
    #
    # Sets/queries the simulation speed.

    typemethod speed {{speed ""}} {
        if {$speed ne "" && $speed != $info(speed)} {
            require {$speed in [array names speeds]} \
                "Invalid speed: \"$speed\""

            set info(speed) $speed

            set wasScheduled [$ticker isScheduled]
            
            $ticker cancel
            $ticker configure -interval $speeds($info(speed))
            
            if {$wasScheduled} {
                $ticker schedule
            }

            notifier send $type <Speed>
        }

        return $info(speed)
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
    # Model Sanity Check

    # check ?-log?
    #
    # Does a sanity check of the model: can leave PREP for PAUSED?
    # Returns 1 if sane and 0 otherwise.  If -log is specified, then the 
    # results are logged.

    typemethod check {{option -nolog}} {
        # FIRST, presume that the model is sane.
        set sane 1

        set results [list]

        # NEXT, Require at least one neighborhood:
        if {[llength [nbhood names]] == 0} {
            set sane 0

            lappend results \
                "No neighborhoods are defined; at least one is required"
        }

        # NEXT, verify that neighborhoods are properly stacked
        rdb eval {
            SELECT n, obscured_by FROM nbhoods
            WHERE obscured_by != ''
        } {
            set sane 0

            lappend results \
                "Neighborhood $n is obscured by neighborhood $obscured_by"
        }

        # NEXT, Require at least one force group
        if {[llength [frcgroup names]] == 0} {
            set sane 0

            lappend results \
                "No force groups are defined; at least one is required"
        }

        # NEXT, Require at least one civ group
        if {[llength [civgroup names]] == 0} {
            set sane 0

            lappend results \
                "No civilian groups are defined; at least one is required"
        }

        # NEXT, collect data on neighborhood groups
        rdb eval {
            SELECT n,g FROM nbgroups
        } {
            lappend gInN($n)  $g
            lappend nForG($g) $n
        }

        # NEXT, Every neighborhood must have at least one group
        # TBD: Is this really required?  Can we insist, instead,
        # that at least one neighborhood must have a group?
        foreach n [nbhood names] {
            if {![info exists gInN($n)]} {
                set sane 0

                lappend results \
              "Neighborhood $n contains no groups; at least one is required"
            }
        }

        # NEXT, Every CIV group must reside in at least one nbhood.
        # TBD: Is this really required?
        foreach g [civgroup names] {
            if {![info exists nForG($g)]} {
                set sane 0

                lappend results \
      "Civilian group $g resides in no neighborhoods; at least one is required"
            }
        }

        # NEXT, every ensit must reside in a neighborhood
        set ids [rdb eval {
            SELECT s FROM ensits
            WHERE n = ''
        }]

        if {[llength $ids] > 0} {
            set sane 0

            set ids [join $ids ", "]
            lappend results \
                "The following ensits are outside any neighborhood:\n $ids"
        }

        # NEXT, you can't have more than one ensit of a type in a 
        # neighborhood.
        rdb eval {
            SELECT count(s) AS count, n, stype
            FROM ensits
            GROUP BY n, stype
            HAVING count > 1
        } {
            set sane 0
            lappend results \
                "Duplicate ensits of type $stype in neighborhood $n"
        }

        # NEXT, all implicit population figures must be at least 1
        rdb eval {
            SELECT n,g,implicit FROM demog_ng
            WHERE implicit < 1
        } {
            set sane 0
            lappend results \
                "Implicit population < 1 for group $g in neighborhood $n." \
                "Increase the base population, or reduce the number of" \
                "people in units for $n $g."
        }

        # NEXT, report on sanity
        if {$option eq "-log"} {
            if {$sane} {
                log normal sim "Scenario Sanity Check: OK"
            } else {
                log warning sim \
                    "Scenario Sanity Check: FAILED\n[join $results \n]"
            }
        }

        # NEXT, return the result
        return $sane
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

        # NEXT, initialize the ARAM, etc.
        aram     init -reload
        nbstat   init
        mad      getdrivers

        # NEXT, execute events scheduled at time 0.
        eventq advance 0

        # NEXT, set the state to PAUSED
        $type SetState PAUSED

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

        # NEXT, reconfigure
        # TBD: Is this needed?
        $type reconfigure

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
        assert {$info(state) ne "RUNNING"}

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
    # This command is executed at each time tick.

    typemethod Tick {} {
        # FIRST, advance models
        ensit assess
        nbstat analyze
        actsit analyze
        
        if {[simclock now] % [parmdb get aam.ticksPerTock] == 0} {
            aam assess
        }

        # NEXT, advance GRAM; but first give it the latest
        # population data.
        aram update population {*}[rdb eval {
            SELECT n,g,population FROM demog_ng
        }]
        aram advance

        # NEXT, check Reactive Decision Conditions (RDCs)
        # TBD: None yet

        # NEXT, advance time one tick.
        simclock tick

        notifier send $type <Time>
        log normal sim "Tick [simclock now]"
        set info(changed) 1
        
        # NEXT, execute eventq events
        eventq advance [simclock now]

        # NEXT, pause if it's the pause time.
        if {$info(stoptime) != 0 &&
            [simclock now] >= $info(stoptime)
        } {
            log normal sim "Stop time reached"
            $type mutate pause
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

    # RefreshStartDate
    #
    # Initializes the startdate parameter of SIM:STARTDATE when the
    # the order is cleared.
    
    typemethod RefreshStartDate {field parmdict} {
        if {[$field get] eq ""} {
            $field set [simclock cget -t0]
        }
    }
}

# SIM:STARTDATE
#
# Sets the zulu-time corresponding to time 0

order define ::sim SIM:STARTDATE {
    title "Set Start Date"
    options -sendstates PREP

    parm startdate  text "Start Date" \
        -refreshcmd [list ::sim RefreshStartDate]
} {
    # FIRST, prepare the parameters
    prepare startdate -toupper -required -type zulu

    returnOnError -final

    # NEXT, set the start date
    lappend undo [$type mutate startdate $parms(startdate)]

    setundo [join $undo \n]
}

# SIM:LOCK
#
# Locks scenario preparation and transitions from PREP to PAUSED.

order define ::sim SIM:LOCK {
    title "Lock Scenario Preparation"
    options -sendstates {PREP}
} {
    # FIRST, do the sanity check.
    if {![sim check -log]} {
        reject * {
            Scenario sanity check failed; time cannot advance.
            Fix the error, and try again.
            Please see the log for details.
        }

        if {[interface] eq "gui"} {
            [app topwin] tab view slog
        }
    }

    returnOnError -final

    # NEXT, lock scenario prep.
    lappend undo [$type mutate lock]

    setundo [join $undo \n]
}


# SIM:UNLOCK
#
# Locks scenario preparation and transitions from PREP to PAUSED.

order define ::sim SIM:UNLOCK {
    title "Unlock Scenario Preparation"
    options -sendstates {PAUSED SNAPSHOT}
} {
    returnOnError -final

    # NEXT, unlock scenario prep.
    lappend undo [$type mutate unlock]

    setundo [join $undo \n]
}


# SIM:RUN
#
# Starts the simulation going.

order define ::sim SIM:RUN {
    title "Run Simulation"
    options -sendstates {PAUSED}

    parm days  text "Days to Run"
    parm block enum "Block?"         -type eyesno -defval NO

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
        lappend undo [$type mutate run]
    } else {
        set ticks [simclock fromDays $parms(days)]

        lappend undo [$type mutate run -ticks $ticks -block $parms(block)]
    }

    setundo [join $undo \n]
}


# SIM:PAUSE
#
# Pauses the simulation.  It's an error if the simulation is not
# running.

order define ::sim SIM:PAUSE {
    title "Pause Simulation"
    options -sendstates RUNNING
} {
    returnOnError -final

    # FIRST, pause the simulation and return the undo script
    lappend undo [$type mutate pause]

    setundo [join $undo \n]
}

