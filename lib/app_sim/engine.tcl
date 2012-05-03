#-----------------------------------------------------------------------
# TITLE:
#    engine.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_engine(n) Engine Ensemble
#
#    This module is responsible for initializing and invoking the
#    model-oriented code at scenario start and at time advances.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# engine ensemble

snit::type engine {
    pragma -hastypedestroy 0 -hasinstances 0


    #-------------------------------------------------------------------
    # Public Type Methods

    # init
    #
    # Initializes the engine and its submodules, to the extent that
    # this can be done at application initialization.  True initialization
    # happens when scenario preparation is locked, when 
    # the simulation state moves from PREP to PAUSED.

    typemethod init {} {
        log normal engine "init"

        # FIRST, initialize the event queue
        # TBD: wart needed.  Register only in main thread.
        eventq init ::rdb
        scenario register ::marsutil::eventq

        # NEXT, create an instance of URAM and register it as a saveable
        # TBD: wart needed.  Register only in main thread.
        uram ::aram \
            -rdb          ::rdb                   \
            -loadcmd      [mytypemethod LoadAram] \
            -undo         on                      \
            -logger       ::log                   \
            -logcomponent "aram"


        scenario register [list ::aram saveable]

        # NEXT, initialize the simulation modules
        econ      init ;# TBD: Proxy needed, but not a simple forwarding proxy.
        situation init ;# TBD: What initialization is needed here?

        log normal engine "init complete"
    }

    # LoadAram uram
    #
    # Loads scenario data into URAM when it's initialized.
    #
    # TBD: Set natural levels!

    typemethod LoadAram {uram} {
        $uram load causes {*}[ecause names]

        $uram load actors {*}[rdb eval {
            SELECT a FROM actors
            ORDER BY a
        }]

        $uram load nbhoods {*}[rdb eval {
            SELECT n FROM nbhoods
            ORDER BY n
        }]

        $uram load prox {*}[rdb eval {
            SELECT m, n, proximity 
            FROM nbrel_mn
            ORDER BY m, n
        }]

        $uram load civg {*}[rdb eval {
            SELECT g,n,basepop FROM civgroups_view
            ORDER BY g
        }]

        $uram load otherg {*}[rdb eval {
            SELECT g,gtype FROM groups
            WHERE gtype != 'CIV'
            ORDER BY g
        }]

        $uram load hrel {*}[rdb eval {
            SELECT f, g, base FROM hrel_view
            ORDER BY f, g
        }]

        $uram load vrel {*}[rdb eval {
            SELECT g, a, base FROM vrel_view
            ORDER BY g, a
        }]

        $uram load sat {*}[rdb eval {
            SELECT g, c, base, saliency
            FROM sat_gc
            ORDER BY g, c
        }]

        $uram load coop {*}[rdb eval {
            SELECT f, g, coop0 FROM coop_fg
            ORDER BY f, g
        }]
    }


    # start
    #
    # Engine activities on simulation start.

    typemethod start {} {
        # FIRST, Set up the attitudes model: initialize URAM and relate all
        # existing MADs to URAM drivers.
        aram init -reload

        # NEXT, set natural attitude levels, so that they will look right
        # when the simulation pauses at t=0.
        # TBD.  Also, this might need to go further down (e.g., we need
        # security to compute SFT's natural level.)

        # NEXT, initialize all modules, and do basic analysis, in preparation
        # for executing the on-lock tactics.

        personnel start      ;# Initial deployments and base units.
        demog start          ;# Computes population statistics
        service start        ;# Populates service tables.
        nbstat start         ;# Computes initial security and coverage
        control_model start  ;# Computes initial support and influence
        econ start           ;# Initializes the econ CGE.

        # NEXT, Advance time to 0.  What we get here is a pseudo-tick,
        # in which we execute the on-lock strategy and provide transient
        # effects to URAM.

        strategy start       ;# Execute on-lock strategies
        eventq advance 0     ;# Execute any scheduled orders.

        # NEXT, do analysis and assessment, of transient effects only.
        # There will be no attrition and no shifts in neighborhood control.

        demog analyze pop
        ensit assess
        nbstat analyze
        control_model analyze
        actsit assess
        service assess
        set econOK [econ tock]
        if {$econOK} {
            demog analyze econ
        }
        demsit assess

        # NEXT, advance URAM to time 0, applying the transient inputs
        # entered above.
        aram advance 0

        # NEXT,  Save time 0 history!
        hist tick
        hist econ
    }


    # tick
    #
    # This command is executed at each simulation time tick.
    # A tick is one week long.

    typemethod tick {} {
        # FIRST, advance time by one tick.
        simclock tick
        notifier send $type <Time>
        log normal engine "Tick [simclock now]"

        # NEXT, execute strategies; this changes the situation
        # on the ground.  It may also schedule events to be executed
        # immediately.
        profile strategy tock

        # NEXT, execute eventq events
        profile eventq advance [simclock now]

        # FIRST, do analysis and assessment
        profile demog analyze pop
        profile ensit assess
        profile nbstat analyze
        profile misc_rules assess
        profile control_model analyze
        profile actsit assess
        profile service assess
        profile aam assess

        if {[simclock now] % [parmdb get econ.ticksPerTock] == 0} {
            set econOK [profile econ tock]

            if {$econOK} {
                profile demog analyze econ
            }
        }

        profile demsit assess
        profile control_model assess

        # NEXT, advance URAM, first giving it the latest population data
        # and natural attitude levels.
        aram update pop {*}[rdb eval {
            SELECT g,population 
            FROM demog_g
        }]

        # TBD: Update natural levels!
        profile aram advance [simclock now]


        # NEXT, save the history for this tick.
        profile hist tick

        if {[simclock now] % [parmdb get econ.ticksPerTock] == 0} {
            if {$econOK} {
                profile hist econ
            }
        }
    }

    # analysis
    #
    # Analysis to be done when restarting simulation, to update
    # data values used by strategy conditions.

    typemethod analysis {} {
        profile demog   analyze pop
        profile nbstat  analyze
        profile control_model analyze
    }

}



