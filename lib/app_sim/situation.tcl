#-----------------------------------------------------------------------
# TITLE:
#    situation.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1) Situation module
#
#    This module defines a singleton, "situation", which is used to
#    manage situations in general, and a type, "situationType", which
#    is an abstract base type for situation objects.  A single
#    snit::type could do both jobs--but at the expense of accidentally
#    creating a situation object if an incorrect method name is used.
#
#    All situation objects use the Database-backed Objects pattern.  
#    Situation objects come into being as needed, and may be used to
#    set and query situation parameters, which are transparently
#    stored in the RDB.
#
# PATTERN OF USE:
#    This code should be used in the following way, in order to get the
#    benefits described above:
#
#    * Situation objects should always be retrieved into a local variable for
#      use:
#
#          set o [situation get $s]
#
#      They can then be passed to other commands, provided that those
#      commands do not cache the command name.
#
#      NEVER save the name of a situation object across Tcl events; each
#      time you return to the event loop there's the possibility of an
#      event that will delete all situation objects from memory.
#
#    * All updates to the situation tables should be done through the 
#      situation command, the actsit command, the ensit command, the
#      demsit command, or through a situation object.
#
#      * Create records in the situation tables using 
#        [ensit mutate create], [actsit assess], or [demsit assess].
#
#      * Update field values by using [$o set], where $o is a situation
#        object.
#
#    Note that the situation tables may still be *queried* in the usual
#    way, via the rdb command; they just shouldn't be updated via the
#    rdb command.
#
# CHECKPOINT/RESTORE
#    The situation module participates in the checkpoint/restore protocol.
#    On restore, situation must flush its cache of situation objects,
#    destroying the existing objects.  New situation objects will then 
#    be created as they are needed.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# situation singleton

