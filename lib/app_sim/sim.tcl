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

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # constants -- scalar array
    
    typevariable constants -array {
        ticksize  {1 day}
        startdate 190000ZMAR09
    }

    # info -- scalar info array
    #
    # changed   1 if saveable(i) data has changed, and 0 otherwise.
    # state     The current simulation state, a simstate value

    typevariable info -array {
        changed 0
        state   PREP
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
        set info(state)   prep
        set info(changed) 0

        # NEXT, configure the simclock.
        # TBD: The tick size and the start date should be parmdb parms.
        simclock configure              \
            -tick $constants(ticksize)  \
            -t0   $constants(startdate)
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
    }

    # reset
    #
    # Resets the simulation to time 0 and the PREP state, doing all
    # relevent cleanup.

    typemethod reset {} {
        # FIRST, reset the sim time to time 0
        simclock reset
        
        # NEXT, reset the sim state
        set info(state) PREP

        # NEXT, clean up other simulation modules and delete simulation
        # history.
        # TBD: Clear orders at times greater than time 0 from the CIF.

        # NEXT, reconfigure the app.
        $type reconfigure
    }


    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.


    # mutate startdate startdate
    #cha
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
        simclock configure -t0 $checkpoint
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







