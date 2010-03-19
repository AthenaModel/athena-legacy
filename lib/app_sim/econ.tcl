#-----------------------------------------------------------------------
# FILE: econ.tcl
#
#   Athena Economics Model singleton
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module: econ
#
# This module is responsible for computing the economics of the
# region for this scenario.  The three primary entry points are:
# <init>, to be called at start-up; <calibrate>, which calibrates the 
# model when the simulation leaves the PREP state and enters time 0, 
# and <advance>, to be called when time is advanced for the economic model.

snit::type econ {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Group: Type Components

    # Type Component: cge
    #
    # This is the cellmodel(n) instance containing the CGE model.

    typecomponent cge

    #-------------------------------------------------------------------
    # Group: Non-Checkpointed Type Variables

    # Type Variable: info
    #
    # Miscellaneous non-checkpointed scalar values.
    #
    # changed - 1 if there is unsaved data, and 0 otherwise.

    typevariable info -array {
        changed 0
    }



    #-------------------------------------------------------------------
    # Group: Initialization

    # Type Method: init
    #
    # Initializes the module before the simulation first starts to run.

    typemethod init {} {
        log normal econ "init"

        # FIRST, create the CGE.
        set cge [cellmodel cge]
        cge load [readfile [file join $::app_sim::library eco3x3.cm]]
        
        require {[cge sane]} "The econ model's CGE (eco3x3.cm) is not sane."

        # NEXT, register this type as a saveable
        scenario register ::econ

        # NEXT, Econ is up.
        log normal econ "init complete"
    }

    # Type Method: start
    #
    # Calibrates the CGE.  This is done when the simulation leaves
    # the PREP state and enters time 0.

    typemethod start {} {
        log normal econ "start"

        # FIRST, set the input parameters
        cge reset
        cge set [list in::population 2e6]

        # NEXT, calibrate the CGE.
        set result [cge solve]

        # NEXT, the data has changed.
        set info(changed) 1

        # NEXT, handle failures.
        if {$result ne "ok"} {
            log warning econ "Failed to calibrate"
            error "Failed to calibrate economic model."
        }

        log normal econ "start complete"
    }

    #-------------------------------------------------------------------
    # Group: Time Advance

    # Type Method: tock
    #
    # Updates the CGE at each econ tock.

    typemethod tock {} {
        log normal econ "tock"

        # FIRST, set the input parameters
        # TBD

        # NEXT, update the CGE.
        set result [cge solve in]

        # NEXT, the data has changed.
        set info(changed) 1

        # NEXT, handle failures
        if {$result ne "ok"} {
            log warning econ "Failed to advance economic model"
            error "Failed to advance economic model"
        }

        log normal econ "tock complete"
    }

    #-------------------------------------------------------------------
    # Group: Queries

    # Type Methods: Delegated
    #
    # Methods delegated to the <cge> component
    #
    # - get

    delegate typemethod get to cge

    #-------------------------------------------------------------------
    # Group: saveable(i) interface

    # Type Method: checkpoint
    #
    # Returns a checkpoint of the non-RDB simulation data.  If 
    # -saved is specified, the data is marked unchanged.
    #
    # Syntax:
    #   checkpoint ?-saved?


    typemethod checkpoint {{option ""}} {
        if {$option eq "-saved"} {
            set info(changed) 0
        }

        return [cge get]
    }

    # Type Method: restore
    #
    # Restores the non-RDB state of the module to that contained
    # in the _checkpoint_.  If -saved is specified, the data is marked
    # unchanged.
    #
    # Syntax:
    #   restore _checkpoint_ ?-saved?
    #
    #   checkpoint - A string returned by the checkpoint typemethod
    
    typemethod restore {checkpoint {option ""}} {
        # FIRST, restore the checkpoint data
        cge set $checkpoint

        if {$option eq "-saved"} {
            set info(changed) 0
        }
    }

    # Type Method: changed
    #
    # Returns 1 if saveable(i) data has changed, and 0 otherwise.
    #
    # Syntax:
    #   changed

    typemethod changed {} {
        return $info(changed)
    }

}