snit::type situation {
    # Make it an ensemble
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Non-checkpointed Variables

    # Array, situation object commands by id
    typevariable cache -array {}

    #-------------------------------------------------------------------
    # Initialization method

    typemethod init {} {
        log normal situation "init"

        # FIRST, register this module as a saveable, so that the
        # cache is flushed as appropriate.
        scenario register $type

        # NEXT, prepare to receive simulation events
        notifier bind ::sim <State>   $type [mytypemethod SimState]
        notifier bind ::sim <DbSyncA> $type [mytypemethod dbsync]

        # NEXT, the module is up.
        log normal situation "init complete"
    }

    #-------------------------------------------------------------------
    # Event Bindings

    # SimState
    #
    # Called when the simulation state changes.

    typemethod SimState {} {
        # FIRST, on transition to "RUNNING" clear all change marks.
        if {[sim state] eq "RUNNING"} {
            $type ClearChangeMarks
        }
    }


    # ClearChangeMarks
    #
    # Clears all of the change marks.  This is typically called
    # on entry to the RUNNING state.

    typemethod ClearChangeMarks {} {
        rdb eval {SELECT s, kind FROM situations WHERE change != ''} {
            set sit [$type get $s]
            $sit set change ""
        }
    }

    # dbsync
    #
    # Resets the in-memory state to reflect the RDB.

    typemethod dbsync {} {
        $type FlushCache
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # create kind column value....
    #
    # kind              The kind of the situation
    #
    # column value...   Specific columns and their values in the
    #                   situations table
    #
    # Creates the new record.  Sets the following columns
    # automatically:
    #
    #    s
    #    kind
    #    state = INITIAL
    #    change = NEW
    #    ts, tc = now
    #
    # Returns the new situation ID

    typemethod create {kind args} {
        # FIRST, get default parameters
        set parmdict [dict create \
                          state  INITIAL        \
                          change NEW            \
                          ts     [simclock now] \
                          tc     [simclock now]]

        set parmdict [dict merge $parmdict $args]

        dict set parmdict kind $kind

        # NEXT, create the row
        rdb insert situations $parmdict

        # NEXT, get and return the new situation ID.
        return [rdb last_insert_rowid]
    }


    # get s ?-all | -live?
    #
    # s               The situation ID
    #
    # -all   Default.  All situations are included
    # -live  Only live situations are included.
    #
    # Returns the object associated with the ID.  A record must already
    # exist in the RDB.

    typemethod get {s {opt -all}} {
        # FIRST, If we have an object, return it.
        if {[info exists cache($s)]} {
            if {$opt eq "-all" || [$cache($s) get state] ne "ENDED"} {
                return $cache($s)
            }
        }

        # NEXT, We don't have an object; create and return it.
        set kind [$type kind $s $opt]

        if {$kind ne ""} {
            set cache($s) [${kind}Type %AUTO% $s]

            return $cache($s)
        }

        # NEXT, There's no such situation.
        if {$opt eq "-live"} {
            error "no such live situation: \"$s\""
        } else {
            error "no such situation: \"$s\""
        }
    }


    # kind s ?-all | -live?
    #
    # s      The situation ID
    #
    # -all   Default.  All situations are included
    # -live  Only live situations are included.
    #
    # Returns the kind of the situation: ::actsit, etc.  If none
    # is found, returns "".

    typemethod kind {s {opt -all}} {
        set kind ""

        rdb eval {
            SELECT kind, state FROM situations WHERE s=$s
        } {
            if {$opt eq "-live" && $state eq "ENDED"} {
                set kind ""
            }
        }

        return $kind
    }

    # uncache s
    #
    # s     The situation ID
    #
    # Removes s from the object cache.

    typemethod uncache {s} {
        if {[info exists cache($s)]} {
            $cache($s) destroy
            unset cache($s)
        }
    }

    #-------------------------------------------------------------------
    # Private Type Methods

    # FlushCache
    #
    # Flush the object cache; we'll rebuild it as needed.

    typemethod FlushCache {} {
        # FIRST, destroy all of the known situation objects
        foreach {s o} [array get cache] {
            $o destroy
        }

        # NEXT, clear the cache array, so that we can cache new
        # objects.
        array unset cache

        log normal situation "Cache cleared."
    }

    #-------------------------------------------------------------------
    # Checkpoint/Restore

    # checkpoint ?-saved?
    #
    # Returns the component's checkpoint information as a string.

    typemethod checkpoint {{flag ""}} {
        # No checkpointed data
        return ""
    }

    # restore checkpoint ?-saved?
    #
    # checkpoint      A checkpoint string returned by "checkpoint"
    #
    # Restores the component's state to the checkpoint.  In this case,
    # the persistent situation state is stored wholly in the RDB...but we 
    # need to flush the cache of existing situation objects.

    typemethod restore {checkpoint {flag ""}} {
        $type FlushCache
    }

    # changed
    #
    # Indicates that the nothing needs to be saved.

    typemethod changed {} {
        return 0
    }
}

#-----------------------------------------------------------------------
# situationType

snit::type situationType {
    #-------------------------------------------------------------------
    # Instance Variables
    #
    # Instance data is stored in two arrays, binfo and dinfo.  
    # binfo contains the field values from the situations table, and 
    # dinfo contains the field values from the derived situation type's
    # table.  Both are aliased into the derived situation object.

    # binfo() and dinfo() Array of fields, kept consistent with the RDB.
    variable binfo -array {}
    variable dinfo -array {}

    #-------------------------------------------------------------------
    # Constructor

    # constructor kind s
    # 
    # kind   The singleton type for the derived situation
    # s      The situation ID

    constructor {kind s} {
        # FIRST, retrieve the contents of the binfo array.
        rdb eval { SELECT * FROM situations WHERE s=$s } binfo {}
        unset binfo(*)

        # NEXT, make sure the kinds match
        assert {$binfo(kind) eq $kind}

        # NEXT, retrieve the contents of the dinfo array.
        set table [$kind table]

        if {$table ne ""} {
            rdb eval " SELECT * FROM $table WHERE s=$s " dinfo {}
            unset dinfo(*)
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    # id
    #
    # Returns the situation's ID

    method id {} {
        return $binfo(s)
    }


    # kind
    #
    # Returns the kind of situation it is.

    method kind {} {
        return $binfo(kind)
    }


    # oneliner
    #
    # Returns a one-line description of the situation

    method oneliner {} {
        return "$binfo(stype) in $binfo(n)"
    }


    # islive
    #
    # Returns 1 if the situation is alive, and 0 otherwise

    method islive {} {
        return [expr {$binfo(state) ne "ENDED"}]
    }


    # set field value
    #
    # field    The field name
    # value    A new value for the field
    #
    # Updates the field's value, in memory and in the RDB.
    
    method set {field value} {
        # FIRST, This is either a base or a derived field.  Update the
        # relevant table and array.
        if {[info exists binfo($field)]} {
            rdb eval "
                UPDATE situations SET $field = \$value 
                WHERE s=$binfo(s)
            "

            set binfo($field) $value
        } elseif {[info exists dinfo($field)]} {
            rdb eval "
                UPDATE [$binfo(kind) table] SET $field = \$value 
                WHERE s=$binfo(s)
            "

            set dinfo($field) $value
        } else {
            error "no such field: \"$field\""
        }
    }


    # dict
    #
    # Returns a dictionary of all field/value pairs

    method dict {} {
        return [concat [array get binfo] [array get dinfo]]
    }

    
    # get field
    #
    # field   The field name
    #
    # Return the cached value

    method get {field} {
        if {[info exists binfo($field)]} {
            return $binfo($field)
        } else {
            return $dinfo($field)
        }
    }
}
