#-----------------------------------------------------------------------
# TITLE:
#    appserver_bean.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Beans
#
#    my://app/bean/{id}
#
#    Each bean class can provide an "html" method which produces 
#    content.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module BEAN {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /bean/{id} {bean/(\w+)/?} \
            text/html [myproc /bean:html]            \
            "Detail page for bean {id}."
    }

    #-------------------------------------------------------------------
    # /bean/{id}: A single bean {id}
    #
    # Match Parameters:
    #
    # {id} => $(1)    - The bean's id

    # /bean:html udict matchArray
    #
    # Detail page for a single bean {id}

    proc /bean:html {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, is there a bean with this id?
        set id [string toupper $(1)]

        if {![bean exists $id]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        set bean [bean get $id]

        # NEXT, does it have an "html" method?
        if {"html" ni [info object methods $bean -all]} {
            ht page "Bean $id" {
                ht title "Bean $id"

                ht putln "No information available"
            }
        } else {
            ht page "Bean $id" {
                $bean html ::appserver::ht
            }
        }

        return [ht get]
    }
}