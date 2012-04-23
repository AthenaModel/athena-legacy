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
            SELECT f, g, rel FROM rel_view
            ORDER BY f, g
        }]

        # TBD: vrels need additional work; for now, all 0.0.
        $uram load vrel {*}[rdb eval {
            SELECT g, a, 0.0
            FROM groups JOIN actors
            ORDER BY g, a
        }]

        $uram load sat {*}[rdb eval {
            SELECT g, c, sat0, saliency
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
        aram      init -reload
        # TBD: Update natural levels

        # NEXT, set up the status quo.
        # 
        # * [personnel start] creates units for all status quo
        #   CIV/FRC/ORG personnel.  
        #
        # * [demog analyze pop] initializes the demographics tables; in 
        #   the status quo there has been no attrition and no 
        #   displacements.
        #
        # * [service start] initializes the service tables,
        #   and computes the actual and expected level of service.
        #
        # * [nbstat start] computes the security levels and activity
        #   coverage.
        #
        # * [control_model start] initializes vertical relationships, actor
        #   support and influence, and neighborhood control, based on
        #   the status quo data.
       
        # TBD: Look through these; now that the on-lock strategy execution
        # doesn't depend on conditions, we might be doing more than we
        # need to do.
        personnel     start
        demog         analyze pop
        service       start
        nbstat        start
        control_model start
        econ          start 

        # NEXT, Enter time 0: Execute the on-lock strategy, and execute
        # any scheduled events (scheduled orders, really).
        strategy start
        eventq advance 0

        # NEXT, Compute the new state of affairs, given the agent's
        # decisions at time 0.
        demog          analyze pop
        nbstat         analyze
        control_model  analyze
        demog          analyze econ

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
        profile control_model analyze
        profile actsit assess
        profile service assess attitudes
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



