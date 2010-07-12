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
    # Type Variables

    # info  -- scalar data
    #
    # nextid      Next order ID.  If we've undone, it's the ID of the
    #             next order to redo.

    typevariable info -array {
        nextid  0
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
        rdb eval {
            UPDATE cif SET undo='';
            DELETE FROM cif WHERE id >= $info(nextid);
        }

        notifier send ::cif <Update>
    }

    # DbSync
    #
    # Syncs the CIF stack with the database.

    typemethod DbSync {} {
        if {[rdb exists {SELECT * FROM cif}]} {
            set info(nextid) [rdb onecolumn {
                SELECT max(id) + 1 FROM cif
            }]
        } else {
            set info(nextid) 0
        }
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # mark
    #
    # Returns a mark representing the top of the CIF

    typemethod mark {} {
        expr $info(nextid) - 1
    }

    # clear ?mark?
    #
    # mark    A mark, as returned by "mark".
    #
    # By default, deletes all history from the CIF.  If mark is
    # given, deletes all history later than mark.

    typemethod clear {{mark 0}} {
        rdb eval {
            DELETE FROM cif WHERE id > $mark;
        }

        set info(nextid) $mark
        notifier send ::cif <Update>
    }

    # add order parmdict ?undo?
    #
    # order      The name of the order to be saved
    # parmdict   The order's parameter dictionary
    # undo       A script that will undo the order
    #
    # Saves the order in the CIF.

    typemethod add {order parmdict {undo ""}} {
        # FIRST, if there are things above this on the
        # stack, delete them; this replaces them.
        rdb eval {
            DELETE FROM cif WHERE id >= $info(nextid);
        }

        # NEXT, insert the new order.
        # TBD: there should be an SQL function for this!
        set now [simclock now]

        set narrative [order narrative $order $parmdict]

        rdb eval {
            INSERT INTO cif(id,time,name,narrative,parmdict,undo)
            VALUES($info(nextid), $now, $order, $narrative, $parmdict, $undo);
        }

        incr info(nextid)

        notifier send ::cif <Update>
    }

    # canundo
    #
    # If the top order on the stack can be undone, returns its title;
    # and "" otherwise.

    typemethod canundo {} {
        # FIRST, get the undo information
        rdb eval {
            SELECT name,
                   narrative,
                   undo == '' AS noUndo
            FROM cif 
            WHERE id=$info(nextid) - 1
        } {
            if {$noUndo} {
                return ""
            }

            return $narrative
        }

        return
    }

    # undo ?-test?
    #
    # -test        Throw an error instead of popping up a dialog.
    #
    # Undo the previous command, if possible.  If not, throw an
    # error.

    typemethod undo {{opt ""}} {
        # FIRST, get the undo information
        set id ""

        rdb eval {
            SELECT id, name, parmdict, undo
            FROM cif 
            WHERE id=$info(nextid) - 1
        } {}

        if {$id eq "" || $undo eq ""} {
            error "Nothing to undo"
        }

        # NEXT, Undo the order
        log normal cif "undo: $name $parmdict"

        if {[catch {
            rdb transaction {
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
            # FIRST, no error; update the top of the stack.
            incr info(nextid) -1
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
        rdb eval {
            SELECT name, narrative
            FROM cif 
            WHERE id=$info(nextid)
        } {
            return $narrative
        }

        return
    }

    # redo
    #
    # Redo the previous command, if possible.  If not, throw an
    # error.

    typemethod redo {} {
        # FIRST, get the redo information
        rdb eval {
            SELECT name, parmdict
            FROM cif 
            WHERE id=$info(nextid)
        } {
            log normal cif "redo: $name $parmdict"

            bgcatch {
                order send sim $name $parmdict
            }

            incr info(nextid)

            notifier send ::cif <Update>
            return
        }

        error "Nothing to redo"
    }

    # dump ?-count n? ?-redo"
    #
    # -count n     Number of entries to dump, starting from the most recent.
    #              Defaults to 1
    #
    # -redo        Include undone orders; otherwise starts at the top of
    #              the undo stack.
    #
    # Returns a dump of the CIF in human-readable form.  Defaults to
    # the entry on the top of the stack.

    typemethod dump {args} {
        # FIRST, get the options
        array set opts {
            -count 1
            -redo  no
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -count {
                    set opts(-count) [lshift args]
                }

                -redo {
                    set opts(-redo) yes
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
            [tif {!$opts(-redo)} {WHERE id < \$info(nextid)}]
            ORDER BY id DESC
            LIMIT $opts(-count)
        }] row {
            if {$row(id) == $info(nextid) - 1} {
                set tag " *top*"
            } elseif {$row(id) >= $info(nextid)} {
                set tag " *redo*"
            } else {
                set tag ""
            }

            set out "\#$row(id)$tag $row(name) @ $row(time): \n"


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



