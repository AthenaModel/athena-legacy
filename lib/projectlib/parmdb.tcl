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

        # NEXT, Force/Volatility/Security Parameters
        $ps subset force {
            Parameters which affect the neighborhood force analysis models.
        }

        $ps define force.mood ::simlib::rfraction 0.2 {
            Dial that controls the extent to which a civilian group's mood 
            in a neighborhood affects its force in that neighborhood.
            At 0.0, mood has no effect.  At 1.0, the group's force will
            be doubled if the mood is -100.0 (perfectly dissatisfied) and 
            zeroed  if the mood is +100 (perfectly satisfied).  At the
            default value of 0.2, the effect changes from 1.2 
            when perfectly dissatisfied to 0.8 when perfectly satisfied.
            (This value is denoted "b" in the Athena Analyst Guide.)
        }

        $ps define force.population ::simlib::rfraction 0.01 {
            Dial that controls the fraction of a civilian group's 
            population in a neighborhood  
            that counts toward that group's force in the 
            neighborhood.  Must be no less than 0. (This value is denoted 
            "a" in the Athena Analyst Guide.)
        }

        $ps define force.proximity ::projectlib::rgain 0.1 {
            Dial that controls the extent to which nearby 
            neighborhoods contribute to a group's force in a neighborhood.
            This dial should be larger if neighborhoods are small, and
            smaller if neighborhoods are large.  Set it to 0.0 if 
            nearby neighborhoods have no effect.  Must be no less than
            0.  (This value is denoted "h" in the Athena Analyst Guide.)
        }

        $ps define force.volatility ::projectlib::rgain 1.0 {
            Dial that controls the affect of neighborhood volatility
            on the security of each group in the neighborhood.  Set to 0
            to ignore volatility altogether.  Must be no less than 0.
            (This value is denoted "v" in the Athena Analyst Guide.)
        }

        $ps subset force.demeanor {
            Dial that determines the effect of demeanor on a group's
            force.  Must be no less than 0; set to 1.0 if demeanor should
            have no effect.
        }

        foreach {name value} {
            APATHETIC  0.3
            AVERAGE    1.0
            AGGRESSIVE 1.5
        } {
            $ps define force.demeanor.$name ::projectlib::rgain $value "
                Dial that determines the effect of $name demeanor 
                on a group's force.  Must be no less than 0; set to 1.0 
                if demeanor should have no effect.
            "
        }

        $ps subset force.forcetype {
            For units belonging to force groups, this set of dials
            determines the contribution to force of each person in the unit,
            based on the group's force type.  Must be no less 
            than 0.
        }

        foreach {name value} {
            REGULAR       25
            PARAMILITARY  15
            POLICE        10
            IRREGULAR     20
            CRIMINAL       8
        } {
            $ps define force.forcetype.$name ::projectlib::rgain $value "
                This dial determines the contribution to force of each
                person in a unit, where that unit belongs to an
                force group of force type $name.
                Must be no less than 0.
            "
        }

        $ps subset force.orgtype {
            For units belonging to organization groups, this set of dials
            determines the contribution to force of each person in the unit,
            based on the group's organization type.  Must be no less 
            than 0.
        }

        foreach {name value} {
            NGO 0.0
            IGO 0.0
            CTR 2.0
        } {
            $ps define force.orgtype.$name ::projectlib::rgain $value "
                This dial determines the contribution to force of each
                person in a unit, where that unit belongs to an
                organization group of organization type $name.
                Must be no less than 0.
            "
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
        $ps save $defaultsFile
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

