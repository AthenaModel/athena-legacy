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
    # happens just before the first time advance from time 0, when
    # the simulation state moves from PREP to RUNNING.

    typemethod init {} {
        # FIRST, register with scenario(sim) as a saveable
        scenario register $type

        # NEXT, set the simulation state
        set info(state)   PREP
        order state $info(state)
        set info(changed) 0

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

    # restart ?-noconfirm?
    #
    # Resets the simulation as a whole to the moment before it first
    # transitioned from PREP to RUNNING.

    typemethod restart {{option ""}} {
        assert {[sim state] eq "PAUSED"}

        # FIRST, Confirm with the user
        if {$option ne "-noconfirm"} {
            set answer [messagebox popup \
                            -title         "Are you sure?"   \
                            -icon          warning           \
                            -buttons       {
                                ok     "Restart the Sim" 
                                cancel "Cancel"
                            }                                \
                            -default       cancel            \
                            -ignoretag     sim_restart       \
                            -ignoredefault ok                \
                            -parent        [app topwin]      \
                            -message       [normalize {
                                Are you sure you
                                really want to reset the simulation state
                                back to time 0?  This cannot be undone!
                            }]]

            if {$answer eq "cancel"} {
                cancel
            }
        }

        # NEXT, if the time is greater than 0, save a snapshot
        if {[simclock now] > 0} {
            scenario snapshot save
        }

        # NEXT, restore to the tick 0 
        scenario snapshot load 0

        # NEXT, make sure the state is PREP
        $type SetState PREP

        # NEXT, log the restart.
        log newlog restart
        log normal sim "Restarted the simulation"
        app puts "Restarted the simulation"

        # NEXT, reconfigure the app.
        $type reconfigure

        return
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
        nbrel    reconfigure
        group    reconfigure
        civgroup reconfigure
        frcgroup reconfigure
        orggroup reconfigure
        nbgroup  reconfigure
        sat      reconfigure
        rel      reconfigure
        coop     reconfigure
        unit     reconfigure

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
    # Does a sanity check of the model: can we advance time from PREP?
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

    # mutate run ?options...?
    #
    # -ticks ticks       Run until now + ticks
    # -until tick        Run until tick
    #
    # Causes the simulation to run time forward until the specified
    # time, or until "mutate pause" is called.
    #
    # Time proceeds by ticks; each tick is run in the context of the 
    # Tcl event loop, as controlled by a timeout(n) object called
    # "ticker".  The timeout interval is called the inter-tick delay;
    # it determines how fast the simulation runs.

    typemethod {mutate run} {args} {
        assert {$info(state) ne "RUNNING"}

        # FIRST, get the pause time
        set info(stoptime) 0

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

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # The SIM:RUN order should have guaranteed this, but let's
        # check it to make sure.
        assert {$info(stoptime) == 0 || $info(stoptime) > [simclock now]}

        # NEXT, if state is PREP, we've got work to do
        if {$info(state) eq "PREP"} {
            # FIRST, initialize GRAM, other sim models
            # TBD
        }

        # NEXT, set the state to running
        $type SetState RUNNING

        # NEXT, schedule the next tick.
        $ticker schedule

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
    #
    # TBD: The precise sequence of events during a Tick has yet
    # to be determined.

    typemethod Tick {} {
        # FIRST, advance time one tick.
        simclock tick

        notifier send $type <Time>
        log normal sim "Tick [simclock now]"
        set info(changed) 1
        
        # NEXT, advance GRAM
        # TBD: gram advance

        # NEXT, execute eventq events
        eventq advance [simclock now]

        # NEXT, check Reactive Decision Conditions (RDCs)

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
    # On transition to RUNNING, saves snapshot

    typemethod SetState {state} {
        # FIRST, save snapshot if need be, purging snapshots
        # that are in the future.
        if {$info(state) ne "RUNNING" && $state eq "RUNNING"} {
            scenario snapshot purge [simclock now]
            scenario snapshot save
        }

        # NEXT, transition to the new state.
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
        if {$option eq "-saved"} {
            set info(changed) 0
        }

        set checkpoint [dict create]

        dict set checkpoint t0   [simclock cget -t0]
        dict set checkpoint now  [simclock now]
    }

    # restore checkpoint ?-saved?
    #
    # checkpoint     A string returned by the checkpoint typemethod
    
    typemethod restore {checkpoint {option ""}} {
        # FIRST, restore the checkpoint data
        simclock configure -t0 [dict get $checkpoint t0]
        simclock reset
        simclock advance [dict get $checkpoint now]

        # Don't use SetState, as we'll be reconfiguring immediately.
        if {[simclock now] == 0} {
            set info(state) PREP
        } else {
            set info(state) PAUSED
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
        $field set [simclock cget -t0]
    }
}

# SIM:STARTDATE
#
# Sets the zulu-time corresponding to time 0

order define ::sim SIM:STARTDATE {
    title "Set Start Date"
    options -sendstates PREP

    # TBD: This should be a "zulu" field; but that's not working
    # yet.
    parm startdate  text "Start Date" \
        -refreshcmd [list ::sim RefreshStartDate]
} {
    # FIRST, prepare the parameters
    prepare startdate -toupper -required -type zulu

    returnOnError

    # NEXT, set the start date
    lappend undo [$type mutate startdate $parms(startdate)]

    setundo [join $undo \n]
}

# SIM:RUN
#
# Starts the simulation going.

order define ::sim SIM:RUN {
    title "Run Simulation"
    options -sendstates {PREP PAUSED}

    parm days text "Days to Run"

    # TBD Need to indicate valid states
} {
    # FIRST, prepare the parameters
    prepare days -toupper -type idays

    returnOnError

    # NEXT, do the sanity check
    if {![sim check -log]} {
        reject * {
            Scenario sanity check failed; time cannot advance.
            Fix the error, and try again.
            Please see the log for details.
        }
    }

    returnOnError

    # NEXT, start the simulation and return the undo script

    if {$parms(days) eq "" || $parms(days) == 0} {
        lappend undo [$type mutate run]
    } else {
        lappend undo [$type mutate run -ticks [simclock fromDays $parms(days)]]
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

    # TBD Need to indicate valid states
} {
    # FIRST, pause the simulation and return the undo script
    lappend undo [$type mutate pause]

    setundo [join $undo \n]
}






