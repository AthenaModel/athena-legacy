#-----------------------------------------------------------------------
# TITLE:
#    sim.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Simulation Ensemble
#
#    This module manages the overall simulation, as distinct from the 
#    the purely scenario-data oriented work done by sim(sim).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# sim ensemble

snit::type sim {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent ticker    ;# The timeout(n) instance that makes the
                             # simulation go.

    #-------------------------------------------------------------------
    # Non-checkpointed Type Variables

    # constants -- scalar array
    
    typevariable constants -array {
        ticksize  {1 day}
        startdate 100000ZJAN10
    }

    # speeds -- array of inter-tick delays in milliseconds, by
    #           simulation speed.

    typevariable speeds -array {
        1  10000
        2   5000
        3   3000
        4   2000
        5   1000
        6    600
        7    400
        8    200
        9    100
        10    50
    }

    # info -- scalar info array
    #
    # changed        - 1 if saveable(i) data has changed, and 0 
    #                  otherwise.
    # state          - The current simulation state, a simstate value
    # stoptime       - The time tick at which the simulation should 
    #                  pause, or 0 if there's no limit.
    # speed          - The speed at which the simulation should run.
    #                  (This should probably be saved with the GUI 
    #                  settings.)
    # econOK         - 1 if the econ CGE is converging, and 0 if it is
    #                  diverging.

    typevariable info -array {
        changed        0
        state          PREP
        stoptime       0
        speed          10
        econOK         1
    }

    # trans -- transient data array
    #
    #  buffer  - Buffer used to build up long strings.

    typevariable trans -array {
        buffer {}
    }

    #-------------------------------------------------------------------
    # Singleton Initializer

    # init
    #
    # Initializes the simulation proper, to the extent that this can
    # be done at application initialization.  True initialization
    # happens when scenario preparation is locked, when 
    # the simulation state moves from PREP to PAUSED.

    typemethod init {} {
        log normal sim "init"

        # FIRST, register with scenario(sim) as a saveable
        scenario register $type

        # NEXT, set the simulation state
        set info(state)    PREP
        set info(changed)  0
        set info(stoptime) 0

        order state $info(state)

        # NEXT, configure the simclock.
        # TBD: The tick size and the start date should be parmdb parms.
        simclock configure              \
            -tick $constants(ticksize)  \
            -t0   $constants(startdate)

        # NEXT, create the ticker
        set ticker [timeout ${type}::ticker              \
                        -interval   $speeds($info(speed)) \
                        -repetition yes                  \
                        -command    {profile sim Tick}]

        # NEXT, initialize the event queue
        eventq init ::rdb
        scenario register ::marsutil::eventq

        # NEXT, create ARAM and register it as a saveable
        gram ::aram \
            -clock        ::simclock              \
            -rdb          ::rdb                   \
            -logger       ::log                   \
            -logcomponent "aram"                  \
            -loadcmd      [mytypemethod LoadAram]

        scenario register ::aram

        # NEXT, create a MAM; arrange for it to clear undo info
        # before the scenario is saved.
        mam ::bsystem \
            -rdb ::rdb

        notifier bind ::scenario <Saving> ::bsystem [list ::bsystem edit reset]

        # NEXT, initialize the simulation modules
        econ      init
        situation init


        log normal sim "init complete"
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
            SELECT m, n, proximity, effects_delay 
            FROM nbrel_mn
            ORDER BY m,n
        }]

        $gram load civg {*}[rdb eval {
            SELECT g,n,basepop FROM civgroups
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

    # new
    #
    # Reinitializes the module when a new scenario is created.

    typemethod new {} {
        # FIRST, configure the simclock.
        simclock reset
        simclock configure              \
            -tick $constants(ticksize)  \
            -t0   $constants(startdate)

        # NEXT, clear the event queue
        eventq restart

        # NEXT, clear the belief system
        bsystem clear

        # NEXT, set the simulation status
        set info(changed) 0
        set info(state)   PREP

        $type dbsync
    }

    # restart
    #
    # Reloads snapshot 0, and enters.

    typemethod restart {} {
        sim mutate unlock
    }

    #-------------------------------------------------------------------
    # Snapshot Navigation

    # snapshot first
    #
    # Loads the tick 0 snapshot, which resets the simulation as a 
    # whole to the moment before it first 
    # transitioned from PAUSED to RUNNING.

    typemethod {snapshot first} {} {
        $type LoadSnapshot 0

        return
    }


    # snapshot prev
    #
    # Loads the previous snapshot, if any.

    typemethod {snapshot prev} {} {
        # FIRST, get the tick of the previous snapshot
        set now [simclock now]

        foreach tick [lreverse [scenario snapshot list]] {
            if {$tick < $now} {
                break
            }
        }

        # NEXT, Load the snapshot
        $type LoadSnapshot $tick

        return
    }


    # snapshot next
    #
    # Loads the next snapshot, if any.

    typemethod {snapshot next} {} {
        # FIRST, get the tick of the next snapshot
        set now [simclock now]

        foreach tick [scenario snapshot list] {
            if {$tick > $now} {
                break
            }
        }

        assert {$tick > $now}

        # NEXT, Load the snapshot
        $type LoadSnapshot $tick

        return
    }


    # snapshot last
    #
    # Loads the latest snapshot.

    typemethod {snapshot last} {} {
        set tick [scenario snapshot latest]

        assert {[simclock now] < $tick}

        $type LoadSnapshot $tick

        return
    }

    # LoadSnapshot tick
    #
    # tick        The timestamp of the snapshot to load
    #
    # Loads the snapshot.  If the time now is later than 
    # the latest checkpoint, saves one so that we can return.

    typemethod LoadSnapshot {tick} {
        assert {[sim state] in {PAUSED SNAPSHOT}}

        # FIRST, if the time is greater than the last snapshot, 
        # save one.
        if {[simclock now] > [scenario snapshot latest]} {
            scenario snapshot save
        }

        # NEXT, restore to the tick 
        scenario snapshot load $tick

        # NEXT, PAUSED if we're at the 
        # last snapshot, and SNAPSHOT otherwise.
        if {$tick == [scenario snapshot latest]} {
            $type SetState PAUSED
            log newlog latest
        } else {
            $type SetState SNAPSHOT
            log newlog snapshot
        }

        # NEXT, log the change
        set message \
            "Loaded snapshot [scenario snapshot current] at [simclock asZulu] (tick [simclock now])"

        log normal sim $message
        app puts $message

        # NEXT, resync the app with the RDB
        $type dbsync

        return
    }

    # snapshot enter
    #
    # Re-enters the time-stream as of the current snapshot; purges
    # later snapshots.

    typemethod {snapshot enter} {} {
        # FIRST, must be in SNAPSHOT mode.
        assert {[sim state] eq "SNAPSHOT"}

        # NEXT, purge future snapshots
        set now [simclock now]
        scenario snapshot purge $now

        # NEXT, set state
        $type SetState PAUSED

        # NEXT, log it.
        log newlog latest
        
        set message \
       "Re-entered the timestream at [simclock asZulu] (tick [simclock now])"

        log normal sim $message
        app puts $message

        # NEXT, resync the app with the RDB
        $type dbsync
    }

    #-------------------------------------------------------------------
    # RDB Synchronization

    # dbsync
    #
    # Database synchronization occurs when the RDB changes out from under
    # the application, i.e., brand new scenario is created or
    # loaded.  All application modules must re-initialize themselves
    # at this time.
    #
    # * Non-GUI modules subscribe to the <DbSyncA> event.
    # * GUI modules subscribe to the <DbSyncB> event.
    #
    # This guarantees that the "model" is in a consistent state
    # before the "view" is updated.

    typemethod dbsync {} {
        # FIRST, Sync the simulation
        notifier send $type <DbSyncA>

        # NEXT, Sync the GUI
        notifier send $type <DbSyncB>
        notifier send $type <Time>
        notifier send $type <Speed>
        notifier send $type <State>
    }


    #-------------------------------------------------------------------
    # Speed Control
    #
    # The inter-tick delay controls how fast the sim appears to run.
    # There's no order for this, as it has no effect on the simulation 
    # proper.  It can be set and reset at any time, including when the
    # simulation is running.

    # speed ?speed?
    #
    # speed     The simulation speed, 1 through 10
    #
    # Sets/queries the simulation speed.

    typemethod speed {{speed ""}} {
        if {$speed ne "" && $speed != $info(speed)} {
            require {$speed in [array names speeds]} \
                "Invalid speed: \"$speed\""

            set info(speed) $speed

            set wasScheduled [$ticker isScheduled]
            
            $ticker cancel
            $ticker configure -interval $speeds($info(speed))
            
            if {$wasScheduled} {
                $ticker schedule
            }

            notifier send $type <Speed>
        }

        return $info(speed)
    }

    #-------------------------------------------------------------------
    # Queries

    delegate typemethod now using {::simclock %m}

    # state
    #
    # Returns the current simulation state

    typemethod state {} {
        return $info(state)
    }

    # stoptime
    #
    # Returns the current stop time in ticks

    typemethod stoptime {} {
        return $info(stoptime)
    }

    #-------------------------------------------------------------------
    # Model Sanity Check

    # check onlock ?-report? ?-log?
    #
    # Does a sanity check of the model: can we lock the scenario (leave 
    # PREP for PAUSED?)
    # 
    # Returns 1 if sane and 0 otherwise.  If -report is specified, then 
    # a SCENARIO SANITY ONLOCK report is written.

    typemethod "check onlock" {args} {
        # FIRST, get options.
        array set opts {
            -log    0
            -report 0
        }

        foreach opt $args {
            switch -exact -- $opt {
                -log    -
                -report {
                    set opts($opt) 1
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # NEXT, presume that the model is sane.
        set sane 1

        # NEXT, initialize the buffer
        set trans(buffer) {}

        # NEXT, Require at least one neighborhood:
        if {[llength [nbhood names]] == 0} {
            set sane 0

            $type CheckTopic "No neighborhoods are defined." \
                "At least one neighborhood is required."     \
                "Create neighborhoods on the Map tab."
        }

        # NEXT, verify that neighborhoods are properly stacked
        rdb eval {
            SELECT n, obscured_by FROM nbhoods
            WHERE obscured_by != ''
        } {
            set sane 0

            $type CheckTopic "Neighborhood Stacking Error." \
                "Neighborhood $n is obscured by neighborhood $obscured_by." \
                "Fix the stacking order on the Neighborhoods/Neighborhoods" \
                "tab."
        }

        # NEXT, Require at least one force group
        if {[llength [frcgroup names]] == 0} {
            set sane 0

            $type CheckTopic "No force groups are defined."           \
                "At least one force group is required.  Create force" \
                "groups on the Groups/FrcGroups tab."
        }

        # NEXT, Require that each force group has an actor
        set names [rdb eval {SELECT g FROM frcgroups WHERE a IS NULL}]

        if {[llength $names] > 0} {
            set sane 0

            $type CheckTopic "Some force groups have no owner."      \
                "The following force groups have no owning actor:"   \
                "[join $names {, }].  Assign owning actors to force" \
                "groups on the Groups/FrcGroups tab."
        }

        # NEXT, Require at least one civ group
        if {[llength [civgroup names]] == 0} {
            set sane 0

            $type CheckTopic "No civilian groups are defined."              \
                "At least one civilian group is required.  Create civilian" \
                "groups on the Groups/CivGroups tab."
        }

        # NEXT, Require that each ORG group has an actor
        set names [rdb eval {SELECT g FROM orggroups WHERE a IS NULL}]

        if {[llength $names] > 0} {
            set sane 0

            $type CheckTopic "Some organization groups have no owner."      \
                "The following organization groups have no owning actor:"   \
                "[join $names {, }].  Assign owning actors to" \
                "organization groups on the Groups/OrgGroups tab."
        }

        # NEXT, collect data on groups and neighborhoods
        rdb eval {
            SELECT g,n FROM civgroups
        } {
            lappend gInN($n)  $g
        }

        # NEXT, Every neighborhood must have at least one group
        # TBD: Is this really required?  Can we insist, instead,
        # that at least one neighborhood must have a group?
        foreach n [nbhood names] {
            if {![info exists gInN($n)]} {
                set sane 0

                $type CheckTopic "Neighborhood has no residents"   \
                    "Neighborhood $n contains no civilian groups;" \
                    "at least one is required.  Create civilian"   \
                    "groups and assign them to neighborhoods"      \
                    "on the Groups/CivGroups tab."
            }
        }

        # NEXT, every ensit must reside in a neighborhood
        set ids [rdb eval {
            SELECT s FROM ensits
            WHERE n = ''
        }]

        if {[llength $ids] > 0} {
            set sane 0

            set ids [join $ids ", "]

            $type CheckTopic "Homeless Environmental Situations"           \
                "The following ensits are outside any neighborhood: $ids." \
                "Either add neighborhoods around them on the Map tab,"     \
                "or delete them on the Neighborhoods/EnSits tab."
        }

        # NEXT, you can't have more than one ensit of a type in a 
        # neighborhood.
        rdb eval {
            SELECT count(s) AS count, n, stype
            FROM ensits
            GROUP BY n, stype
            HAVING count > 1
        } {
            set sane 0

            $type CheckTopic "Duplicate Environmental Situations"     \
                "There are duplicate ensits of type $stype in"        \
                "neighborhood $n.  Delete all but one of them on the" \
                "Neighborhoods/EnSits tab."
        }

        # NEXT, there must be at least 1 local consumer; and hence, there
        # must be at least one local civ group with a sap less than 100.

        if {![rdb exists {
            SELECT sap 
            FROM civgroups JOIN nbhoods USING (n)
            WHERE local AND sap < 100
        }]} {
            set sane 0

            $type CheckTopic "No consumers in local economy"             \
                "There are no consumers in the local economy.  At least" \
                "one civilian group in a \"local\" neighborhood"     \
                "needs to have non-subsistence"                          \
                "population.  Add or edit civilian groups on the"    \
                "Groups/CivGroups tab."
        }

        # NEXT, The econ(sim) CGE Cobb-Douglas parameters must sum to 
        # 1.0.  Therefore, econ.f.*.goods and econ.f.*.pop must sum to
        # <= 1.0, since f.else.goods and f.else.pop can be 0.0, and
        # f.*.else must sum to no more than 0.95, so that f.else.else
        # isn't 0.0.

        let sum {
            [parmdb get econ.f.goods.goods] + 
            [parmdb get econ.f.pop.goods]
        }

        if {$sum > 1.0} {
            set sane 0

            $type CheckTopic "Invalid Cobb-Douglas Parameters"           \
                "econ.f.goods.goods + econ.f.pop.goods > 1.0.  However," \
                "Cobb-Douglas parameters must sum to 1.0.  Therefore,"   \
                "the following must be the case:"                        \
                "econ.f.goods.goods + econ.f.pop.goods <= 1.0.  Use the" \
                "\"parm set\" command to edit the parameter values."
        }

        let sum {
            [parmdb get econ.f.goods.pop] + 
            [parmdb get econ.f.pop.pop]
        }

        if {$sum > 1.0} {
            set sane 0
            $type CheckTopic "Invalid Cobb-Douglas Parameters"         \
                "econ.f.goods.pop + econ.f.pop.pop > 1.0.  However,"   \
                "Cobb-Douglas parameters must sum to 1.0.  Therefore," \
                "the following must be the case:"                      \
                "econ.f.goods.pop + econ.f.pop.pop <= 1.0  Use the"    \
                "\"parm set\" command to edit the parameter values."
        }


        let sum {
            [parmdb get econ.f.goods.else] + 
            [parmdb get econ.f.pop.else]
        }

        if {$sum > 0.95} {
            set sane 0
            $type CheckTopic "Invalid Cobb-Douglas Parameters"         \
                "econ.f.goods.pop + econ.f.pop.pop > 1.0.  However,"   \
                "Cobb-Douglas parameters must sum to 1.0.  Also, the " \
                "value of f.else.else cannot be 0.0.  Therefore,"      \
                "the following must be the case:"                      \
                "econ.f.goods.else + econ.f.pop.else <= 0.95  Use the" \
                "\"parm set\" command to edit the parameter values."
        }

        # NEXT, log sanity
        if {$opts(-log)} {
            if {$sane} {
                log normal sim "On-Lock Sanity Check: OK"
            } else {
                log warning sim \
                    "Scenario Sanity Check: FAILED\n$trans(buffer)"
            }
        }

        # NEXT, report on sanity
        if {$opts(-report)} {
            if {$sane} {
                report save                             \
                    -rtype   SCENARIO                   \
                    -subtype SANITY                     \
                    -meta1   ONLOCK                     \
                    -title   "On-Lock Sanity Check: OK" \
                    -text    "The scenario is sane."
            } else {
                report save                                 \
                    -rtype   SCENARIO                       \
                    -subtype SANITY                         \
                    -meta1   ONLOCK                         \
                    -title   "On-Lock Sanity Check: FAILED" \
                    -text    $trans(buffer)

            }
        }

        # NEXT, clear the buffer
        set trans(buffer) ""

        # NEXT, return the result
        return $sane
    }

    # check ontick ?-report?
    #
    # Does an on-tick sanity check of the model: can we advance time?
    # 
    # Returns 1 if sane and 0 otherwise.  If -report is specified, and
    # the check fails, a SCENARIO SANITY ONTICK report is written.

    typemethod "check ontick" {args} {
        # FIRST, get options.
        array set opts {
            -report 0
        }

        foreach opt $args {
            switch -exact -- $opt {
                -report {
                    set opts($opt) 1
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # NEXT, presume that the model is sane.
        set sane 1

        # NEXT, has the econ model been disabled?
        let gotEcon {![parmdb get econ.disable]}

        # NEXT, initialize the buffer
        set trans(buffer) {}

        # NEXT, Some help for the reader
        $type CheckTopic "Sanity Check(s) Failed" {
            One or more of Athena's on-tick sanity checks has failed; the
            entries below give complete details.  Most checks depend on 
            the economic model; hence, setting the "econ.disable" parameter
            to "yes" will disable them and allow the simulation to proceed,
            at the cost of ignoring the economy.  (See "Model Parameters"
            in the on-line help for information on how to browse and
            set model parameters.)
        }

        # NEXT, Check econ CGE convergence.
        if {$gotEcon && !$info(econOK)} {
            set sane 0

            $type CheckTopic "Economy: Diverged" {
                The economic model uses a system of equations called
                a CGE.  The system of equations could not be solved.
                This might be an error in the CGE; alternatively, the
                economy might really be in chaos.
            }
        }

        # NEXT, check a variety of econ result constraints.
        array set cells [econ get]
        array set start [econ getstart]

        if {$gotEcon && $cells(Out::SUM.QS) == 0.0} {
            set sane 0

            $type CheckTopic "Economy: Zero Production" {
                The economy has converged to the zero point, i.e., there
                is no consumption or production, and hence no economy.
                Enter "dump econ In" at the CLI to see the current 
                inputs to the economy; it's likely that there are no
                consumers.
            }
        }

        if {$gotEcon && !$cells(Out::FLAG.QS.NONNEG)} {
            set sane 0

            $type CheckTopic "Economy: Negative Quantity Supplied" {
                One of the QS.i cells has a negative value; this implies
                an error in the CGE.  Enter "dump econ" at the CLI to
                see the full list of CGE outputs.  Consider setting
                the "econ.disable" parameter to "yes", since the
                economic model is clearly malfunctioning.
            }
        }

        if {$gotEcon && !$cells(Out::FLAG.P.POS)} {
            set sane 0

            $type CheckTopic "Economy: Non-Positive Prices" {
                One of the P.i price cells is negative or zero; this implies
                an error in the CGE.  Enter "dump econ" at the CLI to
                see the full list of CGE outputs.  Consider setting
                the "econ.disable" parameter to "yes", since the
                economic model is clearly malfunctioning.
            }
        }

        if {$gotEcon && !$cells(Out::FLAG.DELTAQ.ZERO)} {
            set sane 0

            $type CheckTopic "Economy: Delta-Q non-zero" {
                One of the deltaQ.i cells is negative or zero; this implies
                an error in the CGE.  Enter "dump econ" at the CLI to
                see the full list of CGE outputs.  Consider setting
                the "econ.disable" parameter to "yes", since the
                economic model is clearly malfunctioning.
            }
        }

        set limit [parmdb get econ.check.MinConsumerFrac]
        if {$gotEcon && 
            $cells(In::Consumers) < $limit * $start(In::Consumers)
        } {
            set sane 0

            $type CheckTopic "Number of consumers has declined alarmingly" {
                The current number of consumers in the local economy,
            } $cells(In::Consumers), {
                is less than 
            } $limit {
                of the starting number.  To change the limit, set the
                value of the "econ.check.MinConsumerFrac" model parameter.
            }
        }

        set limit [parmdb get econ.check.MinLaborFrac]
        if {$gotEcon && 
            $cells(In::WF) < $limit * $start(In::WF)
        } {
            set sane 0

            $type CheckTopic "Number of workers has declined alarmingly" {
                The current number of workers in the local labor force,
            } $cells(In::WF), { 
                is less than
            } $limit {
                of the starting number.  To change the limit, set the 
                value of the "econ.check.MinLaborFrac" model parameter.
            }
        }

        set limit [parmdb get econ.check.MaxUR]
        if {$gotEcon && $cells(Out::UR) > $limit} {
            set sane 0

            $type CheckTopic "Unemployment skyrockets" {
                The unemployment rate, 
            } [format "%.1f%%," $cells(Out::UR)] {
                exceeds the limit of 
            } [format "%.1f%%." $limit] {
                To change the limit, set the value of the 
                "econ.check.MaxUR" model parameter.
            }
        }

        set limit [parmdb get econ.check.MinDgdpFrac]
        if {$gotEcon && 
            $cells(Out::DGDP) < $limit * $start(Out::DGDP)
        } {
            set sane 0

            $type CheckTopic "DGDP Plummets" {
                The Deflated Gross Domestic Product (DGDP),
            } \$[moneyfmt $cells(Out::DGDP)], {
                is less than 
            } $limit {
                of its starting value.  To change the limit, set the
                value of the "econ.check.MinDgdpFrac" model parameter.
            }
        }

        set min [parmdb get econ.check.MinCPI]
        set max [parmdb get econ.check.MaxCPI]
        if {$gotEcon && $cells(Out::CPI) < $min || 
            $cells(Out::CPI) > $max
        } {
            set sane 0

            $type CheckTopic "CPI beyond limits" {
                The Consumer Price Index (CPI), 
            } [format "%4.2f," $cells(Out::CPI)] {
                is outside the expected range of
            } [format "(%4.2f, %4.2f)." $min $max] {
                To change the bounds, set the values of the 
                "econ.check.MinCPI" and "econ.check.MaxCPI" model
                parameters.
            }
        }

        

        # NEXT, report on sanity
        if {$opts(-report) && !$sane} {
            report save                                 \
                -rtype   SCENARIO                       \
                -subtype SANITY                         \
                -meta1   ONTICK                         \
                -title   "On-Tick Sanity Check: FAILED" \
                -text    $trans(buffer)
        }

        # NEXT, clear the buffer
        set trans(buffer) ""

        # NEXT, return the result
        return $sane
    }

    # CheckTopic header lines...
    #
    # header     A header string for a sanity check failure
    # lines      Zero or more lines of body text
    #
    # Formats the topic as a left-justified header with an
    # indented body.  Adds the topic to the buffer.  Blank lines
    # separate topics.

    typemethod CheckTopic {header args} {
        # FIRST, add a blank line, if needed.
        if {[string length $trans(buffer)] > 0} {
            append trans(buffer) "\n\n"
        }

        # NEXT, append the header.
        append trans(buffer) [normalize $header]

        # NEXT, format and append the body, if any.
        if {[llength $args] > 0} {
            set body [normalize [join $args \n]]
            
            append trans(buffer) \n
            append trans(buffer) \
                [textutil::adjust::indent \
                     [textutil::adjust::adjust $body -length 70] \
                     "    "]
        }

        return
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # the change cannot be undone, the mutator returns the empty string.


    # mutate startdate startdate
    #
    # startdate   The date of T0 as a zulu-time string
    #
    # Sets the simclock's -t0 start date

    typemethod {mutate startdate} {startdate} {
        set oldDate [simclock cget -t0]

        simclock configure -t0 $startdate

        # NEXT, saveable(i) data has changed
        set info(changed) 1

        # NEXT, notify the app
        notifier send $type <Time>

        # NEXT, set the undo command
        return [mytypemethod mutate startdate $oldDate]
    }

    # mutate lock
    #
    # Causes the simulation to transition from PREP to PAUSED in time 0.

    typemethod {mutate lock} {} {
        assert {$info(state) eq "PREP"}

        # FIRST, save a PREP checkpoint.
        scenario snapshot save -prep

        # NEXT, do initial analyses, and initialize modules that
        # begin to work at this time.
        aram     init -reload
        activity analyze staffing
        demog    analyze pop
        sat      start                 ;# TBD: check results (need trends)
        coop     start                 ;# TBD: check results (need trends)
        nbstat   start
        econ     start
        demog    analyze econ
        demsit   assess                ;# TBD

        # TBD: demog should probably do something here.
        mad getdrivers

        # NEXT, execute events scheduled at time 0.
        eventq advance 0

        # NEXT, set the state to PAUSED
        $type SetState PAUSED

        set info(econOK) 1

        # NEXT, resync the GUI, since much has changed.
        notifier send $type <DbSyncB>

        # NEXT, return "", as this can't be undone.
        return ""
    }

    # mutate unlock
    #
    # Causes the simulation to transition from PAUSED or SNAPSHOT
    # to PREP.

    typemethod {mutate unlock} {} {
        assert {$info(state) in {PAUSED SNAPSHOT}}

        # FIRST, load the PREP snapshot
        scenario snapshot load -prep

        # NEXT, purge future snapshots
        scenario snapshot purge 0

        # NEXT, set state
        $type SetState PREP

        # NEXT, log it.
        log newlog prep
        log normal sim "Unlocked Scenario Preparation"

        # NEXT, resync the sim with the RDB
        $type dbsync

        # NEXT, return "", as this can't be undone.
        return ""
    }

    # mutate run ?options...?
    #
    # -ticks ticks       Run until now + ticks
    # -until tick        Run until tick
    # -block flag        If true, block until run completed.
    #
    # Causes the simulation to run time forward until the specified
    # time, or until "mutate pause" is called.
    #
    # Time proceeds by ticks.  Normally, each tick is run in the 
    # context of the Tcl event loop, as controlled by a timeout(n) 
    # object called "ticker".  The timeout interval is called the 
    # inter-tick delay; it determines how fast the simulation runs.
    # If -block is specified, then this routine runs time forward
    # until the stoptime, and then returns.  Thus, -block requires
    # -ticks or -until.

    typemethod {mutate run} {args} {
        assert {$info(state) eq "PAUSED"}

        # FIRST, get the pause time
        set info(stoptime) 0
        set blocking 0

        while {[llength $args] > 0} {
            set opt [lshift args]
            
            switch -exact -- $opt {
                -ticks {
                    set val [lshift args]

                    set info(stoptime) [expr {[simclock now] + $val}]
                }

                -until {
                    set info(stoptime) [lshift args]
                }

                -block {
                    set blocking [lshift args]
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # The SIM:RUN order should have guaranteed this, but let's
        # check it to make sure.
        assert {$info(stoptime) == 0 || $info(stoptime) > [simclock now]}
        assert {!$blocking || $info(stoptime) != 0}

        # NEXT, save a snapshot, purging any later snapshots.
        scenario snapshot purge [simclock now]
        scenario snapshot save

        # NEXT, set the state to running.  This will initialize the
        # models, if need be.
        $type SetState RUNNING

        # NEXT, Either execute the first tick and schedule the next,
        # or run in blocking mode until the stop time.
        if {!$blocking} {
            # FIRST, run a tick immediately.
            $type Tick

            # NEXT, if we didn't pause as a result of the first
            # tick, schedule the next one.
            if {$info(state) eq "RUNNING"} {
                $ticker schedule
            }
        } else {
            while {$info(state) eq "RUNNING"} {
                $type Tick
            }

            set info(stoptime) 0
        }

        # NEXT, return "", as this can't be undone.
        return ""
    }

    # mutate pause
    #
    # Pauses the simulation from running.

    typemethod {mutate pause} {} {
        # FIRST, cancel the ticker, so that the next tick doesn't occur.
        $ticker cancel

        # NEXT, set the state to paused, if we're running
        if {$info(state) eq "RUNNING"} {
            set info(stoptime) 0
            $type SetState PAUSED
        }

        # NEXT, cannot be undone.
        return ""
    }

    #-------------------------------------------------------------------
    # Tick

    # Tick
    #
    # This command is executed at each time tick.

    typemethod Tick {} {
        # FIRST, advance models
        demog analyze pop
        ensit assess
        nbstat analyze
        actsit assess
        
        if {[simclock now] % [parmdb get aam.ticksPerTock] == 0} {
            aam assess
        }

        if {[simclock now] % [parmdb get econ.ticksPerTock] == 0} {
            set info(econOK) [econ tock]

            if {$info(econOK)} {
                demog analyze econ
            }
        }

        demsit assess

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

            aram advance
        }

        # NEXT, save the history for this tick.
        profile hist tick

        if {[simclock now] % [parmdb get econ.ticksPerTock] == 0} {
            profile hist econ
        }

        # NEXT, advance time one tick.
        simclock tick

        notifier send $type <Time>
        log normal sim "Tick [simclock now]"
        set info(changed) 1
        
        # NEXT, execute eventq events
        eventq advance [simclock now]

        # NEXT, execute tactics tock, if any.
        if {[simclock now] % [parmdb get tactics.ticksPerTock] == 0} {
            profile tactic tock
        }

        # NEXT, do staffing.
        # TBD: It's not clear how staffing relates to tactics.
        activity analyze staffing

        # NEXT, pause if it's the pause time, or checks failed.
        set stopping 0

        if {![sim check ontick -report]} {
            if {[winfo exists .main]} {
                messagebox popup \
                    -parent  [app topwin]         \
                    -icon    error                \
                    -title   "Simulation Stopped" \
                    -message [normalize {
            On-tick sanity check failed; simulation stopped.
            Please see the On-Tick Sanity Check report for details.
                    }]

                [app topwin] tab view report
            }

            set stopping 1
        }

        if {$info(stoptime) != 0 &&
            [simclock now] >= $info(stoptime)
        } {
            log normal sim "Stop time reached"
            set stopping 1
        }

        if {$stopping} {
            $type mutate pause

            # Update demographics and nbstats, in case the user
            # wants to look at them.
            demog    analyze pop
            nbstat   analyze
        }

        # NEXT, notify the application that the tick has occurred.
        notifier send $type <Tick>
    }

    #-------------------------------------------------------------------
    # Utility Routines

    # SetState state
    #
    # state    The simulation state
    #
    # Sets the current simulation state, and reports it as <State>.

    typemethod SetState {state} {
        # FIRST, transition to the new state.
        set info(state) $state
        log normal sim "Simulation state is $info(state)"

        notifier send $type <State>
    }

    #-------------------------------------------------------------------
    # saveable(i) interface

    # checkpoint ?-saved?
    #
    # Returns a checkpoint of the non-RDB simulation data.

    typemethod checkpoint {{option ""}} {
        assert {$info(state) ne "RUNNING"}

        if {$option eq "-saved"} {
            set info(changed) 0
        }

        set checkpoint [dict create]
        
        dict set checkpoint state $info(state)
        dict set checkpoint t0    [simclock cget -t0]
        dict set checkpoint now   [simclock now]

        return $checkpoint
    }

    # restore checkpoint ?-saved?
    #
    # checkpoint     A string returned by the checkpoint typemethod
    
    typemethod restore {checkpoint {option ""}} {
        # FIRST, restore the checkpoint data
        dict with checkpoint {
            simclock configure -t0 $t0
            simclock reset
            simclock advance $now

            if {[info exists state]} {
                set info(state) $state
            } elseif {$now == 0} {
                # Fix up older scenario files, in which state was not
                # checkpointed.
                set info(state) PREP
            } else {
                set info(state) PAUSED
            }
        }

        if {$option eq "-saved"} {
            set info(changed) 0
        }
    }

    # changed
    #
    # Returns 1 if saveable(i) data has changed, and 0 otherwise.

    typemethod changed {} {
        return $info(changed)
    }


    #-------------------------------------------------------------------
    # Order Helper Routines

    # Refresh_SS dlg fields fdict
    #
    # Initializes the startdate parameter of SIM:STARTDATE when the
    # the order is cleared.
    
    typemethod Refresh_SS {dlg fields fdict} {
        dict with fdict {
            if {$startdate eq ""} {
                $dlg set startdate [simclock cget -t0]
            }
        }
    }
}

# SIM:STARTDATE
#
# Sets the zulu-time corresponding to time 0

order define SIM:STARTDATE {
    title "Set Start Date"
    options -sendstates PREP \
        -refreshcmd {::sim Refresh_SS}

    parm startdate  text "Start Date"
} {
    # FIRST, prepare the parameters
    prepare startdate -toupper -required -type zulu

    returnOnError -final

    # NEXT, set the start date
    lappend undo [sim mutate startdate $parms(startdate)]

    setundo [join $undo \n]
}

# SIM:LOCK
#
# Locks scenario preparation and transitions from PREP to PAUSED.

order define SIM:LOCK {
    title "Lock Scenario Preparation"
    options -sendstates {PREP}
} {
    # FIRST, do the scenario sanity check.
    if {![sim check onlock -log]} {
        reject * {
            Scenario sanity check failed; time cannot advance.
            Fix the error, and try again.
            Please see the Reports tab for details.
        }

        returnOnError
    }

    returnOnError -final

    # NEXT, do the tactics sanity check.
    if {![tactic check]} {
        set answer \
            [messagebox popup \
                 -title         "Tactic Sanity Check Failed"     \
                 -icon          warning                          \
                 -buttons       {ok "Continue" cancel "Cancel"}  \
                 -default       cancel                           \
                 -ignoretag     tactic_check_failed              \
                 -ignoredefault ok                               \
                 -parent        [app topwin]                     \
                 -message       [normalize {
                     One or more of your actor's tactics are invalid.
                     These tactics have been disabled; details are
                     to be found on the Reports tab and in the
                     Strategy browser.  Press
                     "Continue" to go ahead and lock the scenario;
                     or press "Cancel" if you wish to fix the
                     problems first.
                 }]]

        if {$answer eq "cancel"} {
            # Don't do anything.
            return
        }
    }

    # NEXT, lock scenario prep.
    lappend undo [sim mutate lock]

    setundo [join $undo \n]
}


# SIM:UNLOCK
#
# Locks scenario preparation and transitions from PREP to PAUSED.

order define SIM:UNLOCK {
    title "Unlock Scenario Preparation"
    options \
        -sendstates {PAUSED SNAPSHOT} \
        -monitor    no
} {
    returnOnError -final

    # NEXT, unlock scenario prep.
    lappend undo [sim mutate unlock]

    setundo [join $undo \n]
}


# SIM:RUN
#
# Starts the simulation going.

order define SIM:RUN {
    title "Run Simulation"
    options -sendstates {PAUSED}

    parm days  text "Days to Run"
    parm block enum "Block?"         -type eyesno -defval NO

    # TBD Need to indicate valid states
} {
    # FIRST, prepare the parameters
    prepare days  -toupper -type idays
    prepare block -toupper -type boolean

    returnOnError

    # NEXT, if block is yes, then days must be greater than 0
    validate block {
        if {$parms(block) && ($parms(days) eq "" || $parms(days) == 0)} {
            reject block "Cannot block without specifying the days to run"
        }
    }

    returnOnError -final

    if {$parms(block) eq ""} {
        set parms(block) 0
    }

    # NEXT, start the simulation and return the undo script

    if {$parms(days) eq "" || $parms(days) == 0} {
        lappend undo [sim mutate run]
    } else {
        set ticks [simclock fromDays $parms(days)]

        lappend undo [sim mutate run -ticks $ticks -block $parms(block)]
    }

    setundo [join $undo \n]
}


# SIM:PAUSE
#
# Pauses the simulation.  It's an error if the simulation is not
# running.

order define SIM:PAUSE {
    title "Pause Simulation"
    options -sendstates RUNNING
} {
    returnOnError -final

    # FIRST, pause the simulation and return the undo script
    lappend undo [sim mutate pause]

    setundo [join $undo \n]
}


