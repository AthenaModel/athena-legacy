#-----------------------------------------------------------------------
# TITLE:
#    cif.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    minerva_sim(1): Critical Input File manager.  Granted, it's now a 
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

    # add order parmdict ?undo?
    #
    # order      The name of the order to be saved
    # parmdict   The order's parameter dictionary
    # undo       A command that will undo the order
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

            # TBD: This should be part of the order definition
            return [ordergui meta $name title]
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
            SELECT name, parmdict, undo
            FROM cif 
            WHERE id=$info(nextid) - 1
        } {
            if {$undo ne ""} {
                log normal cif "undo: $name $parmdict"

                uplevel \#0 $undo

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
            # TBD: This should be part of the order definition
            return [ordergui meta $name title]
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

            order send "" sim $name $parmdict

            incr info(nextid)

            return
        }

        error "Nothing to redo"
    }
}

