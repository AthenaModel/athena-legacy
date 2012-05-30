#-----------------------------------------------------------------------
# TITLE:
#    appserver_sigevents.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Significant Events
#
#    my://app/image/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module SIGEVENTS {
    #-------------------------------------------------------------------
    # Type Variables

    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /sigevents {sigevents/?} \
            text/html [myproc /sigevents:html] {
                Significant simulation events occuring during the
                past game turn (i.e., since the Run Simulation button
                was last pressed.)
            }

        appserver register /sigevents/all {sigevents/(all)/?} \
            text/html [myproc /sigevents:html] {
                Significant simulation events occuring since the
                scenario was locked.
            }
    }




    #-------------------------------------------------------------------
    # /sigevents                 - Significant Simulation Events
    # /sigevents/{subset}
    #
    # Match Parameters
    #
    # {subset} ==> $(1)   - Event subset: all or ""

    # /sigevents:html udict matchArray
    #
    # Returns a text/html of significant events.

    proc /sigevents:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        if {$(1) eq "all"} {
            ht page "Significant Events: All"
            ht title "Significant Events: All"

            ht linkbar {
                /sigevents "Events Since Last Advance"
            }

            ht putln {
                The following significant simulation events have
                occurred since the scenario was locked.  Newer events
                are listed first.
            }

            set opts -desc
        } else {
            ht page "Significant Events: Last Advance"
            ht title "Significant Events: Last Advance"

            ht linkbar {
                /sigevents/all "All Significant Events"
            }

            ht putln {
                The following signficant events occurred during the previous
                time advance.
            }

            set opts [list -mark run]
        }

        ht para

        sigevents {*}$opts

        ht /page
        
        return [ht get]
    }

}



