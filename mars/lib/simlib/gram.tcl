#-----------------------------------------------------------------------
# FILE: gram.tcl
#
#   GRAM: Generalized Regional Analysis Module
#
# PACKAGE:
#   simlib(n) -- Simulation Infrastructure Package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

namespace eval ::simlib:: {
    namespace export gram
}

#-----------------------------------------------------------------------
# Section: Data Types

# Type: satgrouptypes
#
# Group types for which satisfaction is tracked
snit::enum ::simlib::satgrouptypes -values {CIV ORG}

# Type: proxlimit
#
# Proximity limit enumeration.
snit::enum ::simlib::proxlimit -values {none here near far}

#-----------------------------------------------------------------------
# Section: Object Types

#-----------------------------------------------------------------------
# Object Type: gram
#
# GRAM -- Generalized Regional Analysis Model
#
# Instances of the gram object type do the following.
#
#  * Bookkeep GRAM inputs.
#  * Recompute GRAM outputs as simulation time is advanced per
#    the <-simclock>.
#  * Allow the owner to schedule GRAM level and slope inputs.
#  * Allow introspection of all inputs and outputs.
#
# Note that the instance of gram cannot "run" on its own; it expects to be
# embedded in a larger simulation which will control the advancement
# of simulation time and schedule GRAM level and slope inputs as needed.
#
# TBD:
#  * We need a "coop drivers" command.
#  * Need to optimize <cancel>; see the TBD in that routine.

