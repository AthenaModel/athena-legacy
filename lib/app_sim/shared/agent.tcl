#-----------------------------------------------------------------------
# TITLE:
#    agent.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Agent Manager
#
#    This module is responsible for managing agents and operations
#    upon them.  An agent is an entity that can own and execute a
#    strategy, i.e., can have goals, tactics, and conditions.
#
#-----------------------------------------------------------------------

snit::type agent {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of agent names

    typemethod names {} {
        set names [rdb eval {
            SELECT agent_id FROM agents
        }]
    }


    # validate agent_id
    #
    # agent_id - Possibly, an agent short name.
    #
    # Validates an agent ID

    typemethod validate {agent_id} {
        set names [$type names]

        if {$agent_id ni $names} {
            set nameString [join $names ", "]

            if {$nameString ne ""} {
                set msg "should be one of: $nameString"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid agent, $msg"
        }

        return $agent_id
    }

    # system names
    #
    # Returns the list of system agent names

    typemethod {system names} {} {
        set names [rdb eval {
            SELECT agent_id FROM agents WHERE agent_type = 'system'
        }]
    }


    # system validate agent_id
    #
    # agent_id - Possibly, a system agent short name.
    #
    # Validates a system agent ID

    typemethod {system validate} {agent_id} {
        set names [$type system names]

        if {$agent_id ni $names} {
            set nameString [join $names ", "]

            if {$nameString ne ""} {
                set msg "should be one of: $nameString"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid system agent, $msg"
        }

        return $agent_id
    }

    # type agent_id
    #
    # agent_id - An agent short name
    #
    # Retrieves the type of the agent, or ""

    typemethod type {agent_id} {
        rdb eval {SELECT agent_type FROM agents WHERE agent_id=$agent_id}
    }
}


