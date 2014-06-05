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

    # names
    #
    # Returns the list of neighborhood names

    typemethod names {} {
        return [adb eval {
            SELECT n FROM nbhoods ORDER BY n
        }]
    }

    # fullname n
    #
    # Returns the full name of the neighborhood: "$longname ($n)"

    typemethod fullname {n} {
        return "[$type get $n longname] ($n)"
    }

    # get n ?parm?
    #
    # n  - A neighborhood ID
    #
    # Returns the neighborhood's data dictionary; or the specific
    # parameter, if given.

    typemethod get {n {parm ""}} {
        # FIRST, get the data
        adb eval {SELECT * FROM nbhoods WHERE n=$n} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
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
}





