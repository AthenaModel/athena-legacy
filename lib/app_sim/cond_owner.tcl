#-----------------------------------------------------------------------
# TITLE:
#    cond_owner.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Condition Owner Manager
#
#    A cond_owner is an entity (a goal or tactic) that can own
#    conditions.  This module exists only to validate cond_collections in
#    the condition orders.
#-----------------------------------------------------------------------

snit::type cond_owner {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of cond_owner ids

    typemethod names {} {
        set names [rdb eval {
            SELECT cc_id FROM cond_collections ORDER BY cc_id
        }]
    }


    # validate id
    #
    # id - Possibly, a cond_owner ID
    #
    # Validates a cond_owner ID

    typemethod validate {id} {
        set ids [$type names]

        if {$id ni $ids} {
            return -code error -errorcode INVALID \
                "Invalid goal or tactic ID: \"$id\""
        }

        return $id
    }
}



