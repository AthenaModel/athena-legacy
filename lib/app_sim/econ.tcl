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
    # Group: Initialization

    # Type Method: init
    #
    # Initializes the module before the simulation first starts to run.

    typemethod init {} {
        log normal econ "init"

        # FIRST, create the CGE.
        cellmodel cge
        cge load [readfile [file join $::app_sim::library eco3x3.cm]]
        
        require {[cge sane]} "The econ model's CGE (eco3x3.cm) is not sane."

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
        # TBD

        # NEXT, calibrate the CGE.
        set result [cge solve]

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

        if {$result ne "ok"} {
            log warning econ "Failed to advance economic model"
            error "Failed to advance economic model"
        }

        log normal econ "tock complete"
    }
}

