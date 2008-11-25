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
    
    # TBD

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
    }

    #-------------------------------------------------------------------
    # Public Typemethods

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

        # TBD: Delete dependent entities, or clear the nbhood field.

        # NEXT, recompute the obscured_by field; this nbhood might
        # have obscured some other neighborhood's refpoint.
        $type SetObscuredBy

        notifier send ::nbhood <Entity> delete $n
    }

    # find mx my
    #
    # mx,my    A point in map coordinates
    #
    # Returns the short name of the neighborhood which contains the
    # coordinates, or the empty string.

    typemethod find {mx my} {
        return [$geo find [list $mx $my] nbhood]
    }

    # lower n
    #
    # n     A neighborhood short name
    #
    # Sends the neighborhood to the bottom of the stacking order.

    typemethod lower {n} {
        # FIRST, reorder the neighborhoods
        set names [rdb eval {
            SELECT n FROM nbhoods 
            ORDER BY stacking_order
        }]

        ldelete names $n
        set names [linsert $names 0 $n]

        $type ReorderNbhoods $names

        # NEXT, recompute the obscured_by field; this nbhood might
        # have obscured some other neighborhood's refpoint.
        $type SetObscuredBy

        notifier send ::nbhood <Entity> lower $n
    }

    # names
    #
    # Returns the list of neighborhood names

    typemethod names {} {
        set names [rdb eval {
            SELECT n FROM nbhoods 
        }]
    }

    # raise n
    #
    # n     A neighborhood short name
    #
    # Brings the neighborhood to the top of the stacking order.

    typemethod raise {n} {
        # FIRST, reorder the neighborhoods
        set names [rdb eval {
            SELECT n FROM nbhoods 
            ORDER BY stacking_order
        }]

        ldelete names $n
        lappend names $n

        $type ReorderNbhoods $names

        # NEXT, recompute the obscured_by field; this nbhood might
        # have obscured some other neighborhood's refpoint.
        $type SetObscuredBy

        notifier send ::nbhood <Entity> raise $n
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

        # NEXT, notify the app.
        notifier send ::nbhood <Entity> update $n
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

    # ReorderNbhoods names
    #
    # names      A list of all nbhood names in the desired stacking
    #            order
    #
    # Sets the stacking_order according to the order of the names.

    typemethod ReorderNbhoods {names} {
        set i 0

        foreach name $names {
            incr i

            rdb eval {
                UPDATE nbhoods
                SET stacking_order=$i
                WHERE n=$name
            }
        }

        $type reconfigure
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
