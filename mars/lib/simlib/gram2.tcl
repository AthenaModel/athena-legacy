#-----------------------------------------------------------------------
# FILE: gram2.tcl
#
#   GRAM: Generalized Regional Analysis Module, V2.0
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
snit::enum ::simlib::satgrouptypes -values CIV

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

        $parm define gram.epsilon ::simlib::rmagnitude 0.01 {
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

        $parm define gram.coopRelationshipLimit ::simlib::rfraction 1.0 {
            Controls the set of civilian groups that receive cooperation
            indirect effects.  When CIV group g gets a direct cooperation
            effect, all groups f whose relationships rel.fg are
            greater than or equal to this limit receive indirect effects.
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
    # read from <gram2.sql>.

    typemethod {sqlsection schema} {} {
        return [readfile [file join $::simlib::library gram2.sql]]
    }

    # Type method: sqlsection tempschema
    #
    # Returns the section's temporary schema definitions, which are
    # read from <gram_temp.sql>.

    typemethod {sqlsection tempschema} {} {
        return [readfile [file join $::simlib::library gram2_temp.sql]]
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
    #   scid        - Satisfaction curve_id cache: dict g -> c -> curve_id
    #
    #   frel.gf     - FRC/FRC relationship dictionary: g -> f -> rel.
    #                 The order of the subscripts is reversed so that it
    #                 is easy to retrieve the relationships of all 
    #                 force groups f with force group g.
    #
    #   sstag       - Satisfaction spread tag
    #
    #   ssvalue - Satisfaction spread value
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
        scid             {}
        frel.gf          {}
        sstag            {}
        ssvalue          {}
    }

    # Variable: info
    #
    # Array, non-checkpointed scalar data.  The keys are as follows.
    #
    #   changed - 1 if the contents of <db> has changed, and 0 otherwise.
    
    variable info -array {
        changed  0
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

        # NEXT, compute the civ group proximity
        $self ComputeGroupProximity

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
            UPDATE gram_frc_ng SET coop0 = coop;
        }

        # NEXT, save initial group history.
        $self SaveGroupHistory

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
            rename $fgroups   "" ; set fgroups  ""
            rename $concerns  "" ; set concerns ""
        }
    }

    # Method: ClearTables
    #
    # Deletes all data from the <gram2.sql> tables for this instance

    method ClearTables {} {
        $rdb eval {
            DELETE FROM gram_curves;
            DELETE FROM gram_effects;
            DELETE FROM gram_contribs;
            DELETE FROM gram_deltas;
            DELETE FROM gram_hist_g;
            DELETE FROM gram_n;
            DELETE FROM gram_g;
            DELETE FROM gram_c;
            DELETE FROM gram_mn;
            DELETE FROM gram_fg;
            DELETE FROM gram_frc_g;
            DELETE FROM gram_frc_fg;
            DELETE FROM gram_frc_ng;
            DELETE FROM gram_gc;
            DELETE FROM gram_coop_fg;
        }
    }

    # Method: initialized
    #
    # Returns 1 if the <-loadcmd> has ever been successfully called, and 0
    # otherwise.

    method initialized {} {
        return $db(initialized)
    }
    
    # Method: ComputeGroupProximity
    #
    # Computes the proximity and effects delay between all pairs
    # of civilian groups, and places them in gram_fg.  Specify a
    # specific group to recompute proximity just for that group.
    #
    # Syntax:
    #    ComputeGroupProximity _?g?_
    #
    #    g    - An optional group name.

    method ComputeGroupProximity {{g ""}} {
        # FIRST, get the conversion from days to ticks
        set daysToTicks [$clock fromDays 1.0]

        # NEXT, get the query string.
        set query {
            SELECT gram_fg.f                            AS f,
                   gram_fg.g                            AS g,
                   gram_mn.proximity                    AS prox,
                   gram_mn.effects_delay * $daysToTicks AS delay
            FROM gram_fg
            JOIN gram_g AS F ON (F.g = gram_fg.f)
            JOIN gram_g AS G ON (G.g = gram_fg.g)
            JOIN gram_mn ON (gram_mn.m = F.n AND gram_mn.n = G.n)
        }

        if {$g ne ""} {
            append query {WHERE gram_fg.f = $g OR gram_fg.g = $g}
        }

        foreach {f g prox delay} [$rdb eval $query] {
            # FIRST, if f *is* g, this is a direct effect, and the
            # proximity is -1.
            if {$f eq $g} {
                set prox -1
            }

            # NEXT, save the data in the gram_fg table.
            $rdb eval {
                UPDATE gram_fg
                SET prox  = $prox,
                    delay = $delay
                WHERE f=$f AND g=$g;
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
    #  * nbrel
    #  * civg
    #  * civrel
    #  * concerns
    #  * sat
    #  * frcg
    #  * frcrel
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

        # NEXT, cache the satisfaction and cooperation curve ID 
        # dictionaries.  (These are updated on civgroup split.)
        set db(scid) [dict create]

        $rdb eval {
            SELECT g,c,curve_id FROM gram_gc
        } {
            dict set db(scid) $g $c $curve_id
        }

        # NEXT, cache the FRC/FRC relationships in a dictionary.
        $rdb eval {
            SELECT f,g,rel FROM gram_frc_fg
        } {
            dict set db(frel.gf) $g $f $rel
        }
        
    }
    
    # Method: SanityCheck
    #
    # Verifies that <LoadData> has loaded everything we need to run.
    #
    # This routine simply checks that we've got the right number of
    # entries in the multi-key tables.  To verify that the key
    # fields are valid, enable foreign keys when creating the
    # database handle.

    method SanityCheck {} {
        set N(n)       [$rdb eval {SELECT count(n) FROM gram_n}]
        set N(g)       [$rdb eval {SELECT count(g) FROM gram_g}]
        set N(frc_g)   [$rdb eval {SELECT count(g) FROM gram_frc_g}]
        set N(c)       [$rdb eval {SELECT count(c) FROM gram_c}]
        set N(mn)      [$rdb eval {SELECT count(mn_id) FROM gram_mn}]
        set N(gc)      [$rdb eval {SELECT count(gc_id) FROM gram_gc}]
        set N(fg)      [$rdb eval {SELECT count(fg_id) FROM gram_fg}]
        set N(frc_fg)  [$rdb eval {SELECT count(fg_id) FROM gram_frc_fg}]
        set N(coop_fg) [$rdb eval {SELECT count(fg_id) FROM gram_coop_fg}]

        require {$N(n) > 0}             "too few entries in gram_n"
        require {$N(g) > 0}             "too few entries in gram_g"
        require {$N(frc_g) > 0}         "too few entries in gram_frc_g"
        require {$N(c) > 0}             "too few entries in gram_c"
        require {$N(mn) == $N(n)*$N(n)} "too few entries in gram_mn"
        require {$N(gc) == $N(g)*$N(c)} "too few entries in gram_gc"
        require {$N(fg) == $N(g)*$N(g)} "too few entries in gram_fg"
        require {$N(frc_fg) == $N(frc_g)*$N(frc_g)} \
            "too few entries in gram_frc_fg"
        require {$N(coop_fg) == $N(g)*$N(frc_g)} \
            "too few entries in gram_coop_fg"
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
            ORDER BY g_id
        }]

        set cgroups [snit::enum ${selfns}::cgroups -values $values]

        # FRC Groups
        set values [$rdb eval {
            SELECT g FROM gram_frc_g 
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
    # should be pre-sorted.  Pre-populations <gram_mn>.
    #
    # Syntax:
    #   load nbhoods _name ?name...?_
    #
    #   name - A neighborhood name.

    method "load nbhoods" {args} {
        assert {$db(loadstate) eq "begin"}
        
        # FIRST, load the nbhood names.
        foreach n $args {
            $rdb eval {
                INSERT INTO gram_n(n)
                VALUES($n);
            }
        }

        set db(loadstate) "nbhoods"
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
        assert {$db(loadstate) eq "nbhoods"}

        foreach {m n proximity effects_delay} $args {
            set proximity [eproximity index $proximity]

            assert {
                ($m eq $n && $proximity == 0) ||
                ($m ne $n && $proximity != 0)
            }

            $rdb eval {
                INSERT INTO gram_mn(m, n, proximity, effects_delay)
                VALUES($m, $n, $proximity, $effects_delay)
            }
        }

        set db(loadstate) "nbrel"
    }

    # Method: load civg
    #
    # Loads the CIV group names into <gram_g>. Typically, the groups are
    # ordered by name.  Pre-populates <gram_fg> with defaults.
    #
    # Syntax:
    #   load civg _g n population ?...?_
    #
    #   g              - Group name
    #   n              - Nbhood of residence
    #   population     - Population

    method "load civg" {args} {
        assert {$db(loadstate) eq "nbrel"}

        # FIRST, load the civ group definitions.
        foreach {g n population} $args {
            $rdb eval {
                INSERT INTO gram_g(g,n,ancestor,population)
                VALUES($g,$n,$g,$population);
            }
        }

        set db(loadstate) "civg"
    }

    # Method: load civrel
    #
    # Loads non-default civilian group relationships into <gram_fg>. 
    #
    # Syntax:
    #   load civrel _f g rel ?...?_
    #
    #   f   - Group name
    #   g   - Group name
    #   rel - Group relationship

    method "load civrel" {args} {
        assert {$db(loadstate) eq "civg"}

        foreach {f g rel} $args {
            $rdb eval {
                INSERT INTO gram_fg(f, g, rel)
                VALUES($f,$g,$rel)
            }
        }

        set db(loadstate) "civrel"
    }

    # Method: load concerns
    #
    # Loads the concern names into <gram_c>.
    #
    # Syntax:
    #   load concerns _name ?name...?_
    #
    #   name  - Concern name

    method "load concerns" {args} {
        assert {$db(loadstate) eq "civrel"}

        foreach c $args {
            $rdb eval {
                INSERT INTO gram_c(c)
                VALUES($c);
            }
        }

        set db(loadstate) "concerns"
    }

    # Method: load sat
    #
    # Loads the non-default satisfaction curve data into <gram_curves> and
    # <gram_gc>.
    #
    # Syntax:
    #   load sat _g c sat0 saliency ?...?_
    #
    #   g        - Group name
    #   c        - Concern name
    #   sat0     - Initial satisfaction level
    #   saliency - Saliency

    method {load sat} {args} {
        assert {$db(loadstate) eq "concerns"}

        array set gids [$rdb eval {SELECT g, g_id FROM gram_g}]

        foreach {g c sat0 saliency} $args {
            set g_id $gids($g)

            $rdb eval {
                INSERT INTO gram_curves(curve_type, val0, val)
                VALUES('SAT', $sat0, $sat0);

                INSERT INTO gram_gc(g_id, curve_id, g, c, saliency)
                VALUES($g_id, last_insert_rowid(), $g, $c, $saliency);
            }
        }

        # NEXT, get the total_saliency for each group
        $rdb eval {
            SELECT g,
                   total(saliency) AS saliency
            FROM gram_gc
            GROUP BY g
        } {
            $rdb eval {
                UPDATE gram_g
                SET total_saliency=$saliency
                WHERE g=$g
            }
        }

        set db(loadstate) "sat"
    }

    # Method: load frcg
    #
    # Loads the group names into <gram_frc_g>. Typically, the groups are
    # ordered by name.
    #
    # Syntax:
    #   load frcg _name ?name...?_
    #
    #   name  - Group name

    method "load frcg" {args} {
        assert {$db(loadstate) eq "sat"}

        # FIRST, load the force group definitions.
        foreach g $args {
            $rdb eval {
                INSERT INTO gram_frc_g(g)
                VALUES($g);
            }
        }

        # NEXT, populate gram_frc_ng.
        $rdb eval {
            INSERT INTO gram_frc_ng(
                n,
                g)
            SELECT n, g
            FROM gram_n JOIN gram_frc_g
            ORDER BY n, g
        }

        set db(loadstate) "frcg"
    }

    # Method: load frcrel
    #
    # Loads non-default force group relationships into <gram_frc_fg>.
    #
    # Syntax:
    #   load frcrel _f g rel ?...?_
    #
    #   f   - Group name
    #   g   - Group name
    #   rel - Group relationship

    method "load frcrel" {args} {
        assert {$db(loadstate) eq "frcg"}

        foreach {f g rel} $args {
            $rdb eval {
                INSERT INTO gram_frc_fg(f, g, rel)
                VALUES($f,$g,$rel)
            }
        }

        set db(loadstate) "frcrel"
    }

    # Method: load coop
    #
    # Loads non-default cooperation levels into <gram_curves>.
    #
    # Syntax:
    #   load coop _f g coop0 ?...?_
    #
    #   f     - Force group name
    #   g     - Civ group name
    #   coop0 - Initial cooperation level

    method {load coop} {args} {
        assert {$db(loadstate) eq "frcrel"}

        foreach {f g coop0} $args {
            $rdb eval {
                -- Note: curve_id is set automatically.
                INSERT INTO gram_curves(curve_type, val0, val)
                VALUES('COOP', $coop0, $coop0);

                INSERT INTO gram_coop_fg(curve_id,f,g)
                VALUES(last_insert_rowid(), $f, $g)
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
    # Updates <gram_g.population> for the specified groups.
    #
    # The change takes affect on the next time <advance>.
    #
    # NOTE: This routine updates <gram_g>; do not call it in the body
    # of a query on <gram_g>.
    #
    # Syntax:
    #   update population _ g population ?...?_
    #
    #   g          - A CIV group
    #   population - g's new population

    method "update population" {args} {
        foreach {g population} $args {
            $rdb eval {
                UPDATE gram_g
                SET population = $population
                WHERE g=$g
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

        # NEXT, "kill" any dead groups
        foreach g [$rdb eval {
            SELECT g 
            FROM gram_g
            WHERE population = 0 
            AND   alive = 1
        }] {
            # Mark the group dead.
            $rdb eval {
                UPDATE gram_g 
                SET alive = 0
                WHERE g = $g;
            }

            # NEXT, terminate all active effects on this group.
            $self TerminateGroupEffects $g
        }

        # NEXT, Compute the contribution to each of the curves for
        # this time step.
        $self UpdateCurves

        # NEXT, Compute all roll-ups
        $self ComputeSatRollups
        $self ComputeCoopRollups

        # NEXT, Save the group population history
        $self SaveGroupHistory

        return
    }

    # Method: SaveGroupHistory
    #
    # Saves the neighborhood, population, and alive flag for each
    # civilian group.

    method SaveGroupHistory {} {
        # FIRST, skip the history data, if that's what we want to do
        set pname gram.saveHistory

        if {![$parm get $pname]} {
            return
        }

        # NEXT, save the data.
        $rdb eval {
            INSERT INTO gram_hist_g
            SELECT $db(time), g, n, alive, population
            FROM gram_g;
        }
    }


    #-------------------------------------------------------------------
    # Group: Satisfaction Roll-ups
    #
    # All satisfaction roll-ups -- sat.n, sat.g, sat.nc, sat.g, sat.c
    # -- all have the same nature.  The computation is a weighted average
    # over a set of satisfaction levels; all that changes is the definition
    # of the set.  The equation for a roll-up over set A is as follows:
    #
    # >        Sum          w  * L   * S
    # >           g,c in A   g    gc    gc
    # >  S  =  --------------------------------
    # >   A    Sum          w  * L   
    # >           g,c in A   g    gc

    # Method: ComputeSatRollups
    #
    # Computes all satisfaction roll-ups.

    method ComputeSatRollups {} {
        $self ComputeSatN
        $self ComputeSatG
    }


    # Method: ComputeSatN
    #
    # Computes the overall civilian mood for each nbhood at time t.
    # The mood is 0.0 if the population of the neighborhood is 0.0.
    
    method ComputeSatN {} {
        $rdb eval {
            SELECT n            AS n,
                   total(num)   AS num,
                   total(denom) AS denom
            FROM (
                SELECT gram_sat.n                          AS n, 
                       gram_sat.sat*saliency*population    AS num,
                       saliency*population                 AS denom
                FROM gram_sat JOIN gram_g USING (g_id))
            GROUP BY n
        } {
            if {$denom == 0.0} {
                let sat 0.0
            } else {
                let sat {$num/$denom}
            }

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
                       gram_sat.sat*saliency               AS num,
                       saliency                            AS denom
                FROM gram_sat JOIN gram_g USING (g_id))
            GROUP BY g
        } {
            $rdb eval {
                UPDATE gram_g
                SET sat = $sat
                WHERE g=$g
            }
        }
    }

    #-------------------------------------------------------------------
    # Group: Cooperation Roll-ups
    #
    # We only compute one cooperation roll-up, coop.ng: the cooperation
    # of a neighborhood as a whole with a force group.  This is based
    # on the population of the neighborhood groups, rather than
    # saliency; cooperation is the likelihood that
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
    # Computes coop.ng; if neighborhood n has zero population, 
    # the result is 0.0.

    method ComputeCoopRollups {} {
        # FIRST, compute coop.ng
        $rdb eval {
            SELECT gram_coop.n                                AS n, 
                   gram_coop.f                                AS f, 
                   gram_coop.g                                AS g,
                   total(gram_coop.coop * gram_g.population)  AS num,
                   total(gram_g.population)                   AS denom
            FROM gram_coop
            JOIN gram_g ON  gram_coop.n = gram_g.n
                        AND gram_coop.f = gram_g.g
            GROUP BY gram_coop.n, gram_coop.g
        } {
            if {$denom == 0} {
                let coop 0.0
            } else {
                let coop {$num/$denom}
            }

            $rdb eval {
                UPDATE gram_frc_ng
                SET coop = $coop
                WHERE n=$n AND g=$g
            }
        }
    }

    #-------------------------------------------------------------------
    # Group: Dynamic CIV Group API
    #
    # In this version of GRAM, civilian groups become considerably more
    # dynamic.  Existing groups can be moved, new groups can be split
    # out of old groups, and so forth.

    # Method: civgroup names
    #
    # Returns a list of civ groups.  If _n_ is given,
    # only groups from the specified neighborhood are returned.
    #
    # Syntax:
    #   civgroup names _?n?_
    #
    #   n - A neighborhood

    method "civgroup names" {{n ""}} {
        if {$n eq ""} {
            return [$rdb eval {
                SELECT g FROM gram_g
            }]
        } else {
            return [$rdb eval {
                SELECT g FROM gram_g WHERE n=$n
            }]
        }
    }

    # Method: civgroup alive
    #
    # Returns a list of civ groups that are alive.  If _n_ is given,
    # only groups from the specified neighborhood are returned.
    #
    # Syntax:
    #   civgroup alive _?n?_
    #
    #   n - A neighborhood

    method "civgroup alive" {{n ""}} {
        if {$n eq ""} {
            return [$rdb eval {
                SELECT g FROM gram_g WHERE alive=1
            }]
        } else {
            return [$rdb eval {
                SELECT g FROM gram_g WHERE alive=1 AND n=$n
            }]
        }
    }

    # Method: civgroup dead
    #
    # Returns a list of dead civ groups.  If _n_ is given,
    # only groups from the specified neighborhood are returned.
    #
    # Syntax:
    #   civgroup dead _?n?_
    #
    #   n - A neighborhood

    method "civgroup dead" {{n ""}} {
        if {$n eq ""} {
            return [$rdb eval {
                SELECT g FROM gram_g WHERE alive=0
            }]
        } else {
            return [$rdb eval {
                SELECT g FROM gram_g WHERE alive=0 AND n=$n
            }]
        }
    }

    # Method: civgroup get
    #
    # Returns a dictionary of the group's data (the gram_g fields).
    # If a particular field is named, returns that field's value.
    #
    # Syntax:
    #    group get _g ?field?_
    #
    #    g      - A group name
    #    field  - A column name in the gram_g table
   
    method "civgroup get" {g {field ""}} {
        $rdb eval {
            SELECT * FROM gram_g WHERE g=$g
        } row {
            unset row(*)

            if {$field eq ""} {
                return [array get row]
            }

            if {[info exists row($field)]} {
                return $row($field)
            }

            error "unknown group field, \"$field\""
        }

        return ""
    }

    # Method: civgroup move
    #
    # Moves a civilian group to a different neighborhood.  Recomputes
    # group proximities; terminates all pending attitude effects.
    # It's up to the application to apply any relevant drivers.
    #
    # Syntax:
    #    civgroup move _g n_
    #
    #    g     The group to move
    #    n     The neighborhood to move it to.

    method "civgroup move" {g n} {
        $self Log normal "civgroup move g=$g n=$n"

        # FIRST, validate the inputs.
        $cgroups validate $g
        $nbhoods validate $n

        # NEXT, reset the group's neighborhood.
        $rdb eval {
            UPDATE gram_g
            SET    n = $n
            WHERE  g = $g
        }

        # NEXT, terminate all active effects on this group.
        $self TerminateGroupEffects $g

        # NEXT, recompute the group's proximity
        $self ComputeGroupProximity $g

        # NEXT, clear the satisfaction spread cache; it might
        # be invalid.
        set db(sstag) ""

        return
    }
    

    # Method: TerminateGroupEffects
    #
    # Deletes all gram_effects entries related to the given group.
    #
    # Syntax:
    #    TerminateGroupEffects _g_
    #
    #    g  - A CIV group

    method TerminateGroupEffects {g} {
        foreach id [$rdb eval {
            SELECT id FROM gram_sat_effects WHERE g=$g
            UNION
            SELECT id FROM gram_coop_effects WHERE f=$g
        }] {
            $rdb eval {
                DELETE FROM gram_effects
                WHERE id = $id
            }
        }
    }
    
    # Method: civgroup split
    #
    # Creates a new civilian group as a clone of an existing group,
    # putting it into a specific neighborhood and giving it some
    # portion of the original group's personnel.  The new group
    # will have the same attitudes and relationships as the parent
    # group.xs
    #
    # Syntax:
    #    civgroup split _parent g n population_
    #
    #    parent        The parent group
    #    g             The group to create
    #    n             Group g's initial neighborhood of residence
    #    population    Population to transfer from parent to g.

    method "civgroup split" {parent g n population} {
        $self Log normal "civgroup split parent=$parent g=$g n=$n population=$population"

        # FIRST, validate the inputs.
        $cgroups validate $parent
        array set pdata [$self civgroup get $parent]

        require {$g ni [$cgroups cget -values]} "group already exists: \"$g\""

        $nbhoods validate $n
        ipopulation validate $population

        require {$pdata(population) >= $population} \
            "parent group has insufficient population ($pdata(population) < $population)"

        # NEXT, create the new group's gram_g record.
        $rdb eval {
            INSERT INTO gram_g(g, n, population, parent, ancestor,
                               total_saliency, sat0, sat)
            VALUES($g, $n, $population, $parent, $pdata(ancestor),
                   $pdata(total_saliency), $pdata(sat0), $pdata(sat))
        }

        # NEXT, remove the population from the parent group.
        $rdb eval {
            UPDATE gram_g
            SET population = population - $population
            WHERE g=$parent
        }

        # NEXT, get the new group's g_id
        set g_id [$rdb last_insert_rowid]

        # NEXT, copy the parent's satisfactions.
        foreach {c sat sat0 saliency delta slope} [$rdb eval {
            SELECT c, sat, sat0, saliency, delta, slope
            FROM gram_sat
            WHERE g=$parent
            ORDER BY c
        }] {
            $rdb eval {
                -- Note: curve_id is set automatically
                INSERT INTO gram_curves(curve_type, val0, val, delta, slope)
                VALUES('SAT', $sat0, $sat, $delta, $slope);

                -- Note: gc_id is set automatically
                INSERT INTO 
                gram_gc(g_id, curve_id, g, c, saliency)
                VALUES($g_id, last_insert_rowid(), $g, $c, $saliency);
            }
        }


        # NEXT, copy the parent's cooperations.
        foreach {frc coop coop0 delta slope} [$rdb eval {
            SELECT g, coop, coop0, delta, slope
            FROM gram_coop
            WHERE f=$parent
            ORDER BY g
        }] {
            $rdb eval {
                -- Note: curve_id is set automatically.
                INSERT INTO gram_curves(curve_type, val0, val, delta, slope)
                VALUES('COOP', $coop0, $coop, $delta, $slope);

                INSERT INTO gram_coop_fg(curve_id,f,g)
                VALUES(last_insert_rowid(), $g, $frc)
            }
        }

        # NEXT, cache the new curve IDs.
        $rdb eval {
            SELECT c,curve_id FROM gram_gc
            WHERE g=$g
        } {
            dict set db(scid) $g $c $curve_id
        }

        # NEXT, copy the parent's relationships.
        $rdb eval {
            INSERT INTO gram_fg(f,g,rel)
            SELECT f AS f, $g AS g, rel
            FROM gram_fg WHERE g=$parent
            UNION
            SELECT $g AS f, g AS g, rel
            FROM gram_fg WHERE f=$parent
            UNION
            SELECT $g AS f, $g AS g, rel
            FROM gram_fg WHERE f=$parent AND g=$parent
        }

        # NEXT, compute g's proximity
        $self ComputeGroupProximity $g

        # NEXT, re-create the validators, so that the new
        # group is present in $cgroups.
        $self CreateValidators

        return
    }

    # Method: civgroup transfer
    #
    # Transfers population from one civ group to another, and updates
    # the second group's attitudes according to the mixture of old and
    # new population.
    #
    # Syntax:
    #    civgroup transfer _driver e f population_
    #
    #    driver        The driver of the change
    #    e             The source group
    #    f             The destination group
    #    population    Population to transfer from e to f

    method "civgroup transfer" {driver e f population} {
        $self Log normal "civgroup transfer driver=$driver e=$e f=$f population=$population"

        # FIRST, validate the inputs.
        $self driver validate $driver "Cannot transfer population"
        $cgroups validate $e
        $cgroups validate $f

        array set edata [$self civgroup get $e]
        array set fdata [$self civgroup get $f]

        require {$edata(ancestor) eq $fdata(ancestor)} \
            "Groups $e and $f have different ancestors."

        ipopulation validate $population

        require {$edata(population) >= $population} \
            "group \"$e\"has insufficient population ($edata(population) < $population)"

        # NEXT, update the population values for each group.
        $rdb eval {
            -- e loses population.
            UPDATE gram_g 
            SET   population = population - $population
            WHERE g=$e;

            UPDATE gram_g 
            SET   population = population + $population
            WHERE g=$f;

            UPDATE gram_g
            SET    alive = 1
            WHERE  g=$f AND population > 0;
        }

        # NEXT, update the satisfactions
        set epop $edata(population)
        set fpop $fdata(population)

        foreach {esat fsat c} [$rdb eval {
            SELECT ESAT.sat AS esat,
                   FSAT.sat AS fsat,
                   FSAT.c   AS c
            FROM gram_sat AS ESAT
            JOIN gram_sat AS FSAT USING (c)
            WHERE ESAT.g = $e
            AND   FSAT.g = $f
        }] {
            if {$epop == 0 && $fpop == 0} {
                let sat 0.0
            } else {
                let sat {($epop*$esat + $fpop*$fsat)/($epop + $fpop)}
            }

            $self sat set $driver $f $c $sat
        }

        # NEXT, update the cooperations

        foreach {ecoop fcoop g} [$rdb eval {
            SELECT ECOOP.coop AS ecoop,
                   FCOOP.coop AS fcoop,
                   FCOOP.g    AS g
            FROM gram_coop AS ECOOP
            JOIN gram_coop AS FCOOP USING (g)
            WHERE ECOOP.f = $e
            AND   FCOOP.f = $f
        }] {
            if {$epop == 0 && $fpop == 0} {
                let coop 0.0
            } else {
                let coop {($epop*$ecoop + $fpop*$fcoop)/($epop + $fpop)}
            }

            $self coop set $driver $f $g $coop
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
    # Adjusts sat.gc by the required amount, clamping it within bounds.
    #
    # Returns the input ID for this _driver_.  
    #
    # Syntax:
    #   sat adjust _driver g c mag_
    #
    #   driver - The driver ID
    #   g      - Group name, or "*" for all.
    #   c      - Concern name, or "*" for all.
    #   mag    - Magnitude (a qmag value)

    method "sat adjust" {driver g c mag} {
        $self Log detail "sat adjust driver=$driver g=$g c=$c M=$mag"

        # FIRST, check the inputs, and accumulate query terms
        set where [list]

        # driver
        $self driver validate $driver "Cannot sat adjust"

        set conds [list]

        # g
        if {$g ne "*"} {
            $cgroups validate $g
            require {$g in [$self civgroup alive]} "Group is dead: \"$g\""

            lappend conds "g = \$g "
        }

        # c
        if {$c ne "*"} {
            $concerns validate $c
            lappend conds "c = \$c "
        }

        # qmag
        qmag validate $mag
        set mag [qmag value $mag]

        # NEXT, if the magnitude is zero, there's nothing to do.
        if {$mag == 0.0} {
            return
        }

        # NEXT, do the query.
        if {[llength $conds] > 0} {
            set where "AND [join $conds { AND }]"
        } else {
            set where ""
        }

        foreach curve_id [$rdb eval "
            SELECT curve_id
            FROM gram_gc
            JOIN gram_g USING (g)
            WHERE gram_g.alive
            $where
        "] {
            $self AdjustCurve $driver $curve_id $mag
        }

        # NEXT, recompute other outputs that depend on sat.gc
        $self ComputeSatRollups

        return [$self DriverGetInput $driver]
    }

    # Method: sat set
    #
    # Sets sat.gc to the required value.
    #
    # Returns the input ID for this driver.  
    #
    #
    # Syntax:
    #   sat set _driver g c sat_ ?-undo?
    #
    #   driver - The driver ID
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

    method "sat set" {driver g c sat {flag ""}} {
        $self Log detail "sat set driver=$driver g=$g c=$c S=$sat $flag"

        # FIRST, check the inputs, and accumulate query terms
        set where ""

        # driver
        $self driver validate $driver "Cannot sat set"

        # g
        if {$g ne "*"} {
            $cgroups validate $g
            require {$g in [$self civgroup alive]} "Group is dead: \"$g\""

            append where "AND g = \$g "
        }

        # c
        if {$c ne "*"} {
            $concerns validate $c
            append where "AND c = \$c "
        }

        # qsat
        qsat validate $sat
        set sat [qsat value $sat]

        # NEXT, do the query.
        foreach {curve_id mag} [$rdb eval "
            SELECT curve_id, \$sat - sat AS mag
            FROM gram_sat
            WHERE alive
            AND   mag != 0.0
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
    # Returns the driver input number for this input.  This is
    # a number that starts at 1 and is incremented for each level or slope
    # input received for the driver.
    #
    # Syntax:
    #   sat level _driver ts g c limit days ?options?_
    #
    #   driver - driver ID
    #   ts     - Start time, integer ticks
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
    #   -allowdead          - If given, f can be a dead group; indirect
    #                         effects will be created normally.

    method "sat level" {driver ts g c limit days args} {
        $self Log detail "sat level driver=$driver ts=$ts g=$g c=$c lim=$limit days=$days $args"

        # FIRST, check the regular inputs
        $self driver validate $driver "Cannot sat level"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        $cgroups  validate $g
        $concerns validate $c

        qmag      validate $limit
        qduration validate $days

        # NEXT, validate the options
        $self ParseInputOptions sat opts $args

        # NEXT, make sure g is a living group
        if {!$opts(-allowdead)} {
            require {$g in [$self civgroup alive]} \
                "Group is dead: \"$g\""
        }

        # NEXT, normalize the input data.

        set input(driver)    $driver
        set input(input)     [$self DriverGetInput $driver]
        set input(dg)        $g
        set input(c)         $c
        set input(direct_id) [dict get $db(scid) $g $c]
        set input(ts)        $ts
        set input(days)      [qduration value $days]
        set input(llimit)    [qmag      value $limit]
        set input(athresh)   $opts(-athresh)
        set input(dthresh)   $opts(-dthresh)

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

        # NEXT, compute the spread
        set spread [$self SatSpread $input(dg) $opts(-s) $opts(-p) $opts(-q)]

        # NEXT, schedule the effects in the spread.
        set epsilon [$parm get gram.epsilon]

        dict for {g list} $spread {
            lassign $list factor effect(delay) effect(prox)

            set effect(llimit) [expr {$input(llimit)*$factor}]
            set effect(curve_id) [dict get $db(scid) $g $c]
            
            $self ScheduleLevel input effect $epsilon
        }

        return $input(input)
    }

    # Method: SatSpread 
    #
    # Computes and returns a satisfaction spread, caching the spread
    # for later use.
    #
    # The spread is a dictionary: group -> [list factor delay prox].
    #
    # Syntax:
    #    SatSpread _dg s p q_
    #
    #    g          - The directly affected group
    #    s          - The -s "here factor"
    #    p          - The -p "near factor"
    #    q          - The -q "far factor".
    
    method SatSpread {g s p q} {
        # FIRST, if this spread is cached, return the cached value.
        if {$db(sstag) eq "$g,$s,$p,$q"} {
            return $db(ssvalue)
        }

        # FIRST, get the proximity limit
        set plimit [$self GetProxLimit $s $p $q]
        
        # NEXT, create the empty dictionary
        set spread [dict create]

        $rdb eval {
            SELECT f, rel, delay, prox
            FROM gram_fg
            JOIN gram_g ON (gram_g.g = gram_fg.f)
            WHERE gram_fg.g = $g
            AND   prox < $plimit
            AND   gram_g.alive
        } {
            # FIRST, apply the here, near, and far factors.
            if {$prox == 2} {
                # Far
                set factor [expr {$q * $rel}]
            } elseif {$prox == 1} {
                # Near
                set factor [expr {$p * $rel}]
            } elseif {$prox == 0} {
                # Here
                set factor [expr {$s * $rel}]
            } else {
                set factor $rel
            }

            # NEXT, save the data for this group.
            if {$factor != 0.0} {
                dict set spread $f [list $factor $delay $prox]
            }
        }

        # NEXT, cache this spread
        set db(sstag) $g,$s,$p,$q
        set db(ssvalue) $spread

        # NEXT, return the spread
        return $spread
    }

    # Method: sat slope
    #
    # Schedules a new GRAM slope input with the specified parameters.
    #
    # * A subsequent input for the same driver, g, c, and cause will update
    #   all direct and indirect effects accordingly.
    # * Such subsequent inputs must have a start time, ts,
    #   no earlier than the ts of the previous input.
    #
    # Returns the driver input number for this input.  This is
    # a number that starts at 1 and is incremented for each level or slope
    # input received for the driver.
    #
    # Syntax:
    #   sat slope _driver ts g c slope ?options...?_
    #
    #   driver - Driver ID
    #   ts     - Input start time, integer ticks
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
    #   -allowdead          - If given, f can be a dead group; indirect
    #                         effects will be created normally.

    method "sat slope" {driver ts g c slope args} {
        $self Log detail \
            "sat slope driver=$driver ts=$ts g=$g c=$c s=$slope $args"

        # FIRST, validate the regular inputs
        $self driver validate $driver "Cannot sat slope"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        $cgroups  validate $g
        $concerns validate $c

        qmag validate $slope

        # NEXT, validate the options
        $self ParseInputOptions sat opts $args

        # NEXT, make sure g is a living group
        if {!$opts(-allowdead)} {
            require {$g in [$self civgroup alive]} \
                "Group is dead: \"$g\""
        }

        # NEXT, normalize the input data
        set input(driver)    $driver
        set input(input)     [$self DriverGetInput $driver]
        set input(dg)        $g
        set input(c)         $c
        set input(direct_id) [dict get $db(scid) $g $c]
        set input(slope)     [qmag value $slope]
        set input(ts)        $ts
        set input(athresh)   $opts(-athresh)
        set input(dthresh)   $opts(-dthresh)

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
                FROM gram_gc     AS direct
                JOIN gram_effects AS effect 
                     ON effect.direct_id = direct.gc_id
                WHERE direct.g      = $input(dg) 
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
        set plimit [$self GetProxLimit $opts(-s) $opts(-p) $opts(-q)]

        # NEXT, terminate existing slope chains which are outside
        # the de facto proximity limit.
        $rdb eval {
            SELECT id, ts, te, cause, delay, future 
            FROM gram_gc     AS direct
            JOIN gram_effects AS effect 
                 ON effect.direct_id = direct.gc_id
            WHERE direct.g      =  $input(dg) 
            AND   direct.c      =  $input(c)
            AND   effect.etype  =  'S'
            AND   effect.driver =  $input(driver)
            AND   effect.cause  = $input(cause)
            AND   effect.prox   >= $plimit
        } row {
            $self TerminateSlope input row
        }

        # NEXT, compute the spread
        set spread [$self SatSpread $input(dg) $opts(-s) $opts(-p) $opts(-q)]

        dict for {g list} $spread {
            lassign $list factor effect(delay) effect(prox)

            set effect(slope) [expr {$input(slope)*$factor}]
            set effect(curve_id) [dict get $db(scid) $g $c]
            
            $self ScheduleSlope input effect $epsilon
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
            -s            1.0
            -p            0.0
            -q            0.0
            -athresh    100.0
            -dthresh   -100.0
            -allowdead      0
        }
        
        if {$ctype eq "coop"} {
            set opts(-dthresh) 0.0
        }

        # NEXT, get the values.
        while {[llength $optsList] > 0} {
            set opt [lshift optsList]

            switch -exact -- $opt {
                -cause {
                    set opts($opt) [lshift optsList]
                }
                -s -
                -p -
                -q {
                    set val [lshift optsList]
                    rfraction validate $val
                        
                    set opts($opt) $val
                }
                
                -athresh -
                -dthresh {
                    set val [lshift optsList]
                    if {$ctype eq "sat"} {
                        set opts($opt) [qsat validate $val]
                    } else {
                        set opts($opt) [qcooperation validate $val]
                    }
                }

                -allowdead {
                    set opts($opt) 1
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
            $cgroups validate $opts(-group)
            lappend condList {g = $opts(-group)}
        }

        if {$opts(-concern) ni {"*" "mood"}} {
            $concerns validate $opts(-concern)
            lappend condList {c = $opts(-concern)}
        }

        if {$opts(-concern) ni {"*" "mood"}} {
            $concerns validate $opts(-concern)
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
            JOIN gram_gc USING (g,c)
            JOIN gram_g  USING (g)
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
    # Adjusts coop.fg by the required amount, clamping it within bounds.
    #
    # Returns the input ID for this driver.  
    #
    # Syntax:
    #   coop adjust _driver f g mag_
    #
    #   driver - The driver ID
    #   f      - Civilian group name, or "*" for all.
    #   g      - Force group name, or "*" for all.
    #   mag    - Magnitude (a qmag value)

    method "coop adjust" {driver f g mag} {
        $self Log detail "coop adjust driver=$driver f=$f g=$g M=$mag"

        # FIRST, check the inputs, and accumulate query terms
        set where [list]

        # driver
        $self driver validate $driver "Cannot coop adjust"

        # f
        if {$f ne "*"} {
            $cgroups validate $f
            require {$f in [$self civgroup alive]} "Group is dead: \"$f\""
            lappend where "f = \$f "
        }

        # g
        if {$g ne "*"} {
            $fgroups validate $g
            lappend where "g = \$g "
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
            set where "AND [join $where { AND }]"
        } else {
            set where ""
        }

        foreach curve_id [$rdb eval "
            SELECT curve_id
            FROM gram_coop
            WHERE alive
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
    # Sets coop.fg to the required amount. Returns the input ID for this
    # driver. 
    #
    # Syntax:
    #   coop set _driver f g coop_ ?-undo?
    #
    #   driver - The driver ID
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

    method "coop set" {driver f g coop {flag ""}} {
        $self Log detail "coop set driver=$driver f=$f g=$g C=$coop $flag"

        # FIRST, check the inputs, and accumulate query terms
        set where ""

        # driver
        $self driver validate $driver "Cannot coop set"

        # f
        if {$f ne "*"} {
            $cgroups validate $f
            require {$f in [$self civgroup alive]} "Group is dead: \"$f\""
            append where "AND f = \$f "
        }

        # g
        if {$g ne "*"} {
            $fgroups validate $g
            append where "AND g = \$g "
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
            WHERE alive
            AND   mag != 0.0
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
    #   coop level _driver ts f g limit days ?options?_
    #
    #   driver - Driver ID
    #   ts     - Start time, integer ticks
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
    #   -allowdead          - If given, f can be a dead group; indirect
    #                         effects will be created normally.

    method "coop level" {driver ts f g limit days args} {
        $self Log detail "coop level driver=$driver ts=$ts f=$f g=$g lim=$limit days=$days $args"

        # FIRST, check the regular inputs
        $self driver validate $driver "Cannot coop level"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        $cgroups validate $f
        $fgroups validate $g

        qmag      validate $limit
        qduration validate $days

        # NEXT, validate the options
        $self ParseInputOptions coop opts $args

        # NEXT, make sure f is a living group
        if {!$opts(-allowdead)} {
            require {$f in [$self civgroup alive]} \
                "Group is dead: \"$f\""
        }

        # NEXT, normalize the input data.
        set input(driver)    $driver
        set input(input)     [$self DriverGetInput $driver]
        set input(df)        $f
        set input(dg)        $g
        set input(ts)        $ts
        set input(days)      [qduration value $days]
        set input(llimit)    [qmag      value $limit]
        set input(s)         $opts(-s)
        set input(p)         $opts(-p)
        set input(q)         $opts(-q)
        set input(athresh)   $opts(-athresh)
        set input(dthresh)   $opts(-dthresh)

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

        # Get the cooperation relationship limit
        set CRL [$parm get gram.coopRelationshipLimit]

        # Schedule the effects
        $rdb eval {
            SELECT * FROM gram_coop_influence
            WHERE df     =  $input(df)
            AND   dg     =  $input(dg)
            AND   prox   <  $plimit
            AND   civrel >= $CRL
        } effect {
            set input(direct_id) $effect(direct_id)

            # FIRST, apply the here, near, and far factors.
            if {$effect(prox) == 2} {
                # Far
                set factor [expr {$opts(-q) * $effect(factor)}]
            } elseif {$effect(prox) == 1} {
                # Near
                set factor [expr {$opts(-p) * $effect(factor)}]
            } elseif {$effect(prox) == 0} {
                # Here
                set factor [expr {$opts(-s) * $effect(factor)}]
            } else {
                set factor $effect(factor)
            }

            set effect(llimit) [expr {$factor * $input(llimit)}]

            if {$effect(llimit) == 0} {
                continue
            }

            $self ScheduleLevel input effect $epsilon
        }

        return $input(input)
    }

    # Method: coop slope
    #
    # Schedules a new GRAM slope input with the specified parameters.
    #
    # * A subsequent input for the same driver, f, g, and cause will update
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
    #   coop slope "driver ts f g slope ?options...?"
    #
    #   driver - Driver ID
    #   ts     - Start time, integer ticks
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
    #   -allowdead          - If given, f can be a dead group; indirect
    #                         effects will be created normally.

    method "coop slope" {driver ts f g slope args} {
        $self Log detail \
            "coop slope driver=$driver ts=$ts f=$f g=$g s=$slope $args"

        # FIRST, validate the regular inputs
        $self driver validate $driver "Cannot coop slope"

        require {[string is integer -strict $ts]} \
            "non-numeric ts: \"$ts\""

        if {$ts < $db(time)} {
            set zulu [$clock toZulu $ts]
            error "Start time is in the past: '$zulu'"
        }

        $cgroups validate $f
        $fgroups validate $g

        qmag validate $slope

        # NEXT, validate the options
        $self ParseInputOptions coop opts $args

        # NEXT, make sure f is a living group
        if {!$opts(-allowdead)} {
            require {$f in [$self civgroup alive]} \
                "Group is dead: \"$f\""
        }

        # NEXT, normalize the input data
        set input(driver)    $driver
        set input(input)     [$self DriverGetInput $driver]
        set input(df)        $f
        set input(dg)        $g
        set input(slope)     [qmag value $slope]
        set input(ts)        $ts
        set input(s)         $opts(-s)
        set input(p)         $opts(-p)
        set input(q)         $opts(-q)
        set input(athresh)   $opts(-athresh)
        set input(dthresh)   $opts(-dthresh)

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
                FROM gram_coop_fg     AS direct
                JOIN gram_effects AS effect 
                     ON effect.direct_id = direct.fg_id
                WHERE direct.f      = $input(df) 
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
            FROM gram_coop_fg     AS direct
            JOIN gram_effects AS effect 
                 ON effect.direct_id = direct.fg_id
            WHERE direct.f      =  $input(df) 
            AND   direct.g      =  $input(dg) 
            AND   effect.etype  =  'S'
            AND   effect.driver =  $input(driver)
            AND   effect.cause  =  $input(cause)
            AND   effect.prox   >= $plimit
        } effect {
            $self TerminateSlope input effect
        }

        # NEXT, schedule the effects in every influenced neighborhood
        # within the proximity limit.

        # Get the cooperation relationship limit
        set CRL [$parm get gram.coopRelationshipLimit]

        # Schedule the effects
        $rdb eval {
            SELECT * FROM gram_coop_influence
            WHERE df     =  $input(df)
            AND   dg     =  $input(dg)
            AND   prox   <  $plimit
            AND   civrel >= $CRL
        } effect {
            set input(direct_id) $effect(direct_id)

            # FIRST, apply the here, near, and far factors.
            if {$effect(prox) == 2} {
                # Far
                set factor [expr {$opts(-q) * $effect(factor)}]
            } elseif {$effect(prox) == 1} {
                # Near
                set factor [expr {$opts(-p) * $effect(factor)}]
            } elseif {$effect(prox) == 0} {
                # Here
                set factor [expr {$opts(-s) * $effect(factor)}]
            } else {
                set factor $effect(factor)
            }

            set effect(slope) [expr {$factor * $input(slope)}]

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
            DELETE FROM gram_hist_g;
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
            let realmag {$newVal - $val}

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
    #   driver    - Driver ID
    #   direct_id - ID of entity receiving the direct effect (the table
    #               depends on the curve type, satisfaction or cooperation).
    #   input     - Input number, for this driver
    #   cause     - "Cause" of this input
    #   ts        - Start time, in ticks
    #   days      - Realization time, in days
    #   llimit    - "level limit", the direct effect magnitude
    #   athresh   - Ascending threshold
    #   dthresh   - Descending threshold
    #
    # The _effectArray_ should contain the following values.
    #
    #   curve_id  - ID of affected curve in <gram_curves>.
    #   prox      - Proximity, -1 (direct), 0 (here), 1 (near), or 2 (far)
    #   llimit    - Effect magnitude
    #   delay     - Effects delay, in ticks

    method ScheduleLevel {inputArray effectArray epsilon} {
        upvar 1 $inputArray input
        upvar 1 $effectArray effect

        set llimit $effect(llimit)

        # NEXT, compute the start time, taking the effects 
        # delay into account.

        set ts [expr {$input(ts) + $effect(delay)}]

        # NEXT, Compute te and tau
        if {abs($llimit) <= $epsilon} {
            set te [expr {$ts + 1}]
            set tau 0.0
        } else {
            set te [expr {int($ts + [$clock fromDays $input(days)])}]

            if {$te == $ts} {
                set te [expr {$ts + 1}]
            }

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
                $input(direct_id),
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
    #   driver    - Driver ID
    #   direct_id - ID of entity receiving the direct effect (depends on
    #               curve type).
    #   input     - Input number, for this driver
    #   cause     - "Cause" of this input
    #   ts        - Start time, in ticks
    #   slope     - Slope, in nominal points/day
    #   athresh   - Ascending threshold
    #   dthresh   - Descending threshold
    #
    # The _effectArray_ should contain the following values.
    #
    #   curve_id  - ID of affected curve in gram_curves.
    #   prox      - Proximity, -1 (direct), 0 (here), 1 (near), or 2 (far)
    #   factor    - Influence multiplier
    #   delay     - Effects delay, in ticks

    method ScheduleSlope {inputArray effectArray epsilon} {
        upvar 1 $inputArray input
        upvar 1 $effectArray effect

        # FIRST, determine the real slope.
        set slope $effect(slope)

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
            AND direct_id=$input(direct_id)
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
                $input(direct_id),
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

                let deltaDays {double($db(time) - $row(ts))/1440.0}

                let valueNow {
                    $row(llimit) * (1.0 - exp(-$deltaDays/$row(tau)))
                }
            }

            let contrib {$valueNow - $row(nominal)}

            # NEXT, add the increment to this effect's nominal
            # contribution to date.
            let row(nominal) {$row(nominal) + $contrib}
            
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
                let poscontribs($curve_id,$cause) {$maxpos*$scale/$sumpos}
            }
            
            # NEXT, store the negative effects by id and cause
            if {$minneg < 0.0} {
                let negcontribs($curve_id,$cause) {$minneg*$scale/$sumneg}
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

    # Method: sat.gc
    #
    # Returns the requested satisfaction level.
    #
    # Syntax:
    #    sat.gc _g c_
    #
    #   g - A CIV group name
    #   c - A concern name

    method sat.gc {g c} {
        $cgroups validate $g
        $concerns validate $c

        set result [$rdb onecolumn {
            SELECT sat FROM gram_sat 
            WHERE g=$g AND c=$c
        }]

        if {$result eq ""} {
            # If the types of g and c don't match, this is
            # an error; otherwise, sat_tracked is 0, so return 0.0

            set result 0.0
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
    #   g - A CIV group name

    method sat.g {g} {
        $cgroups validate $g

        return [$rdb onecolumn {
            SELECT sat FROM gram_g 
            WHERE g=$g
        }]
    }
    
    # Method: coop.fg
    #
    # Returns the requested cooperation level.
    #
    # Syntax:
    #   coop.fg _f g_
    #
    #   f - A CIV group name
    #   g - A FRC group name

    method coop.fg {f g} {
        $cgroups validate $f
        $fgroups validate $g

        set result [$rdb onecolumn {
            SELECT coop FROM gram_coop 
            WHERE f=$f AND g=$g
        }]

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

    # Method: time
    #
    # Current gram(n) simulation time, in ticks.
    method time {} { 
        return $db(time) 
    }


    #-------------------------------------------------------------------
    # Group: Data dumping methods

    # Method: dump sat.gc
    #
    # Dumps a pretty-printed <gram_sat> table.
    #
    # Syntax:
    #   dump sat.gc _?options?_
    #
    # Options:
    #   -nbhood n  - Neighborhood name or *
    #   -group  g  - Group name or *

    method "dump sat.gc" {args} {
        # FIRST, set the defaults
        set conditions [list]
        set n       "*"
        set g       "*"

        # NEXT, get the options
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
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
            $cgroups validate $g
            require {$g in [$self civgroup alive]} "Group is dead: \"$g\""
        }

        # Nbhood
        if {$n ne "*"} {
            $nbhoods validate $n
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
                   gc_id,
                   curve_id
            FROM gram_sat
            -- JOIN gram_g  USING (g)
            WHERE alive
            [tif {$n ne "*"} {AND n='$n'}]
            [tif {$g ne "*"} {AND g='$g'}]
            ORDER BY n,g,c
        }]

        set labels {
            "Nbhood" "Group" "Con" "Sat" "Delta" "Sat0"
            "Slope" "GC ID" "Curve ID"
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

    # Method: dump coop.fg
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

    method "dump coop.fg" {args} {
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
            require {$f in [$self civgroup alive]} "Group is dead: \"$f\""
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
                   fg_id,
                   curve_id
            }]
            FROM gram_coop
            WHERE alive
            [tif {$n ne "*"} {AND n='$n'}]
            [tif {$f ne "*"} {AND f='$f'}]
            [tif {$g ne "*"} {AND g='$g'}]
            ORDER BY n, f, g
        }]

        set labels {
            "Nbhood" "CivGrp" "FrcGrp" "Coop" "Delta" "Coop0"
            "Slope"
        }

        if {$idflag} {
            lappend labels  "FG ID" "Curve ID"
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
    #   dump sat level _g c_
    #
    #   g - A group name
    #   c - A concern name

    method "dump sat level" {g c} {
        # FIRST, validate the inputs
        $cgroups  validate $g
        $concerns validate $c

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
            AND g='$g' AND c='$c'
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
    #   dump coop level _f g_
    #
    #   f - A CIV group name
    #   g - A FRC group name

    method "dump coop level" {f g} {
        # FIRST, validate the inputs
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
            AND f='$f' AND g='$g'
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
                f,
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
                   f,
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
                     n ASC, f ASC, g ASC, prox ASC, ts ASC, id ASC
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
                        f,
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
                        $row(f),
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
                   f,
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
    #   dump sat slope _g c_
    #
    #   g - A group name
    #   c - A concern name

    method "dump sat slope" {g c} {
        # FIRST, validate the inputs
        $cgroups  validate $g
        $concerns validate $c

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
            AND g='$g' AND c='$c'
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
    #   dump coop slope _f g_
    #
    #   f - A civ group name
    #   g - A frc group name

    method "dump coop slope" {f g} {
        # FIRST, validate the inputs
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
            AND f='$f' AND g='$g'
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
