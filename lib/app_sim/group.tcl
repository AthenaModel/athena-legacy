#-----------------------------------------------------------------------
# TITLE:
#    group.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Group Manager
#
#    This module is responsible for managing groups in general.
#    Most of the relevant code is in the frcgroup, orggroup, civgroup,
#    and nbgroup modules; this is just a few things that apply to all.
#
#-----------------------------------------------------------------------

snit::type group {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # TBD

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail group "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module's in-memory data from the database.
    
    typemethod reconfigure {} {
        # Nothing to do
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of neighborhood names

    typemethod names {} {
        set names [rdb eval {
            SELECT g FROM groups 
        }]
    }


    # validate g
    #
    # g         Possibly, a group short name.
    #
    # Validates a group short name

    typemethod validate {g} {
        if {![rdb exists {SELECT g FROM groups WHERE g=$g}]} {
            set names [join [group names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid group, $msg"
        }

        return $g
    }

    # gtype g
    #
    # g       A group short name
    #
    # Returns the group's type, CIV, ORG, or FRC.

    typemethod gtype {g} {
        return [rdb onecolumn {
            SELECT gtype FROM groups WHERE g=$g
        }]
    }

}





