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
        appserver register /drivers {drivers/?} \
            text/html [myproc /drivers:html] {
                A table displaying all of the attitude drivers to date.
            }

        appserver register /drivers/{subset} {drivers/(\w+)/?} \
            text/html [myproc /drivers:html] {
                A table displaying all of the attitude drivers in the
                specified subset: "active", "inactive", "empty".
            }

    }

    #-------------------------------------------------------------------
    # /drivers:           All defined drivers
    # /drivers/{subset}:  A particular subset of drivers
    #
    # Match Parameters:
    #
    # {subset} ==> $(1)     - Driver subset (optional)


    # /drivers:html udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches.
    #
    # Matches:
    #   $(1) - The drivers subset: active, empty, or "" 
    #          for all.
    #
    # Returns a page that documents the current attitude
    # drivers.

    proc /drivers:html {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the driver state
        if {$(1) eq ""} {
            set state "all"
        } else {
            set state $(1)
        }

        # NEXT, set the page title
        ht page "Attitude Drivers ($state)"
        ht title "Attitude Drivers ($state)"

        ht putln "The following drivers are affecting or have affected"
        ht putln "attitudes in the playbox."
        ht para

        # NEXT, get summary statistics
        rdb eval {
            DROP VIEW IF EXISTS temp_report_driver_view;
            DROP TABLE IF EXISTS temp_report_driver_contribs;

            CREATE TEMPORARY TABLE temp_report_driver_contribs AS
            SELECT driver_id, 
                   CASE WHEN min(t) IS NULL 
                        THEN 0
                        ELSE 1 END                  AS has_contribs,
                   CASE WHEN min(t) NOT NULL    
                        THEN tozulu(min(t)) 
                        ELSE '' END                 AS ts,
                   CASE WHEN max(t) NOT NULL    
                        THEN tozulu(max(t)) 
                        ELSE '' END                 AS te
            FROM drivers LEFT OUTER JOIN ucurve_contribs_t USING (driver_id)
            GROUP BY driver_id;

            CREATE TEMPORARY VIEW temp_report_driver_view AS
            SELECT drivers.driver_id AS driver_id, 
                   dtype, 
                   narrative,
                   CASE WHEN has_contribs THEN 'active'
                        ELSE 'empty'
                        END AS state,
                   ts,
                   te
            FROM drivers
            JOIN temp_report_driver_contribs USING (driver_id)
            ORDER BY driver_id DESC;
        }

        # NEXT, produce the query.
        set query {
            SELECT driver_id   AS "Driver",
                   dtype       AS "Type",
                   narrative   AS "Narrative",
                   state       AS "State",
                   ts          AS "Start Time",
                   te          AS "End Time"
            FROM temp_report_driver_view
        }

        if {$state ne "all"} {
            append query "WHERE state = '$state'"
        }

        # NEXT, generate the report text
        ht query $query \
            -default "No drivers found." \
            -align   RLLLLL

        rdb eval {
            DROP VIEW  temp_report_driver_view;
            DROP TABLE temp_report_driver_contribs;
        }

        ht /page

        return [ht get]
    }
}



