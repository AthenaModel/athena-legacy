#-----------------------------------------------------------------------
# TITLE:
#    appserver_mads.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Magic Attitude Drivers
#
#    my://app/mads/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module MADS {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /mads {mads/?}     \
            tcl/linkdict [myproc /mads:linkdict] \
            text/html    [myproc /mads:html]     {
                A table displaying all of the magic attitude drivers.
            }

        appserver register /mad/{id} {mad/(\w+)/?} \
            text/html [myproc /mad:html]            \
            "Detail page for magic attitude driver {id}."
    }

    #-------------------------------------------------------------------
    # /mads:          All defined MADs
    #
    # Match Parameters:  None


    # /mads:linkdict udict matchArray
    #
    # tcl/linkdict of all mads.
    
    proc /mads:linkdict {udict matchArray} {
        return [objects:linkdict {
            label    "MADs"
            listIcon ::projectgui::icon::blueheart12
            table    gui_mads
        }]
    }

    # /mads:html udict matchArray
    #
    # Tabular display of MAD data; content depends on simulation state.

    proc /mads:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page.
        ht page "Magic Attitude Drivers"
        ht title "Magic Attitude Drivers"

        ht putln "The scenario includes the following MADs:"
        ht para

        ht query {
            SELECT link             AS "ID",
                   longlink         AS "Narrative",
                   cause            AS "Cause",
                   s                AS "Here",
                   p                AS "Near",
                   q                AS "Far",
                   count(firing_id) AS "Inputs"
            FROM gui_mads
            LEFT OUTER JOIN rule_firings USING (driver_id)
            GROUP BY mad_id
        } -default "None." -align LLLRRRR

        ht /page

        return [ht get]
    }


    #-------------------------------------------------------------------
    # /mad/{id}: A single mad {id}
    #
    # Match Parameters:
    #
    # {id} => $(1)    - The mad's ID

    # /mad:html udict matchArray
    #
    # Detail page for a single mad {id}

    proc /mad:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Accumulate data
        set id $(1)

        if {![rdb exists {SELECT * FROM mads WHERE mad_id=$id}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        # Begin the page
        rdb eval {SELECT * FROM gui_mads WHERE mad_id=$id} data {}

        ht page "Magic Attitude Driver: $id"
        ht title $data(fancy) "MAD" 

        ht putln "TBD: The following magic inputs have been made."
        ht /page

        return [ht get]
    }
}




