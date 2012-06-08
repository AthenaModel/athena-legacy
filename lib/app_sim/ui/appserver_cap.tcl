#-----------------------------------------------------------------------
# TITLE:
#    appserver_cap.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: CAPs
#
#    my://app/caps
#    my://app/cap/{k}
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module CAP {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /caps/ {caps/?} \
            tcl/linkdict [myproc /caps:linkdict] \
            text/html    [myproc /caps:html] {
                Links to all of the currently defined CAPs. HTML
                content includes CAP attributes.
            }

        appserver register /cap/{k} {cap/(\w+)/?} \
            text/html [myproc /cap:html]         \
            "Detail page for CAP {k}."
    }

    #-------------------------------------------------------------------
    # /caps: All defined caps
    #
    # No match parameters

    # /caps:linkdict udict matchArray
    #
    # tcl/linkdict of all caps.
    
    proc /caps:linkdict {udict matchArray} {
        return [objects:linkdict {
            label    "CAPs"
            listIcon ::projectgui::icon::cap12
            table    gui_caps
        }]
    }

    # /caps:html udict matchArray
    #
    # Tabular display of CAP data.

    proc /caps:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "CAPs"
        ht title "Communication Asset Packages (CAPs)"

        ht put "The scenario currently includes the following "
        ht put "Communication Asset Packages (CAPs):"
        ht para

        ht query {
            SELECT longlink      AS "Name",
                   owner         AS "Owner",
                   capacity      AS "Capacity",
                   cost          AS "Cost, $"
            FROM gui_caps
        } -default "None." -align LLRR

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /cap/{k}: A single cap {k}
    #
    # Match Parameters:
    #
    # {k} => $(1)    - The cap's short name

    # /cap:html udict matchArray
    #
    # Detail page for a single cap {k}

    proc /cap:html {udict matchArray} {
        upvar 1 $matchArray ""
       
        # FIRST, get the CAP name and data.
        set k [string toupper $(1)]

        rdb eval {SELECT * FROM gui_caps WHERE k=$k} data {}

        # NEXT, Begin the page
        ht page "CAP: $k"
        ht title $data(fancy) "CAP" 

        ht linkbar {
            "#capcov"    "CAP Coverage"
            "#sigevents" "Significant Events"
        }
 
        ht subtitle "CAP Coverage" capcov
        rdb eval {SELECT longname, capacity, cost FROM caps WHERE k=$k} data {}

        ht put "$data(fancy) has a capacity of $data(capacity) and a "
        ht put "cost of $data(cost) dollars. " 
        ht put "CAP Coverage is the product of capacity, neighborhood "
        ht put "coverage and group penetration."
        ht para

        ht put "Below is this CAP's coverage for each neighborhood "
        ht put "and group. Combinations where group penetration is "
        ht put "zero <b>and</b> neighborhood coverage is zero are "
        ht put "omitted."
        
        ht para

        ht query {
            SELECT nlink                       AS "Neighborhood",
                   glink                       AS "Group",
                   nbcov                       AS "Nbhood Coverage",
                   pen                         AS "Group Penetration",
                   "<b>" || capcov || "</b>"   AS "CAP Coverage"
            FROM gui_capcov WHERE k=$k AND (raw_pen > 0.0 OR raw_nbcov > 0.0)
            ORDER BY n
        } -default "None." -align LLRRR
        
        
        ht subtitle "Significant Events" sigevents

        if {[locked -disclaimer]} {
            ht putln "
                The following are the most recent significant events 
                involving this CAP, oldest first.
            "

            ht para
            
            sigevents -tags $k -mark run
        }

        ht /page

        return [ht get]
    }
}



