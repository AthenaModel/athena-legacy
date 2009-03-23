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
        startdate 190000ZMAR09
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
    # Checkpointed type variables

    # db -- Checkpointed scalars
    #
    # cifmark    Marks the top of the CIF on PREP->RUNNING, to support
    #            "mutate restart".

    typevariable db -array {
        cifmark   ""
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
        # FIRST, set the simulation state
        set info(state)   PREP
        set info(changed) 0

        # NEXT, configure the simclock.
        simclock configure              \
            -tick $constants(ticksize)  \
            -t0   $constants(startdate)

        simclock reset

        # NEXT, clear the event queue
        eventq restart

    }

    # restart
    #
    # Resets the simulation as a whole to the moment before it first
    # transitioned from PREP to RUNNING.

    typemethod restart {} {
        assert {[sim state] eq "PAUSED"}

        # FIRST, Confirm with the user
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

        # NEXT, reset the sim time to time 0
        simclock reset
        
        # NEXT, clean up other simulation modules and delete simulation
        # history.
        cif clear $db(cifmark)
        eventq restart
        
        # TBD: Other cleanup

        # NEXT, reset the sim state.  Don't use SetState, as we'll be
        # reconfiguring immediately.
        set info(state) PREP

        # NEXT, reconfigure the app.
        $type reconfigure

        # NEXT, log the restart.
        log newlog restart
        log normal sim "Restarted the simulation"
        app puts "Restarted the simulation"

        # NEXT, no undo.
        return ""
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

            notifier send $type <State>
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
        notifier send $type <State>

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
            # FIRST, Do a sanity check: can we advance time?
            # TBD

            # NEXT, mark the top of the CIF stack, so that we
            # can return to it on restart.
            set db(cifmark) [cif mark]

            # NEXT, initialize ARAM.
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

        # NEXT, set the state to paused.
        $type SetState PAUSED

        # NEXT, cannot be undone.
        return ""
    }

    #-------------------------------------------------------------------
    # Tick

    # Tick
    #
    # This command is executed at each time tick.

    typemethod Tick {} {
        # FIRST, advance time one tick.
        # TBD: Put the <State> event and log message in -advancecmd?
        simclock tick

        notifier send $type <State>
        log normal sim "Tick [simclock now]"
        set info(changed) 1
        
        # NEXT, advance ARAM
        # TBD: aram advance

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
    }

    #-------------------------------------------------------------------
    # Utility Routines

    # SetState state
    #
    # state    The simulation state
    #
    # Sets the current simulation state, and reports it as <State>

    typemethod SetState {state} {
        set info(state) $state
        log normal sim "Simulation state is $info(state)"
        notifier send $type <State>
    }

    #-------------------------------------------------------------------
    # saveable(i) interface

    # checkpoint
    #
    # Returns a checkpoint of the non-RDB simulation data.

    typemethod checkpoint {} {
        set info(changed) 0

        set checkpoint [dict create]

        dict set checkpoint t0   [simclock cget -t0]
        dict set checkpoint now  [simclock now]
        dict set checkpoint db   [array get db]
    }

    # restore checkpoint
    #
    # checkpoint     A string returned by the checkpoint typemethod
    
    typemethod restore {checkpoint} {
        # FIRST, restore the checkpoint data
        simclock configure -t0 [dict get $checkpoint t0]
        simclock reset
        simclock advance [dict get $checkpoint now]

        array unset db
        array set db [dict get $checkpoint db]

        # Don't use SetState, as we'll be reconfiguring immediately.
        if {[simclock now] == 0} {
            set info(state) PREP
        } else {
            set info(state) PAUSED
        }

        set info(changed) 0
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

    parm days text "Days to Run"

    # TBD Need to indicate valid states
} {
    # FIRST, prepare the parameters
    prepare days -toupper

    # NEXT, check for errors
    
    validate days {
        # TBD: If not numeric and positive, reject.
    }

    returnOnError

    # NEXT, start the simulation and return the undo script

    if {$parms(days) eq ""} {
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

    # TBD Need to indicate valid states
} {
    # FIRST, pause the simulation and return the undo script
    lappend undo [$type mutate pause]

    setundo [join $undo \n]
}






