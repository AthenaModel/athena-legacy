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
        profile uram ::aram \
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


    # start
    #
    # Engine activities on simulation start.

    typemethod start {} {
        # FIRST, Set up the attitudes model: initialize URAM and relate all
        # existing MADs to URAM drivers.
        profile aram init -reload

        # NEXT, initialize all modules, and do basic analysis, in preparation
        # for executing the on-lock tactics.

        profile demog start          ;# Computes population statistics
        profile personnel start      ;# Initial deployments and base units.
        profile service start        ;# Populates service tables.
        profile nbstat start         ;# Computes initial security and coverage
        profile control_model start  ;# Computes initial support and influence

        # NEXT, Advance time to 0.  What we get here is a pseudo-tick,
        # in which we execute the on-lock strategy and provide transient
        # effects to URAM.

        profile strategy start       ;# Execute on-lock strategies
        profile econ start           ;# Initializes the econ model taking 
                                      # into account on-lock strategies
        profile eventq advance 0     ;# Execute any scheduled orders.

        # NEXT, do analysis and assessment, of transient effects only.
        # There will be no attrition and no shifts in neighborhood control.

        profile demog stats
        profile ensit assess
        profile nbstat analyze
        profile control_model analyze
        profile actsit_rules assess
        profile service assess
        set econOK [econ tock]
        if {$econOK} {
            profile demog econstats
        }
        profile demsit assess

        # NEXT, set natural attitude levels for those attitudes whose
        # natural level varies with time.
        $type SetNaturalLevels

        # NEXT, advance URAM to time 0, applying the transient inputs
        # entered above.
        profile aram advance 0

        # NEXT,  Save time 0 history!
        profile hist tick
        profile hist econ
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

        # NEXT, allow the population to grow or shrink
        # according to its growth rate.
        profile demog growth
        profile demog stats
        
        # NEXT, execute strategies; this changes the situation
        # on the ground.  It may also schedule events to be executed
        # immediately.
        profile strategy tock

        # NEXT, execute eventq events
        profile eventq advance [simclock now]

        # FIRST, do analysis and assessment
        profile demog stats
        profile ensit assess
        profile nbstat analyze
        profile misc_rules assess
        profile control_model analyze
        profile actsit_rules assess
        profile service assess
        profile aam assess

        if {[simclock now] % [parmdb get econ.ticksPerTock] == 0} {
            set econOK [profile econ tock]

            if {$econOK} {
                profile demog econstats
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

        profile $type SetNaturalLevels
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
        profile demog stats
        profile nbstat analyze
        profile control_model analyze
    }

    #-------------------------------------------------------------------
    # URAM-related routines.
    #
    # TBD: Consider defining an ::aram module that wraps an instance
    # of ::uram.  These calls would naturally belong there.
    
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
            SELECT f, g, base, nat FROM hrel_view
            ORDER BY f, g
        }]

        $uram load vrel {*}[rdb eval {
            SELECT g, a, base, nat FROM vrel_view
            ORDER BY g, a
        }]

        # Note: only SFT has a natural level, and it can't be computed
        # until later.
        $uram load sat {*}[rdb eval {
            SELECT g, c, base, 0.0, saliency
            FROM sat_gc
            ORDER BY g, c
        }]

        # Note: COOP natural levels are not being computed yet.
        $uram load coop {*}[rdb eval {
            SELECT f, g, base, base FROM coop_fg
            ORDER BY f, g
        }]
    }

    # SetNaturalLevels
    #
    # This routine sets the natural level for all attitude curves whose
    # natural level changes over time.
    
    typemethod SetNaturalLevels {} {
        # Set the natural level for all SFT curves.
        set Z [parm get attitude.SFT.Znatural]

        set values [list]

        rdb eval {
            SELECT g, security
            FROM civgroups
            JOIN force_ng USING (g,n)
        } {
            lappend values $g SFT [zcurve eval $Z $security]
        }

        aram sat cset {*}$values
    }
}



