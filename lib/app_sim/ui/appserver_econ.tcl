#-----------------------------------------------------------------------
# TITLE:
#    appserver_econ.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Econ Model Reports
#
#    my://app/econ/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module ECON {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /econ {econ/?} \
            text/html [myproc /econ:html]          \
            "Economic model status report."
    }

    #-------------------------------------------------------------------
    # /econ/status:       Econ model status report.
    #
    # No match parameters

    # /econ/status:html udict matchArray
    #

    proc /econ:html {udict matchArray} {
        ht page "Econ Model: Status" {
            ht title "Status" "Econ"

            ht putln {
                Athena reports on the status of the economic model
                providing insight into any problems there may be if
                something is not right with it.
            }

            ht para
            
            econ report ::appserver::ht
        }

        return [ht get]
    }
}



