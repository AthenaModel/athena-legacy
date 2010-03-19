#-----------------------------------------------------------------------
# TITLE:
#    parm.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1) model parameters
#
#    The module delegates most of its function to parmdb(n).
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# parm

snit::type parm {
    # Make it a singleton
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Typecomponents

    typecomponent ps ;# parmdb(n), really

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

        log detail parm "init"

        # FIRST, initialize parmdb(n), and delegate to it.
        parmdb init

        set ps ::projectlib::parmdb

        # NEXT, register to receive simulation state updates.
        notifier bind ::sim <State> $type [mytypemethod SimState]

        # FINALLY, register this type as a saveable
        scenario register ::parm

        log detail parm "init complete"
    }

    #-------------------------------------------------------------------
    # Event Handlers

    # SimState
    #
    # This is called when the simulation state changes, e.g., from
    # PREP to RUNNING.  It locks and unlocks significant parameters.

    typemethod SimState {} {
        if {[sim state] eq "PREP"} {
            parmdb unlock *
        } else {
            parmdb lock sim.tickSize
            parmdb lock aam.ticksPerTock
            parmdb lock econ.ticksPerTock
            parmdb lock econ.baseUnemployment
        }
    }



    #-------------------------------------------------------------------
    # Executive Commands
    #
    # The following type methods are intended to implement parm-related
    # executive commands.  They are implemented as subcommands of
    # "parm exec" to distinguish them from the standard commands with
    # the same names.

    # exec import filename
    #
    # filename   A .parmdb file
    #
    # Imports the .parmdb file

    typemethod {exec import} {filename} {
        order send cli PARM:IMPORT filename $filename
    }


    # exec list ?pattern?
    #
    # pattern    A glob pattern
    #
    # Lists all parameters with their values, or those matching the
    # pattern.  If none are found, throws an error.

    typemethod {exec list} {{pattern *}} {
        set result [$ps list $pattern]

        if {$result eq ""} {
            error "No matching parameters"
        }

        return $result
    }


    # exec reset 
    #
    # Resets all parameters to defaults.

    typemethod {exec reset} {} {
        order send cli PARM:RESET
    }


    # exec set parm value
    #
    # parm     A parameter name
    # value    A value
    #
    # Sets the parameter's value, using PARM:SET

    typemethod {exec set} {parm value} {
        order send cli PARM:SET parm $parm value $value
    }


    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate import filename
    #
    # filename     A parameter file
    #
    # Attempts to import the parameter into the RDB.  This command is
    # undoable.

    typemethod {mutate import} {filename} {
        # FIRST, get the undo information
        set undo [mytypemethod restore [$ps checkpoint]]

        # NEXT, try to load the parameters
        $ps load $filename

        # NEXT, log it.
        log normal parm "Imported Parameters: $filename"
        
        app puts "Imported Parameters: $filename"

        # NEXT, Return the undo script
        return $undo
    }


    # mutate reset
    #
    # Resets the values to the current defaults, reading them from the
    # disk as necessary.

    typemethod {mutate reset} {} {
        # FIRST, get the undo information
        set undo [mytypemethod restore [$ps checkpoint]]

        # NEXT, get the names and values of any locked parameters
        set locked [$ps locked]

        foreach parm $locked {
            set saved($parm) [$ps get $parm]
        }

        $ps unlock *

        # NEXT, try to load the defaults
        $type defaults load

        # NEXT, put the locked parameters back
        set unreset [list]

        foreach parm $locked {
            if {$saved($parm) ne [$ps get $parm]} {
                $ps set $parm $saved($parm)
                lappend unreset $parm
            }
            $ps lock $parm
        }

        # NEXT, log it.
        if {[llength $unreset] == 0} {
            log normal parm "Reset Parameters"
            app puts        "Reset Parameters"
        } else {
            log normal warning \
                "Reset Parameters, except for the following locked parameters\n[join $unreset \n]"

            app puts "Reset Parameters (except for locked parameters, see log)"
        }

        # NEXT, Return the undo script
        return $undo
    }


    # mutate set parm value
    #
    # parm    A parameter name
    # value   A parameter value
    #
    # Sets the value of the parameter, and returns an undo script

    typemethod {mutate set} {parm value} {
        # FIRST, get the undo information
        set undo [mytypemethod mutate set $parm [$ps get $parm]]

        # NEXT, try to set the parameter
        $ps set $parm $value

        # NEXT, return the undo script
        return $undo
    }
}

#-----------------------------------------------------------------------
# Orders: PARM:*

# PARM:IMPORT
#
# Imports the contents of a parmdb file into the scenario.

order define ::parm PARM:IMPORT {
    title "Import Parameter File"

    options -sendstates {PREP RUNNING PAUSED}

    # NOTE: Dialog is not usually used.  Could define a "filepicker"
    # -editcmd, though.
    parm filename   text "Parameter File"
} {
    # FIRST, prepare the parameters
    prepare filename -required 

    returnOnError -final

    # NEXT, validate the parameters
    if {[catch {
        # In this case, simply try it.
        setundo [$type mutate import $parms(filename)]
    } result]} {
        reject filename $result
    }

    returnOnError
}


# PARM:RESET
#
# Imports the contents of a parmdb file into the scenario.

order define ::parm PARM:RESET {
    title "Reset Parameters to Defaults"

    options -sendstates {PREP RUNNING PAUSED}
} {
    returnOnError -final

    # FIRST, try to do it.
    if {[catch {
        # In this case, simply try it.
        setundo [$type mutate reset]
    } result]} {
        reject * $result
    }

    returnOnError
}


# PARM:SET
#
# Sets the value of a parameter.

order define ::parm PARM:SET {
    title "Set Parameter Value"

    options -sendstates {PREP RUNNING PAUSED}

    # NOTE: Dialog is not usually used.
    parm parm   text "Parameter"
    parm value  text "Value"
} {
    # FIRST, prepare the parameters
    prepare parm  -required 
    prepare value -required

    returnOnError -final

    # NEXT, validate the parameters
    if {[catch {
        # In this case, simply try it.
        setundo [$type mutate set $parms(parm) $parms(value)]
    } result]} {
        reject * $result
    }

    returnOnError
}
