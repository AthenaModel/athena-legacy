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
        # FIRST, prepare to receive events
        notifier bind ::scenario <Saving> $type [mytypemethod ClearUndo]

        # NEXT, log that we're saved.
        log normal cif "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the CIF stack from the database.

    typemethod reconfigure {} {
        if {[rdb exists {SELECT * FROM cif}]} {
            set info(nextid) [rdb onecolumn {
                SELECT max(id) + 1 FROM cif
            }]
        } else {
            set info(nextid) 0
        }
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
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # clear
    #
    # Deletes all history from the CIF

    typemethod clear {} {
        rdb eval {
            DELETE FROM cif;
        }

        set info(nextid) 0
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

        rdb eval {
            INSERT INTO cif(id,time,name,parmdict,undo)
            VALUES($info(nextid), $now, $order, $parmdict, $undo);
        }

        incr info(nextid)
    }

    # canundo
    #
    # If the top order on the stack can be undone, returns its title;
    # and "" otherwise.

    typemethod canundo {} {
        # FIRST, get the undo information
        rdb eval {
            SELECT name,
                   undo == '' AS noUndo
            FROM cif 
            WHERE id=$info(nextid) - 1
        } {
            if {$noUndo} {
                return ""
            }

            return [order meta $name title]
        }

        return
    }

    # undo
    #
    # Undo the previous command, if possible.  If not, throw an
    # error.

    typemethod undo {} {
        # FIRST, get the undo information
        rdb eval {
            SELECT id, name, parmdict, undo
            FROM cif 
            WHERE id=$info(nextid) - 1
        } {
            if {$undo ne ""} {
                log normal cif "undo: $name $parmdict"

                uplevel \#0 $undo

                rdb eval {
                    UPDATE cif
                    SET   undo = ''
                    WHERE id   = $id
                }

                incr info(nextid) -1

                return
            }
        }

        error "Nothing to undo"
    }

    # canredo
    #
    # If there's an undone order on the stack, returns its title;
    # and "" otherwise.

    typemethod canredo {} {
        # FIRST, get the redo information
        rdb eval {
            SELECT name
            FROM cif 
            WHERE id=$info(nextid)
        } {
            return [order meta $name title]
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
                order send "" sim $name $parmdict
            }

            incr info(nextid)

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


