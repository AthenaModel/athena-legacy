#-----------------------------------------------------------------------
# TITLE:
#    appserver_agent.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Agent Strategies
#
#    my://app/agents
#    my://app/agent/{agent}
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module AGENT {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /agents {agents/?}         \
            tcl/linkdict [myproc /agents:linkdict]    \
            tcl/enumlist [asproc enum:enumlist agent] \
            text/html    [myproc /agents:html] {
                Links to all of the currently 
                defined agents.  HTML content 
                includes agent attributes.
            }

        # TBD: We'll put this back in the /sanity tree eventually
        appserver register /agents/sanity {agents/sanity/?} \
            text/html [myproc /agents/sanity:html]            \
            "Sanity check report for agent strategies."

        appserver register /agent/{agent} {agent/(\w+)/?} \
            text/html [myproc /agent:html]            \
            "Detail page for agent {agent}'s strategy."

    }



    #-------------------------------------------------------------------
    # /agents: All defined agents
    #
    # No match parameters

    # /agents:linkdict udict matchArray
    #
    # tcl/linkdict of all agents.
    
    proc /agents:linkdict {udict matchArray} {
        return [objects:linkdict {
            label    "Agents"
            listIcon ::projectgui::icon::actor12
            table    gui_agents
        }]
    }

    # /agents:html udict matchArray
    #
    # Tabular display of agent data; content depends on 
    # simulation state.

    proc /agents:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Agents"
        ht title "Agents"

        ht putln "The scenario currently includes the following agents:"
        ht para

        ht query {
            SELECT link          AS "Agent",
                   agent_type    AS "Type"
            FROM gui_agents
        } -default "None." -align LL

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /agent/{agent}: A single {agent}'s strategy
    #
    # Match Parameters:
    #
    # {agent} => $(1)    - The agent's short name

    # /agent:html udict matchArray
    #
    # Detail page for a single agent's strategy

    proc /agent:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Accumulate data
        set a [string toupper $(1)]

        if {$a ni [agent names]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        set s ::strategy::$a

        # Begin the page
        rdb eval {SELECT * FROM gui_agents WHERE agent_id=$a} data {}

        ht page "Agent: $a ($data(agent_type))"
        ht title "Agent: $a ($data(agent_type))" 

        if {$data(agent_type) eq "actor"} {
            ht putln "Agent $a is an actor; click "
            ht link [rdb onecolumn {
                SELECT url FROM gui_actors
                WHERE a=$a
            }] here
            ht put " for the actor data."
            ht para
        }

        set nblocks [llength [$s blocks]]
        if {$nblocks > 0} {
            ht putln "Agent $a's strategy contains the following $nblocks blocks,"
            ht putln "in priority order."
        } else {
            ht putln "Agent $a's strategy is empty."
        }
        ht para

        foreach block [$s blocks] {
            ht hr
            $block html $ht
        }


        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /agents/sanity:  Strategy Sanity Check reports
    #
    # No match parameters

    # /agents/sanity:html udict matchArray
    #
    # Formats the strategy sanity check report for
    # /agents/sanity.  Note that sanity is checked by the
    # "strategy checker" command; this command simply reports on the
    # results.

    proc /agents/sanity:html {udict matchArray} {
        ht page "Sanity Check: Agents' Strategies" {
            ht title "Agents' Strategies" "Sanity Check"
            
            if {[strategy checker ::appserver::ht] eq "OK"} {
                ht putln "No problems were found."
                ht para
            }
        }

        return [ht get]
    }
}
