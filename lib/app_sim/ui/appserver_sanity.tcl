#-----------------------------------------------------------------------
# TITLE:
#    appserver_sanity.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Sanity Check Reports
#
#    my://app/sanity/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module SANITY {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /sanity/onlock {sanity/onlock/?} \
            text/html [myproc /sanity/onlock:html]          \
            "Scenario On-Lock sanity check report."

        appserver register /sanity/ontick {sanity/ontick/?} \
            text/html [myproc /sanity/ontick:html]          \
            "Simulation On-Tick sanity check report."

        appserver register /sanity/hook {sanity/hook/?} \
            text/html [myproc /sanity/hook:html]        \
            "Sanity check report for Semantic Hooks."

        appserver register /sanity/payload {sanity/payload/?} \
            text/html [myproc /sanity/payload:html]           \
            "Sanity check report for IOM Payloads."

        appserver register /sanity/strategy {sanity/strategy/?} \
            text/html [myproc /sanity/strategy:html]            \
            "Sanity check report for actor strategies."

    }

    #-------------------------------------------------------------------
    # /sanity/onlock:       On-Lock sanity check report.
    #
    # No match parameters

    # /sanity/onlock:html udict matchArray
    #
    # Formats the on-lock sanity check report for
    # /sanity/onlock.  Note that sanity is checked by the
    # "sanity onlock report" command; this command simply reports on the
    # results.

    proc /sanity/onlock:html {udict matchArray} {
        ht page "Sanity Check: On-Lock" {
            ht title "On-Lock" "Sanity Check"

            ht putln {
                Athena checks the scenario's sanity before
                allowing the user to lock the scenario and begin
                simulation.
            }

            ht para
            
            sanity onlock report ::appserver::ht
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /sanity/ontick:   On Tick sanity check report
    #
    # No match parameters

    # /sanity/ontick:html udict matchArray
    #
    # Formats the on-tick sanity check report for
    # /sanity/ontick.  Note that sanity is checked by the
    # "sanity ontick report" command; this command simply reports on the
    # results.

    proc /sanity/ontick:html {udict matchArray} {
        ht page "Sanity Check: On-Tick" {
            ht title "On-Tick" "Sanity Check"

            ht putln {
                Athena checks the scenario's sanity before
                advancing time at each time tick.
            }

            ht para

            if {[sim state] ne "PREP"} {
                sanity ontick report ::appserver::ht
            } else {
                ht putln {
                    This check cannot be performed until after the scenario
                    is locked.
                }

                ht para
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /sanity/hook:   Hook sanity checks
    #
    # No match parameters

    # /sanity/hook:html udict matchArray
    #
    # Formats the semantic hook sanity check report for
    # /sanity/hook.  Note that sanity is checked by the 
    # "hook sanity report" command; this command simply reports on the
    # results.

    proc /sanity/hook:html {udict matchArray} {
        ht page "Sanity Check: Semantic Hook Topics" {
            ht title "Semantic Hooks" "Sanity Check"

            hook sanity report ::appserver::ht
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /sanity/payload: Payload sanity check reports
    #
    # No match parameters

    # /sanity/payload:html udict matchArray
    #
    # Formats the payload sanity check report for
    # /sanity/payload.  Note that sanity is checked by the
    # "payload sanity report" command; this command simply reports on the
    # results.

    proc /sanity/payload:html {udict matchArray} {
        ht page "Sanity Check: IOM Payloads" {
            ht title "IOM Payloads" "Sanity Check"
            
            payload sanity report ::appserver::ht
        }

        return [ht get]
    }


    #-------------------------------------------------------------------
    # /sanity/strategy:  Strategy Sanity Check reports
    #
    # No match parameters

    # /sanity/strategy:html udict matchArray
    #
    # Formats the strategy sanity check report for
    # /sanity/strategy.  Note that sanity is checked by the
    # "strategy sanity report" command; this command simply reports on the
    # results.

    proc /sanity/strategy:html {udict matchArray} {
        ht page "Sanity Check: Actor's Strategies" {
            ht title "Actor's Strategies" "Sanity Check"
            
            strategy sanity report ::appserver::ht
        }

        return [ht get]
    }
}



