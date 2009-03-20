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

    # info -- scalar info array
    #
    # changed   1 if saveable(i) data has changed, and 0 otherwise.
    # state     The current simulation state, a simstate value
    # delay     The inter-tick delay in milliseconds.  
    #           TBD: Should be checkpointed.
    # stoptime  The time tick at which the simulation should pause,
    #           or 0 if there's no limit.

    typevariable info -array {
        changed  0
        state    PREP
        delay    1000
        stoptime 0
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
                        -interval   $info(delay)         \
                        -repetition yes                  \
                        -command    [mytypemethod Tick]]
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

    # reset
    #
    # Resets the simulation to time 0 and the PREP state, doing all
    # relevent cleanup.

    typemethod reset {} {
        # FIRST, reset the sim time to time 0
        simclock reset
        
        # NEXT, clean up other simulation modules and delete simulation
        # history.
        # TBD: Clear orders at times greater than time 0 from the CIF.
        # TBD: Reset the event queue, including scheduling standard events.

        # NEXT, reset the sim state.  Don't use SetState, as we'll be
        # reconfiguring immediately.
        set info(state) PREP

        # NEXT, reconfigure the app.
        $type reconfigure
    }

    #-------------------------------------------------------------------
    # Queries

    # state
    #
    # Returns the current simulation state

    typemethod state {} {
        return $info(state)
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.


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
        notifier send ::sim <Time>

        # NEXT, set the undo command
        return [mytypemethod mutate startdate $oldDate]
    }

    # mutate run ?options...?
    #
    # -ticks ticks       Run until now + ticks
    # -until tick        Run until tick
    #
    # Causes the simulation to run time forward until the specified
    # time, or until "mutate stop" is called.
    #
    # Time proceeds by ticks; each tick is run in the context of the 
    # Tcl event loop, as controlled by a timeout(n) object called
    # "ticker".  The timeout interval is called the inter-tick delay;
    # it determines how fast the simulation runs.

    typemethod {mutate run} {args} {
        assert {$info(state) ne "RUNNING"}

        # FIRST, get the stop time
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
        # TBD: E.g., initialize ARAM.

        # NEXT, set the state to running
        $type SetState RUNNING

        # NEXT, schedule the next tick.
        $ticker schedule

        # NEXT, return "", as this can't be undone.
        return ""
    }

    # mutate stop
    #
    # Stops the simulation from running.

    typemethod {mutate stop} {} {
        # FIRST, cancel the ticker, so that the next tick doesn't occur.
        $ticker cancel

        # NEXT, set the state to paused.
        $type SetState PAUSED
    }

    #-------------------------------------------------------------------
    # Tick

    # Tick
    #
    # This command is executed at each time tick.

    typemethod Tick {} {
        # FIRST, advance time one tick.
        # TBD: Put the <Time> event and log message in -advancecmd?
        simclock tick

        notifier send $type <Time>
        log normal sim "Tick [simclock now]"
        
        # NEXT, advance ARAM
        # TBD: aram advance

        # NEXT, execute eventq events
        # TBD: eventq advance [simclock now]

        # NEXT, check Reactive Decision Conditions (RDCs)

        # NEXT, stop if it's the stop time.
        if {$info(stoptime) != 0 &&
            [simclock now] >= $info(stoptime)
        } {
            log normal sim "Stop time reached"
            $type mutate stop
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

        return [simclock cget -t0]
    }

    # restore checkpoint
    #
    # checkpoint     A string returned by the checkpoint typemethod
    
    typemethod restore {checkpoint} {
        # FIRST, restore the sim time
        simclock configure -t0 $checkpoint

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







