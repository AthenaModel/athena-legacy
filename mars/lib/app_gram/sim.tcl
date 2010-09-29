#-----------------------------------------------------------------------
# FILE: sim.tcl
#
# Simulation Manager
#
# PACKAGE:
#   app_gram(n) -- mars_gram(1) implementation package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#   Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module: sim
#
# The sim module manages the simulation proper: the gramdb(5)
# database input, the initialization of the GRAM module, the passage
# of simulation time, and so forth.  Most of the <executive> commands
# relating to the simulation are defined here as well.

snit::type sim {
    pragma -hasinstances no
    
    #-------------------------------------------------------------------
    # Group: Notifier Events
    
    # Notifier Event: Load
    #
    # A new gramdb(5) database has been loaded.  A <Reset> is also sent.
    
    # Notifier Event: Reset
    #
    # The simulation has changed in some basic way; all dependent modules
    # should reset themselves.
    
    # Notifier Event: Unload
    #
    # The gramdb(5) data has been deleted and the simulation uninitialized.
    # A <Reset> is also sent.
    
    # Notifier Event: Time
    #
    # Simulation time has changed.

    #-------------------------------------------------------------------
    # Group: Type Components

    # Type Component: ram
    #
    # The current gram(n) instance, or <NullGram> if no gram(n)
    # instance currently exists.
    
    typecomponent ram

    #-------------------------------------------------------------------
    # Group: Type Variables
    
    # Type variable: info
    #
    # An array of information about the state of the simulation.  The
    # keys are as follows.
    #
    #   dbloaded - 1 if a gramdb(5) is loaded, and 0 otherwise
    #   dbfile   - Name of the loaded gramdb(5) file, or "" if none.
    
    typevariable info -array {
        dbloaded   0
        dbfile     ""
    }

    #-------------------------------------------------------------------
    # Group: Initialization

    # Type method: init
    #
    # Initializes the module.  This is a simple task, as most things
    # can't be done until the user specifies a gramdb(5) file, and
    # we don't have it yet.  It _does_ set the ram component to
    # <NullGram>, so that <executive> commands delegated to GRAM
    # will be rejected with a user-friendly error message.
    
    typemethod init {} {
        log normal sim "Initializing..."
        
        # Initialize the GRAM component to NullGram, so that
        # commands delegated to it are handled before it is
        # created.
        
        set ram [myproc NullGram]
    }

    #-------------------------------------------------------------------
    # Group: Scenario Management

    # Type method: load 
    #
    # Loads the _dbfile_ and initializes GRAM.  Sends <Load> and <Reset>.
    #
    # Syntax:
    #   sim load _dbfile_
    #
    #   dbfile - The name of a gramdb(5) database file.

    typemethod load {dbfile} {
        # FIRST, clean up the old simulation data.
        sim unload
        
        # NEXT, open a new log.
        log newlog load

        # NEXT, load the dbfile
        log normal sim "Loading gramdb $dbfile"
        gramdb loadfile $dbfile ::rdb
        set info(dbfile) $dbfile

        # NEXT, set the simulation clock
        simclock reset
        simclock configure \
            -t0   "100000ZJAN10"            \
            -tick [parmdb get sim.tickSize]

        # NEXT, create and initialize the GRAM.
        if {[catch {sim CreateGram} result]} {
            # Save the stack trace while we clean up
            set errInfo $::errorInfo
            sim unload

            return -code error -errorinfo $errInfo $result
        }

        set info(dbloaded) 1
        log normal sim "Loaded gramdb $dbfile"

        notifier send ::sim <Reset>
        notifier send ::sim <Load>
        return
    }

    # Type method: CreateGram
    #
    # Creates the gram(n) object, and initializes it using the currently
    # loaded gramdb(5) data.
    
    typemethod CreateGram {} {
        set ram [gram ::ram \
                     -clock        ::simclock                       \
                     -rdb          ::rdb                            \
                     -logger       ::log                            \
                     -logcomponent gram                             \
                     -loadcmd      {::simlib::gramdb loader ::rdb}]
        $ram init
    }
    
    # Type method: reset
    #
    # Reinitializes the simulation, setting the simulation time back to
    # 0.  Sends <Reset>.
    
    typemethod reset {} {
        simclock reset
        simclock configure \
            -t0   "100000ZJAN10"            \
            -tick [parmdb get sim.tickSize]

        log newlog reset
        $ram init

        notifier send ::sim <Reset>
        return 
    }

    # Type method: unload
    #
    # Deletes the simulation objects, leaving the simulation
    # uninitialized.  Sends <Reset> and <Unload>
    
    typemethod unload {} {
        catch {$ram destroy}

        set ram [myproc NullGram]

        set info(dbloaded) 0
        set info(dbfile)   ""

        rdb clear
        rdb eval [readfile [file join $::app_gram::library gui_views.sql]]

        notifier send ::sim <Reset>
        notifier send ::sim <Unload>
    }
    
    #-------------------------------------------------------------------
    # Group: Simulation Control

    # Type method: step
    #
    # Runs the simulation forward one timestep.  Sends <Time>.
    #
    # Syntax:
    #   sim step _?ticks?_
    #
    #   ticks - Some positive number of simulation ticks, defaulting
    #           to sim.stepsize.

    typemethod step {{ticks ""}} {
        if {$ticks eq ""} {
            set ticks [parmdb get sim.stepsize]
        }
        
        simclock step $ticks
        $ram advance

        notifier send ::sim <Time>
        return
    }

    # Type method: run
    #
    # Lets the simulation run until the specified zulu-time, one
    # <step> at a time.  Sends <Time> after each step.
    #
    # Syntax:
    #   sim run _zulutime_
    #
    #   zulutime - A simulation time expressed as a Zulu-time string.
    
    typemethod run {zulutime} {
        set endTime [simclock fromZulu $zulutime]
        set ticks [parmdb get sim.stepsize]
    
        if {$endTime <= [simclock now]} {
            error "Not in future: '$zulutime'"
        }

        while {[simclock now] <= $endTime} {
            simclock step $ticks

            $ram advance
            notifier send ::sim <Time>
        }

        return
    }
    
    #-------------------------------------------------------------------
    # Group: Queries
    
    # Type method: dbfile 
    #
    # Returns the name of the loaded gramdb(5) file, or "" if not
    # <dbloaded>.

    typemethod dbfile {} {
        if {$info(dbloaded)} {
            return $info(dbfile)
        } else {
            return ""
        }
    }

    # Type method: dbloaded
    #
    # Returns 1 if GRAM is initialized with a database, and
    # 0 otherwise.
    
    typemethod dbloaded {} {
        return $info(dbloaded)
    }

    # Type method: now
    #
    # Returns the current simulation time (plus the _offset_) 
    # as a Zulu-time string.  If not <dbloaded>, returns "".
    #
    # Syntax:
    #   sim now _?offset?_
    #
    # offset - An offset in integer ticks; defaults to 0.

    typemethod now {{offset 0}} {
        # Do we have a scenario?
        if {$info(dbloaded)} {
            # Convert the simulation time to zulu-time.
            return [simclock asZulu $offset]
        } else {
            return ""
        }
    }

    #-------------------------------------------------------------------
    # Group: GRAM Executive Commands
    #
    # These routines are the implementations for GRAM-related
    # <executive> commands.  They are declared here, rather
    # than in <executive>, because they depend on the <ram> component.
    
    # Delegated type method: dump *
    #
    # The "dump" family of subcommands is delegated to <ram> as is.
    
    delegate typemethod {dump *} to ram  using {%c dump %m}

    # Type method: cancel
    #
    # Cancels the effects of a gram(n) _driver_ given its ID.
    # If -delete is specified, deletes the driver completely;
    # otherwise, it is retained but is marked deleted.
    #
    # Syntax:
    #   sim cancel _driver_ ?-delete?
    #
    #   driver - The gram(n) driver ID

    typemethod cancel {driver {option ""}} {
        if {![$ram driver exists $driver]} {
            error "Unknown driver: \"$driver\""
        }
        
        if {$option ni {"" "-delete"}} {
            error "Unknown option: $option"
        }

        $ram cancel $driver $option
    }

    
    # Type method: coop adjust
    #
    # Adjusts the specified cooperation level by the specified
    # amount.  If -driver is specified, the adjustment is associated
    # with the specified driver; otherwise, a new driver ID is assigned
    # automatically.
    #
    # Syntax:
    #   sim coop adjust _n f g mag ?options...?_
    #
    #   n   - The targeted neighborhood, or "*"
    #   f   - The targeted civ group, or "*"
    #   g   - The targeted frc group, or "*"
    #   mag - magnitude (qmag)
    #
    # Options:
    # -driver driver - A gram(n) driver ID

    typemethod "coop adjust" {n f g mag args} {
        set driver [sim GetDriver args]

        if {[llength $args] > 0} {
            error "Unknown option: [lshift args]"
        }

        $ram coop adjust $driver $n $f $g $mag
    }

    # Type method: coop level
    #
    # Schedule a cooperation level input at the specified time,
    # which defaults to now.
    #
    # Syntax:
    #   sim coop level _n f g limit days ?options?_
    #
    #   n     - The targeted neighborhood, or "*"
    #   f     - The targeted civilian group
    #   g     - The targeted force group
    #   limit - Nominal magnitude (qmag)
    #   days  - Realization time in days (qduration)
    #
    # Options: 
    #   -driver driver  - Driver ID; defaults to next ID
    #   -cause cause    - Sets the cause for this input.
    #   -s factor       - "here" multiplier, defaults to 1
    #   -p factor       - "near" indirect effects multiplier, defaults to 0
    #   -q factor       - "far" indirect effects multiplier, defaults to 0
    #   -zulu zulu      - Start time, as a zulu-time
    #   -tick ticks     - Start time, in ticks

    typemethod "coop level" {n f g limit days args} {
        set driver [sim GetDriver args]
        set ts     [sim GetStartTime args]

        $ram coop level $driver $ts $n $f $g $limit $days {*}$args

        return
    }

    # Type method: coop slope
    #
    # Schedule a cooperation slope input at the specified time, which
    # defaults to now.
    #
    # Syntax:
    #   sim coop slope _n f g slope limit ?options...?_
    #
    #   n     - The targeted neighborhood, or "*"
    #   f     - The targeted civilian group
    #   g     - The targeted force group
    #   slope - change/day (qmag)
    #
    # Options: 
    #   -driver driver  - Driver ID; defaults to next ID
    #   -s factor       - "here" multiplier, defaults to 1
    #   -p factor       - "near" indirect effects multiplier, defaults to 0
    #   -q factor       - "far" indirect effects multiplier, defaults to 1
    #   -zulu zulu      - Start time, as a zulu-time
    #   -tick ticks     - Start time, in ticks

    typemethod "coop slope" {n f g slope args} {
        set driver [sim GetDriver args]
        set ts     [sim GetStartTime args]

        $ram coop slope $driver $ts $n $f $g $slope {*}$args

        return
    }

    # Type method: sat adjust
    #
    # Adjusts the specified satisfaction level by the specified amount.
    # If -driver is specified, the adjustment is associated
    # with the specified driver; otherwise, a new driver ID is assigned
    # automatically.
    #
    # Syntax:
    #   sim sat adjust _n g c mag ?options?_
    #
    #   n   - The targeted neighborhood, or "*"
    #   g   - The targeted group, or "*"
    #   c   - The affected concern, or "*"
    #   mag - magnitude (qmag)
    #
    # Options:
    #   -driver driver  - Driver ID.  Defaults to next ID.

    typemethod "sat adjust" {n g c mag args} {
        # FIRST, get the Driver ID
        set driver [sim GetDriver args]

        if {[llength $args] > 0} {
            error "Unknown option: [lshift args]"
        }

        $ram sat adjust $driver $n $g $c $mag
    }

    # Type method: sat level 
    #
    # Schedule a satisfaction level input at the specified time,
    # which defaults to now.
    #
    # Syntax:
    #   sim sat level _n g c limit days ?options?_
    #
    #   n     -  The targeted neighborhood
    #   g     -  The targeted group
    #   c     -  The affected concern
    #   limit -  Nominal magnitude (qmag)
    #   days  -  Realization time in days (qduration)
    #
    # Options: 
    #   -driver driver  - Driver ID; defaults to next ID
    #   -s factor       - "here" multiplier, defaults to 1
    #   -p factor       - "near" indirect effects multiplier, defaults to 0
    #   -q factor       - "far" indirect effects multiplier, defaults to 0
    #   -zulu zulu      - Start time, as a zulu-time
    #   -tick ticks     - Start time, in ticks

    typemethod "sat level" {n g c limit days args} {
        set driver [sim GetDriver args]
        set ts     [sim GetStartTime args]

        $ram sat level $driver $ts $n $g $c $limit $days {*}$args

        return
    }

    # Type method: sat slope
    #
    # Schedule a satisfaction slope input at the specified time,
    # which defaults to now.
    #
    # Syntax:
    #   sim sat slope _n g c slope ?options...?_
    #
    #   n     - The targeted neighborhood
    #   g     - The targeted group
    #   c     - The affected concern
    #   slope - change/day (qmag)
    #
    # Options: 
    #   -driver driver  - Driver ID; defaults to next ID
    #   -s factor       - "here" multiplier, defaults to 1
    #   -p factor       - "near" indirect effects multiplier, defaults to 0
    #   -q factor       - "far" indirect effects multiplier, defaults to 0
    #   -zulu zulu      - Start time, as a zulu-time
    #   -tick ticks     - Start time, in ticks

    typemethod "sat slope" {n g c slope args} {
        set driver [sim GetDriver args]
        set ts     [sim GetStartTime args]

        $ram sat slope $driver $ts $n $g $c $slope {*}$args

        return
    }
    
    #-------------------------------------------------------------------
    # Group: Utility Routines

    # Type method: GetDriver
    #
    # Plucks -driver from an option/value list (if present).
    # If set, validates it; otherwise, generates a new Driver ID.
    # Returns the Driver ID.
    #
    # Syntax:
    #   sim GetDriver _argvar_
    #
    #   argvar - Name of a variable containing an option/value list.
    #
    # Options:
    #   -driver driver    - A GRAM driver ID

    typemethod GetDriver {argvar} {
        upvar $argvar arglist

        set driver [from arglist -driver ""]

        if {$driver eq ""} {
            set driver [$ram driver add]
        } else {
            $ram driver validate $driver
        }

        return $driver
    }
    
    # Type method: GetStartTime
    #
    # Plucks the start time options and their values from
    # the argument variable and validates them.
    #
    # Syntax:
    #   sim GetStartType _argvar_
    #
    #   argvar - Name of a variable containing an option/value list.
    #
    # Options:
    #   -zulu zulutime - A valid zulu-time
    #   -tick ticks    - A simulation time in ticks
    #
    # If either option is given, returns the number of ticks.
    # Otherwise, returns <now>.

    typemethod GetStartTime {argvar} {
        upvar $argvar arglist

        set zulu [from arglist -zulu ""]

        if {$zulu ne ""} {
            set ts [simclock fromZulu $zulu]
        } else {
            set ts [from arglist -tick [simclock now]]
        }

        return $ts
    }


    # Proc: NullGram
    #
    # Handles typemethods delegated to <ram> when not <dbloaded> by
    # throwing a user-readable error.  Any arguments are ignored.
    
    proc NullGram {args} {
        error "simulation uninitialized"
    }
}





