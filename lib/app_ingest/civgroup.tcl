#-----------------------------------------------------------------------
# TITLE:
#    civgroup.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_ingest(1): Civilian Group Manager
#
#    This module is responsible for managing civilian groups and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type civgroup {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of civgroup names

    typemethod names {} {
        return [adb eval {
            SELECT g FROM civgroups_view
        }]
    }


    # namedict
    #
    # Returns ID/longname dictionary

    typemethod namedict {} {
        return [adb eval {
            SELECT g, longname FROM civgroups_view ORDER BY g
        }]
    }

    # validate g
    #
    # g         Possibly, a civilian group short name.
    #
    # Validates a civilian group short name

    typemethod validate {g} {
        if {![adb exists {SELECT g FROM civgroups_view WHERE g=$g}]} {
            set names [join [civgroup names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid civilian group, $msg"
        }

        return $g
    }

    # gIn n
    #
    # n      A neighborhood ID
    #
    # Returns a list of the civ groups that reside in the neighborhood.

    typemethod gIn {n} {
        adb eval {
            SELECT g FROM civgroups_view WHERE n=$n
            ORDER BY g
        }
    }



    # Type Method: get
    #
    # Retrieves a row dictionary, or a particular column value, from
    # civgroups.
    #
    # Syntax:
    #   get _g ?parm?_
    #
    #   g    - A group in the neighborhood
    #   parm - A civgroups column name

    typemethod get {g {parm ""}} {
        # FIRST, get the data
        adb eval {SELECT * FROM civgroups_view WHERE g=$g} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }
}


