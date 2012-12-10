#-----------------------------------------------------------------------
# FILE: mam.tcl
#
#   MAM: Mars Affinity Model Prototype
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
# NOTES:
#
# * For this package I'm trying out a new error handling scheme.  In
#   GRAM, I very much use a precondition-based strategy.  Validate all
#   of the inputs before doing anything, and make all error messages
#   highly detailed.  This approach led directly to trying to use
#   internal error messages as user error messages, which has proven
#   to be a mistake.  In newer code (e.g., Athena) all user input is
#   validated by orders before any actions are taken; the code in
#   which the actions are taken should produce errors for the developer.
#
#   Consequently, I'm going to try to catch all of the relevant input
#   errors; but I'm not going to worry about doing them all upfront,
#   and I'm not going to worry about end-user error messages.  In 
#   particular, I'm going to let SQLite check constraints, insofar
#   as that's possible.
#
#   This approach is based on allowing rollbacks in the RDB, 
#   e.g., -rollback on.
#
# * In addition, I'm trying to leverage SQLite's new foreign key
#   capabilities, and particularly cascading update and cascading
#   delete.  The foreign key references are all declared
#   DEFERRABLE INITIALLY DEFERRED so that the constraints are 
#   checked at the end of the transaction.
#
#-----------------------------------------------------------------------

namespace eval ::simlib:: {
    namespace export mam
}

#-----------------------------------------------------------------------
# mam Type
#
# MAM -- Mars Affinity Model Prototype
#
# Instances of the mam object type do the following.
#
#  * Bookkeep MAM inputs.
#  * Allow changes to MAM inputs to be undone.
#  * Recompute MAM outputs.
#  * Allow introspection of all inputs and outputs.

