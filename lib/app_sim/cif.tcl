#-----------------------------------------------------------------------
# TITLE:
#    cif.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Critical Input File manager.  Granted, it's now a 
#    database table rather than a file, but "cif" is hallowed by time.
#
#    This module is responsible for adding orders to the cif table and
#    for supporting application undo/redo.
#
#-----------------------------------------------------------------------

snit::type cif {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Uncheckpointed Type Variables

    # info  -- scalar data
    #
    # redoStack  - Stack of redo records.  Item "end" is the head of the
    #              stack.  The variable contains the empty list if there
    #              is nothing to redo.  Each record is a dict corresponding
    #              to a CIF row.

    typevariable info -array {
        redoStack {}
    }


    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail cif "init"

        # FIRST, prepare to receive events
        notifier bind ::scenario <Saving>  $type [mytypemethod ClearUndo]
        notifier bind ::sim      <Tick>    $type [mytypemethod ClearUndo]
        notifier bind ::sim      <DbSyncA> $type [mytypemethod DbSync]

        # NEXT, log that we're saved.
        log detail cif "init complete"
    }

    #-------------------------------------------------------------------
    # Event handlers

    # ClearUndo
    #
    # Clears all undo information, and gets rid of undone orders that
    # are waiting to be redone

    typemethod ClearUndo {} {
        # FIRST, clear the undo information from the cif table.
        rdb eval {
            UPDATE cif SET undo='';
        }

        # NEXT, get rid of the redo stack.
        set info(redoStack) [list]

        notifier send ::cif <Update>
    }

    # DbSync
    #
    # Syncs the CIF stack with the database.

    typemethod DbSync {} {
        # FIRST, clear the redoStack.
        set info(redoStack) [list]
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # clear
    #
    # Clears all data from the CIF.

    typemethod clear {} {
        set info(redoStack) [list]
        rdb eval {DELETE FROM cif}
    }

    # add order parmdict ?undo?
    #
    # order      The name of the order to be saved
    # parmdict   The order's parameter dictionary
    # undo       A script that will undo the order
    #
    # Saves the order in the CIF.

    typemethod add {order parmdict {undo ""}} {
        # FIRST, clear the redo stack.
        set info(redoStack) [list]

        # NEXT, insert the new order.
        set now [simclock now]

        set narrative [order narrative $order $parmdict]

        rdb eval {
            INSERT INTO cif(time,name,narrative,parmdict,undo)
            VALUES($now, $order, $narrative, $parmdict, $undo);
        }

        notifier send ::cif <Update>
    }

    # top
    #
    # Returns the ID of the top entry in the CIF, or "" if none.

    typemethod top {} {
        rdb eval {
            SELECT max(id) AS top FROM cif
        } {
            return $top
        }

        return ""
    }

    # canundo
    #
    # If the top order on the stack can be undone, returns its title;
    # and "" otherwise.

    typemethod canundo {} {
        # FIRST, get the undo information
        set top [cif top]

        if {$top eq ""} {
            return ""
        }

        rdb eval {
            SELECT narrative,
                   coalesce(undo,'') == '' AS noUndo
            FROM cif 
            WHERE id=$top
        } {
            if {$noUndo} {
                return ""
            }

            return $narrative
        }

        return ""
    }

    # undo ?-test?
    #
    # -test        Throw an error instead of popping up a dialog.
    #
    # Undo the previous command, if possible.  If not, throw an
    # error.

    typemethod undo {{opt ""}} {
        # FIRST, get the undo information
        set id [cif top]


        rdb eval {
            SELECT id, name, narrative, parmdict, undo
            FROM cif 
            WHERE id=$id
        } {}

        if {$id eq "" || $undo eq ""} {
            error "Nothing to undo"
        }

        # NEXT, Undo the order
        log normal cif "undo: $name $parmdict"

        if {[catch {
            rdb monitor transaction {
                uplevel \#0 $undo
            }
        } result opts]} {
            # FIRST, If we're testing, rethrow the error.
            if {$opt eq "-test"} {
                return {*}$opts $result
            }

            # NEXT, Log all of the details
            set einfo [dict get $opts -errorinfo]

            log error cif [tsubst {
                |<--
                Error during undo (changes have been rolled back):

                [cif dump]

                Stack Trace:
                $einfo
            }]

            # NEXT, clear all undo information; we can't undo, and
            # we've logged the problem entry.
            rdb eval {
                UPDATE cif
                SET undo = '';
            }

            # NEXT, tell the user what happened.
            app error {
                |<--
                Undo $name

                There was an unexpected error while undoing 
                this order.  The scenario has been rolled back 
                to its previous state, so the application data
                should not be corrupted.  However:

                * You should probably save the scenario under
                a new name, just in case.

                * The error has been logged in detail.  Please
                contact JPL to get the problem fixed. 
            }

            # NEXT, Reconfigure all modules from the database: 
            # this should clean up any problems in Tcl memory.
            sim dbsync
        } else {
            # FIRST, no error; add the undo order to the redo stack.
            lappend info(redoStack)       \
                [dict create              \
                     name      $name      \
                     narrative $narrative \
                     parmdict  $parmdict  \
                     undo      $undo]

            # NEXT, delete the order from the undo stack
            rdb eval {
                DELETE FROM cif WHERE id=$id
            }
        }

        notifier send ::cif <Update>

        return
    }

    # canredo
    #
    # If there's an undone order on the stack, returns its narrative;
    # and "" otherwise.

    typemethod canredo {} {
        # FIRST, get the redo information
        set record [lindex $info(redoStack) end]

        if {[dict size $record] > 0} {
            return [dict get $record narrative]
        }

        return
    }

    # redo
    #
    # Redo the previous command, if possible.  If not, throw an
    # error.

    typemethod redo {} {
        # FIRST, get the redo information
        set record [lindex $info(redoStack) end]
        set info(redoStack) [lrange $info(redoStack) 0 end-1]

        if {[dict size $record] == 0} {
            error "Nothing to redo"
        }

        dict with record {
            log normal cif "redo: $name $parmdict"

            bgcatch {
                order send app $name $parmdict
            }

            cif add $name $parmdict $undo

            notifier send ::cif <Update>
        }

        return
    }

    # dump ?-count n?"
    #
    # -count n     Number of entries to dump, starting from the most recent.
    #              Defaults to 1
    #
    # Returns a dump of the CIF in human-readable form.  Defaults to
    # the entry on the top of the stack.

    typemethod dump {args} {
        # FIRST, get the options
        array set opts {
            -count 1
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -count {
                    set opts(-count) [lshift args]
                }

                default {
                    error "Unrecognized option: \"$opt\""
                }
            }
        }

        require {$opts(-count) > 0} "-count is less than 1."

        set result [list]

        rdb eval [tsubst {
            SELECT * FROM cif
            ORDER BY id DESC
            LIMIT $opts(-count)
        }] row {
            set out "\#$row(id) $row(name) @ $row(time): \n"


            append out "Parameters:\n"

            # Get the width of the longest parameter name, plus the colon.
            set wid [lmaxlen [dict keys $row(parmdict)]]
            incr wid 

            set parmlist [order parms $row(name)]

            foreach parm [order parms $row(name)] {
                if {[dict exists $row(parmdict) $parm]} {
                    set value [dict get $row(parmdict) $parm]
                    append out [format "    %-*s %s\n" $wid $parm: $value]
                }
            }

            if {$row(undo) ne ""} {
                append out "Undo Script:\n"
                foreach line [split $row(undo) "\n"] {
                    append out "    $line\n"
                }
            }

            lappend result $out
        }

        return [join $result "\n"]
    }
}



