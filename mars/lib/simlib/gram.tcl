#-----------------------------------------------------------------------
# TITLE:
#    gram.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    GRAM: Generalized Regional Analysis Model
#
#    * Bookkeeps GRAM inputs.
#    * Recomputes GRAM outputs as simulation time is advanced per
#      simulation clock.
#    * Allows owner to schedule GRAM level and slope inputs.
#    * Allows introspection of all inputs and outputs.
#
#    Note that the engine cannot "run" on its own; it expects to be
#    embedded in a larger simulation which will control the advancement
#    of simulation time and schedule GRAM level and slope inputs as needed.
#
# TBD:
#
#    * Would like a "-s" multiplier, for direct effects "here"; 
#      defaults to 1.0, but can be set smaller, including to 0.
#
#    * Consider saving total saliency in gram_ng.
#
#-----------------------------------------------------------------------

namespace eval ::simlib:: {
    namespace export gram
}

#-----------------------------------------------------------------------
# Data Types

# Group types for which satisfaction is tracked
snit::enum ::simlib::satgrouptypes -values {CIV ORG}

# Proximity Limits
snit::enum ::simlib::proxlimit     -values {none here near far}

#-----------------------------------------------------------------------
# GRAM engine

snit::type ::simlib::gram {
    #-------------------------------------------------------------------
    # Type Components

    # gram(n)'s configuration parameter set
    typecomponent parm -public parm


    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # FIRST, Import needed commands from other packages.
        namespace import ::marsutil::* 
        namespace import ::marsutil::*
        namespace import ::simlib::*

        # NEXT, Register this module's SQL schema
        sqldocument register $type

        # NEXT, define the module's configuration parameters.
        # TBD: The types will need to be dealt with when gram(n)
        # is moved to Paxsim.
        set parm ${type}::parm
        parmset $parm

        $parm subset gram {
            gram(n) configuration parameters.
        }

        $parm define gram.epsilon ::simlib::rmagnitude 0.1 {
            Level effects expire when the effect remaining is less
            than epsilon.  Slope effects are discarded if the
            slope is less than epsilon.
        }

        $parm define gram.proxlimit ::simlib::proxlimit far {
            Bounds indirect effects by proximity to the neighborhood 
            in which a driver occurs.  Valid values are "none",
            "here", "near", and "far".
        }

        $parm define gram.saveHistory ::snit::boolean yes {
            If yes, GRAM saves a history, timestep-by-timestep,
            of the actual contribution to each effects curve during 
            that timestep by each driver, as well as the current
            level of each curve.  If no, it doesn't.
        }
    }

    #-------------------------------------------------------------------
    # sqlsection(i) implementation
    #
    # The following routines implement the module's 
    # sqlsection(i) interface.

    # sqlsection title
    #
    # Returns a human-readable title for the section

    typemethod {sqlsection title} {} {
        return "gram(n)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions.

    typemethod {sqlsection schema} {} {
        return [readfile [file join $::simlib::library gram.sql]]
    }

    # sqlsection tempschema
    #
    # Returns the section's temporary schema definitions, if any.

    typemethod {sqlsection tempschema} {} {
        return [readfile [file join $::simlib::library gram_temp.sql]]
    }

    # sqlsection functions
    #
    # Returns a dictionary of function names and command prefixes

    typemethod {sqlsection functions} {} {
        return [list \
                    clamp [myproc ClampCurve]]
    }

    #-------------------------------------------------------------------
    # Type Variables

    # This value is used as a sentinel, to indicate that a slope effect
    # has no end time.
    typevariable maxEndTime [expr {int(99999999)}]

    # This value indicates the numeric proximity limit for each
    # value of gram.*.proxlimit.

    typevariable proxlimit -array {
        none   0
        here   1
        near   2
        far    3
    }

    #-------------------------------------------------------------------
    # Options

    # -dbid dbid
    #
    # The "dbid" is the string used to identify this instance of 
    # gram(n) in the RDB.  It defaults to $self, the fully-qualified
    # instance name.
    option -dbid -readonly 1
    

    # -rdb rdb
    #
    # The name of an sqldocument(n) instance in which
    # gram(n) will store its working data.
    option -rdb -readonly 1
    component rdb

    # -loadcmd cmd
    #
    # The name of a command that will populate the GRAM tables in the
    # RDB.  It must take one additional argument, $self.
    # See gram(n) for more details.

    option -loadcmd -readonly 1

    # -clock simclock
    #
    # The input is the name of a simclock(n) instance which is controlling
    # simulation time.

    option -clock -readonly 1
    component clock

    # -logger
    #
    # Sets name of application's logger(n) object.

    option -logger

    # -logcomponent
    #
    # Sets this object's "log component" name, to be used in log messages.

    option -logcomponent -default gram -readonly 1

    #-------------------------------------------------------------------
    # Components

    # nbhoods: Neighborhoods snit::enum
    component nbhoods

    # cgroups: CIV Groups snit::enum
    component cgroups

    # cogroups: CIV and ORG Groups snit::enum
    component cogroups

    # fgroups: FRC Groups snit::enum
    component fgroups

    # concerns: Concerns snit::enum
    component concerns

    #-------------------------------------------------------------------
    # GRAM Model Data
    #
    # Some GRAM model data is stored as elements in the "db" array.  The 
    # elements are as listed below.
    #
    # initialized        0 if -loadcmd has never been called, and 1 if 
    #                    it has.
    #
    # loadstate          Indicates the progress of the -loadcmd.
    #
    # time               Simulation Time: integer ticks, starting at 0
    #
    # timelast           Time of previous advance: integer ticks, 
    #                    starting at 0.  time - timelast gives us the 
    #                    most recent time step.
    #
    #-----------------------------------------------------------------------
    
    variable db -array { }

    # Initial db values
    variable initdb {
        initialized      0
        loadstate        ""
        time             {}
        timelast         {}
    }


    #-------------------------------------------------------------------
    # Other Variables

    # This gram's identifier in rdb records.
    variable dbid ""
    
    # Non-checkpointed scalar data
    #
    # changed    1 if db() has changed, and 0 otherwise.

    
    variable info -array {
        changed          0
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, set the default dbid
        set options(-dbid) $self

        # NEXT, get the creation arguments.
        $self configurelist $args

        # NEXT, verify that we have a load command
        assert {$options(-loadcmd) ne ""}

        # NEXT, set the database ID variable accordingly.
        set dbid $options(-dbid)

        # NEXT, save components passed in as options
        set clock $options(-clock)
        assert {[info commands $clock] ne ""}

        set rdb $options(-rdb)
        assert {[info commands $rdb] ne ""}

        # NEXT, initialize db
        array set db $initdb

        $self Log normal "Created"
    }

    destructor {
        catch {$self ClearTables}
    }

    #-------------------------------------------------------------------
    # Object Management Methods

    # checkpoint ?-saved?
    #
    # Return a copy of the engine's state for later restoration.
    # This includes only the data stored in the db array; data stored
    # in the RDB is checkpointed automatically.
    
    method checkpoint {{option ""}} {
        if {$option eq "-saved"} {
            set info(changed) 0
        }

        return [array get db]
    }


    # restore state ?-saved?
    #
    # state     Checkpointed state returned by the checkpoint method.
    #
    # Restores the checkpointed state; this is just the reverse of
    # "checkpoint".

    method restore {state {option ""}} {
        # FIRST, restore the state.
        array unset db
        array set db $state

        # NEXT, if GRAM is initialized, create the validators.
        if {$db(initialized)} {
            $self CreateValidators
        }

        # NEXT, set the changed flag
        if {$option eq "-saved"} {
            set info(changed) 0
        } else {
            set info(changed) 1
        }
    }


    # changed
    #
    # Returns the changed flag.

    method changed {} {
        return $info(changed)
    }

    #-------------------------------------------------------------------
    # Simulation Execution Methods

    # init ?-reload?
    #
    # -reload    If present, calls the -loadcmd to reload the 
    #            initial data into the RDB.
    #
    # Initializes the simulation to 0.  Reloads initial data on
    # demand.

    method init {{opt ""}} {
        # FIRST, get inputs from the RDB
        if {!$db(initialized) || $opt eq "-reload"} {
            $self LoadData
            set db(initialized) 1
        } elseif {$opt ne ""} {
            error "invalid option: \"$opt\""
        }

        # NEXT, set the time to the current simclock time.
        set db(time)     [$clock now]
        set db(timelast) $db(time)

        # NEXT, compute the influence table.
        $self ComputeSatInfluence
        $self ComputeCoopInfluence

        # NEXT, Initialize the curves.  This includes deleting all history.
        $self CurvesInit

        # NEXT, Create the long-term trend slope effects
        $self CreateLongTermTrends

        # NEXT, compute the initial roll-ups.
        $self ComputeSatRollups
        $self ComputeCoopRollups

        # NEXT, save initial values
        $rdb eval {
            UPDATE gram_n      SET sat0  = sat  WHERE object=$dbid;
            UPDATE gram_g      SET sat0  = sat  WHERE object=$dbid;
            UPDATE gram_c      SET sat0  = sat  WHERE object=$dbid;
            UPDATE gram_ng     SET sat0  = sat  WHERE object=$dbid;
            UPDATE gram_nc     SET sat0  = sat  WHERE object=$dbid;
            UPDATE gram_gc     SET sat0  = sat  WHERE object=$dbid;
            UPDATE gram_frc_ng SET coop0 = coop WHERE object=$dbid;
        }

        # NEXT, set the changed flag
        set info(changed) 1

        return
    }

    # clear
    #
    # Uninitializes gram, returning it to its initial state on 
    # creation and deleting all of the instance's data from the RDB.

    method clear {} {
        # FIRST, reset the in-memory data
        array unset db
        array set db $initdb

        # NEXT, destroy validators
        $self DestroyValidators

        # NEXT, Clear the RDB
        $self ClearTables
    }

    # initialized
    #
    # Returns 1 if the -loadcmd has ever been successfully called, and 0
    # otherwise.

    method initialized {} {
        return $db(initialized)
    }

    #-------------------------------------------------------------------
    # load API
    #
    # This API is used by the load command to load new data into 
    # GRAM.  The commands must be used in a strict order, as indicated
    # by db(loadstate).

    # LoadData
    #
    # This is called by "init" when it's necessary to reload input
    # data from the client.

    method LoadData {} {
        # FIRST, clear all of the tables, so that they can be
        # refilled.
        $self ClearTables

        # NEXT, the client's -loadcmd must call the "load *" methods
        # in a precise sequence.  Set up the state machine to handle
        # it.
        set db(loadstate) begin

        # NEXT, call the -loadcmd.  The client will specify the
        # entities and input data, and GRAM will populate tables.
        {*}$options(-loadcmd) $self

        # NEXT, make sure that all "load *" methods were called,
        # and terminate the state machine.
        assert {$db(loadstate) eq "coop"}
        set db(loadstate) end

        # NEXT, final steps.  Do a sanity check of the input data,
        # and create the validation enums.
        $self SanityCheck
        $self CreateValidators
    }

    # ClearTables
    #
    # Clears all gram(n) tables for this instance

    method ClearTables {} {
        $rdb eval {
            DELETE FROM gram_curves         WHERE object=$dbid;
            DELETE FROM gram_effects        WHERE object=$dbid;
            DELETE FROM gram_contribs       WHERE object=$dbid;
            DELETE FROM gram_values         WHERE object=$dbid;
            DELETE FROM gram_n              WHERE object=$dbid;
            DELETE FROM gram_g              WHERE object=$dbid;
            DELETE FROM gram_c              WHERE object=$dbid;
            DELETE FROM gram_mn             WHERE object=$dbid;
            DELETE FROM gram_nfg            WHERE object=$dbid;
            DELETE FROM gram_ng             WHERE object=$dbid;
            DELETE FROM gram_frc_ng         WHERE object=$dbid;
            DELETE FROM gram_nc             WHERE object=$dbid;
            DELETE FROM gram_gc             WHERE object=$dbid;
            DELETE FROM gram_ngc            WHERE object=$dbid;
            DELETE FROM gram_sat_influence  WHERE object=$dbid;
            DELETE FROM gram_coop_influence WHERE object=$dbid;
        }
    }

    # load nbhoods name ?name...?
    #
    # name         A neighborhood name.
    #
    # Loads the neighborhoods.  Typically, the names should be pre-sorted.

    method {load nbhoods} {args} {
        assert {$db(loadstate) eq "begin"}

        foreach n $args {
            $rdb eval {
                INSERT INTO gram_n(object,n)
                VALUES($dbid,$n);
            }
        }

        set db(loadstate) "nbhoods"
    }

    # load groups name gtype ?name gtype...?
    # 
    # name       Group name
    # gtype      Group type (CIV, FRC, ORG)
    #
    # Loads the group names.  Typically, the groups are ordered
    # first by group type, and then by name.

    method {load groups} {args} {
        assert {$db(loadstate) eq "nbhoods"}

        foreach {g gtype} $args {
            $rdb eval {
                INSERT INTO gram_g(object,g,gtype)
                VALUES($dbid,$g,$gtype);
            }
        }

        set db(loadstate) "groups"
    }

    # load concerns name gtype ?name gtype...?
    # 
    # name       Concern name
    # gtype      Concern type (CIV, ORG)
    #
    # Loads the concern names.  Typically, the concerns are ordered
    # first by concern type, and then by name.

    method {load concerns} {args} {
        assert {$db(loadstate) eq "groups"}

        foreach {c gtype} $args {
            $rdb eval {
                INSERT INTO gram_c(object,c,gtype)
                VALUES($dbid,$c,$gtype);
            }
        }

        $self PopulateDefaultsAfterConcerns

        set db(loadstate) "concerns"
    }

    # PopulateDefaultsAfterConcerns
    #
    # Once all of the relevant neighborhoods, groups, and concerns
    # known, this routine populates dependent tables with default
    # values.  The -loadcmd can subsequently fill in details as
    # desired.

    method PopulateDefaultsAfterConcerns {} {
        # FIRST, populate gram_nc.
        $rdb eval {
            INSERT INTO gram_nc(
                object,
                n,
                c)
            SELECT $dbid, n, c
            FROM gram_n JOIN gram_c USING (object)
            WHERE object=$dbid
            ORDER BY n, gtype, c;
        }

        # NEXT, populate gram_gc.
        $rdb eval {
            INSERT INTO gram_gc(
                object,
                g,
                c)
            SELECT $dbid, g, c
            FROM gram_g JOIN gram_c USING (object,gtype)
            WHERE object=$dbid
            ORDER BY gtype, g, c
        }

        # NEXT, populate gram_mn: A nbhood is "here" to itself and
        # "far" to all others, and effects_delays are all 0.0

        $rdb eval {
            INSERT INTO gram_mn(
                object,
                m,
                n,
                proximity,
                effects_delay)
            SELECT $dbid,
                   M.n,
                   N.n,
                   CASE WHEN M.n=N.n THEN 0 ELSE 2 END,
                   0.0
            FROM gram_n AS M join gram_n AS N USING (object)
            WHERE object=$dbid
            ORDER BY M.n, N.n
        }

        # NEXT, populate gram_ng.  Weights and factors are 1.0,
        # sat_tracked is 1 only for ORG groups, and all populations
        # are 0.

        $rdb eval {
            SELECT n, g, gtype
            FROM gram_n JOIN gram_g USING (object)
            WHERE object=$dbid
            AND   gtype IN ('CIV', 'ORG')
            ORDER BY n, gtype, g
        } {
            # FIRST, Satisfaction is not tracked for CIVs unless 
            # population is not 0, which we don't know yet.
            # population is 0!
            if {$gtype eq "CIV"} {
                set sat_tracked 0
            } else {
                set sat_tracked 1
            }

            $rdb eval {
                -- Note: ng_id is set automatically
                INSERT INTO 
                gram_ng(object, n, g, 
                        population, rollup_weight, effects_factor,
                        sat_tracked)
                VALUES($dbid, $n, $g, 0, 1.0, 1.0, $sat_tracked)
            }
        }

        # NEXT, populate gram_frc_ng.
        $rdb eval {
            INSERT INTO gram_frc_ng(
                object,
                n,
                g)
            SELECT $dbid, n, g
            FROM gram_n JOIN gram_g USING (object)
            WHERE object=$dbid
            AND   gtype = 'FRC'
            ORDER BY n, g
        }
    }

    # load nbrel m n proximity effects_delay ?...?
    #
    # m               Neighborhood name
    # n               Neighborhood name
    # proximity       eproximity(n); must be 0 if m=n.
    # effects_delay   Effects delay in decimal days.

    method {load nbrel} {args} {
        assert {$db(loadstate) eq "concerns"}

        foreach {m n proximity effects_delay} $args {
            set proximity [eproximity index $proximity]

            assert {
                ($m eq $n && $proximity == 0) ||
                ($m ne $n && $proximity != 0)
            }

            set mn_id [$rdb onecolumn {
                SELECT mn_id FROM gram_mn
                WHERE object=$dbid AND m=$m AND n=$n;
            }]

            require {$mn_id ne ""} "Invalid nbhood pair: $m $n"

            $rdb eval {
                UPDATE gram_mn
                SET proximity     = $proximity,
                    effects_delay = $effects_delay
                WHERE mn_id = $mn_id;
            }
        }

        set db(loadstate) "nbrel"
    }

    # load nbgroups n g population rollup_weight effects_factor ?...?
    #
    # n               Neighborhood name
    # g               Group name
    # population      Population; 0 for ORG groups
    # rollup_weight   Rollup Weight
    # effects_factor  Effects Factor

    method {load nbgroups} {args} {
        assert {$db(loadstate) eq "nbrel"}

        foreach {n g population rollup_weight effects_factor} $args {
            set ng_id [$rdb onecolumn {
                SELECT ng_id FROM gram_ng 
                WHERE object=$dbid AND n=$n AND g=$g
            }]

            require {$ng_id ne ""} "Invalid nbgroup: $n $g"

            # TBD: Should verify that population is 0 if g is ORG.

            $rdb eval {
                UPDATE gram_ng
                SET population     = $population,
                    rollup_weight  = $rollup_weight,
                    effects_factor = $effects_factor,
                    sat_tracked    = CASE 
                        WHEN $population > 0 THEN 1 ELSE 0 
                    END
                WHERE ng_id=$ng_id
            }
        }

        $self PopulateDefaultsAfterNbgroups

        set db(loadstate) "nbgroups"
    }

    # PopulateDefaultsAfterNbgroups
    #
    # Once all of the relevant neighborhood groups are
    # known, this routine populates dependent tables with default
    # values.  The -loadcmd can subsequently fill in details as
    # desired.

    method PopulateDefaultsAfterNbgroups {} {
        # FIRST, populate gram_ngc. Saliency is 1.0 if sat_tracked,
        # and 0.0 otherwise; trend is always 0.0; there's a curve
        # only if sat_tracked.
        $rdb eval {
            SELECT ng_id, 
                   n, 
                   g, 
                   sat_tracked,
                   c, 
                   gram_g.gtype AS gtype 
            FROM gram_ng 
            JOIN gram_g USING (object, g)
            JOIN gram_c
            WHERE gram_ng.object = $dbid
            AND   gram_c.object  = $dbid
            AND   gram_g.gtype   = gram_c.gtype
            ORDER BY n, gram_g.gtype, g, c
        } {
            if {$sat_tracked} {
                $rdb eval {
                    -- Note: curve_id is set automatically
                    INSERT INTO gram_curves(object, curve_type, val0, val)
                    VALUES($dbid, 'SAT', 0.0, 0.0);

                    -- Note: ngc_id is set automatically
                    INSERT INTO 
                    gram_ngc(object, ng_id, curve_id, n, g, c,
                             gtype, saliency, trend)
                    VALUES($dbid, $ng_id, last_insert_rowid(),  $n, $g, $c, 
                           $gtype, 1.0, 0.0);
                }

            } else {
                $rdb eval {
                    -- Note: ngc_id is set automatically
                    INSERT INTO 
                    gram_ngc(object, ng_id, n, g, c, gtype, saliency, trend)
                    VALUES($dbid, $ng_id, $n, $g, $c, $gtype, 0.0, 0.0);
                }
            }
        }

        # NEXT, populate gram_nfg.  Default relationships are 0.0,
        # unless f=g. Default cooperations are 50.0 where f is a FRC
        # group and g is a CIV group and ng.sat_tracked is 1, and 0.0
        # otherwise.
        $rdb eval {
            INSERT INTO gram_nfg(
                object,
                n,
                f,
                g,
                rel)
            SELECT $dbid,
                   gram_n.n AS n,
                   F.g      AS f,
                   G.g      AS g,
                   CASE WHEN F.g=G.g THEN 1.0 ELSE 0.0 END
            FROM  gram_n 
            JOIN  gram_g AS F USING (object)
            JOIN  gram_g AS G USING (object)
            WHERE gram_n.object=$dbid
            ORDER BY n, F.g, G.g
        }

        $rdb eval {
            SELECT gram_ng.n AS n,
                   gram_ng.g AS f,
                   G.g       AS g
            FROM gram_ng 
            JOIN gram_g AS F USING (object) 
            JOIN gram_g AS G USING (object)             
            WHERE gram_ng.object=$dbid
            AND   gram_ng.sat_tracked=1
            AND   F.gtype = 'CIV'
            AND   G.gtype = 'FRC'
            AND   gram_ng.g = F.g
            ORDER BY n, f, g
        } {
            $rdb eval {
                -- Note: curve_id is set automatically.
                INSERT INTO gram_curves(object, curve_type, val0, val)
                VALUES($dbid, 'COOP', 50.0, 50.0);

                UPDATE gram_nfg
                SET curve_id = last_insert_rowid()
                WHERE object=$dbid AND n=$n AND f=$f AND g=$g;
            }
        }
    }

    # load sat n g c sat0 saliency trend 
    #
    # n               Neighborhood name
    # g               Group name
    # c               Concern name
    # sat0            Initial satisfaction level
    # saliency        Saliency
    # trend           Long-term trend

    method {load sat} {args} {
        assert {$db(loadstate) eq "nbgroups"}

        foreach {n g c sat0 saliency trend} $args {
            set curve_id [$rdb onecolumn {
                SELECT curve_id 
                FROM gram_ngc
                WHERE object=$dbid AND n=$n AND g=$g AND c=$c;
            }]

            require {$curve_id ne ""} "No such sat curve: $n $g $c"

            $rdb eval {
                UPDATE gram_curves
                SET val0 = $sat0,
                    val  = $sat0
                WHERE curve_id = $curve_id;
                
                UPDATE gram_ngc
                SET saliency = $saliency,
                    trend    = $trend
                WHERE curve_id = $curve_id;
            }
        }

        $self PopulateTablesAfterSat

        set db(loadstate) "sat"
    }

    # PopulateTablesAfterSat
    #
    # Computes the total saliency for each n,g,c.

    method PopulateTablesAfterSat {} {
        # FIRST, get the total_saliency for each neighborhood group
        $rdb eval {
            SELECT n,
                   g,
                   total(saliency) AS saliency
            FROM gram_ngc
            WHERE object=$dbid
            GROUP BY n,g
        } {
            $rdb eval {
                UPDATE gram_ng
                SET total_saliency=$saliency
                WHERE object=$dbid AND n=$n AND g=$g
            }
        }
    }

    # load rel n f g rel ?....? 
    #
    # n               Neighborhood name
    # f               Group name
    # g               Group name
    # rel             Group relationship

    method {load rel} {args} {
        assert {$db(loadstate) eq "sat"}

        foreach {n f g rel} $args {
            set nfg_id [$rdb onecolumn {
                SELECT nfg_id FROM gram_nfg 
                WHERE object=$dbid AND n=$n AND f=$f AND g=$g
            }]

            require {$nfg_id ne ""} "Invalid relationship: $n $f $g"

            $rdb eval {
                UPDATE gram_nfg
                SET rel = $rel
                WHERE nfg_id = $nfg_id;
            }
        }

        set db(loadstate) "rel"
    }

    # load coop n f g coop0 
    #
    # n               Neighborhood name
    # f               Force group name
    # g               Civ group name
    # coop0           Initial cooperation level

    method {load coop} {args} {
        assert {$db(loadstate) eq "rel"}

        foreach {n f g coop0} $args {
            set curve_id [$rdb onecolumn {
                SELECT curve_id 
                FROM gram_nfg
                WHERE object=$dbid AND n=$n AND f=$f AND g=$g;
            }]

            require {$curve_id ne ""} "No such coop curve: $n $f $g"

            $rdb eval {
                UPDATE gram_curves
                SET val0 = $coop0,
                    val  = $coop0
                WHERE curve_id = $curve_id;
            }
        }

        set db(loadstate) "coop"
    }

    # SanityCheck
    #
    # Verifies that we have everything we need to run.

    method SanityCheck {} {
        # TBD: Not yet implemented.
    }

    # CreateValidators
    #
    # Creates snit::enums for the valid nbhood, concern, and pgroup
    # names.

    method CreateValidators {} {
        # FIRST, if they already exist get rid of them.
        $self DestroyValidators

        # Nbhoods
        set values [$rdb eval {
            SELECT n FROM gram_n 
            WHERE object=$dbid 
            ORDER BY n_id
        }]

        set nbhoods [snit::enum ${selfns}::nbhoods -values $values]

        # CIV Groups
        set values [$rdb eval {
            SELECT g FROM gram_g 
            WHERE  object=$dbid 
            AND    gtype = 'CIV'
            ORDER BY g_id
        }]

        set cgroups [snit::enum ${selfns}::cgroups -values $values]

        # CIV/ORG Groups
        set values [$rdb eval {
            SELECT g FROM gram_g 
            WHERE  object=$dbid 
            AND    gtype IN ('CIV','ORG')
            ORDER BY g_id
        }]

        set cogroups [snit::enum ${selfns}::cogroups -values $values]

        # FRC Groups
        set values [$rdb eval {
            SELECT g FROM gram_g 
            WHERE  object=$dbid 
            AND    gtype = 'FRC'
            ORDER BY g_id
        }]

        set fgroups [snit::enum ${selfns}::fgroups -values $values]

        # Concerns
        set values [$rdb eval {
            SELECT c FROM gram_c
            WHERE object=$dbid
            ORDER BY c_id
        }]

        set concerns [snit::enum ${selfns}::concerns -values $values]
    }

    # DestroyValidators
    #
    # Destroys the snit::enums for the valid nbhoods, concerns,
    # etc.

    method DestroyValidators {} {
        if {$nbhoods ne ""} {
            rename $nbhoods   "" ; set nbhoods  ""
            rename $cgroups   "" ; set cgroups  ""
            rename $cogroups  "" ; set cogroups ""
            rename $fgroups   "" ; set fgroups  ""
            rename $concerns  "" ; set concerns ""
        }
    }

    # CreateLongTermTrends
    #
    # The long-term trends are entered as a single driver with 
    # driver ID 0; a single slope effect is created for each ngc.

    method CreateLongTermTrends {} {
        # FIRST, create the Driver
        $rdb eval {
            INSERT INTO gram_driver(object,driver,name,dtype,oneliner)
            VALUES($dbid,0,"Trend","Trend","Satisfaction Long-Term Trend")
        }

        set input(driver)  0
        set input(input)  [$self DriverGetInput $input(driver)]
        set input(cause)   "TREND"
        set input(ts)      $db(time)
        set input(p)       0.0
        set input(q)       0.0

        set chain(prox)    -1
        set chain(factor)  1.0
        set chain(delay)   0

        # NEXT, enter a slope effect for each ngc with a non-zero trend.
        $rdb eval {
            SELECT * FROM gram_ngc
            WHERE object=$dbid
            AND   trend != 0.0
        } row {
            set input(slope)     $row(trend)

            set chain(curve_id)  $row(curve_id)
            set chain(direct_id) $row(ngc_id)

            $self ScheduleSlope input chain 0.0
        }
    }

    #-------------------------------------------------------------------
    # Update API
    #
    # This API is used to update scenario data after the initial load.
    # Not everything can be modified.

    # update population n g population ...
    #
    # n           A neighborhood
    # g           A group in the neighborhood
    # population  The group ng's new population
    #
    # Updates the population for the specified groups.  Note that
    # it's an error to assign a non-zero population to a group with
    # zero population, or a zero population to a group with non-zero
    # population.
    #
    # The change takes affect on the next time advance.

    method {update population} {args} {
        foreach {n g population} $args {
            # TBD: Could verify that g is CIV, and that
            # existing population matches.
            $rdb eval {
                UPDATE gram_ng
                SET population = $population
                WHERE object=$dbid AND n=$n AND g=$g
            }
        }
    }



    #-------------------------------------------------------------------
    # Driver IDs
    #
    # Every input to GRAM is associated with a satisfaction or
    # cooperation driver, i.e., an event or situation.
    # Prior to entering the input, the application must allocate
    # a numeric Driver ID by calling "driver add".
    #
    # OPTIONS
    #
    # Driver IDs have the following options:
    #
    # -name     text    Short name for the driver.  Defaults
    #                   to the driver ID.
    # -dtype    text    Driver type.  Defaults to "unknown".
    # -oneliner text    One-line description of the driver.
    #                   Defaults to "unknown".

    # driver add ?options?
    #
    # Assigns and returns a new Driver ID.  Saves the options if given.
    #
    # NOTE: This code has the important property that if the most recently
    # added driver is deleted (cancel -delete), the driver ID will be 
    # reused the next time.  This allows allocation of driver IDs to
    # be undone.  Don't break it!

    method {driver add} {args} {
        # FIRST, process the options
        set opts [$self ParseDriverOptions $args]

        # NEXT, Get the next Driver ID number
        # If there are any, this will get the next one.
        $rdb eval {
            SELECT COALESCE(max(driver) + 1, 1) AS nextDriver
            FROM gram_driver
            WHERE object=$dbid
        } {}

        # NEXT, Create the new record
        $rdb eval {
            INSERT INTO gram_driver(object,driver)
            VALUES($dbid,$nextDriver)
        }

        if {![dict exists $opts name]} {
            dict set opts name $nextDriver
        }

        # NEXT, save the option values
        $self SetDriverOptions $nextDriver $opts

        return $nextDriver
    }

    # driver configure driver ?options?
    #
    # driver    An existing Driver ID
    #
    # Sets new option values

    method {driver configure} {driver args} {
        # FIRST, validate the driver ID
        $self driver validate $driver "Cannot configure"

        # NEXT, save the option values
        $self SetDriverOptions $driver [$self ParseDriverOptions $args]

        return
    }

    # driver exists driver
    #
    # driver    A Driver ID
    #
    # Returns 1 if the Driver ID exists, and 0 otherwise.

    method {driver exists} {driver} {
        # FIRST, validate the driver
        if {[$rdb exists {
            SELECT driver FROM gram_driver
            WHERE object=$dbid
            AND   driver=$driver
        }]} {
            return 1
        } else {
            return 0
        }
    }

    # driver validate driver ?prefix?
    #
    # driver   A Driver ID
    # prefix   Optional error message prefix
    #
    # Throws an error if the Driver ID is not valid.

    method {driver validate} {driver {prefix ""}} {
        if {![$self driver exists $driver]} {
            if {$prefix ne ""} {
                append prefix ", "
            }
            error "${prefix}unknown Driver ID: \"$driver\""
        }
    }

    # driver cget driver option
    #
    # driver  An existing Driver ID
    # option  An option
    #
    # Returns the current value of the option, which can also simply
    # be read from the RDB.

    method {driver cget} {driver option} {
        # FIRST, Validate the option
        switch -exact -- $option {
            -dtype {
                set column "dtype"
            }

            -name {
                set column "name"
            }

            -oneliner {
                set column "oneliner"
            }
            
            default {
                error "Unknown option: \"$option\""
            }
        }

        # NEXT, get the value
        $rdb eval "
            SELECT $column AS value
            FROM gram_driver
            WHERE object=\$dbid AND driver=\$driver
        " {
            return $value
        }

        error "Cannot cget, unknown Driver ID: \"$driver\""
    }

    # ParseDriverOptions optlist
    #
    # optlist     List of zero or more options and their values
    #
    # Parses and validates the options, and returns a dict of them.
    # The option values match the column names.

    method ParseDriverOptions {optlist} {
        set opts [dict create]

        while {[llength $optlist] > 0} {
            set opt [lshift optlist]
            
            switch -exact -- $opt {
                -dtype {
                    dict set opts dtype [lshift optlist]
                }

                -name {
                    dict set opts name [lshift optlist]
                }

                -oneliner {
                    dict set opts oneliner [lshift optlist]
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }
        
        return $opts
    }

    # SetDriverOptions driver opts
    #
    # driver  Existing driver ID
    # opts    Dictionary of valid options and values
    #
    # Sets all option values.
    
    method SetDriverOptions {driver opts} {
        dict for {opt val} $opts {
            $rdb eval "
                UPDATE gram_driver
                SET $opt = \$val
                WHERE object = \$dbid
                AND   driver = \$driver
            "
        } 
    }

    # DriverGetInput driver
    #
    # Returns the next input counter for a given driver.
    
    method DriverGetInput {driver} {
        $rdb onecolumn {
            UPDATE gram_driver
            SET last_input = last_input + 1
            WHERE object = $dbid AND driver=$driver;

            SELECT last_input FROM gram_driver
            WHERE object = $dbid AND driver=$driver;
        }
    }

    # DriverDecrementInput driver
    #
    # Decrements the input counter for a given driver.
    #
    # NOTE: This is provided for "sat set -undo" and 
    # "coop set -undo", pending a real undo mechanism.
    
    method DriverDecrementInput {driver} {
        $rdb eval {
            UPDATE gram_driver
            SET last_input = last_input - 1
            WHERE object = $dbid AND driver=$driver;
        }

        return
    }

    #-------------------------------------------------------------------
    # Influence

    # ComputeSatInfluence
    #
    # Computes all satisfaction influence entries

    method ComputeSatInfluence {} {
        # FIRST, get the conversion from days to ticks
        set daysToTicks [$clock fromDays 1.0]

        # NEXT, clear the previous influence
        $rdb eval {
            DELETE FROM gram_sat_influence 
            WHERE object=$dbid;
        }

        # NEXT, accumulate the combinations and save.  For every
        # neighborhood group that can be the target of a direct effect
        # (which is all of them) we want to acquire the set of 
        # neighborhood groups which can receive the indirect effect.
        # That is, all neighborhood groups that:
        #
        # * Are here, near, or far, but not remote
        # * Do not have a multiplicative factor or 0
        #
        # For each combination we want to compute that multiplicative
        # factor, and also the proximity and delay (in ticks).

        $rdb eval {
            INSERT INTO gram_sat_influence(
                   object, direct_ng, influenced_ng, prox, delay, factor)
            SELECT $dbid                                   AS object,
                   dir_ng.ng_id                            AS direct_ng,
                   inf_ng.ng_id                            AS influenced_ng,
                   CASE WHEN dir_ng.ng_id = inf_ng.ng_id 
                        THEN -1
                        ELSE gram_mn.proximity END         AS prox,
                   CAST (gram_mn.effects_delay*$daysToTicks 
                         AS INTEGER)                       AS delay,
                   CASE WHEN gram_mn.proximity = 0  -- "Here"
                        THEN gram_nfg.rel
                        ELSE gram_nfg.rel * dir_ng.effects_factor 
                        END                                AS factor

            FROM  gram_ng AS dir_ng   -- Direct effect nbhood-group
            JOIN  gram_ng AS inf_ng   -- Influenced nbhood-group
            JOIN  gram_g  AS dir_g    -- Direct group
            JOIN  gram_g  AS inf_g    -- Influenced group
            JOIN  gram_mn             -- proximity, delay
            JOIN  gram_nfg            -- Relationships

            WHERE dir_ng.object      =  $dbid
            AND   inf_ng.object      =  $dbid
            AND   inf_ng.sat_tracked =  1
            AND   dir_g.object       =  $dbid
            AND   dir_g.g            =  dir_ng.g
            AND   inf_g.object       =  $dbid
            AND   inf_g.g            =  inf_ng.g
            AND   dir_g.gtype        =  inf_g.gtype
            AND   gram_mn.object     =  $dbid
            AND   gram_mn.m          =  inf_ng.n
            AND   gram_mn.n          =  dir_ng.n
            AND   prox               <  3   -- Not remote!
            AND   gram_nfg.object    =  $dbid
            AND   gram_nfg.n         =  inf_ng.n
            AND   gram_nfg.f         =  inf_ng.g
            AND   gram_nfg.g         =  dir_ng.g
            AND   factor             != 0.0
        }
    }

    # ComputeCoopInfluence
    #
    # Computes all cooperation influence entries

    method ComputeCoopInfluence {} {
        # FIRST, get the conversion from days to ticks
        set daysToTicks [$clock fromDays 1.0]

        # NEXT, clear the previous influence
        $rdb eval {
            DELETE FROM gram_coop_influence 
            WHERE object=$dbid;
        }

        # NEXT, accumulate the combinations and save.  For every
        # neighborhood dn and FRC group dg that can be the target of a 
        # direct cooperation effect (along with a CIV group f)
        # we want to acquire the set of nbhoods m and FRC groups h
        # which can receive the indirect effect.  That is, all m,h that:
        #
        # * Are here, near, or far, but not remote, from dn
        # * Do not have a multiplicative factor of 0
        #
        # For each combination we want to compute that multiplicative
        # factor, and also the proximity and delay (in ticks).

        $rdb eval {
            SELECT 
            G.g                AS dg,
            H.g                AS h,
            MN.m               AS m,
            MN.n               AS dn,
            MN.proximity       AS prox,
            MN.effects_delay   AS delay,
            MHG.rel            AS rel_mhg
            FROM gram_g   AS G
            JOIN gram_g   AS H     USING (object)
            JOIN gram_mn  AS MN    USING (object)
            JOIN gram_nfg AS MHG   USING (object)
            WHERE G.object           =  $dbid
            AND   G.gtype            =  'FRC'
            AND   H.gtype            =  'FRC'
            AND   MN.proximity       <  3  -- Not remote!
            AND   MHG.n              =  m
            AND   MHG.f              =  h
            AND   MHG.g              =  dg
            AND   rel_mhg            != 0
        } {
            # FIRST, fix up prox to be -1 for direct effects
            if {$m eq $dn &&
                $h eq $dg
            } {
                set prox -1
            }

            # NEXT, convert delay to ticks
            set delay [expr {$delay * $daysToTicks}]

            # NEXT, insert into gram_coop_influence
            $rdb eval {
                INSERT INTO 
                gram_coop_influence(object,dn,dg,m,h,prox,delay,factor)
                VALUES($dbid, $dn, $dg, $m, $h, $prox, $delay, $rel_mhg)
            }
        }
    }

    #-------------------------------------------------------------------
    # Time Advance

    # advance
    #
    # Advances the time to match the -clock.  Recomputes satisfaction
    # and other outputs.

    method advance {} {
        # FIRST, update the time.
        assert {[$clock now] > $db(time)}
        set db(timelast) $db(time)
        set db(time) [$clock now]
        set info(changed) 1

        # NEXT, Compute the contribution to each of the curves for
        # this time step.
        $self UpdateCurves

        # NEXT, Compute all roll-ups
        $self ComputeSatRollups
        $self ComputeCoopRollups

        return
    }


    #-------------------------------------------------------------------
    # Satisfaction Roll-ups
    #
    # All roll-ups -- sat.ng, sat.nc, sat.gc, sat.g, sat.c -- all have
    # the same nature.  The computation is a weighted average over
    # a set of satisfaction levels; all that changes is the definition
    # of the set.  The equation for a roll-up over set A is as follows:
    #
    #            Sum            w   * L    * S
    #               n,g,c in A   ng    ngc    ngc
    #  S  =      --------------------------------
    #   A        Sum            w   * L   
    #               n,g,c in A   ng    ngc

    # ComputeSatRollups
    #
    # Computes all satisfaction roll-ups.

    method ComputeSatRollups {} {
        $self ComputeSatGC
        $self ComputeSatNG
        $self ComputeSatNC
        $self ComputeSatN
        $self ComputeSatG
        $self ComputeSatC
    }

    # ComputeSatGC
    #
    # Computes sat.gc, slope.gc by rolling up sat.ngc, slope.ngc.  Note 
    # that inactive pgroups are skipped.

    method ComputeSatGC {} {
        $rdb eval {
            SELECT g, c,
                   total(num)      / total(denom) AS sat,
                   total(numslope) / total(denom) AS slope
            FROM (
                SELECT gram_sat.g                              AS g, 
                       gram_sat.c                              AS c, 
                       gram_sat.sat   * saliency*rollup_weight AS num,
                       gram_sat.slope * saliency*rollup_weight AS numslope,
                       saliency*rollup_weight                  AS denom
                FROM gram_sat JOIN gram_ng USING (ng_id)
                WHERE gram_sat.object = $dbid)
            GROUP BY g, c
        } {
            $rdb eval {
                UPDATE gram_gc
                SET sat   = $sat,
                    slope = $slope
                WHERE object=$dbid AND g=$g and c=$c
            }
        }
    }
    
    # ComputeSatNG
    #
    # Computes the composite satisfaction for each pgroup at time t
    # weighted by the saliency of each concern, within each neighborhood.
    #
    # NOTE: This is the standard roll-up algorithm; however, the 
    # rollup_weight.ng term cancels out.
    
    method ComputeSatNG {} {
        # FIRST, set all to 0.0 for groups for which satisfaction
        # is not tracked.
        $rdb eval {
            UPDATE gram_ng 
            SET sat = 0.0
            WHERE object=$dbid AND sat_tracked = 0
        }

        # NEXT, compute the current values
        $rdb eval {
            SELECT ng_id, n, g,
                   total(num)/total(denom) AS sat
            FROM (
                SELECT ng_id, n, g, 
                       sat*saliency AS num,
                       saliency     AS denom
                FROM gram_sat
                WHERE object = $dbid)
            GROUP BY ng_id
        } {
            $rdb eval {
                UPDATE gram_ng
                SET sat = $sat
                WHERE ng_id = $ng_id
            }
        }
    }
    
    # ComputeSatNC
    #
    # Computes the composite neighborhood satisfaction by concern.
    #
    # Updates sat.nc in place.
    
    method ComputeSatNC {} {
        $rdb eval {
            SELECT n, c,
                   total(num)/total(denom) AS sat
            FROM (
                SELECT gram_sat.n                          AS n, 
                       gram_sat.c                          AS c, 
                       gram_sat.sat*saliency*rollup_weight AS num,
                       saliency*rollup_weight              AS denom
                FROM gram_sat JOIN gram_ng USING (ng_id)
                WHERE gram_sat.object = $dbid)
            GROUP BY n, c
        } {
            $rdb eval {
                UPDATE gram_nc
                SET sat = $sat
                WHERE object=$dbid AND n=$n and c=$c
            }
        }
    }

    # ComputeSatN
    #
    # Computes the overall civilian mood for each nbhood at time t.
    
    method ComputeSatN {} {
        $rdb eval {
            SELECT n,
                   total(num)/total(denom) AS sat
            FROM (
                SELECT gram_sat.n                          AS n, 
                       gram_sat.sat*saliency*rollup_weight AS num,
                       saliency*rollup_weight              AS denom
                FROM gram_sat JOIN gram_ng USING (ng_id)
                WHERE gram_sat.object = $dbid
                AND   gram_sat.gtype = 'CIV')
            GROUP BY n
        } {
            $rdb eval {
                UPDATE gram_n
                SET sat = $sat
                WHERE object=$dbid AND n=$n
            }
        }
    }
    
    # ComputeSatG
    #
    # Computes the toplevel mood for  each pgroup at time t.
    
    method ComputeSatG {} {
        $rdb eval {
            SELECT g,
                   total(num)/total(denom) AS sat
            FROM (
                SELECT gram_sat.g                          AS g,
                       gram_sat.sat*saliency*rollup_weight AS num,
                       saliency*rollup_weight              AS denom
                FROM gram_sat JOIN gram_ng USING (ng_id)
                WHERE gram_sat.object = $dbid)
            GROUP BY g
        } {
            $rdb eval {
                UPDATE gram_g
                SET sat = $sat
                WHERE object=$dbid AND g=$g
            }
        }
    }
    
    # ComputeSatC
    #
    # Computes the composite satisfaction by concern.
    #
    # Updates sat.c in place.
    
    method ComputeSatC {} {
        $rdb eval {
            SELECT c,
                   total(num)/total(denom) AS sat
            FROM (
                SELECT gram_sat.c                          AS c,
                       gram_sat.sat*saliency*rollup_weight AS num,
                       saliency*rollup_weight              AS denom
                FROM gram_sat JOIN gram_ng USING (ng_id)
                WHERE gram_sat.object = $dbid)
            GROUP BY c
        } {
            $rdb eval {
                UPDATE gram_c
                SET sat = $sat
                WHERE object=$dbid AND c=$c
            }
        }
    }

    #-------------------------------------------------------------------
    # Cooperation Roll-ups
    #
    # We only compute one cooperation roll-up, coop.ng: the cooperation
    # of a neighborhood as a whole with a force group.


    # All roll-ups -- sat.ng, sat.nc, sat.gc, sat.g, sat.c -- all have
    # the same nature.  The computation is a weighted average over
    # a set of satisfaction levels; all that changes is the definition
    # of the set.  The equation for a roll-up over set A is as follows:
    #
    #            Sum            w   * L    * S
    #               n,g,c in A   ng    ngc    ngc
    #  S  =      --------------------------------
    #   A        Sum            w   * L   
    #               n,g,c in A   ng    ngc

    # ComputeCoopRollups
    #
    # Computes coop.ng.  The equation is as follows:
    #
    #           Sum  population   * coop
    #              f           nf       nfg
    #  coop   = ---------------------------
    #      ng        Sum  population  
    #                   f           nf

    method ComputeCoopRollups {} {
        # FIRST, compute coop.ng
        $rdb eval {
            SELECT gram_coop.n                                AS n, 
                   gram_coop.f                                AS f, 
                   gram_coop.g                                AS g,
                   total(gram_coop.coop * gram_ng.population) AS num,
                   total(gram_ng.population)                  AS denom
            FROM gram_coop
            JOIN gram_ng ON gram_coop.object = gram_ng.object
                         AND gram_coop.n     = gram_ng.n
                         AND gram_coop.f     = gram_ng.g
            WHERE gram_coop.object=$dbid
            GROUP BY gram_coop.n, gram_coop.g
        } {
            $rdb eval {
                UPDATE gram_frc_ng
                SET coop = $num/$denom
                WHERE object=$dbid AND n=$n AND g=$g
            }
        }
    }
    
    #-------------------------------------------------------------------
    # Satisfaction Queries

    # sat.ngc
    #
    # n     A neighborhood name
    # g     A CIV or ORG group name
    # c     A CIV or ORG concern name
    #
    # Returns the requested satisfaction level.  g and c must have
    # the same type.

    method sat.ngc {n g c} {
        $nbhoods validate $n
        $cogroups validate $g
        $concerns validate $c

        set result [$rdb onecolumn {
            SELECT sat FROM gram_sat 
            WHERE object=$dbid AND n=$n AND g=$g AND c=$c
        }]

        if {$result eq ""} {
            # If the types of g and c don't match, this is
            # an error; otherwise, sat_tracked is 0, so return 0.0

            require {[$rdb exists {
                SELECT gc_id FROM gram_gc 
                WHERE object=$dbid AND g=$g AND c=$c
            }]} "g and c must have the same group type, CIV or ORG"
            
            set result 0.0
        }

        return $result
    }


    # sat.ng
    #
    # n     A neighborhood name
    # g     A CIV or ORG group name
    #
    # Returns the requested satisfaction roll-up.

    method sat.ng {n g} {
        $nbhoods  validate $n
        $cogroups validate $g

        return [$rdb onecolumn {
            SELECT sat FROM gram_ng 
            WHERE object=$dbid AND n=$n AND g=$g
        }]
    }

    # sat.nc
    #
    # n     A neighborhood name
    # c     A CIV or ORG concern name
    #
    # Returns the requested satisfaction roll-up.

    method sat.nc {n c} {
        $nbhoods  validate $n
        $concerns validate $c

        return [$rdb onecolumn {
            SELECT sat FROM gram_nc 
            WHERE object=$dbid AND n=$n AND c=$c
        }]
    }

    # sat.gc
    #
    # g     A CIV or ORG group name
    # c     A CIV or ORG concern name
    #
    # Returns the requested satisfaction roll-up.  g and c must have
    # the same type.

    method sat.gc {g c} {
        $cogroups validate $g
        $concerns validate $c

        set result [$rdb onecolumn {
            SELECT sat FROM gram_gc 
            WHERE object=$dbid AND g=$g AND c=$c
        }]

        # Only empty if g and c don't match
        if {$result eq ""} {
            error "g and c must have the same group type, CIV or ORG"
        }

        return $result
    }

    # sat.n
    #
    # n     A neighborhood name
    #
    # Returns the requested satisfaction roll-up.

    method sat.n {n} {
        $nbhoods  validate $n

        return [$rdb onecolumn {
            SELECT sat FROM gram_n 
            WHERE object=$dbid AND n=$n
        }]
    }


    # sat.g
    #
    # g     A CIV or ORG group name
    #
    # Returns the requested satisfaction roll-up.

    method sat.g {g} {
        $cogroups validate $g

        return [$rdb onecolumn {
            SELECT sat FROM gram_g 
            WHERE object=$dbid AND g=$g
        }]
    }

    # sat.c
    #
    # c     A CIV or ORG concern name
    #
    # Returns the requested satisfaction roll-up.

    method sat.c {c} {
        $concerns validate $c

        return [$rdb onecolumn {
            SELECT sat FROM gram_c 
            WHERE object=$dbid AND c=$c
        }]
    }

    #-------------------------------------------------------------------
    # Cooperation Queries

    # coop.nfg
    #
    # n     A neighborhood name
    # f     A CIV group name
    # g     A FRC group name
    #
    # Returns the requested cooperation level.  Group f must reside
    # in n.

    method coop.nfg {n f g} {
        $nbhoods validate $n
        $cgroups validate $f
        $fgroups validate $g

        set result [$rdb onecolumn {
            SELECT coop FROM gram_coop 
            WHERE object=$dbid AND n=$n AND f=$f AND g=$g
        }]

        if {$result eq ""} {
            error "Group $f does not reside in nbhood $n"
        }

        return $result
    }


    # coop.ng
    #
    # n     A neighborhood name
    # g     A FRC group name
    #
    # Returns the requested cooperation roll-up.

    method coop.ng {n g} {
        $nbhoods validate $n
        $fgroups validate $g

        return [$rdb onecolumn {
            SELECT coop FROM gram_frc_ng 
            WHERE object=$dbid AND n=$n AND g=$g
        }]
    }

    #-------------------------------------------------------------------
    # Satisfaction Adjustments, Level Inputs, and Slope Inputs

    # sat adjust driver n g c mag
    #
    # driver       The driver ID
    # n            Neighborhood name, or "*" for all.
    # g            Group name, or "*" for all.
    # c            Concern name, or "*" for all.
    # mag          Magnitude (a qmag value)
    #
    # Adjusts sat.ngc by the required amount, clamping it within bounds.
    #
    # * The group and concern must have the same group type, CIV or ORG.
    # * The group and concern cannot both be wildcarded.
    #
    # Returns the input ID for this driver.  

    method {sat adjust} {driver n g c mag} {
        $self Log detail "sat adjust driver=$driver n=$n g=$g c=$c M=$mag"

        # FIRST, check the inputs, and accumulate query terms
        set where ""

        # driver
        $self driver validate $driver "Cannot sat adjust"

        # n
        if {$n ne "*"} {
            $nbhoods validate $n
            append where "AND n = \$n "
        }

        # g
        if {$g ne "*"} {
            $cogroups validate $g
            append where "AND g = \$g "
        }

        # c
        if {$c ne "*"} {
            $concerns validate $c
            append where "AND c = \$c "
        }

        # g and c
        #
        # If $g and $c are both *, we don't know which group type to
        # affect.
        #
        # If neither $g and $c is *, the types must match.

        require {$g ne "*" || $c ne "*"} \
            "g and c cannot both be \"*\""

        if {$g ne "*" && $c ne "*"} {
            require {[$rdb exists {
                SELECT gc_id FROM gram_gc 
                WHERE object=$dbid AND g=$g AND c=$c
            }]} "g and c must have the same group type, CIV or ORG"
        }

        # n and g
        #
        # If they chose a specific neighborhood and group,
        # verify that satisfaction is tracked for the pair.
        if {$n ne "*" && $g ne "*"} {
            require {[$rdb onecolumn {
                SELECT sat_tracked FROM gram_ng
                WHERE object=$dbid AND n=$n AND g=$g
            }]} "satisfaction is not tracked for group $g in nbhood $n"
        }


        # qmag
        qmag validate $mag
        set mag [qmag value $mag]

        # NEXT, if the magnitude is zero, there's nothing to do.
        if {$mag == 0.0} {
            return
        }

        # NEXT, do the query.
        $rdb eval "
            SELECT curve_id
            FROM gram_sat
            WHERE object = \$dbid
            $where
        " {
            $self adjust $driver $curve_id $mag
        }

        # NEXT, recompute other outputs that depend on sat.ngc
        $self ComputeSatRollups

        return [$self DriverGetInput $driver]
    }

    # sat set driver n g c mag ?-undo?
    #
    # driver       The driver ID
    # n            Neighborhood name, or "*" for all.
    # g            Group name, or "*" for all.
    # c            Concern name, or "*" for all.
    # sat          Quantity (a qsat value)
    # -undo        Flag; decrements last_input instead of incrementing.
    #
    # Sets sat.ngc to the required value.
    #
    # * The group and concern must have the same group type, CIV or ORG.
    # * The group and concern cannot both be wildcarded.
    #
    # Returns the input ID for this driver.  
    #
    # NOTE: If -undo is given, decrements the last_input counter for this
    # driver, and returns nothing.  This is a stopgap measure to allow
    # sat adjust and sat set to be undone.

    method {sat set} {driver n g c sat {flag ""}} {
        $self Log detail "sat set driver=$driver n=$n g=$g c=$c S=$sat $flag"

        # FIRST, check the inputs, and accumulate query terms
        set where ""

        # driver
        $self driver validate $driver "Cannot sat set"

        # n
        if {$n ne "*"} {
            $nbhoods validate $n
            append where "AND n = \$n "
        }

        # g
        if {$g ne "*"} {
            $cogroups validate $g
            append where "AND g = \$g "
        }

        # c
        if {$c ne "*"} {
            $concerns validate $c
            append where "AND c = \$c "
        }

        # g and c
        #
        # If $g and $c are both *, we don't know which group type to
        # affect.
        #
        # If neither $g and $c is *, the types must match.

        require {$g ne "*" || $c ne "*"} \
            "g and c cannot both be \"*\""

        if {$g ne "*" && $c ne "*"} {
            require {[$rdb exists {
                SELECT gc_id FROM gram_gc 
                WHERE object=$dbid AND g=$g AND c=$c
            }]} "g and c must have the same group type, CIV or ORG"
        }

        # n and g
        #
        # If they chose a specific neighborhood and group,
        # verify that satisfaction is tracked for the pair.
        if {$n ne "*" && $g ne "*"} {
            require {[$rdb onecolumn {
                SELECT sat_tracked FROM gram_ng
                WHERE object=$dbid AND n=$n AND g=$g
            }]} "satisfaction is not tracked for group $g in nbhood $n"
        }


        # qsat
        qsat validate $sat
        set sat [qsat value $sat]

        # NEXT, do the query.
        $rdb eval "
            SELECT curve_id, \$sat - sat AS mag
            FROM gram_sat
            WHERE object = \$dbid
            AND   mag != 0.0
            $where
        " {
            $self adjust $driver $curve_id $mag
        }

        # NEXT, recompute other outputs that depend on sat.ngc
        $self ComputeSatRollups

        # NEXT, return the input ID, or decrement it.
        if {$flag eq "-undo"} {
            $self DriverDecrementInput $driver
            return
        } else {
            return [$self DriverGetInput $driver]
        }
    }

    # sat level driver ts n g c limit days ?options?
    #
    # driver       driver ID
    # ts           Start time, integer ticks
    # n            Neighborhood name, or "*"
    # g            Group name
    # c            Concern name
    # limit        Magnitude of the effect (qmag)
    # days         Realization time of the effect, in days (qduration)
    #
    # Options: 
    #     -cause cause   Name of the cause of this input
    #     -p factor      "near" indirect effects multiplier, defaults to 0
    #     -q factor      "far" indirect effects multiplier, defaults to 0
    #
    # Schedules a new satisfaction level input with the specified parameters.
    #
    # * The group and concern must have the same type, CIV or ORG.
    #
    # Returns the driver input number for this input.  This is
    # a number that starts at 1 and is incremented for each level or slope
    # input received for the driver.

    method {sat level} {driver ts n g c limit days args} {
        $self Log detail "sat level driver=$driver ts=$ts n=$n g=$g c=$c lim=$limit days=$days $args"

        # FIRST, check the regular inputs
        $self driver validate $driver "Cannot sat level"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        if {$n ne "*"} {
            $nbhoods validate $n
        }

        $self ValidateGC $g $c

        qmag      validate $limit
        qduration validate $days

        # NEXT, validate the options
        $self ParseInputOptions opts $args $n

        # NEXT, normalize the input data.

        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(dn)       $n
        set input(dg)       $g
        set input(c)        $c
        set input(ts)       $ts
        set input(days)     [qduration value $days]
        set input(llimit)   [qmag      value $limit]
        set input(p)        $opts(-p)
        set input(q)        $opts(-q)

        # If no cause is given, use the driver.
        # this ensures that truly independent effects are treated as such.
        if {$opts(-cause) ne ""} {
            set input(cause) $opts(-cause)
        } else {
            set input(cause) "D$input(driver)"
        }

        # NEXT, if the limit is 0, ignore it.
        if {$input(llimit) == 0.0} {
            $self Log detail "direct level effect ignored; lim=0.0"
            return $input(input)
        }

        # NEXT, the input aims directly at a single neighborhood, or 
        # at all neighborhoods.  In the former case we can have 
        # indirect effects in near and far neighborhoods.  In the
        # latter case, there are direct effects in every neighborhood,
        # and the indirect effects in other neighborhoods are neglected.

        set epsilon [$parm get gram.epsilon]

        if {$n ne "*"} {
            # ONE NEIGHBORHOOD

            # FIRST, schedule the effects in every influenced neighborhood
            set plimit \
                $proxlimit([$parm get gram.proxlimit])

            # NEXT, use -p and -q to limit the proximity.
            if {$input(q) == 0.0} {
                set plimit [min $plimit $proxlimit(near)]

                if {$input(p) == 0.0} {
                    set plimit [min $plimit $proxlimit(here)]
                }
            }

            # NEXT, schedule the effects in every influenced neighborhood
            # within the proximity limit.
            $rdb eval {
                SELECT * FROM gram_sat_influence_view
                WHERE object = $dbid 
                AND   dn     = $input(dn)
                AND   dg     = $input(dg)
                AND   c      = $input(c)
                AND   prox   < $plimit
            } effect {
                $self ScheduleLevel input effect $epsilon
            }
        } else {
            # ALL NEIGHBORHOODS

            # FIRST, schedule the effects in each neighborhood
            set plimit $proxlimit(here)
            
            $rdb eval {
                SELECT * FROM gram_sat_influence_view
                WHERE object = $dbid 
                AND   dn     = n
                AND   dg     = $input(dg)
                AND   c      = $input(c)
                AND   prox   < $plimit
            } effect {
                set input(dn) $effect(dn)

                $self ScheduleLevel input effect $epsilon
            }
        }

        return $input(input)
    }


    # sat slope driver ts n g c slope ?options...?
    #
    # driver       Driver ID
    # ts           Input start time, integer ticks
    # n            Neighborhood name, or "*"
    # g            Group name
    # c            Concern name
    # slope        Slope (change/day) of the effect (qmag)
    #
    # Options: 
    #     -cause cause   Name of the cause of this input
    #     -p factor      "near" indirect effects multiplier, defaults to 0
    #     -q factor      "far" indirect effects multiplier, defaults to 0
    #
    # Schedules a new GRAM slope input with the specified parameters.
    #
    # * The g and c must have the same group type
    #
    # * A subsequent input for the same driver, n, g, c, and cause will update
    #   all direct and indirect effects accordingly.
    #
    # * Such subsequent inputs must have a start time, ts,
    #   no earlier than the ts of the previous input.

    method {sat slope} {driver ts n g c slope args} {
        $self Log detail \
            "sat slope driver=$driver ts=$ts n=$n g=$g c=$c s=$slope $args"

        # FIRST, validate the regular inputs
        $self driver validate $driver "Cannot sat slope"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        if {$n ne "*"} {
            $nbhoods validate $n
        }

        $self ValidateGC $g $c

        qmag validate $slope

        # NEXT, validate the options
        $self ParseInputOptions opts $args $n

        # NEXT, normalize the input data
        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(dn)       $n
        set input(dg)       $g
        set input(c)        $c
        set input(slope)    [qmag value $slope]
        set input(ts)       $ts
        set input(p)        $opts(-p)
        set input(q)        $opts(-q)

        # NEXT, if the slope is less than epsilon, make it
        # zero.

        set epsilon [$parm get gram.epsilon]

        if {abs($input(slope)) < $epsilon} {
            set input(slope) 0.0
        }

        # If no cause is given, use the Driver ID;
        # this ensures that truly independent effects are treated as such.
        if {$opts(-cause) ne ""} {
            set input(cause) $opts(-cause)
        } else {
            set input(cause) "D$input(driver)"
        }

        # NEXT, the input aims directly at a single neighborhood, or 
        # at all neighborhoods.  In the former case we can have 
        # indirect effects in near and far neighborhoods.  In the
        # latter case, there are direct effects in every neighborhood,
        # and the indirect effects in other neighborhoods are neglected.

        if {$n ne "*"} {
            # ONE NEIGHBORHOOD

            # FIRST, if the slope is 0, ignore it; otherwise,
            # if there are effects on-going terminate all related
            # chains.  Either way, we're done.

            if {$input(slope) == 0.0} {
                $rdb eval {
                    SELECT id, ts, te, cause, delay, future 
                    FROM gram_ngc     AS direct
                    JOIN gram_effects AS effect 
                         ON effect.direct_id = direct.ngc_id
                    WHERE direct.object = $dbid
                    AND   direct.n      = $input(dn) 
                    AND   direct.g      = $input(dg) 
                    AND   direct.c      = $input(c)
                    AND   effect.etype  = 'S'
                    AND   effect.driver = $input(driver)
                    AND   effect.active = 1
                    AND   effect.cause  = $input(cause)
                } row {
                    $self TerminateSlope input row
                }

                return $input(input)
            }

            # NEXT, get the de facto proximity limit.
            set plimit \
                $proxlimit([$parm get gram.proxlimit])

            if {$input(q) == 0.0} {
                if {$input(p) == 0.0} {
                    set plimit [min $plimit $proxlimit(here)]
                } else {
                    set plimit [min $plimit $proxlimit(near)]
                }
            }

            # NEXT, terminate existing slope chains which are outside
            # the de facto proximity limit.
            $rdb eval {
                SELECT id, ts, te, cause, delay, future 
                FROM gram_ngc     AS direct
                JOIN gram_effects AS effect 
                     ON effect.direct_id = direct.ngc_id
                WHERE direct.object =  $dbid
                AND   direct.n      =  $input(dn) 
                AND   direct.g      =  $input(dg) 
                AND   direct.c      =  $input(c)
                AND   effect.etype  =  'S'
                AND   effect.driver =  $input(driver)
                AND   effect.active =  1
                AND   effect.cause  = $input(cause)
                AND   effect.prox   >= $plimit
            } row {
                $self TerminateSlope input row
            }

            # NEXT, schedule the effects in every influenced neighborhood
            # within the proximity limit.
            $rdb eval {
                SELECT * FROM gram_sat_influence_view
                WHERE object    = $dbid 
                AND   dn        = $input(dn)
                AND   dg        = $input(dg)
                AND   c         = $input(c)
                AND   prox      < $plimit
            } chain {
                $self ScheduleSlope input chain $epsilon
            }
        } else {
            # ALL NEIGHBORHOODS: -p and -q are ignored.

            # FIRST, if the slope is 0, ignore it, unless effects
            # are ongoing for this driver, in which case terminate all related
            # chains.  Either way, we're done.

            if {$input(slope) == 0.0} {
                $rdb eval {
                    SELECT id, ts, te, cause, delay, future 
                    FROM gram_ngc     AS direct
                    JOIN gram_effects AS effect 
                         ON effect.direct_id = direct.ngc_id
                    WHERE direct.object =  $dbid
                    AND   direct.g      =  $input(dg) 
                    AND   direct.c      =  $input(c)
                    AND   effect.etype  =  'S'
                    AND   effect.driver =  $input(driver)
                    AND   effect.active =  1
                    AND   effect.cause  = $input(cause)
                } row {
                    $self TerminateSlope input row
                }

                return $input(input)
            }

            # NEXT, schedule the effects in each neighborhood
            set plimit $proxlimit(here)

            $rdb eval {
                SELECT * FROM gram_sat_influence_view
                WHERE object = $dbid 
                AND   dn     = n
                AND   dg     = $input(dg)
                AND   c      = $input(c)
                AND   prox   < $plimit
            } chain {
                set input(dn) $chain(dn)
                $self ScheduleSlope input chain $epsilon
            }
        }

        return $input(input)
    }

    # ParseInputOptions optsArray optsList n
    #
    # optsArray      An array to receive the options
    # optsList       List of options and their values
    # n              Nbhood name, or "*"
    #
    # Sets defaults, processes the optsList, validating each
    # entry, and puts the parsed values in the optsVar.  If
    # any values are invalid, an error is thrown.

    method ParseInputOptions {optsArray optsList n} {
        upvar $optsArray opts

        array set opts {
            -cause ""
            -p     0.0
            -q     0.0
        }
        
        foreach {opt val} $optsList {
            switch -exact -- $opt {
                -cause {
                    set opts($opt) $val
                }
                -p -
                -q {
                    rfraction validate $val

                    if {$n eq "*" &&
                        $val != 0.0
                    } {
                        error "$opt given, but n=\"*\""
                    }
                        
                    set opts($opt) $val
                }

                default {
                    error "invalid option: \"$opt\""
                }
            }
        }
    }

    # sat drivers ?options...?
    #
    # -nbhood      Neighborhood name, or "*" for all (default).
    # -group       Group name, or "*" for all (default).
    # -concern     Concern name, or "*" for all (default), or "mood" for mood
    # -start       Start time; defaults to time 0
    # -end         End time; defaults to latest time
    #
    # This call queries the gram_sat_contribs view, accumulating 
    # contributions over time for a selected set of neighborhoods,
    # groups, and concerns.  If -concern is "mood", then the contribution
    # to mood will be computed for each driver, neighborhood, and group,
    # and added to the output.
    #
    # If no options are specified, the data will be accumulated for 
    # all neighborhoods, groups, and concerns across the entire run
    # of the simulation.
    #
    # The results are stored in the temporary table gram_sat_drivers.
    # The data will persist until the next query, or until the 
    # database is closed.

    method {sat drivers} {args} {
        # FIRST, get the option values.
        array set opts {
            -nbhood  "*"
            -group   "*"
            -concern "*"
            -start   ""
            -end     ""
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            if {$opt ni [array names opts]} {
                error "invalid option: \"$opt\""
            }

            set opts($opt) [lshift args]
        }

        # NEXT, validate the option values, and build up the list
        # of clauses
        set condList [list]

        if {$opts(-nbhood) ne "*"} {
            $nbhoods validate $opts(-nbhood)
            lappend condList {n = $opts(-nbhood)}
        }

        if {$opts(-group) ne "*"} {
            $cogroups validate $opts(-group)
            lappend condList {g = $opts(-group)}
        }

        if {$opts(-concern) ni {"*" "mood"}} {
            $concerns validate $opts(-concern)
            lappend condList {c = $opts(-concern)}
        }

        if {$opts(-group) ne "*" &&
            $opts(-concern) ni {"*" "mood"}
        } {
            $self ValidateGC $opts(-group) $opts(-concern) \
                "-group and -concern"
        }

        if {$opts(-start) ne ""} {
            snit::integer validate $opts(-start)
            lappend condList {time >= $opts(-start)}
        }

        if {$opts(-end) ne ""} {
            snit::integer validate $opts(-end)
            lappend condList {time <= $opts(-end)}
        }

        if {$opts(-start) ne "" &&
            $opts(-end)   ne "" &&
            $opts(-start) > $opts(-end)
        } {
            error "-start > -end"
        }

        # NEXT, clear the table
        $rdb eval {DELETE FROM gram_sat_drivers}

        # NEXT, Do the aggregation
        if {[llength $condList] > 0} {
            set conditions "AND [join $condList { AND }]"
        } else {
            set conditions ""
        }

        $rdb eval "
            INSERT INTO gram_sat_drivers (object, driver, n, g, c, acontrib)
            SELECT object, driver, n, g, c, total(acontrib) 
            FROM gram_sat_contribs
            WHERE object=\$dbid
            $conditions
            GROUP BY driver, n, g, c
        "

        # NEXT, unless they wanted the mood, we're done.
        if {$opts(-concern) ne "mood"} {
            return
        }

        # NEXT, aggregate the saliencies across each n,g
        set condList [list]

        if {$opts(-nbhood) ne "*"} {
            lappend condList {n = $opts(-nbhood)}
        }

        if {$opts(-group) ne "*"} {
            lappend condList {g = $opts(-group)}
        }

        if {[llength $condList] > 0} {
            set conditions "AND [join $condList { AND }]"
        } else {
            set conditions ""
        }

        # NEXT, aggregate the mood for each (driver,n,g).
        $rdb eval {
            SELECT driver, 
                   gram_sat_drivers.n                      AS n, 
                   gram_sat_drivers.g                      AS g, 
                   total(acontrib*saliency/total_saliency) AS mood
            FROM gram_sat_drivers
            JOIN gram_ngc USING (object,n,g,c)
            JOIN gram_ng  USING (object,n,g)
            GROUP BY driver, gram_sat_drivers.n, gram_sat_drivers.g
        } {
            $rdb eval {
                INSERT INTO 
                gram_sat_drivers(object,driver,n,g,c,acontrib)
                VALUES($dbid,$driver,$n,$g,'mood',$mood)
            }
        }
    }

    #-------------------------------------------------------------------
    # Cooperation Adjustments, Level Inputs, and Slope Inputs

    # coop adjust driver n f g mag
    #
    # driver       The driver ID
    # n            Neighborhood name, or "*" for all.
    # f            Civilian group name, or "*" for all.
    # g            Force group name, or "*" for all.
    # mag          Magnitude (a qmag value)
    #
    # Adjusts coop.nfg by the required amount, clamping it within bounds.
    #
    # Returns the input ID for this driver.  

    method {coop adjust} {driver n f g mag} {
        $self Log detail "coop adjust driver=$driver n=$n f=$f g=$g M=$mag"

        # FIRST, check the inputs, and accumulate query terms
        set where ""

        # driver
        $self driver validate $driver "Cannot coop adjust"

        # n
        if {$n ne "*"} {
            $nbhoods validate $n
            append where "AND n = \$n "
        }

        # f
        if {$f ne "*"} {
            $cgroups validate $f
            append where "AND f = \$f "
        }

        # g
        if {$g ne "*"} {
            $fgroups validate $g
            append where "AND g = \$g "
        }

        # n and f
        #
        # If they chose a specific neighborhood and civ group,
        # verify that cooperation is tracked for the pair.
        if {$n ne "*" && $f ne "*"} {
            # TBD: Should we have a "coop_tracked" attribute?
            # Or rename "sat_tracked"?
            require {[$rdb onecolumn {
                SELECT sat_tracked FROM gram_ng
                WHERE object=$dbid AND n=$n AND g=$f
            }]} "cooperation is not tracked for group $f in nbhood $n"
        }


        # qmag
        qmag validate $mag
        set mag [qmag value $mag]

        # NEXT, if the magnitude is zero, there's nothing to do.
        if {$mag == 0.0} {
            return
        }

        # NEXT, do the query.  Note that we could do the adjustment
        # in a single UPDATE query, except that we need to save the
        # adjustment to the history.
        $rdb eval "
            SELECT curve_id
            FROM gram_coop
            WHERE object = \$dbid
            $where
        " {
            $self adjust $driver $curve_id $mag
        }

        # NEXT, compute the cooperation roll-ups
        $self ComputeCoopRollups

        return [$self DriverGetInput $driver]
    }

    # coop set driver n f g coop ?-undo?
    #
    # driver       The driver ID
    # n            Neighborhood name, or "*" for all.
    # f            Civilian group name, or "*" for all.
    # g            Force group name, or "*" for all.
    # mag          Magnitude (a qmag value)
    # -undo        Flag; decrements last_input instead of incrementing.
    #
    # Sets coop.nfg to the required amount.
    #
    # Returns the input ID for this driver.  
    #
    # NOTE: If -undo is given, decrements the last_input counter for this
    # driver, and returns nothing.  This is a stopgap measure to allow
    # coop adjust and coop set to be undone.

    method {coop set} {driver n f g coop {flag ""}} {
        $self Log detail "coop adjust driver=$driver n=$n f=$f g=$g C=$coop $flag"

        # FIRST, check the inputs, and accumulate query terms
        set where ""

        # driver
        $self driver validate $driver "Cannot coop set"

        # n
        if {$n ne "*"} {
            $nbhoods validate $n
            append where "AND n = \$n "
        }

        # f
        if {$f ne "*"} {
            $cgroups validate $f
            append where "AND f = \$f "
        }

        # g
        if {$g ne "*"} {
            $fgroups validate $g
            append where "AND g = \$g "
        }

        # n and f
        #
        # If they chose a specific neighborhood and civ group,
        # verify that cooperation is tracked for the pair.
        if {$n ne "*" && $f ne "*"} {
            # TBD: Should we have a "coop_tracked" attribute?
            # Or rename "sat_tracked"?
            require {[$rdb onecolumn {
                SELECT sat_tracked FROM gram_ng
                WHERE object=$dbid AND n=$n AND g=$f
            }]} "cooperation is not tracked for group $f in nbhood $n"
        }


        # qcooperation
        qcooperation validate $coop
        set coop [qcooperation value $coop]

        # NEXT, do the query.  Note that we could do the adjustment
        # in a single UPDATE query, except that we need to save the
        # adjustment to the history.
        $rdb eval "
            SELECT curve_id, \$coop - coop AS mag
            FROM gram_coop
            WHERE object = \$dbid
            AND   mag != 0.0
            $where
        " {
            $self adjust $driver $curve_id $mag
        }

        # NEXT, compute the cooperation roll-ups
        $self ComputeCoopRollups

        # NEXT, return the input ID, or decrement it.
        if {$flag eq "-undo"} {
            $self DriverDecrementInput $driver
            return
        } else {
            return [$self DriverGetInput $driver]
        }
    }

    # coop level driver ts n f g limit days ?options?
    #
    # driver       Driver ID
    # ts           Start time, integer ticks
    # n            Neighborhood name, or "*"
    # f            Civilian group name
    # g            Force group name
    # limit        Magnitude of the effect (qmag)
    # days         Realization time of the effect, in days (qduration)
    #
    # Options: 
    #     -cause cause   Name of the cause of this input
    #     -p factor      "near" indirect effects multiplier, defaults to 0
    #     -q factor      "far" indirect effects multiplier, defaults to 0
    #
    # Schedules a new cooperation level input with the specified parameters.
    #
    # Returns the driver input number for this input.  This is
    # a number that starts at 1 and is incremented for each level or slope
    # input received for the driver.

    method {coop level} {driver ts n f g limit days args} {
        $self Log detail "coop level driver=$driver ts=$ts n=$n f=$f g=$g lim=$limit days=$days $args"

        # FIRST, check the regular inputs
        $self driver validate $driver "Cannot coop level"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        if {$n ne "*"} {
            $nbhoods validate $n
        }

        $cgroups validate $f
        $fgroups validate $g

        qmag      validate $limit
        qduration validate $days

        # NEXT, validate the options
        $self ParseInputOptions opts $args $n

        # NEXT, normalize the input data.

        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(dn)       $n
        set input(df)       $f
        set input(dg)       $g
        set input(ts)       $ts
        set input(days)     [qduration value $days]
        set input(llimit)   [qmag      value $limit]

        # NEXT, Apply the effects_factor.nf to p and q.
        $rdb eval {
            SELECT effects_factor FROM gram_ng
            WHERE object = $dbid
            AND   n = $input(dn)
            AND   g = $input(df);
        } {
            let input(p) {$opts(-p) * $effects_factor}
            let input(q) {$opts(-q) * $effects_factor}
        }

        # If no cause is given, use the driver.
        # this ensures that truly independent effects are treated as such.
        if {$opts(-cause) ne ""} {
            set input(cause) $opts(-cause)
        } else {
            set input(cause) "D$input(driver)"
        }

        # NEXT, if the limit is 0, ignore it.
        if {$input(llimit) == 0.0} {
            $self Log detail "direct level effect ignored; lim=0.0"
            return $input(input)
        }

        # NEXT, the input aims directly at a single neighborhood, or 
        # at all neighborhoods.  In the former case we can have 
        # indirect effects in near and far neighborhoods.  In the
        # latter case, there are direct effects in every neighborhood,
        # and the indirect effects in other neighborhoods are neglected.

        set epsilon [$parm get gram.epsilon]

        if {$n ne "*"} {
            # ONE NEIGHBORHOOD

            # FIRST, schedule the effects in every influenced neighborhood
            set plimit \
                $proxlimit([$parm get gram.proxlimit])

            # NEXT, use -p and -q to limit the proximity.
            if {$input(q) == 0.0} {
                set plimit [min $plimit $proxlimit(near)]

                if {$input(p) == 0.0} {
                    set plimit [min $plimit $proxlimit(here)]
                }
            }

            # NEXT, schedule the effects in every influenced neighborhood
            # within the proximity limit.

            $rdb eval {
                SELECT * FROM gram_coop_influence_view
                WHERE object    = $dbid
                AND   dn        = $input(dn)
                AND   df        = $input(df)
                AND   dg        = $input(dg)
                AND   prox      < $plimit 
            } effect {
                $self ScheduleLevel input effect $epsilon
            }
        } else {
            # ALL NEIGHBORHOODS

            # FIRST, schedule the effects in each neighborhood
            set plimit $proxlimit(here)

            $rdb eval {
                SELECT * FROM gram_coop_influence_view
                WHERE object    = $dbid
                AND   dn        = m
                AND   df        = $input(df)
                AND   dg        = $input(dg)
                AND   prox      < $plimit 
            } effect {
                set $input(dn) $effect(dn)
                $self ScheduleLevel input effect $epsilon
            }
        }

        return $input(input)
    }

    # coop slope driver ts n f g slope ?options...?
    #
    # driver       Driver ID
    # ts           Start time, integer ticks
    # n            Neighborhood name, or "*"
    # f            Civilian group name
    # g            Force group name
    # slope        Slope (change/day) of the effect (qmag)
    #
    # Options: 
    #     -cause cause   Name of the cause of this input
    #     -p factor      "near" indirect effects multiplier, defaults to 0
    #     -q factor      "far" indirect effects multiplier, defaults to 0
    #
    # Schedules a new GRAM slope input with the specified parameters.
    #
    # * A subsequent input for the same driver, n, f, g, and cause will update
    #   all direct and indirect effects accordingly.
    #
    # * Such subsequent inputs must have a start time, ts,
    #   no earlier than the ts of the previous input.

    method {coop slope} {driver ts n f g slope args} {
        $self Log detail \
            "coop slope driver=$driver ts=$ts n=$n f=$f g=$g s=$slope $args"

        # FIRST, validate the regular inputs
        $self driver validate $driver "Cannot coop slope"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        if {$n ne "*"} {
            $nbhoods validate $n
        }

        $cgroups validate $f
        $fgroups validate $g

        qmag validate $slope

        # NEXT, validate the options
        $self ParseInputOptions opts $args $n

        # NEXT, normalize the input data

        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(dn)       $n
        set input(df)       $f
        set input(dg)       $g
        set input(slope)    [qmag value $slope]
        set input(ts)       $ts
        set input(p)        $opts(-p)
        set input(q)        $opts(-q)

        # NEXT, Apply the effects_factor.nf to p and q.
        $rdb eval {
            SELECT effects_factor FROM gram_ng
            WHERE object = $dbid
            AND   n = $input(dn)
            AND   g = $input(df);
        } {
            let input(p) {$opts(-p) * $effects_factor}
            let input(q) {$opts(-q) * $effects_factor}
        }

        # NEXT, if the slope is less than epsilon, make it
        # zero.

        set epsilon [$parm get gram.epsilon]

        if {abs($input(slope)) < $epsilon} {
            set input(slope) 0.0
        }

        # If no cause is given, use the driver ID;
        # this ensures that truly independent effects are treated as such.
        if {$opts(-cause) ne ""} {
            set input(cause) $opts(-cause)
        } else {
            set input(cause) "D$input(driver)"
        }

        # NEXT, the input aims directly at a single neighborhood, or 
        # at all neighborhoods.  In the former case we can have 
        # indirect effects in near and far neighborhoods.  In the
        # latter case, there are direct effects in every neighborhood,
        # and the indirect effects in other neighborhoods are neglected.

        if {$n ne "*"} {
            # ONE NEIGHBORHOOD

            # FIRST, if the slope is 0, ignore it, unless effects
            # are ongoing for this driver, in which case terminate all related
            # chains.  Either way, we're done.

            if {$input(slope) == 0.0} {
                $rdb eval {
                    SELECT id, ts, te, cause, delay, future 
                    FROM gram_nfg     AS direct
                    JOIN gram_effects AS effect 
                         ON effect.direct_id = direct.nfg_id
                    WHERE direct.object = $dbid
                    AND   direct.n      = $input(dn) 
                    AND   direct.f      = $input(df) 
                    AND   direct.g      = $input(dg) 
                    AND   effect.etype  = 'S'
                    AND   effect.driver = $input(driver)
                    AND   effect.active = 1
                    AND   effect.cause  = $input(cause)
                } effect {
                    $self TerminateSlope input effect
                }

                return $input(input)
            }

            # NEXT, get the de facto proximity limit.
            set plimit \
                $proxlimit([$parm get gram.proxlimit])

            if {$input(q) == 0.0} {
                if {$input(p) == 0.0} {
                    set plimit [min $plimit $proxlimit(here)]
                } else {
                    set plimit [min $plimit $proxlimit(near)]
                }
            }

            # NEXT, terminate existing slope chains which are outside
            # the de facto proximity limit.
            $rdb eval {
                SELECT id, ts, te, cause, delay, future 
                FROM gram_nfg     AS direct
                JOIN gram_effects AS effect 
                     ON effect.direct_id = direct.nfg_id
                WHERE direct.object =  $dbid
                AND   direct.n      =  $input(dn) 
                AND   direct.f      =  $input(df) 
                AND   direct.g      =  $input(dg) 
                AND   effect.etype  =  'S'
                AND   effect.driver =  $input(driver)
                AND   effect.active =  1
                AND   effect.cause  = $input(cause)
                AND   effect.prox   >= $plimit
            } effect {
                $self TerminateSlope input effect
            }

            # NEXT, schedule the effects in every influenced neighborhood
            # within the proximity limit.
            $rdb eval {
                SELECT * FROM gram_coop_influence_view
                WHERE object    = $dbid 
                AND   dn        = $input(dn)
                AND   df        = $input(df)
                AND   dg        = $input(dg)
                AND   prox      < $plimit
            } effect {
                $self ScheduleSlope input effect $epsilon
            }
        } else {
            # ALL NEIGHBORHOODS: -p and -q are ignored.

            # FIRST, if the slope is 0, ignore it, unless effects
            # are on-going for this driver, in which case terminate all related
            # chains.  Either way, we're done.

            if {$input(slope) == 0.0} {
                $rdb eval {
                    SELECT id, ts, te, cause, delay, future 
                    FROM gram_nfg     AS direct
                    JOIN gram_effects AS effect 
                         ON effect.direct_id = direct.nfg_id
                    WHERE direct.object =  $dbid
                    AND   direct.f      =  $input(df) 
                    AND   direct.g      =  $input(dg) 
                    AND   effect.etype  =  'S'
                    AND   effect.driver =  $input(driver)
                    AND   effect.active =  1
                    AND   effect.cause  = $input(cause)
                } effect {
                    $self TerminateSlope input effect
                }

                return $input(input)
            }

            # NEXT, schedule the effects in each neighborhood
            set plimit $proxlimit(here)

            $rdb eval {
                SELECT * FROM gram_coop_influence_view
                WHERE object = $dbid 
                AND   dn     = m
                AND   df     = $input(df)
                AND   dg     = $input(dg)
                AND   prox   < $plimit
            } effect {
                set input(dn) $effect(dn)
                $self ScheduleSlope input effect $epsilon
            }
        }

        return $input(input)
    }


    #-------------------------------------------------------------------
    # Cancellation/Termination of Drivers

    # cancel driver ?-delete?
    #
    # driver        A Driver ID
    #   -delete     If the option is given, the driver ID itself will be
    #               deleted entirely; otherwise, it will remain with a
    #               type of "unknown" and a name of "CANCELLED".
    #
    # Cancels all actual contributions made to any curve by the specified 
    # driver.  Contributions are cancelled by subtracting the
    # "actual' value from the relevant curves and deleting them from the RDB.

    method cancel {driver {option ""}} {
        # FIRST, Update the curves.
        $rdb eval {
            SELECT curve_id, curve_type, total(acontrib) AS actual
            FROM gram_contribs JOIN gram_curves USING (curve_id)
            WHERE gram_contribs.object = $dbid
            AND   driver = $driver
            GROUP BY curve_id
        } {
            $rdb eval {
                UPDATE gram_curves
                SET val = clamp($curve_type,val - $actual)
                WHERE curve_id=$curve_id
            }
        }

        # NEXT, delete the contributions from gram_values
        #
        # TBD: This code can be extremely slow, and needs to 
        # be optimized.  For each contribution for each curve
        # at each timestep, it updates the entire future stream
        # of values.  This can easily be fixed by processing the
        # contributions in time order and keeping a running total
        # of the contributions to date to each curve_id.  Then
        # we just subtract the total to date from each value at
        # each time, as we go.  Or can we?  Will we miss some of
        # the entries that way?  Anyway, it needs to be fixed.
        $rdb eval {
            SELECT curve_id, time, acontrib AS actual
            FROM gram_contribs
            WHERE object = $dbid
            AND   driver = $driver
        } {
            $rdb eval {
                UPDATE OR IGNORE gram_values
                SET val = val - $actual
                WHERE curve_id=$curve_id
                AND   time >= $time
            }
        }

        # NEXT, delete the effects and the contributions.
        $rdb eval {
            DELETE FROM gram_effects 
            WHERE object = $dbid
            AND   driver = $driver;

            DELETE FROM gram_contribs 
            WHERE object = $dbid
            AND   driver = $driver;
        }

        # NEXT, delete or mark the driver.
        if {$option eq "-delete"} {
            $rdb eval {
                DELETE FROM gram_driver
                WHERE object = $dbid
                AND   driver = $driver
            }
        } else {
            $rdb eval {
                UPDATE gram_driver
                SET dtype      = "unknown",
                    name       = "CANCELLED",
                    oneliner   = "",
                    last_input = 0
                WHERE object = $dbid
                AND   driver = $driver
            }
        }

        # NEXT, recompute other outputs that depend on sat.ngc
        $self ComputeSatRollups

        return
    }

    # terminate driver ts
    #
    # driver    A driver ID
    # ts        A start time.
    #
    # Terminates all slope effects for the given driver, just as though
    # they were assigned a zero slope.  Termination of delayed effects 
    # is delayed accordingly.

    method terminate {driver ts} {
        $self Log detail "terminate driver=$driver ts=$ts"

        $self driver validate $driver "Cannot terminate"

        require {[string is integer -strict $ts]} \
            "invalid value \"$ts\", expected integer"

        if {$ts < $db(time)} {
            error "Start time is in the past: \"$ts\""
        }

        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(ts)       $ts
        
        $rdb eval {
            SELECT id, ts, te, cause, delay, future 
            FROM gram_effects
            WHERE object = $dbid
            AND   etype  = 'S'
            AND   driver = $driver
            AND   active = 1
        } row {
            $self TerminateSlope input row
        }
    }

    #-------------------------------------------------------------------
    # Curve Infrastructure

    # CurvesInit
    #
    # Initializes the curves submodule.  The gram_curves table is already
    # populated; but this resets variable data and clears the history.

    method CurvesInit {} {
        $rdb eval {
            DELETE FROM gram_effects  WHERE object=$dbid;
            DELETE FROM gram_contribs WHERE object=$dbid;
            DELETE FROM gram_values   WHERE object=$dbid;
            DELETE FROM gram_driver   WHERE object=$dbid;

            UPDATE gram_curves 
            SET val   = val0,
                delta = 0.0,
                slope = 0.0
            WHERE object=$dbid;
        }

        # NEXT the values as of this time.
        $self SaveValues
    }

    # adjust driver curve_id mag
    #
    # driver         Driver ID
    # curve_id       ID of the curve to adjust
    # mag            Magnitude to adjust by
    #
    # Adjusts the curve by the selected amount, clamping appropriately.

    method adjust {driver curve_id mag} {
        $rdb eval {
            SELECT curve_type, val 
            FROM gram_curves
            WHERE curve_id = $curve_id
        } {
            # FIRST, get the new value
            # TBD: Have a better mechanism for this!
            # If we had the limits in the gram_curves record, a trigger
            # could do the job. Or we could look up the quality object
            # by curve_type.
            if {$curve_type eq "SAT"} {
                set newVal [qsat clamp [expr {$val + $mag}]]
            } else {
                # COOP
                set newVal [qcooperation clamp [expr {$val + $mag}]]
            }

            # Save the new value.
            $rdb eval {
                UPDATE gram_curves
                SET   val = $newVal
                WHERE curve_id = $curve_id
            }

            # NEXT, save this to the history.
            if {[parm get gram.saveHistory]} {
                let realmag {$newVal - $val}

                $rdb eval {
                    INSERT OR IGNORE INTO
                    gram_contribs(object, time, driver,
                                  curve_id, acontrib)
                    VALUES($dbid, $db(time),
                           $driver, $curve_id, 0.0);

                    UPDATE gram_contribs
                    SET acontrib = acontrib + $realmag
                    WHERE time = $db(time)
                    AND   driver = $driver
                    AND   curve_id = $curve_id;
                }
            }

            $self SaveValues $curve_id
        }
    }


    # ScheduleLevel inputArray effectArray epsilon
    #
    # inputArray   Array of data about the current input
    #     driver     Driver ID
    #     input      Input number, for this driver
    #     cause      "Cause" of this input
    #     ts         Start time, in ticks
    #     days       Realization time, in days (TBD: Should be ticks?)
    #     llimit     "level limit", the direct effect magnitude
    #     p          Near effects multiplier
    #     q          Far effects multiplier
    # effectArray  Array of data about the current effect
    #     curve_id   ID of affected curve in gram_curves.
    #     direct_id  ID of entity receiving the direct effect (depends on
    #                curve type).
    #     prox       Proximity, -1 (direct), 0 (here), 1 (near), or 2 (far)
    #     factor     Influence multiplier
    #     delay      Effects delay, in ticks
    # epsilon      The current epsilon
    #
    # Schedules a single level effect

    method ScheduleLevel {inputArray effectArray epsilon} {
        upvar 1 $inputArray input
        upvar 1 $effectArray effect

        # FIRST, determine the real llimit
        if {$effect(prox) == 1} {
            # Near.
            let mult {$input(p) * $effect(factor)}
        } elseif {$effect(prox) == 2} {
            # Far
            let mult {$input(q) * $effect(factor)}
        } else {
            # Here
            set mult $effect(factor)
        }
        
        let llimit {$mult * $input(llimit)}

        if {$llimit == 0.0} {
            # SKIP!
            return
        }

        # NEXT, compute the start time, taking the effects 
        # delay into account.

        let ts {$input(ts) + $effect(delay)}

        # NEXT, Compute te and tau
        if {abs($llimit) <= $epsilon} {
            set te $ts
            set tau 0.0
        } else {
            let te {int($ts + [$clock fromDays $input(days)])}

            # NEXT, compute tau, which determines the shape of the
            # exponential curve.
            let tau {
                $input(days)/
                    (- log($epsilon/abs($llimit)))
            }
        }

        # NEXT, insert the data into gram_effects
        $rdb eval {
            INSERT INTO gram_effects(
                object,
                curve_id,
                direct_id,
                driver,
                input, 
                etype,
                cause,
                prox,
                ts,
                te,
                days, 
                tau,
                llimit
            )
            VALUES(
                $dbid,
                $effect(curve_id),
                $effect(direct_id),
                $input(driver),
                $input(input), 
                'L',
                $input(cause),
                $effect(prox),
                $ts, 
                $te, 
                $input(days), 
                $tau,
                $llimit
            )
        }

        return
    }

    # ScheduleSlope input effect epsilon
    #
    # inputArray   Array of data about the current input
    #     driver     Driver ID
    #     input      Input number, for this driver
    #     cause      "Cause" of this input
    #     ts         Start time, in ticks
    #     slope      Slope, in nominal points/day
    #     p          Near effects multiplier
    #	  q          Far effects multiplier
    # effectArray  Array of data about the current effect
    #     curve_id   ID of affected curve in gram_curves.
    #     direct_id  ID of entity receiving the direct effect (depends on
    #                curve type).
    #     prox       Proximity, -1 (direct), 0 (here), 1 (near), or 2 (far)
    #     factor     Influence multiplier
    #     delay      Effects delay, in ticks
    # epsilon      The current epsilon
    #
    # Schedules or updates a single effect

    method ScheduleSlope {inputArray effectArray epsilon} {
        upvar 1 $inputArray input
        upvar 1 $effectArray effect

        # FIRST, determine the real slope.
        if {$effect(prox) == 1} {
            # Near.
            let mult {$input(p) * $effect(factor)}
        } elseif {$effect(prox) == 2} {
            # Far
            let mult {$input(q) * $effect(factor)}
        } else {
            # Here
            set mult $effect(factor)
        }
        
        let slope {$mult * $input(slope)}

        # NEXT, if the slope is very small, set it to
        # zero.
        if {abs($slope) < $epsilon} {
            set slope 0.0
        }

        # NEXT, compute the start time, taking the effects 
        # delay into account.
        let ts {$input(ts) + $effect(delay)}

        # NEXT, if the driver already has an entry in gram_effects,
        # we need to update the entry. Get the ID of the chain's entry, if 
        # any.
        set old(id) ""

        $rdb eval {
            SELECT id, active, cause, ts, te, future 
            FROM gram_effects
            WHERE object=$dbid
            AND etype='S'
            AND driver=$input(driver)
            AND curve_id=$effect(curve_id)
            AND direct_id=$effect(direct_id)
            AND cause = $input(cause)
        } old {}

        # NEXT, if a chain exists, update it.
        if {$old(id) ne ""} {
            # FIRST, if the chain is inactive, and this 
            # link has 0 slope, we can skip it; adding another
            # link won't change anything.
            if {!$old(active) && $slope == 0.0} {
                # SKIP!
                return
            }

            # NEXT, check the time constraints, and update te if
            # necessary.
            if {[llength $old(future)] == 0} {
                set te $ts
                set tPrev $old(ts)
            } else {
                set te $old(te)
                set tPrev [lindex $old(future) end-1]
            }

            require {$ts >= $tPrev} \
                "slope scheduled in decreasing time sequence: $ts < $tPrev"

            # NEXT, add this link's data to the profile
            lappend old(future) $ts $slope
            
            # NEXT, update the record, and mark it active.
            $rdb eval {
                UPDATE gram_effects
                SET input = $input(input),
                te = $te,
                future = $old(future),
                active = 1  
                WHERE id=$old(id)
            }

            # NEXT, we're done here.
            return
        }

        # NEXT, this is the first link in a new chain.  There's
        # no point in creating the record if the slope
        # is zero.

        if {$slope == 0.0} {
            # SKIP!
            return
        }

        # NEXT, Save the new effect.
        $rdb eval {
            INSERT INTO gram_effects(
                object,
                etype,
                curve_id,
                direct_id,
                driver,
                input,
                prox,
                delay,
                cause,
                slope,
                ts,
                te
            )
            VALUES(
                $dbid,
                'S',
                $effect(curve_id),
                $effect(direct_id),
                $input(driver),
                $input(input),
                $effect(prox),
                $effect(delay),
                $input(cause),
                $slope,
                $ts,
                $maxEndTime
            );
        }

        return
    }

    # TerminateSlope inputArray effectArray
    #
    # inputArray   Array of data about the current input
    #     ts         Termination time, in ticks
    #     input      Input number for driver
    # effectArray  Array of data about the current effect in gram_effects
    #     id         ID of gram_effects record
    #     ts         Start time of current slope, in ticks
    #     te         End time of current slope, in ticks
    #     delay      Delay of this effect, in ticks
    #     future     Future slopes
    #
    # Terminates a slope effect by scheduling a slope of 0
    # after the appropriate time delay.
    #
    # Constraints: The relevant effect already exists in gram_effects 
    # and is active.

    method TerminateSlope {inputArray effectArray} {
        upvar 1 $inputArray  input
        upvar 1 $effectArray effect

        # FIRST, compute the termination time, taking the effects 
        # delay into account.
        let ts {$input(ts) + $effect(delay)}

        # NEXT, check the time constraints, and update te if
        # necessary.
        if {[llength $effect(future)] == 0} {
            set te $ts
            set tPrev $effect(ts)
        } else {
            set te $effect(te)
            set tPrev [lindex $effect(future) end-1]
        }

        require {$ts >= $tPrev} \
            "slope scheduled in decreasing time sequence: $ts < $tPrev"

        # NEXT, add this link's data to the profile
        lappend effect(future) $ts 0.0
                 
        # NEXT, update the record.
        $rdb eval {
            UPDATE gram_effects
            SET input    = $input(input),
                te       = $te,
                future   = $effect(future)
            WHERE id=$effect(id)
        }

        # NEXT, we're done here.
        return
    }

    #-------------------------------------------------------------------
    # Misc. Output Methods

    # nbhood    A neighborhood name or index
    #
    # Returns a list of the CIV groups that reside in nbhood.

    method nbhoodGroups {nbhood} {
        $nbhoods validate $nbhood

        $rdb eval {
            SELECT g
            FROM gram_ng JOIN gram_g USING (object,g)
            WHERE object       = $dbid
            AND   n            = $nbhood
            AND   sat_tracked  = 1
            AND   gram_g.gtype = 'CIV'
            ORDER BY g
        }
    }

    #-------------------------------------------------------------------
    # Time-Dependent Variable (outputs) Access Methods

    # time
    #
    # Current gram(n) simulation time.
    method time {} { 
        return $db(time) 
    }

    #-------------------------------------------------------------------
    # Effect Curves
    #
    # An effect curve is a variable whose value can vary over time,
    # subject to level and slope effects, e.g., a satisfaction or 
    # cooperation curve.  This section of the module contains the 
    # generic effect curve code.
    #
    # The following tables are used:
    #
    #   gram_curves          One record per curve, including current value.
    #   gram_effects         One record per level/slope effect
    #   gram_contribs        History of contributions to curves.
    #   gram_values          History of curve values.
    #
    # Other sections of this module will provide identities to specific
    # curves.  The satisfaction section, for example, maps n,g,c
    # combinations to particular curves.

    # UpdateCurves
    #
    # Applies level and slope effects to curves for the time interval
    # from timelast to time.  Computes the current value for each
    # curve and the slope for the current time advance.

    method UpdateCurves {} {
        # FIRST, initialize the delta for this time step to 0.
        $rdb eval {
            UPDATE gram_curves
            SET delta = 0.0
            WHERE object=$dbid;
        }

        # NEXT, Add the contributions of the level and slope effects.
        $self ComputeNominalContributionsForLevelEffects
        $self ComputeNominalContributionsForSlopeEffects
        $self ComputeActualContributionsByCause
        $self ExpireEffects
        $self SaveContribs

        # NEXT, Compute the current value and slope, clamping the
        # current value within its upper and lower bounds.

        set deltaDays [$clock toDays [expr {$db(time) - $db(timelast)}]]

        $rdb eval {
            UPDATE gram_curves
            SET val   = max(min(val + delta, 100.0), -100.0),
                slope = delta / $deltaDays
            WHERE object=$dbid;
        }

        # NEXT, save the current values.
        $self SaveValues
    }

    # ComputeNominalContributionsForLevelEffects
    #
    # Computes the nominal contribution of each active level effect to each
    # curve for this time step.

    method ComputeNominalContributionsForLevelEffects {} {
        # FIRST, get parameter values
        set plimit \
            $proxlimit([$parm get gram.proxlimit])

        # NEXT, for each level effect for which the start time has
        # been reached and which has not yet expired, compute its nominal
        # contribution.
        $rdb eval {
            SELECT ts, te, llimit, tau, nominal, id, curve_type, val 
            FROM gram_effects JOIN gram_curves USING (curve_id)
            WHERE gram_effects.object=$dbid
            AND etype = 'L'
            AND active = 1 
            AND ts < $db(time)
            AND prox < $plimit
        } row {
            # FIRST, Compute the nominal increment.
            if {$db(time) >= $row(te)} {
                # FIRST, get all of the remaining change.
                set valueNow $row(llimit)
            } elseif {$db(time) <= $row(ts)} {
                set valueNow 0.0
            } else {
                # FIRST, compute the increment over the previous
                # nominal contribution to date.
                assert {$row(tau) != 0.0}

                let deltaDays {double($db(time) - $row(ts))/1440.0}

                let valueNow {
                    $row(llimit) * (1.0 - exp(-$deltaDays/$row(tau)))
                }
            }

            let contrib {$valueNow - $row(nominal)}

            # NEXT, add the increment to this effect's nominal
            # contribution to date.
            let row(nominal) {$row(nominal) + $contrib}

            $rdb eval {
                UPDATE gram_effects
                SET tlast    = $db(time),
                    nominal  = $row(nominal),
                    ncontrib = $contrib
                WHERE id=$row(id);
            }
        }
    }

    # ComputeNominalContributionsForSlopeEffects
    #
    # Computes the nominal contribution of each active slope effect to each
    # curve for this time advance.

    method ComputeNominalContributionsForSlopeEffects {} {
        # FIRST, get parameter values
        set plimit \
            $proxlimit([$parm get gram.proxlimit])

        # NEXT, Get each slope effect that's been active during
        # the last time step, and compute and save their nominal 
        # contributions.

        $rdb eval {
            SELECT id, 
                   nominal, 
                   ts, 
                   te, 
                   gram_effects.slope AS slope,
                   future,
                   gram_curves.val AS val,
                   curve_type
            FROM gram_effects JOIN gram_curves USING (curve_id)
            WHERE gram_effects.object=$dbid
            AND etype='S'
            AND active = 1 
            AND ts <= $db(time)
            AND prox < $plimit
        } row {
            # FIRST, the effect may be a chain with two or more 
            # links active during this time step.  Loop over them,
            # and accumulate the nominal contributions.

            set ncontrib 0.0

            while {1} {
                # FIRST, get the duration for which this link applies
                # during the last step.
                set ts [max $row(ts) $db(timelast)]
                set te [min $row(te) $db(time)]
                
                set step [expr {$te - $ts}]
                set stepDays [$clock toDays $step]

                # NEXT, Get the nominal contribution of this link in the
                # chain.
                
                let nvalue       {$row(slope)*$stepDays}
                let row(nominal) {$row(nominal) + $nvalue}
                let ncontrib     {$ncontrib + $nvalue}

                # NEXT, if there's another active link get it.
                if {$row(te) < $db(time)} {
                    set row(ts)     [lindex $row(future) 0]
                    set row(slope)  [lindex $row(future) 1]
                    set row(future) [lrange $row(future) 2 end]

                    if {[llength $row(future)] == 0} {
                        set row(te) $maxEndTime
                    } else {
                        set row(te) [lindex $row(future) 0]
                    }

                    $rdb eval {
                        UPDATE gram_effects
                        SET ts     = $row(ts),
                            te     = $row(te),
                            slope  = $row(slope),
                            future = $row(future)
                        WHERE id=$row(id)
                    }
                } else {
                    # We're done
                    break
                }
            }

            
            $rdb eval {
                UPDATE gram_effects
                SET tlast    = $db(time),
                    nominal  = $row(nominal),
                    ncontrib = $ncontrib
                WHERE id=$row(id)
            }
        }
    }

    # ComputeActualContributionsByCause
    #
    # Determine the maximum positive and negative contributions
    # for each curve and cause, scale them, and apply them.

    method ComputeActualContributionsByCause {} {
        $rdb eval {
            SELECT curve_id   AS curve_id, 
                   cause      AS cause,
                   max(pos)   AS maxpos,
                   sum(pos)   AS sumpos,
                   min(neg)   AS minneg,
                   sum(neg)   AS sumneg,
                   curve_type AS curve_type,
                   val        AS current
            FROM
            (SELECT curve_id, cause, curve_type, val,
                    CASE WHEN ncontrib > 0 THEN ncontrib ELSE 0 END AS pos,
                    CASE WHEN ncontrib < 0 THEN ncontrib ELSE 0 END AS neg
             FROM gram_effects JOIN gram_curves USING (curve_id)
             WHERE gram_effects.object=$dbid
             AND active=1)
            GROUP BY curve_id, cause
        } {
            # FIRST, get the scaling factor.
            set contrib [expr {$maxpos + $minneg}]

            if {$contrib > 0} {
                set sign 1.0
            } else {
                set sign -1.0
            }

            set scale [ScaleFactor $curve_type $current $sign]

            # NEXT, compute and apply the actual contribution
            set acontrib [expr {$scale * $contrib}]

            $rdb eval {
                UPDATE gram_curves
                SET delta = delta + $acontrib
                WHERE curve_id=$curve_id
            }

            # NEXT, store the positive effects by id and cause
            if {$maxpos > 0.0} {
                let poscontribs($curve_id,$cause) {$maxpos*$scale/$sumpos}
            }
            
            # NEXT, store the negative effects by id and cause
            if {$minneg < 0.0} {
                let negcontribs($curve_id,$cause) {$minneg*$scale/$sumneg}
            }
        }

        # NEXT, give effects credit for their contribution
        # in proportion to their magnitude.
        $rdb eval {
            SELECT id       AS id,
                   curve_id AS curve_id,
                   cause    AS cause,
                   ncontrib AS ncontrib
            FROM gram_effects
            WHERE object    = $dbid
            AND   active    = 1
            AND   ncontrib != 0.0
        } {

            # NEXT, retrieve the multiplier based on the nominal conribution
            if {$ncontrib < 0.0} {
                set mult $negcontribs($curve_id,$cause)
            } else {
                set mult $poscontribs($curve_id,$cause)
            } 

            # NEXT update the effects
            $rdb eval {
                UPDATE gram_effects
                SET acontrib = ncontrib*$mult,
                    actual   = actual + ncontrib*$mult
                WHERE id=$id
            }
        }
    }

    # ExpireEffects
    #
    # Mark expired effects inactive.

    method ExpireEffects {} {
        # FIRST, get the current proximity limit.
        set plimit \
            $proxlimit([$parm get gram.proxlimit])

        # NEXT, Expire level and slope effects.
        #
        # Expire effects if the proxlimit has changed to
        # exclude them.
        #
        # Expire level effects if their full time has elapsed.
        #
        # Expire slope effects if they have reached their end time.

        $rdb eval {
            UPDATE gram_effects
            SET active = 0
            WHERE object=$dbid 
            AND active = 1
            AND (
                -- proxlimit has changed to exclude them, OR
                (prox >= $plimit) OR 

                -- level effect's time has elapsed
                (etype = 'L' AND te <= $db(time)) OR

                -- slope effect's is endlessly 0.0
                (etype = 'S' AND slope == 0 AND te = $maxEndTime)
            )
        }
    }

    # SaveContribs
    #
    # Saves the total actual contributions for level and slope effects
    # by driver and curve.

    method SaveContribs {} {
        # FIRST, save the history data, if that's what we want to do
        set pname gram.saveHistory

        if {![$parm get $pname]} {
            # No need to log this; SaveHistory will do so.
            return
        }

        $rdb eval {
            INSERT INTO gram_contribs
            SELECT $dbid, tlast, driver, curve_id,
                   total(acontrib) as acontrib
            FROM gram_effects
            WHERE object=$dbid AND tlast=$db(time) AND acontrib != 0.0
            GROUP BY driver, curve_id
        }
    }

    # SaveValues ?curve_id?
    #
    # curve_id     A curve ID; defaults to all curves
    #
    # Saves the current value of the specified curve, or of all
    # curves, to gram_values.

    method SaveValues {{curve_id ""}} {
        # FIRST, save the history data, if that's what we want to do
        set pname gram.saveHistory

        if {![$parm get $pname]} {
            $self Log warning \
                "no history saved; $pname is \"[$parm get $pname]\""
            return
        }

        set query {
            INSERT OR REPLACE
            INTO gram_values(object, time, curve_id, val)
            SELECT object, $db(time), curve_id, val
            FROM gram_curves
            WHERE object=$dbid
        }

        if {$curve_id ne ""} {
            append query {
                AND curve_id=$curve_id
            }
        }

        $rdb eval $query
    }


    #-------------------------------------------------------------------
    # Data dumping methods

    # dump sat.ngc ?options?
    #
    # -civ              Include CIV groups
    # -org              Include ORG groups
    # -nbhood n         Neighborhood name or *
    # -group  g         Group name or *
    #
    # Dumps a pretty-printed gram_sat table.
    #
    # By default, both CIV and ORG groups are included.
    # If a specific group is specified, then -civ and -org are 
    # ignored.

    method {dump sat.ngc} {args} {
        # FIRST, set the defaults
        set conditions [list]
        set civFlag 0
        set orgFlag 0
        set n       "*"
        set g       "*"

        # NEXT, get the options
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -civ    { set civFlag 1       }
                -org    { set orgFlag 1       }
                -nbhood { set n [string toupper [lshift args]] }
                -group  { set g [string toupper [lshift args]] }

                default {
                    error "Unknown option name, \"$opt\""
                }
            }
        }

        # NEXT, validate the option values.
        
        # Group
        if {$g ne "*"} {
            $cogroups validate $g
        }

        # Nbhood
        if {$n ne "*"} {
            $nbhoods validate $n
        }

        # Civ, Org flags
        #
        # If both are given, neither are needed; and if -group is given,
        # neither are needed

        if {($civFlag && $orgFlag) ||
            $g ne "*"
        } {
            set civFlag 0
            set orgFlag 0
        }

        # NEXT, define the query
        set query [tsubst {
            |<--
            SELECT n,
                   g,
                   c,
                   format('%7.2f', gram_sat.sat),
                   format('%7.2f', gram_sat.sat - gram_sat.sat0),
                   format('%7.2f', gram_sat.sat0),
                   format('%7.2f', gram_sat.slope),
                   format('%7.2f', gram_sat.trend), 
                   ngc_id,
                   curve_id
            FROM gram_sat
            JOIN gram_g  USING (object,g)
            WHERE object='$dbid'
            [tif {$civFlag}  {AND gram_g.gtype='CIV'}]
            [tif {$orgFlag}  {AND gram_g.gtype='ORG'}]
            [tif {$n ne "*"} {AND n='$n'}]
            [tif {$g ne "*"} {AND g='$g'}]
            ORDER BY ngc_id
        }]

        set labels {
            "Nbhood" "Group" "Con" "Sat" "Delta" "Sat0"
            "Slope" "Trend0" "NGC ID" "Curve ID"
        }

        set result [$rdb query $query -headercols 2 -labels $labels]

        if {$result eq ""} {
            set result "No matching data"
        }

        return $result
    }

    # dump sat levels ?driver?
    #
    # Returns a pretty-printed list of active level effects, one per line.
    # If driver is given, only those effects that match are included.  

    method {dump sat levels} {{driver "*"}} {
        return [$rdb query "
            SELECT driver || '.' || input,
                   dn,
                   dg,
                   cause,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END,
                   tozulu(ts),
                   tozulu(te),
                   n,
                   g,
                   c,
                   format('%5.3f',days),
                   format('%5.1f',llimit),
                   format('%6.2f',nominal),
                   format('%6.2f',actual)
            FROM gram_sat_effects
            WHERE object='$dbid'
            AND etype='L'
            AND active=1 AND driver GLOB '$driver'
            
            ORDER BY driver ASC, input ASC, 
                     dn ASC, dg ASC, cause ASC, 
                     prox ASC, n ASC, g ASC, ts ASC, c ASC, id ASC
        " -labels {
            "Input" "DN" "DG" "Cause" "E" 
            "Start Time" "End Time" 
            "Nbhd" "Grp" "Con" 
            "Days" "Limit" "Nominal" "Actual"
        } -headercols 4]
    }

    # dump coop.nfg ?options?
    #
    # -nbhood n         Neighborhood name or *
    # -civ    f         Civilian Group name or *
    # -frc    g         Force Group name, or *
    # -ids              Includes curve IDs
    #
    # Dumps a pretty-printed gram_coop table.

    method {dump coop.nfg} {args} {
        # FIRST, set the defaults
        set conditions [list]
        set n       "*"
        set f       "*"
        set g       "*"
        set idflag  0

        # NEXT, get the options
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -nbhood { set n [string toupper [lshift args]] }
                -civ    { set f [string toupper [lshift args]] }
                -frc    { set g [string toupper [lshift args]] }
                -ids    { set idflag 1 }

                default {
                    error "Unknown option name, \"$opt\""
                }
            }
        }

        # NEXT, validate the option values.
        
        # Nbhood
        if {$n ne "*"} {
            $nbhoods validate $n
        }

        # CIV Group
        if {$f ne "*"} {
            $cgroups validate $f
        }

        # FRC Group
        if {$g ne "*"} {
            $fgroups validate $g
        }

        # NEXT, define the query
        set query [tsubst {
            |<--
            SELECT n,
                   f,
                   g,
                   format('%7.2f', coop),
                   format('%7.2f', coop - coop0),
                   format('%7.2f', coop0),
                   format('%7.2f', slope)
            [tif {$idflag} {,
                   nfg_id,
                   curve_id
            }]
            FROM gram_coop
            WHERE object='$dbid'
            [tif {$n ne "*"} {AND n='$n'}]
            [tif {$f ne "*"} {AND f='$f'}]
            [tif {$g ne "*"} {AND g='$g'}]
            ORDER BY nfg_id
        }]

        set labels {
            "Nbhood" "CivGrp" "FrcGrp" "Coop" "Delta" "Coop0"
            "Slope"
        }

        if {$idflag} {
            lappend labels  "NFG ID" "Curve ID"
        }

        set result [$rdb query $query -headercols 2 -labels $labels]

        if {$result eq ""} {
            set result "No matching data"
        }

        return $result
    }

    # dump coop levels ?driver?
    #
    # Returns a pretty-printed list of active level effects, one per line.
    # If driver is given, only those effects that match are included.  

    method {dump coop levels} {{driver "*"}} {
        return [$rdb query "
            SELECT driver || '.' || input,
                   dn,
                   df,
                   dg,
                   cause,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END,
                   tozulu(ts),
                   tozulu(te),
                   n,
                   f,
                   g,
                   format('%5.3f',days),
                   format('%5.1f',llimit),
                   format('%6.2f',nominal),
                   format('%6.2f',actual)
            FROM gram_coop_effects
            WHERE object='$dbid'
            AND etype='L'
            AND active=1 AND driver GLOB '$driver'
            
            ORDER BY driver ASC, input ASC, 
                     dn ASC, df ASC, dg ASC, cause ASC, 
                     prox ASC, n ASC, f ASC, g ASC, ts ASC, id ASC
        " -labels {
            "Input" "DN" "DF" "DG" "Cause" "E" 
            "Start Time" "End Time" 
            "N" "F" "G" 
            "Days" "Limit" "Nominal" "Actual"
        } -headercols 5]
    }

    # dump sat level n g c
    #
    # n       A neighborhood name
    # g       A group name
    # c       A concern name
    #
    # Returns a pretty-printed list of the active level effects acting
    # on the specific satisfaction level, one per line, sorted by
    # cause.

    method {dump sat level} {n g c} {
        # FIRST, validate the inputs
        $nbhoods  validate $n

        $self ValidateGC $g $c

        return [$rdb query "
            SELECT cause,
                   tozulu(ts),
                   tozulu(te),
                   format('%5.1f',llimit),
                   format('%6.2f',nominal),
                   format('%7.3f',ncontrib),
                   format('%6.2f',actual),
                   format('%7.3f',acontrib),
                   driver || '.' || input,
                   dn,
                   dg,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END
            FROM gram_sat_effects
            WHERE object='$dbid' 
            AND etype='L'
            AND active=1 
            AND n='$n' AND g='$g' AND c='$c'
            ORDER BY cause ASC, ts ASC, llimit DESC
        " -labels {
            "Cause" "Start Time" "End Time" 
            "Limit" "NTotal" "NContrib" "ATotal" "AContrib" 
            "Input" "DN" "DG" "E"
        } -headercols 3]
    }

    # dump coop level n f g
    #
    # n       A neighborhood name
    # f       A CIV group name
    # g       A FRC group name
    #
    # Returns a pretty-printed list of the active level effects acting
    # on the specific cooperation level, one per line, sorted by
    # cause.

    method {dump coop level} {n f g} {
        # FIRST, validate the inputs
        $nbhoods validate $n
        $cgroups validate $f
        $fgroups validate $g

        return [$rdb query "
            SELECT cause,
                   tozulu(ts),
                   tozulu(te),
                   format('%5.1f',llimit),
                   format('%6.2f',nominal),
                   format('%7.3f',ncontrib),
                   format('%6.2f',actual),
                   format('%7.3f',acontrib),
                   driver || '.' || input,
                   dn,
                   df,
                   dg,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END
            FROM gram_coop_effects
            WHERE object='$dbid' 
            AND etype='L'
            AND active=1 
            AND n='$n' AND f='$f' AND g='$g'
            ORDER BY cause ASC, ts ASC, llimit DESC
        " -labels {
            "Cause" "Start Time" "End Time" 
            "Limit" "NTotal" "NContrib" "ATotal" "AContrib" 
            "Input" "DN" "DF" "DG" "E"
        } -headercols 3]
    }

    # dump sat slopes ?driver?
    #
    # Returns a pretty-printed list of slope effects, one per line.
    # If driver is given, only those effects that match are included.
    #
    # TBD: The disaggregation of the "future" column can be done in
    # one routine shared with [dump coop slopes].

    method {dump sat slopes} {{driver ""}} {
        # FIRST, build a temporary table, then query it, then destroy
        # it.
        $rdb eval {
            DROP TABLE IF EXISTS temp_gram_slope_query;

            CREATE TEMP TABLE temp_gram_slope_query(
                driver,
                input,
                dn,
                dg,
                cause,
                prox,
                ts,
                te,
                n,
                g,
                c,
                slope,
                nominal,
                actual
            );
        }

        $rdb eval { 
            SELECT driver,
                   input,
                   dn,
                   dg,
                   cause,
                   prox,
                   ts,
                   te,
                   future,
                   n,
                   g,
                   c,
                   slope,
                   nominal,
                   actual
            FROM gram_sat_effects
            WHERE object=$dbid 
            AND etype='S'
            AND active=1 
            AND (($driver != '' AND driver = $driver) OR
                 ($driver =  '' AND driver > 0))
            ORDER BY driver ASC, input ASC,
                     dn ASC, dg ASC, cause ASC, 
                     prox ASC, n ASC, g ASC, ts ASC, c ASC, id ASC
        } row {
            set future \
                [linsert $row(future) 0 $row(ts) $row(slope)]

            while {[llength $future] > 0} {
                set ts     [lshift future]
                set slope  [lshift future]
                set te     [lindex $future 0]

                if {$te eq ""} {
                    set te $maxEndTime
                }

                $rdb eval {
                    INSERT INTO temp_gram_slope_query(
                        driver,
                        input,
                        dn,
                        dg,
                        cause,
                        prox,
                        ts,
                        te,
                        n,
                        g,
                        c,
                        slope,
                        nominal,
                        actual
                    )
                    VALUES(
                        $row(driver),
                        $row(input),
                        $row(dn),
                        $row(dg),
                        $row(cause),
                        $row(prox),
                        $ts,
                        CAST ($te AS INTEGER),
                        $row(n),
                        $row(g),
                        $row(c),
                        $slope,
                        $row(nominal),
                        $row(actual)
                    );
                }
            }
        }

        set out [$rdb query "
            SELECT driver || '.' || input,
                   dn,
                   dg,
                   cause,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END,
                   tozulu(ts) AS ts,
                   CASE WHEN te=$maxEndTime THEN 'n/a' ELSE tozulu(te) END,
                   n,
                   g,
                   c,
                   format('%5.1f',slope),
                   format('%5.1f',nominal),
                   format('%5.1f',actual)
            FROM temp_gram_slope_query
        " -labels {
            "Input" "DN" "DG" "Cause" "E" 
            "Start Time" "End Time" "Nbhd" "Grp" "Con"  
            "Slope" "Nominal" "Actual"
        } -headercols 4]

        return $out
    }

    # dump coop slopes ?driver?
    #
    # Returns a pretty-printed list of slope effects, one per line.
    # If driver is given, only those effects that match are included.  

    method {dump coop slopes} {{driver "*"}} {
        # FIRST, build a temporary table, then query it, then destroy
        # it.
        $rdb eval {
            DROP TABLE IF EXISTS temp_gram_slope_query;

            CREATE TEMP TABLE temp_gram_slope_query(
                driver,
                input,
                dn,
                df,
                dg,
                cause,
                prox,
                ts,
                te,
                n,
                g,
                slope,
                nominal,
                actual
            );
        }

        $rdb eval " 
            SELECT driver,
                   input,
                   dn,
                   df,
                   dg,
                   cause,
                   prox,
                   ts,
                   te,
                   future,
                   n,
                   g,
                   slope,
                   nominal,
                   actual
            FROM gram_coop_effects
            WHERE object='$dbid' 
            AND etype='S'
            AND active=1 
            AND driver GLOB '$driver'
            ORDER BY driver ASC, input ASC,
                     dn ASC, df ASC, dg ASC, cause ASC, 
                     n ASC, g ASC, prox ASC, ts ASC, id ASC
        " row {
            set future \
                [linsert $row(future) 0 $row(ts) $row(slope)]

            while {[llength $future] > 0} {
                set ts     [lshift future]
                set slope  [lshift future]
                set te     [lindex $future 0]

                if {$te eq ""} {
                    set te $maxEndTime
                }

                $rdb eval {
                    INSERT INTO temp_gram_slope_query(
                        driver,
                        input,
                        dn,
                        df,
                        dg,
                        cause,
                        prox,
                        ts,
                        te,
                        n,
                        g,
                        slope,
                        nominal,
                        actual
                    )
                    VALUES(
                        $row(driver),
                        $row(input),
                        $row(dn),
                        $row(df),
                        $row(dg),
                        $row(cause),
                        $row(prox),
                        $ts,
                        $te,
                        $row(n),
                        $row(g),
                        $slope,
                        $row(nominal),
                        $row(actual)
                    );
                }
            }
        }

        set out [$rdb query "
            SELECT driver || '.' || input,
                   dn,
                   df,
                   dg,
                   cause,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END,
                   tozulu(ts) AS ts,
                   CASE WHEN te = CAST ($maxEndTime AS INTEGER) 
                        THEN 'n/a' ELSE tozulu(te) END,
                   n,
                   df,
                   g,
                   format('%5.1f',slope),
                   format('%5.1f',nominal),
                   format('%5.1f',actual)
            FROM temp_gram_slope_query
        " -labels {
            "Input" "DN" "DF" "DG" "Cause" "E" 
            "Start Time" "End Time" "N" "F" "G"  
            "Slope" "Nominal" "Actual"
        } -headercols 5]

        return $out
    }


    # dump sat slope n g c
    #
    # n       A neighborhood name
    # g       A group name
    # c       A concern name
    #
    # Returns a pretty-printed list of the active slope effects acting
    # on the specific satisfaction level, one per line, sorted by
    # cause.

    method {dump sat slope} {n g c} {
        # FIRST, validate the inputs
        $nbhoods  validate $n

        $self ValidateGC $g $c

        return [$rdb query "
            SELECT cause,
                   tozulu(ts),
                   CASE WHEN te=$maxEndTime THEN 'n/a' ELSE tozulu(te) END,
                   format('%5.1f',slope),
                   format('%6.2f',nominal),
                   format('%7.3f',ncontrib),
                   format('%6.2f',actual),
                   format('%7.3f',acontrib),
                   driver || '.' || input,
                   dn,
                   dg,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END
            FROM gram_sat_effects
            WHERE object='$dbid' 
            AND etype='S'
            AND active=1 
            AND n='$n' AND g='$g' AND c='$c'
            ORDER BY cause ASC, ts ASC, slope DESC
        " -labels {
            "Cause" "Start Time" "End Time" 
            "Slope" "NTotal" "NContrib"
            "ATotal" "AContrib" 
            "Input" "DN" "DG" "E"
        } -headercols 3]
    }

    # dump coop slope n f g
    #
    # n       A neighborhood name
    # f       A civ group name
    # g       A frc group name
    #
    # Returns a pretty-printed list of the active slope effects acting
    # on the specific cooperation level, one per line, sorted by
    # cause.

    method {dump coop slope} {n f g} {
        # FIRST, validate the inputs
        $nbhoods validate $n
        $cgroups validate $f
        $fgroups validate $g

        return [$rdb query "
            SELECT cause,
                   tozulu(ts),
                   CASE WHEN te=$maxEndTime THEN 'n/a' ELSE tozulu(te) END,
                   format('%5.1f',slope),
                   format('%6.2f',nominal),
                   format('%7.3f',ncontrib),
                   format('%6.2f',actual),
                   format('%7.3f',acontrib),
                   driver || '.' || input,
                   dn,
                   df,
                   dg,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END
            FROM gram_coop_effects
            WHERE object='$dbid' 
            AND etype='S'
            AND active=1 
            AND n='$n' AND f='$f' AND g='$g'
            ORDER BY cause ASC, ts ASC, slope DESC
        " -labels {
            "Cause" "Start Time" "End Time" 
            "Slope" "NTotal" "NContrib"
            "ATotal" "AContrib" 
            "Input" "DN" "DF" "DG" "E"
        } -headercols 3]
    }

    #-------------------------------------------------------------------
    # Utility Methods and Procs

    # ValidateGC g c ?parmtext?
    #
    # g         A group name
    # c         A concern name
    # parmtext  Alternate errmsg text for "g and c"
    #
    # Verifies that:
    #
    #    g is a valid CIV or ORG group
    #    c is a valid CIV or ORG concern
    #    g and c are both CIV or both ORG
    #
    # Throws an appropriate error if not.

    method ValidateGC {g c {parmtext "g and c"}} {
        $cogroups validate $g
        $concerns validate $c

        require {[$rdb exists {
            SELECT gc_id FROM gram_gc 
            WHERE object=$dbid AND g=$g AND c=$c
        }]} "$parmtext must have the same group type, CIV or ORG"
    }

    # ScaleFactor curve_type value sign
    #
    # curve_type     SAT or COOP
    # value          The current value of the curve in question
    # sign           -1 if net contribution is negative, 
    #                +1 if net contribution is positive
    #
    # Returns a positive scale factor that will scale net positive
    # contributions toward the upper limit and net negative
    # contributions toward the lower limit.  The factor is proportional
    # to the distance of value from the relevant limit.
    #
    # See memo WHD-06-009, "Preventing Satisfaction Overflow" for
    # details.

    proc ScaleFactor {curve_type value sign} {
        if {$curve_type eq "SAT"} {
            if {$sign >= 0.0} {
                return [expr {abs(2.0*$sign*(100.0 - $value)/200.0)}]
            } else {
                return [expr {abs(2.0*$sign*(100.0 + $value)/200.0)}]
            }
        } else {
            # COOP
            if {$sign >= 0.0} {
                return [expr {abs($sign*(100.0 - $value)/100.0)}]
            } else {
                return [expr {abs($sign*$value/100.0)}]
            }
        }
    }

    # ClampCurve curve_type value
    #
    # curve_type     SAT or COOP
    # value          The current value of the curve in question
    #
    # Clamps the value based on the curve type.

    proc ClampCurve {curve_type value} {
        if {$curve_type eq "SAT"} {
            return [qsat clamp $value]
        } else {
            # COOP
            return [qcooperation clamp $value]
        }
    }

    # profile command....
    #
    # command     A command to execute
    #
    # Executes the command using Tcl's "time" command, and logs the
    # run time.

    method profile {args} {
        set profile [time $args 1]
        $self Log detail "profile: $args $profile"
    }


    # Log severity message
    #
    # severity         A logger(n) severity level
    # message          The message text.

    method Log {severity message} {
        if {$options(-logger) ne ""} {
            $options(-logger) $severity $options(-logcomponent) $message
        }
    }
}






