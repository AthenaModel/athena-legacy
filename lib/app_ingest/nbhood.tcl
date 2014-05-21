#-----------------------------------------------------------------------
# TITLE:
#    nbhood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Neighborhood Manager
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
    # Initialization

    typemethod init {} {
        # FIRST, create the geoset
        set geo [geoset ${type}::geo]
    }

    #-------------------------------------------------------------------
    # Notifier Event Handlers

    # dbsync
    #
    # Refreshes the geoset with the current neighborhood data from
    # the database.
    
    typemethod dbsync {} {
        # FIRST, populate the geoset
        $geo clear

        adb eval {
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
    # Delegated methods

    delegate typemethod bbox to geo

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

    # randloc n
    #
    # n       A neighborhood short name
    #
    # Tries to get a random location from the neighborhood.
    # If it fails after ten tries, returns the neighborhood's 
    # reference point.

    typemethod randloc {n} {
        # FIRST, get the neighborhood polygon's bounding box
        foreach {x1 y1 x2 y2} [$geo bbox $n] {}

        # NEXT, no more than 10 tries
        for {set i 0} {$i < 10} {incr i} {
            # Get a random lat/lon
            let x {($x2 - $x1)*rand() + $x1}
            let y {($y2 - $y1)*rand() + $y1}

            # Is it in the neighborhood (taking stacking order
            # into account)?
            set pt [list $x $y]

            if {[geo find $pt] eq $n} {
                return $pt
            }
        }

        # Didn't find one; just return the refpoint.
        return [adb onecolumn {
            SELECT refpoint FROM nbhoods
            WHERE n=$n
        }]
    }

    # names
    #
    # Returns the list of neighborhood names

    typemethod names {} {
        return [adb eval {
            SELECT n FROM nbhoods ORDER BY n
        }]
    }

    # namedict
    #
    # Returns ID/longname dictionary

    typemethod namedict {} {
        return [adb eval {
            SELECT n, longname FROM nbhoods ORDER BY n
        }]
    }

    # validate n
    #
    # n         Possibly, a neighborhood short name.
    #
    # Validates a neighborhood short name

    typemethod validate {n} {
        if {![adb exists {SELECT n FROM nbhoods WHERE n=$n}]} {
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

    # local names
    #
    # Returns the list of nbhoods that have the local flag set

    typemethod {local names} {} {
        return [adb eval {
            SELECT n FROM local_nbhoods ORDER BY n
        }]
    }

    # local namedict
    #
    # Returns ID/longname dictionary for local nbhoods

    typemethod {local namedict} {} {
        return [adb eval {
            SELECT n, longname FROM local_nbhoods ORDER BY n
        }]
    }

    # local validate n
    #
    # n    Possibly, a local nbhood short name
    #
    # Validates a local nbhood short name

    typemethod {local validate} {n} {
        if {![adb exists {SELECT n FROM local_nbhoods WHERE n=$n}]} {
            set names [join [nbhood local names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid local neighborhood, $msg"
        }

        return $n
    }

    #-------------------------------------------------------------------
    # Private Type Methods

    # SetObscuredBy
    #
    # Checks the neighborhoods for obscured reference points, and
    # sets the obscured_by field accordingly.
    #
    # TBD: This could be more efficient if it took into account
    # the neighborhood that changed and only looked at overlapping
    # neighborhoods.

    typemethod SetObscuredBy {} {
        adb eval {
            SELECT n, refpoint, obscured_by FROM nbhoods
        } {
            set in [$geo find $refpoint nbhood]

            if {$in eq $n} {
                set in ""
            }

            if {$in ne $obscured_by} {
                adb eval {
                    UPDATE nbhoods
                    SET obscured_by=$in
                    WHERE n=$n
                }
            }
        }
    }
}





