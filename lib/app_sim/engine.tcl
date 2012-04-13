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

        # NEXT, create ARAM and register it as a saveable
        # TBD: wart needed.  Register only in main thread.
        gram ::aram \
            -clock        ::simclock              \
            -rdb          ::rdb                   \
            -logger       ::log                   \
            -logcomponent "aram"                  \
            -loadcmd      [mytypemethod LoadAram]

        scenario register ::aram

        # NEXT, initialize the simulation modules
        econ      init ;# TBD: Proxy needed, but not a simple forwarding proxy.
        situation init ;# TBD: What initialization is needed here?

        log normal engine "init complete"
    }

    # LoadAram gram
    #
    # Loads scenario data into ARAM when it's initialized.

    typemethod LoadAram {gram} {
        $gram load nbhoods {*}[rdb eval {
            SELECT n FROM nbhoods
            ORDER BY n
        }]

        $gram load nbrel {*}[rdb eval {
            SELECT m, n, proximity, 0.0 
            FROM nbrel_mn
            ORDER BY m,n
        }]

        $gram load civg {*}[rdb eval {
            SELECT g,n,basepop FROM civgroups_view
            ORDER BY g
        }]

        $gram load civrel {*}[rdb eval {
            SELECT R.f,
                   R.g,
                   R.rel
            FROM rel_view AS R
            JOIN civgroups AS F ON (F.g = R.f)
            JOIN civgroups as G on (G.g = R.g)
            ORDER BY R.f, R.g
        }]

        $gram load concerns {*}[rdb eval {
            SELECT c FROM concerns
            ORDER BY c
        }]

        $gram load sat {*}[rdb eval {
            SELECT g, c, sat0, saliency
            FROM sat_gc
            ORDER BY g, c
        }]

        $gram load frcg {*}[rdb eval {
            SELECT g FROM frcgroups
            ORDER BY g
        }]

        $gram load frcrel {*}[rdb eval {
            SELECT R.f,
                   R.g,
                   R.rel
            FROM rel_view AS R
            JOIN frcgroups AS F ON (F.g = R.f)
            JOIN frcgroups as G on (G.g = R.g)
            ORDER BY R.f, R.g
        }]

        $gram load coop {*}[rdb eval {
            SELECT f,
                   g,
                   coop0
            FROM coop_fg
            ORDER BY f, g
        }]
    }


    # start
    #
    # Engine activities on simulation start.

    typemethod start {} {
        # Set up the attitudes model: initialize GRAM and relate all
        # existing MADs to GRAM drivers.
        aram      init -reload
        mad       start

        # Next, set up the status quo, as required by strategy execution.
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
       
        personnel     start
        demog         analyze pop
        service       start
        nbstat        start
        control_model start
        econ          start 

        # Execute the actor's strategies at time 0 
        hist tock
        strategy start

        # Compute the new state of affairs, given the agent's
        # decisions at time 0.
        demog          analyze pop
        nbstat         analyze
        control_model  analyze
        demog          analyze econ

        # NEXT, execute events scheduled at time 0, if any.
        eventq advance 0
    }


    # tick
    #
    # This command is executed at each simulation time tick.

    typemethod tick {} {
        # FIRST, advance models
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

        # NEXT, advance GRAM (if t > 0); but first give it the latest
        # population data.
        #
        # TBD: This mechanism is nuts.
        if {[simclock now] > 0} {
            aram update population {*}[rdb eval {
                SELECT n,g,population 
                FROM demog_g
                JOIN civgroups USING (g)
            }]

            profile aram advance
        }

        # NEXT, save the history for this tick.
        profile hist tick

        if {[simclock now] % [parmdb get econ.ticksPerTock] == 0} {
            profile hist econ
        }

        # NEXT, advance time one tick.
        simclock tick

        # TBD: Need to notify ::sim
        notifier send $type <Time>
        log normal engine "Tick [simclock now]"
        
        # NEXT, execute eventq events
        profile eventq advance [simclock now]

        # NEXT, assess actor influence and execute actor strategies.
        profile control_model assess
        profile hist tock
        profile strategy tock
    }

    # pause
    #
    # Engine actions when the simulation pauses

    typemethod pause {} {
        # Update demographics and nbstats, in case the user
        # wants to look at them.
        profile demog   analyze pop
        profile nbstat  analyze
        profile control_model analyze
    }

}