snit::type ::simlib::gram {
    #-------------------------------------------------------------------
    # Group: Type Components

    # Type component: parm
    #
    # gram(n) supports the parm(i) interface.  This component is
    # gram(n)'s configuration <parmset>.  Because it is -public,
    # it is automatically available as a type method.
    
    typecomponent parm -public parm


    #-------------------------------------------------------------------
    # Group: Type Constructor
    #
    # The type constructor is responsible for creating the <parm>
    # component and adding the GRAM configuration parameters.

    typeconstructor {
        # FIRST, Import needed commands from other packages.
        namespace import ::marsutil::*

        # NEXT, define the module's configuration parameters.
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

        $parm define gram.saveExpired ::snit::boolean no {
            If yes, GRAM saves the expired effects from the latest time
            advance in a temporary table, gram_expired_effects.
        }
    }

    #-------------------------------------------------------------------
    # Group: sqlsection(i) implementation
    #
    # The following routines implement the module's 
    # sqlsection(i) interface.

    # Type method: sqlsection title
    #
    # Returns a human-readable title for the section.

    typemethod {sqlsection title} {} {
        return "gram(n)"
    }

    # Type method: sqlsection schema
    #
    # Returns the section's persistent schema definitions, which are
    # read from <gram.sql>.

    typemethod {sqlsection schema} {} {
        return [readfile [file join $::simlib::library gram.sql]]
    }

    # Type method: sqlsection tempschema
    #
    # Returns the section's temporary schema definitions, which are
    # read from <gram_temp.sql>.

    typemethod {sqlsection tempschema} {} {
        return [readfile [file join $::simlib::library gram_temp.sql]]
    }

    # Type method: sqlsection functions
    #
    # Returns a dictionary of function names and command prefixes.
    #
    #   clamp - <ClampCurve>

    typemethod {sqlsection functions} {} {
        return [list \
                    clamp [myproc ClampCurve]]
    }

    #-------------------------------------------------------------------
    # Group: Type Variables

    # Type Variable: maxEndTime
    #
    # This value is used as a sentinel, to indicate that a slope effect
    # has no end time.  The call to [expr] ensures that the value is
    # seen as an integer by SQLite3.
    typevariable maxEndTime [expr {int(99999999)}]

    # Type Variable: proxlimit
    #
    # The array translates from <proxlimit> enumeration to numeric
    # proximity limits.  Thus, it gives the numeric value
    # for each value of the gram.*.proxlimit <parm>.

    typevariable proxlimit -array {
        none   0
        here   1
        near   2
        far    3
    }
    
    # Type Variable: rdbTracker
    #
    # Array, gram(n) instance by RDB. This array tracks which RDBs are in use by
    # gram instances; thus, if we create a new instance on an RDB that's already
    # in use by a GRAM instance, we can throw an error.
    
    typevariable rdbTracker -array { }

    #-------------------------------------------------------------------
    # Group: Options

    # Option: -rdb
    #
    # The name of the sqldocument(n) instance in which
    # gram(n) will store its working data.  After creation, the
    # value will be stored in the <rdb> component.
    option -rdb -readonly 1

    # Option: -loadcmd
    #
    # The name of a command that will populate the GRAM tables in the
    # RDB.  It must take one additional argument, $self.
    # See gram(n) for more details.

    option -loadcmd -readonly 1

    # Option: -clock
    #
    # The name of a simclock(n) instance which is controlling
    # simulation time.  After creation, the value will be stored in the
    # <clock> component.

    option -clock -readonly 1

    # Option: -logger
    #
    # The name of application's logger(n) object.

    option -logger

    # Option: -logcomponent
    #
    # This object's "log component" name, to be used in log messages.

    option -logcomponent -default gram -readonly 1

    #-------------------------------------------------------------------
    # Group: Components
    #
    # Each instance of gram(n) uses the following components.
    
    # Component: rdb
    #
    # The run-time database (RDB), an instance of sqldocument(n) in which
    # gram(n) stores its data.  The RDB is passed in at creation time via
    # the <-rdb> option.
    component rdb
    
    # Component: clock
    #
    # The simclock(n) simulation clock that drives the advance of simulation
    # time for this instance of gram(n). The clock is passed in at creation time
    # via the <-clock> option.
    component clock

    # Component: nbhoods
    #
    # A snit::enum used to validate neighborhood IDs.
    component nbhoods

    # Component: cgroups
    #
    # A snit::enum used to validate CIV group IDs.
    component cgroups

    # Component: cogroups
    #
    # A snit::enum used to validate CIV and ORG group IDs.
    component cogroups

    # Component: fgroups
    #
    # A snit::enum used to validate FRC group IDs.
    component fgroups

    # Component: concerns
    #
    # A snit::enum used to validate concern IDs.
    component concerns

    #-------------------------------------------------------------------
    # Group: Checkpointed Variables
    #
    # Most model data is stored in the <rdb>; however, there are a few
    # values that are stored in variables.
    
    
    # Variable: db
    #
    # Array of model scalars; the elements are as listed below.
    #
    #   initialized - 0 if <-loadcmd> has never been called, and 1 if 
    #                 it has.
    #
    #   loadstate   - Transient; indicates the progress of the <-loadcmd>.
    #
    #   time        - Simulation Time: integer ticks, starting at 0
    #
    #   timelast    - Time of previous advance: integer ticks, 
    #                 starting at 0. The expression (time minus timelast) gives
    #                 us the length of the most recent time step.
    #
    #-----------------------------------------------------------------------
    
    variable db -array { }

    #-------------------------------------------------------------------
    # Group: Non-checkpointed Variables

    # Variable: initdb
    #
    # Array, initial values for <db>.
    variable initdb {
        initialized      0
        loadstate        ""
        time             {}
        timelast         {}
    }

    # Variable: info
    #
    # Array, non-checkpointed scalar data.  The keys are as follows.
    #
    #   changed - 1 if the contents of <db> has changed, and 0 otherwise.
    
    variable info -array {
        changed          0
    }

    #-------------------------------------------------------------------
    # Group: Constructor

    # Constructor: constructor
    #
    # Creates a new instance of gram(n), given the creation <Options>.
    
    constructor {args} {
        # FIRST, get the creation arguments.
        $self configurelist $args

        # NEXT, verify that we have a load command
        assert {$options(-loadcmd) ne ""}

        # NEXT, save the clock component
        set clock $options(-clock)
        assert {[info commands $clock] ne ""}

        # NEXT, save the RDB component, verifying that no other instance
        # of GRAM is using it.
        set rdb $options(-rdb)
        assert {[info commands $rdb] ne ""}

        require {$type in [$rdb sections]} \
            "gram(n) is not registered with database $rdb"
        
        if {[info exists rdbTracker($rdb)]} {
            return -code error \
                "RDB $rdb already in use by GRAM $rdbTracker($rdb)"
        }
        
        set rdbTracker($rdb) $self

        # NEXT, initialize db
        array set db $initdb

        $self Log normal "Created"
    }
    
    # Constructor: destructor
    #
    # Removes the instance's <rdb> from the <rdbTracker>, and deletes
    # the instance's content from the relevant <rdb> tables.

    destructor {
        catch {
            unset -nocomplain rdbTracker($rdb)
            $self ClearTables
        }
    }

    #-------------------------------------------------------------------
    # Group: Checkpoint/Restore

    # Method: checkpoint
    #
    # Returns a copy of the object's state for later restoration.
    # This includes only the data stored in the db array; data stored
    # in the RDB is checkpointed with the RDB.  If the -saved flag
    # is included, the object is marked as unchanged.
    #
    # Syntax:
    #   checkpoint ?-saved?
    
    method checkpoint {{option ""}} {
        if {$option eq "-saved"} {
            set info(changed) 0
        }

        return [array get db]
    }


    # Method: restore
    #
    # Restores the checkpointed state; this is just the reverse of
    # <checkpoint>. If the -saved flag is included, the object is marked as
    # unchanged.
    #
    # Syntax:
    #   restore _state_ ?-saved?
    #
    #   state - Checkpointed state returned by the <checkpoint> method.

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


    # Method: changed
    #
    # Returns the changed flag, 1 if the state has changed and 0 otherwise.
    # The changed flag is set by TBD, and is cleared by <checkpoint> and
    # <restore> when called with the -saved flag.

    method changed {} {
        return $info(changed)
    }

    #-------------------------------------------------------------------
    # Group: Scenario Management

    # Method: init
    #
    # Initializes the simulation to time 0.  Reloads initial data on
    # demand.
    #
    # Syntax:
    #   init ?-reload?
    #
    #   -reload - If present, calls the <-loadcmd> to reload the 
    #             initial data into the <rdb>.

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

        # NEXT, Create the long-term trend driver
        $self CreateLongTermTrendDriver

        # NEXT, compute the initial roll-ups.
        $self ComputeSatRollups
        $self ComputeCoopRollups

        # NEXT, save initial values
        $rdb eval {
            UPDATE gram_n      SET sat0  = sat;
            UPDATE gram_g      SET sat0  = sat;
            UPDATE gram_c      SET sat0  = sat;
            UPDATE gram_ng     SET sat0  = sat;
            UPDATE gram_nc     SET sat0  = sat;
            UPDATE gram_gc     SET sat0  = sat;
            UPDATE gram_frc_ng SET coop0 = coop;
        }

        # NEXT, set the changed flag
        set info(changed) 1

        return
    }

    # Method: CreateLongTermTrendDrive
    #
    # Creates a driver against which the application can create long-term
    # trends of various kinds.

    method CreateLongTermTrendDriver {} {
        # FIRST, create the Driver
        $rdb eval {
            INSERT INTO gram_driver(driver,name,dtype,oneliner)
            VALUES(0,"Trend","Trend","Long-Term Trends")
        }
    }

    # Method: clear
    #
    # Uninitializes <gram>, returning it to its initial state on 
    # creation and deleting all of the instance's data from the <rdb>.

    method clear {} {
        # FIRST, reset the in-memory data
        array unset db
        array set db $initdb

        # NEXT, destroy validators
        $self DestroyValidators

        # NEXT, Clear the RDB
        $self ClearTables
    }
    
    # Method: DestroyValidators
    #
    # Destroys the snit::enums (e.g., <nbhoods>) for the valid nbhoods,
    # concerns, etc.

    method DestroyValidators {} {
        if {$nbhoods ne ""} {
            rename $nbhoods   "" ; set nbhoods  ""
            rename $cgroups   "" ; set cgroups  ""
            rename $cogroups  "" ; set cogroups ""
            rename $fgroups   "" ; set fgroups  ""
            rename $concerns  "" ; set concerns ""
        }
    }

    # Method: ClearTables
    #
    # Deletes all data from the <gram.sql> tables for this instance

    method ClearTables {} {
        $rdb eval {
            DELETE FROM gram_curves;
            DELETE FROM gram_effects;
            DELETE FROM gram_contribs;
            DELETE FROM gram_deltas;
            DELETE FROM gram_n;
            DELETE FROM gram_g;
            DELETE FROM gram_c;
            DELETE FROM gram_mn;
            DELETE FROM gram_nfg;
            DELETE FROM gram_ng;
            DELETE FROM gram_frc_ng;
            DELETE FROM gram_nc;
            DELETE FROM gram_gc;
            DELETE FROM gram_ngc;
            DELETE FROM gram_sat_influence;
            DELETE FROM gram_coop_influence;
        }
    }

    # Method: initialized
    #
    # Returns 1 if the <-loadcmd> has ever been successfully called, and 0
    # otherwise.

    method initialized {} {
        return $db(initialized)
    }
    
    # Method: ComputeSatInfluence
    #
    # Computes all satisfaction influence entries and places them
    # in <gram_sat_influence>.  This is done at
    # initialization time; hence, it is assumed that none of the
    # influence inputs can vary after time 0.

    method ComputeSatInfluence {} {
        # FIRST, get the conversion from days to ticks
        set daysToTicks [$clock fromDays 1.0]

        # NEXT, clear the previous influence
        $rdb eval {
            DELETE FROM gram_sat_influence 
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
                   direct_ng, influenced_ng, prox, delay, factor)
            SELECT dir_ng.ng_id                            AS direct_ng,
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

            WHERE inf_ng.sat_tracked =  1
            AND   dir_g.g            =  dir_ng.g
            AND   inf_g.g            =  inf_ng.g
            AND   dir_g.gtype        =  inf_g.gtype
            AND   gram_mn.m          =  inf_ng.n
            AND   gram_mn.n          =  dir_ng.n
            AND   prox               <  3   -- Not remote!
            AND   gram_nfg.n         =  inf_ng.n
            AND   gram_nfg.f         =  inf_ng.g
            AND   gram_nfg.g         =  dir_ng.g
            AND   factor             != 0.0
        }
    }

    # Method: ComputeCoopInfluence
    #
    # Computes all cooperation influence entries and places them
    # in <gram_coop_influence>.  This is done at
    # initialization time; hence, it is assumed that none of the
    # influence inputs can vary after time 0.

    method ComputeCoopInfluence {} {
        # FIRST, get the conversion from days to ticks
        set daysToTicks [$clock fromDays 1.0]

        # NEXT, clear the previous influence
        $rdb eval {
            DELETE FROM gram_coop_influence 
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
            JOIN gram_g   AS H
            JOIN gram_mn  AS MN
            JOIN gram_nfg AS MHG
            WHERE G.gtype            =  'FRC'
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
                gram_coop_influence(dn,dg,m,h,prox,delay,factor)
                VALUES($dn, $dg, $m, $h, $prox, $delay, $rel_mhg)
            }
        }
    }

    #-------------------------------------------------------------------
    # Group: Load API
    #
    # GRAM is usually initialized from the <rdb>, but different
    # applications have different database schemas; thus, GRAM cannot
    # assume that the data will be in the form that it wants.
    # Consequently, this API is used by the load command to load new
    # data into GRAM. The commands must be used in a strict order, as
    # indicated by db(loadstate).  The order of states is:
    #
    #  * nbhoods
    #  * groups
    #  * concerns
    #  * nbrel
    #  * nbgroups
    #  * sat
    #  * rel
    #  * coop
    #
    # The state indicates that the relevant "load *" method has
    # successfully been called, e.g., db(loadstate) is *nbhoods*
    # after <load nbhoods> has been called.

    # Method: LoadData
    #
    # This is called by <init> when it's necessary to reload input
    # data from the client.  It clears the current data, initializes
    # the db(loadstate) state machine, calls the <-loadcmd>, verifies
    # that the state machine has terminated, and does a <SanityCheck>
    # and calls <CreateValidators>.

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
    
    # Method: SanityCheck
    #
    # Verifies that <LoadData> has loaded everything we need to run.
    #
    # TBD:
    #
    #  * This method is currently a no-op.

    method SanityCheck {} {
        # TBD: Not yet implemented.
    }

    # Method: CreateValidators
    #
    # Creates snit::enums (e.g., <nbhoods>) for the valid nbhood, concern,
    # and group names.

    method CreateValidators {} {
        # FIRST, if they already exist get rid of them.
        $self DestroyValidators

        # Nbhoods
        set values [$rdb eval {
            SELECT n FROM gram_n 
            ORDER BY n_id
        }]

        set nbhoods [snit::enum ${selfns}::nbhoods -values $values]

        # CIV Groups
        set values [$rdb eval {
            SELECT g FROM gram_g 
            WHERE  gtype = 'CIV'
            ORDER BY g_id
        }]

        set cgroups [snit::enum ${selfns}::cgroups -values $values]

        # CIV/ORG Groups
        set values [$rdb eval {
            SELECT g FROM gram_g 
            WHERE  gtype IN ('CIV','ORG')
            ORDER BY g_id
        }]

        set cogroups [snit::enum ${selfns}::cogroups -values $values]

        # FRC Groups
        set values [$rdb eval {
            SELECT g FROM gram_g 
            WHERE  gtype = 'FRC'
            ORDER BY g_id
        }]

        set fgroups [snit::enum ${selfns}::fgroups -values $values]

        # Concerns
        set values [$rdb eval {
            SELECT c FROM gram_c
            ORDER BY c_id
        }]

        set concerns [snit::enum ${selfns}::concerns -values $values]
    }

    # Method: load nbhoods
    #
    # Loads the neighborhood names into <gram_n>. Typically, the names
    # should be pre-sorted.
    #
    # Syntax:
    #   load nbhoods _name ?name...?_
    #
    #   name - A neighborhood name.

    method "load nbhoods" {args} {
        assert {$db(loadstate) eq "begin"}

        foreach n $args {
            $rdb eval {
                INSERT INTO gram_n(n)
                VALUES($n);
            }
        }

        set db(loadstate) "nbhoods"
    }

    # Method: load groups
    #
    # Loads the group names into <gram_g>. Typically, the groups are
    # ordered first by group type, and then by name.
    #
    # Syntax:
    #   load groups _name gtype ?name gtype...?_
    #
    #   name  - Group name
    #   gtype - Group type (CIV, FRC, ORG)

    method "load groups" {args} {
        assert {$db(loadstate) eq "nbhoods"}

        foreach {g gtype} $args {
            $rdb eval {
                INSERT INTO gram_g(g,gtype)
                VALUES($g,$gtype);
            }
        }

        set db(loadstate) "groups"
    }

    # Method: load concerns
    #
    # Loads the concern names into <gram_c>. Typically, the concerns are
    # ordered first by group type, and then by name.
    #
    # Syntax:
    #   load concerns _name gtype ?name gtype...?_
    #
    #   name  - Concern name
    #   gtype - Concern type (CIV, ORG)

    method "load concerns" {args} {
        assert {$db(loadstate) eq "groups"}

        foreach {c gtype} $args {
            $rdb eval {
                INSERT INTO gram_c(c,gtype)
                VALUES($c,$gtype);
            }
        }

        $self PopulateDefaultsAfterConcerns

        set db(loadstate) "concerns"
    }

    # Method: PopulateDefaultsAfterConcerns
    #
    # Once all of the relevant neighborhoods, groups, and concerns
    # are known, this routine populates <gram_nc>, <gram_gc>,
    # <gram_mn>, <gram_ng>, and <gram_frc_ng> with default
    # values.  The <-loadcmd> can subsequently fill in details as
    # desired.

    method PopulateDefaultsAfterConcerns {} {
        # FIRST, populate gram_nc.
        $rdb eval {
            INSERT INTO gram_nc(
                n,
                c)
            SELECT n, c
            FROM gram_n JOIN gram_c
            ORDER BY n, gtype, c;
        }

        # NEXT, populate gram_gc.
        $rdb eval {
            INSERT INTO gram_gc(
                g,
                c)
            SELECT g, c
            FROM gram_g JOIN gram_c USING (gtype)
            ORDER BY gtype, g, c
        }

        # NEXT, populate gram_mn: A nbhood is "here" to itself and
        # "far" to all others, and effects_delays are all 0.0

        $rdb eval {
            INSERT INTO gram_mn(
                m,
                n,
                proximity,
                effects_delay)
            SELECT M.n,
                   N.n,
                   CASE WHEN M.n=N.n THEN 0 ELSE 2 END,
                   0.0
            FROM gram_n AS M join gram_n AS N
            ORDER BY M.n, N.n
        }

        # NEXT, populate gram_ng.  Weights and factors are 1.0,
        # sat_tracked is 1 only for ORG groups, and all populations
        # are 0.

        $rdb eval {
            SELECT n, g, gtype
            FROM gram_n JOIN gram_g
            WHERE gtype IN ('CIV', 'ORG')
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
                gram_ng(n, g, 
                        population, rollup_weight, effects_factor,
                        sat_tracked)
                VALUES($n, $g, 0, 1.0, 1.0, $sat_tracked)
            }
        }

        # NEXT, populate gram_frc_ng.
        $rdb eval {
            INSERT INTO gram_frc_ng(
                n,
                g)
            SELECT n, g
            FROM gram_n JOIN gram_g
            WHERE gtype = 'FRC'
            ORDER BY n, g
        }
    }

    # Method: load nbrel
    #
    # Loads non-default neighborhood relationships into <gram_mn>.
    #
    # Syntax:
    #   load nbrel _m n proximity effects_delay ?...?_
    #
    #   m             - Neighborhood name
    #   n             - Neighborhood name
    #   proximity     - eproximity(n); must be 0 if m=n.
    #   effects_delay - Effects delay in decimal days.

    method "load nbrel" {args} {
        assert {$db(loadstate) eq "concerns"}

        foreach {m n proximity effects_delay} $args {
            set proximity [eproximity index $proximity]

            assert {
                ($m eq $n && $proximity == 0) ||
                ($m ne $n && $proximity != 0)
            }

            set mn_id [$rdb onecolumn {
                SELECT mn_id FROM gram_mn
                WHERE m=$m AND n=$n;
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

    # Method: load nbgroups
    #
    # Loads specifics of the neighborhood CIV and ORG groups into
    # <gram_ng>.
    #
    # Syntax:
    #   load nbgroups _n g population rollup_weight effects_factor ?...?_
    #
    #   n              - Neighborhood name
    #   g              - Group name
    #   population     - Population; 0 for ORG groups
    #   rollup_weight  - Rollup Weight
    #   effects_factor - Effects Factor

    method "load nbgroups" {args} {
        assert {$db(loadstate) eq "nbrel"}

        foreach {n g population rollup_weight effects_factor} $args {
            set ng_id [$rdb onecolumn {
                SELECT ng_id FROM gram_ng 
                WHERE n=$n AND g=$g
            }]
            
            set gtype [$rdb onecolumn {
                SELECT gtype FROM gram_g WHERE g=$g
            }]

            require {$ng_id ne ""} "Invalid nbgroup: $n $g"

            if {$gtype eq "ORG"} {
                require {$population == 0} \
                    "ORG with non-zero population: $n $g $population"
            }
            
            $rdb eval {
                UPDATE gram_ng
                SET population     = $population,
                    rollup_weight  = $rollup_weight,
                    effects_factor = $effects_factor,
                    sat_tracked    = CASE 
                        WHEN $gtype = 'ORG' OR $population > 0
                        THEN 1
                        ELSE 0 
                    END
                WHERE ng_id=$ng_id
            }
        }

        $self PopulateDefaultsAfterNbgroups

        set db(loadstate) "nbgroups"
    }

    # Method: PopulateDefaultsAfterNbgroups
    #
    # Once all of the relevant neighborhood groups are
    # known, this routine populates <gram_curves>, <gram_ngc>, and
    # <gram_nfg> with default values. The <-loadcmd> can subsequently fill
    # in details as desired.

    method PopulateDefaultsAfterNbgroups {} {
        # FIRST, populate gram_ngc. Saliency is 1.0 if sat_tracked,
        # and 0.0 otherwise; there's a curve
        # only if sat_tracked.
        $rdb eval {
            SELECT ng_id, 
                   n, 
                   g, 
                   sat_tracked,
                   c, 
                   gram_g.gtype AS gtype 
            FROM gram_ng 
            JOIN gram_g USING (g)
            JOIN gram_c
            WHERE gram_g.gtype   = gram_c.gtype
            ORDER BY n, gram_g.gtype, g, c
        } {
            if {$sat_tracked} {
                $rdb eval {
                    -- Note: curve_id is set automatically
                    INSERT INTO gram_curves(curve_type, val0, val)
                    VALUES('SAT', 0.0, 0.0);

                    -- Note: ngc_id is set automatically
                    INSERT INTO 
                    gram_ngc(ng_id, curve_id, n, g, c,
                             gtype, saliency)
                    VALUES($ng_id, last_insert_rowid(),  $n, $g, $c, 
                           $gtype, 1.0);
                }

            } else {
                $rdb eval {
                    -- Note: ngc_id is set automatically
                    INSERT INTO 
                    gram_ngc(ng_id, n, g, c, gtype, saliency)
                    VALUES($ng_id, $n, $g, $c, $gtype, 0.0);
                }
            }
        }

        # NEXT, populate gram_nfg.  Default relationships are 0.0,
        # unless f=g. Default cooperations are 50.0 where f is a FRC
        # group and g is a CIV group and ng.sat_tracked is 1, and 0.0
        # otherwise.
        $rdb eval {
            INSERT INTO gram_nfg(
                n,
                f,
                g,
                rel)
            SELECT gram_n.n AS n,
                   F.g      AS f,
                   G.g      AS g,
                   CASE WHEN F.g=G.g THEN 1.0 ELSE 0.0 END
            FROM  gram_n 
            JOIN  gram_g AS F
            JOIN  gram_g AS G
            ORDER BY n, F.g, G.g
        }

        $rdb eval {
            SELECT gram_ng.n AS n,
                   gram_ng.g AS f,
                   G.g       AS g
            FROM gram_ng 
            JOIN gram_g AS F
            JOIN gram_g AS G
            WHERE gram_ng.sat_tracked=1
            AND   F.gtype = 'CIV'
            AND   G.gtype = 'FRC'
            AND   gram_ng.g = F.g
            ORDER BY n, f, g
        } {
            $rdb eval {
                -- Note: curve_id is set automatically.
                INSERT INTO gram_curves(curve_type, val0, val)
                VALUES('COOP', 50.0, 50.0);

                UPDATE gram_nfg
                SET curve_id = last_insert_rowid()
                WHERE n=$n AND f=$f AND g=$g;
            }
        }
    }

    # Method: load sat
    #
    # Loads the non-default satisfaction curve data into <gram_curves> and
    # <gram_ngc>.
    #
    # Syntax:
    #   load sat _n g c sat0 saliency ?...?_
    #
    #   n        - Neighborhood name
    #   g        - Group name
    #   c        - Concern name
    #   sat0     - Initial satisfaction level
    #   saliency - Saliency

    method {load sat} {args} {
        assert {$db(loadstate) eq "nbgroups"}

        foreach {n g c sat0 saliency} $args {
            set curve_id [$rdb onecolumn {
                SELECT curve_id 
                FROM gram_ngc
                WHERE n=$n AND g=$g AND c=$c;
            }]

            require {$curve_id ne ""} "No such sat curve: $n $g $c"

            $rdb eval {
                UPDATE gram_curves
                SET val0 = $sat0,
                    val  = $sat0
                WHERE curve_id = $curve_id;
                
                UPDATE gram_ngc
                SET saliency = $saliency
                WHERE curve_id = $curve_id;
            }
        }

        $self PopulateTablesAfterSat

        set db(loadstate) "sat"
    }

    # Method: PopulateTablesAfterSat
    #
    # Computes the total saliency for each n,g,c and saves it in
    # <gram_ng>

    method PopulateTablesAfterSat {} {
        # FIRST, get the total_saliency for each neighborhood group
        $rdb eval {
            SELECT n,
                   g,
                   total(saliency) AS saliency
            FROM gram_ngc
            GROUP BY n,g
        } {
            $rdb eval {
                UPDATE gram_ng
                SET total_saliency=$saliency
                WHERE n=$n AND g=$g
            }
        }
    }

    # Method: load rel
    #
    # Loads non-default group relationships into <gram_nfg>. All groups
    # have relationships in all neighborhoods; however, it's expected that
    # relationships between non-CIV groups will be constant across
    # neighborhoods.
    #
    # Syntax:
    #   load rel _n f g rel ?...?_
    #
    #   n   - Neighborhood name
    #   f   - Group name
    #   g   - Group name
    #   rel - Group relationship

    method "load rel" {args} {
        assert {$db(loadstate) eq "sat"}

        foreach {n f g rel} $args {
            set nfg_id [$rdb onecolumn {
                SELECT nfg_id FROM gram_nfg 
                WHERE n=$n AND f=$f AND g=$g
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

    # Method: load coop
    #
    # Loads non-default cooperation levels into <gram_curves>.
    #
    # Syntax:
    #   load coop _n f g coop0 ?...?_
    #
    #   n     - Neighborhood name
    #   f     - Force group name
    #   g     - Civ group name
    #   coop0 - Initial cooperation level

    method {load coop} {args} {
        assert {$db(loadstate) eq "rel"}

        foreach {n f g coop0} $args {
            set curve_id [$rdb onecolumn {
                SELECT curve_id 
                FROM gram_nfg
                WHERE n=$n AND f=$f AND g=$g;
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


    #-------------------------------------------------------------------
    # Group: Update API
    #
    # This API is used to update scenario data after the initial load.
    # Not everything can be modified.  (In fact, very little can
    # be modified.)

    # Method: update population
    #
    # Updates <gram_ng.population> for the specified groups.  Note that
    # it's an error to assign a non-zero population to a group with
    # zero population, or a zero population to a group with non-zero
    # population.
    #
    # The change takes affect on the next time <advance>.
    #
    # NOTE: This routine updates <gram_ng>; do not call it in the body
    # of a query on <gram_ng>.
    #
    # Syntax:
    #   update population _n g population ?...?_
    #
    #   n          - A neighborhood
    #   g          - A group in the neighborhood
    #   population - The group ng's new population

    method "update population" {args} {
        foreach {n g population} $args {
            # TBD: Could verify that g is CIV, and that
            # existing population matches.
            $rdb eval {
                UPDATE gram_ng
                SET population = $population
                WHERE n=$n AND g=$g
            }
        }
    }

    #-------------------------------------------------------------------
    # Group: Drivers
    #
    # Every input to GRAM is associated with a satisfaction or
    # cooperation driver, i.e., an event or situation.
    # Prior to entering the input, the application must allocate
    # a numeric Driver ID by calling <driver add>.  Driver data
    # is stored in the <gram_driver> table.

    # Method: driver add
    #
    # Creates a new driver and returns its driver ID.  Saves the options
    # if given. 
    #
    # Syntax:
    #   driver add _?option value...?_
    #
    # Options:
    #   -name     text  - Short name for the driver.  Defaults
    #                     to the driver ID.
    #   -dtype    text  - Driver type.  Defaults to "unknown".
    #   -oneliner text  - One-line description of the driver.
    #                     Defaults to "unknown".
    #
    # NOTE: This code has the important property that if the most recently
    # added driver is deleted (<cancel> -delete), the driver ID will be 
    # reused the next time.  This allows allocation of driver IDs to
    # be undone.  Don't break it!

    method "driver add" {args} {
        # FIRST, process the options
        set opts [$self ParseDriverOptions $args]

        # NEXT, Get the next Driver ID number
        # If there are any, this will get the next one.
        $rdb eval {
            SELECT COALESCE(max(driver) + 1, 1) AS nextDriver
            FROM gram_driver
        } {}

        # NEXT, Create the new record
        $rdb eval {
            INSERT INTO gram_driver(driver)
            VALUES($nextDriver)
        }

        if {![dict exists $opts name]} {
            dict set opts name $nextDriver
        }

        # NEXT, save the option values
        $self SetDriverOptions $nextDriver $opts

        return $nextDriver
    }

    # Method: driver configure
    #
    # Sets new driver option values.
    #
    # Syntax:
    #   driver configure _driver option value ?option value...?_
    #
    #   driver - An existing Driver ID.
    #
    # The options are as for <driver add>.

    method "driver configure" {driver args} {
        # FIRST, validate the driver ID
        $self driver validate $driver "Cannot configure"

        # NEXT, save the option values
        $self SetDriverOptions $driver [$self ParseDriverOptions $args]

        return
    }

    # Method: driver cget
    #
    # Returns the current value of the option, which can also simply
    # be read from the RDB.
    #
    # Syntax:
    #   driver cget _driver option_
    #
    #   driver - An existing Driver ID
    #   option - An option
    #
    # The options are as for <driver add>.

    method "driver cget" {driver option} {
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
            WHERE driver=\$driver
        " {
            return $value
        }

        error "Cannot cget, unknown Driver ID: \"$driver\""
    }

    # Method: driver exists
    #
    # Returns 1 if the driver exists, and 0 otherwise.
    #
    # Syntax:
    #   driver exists _driver_
    #
    #   driver - A Driver ID

    method "driver exists" {driver} {
        # FIRST, validate the driver
        if {[$rdb exists {
            SELECT driver FROM gram_driver
            WHERE driver=$driver
        }]} {
            return 1
        } else {
            return 0
        }
    }

    # Method: driver validate
    #
    # Throws an error if the Driver ID is not valid.  If the
    # _prefix_ is given, it begins the error message.
    #
    # Syntax:
    #   driver validate _driver ?prefix?_
    #
    # driver - A Driver ID
    # prefix - Optional error message prefix

    method "driver validate" {driver {prefix ""}} {
        if {![$self driver exists $driver]} {
            if {$prefix ne ""} {
                append prefix ", "
            }
            error "${prefix}unknown Driver ID: \"$driver\""
        }
    }


    # Method: ParseDriverOptions
    #
    # Parses and validates the options, and returns a dict of
    # equivalent <gram_driver> column names and option values.
    #
    # Syntax:
    #   ParseDriverOptions _optlist_
    #
    #   optlist - List of zero or more <driver add> options and their
    #             values.

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

    # Method: SetDriverOptions
    #
    # Sets all option values, given a dictionary as produced by
    # <ParseDriverOptions>.
    #
    # Syntax:
    #   SetDriverOptions _driver opts_
    #
    #   driver - Existing driver ID
    #   opts   - Dictionary of valid <gram_driver> column names
    #            and values
    
    method SetDriverOptions {driver opts} {
        dict for {opt val} $opts {
            $rdb eval "
                UPDATE gram_driver
                SET $opt = \$val
                WHERE driver = \$driver
            "
        } 
    }

    # Method: DriverGetInput
    #
    # Returns the next input counter for a given driver.
    #
    # Syntax:
    #   DriverGetInput _driver_
    #
    #   driver - An existing driver ID
    
    method DriverGetInput {driver} {
        $rdb onecolumn {
            UPDATE gram_driver
            SET last_input = last_input + 1
            WHERE driver=$driver;

            SELECT last_input FROM gram_driver
            WHERE driver=$driver;
        }
    }

    # Method: DriverDecrementInput
    #
    # Decrements the input counter for a given driver.
    #
    # Syntax:
    #   DriverDecrementInput _driver_
    #
    #   driver - An existing driver ID
    #
    # NOTE: This is provided for "<sat set> -undo" and 
    # "<coop set> -undo", pending a real undo mechanism.
    
    method DriverDecrementInput {driver} {
        $rdb eval {
            UPDATE gram_driver
            SET last_input = last_input - 1
            WHERE driver=$driver;
        }

        return
    }

    #-------------------------------------------------------------------
    # Group: Time Advance

    # Method: advance
    #
    # Advances the time to match the <-clock>.  Computes current
    # satisfaction and cooperation levels, saves contributions of
    # drivers to the levels, and computes roll-ups.

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
    # Group: Satisfaction Roll-ups
    #
    # All satisfaction roll-ups -- sat.ng, sat.nc, sat.gc, sat.g, sat.c
    # -- all have the same nature.  The computation is a weighted average
    # over a set of satisfaction levels; all that changes is the definition
    # of the set.  The equation for a roll-up over set A is as follows:
    #
    # >        Sum            w   * L    * S
    # >           n,g,c in A   ng    ngc    ngc
    # >  S  =  --------------------------------
    # >   A    Sum            w   * L   
    # >           n,g,c in A   ng    ngc

    # Method: ComputeSatRollups
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

    # Method: ComputeSatGC
    #
    # Computes sat.gc, slope.gc by rolling up sat.ngc, slope.ngc.  Note 
    # that inactive groups are skipped.

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
                FROM gram_sat JOIN gram_ng USING (ng_id))
            GROUP BY g, c
        } {
            $rdb eval {
                UPDATE gram_gc
                SET sat   = $sat,
                    slope = $slope
                WHERE g=$g and c=$c
            }
        }
    }
    
    # Method: ComputeSatNG
    #
    # Computes the composite satisfaction for each group at time t
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
            WHERE sat_tracked = 0
        }

        # NEXT, compute the current values
        $rdb eval {
            SELECT ng_id, n, g,
                   total(num)/total(denom) AS sat
            FROM (
                SELECT ng_id, n, g, 
                       sat*saliency AS num,
                       saliency     AS denom
                FROM gram_sat)
            GROUP BY ng_id
        } {
            $rdb eval {
                UPDATE gram_ng
                SET sat = $sat
                WHERE ng_id = $ng_id
            }
        }
    }
    
    # Method: ComputeSatNC
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
                FROM gram_sat JOIN gram_ng USING (ng_id))
            GROUP BY n, c
        } {
            $rdb eval {
                UPDATE gram_nc
                SET sat = $sat
                WHERE n=$n and c=$c
            }
        }
    }

    # Method: ComputeSatN
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
                WHERE gram_sat.gtype = 'CIV')
            GROUP BY n
        } {
            $rdb eval {
                UPDATE gram_n
                SET sat = $sat
                WHERE n=$n
            }
        }
    }
    
    # Method: ComputeSatG
    #
    # Computes the playbox mood for each group at time t.
    
    method ComputeSatG {} {
        $rdb eval {
            SELECT g,
                   total(num)/total(denom) AS sat
            FROM (
                SELECT gram_sat.g                          AS g,
                       gram_sat.sat*saliency*rollup_weight AS num,
                       saliency*rollup_weight              AS denom
                FROM gram_sat JOIN gram_ng USING (ng_id))
            GROUP BY g
        } {
            $rdb eval {
                UPDATE gram_g
                SET sat = $sat
                WHERE g=$g
            }
        }
    }
    
    # Method: ComputeSatC
    #
    # Computes the playbox composite satisfaction by concern at time t.
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
                FROM gram_sat JOIN gram_ng USING (ng_id))
            GROUP BY c
        } {
            $rdb eval {
                UPDATE gram_c
                SET sat = $sat
                WHERE c=$c
            }
        }
    }

    #-------------------------------------------------------------------
    # Group: Cooperation Roll-ups
    #
    # We only compute one cooperation roll-up, coop.ng: the cooperation
    # of a neighborhood as a whole with a force group.  This is based
    # on the population of the neighborhood groups, rather than
    # effects_factor and saliency; cooperation is the likelihood that
    # random member of the population will share information if asked.
    #
    # The equation is as follows:
    #
    # >           Sum  population   * coop
    # >              f           nf       nfg
    # >  coop   = ---------------------------
    # >      ng        Sum  population  
    # >                   f           nf


    # Method: ComputeCoopRollups
    #
    # Computes coop.ng.  

    method ComputeCoopRollups {} {
        # FIRST, compute coop.ng
        $rdb eval {
            SELECT gram_coop.n                                AS n, 
                   gram_coop.f                                AS f, 
                   gram_coop.g                                AS g,
                   total(gram_coop.coop * gram_ng.population) AS num,
                   total(gram_ng.population)                  AS denom
            FROM gram_coop
            JOIN gram_ng ON  gram_coop.n     = gram_ng.n
                         AND gram_coop.f     = gram_ng.g
            GROUP BY gram_coop.n, gram_coop.g
        } {
            $rdb eval {
                UPDATE gram_frc_ng
                SET coop = $num/$denom
                WHERE n=$n AND g=$g
            }
        }
    }
    
    #-------------------------------------------------------------------
    # Group: Satisfaction Adjustments and Inputs
    #
    # An adjustment is an administrative change to a particular
    # satisfaction level.  An input is a level or slope change to a
    # particular satisfaction level that has indirect effects across
    # the playbox as determined by GRAM.
    #
    # Both adjustments and inputs are made relative to some _driver_, as
    # created using <driver add>. Each has an input ID, a driver-specific
    # serial number. Thus, any adjustment or input can be identified as
    # "_driver.input_".
    
    # Method: sat adjust
    #
    # Adjusts sat.ngc by the required amount, clamping it within bounds.
    #
    # * The group and concern must have the same group type, CIV or ORG.
    # * The group and concern cannot both be wildcarded.
    #
    # Returns the input ID for this _driver_.  
    #
    # Syntax:
    #   sat adjust _driver n g c mag_
    #
    #   driver - The driver ID
    #   n      - Neighborhood name, or "*" for all.
    #   g      - Group name, or "*" for all.
    #   c      - Concern name, or "*" for all.
    #   mag    - Magnitude (a qmag value)

    method "sat adjust" {driver n g c mag} {
        $self Log detail "sat adjust driver=$driver n=$n g=$g c=$c M=$mag"

        # FIRST, check the inputs, and accumulate query terms
        set where [list]

        # driver
        $self driver validate $driver "Cannot sat adjust"

        # n
        if {$n ne "*"} {
            $nbhoods validate $n
            lappend where "n = \$n "
        }

        # g
        if {$g ne "*"} {
            $cogroups validate $g
            lappend where "g = \$g "
        }

        # c
        if {$c ne "*"} {
            $concerns validate $c
            lappend where "c = \$c "
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
                WHERE g=$g AND c=$c
            }]} "The concern: $c is not valid for the specified group"
        }

        # n and g
        #
        # If they chose a specific neighborhood and group,
        # verify that satisfaction is tracked for the pair.
        if {$n ne "*" && $g ne "*"} {
            require {[$rdb onecolumn {
                SELECT sat_tracked FROM gram_ng
                WHERE n=$n AND g=$g
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
        set where [join $where " AND "]
        foreach curve_id [$rdb eval "
            SELECT curve_id
            FROM gram_sat
            WHERE 
            $where
        "] {
            $self AdjustCurve $driver $curve_id $mag
        }

        # NEXT, recompute other outputs that depend on sat.ngc
        $self ComputeSatRollups

        return [$self DriverGetInput $driver]
    }

    # Method: sat set
    #
    # Sets sat.ngc to the required value.
    #
    # * The group and concern must have the same group type, CIV or ORG.
    # * The group and concern cannot both be wildcarded.
    #
    # Returns the input ID for this driver.  
    #
    #
    # Syntax:
    #   sat set _driver n g c sat_ ?-undo?
    #
    #   driver - The driver ID
    #   n      - Neighborhood name, or "*" for all.
    #   g      - Group name, or "*" for all.
    #   c      - Concern name, or "*" for all.
    #   sat    - Quantity (a qsat value)
    #
    # Options:
    #   -undo  - Flag; decrements last_input instead of incrementing.
    #
    # NOTE: If -undo is given, decrements the last_input counter for this
    # driver, and returns nothing.  This is a stopgap measure to allow
    # <sat adjust> and <sat set> to be undone.

    method "sat set" {driver n g c sat {flag ""}} {
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
                WHERE g=$g AND c=$c
            }]} "The concern: $c is not valid for the specified group"
        }

        # n and g
        #
        # If they chose a specific neighborhood and group,
        # verify that satisfaction is tracked for the pair.
        if {$n ne "*" && $g ne "*"} {
            require {[$rdb onecolumn {
                SELECT sat_tracked FROM gram_ng
                WHERE n=$n AND g=$g
            }]} "satisfaction is not tracked for group $g in nbhood $n"
        }


        # qsat
        qsat validate $sat
        set sat [qsat value $sat]

        # NEXT, do the query.
        foreach {curve_id mag} [$rdb eval "
            SELECT curve_id, \$sat - sat AS mag
            FROM gram_sat
            WHERE mag != 0.0
            $where
        "] {
            $self AdjustCurve $driver $curve_id $mag
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

    # Method: sat level
    #
    # Schedules a new satisfaction level input with the specified
    # parameters.  This will result in a direct effect on the specified
    # curve, and indirect effects across the playbox, as determined by
    # the influence and the values of -s, -p, and -q.
    #
    # * The group and concern must have the same type, CIV or ORG.
    #
    # Returns the driver input number for this input.  This is
    # a number that starts at 1 and is incremented for each level or slope
    # input received for the driver.
    #
    # Syntax:
    #   sat level _driver ts n g c limit days ?options?_
    #
    #   driver - driver ID
    #   ts     - Start time, integer ticks
    #   n      - Neighborhood name
    #   g      - Group name
    #   c      - Concern name
    #   limit  - Magnitude of the effect (qmag)
    #   days   - Realization time of the effect, in days (qduration)
    #
    # Options: 
    #   -cause cause        - Name of the cause of this input
    #   -s factor           - "here" indirect effects multiplier, defaults
    #                         to 1.0
    #   -p factor           - "near" indirect effects multiplier, defaults
    #                         to 0
    #   -q factor           - "far" indirect effects multiplier, defaults
    #                         to 0
    #   -athresh threshold  - Ascending threshold, defaults to 100.0.
    #   -dthresh threshold  - Descending threshold, defaults to -100.0

    method "sat level" {driver ts n g c limit days args} {
        $self Log detail "sat level driver=$driver ts=$ts n=$n g=$g c=$c lim=$limit days=$days $args"

        # FIRST, check the regular inputs
        $self driver validate $driver "Cannot sat level"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        $nbhoods validate $n

        $self ValidateGC $g $c

        qmag      validate $limit
        qduration validate $days

        # NEXT, validate the options
        $self ParseInputOptions sat opts $args

        # NEXT, normalize the input data.

        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(dn)       $n
        set input(dg)       $g
        set input(c)        $c
        set input(ts)       $ts
        set input(days)     [qduration value $days]
        set input(llimit)   [qmag      value $limit]
        set input(s)        $opts(-s)
        set input(p)        $opts(-p)
        set input(q)        $opts(-q)
        set input(athresh)  $opts(-athresh)
        set input(dthresh)  $opts(-dthresh)

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

        # NEXT, schedule the effects in every influenced neighborhood
        set epsilon [$parm get gram.epsilon]

        set plimit [$self GetProxLimit $input(s) $input(p) $input(q)]

        # NEXT, schedule the effects in every influenced neighborhood
        # within the proximity limit.
        $rdb eval {
            SELECT * FROM gram_sat_influence_view
            WHERE dn     = $input(dn)
            AND   dg     = $input(dg)
            AND   c      = $input(c)
            AND   prox   < $plimit
        } effect {
            $self ScheduleLevel input effect $epsilon
        }

        return $input(input)
    }


    # Method: sat slope
    #
    # Schedules a new GRAM slope input with the specified parameters.
    #
    # * The g and c must have the same group type
    # * A subsequent input for the same driver, n, g, c, and cause will update
    #   all direct and indirect effects accordingly.
    # * Such subsequent inputs must have a start time, ts,
    #   no earlier than the ts of the previous input.
    #
    # Returns the driver input number for this input.  This is
    # a number that starts at 1 and is incremented for each level or slope
    # input received for the driver.
    #
    # Syntax:
    #   sat slope _driver ts n g c slope ?options...?_
    #
    #   driver - Driver ID
    #   ts     - Input start time, integer ticks
    #   n      - Neighborhood name
    #   g      - Group name
    #   c      - Concern name
    #   slope  - Slope (change/day) of the effect (qmag)
    #
    # Options: 
    #   -cause cause        - Name of the cause of this input
    #   -s factor           - "here" indirect effects multiplier, defaults
    #                         to 1.0
    #   -p factor           - "near" indirect effects multiplier, defaults
    #                         to 0
    #   -q factor           - "far" indirect effects multiplier, defaults
    #                         to 0
    #   -athresh threshold  - Ascending threshold, defaults to 100.0.
    #   -dthresh threshold  - Descending threshold, defaults to -100.0

    method "sat slope" {driver ts n g c slope args} {
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

        $nbhoods validate $n

        $self ValidateGC $g $c

        qmag validate $slope

        # NEXT, validate the options
        $self ParseInputOptions sat opts $args

        # NEXT, normalize the input data
        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(dn)       $n
        set input(dg)       $g
        set input(c)        $c
        set input(slope)    [qmag value $slope]
        set input(ts)       $ts
        set input(s)        $opts(-s)
        set input(p)        $opts(-p)
        set input(q)        $opts(-q)
        set input(athresh)  $opts(-athresh)
        set input(dthresh)  $opts(-dthresh)

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

        # NEXT, if the slope is 0, ignore it; otherwise,
        # if there are effects on-going terminate all related
        # chains.  Either way, we're done.

        if {$input(slope) == 0.0} {
            $rdb eval {
                SELECT id, ts, te, cause, delay, future 
                FROM gram_ngc     AS direct
                JOIN gram_effects AS effect 
                     ON effect.direct_id = direct.ngc_id
                WHERE direct.n      = $input(dn) 
                AND   direct.g      = $input(dg) 
                AND   direct.c      = $input(c)
                AND   effect.etype  = 'S'
                AND   effect.driver = $input(driver)
                AND   effect.cause  = $input(cause)
            } row {
                $self TerminateSlope input row
            }

            return $input(input)
        }

        # NEXT, get the de facto proximity limit.
        set plimit [$self GetProxLimit $input(s) $input(p) $input(q)]

        # NEXT, terminate existing slope chains which are outside
        # the de facto proximity limit.
        $rdb eval {
            SELECT id, ts, te, cause, delay, future 
            FROM gram_ngc     AS direct
            JOIN gram_effects AS effect 
                 ON effect.direct_id = direct.ngc_id
            WHERE direct.n      =  $input(dn) 
            AND   direct.g      =  $input(dg) 
            AND   direct.c      =  $input(c)
            AND   effect.etype  =  'S'
            AND   effect.driver =  $input(driver)
            AND   effect.cause  = $input(cause)
            AND   effect.prox   >= $plimit
        } row {
            $self TerminateSlope input row
        }

        # NEXT, schedule the effects in every influenced neighborhood
        # within the proximity limit.
        $rdb eval {
            SELECT * FROM gram_sat_influence_view
            WHERE dn        = $input(dn)
            AND   dg        = $input(dg)
            AND   c         = $input(c)
            AND   prox      < $plimit
        } chain {
            $self ScheduleSlope input chain $epsilon
        }

        return $input(input)
    }

    # Method: ParseInputOptions
    #
    # Option parser for <sat level> and company.
    # Sets defaults, processes the _optsList_, validating each
    # entry, and puts the parsed values in the _optsVar_.  If
    # any values are invalid, an error is thrown.
    #
    # Syntax:
    #   ParseInputOptions _ctype optsArray optsList_
    #
    #   ctype     - sat or coop
    #   optsArray - An array to receive the options
    #   optsList  - List of options and their values

    method ParseInputOptions {ctype optsArray optsList} {
        upvar $optsArray opts

        # FIRST, set up the defaults.
        array set opts { 
            -cause   ""
            -s          1.0
            -p          0.0
            -q          0.0
            -athresh  100.0
            -dthresh -100.0
        }
        
        if {$ctype eq "coop"} {
            set opts(-dthresh) 0.0
        }

        # NEXT, get the values.
        foreach {opt val} $optsList {
            switch -exact -- $opt {
                -cause {
                    set opts($opt) $val
                }
                -s -
                -p -
                -q {
                    rfraction validate $val
                        
                    set opts($opt) $val
                }
                
                -athresh -
                -dthresh {
                    if {$ctype eq "sat"} {
                        set opts($opt) [qsat validate $val]
                    } else {
                        set opts($opt) [qcooperation validate $val]
                    }
                }

                default {
                    error "invalid option: \"$opt\""
                }
            }
        }
    }

    # Method: sat drivers
    #
    # This call queries the <gram_sat_contribs> view, accumulating 
    # contributions by specific drivers over time for a selected set of
    # neighborhoods, groups, and concerns.
    #
    # Syntax:
    #   sat drivers _?options...?_
    #
    # Options:
    #   -nbhood  - Neighborhood name, or "*" for all (default).
    #   -group   - Group name, or "*" for all (default).
    #   -concern - Concern name, or "*" for all (default), or "mood" for
    #              mood
    #   -start   - Start time; defaults to time 0
    #   -end     - End time; defaults to latest time
    #
    # If -concern is "mood", then the contribution
    # to mood will be computed for each driver, neighborhood, and group,
    # and added to the output.
    #
    # If no options are specified, the data will be accumulated for 
    # all neighborhoods, groups, and concerns across the entire run
    # of the simulation.
    #
    # The results are stored in the temporary table <gram_sat_drivers>.
    # The data will persist until the next query, or until the 
    # database is closed.

    method "sat drivers" {args} {
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
            set conditions "WHERE [join $condList { AND }]"
        } else {
            set conditions ""
        }

        $rdb eval "
            INSERT INTO gram_sat_drivers (driver, n, g, c, acontrib)
            SELECT driver, n, g, c, total(acontrib) 
            FROM gram_sat_contribs
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
            JOIN gram_ngc USING (n,g,c)
            JOIN gram_ng  USING (n,g)
            GROUP BY driver, gram_sat_drivers.n, gram_sat_drivers.g
        } {
            $rdb eval {
                INSERT INTO 
                gram_sat_drivers(driver,n,g,c,acontrib)
                VALUES($driver,$n,$g,'mood',$mood)
            }
        }
    }

    #-------------------------------------------------------------------
    # Group: Cooperation Adjustments and Inputs
    #
    # An adjustment is an administrative change to a particular
    # cooperation level.  An input is a level or slope change to a
    # particular cooperation level that has indirect effects across
    # the playbox as determined by GRAM.
    #
    # Both adjustments and inputs are made relative to some _driver_, as
    # created using <driver add>. Each has an input ID, a driver-specific
    # serial number. Thus, any adjustment or input can be identified as
    # "_driver.input_".

    # Method: coop adjust
    #
    # Adjusts coop.nfg by the required amount, clamping it within bounds.
    #
    # Returns the input ID for this driver.  
    #
    # Syntax:
    #   coop adjust _driver n f g mag_
    #
    #   driver - The driver ID
    #   n      - Neighborhood name, or "*" for all.
    #   f      - Civilian group name, or "*" for all.
    #   g      - Force group name, or "*" for all.
    #   mag    - Magnitude (a qmag value)

    method "coop adjust" {driver n f g mag} {
        $self Log detail "coop adjust driver=$driver n=$n f=$f g=$g M=$mag"

        # FIRST, check the inputs, and accumulate query terms
        set where [list]

        # driver
        $self driver validate $driver "Cannot coop adjust"

        # n
        if {$n ne "*"} {
            $nbhoods validate $n
            lappend where "n = \$n "
        }

        # f
        if {$f ne "*"} {
            $cgroups validate $f
            lappend where "f = \$f "
        }

        # g
        if {$g ne "*"} {
            $fgroups validate $g
            lappend where "g = \$g "
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
                WHERE n=$n AND g=$f
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

        if {[llength $where] > 0} {
            set where "WHERE [join $where { AND }]"
        } else {
            set where ""
        }

        foreach curve_id [$rdb eval "
            SELECT curve_id
            FROM gram_coop
            $where
        "] {
            $self AdjustCurve $driver $curve_id $mag
        }

        # NEXT, compute the cooperation roll-ups
        $self ComputeCoopRollups

        return [$self DriverGetInput $driver]
    }

    # Method: coop set
    #
    # Sets coop.nfg to the required amount. Returns the input ID for this
    # driver. 
    #
    # Syntax:
    #   coop set _driver n f g coop_ ?-undo?
    #
    #   driver - The driver ID
    #   n      - Neighborhood name, or "*" for all.
    #   f      - Civilian group name, or "*" for all.
    #   g      - Force group name, or "*" for all.
    #   mag    - Magnitude (a qmag value)
    #
    # Options:
    #   -undo  - Flag; decrements last_input instead of incrementing.
    #
    # NOTE: If -undo is given, decrements the last_input counter for this
    # driver, and returns nothing.  This is a stopgap measure to allow
    # <coop adjust> and <coop set> to be undone.

    method "coop set" {driver n f g coop {flag ""}} {
        $self Log detail "coop set driver=$driver n=$n f=$f g=$g C=$coop $flag"

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
                WHERE n=$n AND g=$f
            }]} "cooperation is not tracked for group $f in nbhood $n"
        }


        # qcooperation
        qcooperation validate $coop
        set coop [qcooperation value $coop]

        # NEXT, do the query.  Note that we could do the adjustment
        # in a single UPDATE query, except that we need to save the
        # adjustment to the history.
        foreach {curve_id mag} [$rdb eval "
            SELECT curve_id, \$coop - coop AS mag
            FROM gram_coop
            WHERE mag != 0.0
            $where
        "] {
            $self AdjustCurve $driver $curve_id $mag
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

    # Method: coop level
    #
    # Schedules a new cooperation level input with the specified parameters.
    #
    # Returns the driver input number for this input.  This is
    # a number that starts at 1 and is incremented for each level or slope
    # input received for the driver.
    #
    # Syntax:
    #   coop level _driver ts n f g limit days ?options?_
    #
    #   driver - Driver ID
    #   ts     - Start time, integer ticks
    #   n      - Neighborhood name
    #   f      - Civilian group name
    #   g      - Force group name
    #   limit  - Magnitude of the effect (qmag)
    #   days   - Realization time of the effect, in days (qduration)
    #
    # Options: 
    #   -cause cause        - Name of the cause of this input
    #   -s factor           - "here" indirect effects multiplier, defaults
    #                         to 1.0
    #   -p factor           - "near" indirect effects multiplier, defaults
    #                         to 0
    #   -q factor           - "far" indirect effects multiplier, defaults
    #                         to 0
    #   -athresh threshold  - Ascending threshold, defaults to 100.0.
    #   -dthresh threshold  - Descending threshold, defaults to 0.0

    method "coop level" {driver ts n f g limit days args} {
        $self Log detail "coop level driver=$driver ts=$ts n=$n f=$f g=$g lim=$limit days=$days $args"

        # FIRST, check the regular inputs
        $self driver validate $driver "Cannot coop level"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        $nbhoods validate $n
        $cgroups validate $f
        $fgroups validate $g

        qmag      validate $limit
        qduration validate $days

        # NEXT, validate the options
        $self ParseInputOptions coop opts $args

        # NEXT, normalize the input data.

        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(dn)       $n
        set input(df)       $f
        set input(dg)       $g
        set input(ts)       $ts
        set input(days)     [qduration value $days]
        set input(llimit)   [qmag      value $limit]
        set input(s)        $opts(-s)
        set input(athresh)  $opts(-athresh)
        set input(dthresh)  $opts(-dthresh)

        # NEXT, Apply the effects_factor.nf to p and q.
        $rdb eval {
            SELECT effects_factor FROM gram_ng
            WHERE n = $input(dn)
            AND   g = $input(df);
        } {
            set input(p) [expr {$opts(-p) * $effects_factor}]
            set input(q) [expr {$opts(-q) * $effects_factor}]
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

        # NEXT, schedule the effects in every influenced neighborhood
        set epsilon [$parm get gram.epsilon]

        set plimit [$self GetProxLimit $input(s) $input(p) $input(q)]

        # NEXT, schedule the effects in every influenced neighborhood
        # within the proximity limit.

        $rdb eval {
            SELECT * FROM gram_coop_influence_view
            WHERE dn        = $input(dn)
            AND   df        = $input(df)
            AND   dg        = $input(dg)
            AND   prox      < $plimit 
        } effect {
            $self ScheduleLevel input effect $epsilon
        }

        return $input(input)
    }

    # Method: coop slope
    #
    # Schedules a new GRAM slope input with the specified parameters.
    #
    # * A subsequent input for the same driver, n, f, g, and cause will update
    #   all direct and indirect effects accordingly.
    #
    # * Such subsequent inputs must have a start time, ts,
    #   no earlier than the ts of the previous input.
    #
    # Returns the driver input number for this input.  This is
    # a number that starts at 1 and is incremented for each level or slope
    # input received for the driver.
    #
    # Syntax:
    #   coop slope "driver ts n f g slope ?options...?"
    #
    #   driver - Driver ID
    #   ts     - Start time, integer ticks
    #   n      - Neighborhood name
    #   f      - Civilian group name
    #   g      - Force group name
    #   slope  - Slope (change/day) of the effect (qmag)
    #
    # Options: 
    #   -cause cause        - Name of the cause of this input
    #   -s factor           - "here" indirect effects multiplier, defaults
    #                         to 1.0
    #   -p factor           - "near" indirect effects multiplier, defaults
    #                         to 0
    #   -q factor           - "far" indirect effects multiplier, defaults
    #                         to 0
    #   -athresh threshold  - Ascending threshold, defaults to 100.0.
    #   -dthresh threshold  - Descending threshold, defaults to 0.0

    method "coop slope" {driver ts n f g slope args} {
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

        $nbhoods validate $n
        $cgroups validate $f
        $fgroups validate $g

        qmag validate $slope

        # NEXT, validate the options
        $self ParseInputOptions coop opts $args

        # NEXT, normalize the input data

        set input(driver)   $driver
        set input(input)    [$self DriverGetInput $driver]
        set input(dn)       $n
        set input(df)       $f
        set input(dg)       $g
        set input(slope)    [qmag value $slope]
        set input(ts)       $ts
        set input(s)        $opts(-s)
        set input(p)        $opts(-p)
        set input(q)        $opts(-q)
        set input(athresh)  $opts(-athresh)
        set input(dthresh)  $opts(-dthresh)

        # NEXT, Apply the effects_factor.nf to p and q.
        $rdb eval {
            SELECT effects_factor FROM gram_ng
            WHERE n = $input(dn)
            AND   g = $input(df);
        } {
            set input(p) [expr {$opts(-p) * $effects_factor}]
            set input(q) [expr {$opts(-q) * $effects_factor}]
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

        # NEXT, if the slope is 0, ignore it, unless effects
        # are ongoing for this driver, in which case terminate all related
        # chains.  Either way, we're done.

        if {$input(slope) == 0.0} {
            $rdb eval {
                SELECT id, ts, te, cause, delay, future 
                FROM gram_nfg     AS direct
                JOIN gram_effects AS effect 
                     ON effect.direct_id = direct.nfg_id
                WHERE direct.n      = $input(dn) 
                AND   direct.f      = $input(df) 
                AND   direct.g      = $input(dg) 
                AND   effect.etype  = 'S'
                AND   effect.driver = $input(driver)
                AND   effect.cause  = $input(cause)
            } effect {
                $self TerminateSlope input effect
            }

            return $input(input)
        }

        # NEXT, get the de facto proximity limit.
        set plimit [$self GetProxLimit $input(s) $input(p) $input(q)]

        # NEXT, terminate existing slope chains which are outside
        # the de facto proximity limit.
        $rdb eval {
            SELECT id, ts, te, cause, delay, future 
            FROM gram_nfg     AS direct
            JOIN gram_effects AS effect 
                 ON effect.direct_id = direct.nfg_id
            WHERE direct.n      =  $input(dn) 
            AND   direct.f      =  $input(df) 
            AND   direct.g      =  $input(dg) 
            AND   effect.etype  =  'S'
            AND   effect.driver =  $input(driver)
            AND   effect.cause  = $input(cause)
            AND   effect.prox   >= $plimit
        } effect {
            $self TerminateSlope input effect
        }

        # NEXT, schedule the effects in every influenced neighborhood
        # within the proximity limit.
        $rdb eval {
            SELECT * FROM gram_coop_influence_view
            WHERE dn        = $input(dn)
            AND   df        = $input(df)
            AND   dg        = $input(dg)
            AND   prox      < $plimit
        } effect {
            $self ScheduleSlope input effect $epsilon
        }

        return $input(input)
    }


    #-------------------------------------------------------------------
    # Group: Cancellation/Termination of Drivers

    # Method: cancel
    #
    # Cancels all actual contributions made to any curve by the specified 
    # driver.  Contributions are cancelled by subtracting the
    # "actual: value from the relevant curves and deleting them from the
    # <rdb>.
    #
    # Syntax:
    #   cancel _driver_ ?-delete?
    #
    #   driver - A Driver ID
    #
    # Options:
    #   -delete - If the option is given, the driver ID itself will be
    #             deleted entirely; otherwise, it will remain with a
    #             type of "unknown" and a name of "CANCELLED".

    method cancel {driver {option ""}} {
        # FIRST, Update the curves.
        set updates [list]

        $rdb eval {
            SELECT curve_id, curve_type, total(acontrib) AS actual
            FROM gram_contribs JOIN gram_curves USING (curve_id)
            WHERE driver = $driver
            GROUP BY curve_id
        } {
            lappend updates $curve_id $curve_type $actual
        }

        foreach {curve_id curve_type actual} $updates {
            $rdb eval {
                UPDATE gram_curves
                SET val = clamp($curve_type,val - $actual)
                WHERE curve_id=$curve_id
            }
        }

        # NEXT, delete the contributions from gram_deltas
        $rdb eval {
            SELECT curve_id, time, acontrib AS actual
            FROM gram_contribs
            WHERE driver = $driver
        } {
            $rdb eval {
                UPDATE OR IGNORE gram_deltas
                SET delta = delta - $actual
                WHERE curve_id=$curve_id
                AND   time = $time
            }
        }

        # NEXT, delete the effects and the contributions.
        $rdb eval {
            DELETE FROM gram_effects 
            WHERE driver = $driver;

            DELETE FROM gram_contribs 
            WHERE driver = $driver;
        }

        # NEXT, delete or mark the driver.
        if {$option eq "-delete"} {
            $rdb eval {
                DELETE FROM gram_driver
                WHERE driver = $driver
            }
        } else {
            $rdb eval {
                UPDATE gram_driver
                SET dtype      = "unknown",
                    name       = "CANCELLED",
                    oneliner   = "",
                    last_input = 0
                WHERE driver = $driver
            }
        }

        # NEXT, recompute other outputs that depend on sat.ngc
        $self ComputeSatRollups
        $self ComputeCoopRollups

        return
    }

    # Method: terminate
    #
    # Terminates all slope effects for the given driver, just as though
    # they were assigned a zero slope.  Termination of delayed effects 
    # is delayed accordingly.
    #
    # Syntax:
    #   terminate _driver ts_
    #
    #   driver - A driver ID
    #   ts     - A start time.

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
            WHERE etype  = 'S'
            AND   driver = $driver
        } row {
            $self TerminateSlope input row
        }
    }

    #-------------------------------------------------------------------
    # Group: Effect Curves
    #
    # An effect curve is a variable whose value can vary over time,
    # subject to level and slope effects, e.g., a satisfaction or 
    # cooperation curve.  This section of the module contains the 
    # generic effect curve code.
    #
    # The following tables are used:
    #
    #   gram_curves   - One record per curve, including current value.
    #   gram_effects  - One record per level/slope effect
    #   gram_contribs - History of contributions to curves.
    #   gram_deltas   - History of curve values.
    #
    # Other sections of this module will provide identities to specific
    # curves.  The satisfaction section, for example, maps n,g,c
    # combinations to particular curves.

    # Method: CurvesInit
    #
    # Initializes the curves submodule.  The <gram_curves> table is
    # populated at GRAM <init>; but this routine resets variable data and
    # clears the history.

    method CurvesInit {} {
        $rdb eval {
            DELETE FROM gram_effects;
            DELETE FROM gram_contribs;
            DELETE FROM gram_deltas;
            DELETE FROM gram_driver;

            UPDATE gram_curves 
            SET val   = val0,
                delta = 0.0,
                slope = 0.0;
        }

        # NEXT the values as of this time.
        $self SaveDeltas
    }

    # Method: AdjustCurve
    #
    # Adjusts the curve by the selected amount, clamping appropriately.
    #
    # Syntax:
    #   AdjustCurve _driver curve_id mag_
    #
    #   driver   - Driver ID
    #   curve_id - ID of the curve to adjust
    #   mag      - Magnitude to adjust by

    method AdjustCurve {driver curve_id mag} {
        # FIRST, get the curve type and current value of this curve.
        $rdb eval {
            SELECT curve_type, val 
            FROM gram_curves
            WHERE curve_id = $curve_id
        } {}
        
        # NEXT, get the new value
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
            set realmag [expr {$newVal - $val}]

            $rdb eval {
                INSERT OR IGNORE INTO
                gram_contribs(time, driver,
                              curve_id, acontrib)
                VALUES($db(time),
                       $driver, $curve_id, 0.0);

                UPDATE gram_contribs
                SET acontrib = acontrib + $realmag
                WHERE time = $db(time)
                AND   driver = $driver
                AND   curve_id = $curve_id;

                INSERT OR IGNORE INTO
                gram_deltas(time, curve_id, delta)
                VALUES($db(time), $curve_id, 0.0);

                UPDATE gram_deltas
                SET delta = delta + $realmag
                WHERE time = $db(time)
                AND   curve_id = $curve_id;
            }
        }
    }

    # Method: GetProxLimit
    #
    # An input to a curve cannot have any indirect effect beyond the
    # proximity limit.  There is a global proximity limit, as defined
    # by the gram.proxlimit parameter; but for each input, there is
    # also a _de facto_ proximity limit, given the global
    # proximity limit and the here, near, and far multipliers.  This
    # routine computed this _de facto_ proximity limit for an input.
    #
    # Syntax:
    #   GetProxLimit _s p q_
    #
    #  s - Here effects multiplier
    #  p - Near effects multiplier
    #  q - Far effects multiplier

    method GetProxLimit {s p q} {
        set plimit $proxlimit([$parm get gram.proxlimit])
        
        if {$q == 0.0} {
            if {$p == 0.0} {
                if {$s == 0.0} {
                    set plimit $proxlimit(none)
                } else {
                    set plimit [min $plimit $proxlimit(here)]
                }
            } else {
                set plimit [min $plimit $proxlimit(near)]
            }
        }
        
        return $plimit
    }

    # Method: ScheduleLevel
    #
    # Schedules a single level effect, given a dizzying set of input
    # values.
    #
    # Syntax:
    #   ScheduleLevel _inputArray effectArray epsilon_
    #
    #   inputArray  - Name of a variable containing an array of data about
    #                 the current input
    #   effectArray - Name of a variable containing an array of data about
    #                 the current effect for the input.
    #   epsilon     - The current epsilon.  Level effects smaller than
    #                 epsilon take effect immediately.
    #
    # The _inputArray_ should contain the following values.
    #
    #   driver  - Driver ID
    #   input   - Input number, for this driver
    #   cause   - "Cause" of this input
    #   ts      - Start time, in ticks
    #   days    - Realization time, in days
    #   llimit  - "level limit", the direct effect magnitude
    #   s       - Here effects multiplier
    #   p       - Near effects multiplier
    #   q       - Far effects multiplier
    #   athresh - Ascending threshold
    #   dthresh - Descending threshold
    #
    # The _effectArray_ should contain the following values.
    #
    #   curve_id  - ID of affected curve in <gram_curves>.
    #   direct_id - ID of entity receiving the direct effect (the table
    #               depends on the curve type, satisfaction or cooperation).
    #   prox      - Proximity, -1 (direct), 0 (here), 1 (near), or 2 (far)
    #   factor    - Influence multiplier
    #   delay     - Effects delay, in ticks

    method ScheduleLevel {inputArray effectArray epsilon} {
        upvar 1 $inputArray input
        upvar 1 $effectArray effect

        # FIRST, determine the real llimit
        if {$effect(prox) == 2} {
            # Far
            set mult [expr {$input(q) * $effect(factor)}]
        } elseif {$effect(prox) == 1} {
            # Near
            set mult [expr {$input(p) * $effect(factor)}]
        } elseif {$effect(prox) == 0} {
            # Here
            set mult [expr {$input(s) * $effect(factor)}]
        } else {
            set mult $effect(factor)
        }
        
        set llimit [expr {$mult * $input(llimit)}]

        if {$llimit == 0.0} {
            # SKIP!
            return
        }

        # NEXT, compute the start time, taking the effects 
        # delay into account.

        set ts [expr {$input(ts) + $effect(delay)}]

        # NEXT, Compute te and tau
        if {abs($llimit) <= $epsilon} {
            set te $ts
            set tau 0.0
        } else {
            set te [expr {int($ts + [$clock fromDays $input(days)])}]

            # NEXT, compute tau, which determines the shape of the
            # exponential curve.
            set tau [expr {
                $input(days)/
                    (- log($epsilon/abs($llimit)))
            }]
        }

        # NEXT, insert the data into gram_effects
        $rdb eval {
            INSERT INTO gram_effects(
                curve_id,
                direct_id,
                driver,
                input, 
                etype,
                cause,
                prox,
                ts,
                te,
                athresh,
                dthresh,
                days, 
                tau,
                llimit
            )
            VALUES(
                $effect(curve_id),
                $effect(direct_id),
                $input(driver),
                $input(input), 
                'L',
                $input(cause),
                $effect(prox),
                $ts, 
                $te,
                $input(athresh),
                $input(dthresh),
                $input(days), 
                $tau,
                $llimit
            )
        }

        return
    }

    # Method: ScheduleSlope
    #
    # Schedules or updates a single slope effect, given a dizzying set
    # of input values.
    #
    # Syntax:
    #   ScheduleSlope _inputArray effectArray epsilon_
    #
    #   inputArray  - Name of a variable containing an array of data about
    #                 the current input
    #   effectArray - Name of a variable containing an array of data about
    #                 the current effect for the input.
    #   epsilon     - The current epsilon.  Slope effects smaller than
    #                 epsilon are ignored.
    #
    # The _inputArray_ should contain the following values.
    #
    #   driver  - Driver ID
    #   input   - Input number, for this driver
    #   cause   - "Cause" of this input
    #   ts      - Start time, in ticks
    #   slope   - Slope, in nominal points/day
    #   s       - Here effects multiplier
    #   p       - Near effects multiplier
    #   q       - Far effects multiplier
    #   athresh - Ascending threshold
    #   dthresh - Descending threshold
    #
    # The _effectArray_ should contain the following values.
    #
    #   curve_id  - ID of affected curve in gram_curves.
    #   direct_id - ID of entity receiving the direct effect (depends on
    #               curve type).
    #   prox      - Proximity, -1 (direct), 0 (here), 1 (near), or 2 (far)
    #   factor    - Influence multiplier
    #   delay     - Effects delay, in ticks

    method ScheduleSlope {inputArray effectArray epsilon} {
        upvar 1 $inputArray input
        upvar 1 $effectArray effect

        # FIRST, determine the real slope.
        if {$effect(prox) == 2} {
            # Far
            set mult [expr {$input(q) * $effect(factor)}]
        } elseif {$effect(prox) == 1} {
            # Near
            set mult [expr {$input(p) * $effect(factor)}]
        } elseif {$effect(prox) == 0} {
            # Here
            set mult [expr {$input(s) * $effect(factor)}]
        } else {
            set mult $effect(factor)
        }
        
        set slope [expr {$mult * $input(slope)}]

        # NEXT, if the slope is very small, set it to
        # zero.
        if {abs($slope) < $epsilon} {
            set slope 0.0
        }

        # NEXT, compute the start time, taking the effects 
        # delay into account.
        set ts [expr {$input(ts) + $effect(delay)}]

        # NEXT, if the driver already has an entry in gram_effects,
        # we need to update the entry. Get the ID of the chain's entry, if 
        # any.
        set old(id) ""

        $rdb eval {
            SELECT id, cause, ts, te, future 
            FROM gram_effects
            WHERE etype='S'
            AND driver=$input(driver)
            AND curve_id=$effect(curve_id)
            AND direct_id=$effect(direct_id)
            AND cause = $input(cause)
        } old {}

        # NEXT, if a chain exists, update it.
        if {$old(id) ne ""} {
            # FIRST, check the time constraints, and update te if
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
            
            # NEXT, update the record
            $rdb eval {
                UPDATE gram_effects
                SET input   = $input(input),
                    te      = $te,
                    future  = $old(future),
                    athresh = $input(athresh),
                    dthresh = $input(dthresh)
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
                etype,
                curve_id,
                direct_id,
                driver,
                input,
                prox,
                athresh,
                dthresh,
                delay,
                cause,
                slope,
                ts,
                te
            )
            VALUES(
                'S',
                $effect(curve_id),
                $effect(direct_id),
                $input(driver),
                $input(input),
                $effect(prox),
                $input(athresh),
                $input(dthresh),
                $effect(delay),
                $input(cause),
                $slope,
                $ts,
                $maxEndTime
            );
        }

        return
    }

    # Method: TerminateSlope
    #
    # Terminates a slope effect by scheduling a slope of 0
    # after the appropriate time delay.
    #
    # Constraints: The relevant effect must already exist in <gram_effects>.
    #
    # Syntax:
    #   TerminateSlope _inputArray effectArray_
    #
    #   inputArray  - Name of a variable containing an array of data about
    #                 the current input
    #   effectArray - Name of a variable containing an array of data about
    #                 the current effect for the input.
    #
    # The _inputArray_ should contain the following values.
    #
    #   ts    - Termination time, in ticks
    #   input - Input number for driver
    #
    # The _effectArray_ should contain the following values.
    #
    #   id     - ID of gram_effects record
    #   ts     - Start time of current slope, in ticks
    #   te     - End time of current slope, in ticks
    #   delay  - Delay of this effect, in ticks
    #   future - Future slopes

    method TerminateSlope {inputArray effectArray} {
        upvar 1 $inputArray  input
        upvar 1 $effectArray effect

        # FIRST, compute the termination time, taking the effects 
        # delay into account.
        set ts [expr {$input(ts) + $effect(delay)}]

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


    # Method: UpdateCurves
    #
    # Applies level and slope effects to curves for the time interval
    # from timelast to time.  Computes the current value for each
    # curve and the slope for the current time <advance>.

    method UpdateCurves {} {
        # FIRST, initialize the delta for this time step to 0.
        $rdb eval {
            UPDATE gram_curves
            SET delta = 0.0
        }

        # NEXT, Add the contributions of the level and slope effects.
        $self profile $self ComputeNominalContributionsForLevelEffects
        $self profile $self ComputeNominalContributionsForSlopeEffects
        $self profile $self ComputeActualContributionsByCause
        $self profile $self SaveContribs
        $self profile $self DeleteExpiredEffects

        # NEXT, Compute the current value and slope, clamping the
        # current value within its upper and lower bounds.

        set deltaDays [$clock toDays [expr {$db(time) - $db(timelast)}]]

        $rdb eval {
            UPDATE gram_curves
            SET val   = max(min(val + delta, 100.0), -100.0),
                slope = delta / $deltaDays
        }

        # NEXT, save the current deltas to each curve.
        $self SaveDeltas
    }

    # Method: ComputeNominalContributionsForLevelEffects
    #
    # Computes the nominal contribution of each level effect to each
    # curve for this time step.

    method ComputeNominalContributionsForLevelEffects {} {
        # FIRST, get parameter values
        set plimit \
            $proxlimit([$parm get gram.proxlimit])

        # NEXT, for each level effect for which the start time has
        # been reached and which has not yet expired, compute its nominal
        # contribution. Accumulate the desired updates, and apply them
        # once the loop is complete.

        set updates [list]

        $rdb eval {
            SELECT ts, te, llimit, tau, nominal, id, athresh, dthresh,
                   curve_type, val 
            FROM gram_effects JOIN gram_curves USING (curve_id)
            WHERE etype = 'L'
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

                set deltaDays [expr {double($db(time) - $row(ts))/1440.0}]

                set valueNow [expr {
                    $row(llimit) * (1.0 - exp(-$deltaDays/$row(tau)))
                }]
            }

            set contrib [expr {$valueNow - $row(nominal)}]

            # NEXT, add the increment to this effect's nominal
            # contribution to date.
            set row(nominal) [expr {$row(nominal) + $contrib}]
            
            # NEXT, apply thresholds
            if {$contrib > 0 && $row(val) >= $row(athresh)} {
                set contrib 0
            } elseif {$contrib < 0 && $row(val) <= $row(dthresh)} {
                set contrib 0
            }

            lappend updates $row(id) $row(nominal) $contrib
        }

        foreach {id nominal contrib} $updates {
            $rdb eval {
                UPDATE gram_effects
                SET tlast    = $db(time),
                    nominal  = $nominal,
                    ncontrib = $contrib,
                    acontrib = 0
                WHERE id=$id;
            }
        }
    }

    # Method: ComputeNominalContributionsForSlopeEffects
    #
    # Computes the nominal contribution of each slope effect to each
    # curve for this time advance.

    method ComputeNominalContributionsForSlopeEffects {} {
        # FIRST, get parameter values
        set plimit \
            $proxlimit([$parm get gram.proxlimit])

        # NEXT, Get each slope effect that's been active during
        # the last time step, and compute and save their nominal 
        # contributions.
        
        set futureUpdates {}
        set contribUpdates {} 

        $rdb eval {
            SELECT id, 
                   nominal, 
                   ts, 
                   te, 
                   gram_effects.slope AS slope,
                   future,
                   athresh,
                   dthresh,
                   gram_curves.val AS val,
                   curve_type
            FROM gram_effects JOIN gram_curves USING (curve_id)
            WHERE etype='S'
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
                
                set nvalue       [expr {$row(slope)*$stepDays}]
                set row(nominal) [expr {$row(nominal) + $nvalue}]
                set ncontrib     [expr {$ncontrib + $nvalue}]

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
                    
                    lappend futureUpdates \
                        $row(id) $row(ts) $row(te) $row(slope) $row(future)
                } else {
                    # We're done
                    break
                }
            }

            # NEXT, apply thresholds
            if {$ncontrib > 0 && $row(val) >= $row(athresh)} {
                set ncontrib 0
            } elseif {$ncontrib < 0 && $row(val) <= $row(dthresh)} {
                set ncontrib 0
            }
            
            lappend contribUpdates \
                $row(id) $row(nominal) $ncontrib
        }
        
        foreach {id ts te slope future} $futureUpdates {
            $rdb eval {
                UPDATE gram_effects
                SET ts     = $ts,
                    te     = $te,
                    slope  = $slope,
                    future = $future
                WHERE id=$id
            }
        }
        
        foreach {id nominal ncontrib} $contribUpdates {
            $rdb eval {
                UPDATE gram_effects
                SET tlast    = $db(time),
                    nominal  = $nominal,
                    ncontrib = $ncontrib,
                    acontrib = 0
                WHERE id=$id
            }
        }
    }

    # Method: ComputeActualContributionsByCause
    #
    # Determine the maximum positive and negative contributions
    # for each curve and cause, scale them, and apply them.

    method ComputeActualContributionsByCause {} {
        # FIRST, accumulate the actual contributions to the
        # curves.
        set updates [list]

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
                    CASE WHEN ncontrib > 0
                         THEN ncontrib
                         ELSE 0 END AS pos,
                    CASE WHEN ncontrib < 0
                         THEN ncontrib
                         ELSE 0 END AS neg
             FROM gram_effects JOIN gram_curves USING (curve_id)
             WHERE ncontrib != 0)
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

            # NEXT, compute and cache the actual contribution
            set acontrib [expr {$scale * $contrib}]

            lappend updates $curve_id $acontrib

            # NEXT, store the positive effects by id and cause
            if {$maxpos > 0.0} {
                set poscontribs($curve_id,$cause) \
                    [expr {$maxpos*$scale/$sumpos}]
            }
            
            # NEXT, store the negative effects by id and cause
            if {$minneg < 0.0} {
                set negcontribs($curve_id,$cause) \
                    [expr {$minneg*$scale/$sumneg}]
            }
        }

        # NEXT, apply the updates to the curves.
        foreach {curve_id acontrib} $updates {
            $rdb eval {
                UPDATE gram_curves
                SET delta = delta + $acontrib
                WHERE curve_id=$curve_id
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
            WHERE ncontrib != 0.0
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

    # Method: DeleteExpiredEffects
    #
    # Mark expired effects.

    method DeleteExpiredEffects {} {
        # FIRST, get the current proximity limit.
        set plimit \
            $proxlimit([$parm get gram.proxlimit])

        # NEXT, save these expired level and slope effects, if 
        # desired.
        if {[parm get gram.saveExpired]} {
            $rdb eval {
                DROP TABLE IF EXISTS gram_expired_effects;

                CREATE TABLE gram_expired_effects AS
                SELECT * FROM gram_effects
                WHERE
                    -- proxlimit has changed to exclude them, OR
                    (prox >= $plimit) OR 

                    -- level effect's time has elapsed
                    (etype = 'L' AND te <= $db(time)) OR

                    -- slope effect's is endlessly 0.0
                    (etype = 'S' AND slope == 0 AND te = $maxEndTime);
            }
        }

        # NEXT, Expire level and slope effects.
        #
        # Expire effects if the proxlimit has changed to
        # exclude them.
        #
        # Expire level effects if their full time has elapsed.
        #
        # Expire slope effects if they have reached their end time.

        $rdb eval {
            DELETE FROM gram_effects
            WHERE
                -- proxlimit has changed to exclude them, OR
                (prox >= $plimit) OR 

                -- level effect's time has elapsed
                (etype = 'L' AND te <= $db(time)) OR

                -- slope effect's is endlessly 0.0
                (etype = 'S' AND slope == 0 AND te = $maxEndTime);
        }
    }

    # Method: SaveContribs
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
            SELECT tlast, driver, curve_id,
                   total(acontrib) as acontrib
            FROM gram_effects
            WHERE tlast=$db(time) AND acontrib != 0.0
            GROUP BY driver, curve_id
        }
    }

    # Method: SaveDeltas
    #
    # Saves the current deltas to all curves to <gram_deltas>.

    method SaveDeltas {} {
        # FIRST, save the history data, if that's what we want to do
        set pname gram.saveHistory

        if {![$parm get $pname]} {
            $self Log warning \
                "no history saved; $pname is \"[$parm get $pname]\""
            return
        }

        set query {
            INSERT OR REPLACE
            INTO gram_deltas(time, curve_id, delta)
            SELECT $db(time), curve_id, delta
            FROM gram_curves
        }

        $rdb eval $query
    }

    #-------------------------------------------------------------------
    # Group: Miscellaneous Queries

    # Method: sat.ngc
    #
    # Returns the requested satisfaction level.  Note that
    # _g_ and _c_ must have the same group type, CIV or ORG.
    #
    # Syntax:
    #    sat.ngc _n g c_
    #
    #   n - A neighborhood name
    #   g - A CIV or ORG group name
    #   c - A CIV or ORG concern name

    method sat.ngc {n g c} {
        $nbhoods validate $n
        $cogroups validate $g
        $concerns validate $c

        set result [$rdb onecolumn {
            SELECT sat FROM gram_sat 
            WHERE n=$n AND g=$g AND c=$c
        }]

        if {$result eq ""} {
            # If the types of g and c don't match, this is
            # an error; otherwise, sat_tracked is 0, so return 0.0

            require {[$rdb exists {
                SELECT gc_id FROM gram_gc 
                WHERE g=$g AND c=$c
            }]} "The concern: $c is not valid for the specified group"
            
            set result 0.0
        }

        return $result
    }


    # Method: sat.ng
    #
    # Returns the requested satisfaction roll-up.
    #
    # Syntax:
    #   sat.ng _n g_
    #
    #   n - A neighborhood name
    #   g - A CIV or ORG group name

    method sat.ng {n g} {
        $nbhoods  validate $n
        $cogroups validate $g

        return [$rdb onecolumn {
            SELECT sat FROM gram_ng 
            WHERE n=$n AND g=$g
        }]
    }

    # Method: sat.nc
    #
    # Returns the requested satisfaction roll-up.
    #
    # Syntax:
    #   sat.nc _n c_
    #
    #   n - A neighborhood name
    #   c - A CIV or ORG concern name

    method sat.nc {n c} {
        $nbhoods  validate $n
        $concerns validate $c

        return [$rdb onecolumn {
            SELECT sat FROM gram_nc 
            WHERE n=$n AND c=$c
        }]
    }

    # Method: sat.gc
    #
    # Returns the requested satisfaction roll-up.  Note that
    # _g_ and _c_ must have the same group type.
    #
    # Syntax:
    #   sat.gc _g c_
    #
    #   g - A CIV or ORG group name
    #   c - A CIV or ORG concern name

    method sat.gc {g c} {
        $cogroups validate $g
        $concerns validate $c

        set result [$rdb onecolumn {
            SELECT sat FROM gram_gc 
            WHERE g=$g AND c=$c
        }]

        # Only empty if g and c don't match
        if {$result eq ""} {
            error "The concern: $c is not valid for the specified group"
        }

        return $result
    }

    # Method: sat.n
    #
    # Returns the requested satisfaction roll-up.
    #
    # Syntax:
    #   sat.n _n_
    #
    #   n - A neighborhood name

    method sat.n {n} {
        $nbhoods  validate $n

        return [$rdb onecolumn {
            SELECT sat FROM gram_n 
            WHERE n=$n
        }]
    }


    # Method: sat.g
    #
    # Returns the requested satisfaction roll-up.
    #
    # Syntax:
    #   sat.g _g_
    #
    #   g - A CIV or ORG group name

    method sat.g {g} {
        $cogroups validate $g

        return [$rdb onecolumn {
            SELECT sat FROM gram_g 
            WHERE g=$g
        }]
    }

    # Method: sat.c
    #
    # Returns the requested satisfaction roll-up.
    #
    # Syntax:
    #   sat.c _c_
    #
    #   c - A CIV or ORG concern name

    method sat.c {c} {
        $concerns validate $c

        return [$rdb onecolumn {
            SELECT sat FROM gram_c 
            WHERE c=$c
        }]
    }
    
    # Method: coop.nfg
    #
    # Returns the requested cooperation level.  Group _f_ must reside
    # in _n_.
    #
    # Syntax:
    #   coop.nfg _n f g_
    #
    #   n - A neighborhood name
    #   f - A CIV group name
    #   g - A FRC group name

    method coop.nfg {n f g} {
        $nbhoods validate $n
        $cgroups validate $f
        $fgroups validate $g

        set result [$rdb onecolumn {
            SELECT coop FROM gram_coop 
            WHERE n=$n AND f=$f AND g=$g
        }]

        if {$result eq ""} {
            error "Group $f does not reside in nbhood $n"
        }

        return $result
    }


    # Method: coop.ng
    #
    # Returns the requested cooperation roll-up.
    #
    # Syntax:
    #   coop.ng _n g_
    #
    #   n - A neighborhood name
    #   g - A FRC group name

    method coop.ng {n g} {
        $nbhoods validate $n
        $fgroups validate $g

        return [$rdb onecolumn {
            SELECT coop FROM gram_frc_ng 
            WHERE n=$n AND g=$g
        }]
    }


    # Method: nbhoodGroups
    #
    # Returns a list of the CIV groups that reside in the _nbhood_.
    #
    # Syntax:
    #   nbhoodGroups _nbhood_
    #
    #   nbhood - A neighborhood name

    method nbhoodGroups {nbhood} {
        $nbhoods validate $nbhood

        $rdb eval {
            SELECT g
            FROM gram_ng JOIN gram_g USING (g)
            WHERE n            = $nbhood
            AND   sat_tracked  = 1
            AND   gram_g.gtype = 'CIV'
            ORDER BY g
        }
    }

    # Method: time
    #
    # Current gram(n) simulation time, in ticks.
    method time {} { 
        return $db(time) 
    }


    #-------------------------------------------------------------------
    # Group: Data dumping methods

    # Method: dump sat.ngc
    #
    # Dumps a pretty-printed <gram_sat> table.
    #
    # By default, both CIV and ORG groups are included.
    # If a specific group is specified, then -civ and -org are 
    # ignored.
    #
    # Syntax:
    #   dump sat.ngc _?options?_
    #
    # Options:
    #   -civ       - Include CIV groups
    #   -org       - Include ORG groups
    #   -nbhood n  - Neighborhood name or *
    #   -group  g  - Group name or *

    method "dump sat.ngc" {args} {
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
                   ngc_id,
                   curve_id
            FROM gram_sat
            JOIN gram_g  USING (g)
            WHERE 1=1
            [tif {$civFlag}  {AND gram_g.gtype='CIV'}]
            [tif {$orgFlag}  {AND gram_g.gtype='ORG'}]
            [tif {$n ne "*"} {AND n='$n'}]
            [tif {$g ne "*"} {AND g='$g'}]
            ORDER BY ngc_id
        }]

        set labels {
            "Nbhood" "Group" "Con" "Sat" "Delta" "Sat0"
            "Slope" "NGC ID" "Curve ID"
        }

        set result [$rdb query $query -headercols 2 -labels $labels]

        if {$result eq ""} {
            set result "No matching data"
        }

        return $result
    }

    # Method: dump sat levels
    #
    # Returns a pretty-printed list of satisfaction level effects,
    # one per line. If _driver_ is given, only those effects that match are
    # included. 
    #
    # Syntax:
    #   dump sat levels _?driver?_
    #
    #   driver - A driver ID

    method "dump sat levels" {{driver "*"}} {
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
                   format('%5.1f',athresh),
                   format('%5.1f',dthresh),
                   format('%6.2f',nominal),
                   format('%6.2f',actual)
            FROM gram_sat_effects
            WHERE etype='L'
            AND driver GLOB '$driver'
            
            ORDER BY driver ASC, input ASC, 
                     dn ASC, dg ASC, cause ASC, 
                     prox ASC, n ASC, g ASC, ts ASC, c ASC, id ASC
        " -labels {
            "Input" "DN" "DG" "Cause" "E" 
            "Start Time" "End Time" 
            "Nbhd" "Grp" "Con" 
            "Days" "Limit" "AThresh" "DThresh" "Nominal" "Actual"
        } -headercols 4]
    }

    # Method: dump coop.nfg
    #
    # Dumps a pretty-printed <gram_coop> table.
    #
    # Syntax:
    #   dump coop.nfg _?options?_
    #
    # Options:
    #   -nbhood n  - Neighborhood name or *
    #   -civ    f  - Civilian Group name or *
    #   -frc    g  - Force Group name, or *
    #   -ids       - Includes curve IDs

    method "dump coop.nfg" {args} {
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
            WHERE 1=1
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

    # Method: dump coop levels
    #
    # Returns a pretty-printed list of cooperation level effects,
    # one per line. If _driver_ is given, only those effects that match are
    # included. 
    #
    # Syntax:
    #   dump coop levels _?driver?_

    method "dump coop levels" {{driver "*"}} {
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
                   format('%5.1f',athresh),
                   format('%5.1f',dthresh),
                   format('%6.2f',nominal),
                   format('%6.2f',actual)
            FROM gram_coop_effects
            WHERE etype='L'
            AND driver GLOB '$driver'
            
            ORDER BY driver ASC, input ASC, 
                     dn ASC, df ASC, dg ASC, cause ASC, 
                     prox ASC, n ASC, f ASC, g ASC, ts ASC, id ASC
        " -labels {
            "Input" "DN" "DF" "DG" "Cause" "E" 
            "Start Time" "End Time" 
            "N" "F" "G" 
            "Days" "Limit" "AThresh" "DThresh" "Nominal" "Actual"
        } -headercols 5]
    }

    # Method: dump sat level
    #
    # Returns a pretty-printed list of the level effects acting
    # on the specific satisfaction level, one per line, sorted by
    # cause.
    #
    # Syntax:
    #   dump sat level _n g c_
    #
    #   n - A neighborhood name
    #   g - A group name
    #   c - A concern name

    method "dump sat level" {n g c} {
        # FIRST, validate the inputs
        $nbhoods  validate $n

        $self ValidateGC $g $c

        return [$rdb query "
            SELECT cause,
                   tozulu(ts),
                   tozulu(te),
                   format('%5.1f',llimit),
                   format('%5.1f',athresh),
                   format('%5.1f',dthresh),
                   format('%6.2f',nominal),
                   format('%7.3f',ncontrib),
                   format('%6.2f',actual),
                   format('%7.3f',acontrib),
                   driver || '.' || input,
                   dn,
                   dg,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END
            FROM gram_sat_effects
            WHERE etype='L'
            AND n='$n' AND g='$g' AND c='$c'
            ORDER BY cause ASC, ts ASC, llimit DESC
        " -labels {
            "Cause" "Start Time" "End Time" 
            "Limit" "AThr" "DThr" "NTotal" "NContrib" "ATotal" "AContrib" 
            "Input" "DN" "DG" "E"
        } -headercols 3]
    }

    # Method: dump coop level
    #
    # Returns a pretty-printed list of the level effects acting
    # on the specific cooperation level, one per line, sorted by
    # cause.
    #
    # Syntax:
    #   dump coop level _n f g_
    #
    #   n - A neighborhood name
    #   f - A CIV group name
    #   g - A FRC group name

    method "dump coop level" {n f g} {
        # FIRST, validate the inputs
        $nbhoods validate $n
        $cgroups validate $f
        $fgroups validate $g

        return [$rdb query "
            SELECT cause,
                   tozulu(ts),
                   tozulu(te),
                   format('%5.1f',llimit),
                   format('%5.1f',athresh),
                   format('%5.1f',dthresh),
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
            WHERE etype='L'
            AND n='$n' AND f='$f' AND g='$g'
            ORDER BY cause ASC, ts ASC, llimit DESC
        " -labels {
            "Cause" "Start Time" "End Time" 
            "Limit" "AThr" "DThr" "NTotal" "NContrib" "ATotal" "AContrib" 
            "Input" "DN" "DF" "DG" "E"
        } -headercols 3]
    }

    # Method: dump sat slopes
    #
    # Returns a pretty-printed list of slope effects, one per line.
    # If _driver_ is given, only those effects that match are included.
    #
    # TBD: The disaggregation of the "future" column can be done in
    # one routine shared with <dump coop slopes>.
    #
    # Syntax:
    #   dump sat slopes _?driver?_
    #
    #   driver  - A driver ID

    method "dump sat slopes" {{driver ""}} {
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
                athresh,
                dthresh,
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
                   athresh,
                   dthresh,
                   nominal,
                   actual
            FROM gram_sat_effects
            WHERE etype='S'
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
                        athresh,
                        dthresh,
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
                        $row(athresh),
                        $row(dthresh),
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
                   format('%5.1f',athresh),
                   format('%5.1f',dthresh),
                   format('%5.1f',nominal),
                   format('%5.1f',actual)
            FROM temp_gram_slope_query
        " -labels {
            "Input" "DN" "DG" "Cause" "E" 
            "Start Time" "End Time" "Nbhd" "Grp" "Con"  
            "Slope" "AThresh" "DThresh" "Nominal" "Actual"
        } -headercols 4]

        return $out
    }

    # Method: dump coop slopes
    #
    # Returns a pretty-printed list of slope effects, one per line.
    # If _driver_ is given, only those effects that match are included.  
    #
    # Syntax:
    #   dump coop slopes _?driver?_
    #
    #   driver - A driver ID

    method "dump coop slopes" {{driver "*"}} {
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
                athresh,
                dthresh,
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
                   athresh,
                   dthresh,
                   nominal,
                   actual
            FROM gram_coop_effects
            WHERE etype='S'
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
                        athresh,
                        dthresh,
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
                        $row(athresh),
                        $row(dthresh),
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
                   format('%5.1f',athresh),
                   format('%5.1f',dthresh),
                   format('%5.1f',nominal),
                   format('%5.1f',actual)
            FROM temp_gram_slope_query
        " -labels {
            "Input" "DN" "DF" "DG" "Cause" "E" 
            "Start Time" "End Time" "N" "F" "G"  
            "Slope" "AThresh" "DThresh" "Nominal" "Actual"
        } -headercols 5]

        return $out
    }


    # Method: dump sat slope
    #
    # Returns a pretty-printed list of the slope effects acting
    # on the specific satisfaction level, one per line, sorted by
    # cause.
    #
    # Syntax:
    #   dump sat slope _n g c_
    #
    #   n - A neighborhood name
    #   g - A group name
    #   c - A concern name

    method "dump sat slope" {n g c} {
        # FIRST, validate the inputs
        $nbhoods  validate $n

        $self ValidateGC $g $c

        return [$rdb query "
            SELECT cause,
                   tozulu(ts),
                   CASE WHEN te=$maxEndTime THEN 'n/a' ELSE tozulu(te) END,
                   format('%5.1f',slope),
                   format('%5.1f',athresh),
                   format('%5.1f',dthresh),
                   format('%6.2f',nominal),
                   format('%7.3f',ncontrib),
                   format('%6.2f',actual),
                   format('%7.3f',acontrib),
                   driver || '.' || input,
                   dn,
                   dg,
                   CASE WHEN prox=-1 THEN 'D' ELSE 'I' END
            FROM gram_sat_effects
            WHERE etype='S'
            AND n='$n' AND g='$g' AND c='$c'
            ORDER BY cause ASC, ts ASC, slope DESC
        " -labels {
            "Cause" "Start Time" "End Time" 
            "Slope" "AThr" "DThr" "NTotal" "NContrib"
            "ATotal" "AContrib" 
            "Input" "DN" "DG" "E"
        } -headercols 3]
    }

    # Method: dump coop slope
    #
    # Returns a pretty-printed list of the slope effects acting
    # on the specific cooperation level, one per line, sorted by
    # cause.
    #
    # Syntax:
    #   dump coop slope _n f g_
    #
    #   n - A neighborhood name
    #   f - A civ group name
    #   g - A frc group name

    method "dump coop slope" {n f g} {
        # FIRST, validate the inputs
        $nbhoods validate $n
        $cgroups validate $f
        $fgroups validate $g

        return [$rdb query "
            SELECT cause,
                   tozulu(ts),
                   CASE WHEN te=$maxEndTime THEN 'n/a' ELSE tozulu(te) END,
                   format('%5.1f',slope),
                   format('%5.1f',athresh),
                   format('%5.1f',dthresh),
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
            WHERE etype='S'
            AND n='$n' AND f='$f' AND g='$g'
            ORDER BY cause ASC, ts ASC, slope DESC
        " -labels {
            "Cause" "Start Time" "End Time" 
            "Slope" "AThr" "DThr" "NTotal" "NContrib"
            "ATotal" "AContrib" 
            "Input" "DN" "DF" "DG" "E"
        } -headercols 3]
    }

    #-------------------------------------------------------------------
    # Group: Utility Methods and Procs

    # Method: ValidateGC
    #
    # Verifies that:
    #
    #   * g is a valid CIV or ORG group
    #   * c is a valid CIV or ORG concern
    #   * g and c are both CIV or both ORG
    #
    # Throws an appropriate error if not.
    #
    # Syntax:
    #   ValidateGC _g c ?parmtext?_
    #
    #   g        - A group name
    #   c        - A concern name
    #   parmtext - Alternate errmsg text for "g and c"

    method ValidateGC {g c {parmtext "g and c"}} {
        $cogroups validate $g
        $concerns validate $c

        require {[$rdb exists {
            SELECT gc_id FROM gram_gc 
            WHERE g=$g AND c=$c
        }]} "$parmtext must have the same group type, CIV or ORG"
    }

    # Proc: ScaleFactor
    #
    # Returns a positive scale factor that will scale net positive
    # contributions toward the upper limit and net negative
    # contributions toward the lower limit.  The factor is proportional
    # to the distance of value from the relevant limit.
    #
    # See memo WHD-06-009, "Preventing Satisfaction Overflow" for
    # details.
    #
    # Syntax:
    #   ScaleFactor _curve_type value sign_
    #
    #   curve_type - SAT or COOP
    #   value      - The current value of the curve in question
    #   sign       - -1 if net contribution is negative, 
    #                +1 if net contribution is positive

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

    # Proc: ClampCurve
    #
    # Clamps the value based on the curve type.
    #
    # Syntax:
    #   ClampCurve _curve_type value_
    #
    #   curve_type - SAT or COOP
    #   value      - The current value of the curve in question

    proc ClampCurve {curve_type value} {
        if {$curve_type eq "SAT"} {
            return [qsat clamp $value]
        } else {
            # COOP
            return [qcooperation clamp $value]
        }
    }

    # Method: profile
    #
    # Executes the _command_ using Tcl's "time" command, and logs the
    # run time.
    #
    # Syntax:
    #   profile _command...._
    #
    #   command - A command to execute

    method profile {args} {
        set profile [time $args 1]
        $self Log detail "profile: $args $profile"
    }

    # Method: Log
    #
    # Logs the message to the -logger.
    #
    # Syntax:
    #   Log _severity message_
    #
    #   severity - A logger(n) severity level
    #   message  - The message text.

    method Log {severity message} {
        if {$options(-logger) ne ""} {
            $options(-logger) $severity $options(-logcomponent) $message
        }
    }
}






