#-----------------------------------------------------------------------
# FILE: parmdb.tcl
#
#   Preference parameter definitions
#
# PACKAGE:
#   app_gram(n): mars_gram(1) implementation package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Exported Commands

namespace eval ::lib:: {
    namespace export parmdb
}

#-----------------------------------------------------------------------
# Module: parmdb
#
# This module is a wrapper around a parmset(n) object containing
# preference and model parameters for the application.  In addition
# to defining the application-specific parameters and pulling in
# library parameters, it provides for saving the parameters as
# ~/.mars_gram/defaults.parmdb.

snit::type parmdb {
    # Make it a singleton
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Typecomponents

    typecomponent ps ;# The parmset(n) object

    #-------------------------------------------------------------------
    # Group: Type Variables

    # Type Variable: defaultsFile
    #
    # The name of the user's default parameter settings file; set
    # by <init>.
    typevariable defaultsFile

    #-------------------------------------------------------------------
    # Group: Public Type Methods

    # Delegated Type Method: *
    #
    # All parmset(n) methods are available as subcommands of <parmdb>.
    
    delegate typemethod * to ps


    # Type method: init
    #
    # Initializes the module, defining the parameters and loading
    # the user's default settings (if any).

    typemethod init {} {
        # Don't initialize twice.
        if {$ps ne ""} {
            return
        }

        # FIRST, set the defaults file name
        set defaultsFile [file join ~ .mars_gram defaults.parmdb]

        # NEXT, create the parmset.
        set ps [parmset %AUTO%]

        # NEXT, define the "sim" parameters

        $ps subset sim {
            Parameters which affect the behavior of the simulation in
            general.
        }

        $ps define sim.tickSize ::marsutil::ticktype {5 minutes} {
            Defines the size of the simulation time tick, i.e., the 
            resolution of the simulation clock.  The time tick can be 
            (within reason) any positive number of minutes, hours, or days, 
            expressed as "<i>number</i> <i>units</i>", e.g., 
            "1 minute", "2 minutes", 
            "1 hour", "2 hours", "1 day", "2 days"; however, the Athena
            models are designed for a tick size of approximately one
            day.<p>  

            This parameter takes effect when on "load" and "reset".
        }
        
        $ps define sim.stepSize ::ticks 5 {
            Defines the default step size, in ticks.
        }

        # NEXT, define gram parameters
        $ps slave add [list ::simlib::gram parm]

        # NEXT, define rmf parameters
        $ps slave add [list ::simlib::rmf parm]
        
        # NEXT, load default parameters
        $type load
    }

    # Type method: save
    #
    # Saves the current parameter settings to the user <defaultsFile>
    # as the default for future runs.

    typemethod save {} {
        file mkdir [file join ~ .mars_gram]
        $ps save $defaultsFile
        return
    }

    # Type method: reset
    #
    # Resets all parameter settings to their default values, and
    # deletes the user <defaultsFile>.

    typemethod reset {} {
        if {[file exists $defaultsFile]} {
            file delete $defaultsFile
        }
        
        $ps reset
        return "Parameters reset to default values."
    }

    # Type method: load
    #
    # Loads the user's parameter settings from the user <defaultsFile>,
    # if there is one.  Otherwise, the parameters are reset to the normal
    # defaults.

    typemethod load {} {
        if {[file exists $defaultsFile]} {
            $ps load $defaultsFile -safe
        } else {
            $ps reset
        }

        return
    }
}

#-------------------------------------------------------------------
# Section: Validation Types

# Type: ticks
#
# An integer number of simulation ticks, no less than 1.
# TBD: This should probably be in a different module.

snit::integer ticks -min 1

