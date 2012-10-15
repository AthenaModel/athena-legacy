#-----------------------------------------------------------------------
# TITLE:
#    appserver_drivers.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Attitude Drivers
#
#    my://app/drivers/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module DRIVERS {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /drivers {drivers/?}     \
            tcl/linkdict [myproc /drivers:linkdict] \
            text/html    [myproc /drivers:html]     {
                A table displaying all of the attitude drivers to date.
            }

        appserver register /drivers/{dtype} {drivers/(\w+)/?} \
            text/html [myproc /drivers:html] {
                A table displaying all of the attitude drivers of
                the specified type.
            }

    }

    #-------------------------------------------------------------------
    # /drivers:          All defined drivers
    # /drivers/{dtype}:  Drivers of a particular type 
    #
    # Match Parameters:
    #
    # {dtype} ==> $(1)     - Driver type (optional)


    # /drivers:linkdict udict matcharray
    #
    # Returns a /drivers resource as a tcl/linkdict.  Only driver
    # types with inputs are included.  Does not handle
    # subsets or queries.

    proc /drivers:linkdict {udict matchArray} {
        set result [dict create]

        rdb eval {
            SELECT dtype FROM drivers
            WHERE inputs > 0
            GROUP BY dtype
            ORDER BY dtype
        } {
            set url /drivers/$dtype

            dict set result $url label $dtype
            dict set result $url listIcon ::projectgui::icon::blackheart12
        }

        return $result
    }

    # /drivers:html udict matchArray
    #
    # Returns a page that lists the current attitude
    # drivers, possibly by driver type.

    proc /drivers:html {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the driver state
        set dtype [string trim [string toupper $(1)]]

        if {$dtype ne ""} {
            if {$dtype ni [edamruleset names]} {
                throw NOTFOUND "Unknown driver type: \"$dtype\""
            }

            set label $dtype
        } else {
            set label "All"
        }

        # NEXT, set the page title
        ht page "Attitude Drivers ($label)"
        ht title "Attitude Drivers ($label)"

        # NEXT, get summary statistics
        rdb eval {
            DROP VIEW IF EXISTS temp_report_driver_view;
            DROP TABLE IF EXISTS temp_report_driver_contribs;

            CREATE TEMPORARY TABLE temp_report_driver_contribs AS
            SELECT driver_id, 
                   CASE WHEN min(t) NOT NULL    
                        THEN timestr(min(t)) 
                        ELSE '' END                 AS ts,
                   CASE WHEN max(t) NOT NULL    
                        THEN timestr(max(t)) 
                        ELSE '' END                 AS te
            FROM drivers LEFT OUTER JOIN ucurve_contribs_t USING (driver_id)
            GROUP BY driver_id;

            CREATE TEMPORARY VIEW temp_report_driver_view AS
            SELECT drivers.driver_id AS driver_id, 
                   dtype, 
                   narrative,
                   inputs,
                   ts,
                   te
            FROM drivers
            JOIN temp_report_driver_contribs USING (driver_id);
        }

        # NEXT, produce the query.
        set query {
            SELECT driver_id   AS "Driver",
                   dtype       AS "Type",
                   narrative   AS "Narrative",
                   inputs      AS "No. of Inputs",
                   ts          AS "Start Time",
                   te          AS "End Time"
            FROM temp_report_driver_view
        }

        if {$dtype ne ""} {
            append query "WHERE dtype=\$dtype\n"
        }

        append query "ORDER BY driver_id ASC"

        # NEXT, generate the report text
        ht query $query \
            -default "No drivers found." \
            -align   RLLRLL

        rdb eval {
            DROP VIEW  temp_report_driver_view;
            DROP TABLE temp_report_driver_contribs;
        }

        ht /page

        return [ht get]
    }
}




