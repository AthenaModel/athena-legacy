#-----------------------------------------------------------------------
# TITLE:
#    parmdb.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena model parameter database
#
#    The module delegates most of its function to parmset(n).
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export parmdb
}

#-------------------------------------------------------------------
# parm

snit::type ::projectlib::parmdb {
    # Make it a singleton
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Typecomponents

    typecomponent ps ;# The parmset(n) object

    #-------------------------------------------------------------------
    # Type Variables

    # Name of the defaults file; set by init
    typevariable defaultsFile

    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod * to ps

    # init
    #
    # Initializes the module

    typemethod init {} {
        # Don't initialize twice.
        if {$ps ne ""} {
            return
        }

        # FIRST, set the defaults file name
        set defaultsFile [file join ~ .athena defaults.parmdb]

        # NEXT, create the parmset.
        set ps [parmset %AUTO%]

        # NEXT, define the "sim" parameters

        $ps subset sim {
            Parameters which affect the behavior of the simulation in
            general.
        }

        $ps define sim.tickSize ::marsutil::ticktype {1 day} {
            Defines the size of the simulation time tick, i.e., the 
            resolution of the simulation clock.  The time tick can be 
            (within reason) any positive number of minutes, hours, or days, 
            expressed as "<number> <units>", e.g., "1 minute", "2 minutes",
            "1 hour", "2 hours", "1 day", "2 days".  This parameter
            cannot be changed at run-time.
        }

        # NEXT, define gram parameters
        $ps slave add [list ::simlib::gram parm]

        # NEXT, define rmf parameters
        $ps slave add [list ::simlib::rmf parm]
    }

    # defaults save
    #
    # Saves the current parameters as the default for future
    # scenarios, by saving ~/.athena/defaults.parmdb.

    typemethod {defaults save} {} {
        parm save $defaultsFile
        return
    }

    # defaults clear
    #
    # Clears the saved defaults by deleting ~/.athena/defaults.parmdb.

    typemethod {defaults clear} {} {
        if {[file exists $defaultsFile]} {
            file delete $defaultsFile
        }
        return
    }

    # defaults load
    #
    # Loads the parameters from the defaults file, if any.  Otherwise,
    # the parameters are reset to the normal defaults.

    typemethod {defaults load} {} {
        if {[file exists $defaultsFile]} {
            $ps load $defaultsFile -safe
        } else {
            $ps reset
        }

        return
    }
}

