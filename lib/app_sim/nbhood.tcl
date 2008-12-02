#-----------------------------------------------------------------------
# TITLE:
#    nbhood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    minerva_sim(1): Neighborhood Manager
#
#    This module is responsible for managing neighborhoods and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type nbhood {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    typecomponent geo   ;# A geoset, for polygon computations

    #-------------------------------------------------------------------
    # Type Variables
    
    # info -- array of scalars
    #
    # undo       Command to undo the last operation, or ""

    typevariable info -array {
        undo {}
    }

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        # FIRST, create the geoset
        set geo [geoset ${type}::geo]

        log detail nbhood "Initialized"
    }

    # reconfigure
    #
    # Refreshes the geoset with the current neighborhood data from
    # the database.
    
    typemethod reconfigure {} {
        # FIRST, populate the geoset
        $geo clear

        rdb eval {
            SELECT n, polygon FROM nbhoods
            ORDER BY stacking_order
        } {
            # Create the polygon with the neighborhood's name and
            # polygon coordinates; tag it with "nbhood".
            $geo create polygon $n $polygon nbhood
        }

        # NEXT, update the obscured_by fields
        $type SetObscuredBy

        # NEXT, clear the undo command
        set info(undo) {}
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # The following routines create or modify entity data.  Each of them
    # must set or clear the undo command.

    # create parmdict
    #
    # parmdict     A dictionary of neighborhood parms
    #
    #    longname       The neighborhood's long name
    #    urbanization   eurbanization level
    #    refpoint       Reference point, map coordinates
    #    polygon        Boundary polygon, in map coordinates.
    #
    # Creates a nbhood given the parms, which are presumed to be
    # valid.  When validity checks are needed, use the NBHOOD:CREATE
    # order.

    typemethod create {parmdict} {
        dict with parmdict {
            # FIRST, Put the neighborhood in the database
            rdb eval {
                INSERT INTO nbhoods(longname,refpoint,polygon,urbanization)
                VALUES($longname,
                       $refpoint,
                       $polygon,
                       $urbanization);

                -- Set the "n" based on the uid.
                UPDATE nbhoods
                SET    n=format('N%03d',last_insert_rowid())
                WHERE uid=last_insert_rowid();
        
                -- Get the "n" value
                SELECT n FROM nbhoods WHERE uid=last_insert_rowid();
            } {}

            # NEXT, set the stacking order
            rdb eval {
                SELECT COALESCE(MAX(stacking_order)+1, 1) AS top FROM nbhoods
            } {
                rdb eval {
                    UPDATE nbhoods
                    SET stacking_order=$top
                    WHERE n=$n;
                }
            }

            # NEXT, add the nbhood to the geoset
            $geo create polygon $n $polygon nbhood
        }

        # NEXT, recompute the obscured_by field; this nbhood might
        # have obscured some other neighborhood's refpoint.
        $type SetObscuredBy

        # NEXT, Not yet undoable; clear the undo command
        set info(undo) [list $type delete $n]

        # NEXT, notify the app.
        notifier send ::nbhood <Entity> create $n
    }

    # delete n
    #
    # n     A neighborhood short name
    #
    # Deletes the neighborhood, including all entities that depend
    # on it.
    #
    # TBD: Alternatively, we might simply forbid deleting a 
    # neighborhood that's "in use".

    typemethod delete {n} {
        # FIRST, delete it.
        rdb eval {
            DELETE FROM nbhoods WHERE n=$n
        }

        $geo delete $n

        # NEXT, recompute the obscured_by field; this nbhood might
        # have obscured some other neighborhood's refpoint.
        $type SetObscuredBy

        # NEXT, Not undoable; clear the undo command
        set info(undo) {}

        notifier send ::nbhood <Entity> delete $n
    }

    # lower n
    #
    # n     A neighborhood short name
    #
    # Sends the neighborhood to the bottom of the stacking order.

    typemethod lower {n} {
        # FIRST, reorder the neighborhoods
        set oldNames [rdb eval {
            SELECT n FROM nbhoods 
            ORDER BY stacking_order
        }]

        set names $oldNames
        ldelete names $n
        set names [linsert $names 0 $n]

        $type RestackNbhoods $names $oldNames
    }

    # raise n
    #
    # n     A neighborhood short name
    #
    # Brings the neighborhood to the top of the stacking order.

    typemethod raise {n} {
        # FIRST, reorder the neighborhoods
        set oldNames [rdb eval {
            SELECT n FROM nbhoods 
            ORDER BY stacking_order
        }]

        set names $oldNames

        ldelete names $n
        lappend names $n

        $type RestackNbhoods $names $oldNames
    }
  

    # update n parmdict
    #
    # n            A neighborhood short name
    # parmdict     A dictionary of neighborhood parms
    #
    #    longname       A new long name, or ""
    #    urbanization   A new eurbanization level, or ""
    #    refpoint       A new reference point, or ""
    #    polygon        A new polygon, or ""
    #
    # Updates a nbhood given the parms, which are presumed to be
    # valid.  When validity checks are needed, use the NBHOOD:UPDATE
    # order.

    typemethod update {n parmdict} {
        # FIRST, get the undo information
        rdb eval {
            SELECT longname, refpoint, polygon, urbanization 
            FROM nbhoods
            WHERE n=$n
        } row {
            unset row(*)
        }

        # NEXT, Update the neighborhood
        dict with parmdict {
            # FIRST, Put the neighborhood in the database
            rdb eval {
                UPDATE nbhoods
                SET longname     = nonempty($longname,     longname),
                    refpoint     = nonempty($refpoint,     refpoint),
                    polygon      = nonempty($polygon,      polygon),
                    urbanization = nonempty($urbanization, urbanization)
                WHERE n=$n
            } {}

            # NEXT, recompute the obscured_by field if necessary; this 
            # nbhood might have obscured some other neighborhood's refpoint.
            if {$polygon ne ""} {
                $type SetObscuredBy
            }
        }

        # NEXT, Not undoable; clear the undo command
        set info(undo) [mytypemethod update $n [array get row]]

        # NEXT, notify the app.
        notifier send ::nbhood <Entity> update $n
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # find mx my
    #
    # mx,my    A point in map coordinates
    #
    # Returns the short name of the neighborhood which contains the
    # coordinates, or the empty string.

    typemethod find {mx my} {
        return [$geo find [list $mx $my] nbhood]
    }

    # lastundo
    #
    # Returns the undo command for the last mutator, or "" if none.

    typemethod lastundo {} {
        return $info(undo)
    }

    # names
    #
    # Returns the list of neighborhood names

    typemethod names {} {
        set names [rdb eval {
            SELECT n FROM nbhoods 
        }]
    }


    # validate n
    #
    # n         Possibly, a neighborhood short name.
    #
    # Validates a neighborhood short name

    typemethod validate {n} {
        if {![rdb exists {SELECT n FROM nbhoods WHERE n=$n}]} {
            set names [join [nbhood names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid neighborhood, $msg"
        }

        return $n
    }

    #-------------------------------------------------------------------
    # Private Type Methods

    # RestackNbhoods new ?old?
    #
    # new      A list of all nbhood names in the desired stacking
    #          order
    # old      The previous order
    #
    # Sets the stacking_order according to the order of the names.

    typemethod RestackNbhoods {new {old ""}} {
        # FIRST, set the stacking_order
        set i 0

        foreach name $new {
            incr i

            rdb eval {
                UPDATE nbhoods
                SET stacking_order=$i
                WHERE n=$name
            }
        }

        # NEXT, refresh the geoset
        $type reconfigure
        
        # NEXT, determine who obscures who
        $type SetObscuredBy

        # NEXT, set the undo information
        set info(undo) [list $type RestackNbhoods $old]

        # NEXT, notify the GUI of the change.
        notifier send ::nbhood <Entity> stack
    }

    # SetObscuredBy
    #
    # Checks the neighborhoods for obscured reference points, and
    # sets the obscured_by field accordingly.
    #
    # TBD: This could be more efficient if it took into account
    # the neighborhood that changed and only looked at overlapping
    # neighborhoods.

    typemethod SetObscuredBy {} {
        rdb eval {
            SELECT n, refpoint, obscured_by FROM nbhoods
        } {
            set in [$geo find $refpoint nbhood]

            if {$in eq $n} {
                set in ""
            }

            if {$in ne $obscured_by} {
                rdb eval {
                    UPDATE nbhoods
                    SET obscured_by=$in
                    WHERE n=$n
                }
            }
        }
    }

}