snit::type ::simlib::mam {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # FIRST, Import needed commands from other packages.
        namespace import ::marsutil::*
    }

    #-------------------------------------------------------------------
    # sqlsection(i) implementation
    #
    # The following routines implement the module's 
    # sqlsection(i) interface.

    # sqlsection title
    #
    # Returns a human-readable title for the section.

    typemethod {sqlsection title} {} {
        return "mam(n)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions, which are
    # read from mam.sql.

    typemethod {sqlsection schema} {} {
        return [readfile [file join $::simlib::library mam.sql]]
    }

    # sqlsection tempschema
    #
    # Returns the section's temporary schema definitions.

    typemethod {sqlsection tempschema} {} {
        return ""
    }

    # sqlsection functions
    #
    # Returns a dictionary of function names and command prefixes.

    typemethod {sqlsection functions} {} {
        return [list]
    }

    #-------------------------------------------------------------------
    # Type Variables
   
    # rdbTracker array
    #
    # Array, mam(n) instance by RDB. This array tracks which RDBs are
    # in use by mam instances; thus, if we create a new instance on an
    # RDB that's already in use by a MAM instance, we can throw an error.
    
    typevariable rdbTracker -array { }

    #-------------------------------------------------------------------
    # Options

    # Option: -rdb
    #
    # The name of the sqldocument(n) instance in which
    # mam(n) will store its working data.  After creation, the
    # value will be stored in the rdb component.
    option -rdb -readonly 1

    # Option: -undo
    #
    # A boolean flag, defaulting to "on".  If on, undo information
    # is saved and the "edit undo" command is available.  If
    # off, no undo information is saved.

    option -undo \
        -type            snit::boolean \
        -default         on            \
        -configuremethod ConfigUndo

    method ConfigUndo {opt val} {
        # FIRST, save the option value
        set options($opt) $val

        # NEXT, if -undo is off, clear the undo stack.
        if {!$val} {
            $self edit reset
        }
    }

    #-------------------------------------------------------------------
    # Components
    #
    # Each instance of mam(n) uses the following components.

    component rdb     ;# sqldocument(n), for structured data.
    
    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the creation arguments.
        $self configurelist $args

        # NEXT, save the RDB component, verifying that no other instance
        # of MAM is using it.
        set rdb $options(-rdb)
        assert {[info commands $rdb] ne ""}

        require {$type in [$rdb sections]} \
            "mam(n) is not registered with database $rdb"
        
        if {[info exists rdbTracker($rdb)]} {
            return -code error \
                "RDB $rdb already in use by MAM $rdbTracker($rdb)"
        }
        
        set rdbTracker($rdb) $self

        # NEXT, create the mam_playbox entry
        $rdb eval {
            INSERT INTO mam_playbox(pid) VALUES(1);
        }
    }
    
    # destructor
    #
    # Removes the instance's rdb from the rdbTracker, and deletes
    # the instance's content from the relevant rdb tables.

    destructor {
        catch {
            unset -nocomplain rdbTracker($rdb)
            $self ClearTables destroy
            
        }
    }

    #-------------------------------------------------------------------
    # Playbox Data Methods

    # playbox cget option
    #
    # option  - The name of a playbox option.  See [playbox configure].
    #
    # Retrieves the value of a playbox option.

    method {playbox cget} {option} {
        $self DbCget mam_playbox 1 $option
    }
    
    # playbox configure ?options...?
    #
    # options  - A list of option names and values.
    #
    # Sets playbox option values.

    method {playbox configure} {args} {
        # FIRST, get the undo script.  Don't save it yet, as there
        # might be an error in the arguments.
        set script [list $rdb ungrab [$rdb grab mam_playbox {pid=1}]]

        # NEXT, make the change.
        $self DbConfigure mam_playbox 1 $args

        # NEXT, save the undo script
        $self SaveUndo $script

        return
    }




    #-------------------------------------------------------------------
    # Entity Methods

    # entity names
    #
    # Returns a list of the entity IDs.

    method {entity names} {} {
        $rdb eval {SELECT eid FROM mam_entity ORDER BY eid}
    }

    # entity add eid ?options...?
    #
    # eid - The new entity ID.
    #
    # Adds a new entity to the entities table.  In addition:
    #
    # - Adds the dependent records to the belief and affinity tables.
    # - Sets the entity's values.

    method {entity add} {eid args} {
        # FIRST, use a transaction, so that if there's an error
        # in an option or option value, there will be no change
        # to the database.
        $rdb transaction {
            # FIRST, add the entity record
            $rdb eval {
                INSERT INTO mam_entity(eid) VALUES($eid);
                
                INSERT INTO mam_belief(eid,tid)
                SELECT $eid, tid FROM mam_topic;
                
                INSERT INTO mam_affinity(f,g)
                SELECT $eid, eid FROM mam_entity;
                
                INSERT INTO mam_affinity(f,g)
                SELECT eid, $eid FROM mam_entity WHERE eid != $eid;
            }

            # NEXT, set the option values.
            $self DbConfigure mam_entity [list $eid] $args
        }

        $self SaveUndo [list $self MutateEntityDelete $eid]

        return
    }

    # MutateEntityDelete eid
    #
    # eid - The entity ID.
    #
    # Deletes an entity from the entities table, including dependent
    # records from the belief and affinity tables.

    method MutateEntityDelete {eid} {
        # FIRST, delete the entity record; the dependent records
        # will be deleted automatically.
        $rdb eval {
            DELETE FROM mam_entity WHERE eid=$eid;
        }
    }



    # entity delete eid
    #
    # eid - The entity ID.
    #
    # Deletes an entity from the entities table.  In addition:
    #
    # - Deletes the dependent records from the belief and affinity tables.

    method {entity delete} {eid} {
        # FIRST, delete the entity, grabbing the undo data set.
        set data [$rdb delete -grab mam_entity {eid=$eid}]

        # NEXT, save the undo script.
        $self SaveUndo [list $rdb ungrab $data]

        return
    }

    # entity cget eid option
    #
    # eid     - The entity ID
    # option  - The name of a entity option.  See [entity add].
    #
    # Retrieves the value of a entity's option.

    method {entity cget} {eid option} {
        $self DbCget mam_entity [list $eid] $option
    }
    
    # entity configure eid ?options...?
    #
    # eid      - The entity ID
    # options  - A list of option names and values.
    #
    # Sets entity option values.

    method {entity configure} {eid args} {
        # FIRST, get the undo script.  Don't save it yet, as there
        # might be an error in the arguments.
        set script [list $rdb ungrab [$rdb grab mam_entity {eid=$eid}]]

        # NEXT, make the change.
        $self DbConfigure mam_entity [list $eid] $args

        # NEXT, save the undo script
        $self SaveUndo $script

        return
    }


    # entity rename old new
    #
    # old - The old entity ID.
    # new - The new entity ID.
    #
    # Renames an entity in the entities table and all
    # dependent tables, and saves an undo script.

    method {entity rename} {old new} {
        # FIRST, Rename the entity.
        if {[catch {
            $self MutateEntityRename $old $new
        } result]} {
            error "Could not rename entity \"$old\" to \"$new\": $result"
        }

        # NEXT, if nothing happened, $old is not a valid entity ID.
        if {[$rdb changes] == 0} {
            error "Unknown mam_entity key: \"$old\""
        }

        # NEXT, save the undo script.
        $self SaveUndo [list $self MutateEntityRename $new $old]

        return
    }


    # MutateEntityRename old new
    #
    # old - The old entity ID.
    # new - The new entity ID.
    #
    # Renames an entity in the entities table and all
    # dependent tables.

    method MutateEntityRename {old new} {
        # FIRST, rename the entity; the dependent records
        # will be updated automatically.
        $rdb eval {
            UPDATE mam_entity
            SET   eid = $new
            WHERE eid = $old
        }
    }


    #-------------------------------------------------------------------
    # Topic Methods

    # topic names
    #
    # Returns a list of the topic IDs.

    method {topic names} {} {
        $rdb eval {SELECT tid FROM mam_topic ORDER BY tid}
    }

    # topic add tid ?options...?
    #
    # tid - The new topic ID.
    #
    # Options:
    # 
    #   -title     - The topic's human-readable title
    #   -relevance - The topic's relevance (0.0 to 1.0)
    #   -affinity  - 1 if the topic used when computing affinity,
    #                and 0 otherwise.
    #
    # Adds a new topic to the topics table.  In addition:
    #
    # - Adds the dependent records to the belief table.
    # - Sets the topic's values.

    method {topic add} {tid args} {
        # FIRST, use a transaction, so that if there's an error
        # in an option or option value, there will be no change
        # to the database.
        $rdb transaction {
            # FIRST, add the topic records.
            $rdb eval {
                INSERT INTO mam_topic(tid) VALUES($tid);

                INSERT INTO mam_belief(eid,tid) 
                SELECT eid, $tid FROM mam_entity;
            }

            # NEXT, set the option values.
            $self DbConfigure mam_topic [list $tid] $args
        }

        $self SaveUndo [list $self MutateTopicDelete $tid]

        return
    }

    # MutateTopicDelete tid
    #
    # tid - The topic ID.
    #
    # Deletes a topic from the topics table, including 
    # dependent records from the mam_belief table.

    method MutateTopicDelete {tid} {
        # FIRST, delete the topic record; the dependent records
        # will be deleted automatically.
        $rdb eval {
            DELETE FROM mam_topic WHERE tid=$tid;
        }
    }

    # topic delete tid
    #
    # tid - The topic ID.
    #
    # Deletes a topic from the topics table.  In addition:
    #
    # - Deletes the dependent records from the belief table.

    method {topic delete} {tid} {
        # FIRST, delete the topic and dependent data, grabbing
        # the undo data.
        set data [$rdb delete -grab mam_topic {tid=$tid}]

        # NEXT, save the undo script if the delete succeeded.
        $self SaveUndo [list $rdb ungrab $data]

        return
    }

    # topic cget tid option
    #
    # tid     - The topic ID
    # option  - The name of a topic option.  See [topic add].
    #
    # Retrieves the value of a topic's option.

    method {topic cget} {tid option} {
        $self DbCget mam_topic [list $tid] $option
    }
    
    # topic configure tid ?options...?
    #
    # tid      - The topic ID
    # options  - A list of option names and values.
    #
    # Sets topic option values.

    method {topic configure} {tid args} {
        # FIRST, get the undo script.  Don't save it yet, as there
        # might be an error in the arguments.
        set script [list $rdb ungrab [$rdb grab mam_topic {tid=$tid}]]

        # NEXT, make the change.
        $self DbConfigure mam_topic [list $tid] $args

        # NEXT, save the undo script
        $self SaveUndo $script

        return
    }


    # topic rename old new
    #
    # old - The old topic ID.
    # new - The new topic ID.
    #
    # Renames an topic in the topics table and all
    # dependent tables, and saves an undo script.

    method {topic rename} {old new} {
        # FIRST, Rename the topic.
        if {[catch {
            $self MutateTopicRename $old $new
        } result]} {
            error "Could not rename topic \"$old\" to \"$new\": $result"
        }

        # NEXT, if nothing happened, $old is not a valid topic ID.
        if {[$rdb changes] == 0} {
            error "Unknown mam_topic key: \"$old\""
        }

        # NEXT, save the undo script.
        $self SaveUndo [list $self MutateTopicRename $new $old]

        return
    }


    # MutateTopicRename old new
    #
    # old - The old topic ID.
    # new - The new topic ID.
    #
    # Renames an topic in the topics table and all
    # dependent tables.

    method MutateTopicRename {old new} {
        # FIRST, rename the topic; the dependent records
        # will be updated automatically.
        $rdb eval {
            UPDATE mam_topic
            SET   tid = $new
            WHERE tid = $old
        }
    }

    #-------------------------------------------------------------------
    # Belief methods
    
    # belief cget eid tid option
    #
    # eid     - The entity ID
    # tid     - The topic ID
    # option  - The name of a belief option.  See [belief configure].
    #
    # Retrieves the value of a belief's option.

    method {belief cget} {eid tid option} {
        $self DbCget mam_belief [list $eid $tid] $option
    }
    
    # belief configure eid tid ?options...?
    #
    # eid      - The entity ID
    # tid      - The topic ID
    # options  - A list of option names and values.
    #
    # Sets belief option values.

    method {belief configure} {eid tid args} {
        # FIRST, get the undo script.  Don't save it yet, as there
        # might be an error in the arguments.
        set rows [$rdb grab mam_belief {eid=$eid AND tid=$tid}]

        # NEXT, make the change.
        $self DbConfigure mam_belief [list $eid $tid] $args

        # NEXT, save the undo script
        $self SaveUndo [list $rdb ungrab $rows]

        return
    }

    #-------------------------------------------------------------------
    # Computation
    #
    # This section contains the code that actually computes affinities.

    # compute
    #
    # Computes the affinities for all pairs of entities using the
    # newest RGC method.

    method compute {} {
        # FIRST, retrieve gamma and compute the commonality of the
        # playbox, eta.playbox.
        set gamma [$rdb onecolumn {SELECT gamma FROM mam_playbox}]

        set totalRelevance [$rdb onecolumn {
            SELECT total(relevance) FROM mam_topic
            WHERE affinity = 1
        }]

        let etaPlaybox {$gamma*$totalRelevance}

        # NEXT, get each entity's participation in the commonality
        # of the playbox, theta:

        array set theta [$rdb eval {
            SELECT eid, commonality FROM mam_entity
        }]
        

        # NEXT, Get each entity's signs, strengths, and emphases.
        # The entity's position is attenuated by the relevance of the
        # topic.
        set count 0
        $rdb eval {
            SELECT B.eid                    AS eid, 
                   B.position * T.relevance AS position, 
                   B.emphasis               AS emphasis
            FROM mam_belief AS B
            JOIN mam_topic  AS T USING (tid)
            WHERE T.affinity = 1
            ORDER by eid, tid
        } {
            incr count

            lappend P($eid)   $position
            lappend tau($eid) $emphasis
        }

        # NEXT, if there's no data just set all affinities to zero.
        if {$count == 0} {
            $rdb eval {
                UPDATE mam_affinity SET affinity = 0.0
            }

            return
        }

        # NEXT, compute the affinity for each pair of entities.
        $rdb eval {
            SELECT F.eid AS f,
                   G.eid AS g
            FROM mam_entity AS F
            JOIN mam_entity AS G
        } {
            let eta {$etaPlaybox * min($theta($f),$theta($g))}

            set a [Affinity $eta $P($f) $tau($f) $P($g)]

            $rdb eval {
                UPDATE mam_affinity
                SET affinity=$a
                WHERE f=$f AND g=$g
            }
        }
    }

    # congruence eid theta hook
    #
    # eid     - An entity ID.
    # theta   - The hook's entity commonality, 0.0 to 1.0
    # hook    - A dictionary {tid -> position}
    #
    # Computes the congruence of the hook with the entity,
    # given the hook's entity commonality.  Essentially, 
    # the congruence of the hook with an entity is simply the 
    # affinity of the entity with the hook considering only the
    # explicit topics included in the hook, along with the 
    # implicit topics implied by the playbox commonality setting
    # and the entity's and hook's entity commonality.

    method congruence {eid theta hook} {
        # FIRST, if there are no topics in the hook, return 0.0.
        if {[dict size $hook] == 0} {
            return 0.0
        }

        # NEXT, create an "IN" clause for the topics in the hook.
        set topics [dict keys $hook]
        set topicSet "('[join $topics ',']')"
        
        # NEXT, retrieve gamma and compute the commonality of the
        # playbox, eta.playbox, for the topics in the topic set.
        set gamma [$rdb onecolumn {SELECT gamma FROM mam_playbox}]

        set totalRelevance [$rdb onecolumn "
            SELECT total(relevance) FROM mam_topic
            WHERE tid IN $topicSet
        "]

        let etaPlaybox {$gamma*$totalRelevance}

        # NEXT, get eid's entity commonality, and compute eta.
        set eid_theta [$rdb onecolumn {
            SELECT commonality FROM mam_entity WHERE eid=$eid
        }]
        
        let eta {$etaPlaybox * min($eid_theta, $theta)}

        # NEXT, Get the entity's signs, strengths, and emphases.
        # The entity's position is attenuated by the relevance of the
        # topic.
        $rdb eval "
            SELECT B.position   AS position, 
                   B.emphasis   AS emphasis,
                   B.tid        AS tid,
                   T.relevance  AS relevance
            FROM mam_belief AS B
            JOIN mam_topic  AS T USING (tid)
            WHERE eid=\$eid AND tid IN $topicSet
            ORDER by tid
        " {
            lappend ePos [expr {$relevance * $position}]
            lappend hPos [expr {$relevance * [dict get $hook $tid]}]
            lappend tau $emphasis
        }

        return [Affinity $eta $ePos $tau $hPos]
    }

    # Affinity $eta pfList eList pgList
    #
    # eta     - A measure of the commonality between the entities
    # pfList  - A list of positions for entity f
    # eList   - A list of emphases for entity f
    # pgList  - A list of positions for entity g
    #
    # Computes the affinity of entity f for entity g given their
    # positions on the same topics and f's emphasis on agreement/disagreement,
    # per the Mars Analyst's Guide.
    #
    # NOTE: The eta and positions have already been modified by topic
    # relevance.

    proc Affinity {eta pfList eList pgList} {
        # FIRST, set epsilon.  This could be a parmset parameter, but
        # there seems little need to adjust it.  Note that all of the 
        # numbers we're comparing have absolute values less than or 
        # equal to 1.0.
        set epsilon 0.001

        # NEXT, Prepare to accumulate data
        set J [list]   ;# Topics i s.t. E.fi = 0
        set K [list]   ;# Topics in J s.t. P.fi != P.gi
        set L [list]   ;# Topics i s.t. E.fi > 0

        set sum_L_M     0.0
        set sum_J_ZG    0.0
        set sum_L_Num   0.0
        set sum_L_Denom 0.0

        # NEXT, loop over the topics and accumulate the data needed to
        # assess the special cases.
        for {set i 0} {$i < [llength $pfList]} {incr i} {
            set Efi [lindex $eList $i]
            set Pfi [lindex $pfList $i]
            set Pgi [lindex $pgList $i]

            set Bfi    [sign $Pfi]
            let Bgi    [sign $Pgi]
            let Zfi    {abs($Pfi)}
            let Zgi    {abs($Pgi)}

            # Agreement
            if {$Bfi == $Bgi} {
                let G {sqrt($Pfi * $Pgi)}
            } else {
                let G 0.0
            }

            # Disagreement
            let D {abs($Pfi - $Pgi)/2.0}
            
            # Importance
            let M {max($Zfi,$D)}

            if {abs($Efi) < $epsilon} {
                lappend J $i
                let sum_J_ZG {$sum_J_ZG + $Zfi*$G}

                let val {abs($Pfi-$Pgi)}

                if {abs($Pfi - $Pgi) >= $epsilon} {
                    lappend K $i
                }
            } else {
                lappend L $i

                let beta {(1 - $Efi)/$Efi}

                let sum_L_M {$sum_L_M + $M}

                let sum_L_Num   {$sum_L_Num   + $M*($G - $beta*$D)}
                let sum_L_Denom {$sum_L_Denom + $M*(1  + $beta*$D)}
            }
        }

        # CASE A

        if {[llength $J] == 0 && 
            $eta + $sum_L_M < $epsilon
        } {
            return 0.0
        }

        # CASE B
        if {[llength $J] > 0 &&
            [llength $K] == 0 &&
            $eta + $sum_J_ZG + $sum_L_M < $epsilon
        } {
            return 0.0
        }

        # CASE C
        
        if {[llength $J] > 0 &&
            [llength $K] > 0
        } {
            return -1.0
        }

        # CASE D/E
        #
        # These cases differ only in the $sum_J_ZG term, which is
        # zero in Case E.

        let Num   {$eta + $sum_J_ZG + $sum_L_Num}
        let Denom {$eta + $sum_J_ZG + $sum_L_Denom}

        return [expr {$Num/$Denom}]
    }

    # sign x
    # 
    # x - A number
    #
    # Returns the sign of x as -1, 0, or 1.

    proc sign {x} {
        if {$x < 0.0} {
            return -1.0
        } elseif {$x > 0.0} {
            return 1.0
        } else {
            return 0.0
        }
    }

    #-------------------------------------------------------------------
    # edit
    #
    # This family of subcommands is patterned after the Tk text
    # widget's "edit" command.

    # edit reset
    #
    # Clears the undo stack.

    method {edit reset} {} {
        $rdb eval {DELETE FROM mam_undo}
    }

    # edit undo
    #
    # Undoes the last operation.  It's an error if there's nothing
    # to undo.

    method {edit undo} {} {
        # FIRST, get the maximum id from the mam_undo table.
        set id ""

        $rdb eval {
            -- Note: Retrieving "script" in this way only works
            -- reliably when there is exactly one row for which
            -- "id" has the maximum value.
            SELECT MAX(id) AS id, script
            FROM mam_undo
        } {}

        if {$id eq ""} {
            error "nothing to undo"
        }

        # NEXT, delete the script from the undo stack
        $rdb eval {
            DELETE FROM mam_undo WHERE id=$id
        }

        # NEXT, execute the script
        namespace eval :: $script

        return
    }

    # edit canundo
    #
    # Returns 1 if there's anything on the undo stack, and 0 otherwise.

    method {edit canundo} {} {
        $rdb exists { SELECT * FROM mam_undo }
    }


    # SaveUndo script
    #
    # Saves an undo script in the mam_undo table, provided that 
    # undo is enabled.

    method SaveUndo {script} {
        if {!$options(-undo)} {
            return
        }

        $rdb eval {
            INSERT INTO mam_undo(script) VALUES($script)
        }
    }

    #-------------------------------------------------------------------
    # Other Public Methods

    # clear
    #
    # Uninitializes mam, returning it to its initial state on 
    # creation and deleting all of the instance's data from the rdb.
    # This command is not undoable.

    method clear {} {
        # FIRST, Clear the RDB
        $self ClearTables clear
    }

    # ClearTables mode
    #
    # mode - clear|destroy
    #
    # Deletes all data from the mam.sql tables for this instance.
    # If mode is "clear", then mam_playbox is retained but reset; we should 
    # always have one record in that table.

    method ClearTables {mode} {
        $rdb eval {
            -- The dependent records are deleted automatically
            DELETE FROM mam_entity;
            DELETE FROM mam_topic;
            DELETE FROM mam_undo;
        }

        if {$mode eq "clear"} {
            $rdb eval {
                INSERT OR REPLACE INTO 
                mam_playbox(pid,gamma) 
                VALUES(1,1.0)
            }
        } else {
            $rdb eval {
                DELETE FROM mam_playbox;
            }
        }
    }

    #-------------------------------------------------------------------
    # Generic DB Methods
    #
    # These routines implement a generic way to set and get table
    # column values using a configure/cget interface.  The specifics
    # of the table are defined in the tableInfo array, and then the
    # public interface calls the Db* interface.

    # Table Info Array
    #
    # This table contains data used by the generic routines.
    #
    # $table-keys      - List of names of primary key columns.
    # $table-options   - List of names of table options
    # $table-where     - Where clause

    typevariable tableInfo -array {
        mam_playbox-keys    {pid}
        mam_playbox-options {-gamma}
        mam_playbox-where   {WHERE pid=$key(pid)}

        mam_entity-keys     eid
        mam_entity-options  {-commonality}
        mam_entity-where    {WHERE eid=$key(eid)}

        mam_topic-keys      tid
        mam_topic-options   {-title -relevance -affinity}
        mam_topic-where     {WHERE tid=$key(tid)}

        mam_belief-keys     {eid tid}
        mam_belief-options  {-position -emphasis}
        mam_belief-where    {WHERE eid=$key(eid) AND tid=$key(tid)}
    }

    # DbCget table keyVals option
    #
    # table    - The name of the table
    # keyVals  - A list of the values of the key fields
    # option   - The name of the option to retrieve.
    #
    # Retrieves the value of a table column

    method DbCget {table keyVals option} {
        # FIRST, get the key array
        foreach name $tableInfo($table-keys) val $keyVals {
            set key($name) $val
        }

        # NEXT, get the column name
        if {$option in $tableInfo($table-options)} {
            set colname [string range $option 1 end]
        } else {
            error "Unknown $table option: \"$option\""
        }

        # NEXT, get the value
        $rdb eval "
            SELECT $colname FROM $table 
            $tableInfo($table-where)
        " row {
            return $row($colname)
        }

        # NEXT, there's no such tid.
        error "Unknown $table key: \"$keyVals\""
    }

    # DbConfigure table keyVals optList
    #
    # table     - The name of a table in tableInfo
    # keyVals   - A list of the values of the key field(s)
    # optList   - A list of option names and values.
    #
    # Sets column values in the row specified by the
    # keyVals.  If there is an
    # error in one of the options or values, the database
    # will be rolled back (provided rollbacks are enabled,
    # and that this routine wasn't called from within a wider
    # transaction).

    method DbConfigure {table keyVals optList} {
        # FIRST, get the key array
        foreach name $tableInfo($table-keys) val $keyVals {
            set key($name) $val
        }

        # NEXT, do this in a transaction, so that an error doesn't
        # change the database.
        $rdb transaction {
            while {[llength $optList] > 0} {
                set opt [lshift optList]

                if {$opt in $tableInfo($table-options)} {
                    set colname [string range $opt 1 end]
                    set value   [lshift optList]

                    if {[catch {
                        $rdb eval "
                            UPDATE $table
                            SET $colname = \$value
                            $tableInfo($table-where)
                        "
                    } result]} {
                        error "Invalid $table $opt: $result"
                    }

                    if {[$rdb changes] == 0} {
                        error "Unknown $table key: \"$keyVals\""
                    }
                } else {
                    error "Unknown $table option: \"$opt\""
                }
            }
        }

        return
    }
}
