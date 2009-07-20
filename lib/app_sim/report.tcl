#-----------------------------------------------------------------------
# TITLE:
#    report.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Report Manager
#
#    This module wraps reporter(n), and integrates it into the app.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# report

snit::type report {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Components

    typecomponent reporter  ;# For delegation to reporter(n).

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        enum edriverstate { 
            all       "All Drivers"
            active    "Active Drivers"
            inactive  "Inactive Drivers"
            empty     "Empty Drivers"
        }
    }

    #-------------------------------------------------------------------
    # Initialization
    
    typemethod init {} {
        log normal report "Initializing"

        # FIRST, support delegation to reporter(n)
        set reporter ::projectlib::reporter

        # NEXT, configure the reporter
        reporter configure \
            -db        ::rdb                                \
            -clock     ::simclock                           \
            -deletecmd [list notifier send $type <Delete>]  \
            -reportcmd [list notifier send $type <Report>]

        # NEXT, define the bins.

        reporter bin define all "All Reports" "" {
            SELECT * FROM reports
        }

        reporter bin define requested "Requested" "" {
            SELECT * FROM reports WHERE requested=1
        }

        reporter bin define hotlist "Hot List" "" {
            SELECT * FROM reports WHERE hotlist=1
        }

        reporter bin define gram "Attitudes" "" {
            SELECT * FROM reports WHERE rtype='GRAM'
        }

        reporter bin define gram_driver "Drivers" gram {
            SELECT * FROM REPORTS WHERE rtype='GRAM' AND subtype='DRIVER'
        }

        reporter bin define dam "DAM Rule Firings" "" {
            SELECT * FROM reports WHERE rtype='DAM'
        }

        set count 0
        foreach ruleset [edamruleset names] {
            set bin "dam[incr count]"

            reporter bin define $bin $ruleset dam "
                SELECT * FROM reports WHERE rtype='DAM' AND subtype='$ruleset'
            "
        }
    }

    #-------------------------------------------------------------------
    # Report Implementations
    #
    # Each of these methods is a mutator, in that it adds a report to
    # the RDB, and returns an undo script.

    # imp driver state
    #
    # state    empty|inactive|active|all
    #
    # Produces a report of all GRAM drivers that are active, inactive, etc.,
    # or all drivers.
    #
    # TBD: GRAM should probably keep some of these statistics 
    # automatically.

    typemethod {imp driver} {state} {
        # FIRST, produce the query.
        if {$state eq "all"} {
            set clause ""
        } else {
            set clause "HAVING state = '$state'"
        }

        set query "
            SELECT driver, 
                   dtype, 
                   name, 
                   oneliner,
                   CASE WHEN min(ts) IS NULL     THEN 'empty'
                        WHEN total(active) = 0   THEN 'inactive'
                                                 ELSE 'active'   END AS state,
                   CASE WHEN min(ts) NOT NULL    THEN tozulu(min(ts)) 
                                                 ELSE '' END,
                   CASE WHEN max(te) IS NULL     THEN ''
                        WHEN max(te) != 99999999 THEN tozulu(max(te)) 
                                                 ELSE 'On-going' END
            FROM gram_driver
            LEFT OUTER JOIN gram_effects USING (driver)
            GROUP BY driver
            $clause
            ORDER BY driver DESC;
        "

        # NEXT, generate the report text
        set text [rdb query $query -labels {
            "ID" "Type" "Name" "Description" "State" "Start Time" "End Time"
        }]

        if {$text eq ""} {
            set text "No drivers found."
        }

        set id [reporter save \
                    -title     "Attitude Drivers ($state)"  \
                    -text      $text                        \
                    -requested 1                            \
                    -type      GRAM                         \
                    -subtype   DRIVER]

        return [list reporter delete $id]
    }


    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod save to reporter
}


#-----------------------------------------------------------------------
# Orders

# REPORT:DRIVER
#
# Produces an Attitude Driver Report.

order define ::report REPORT:DRIVER {
    title "Attitude Driver Report"
    options \
        -sendstates {PREP PAUSED RUNNING} \
        -alwaysunsaved

    parm state enum  "Driver State"  -type {::report::edriverstate} \
        -defval active
} {
    # FIRST, prepare the parameters
    prepare state      -toupper -required -type {::report::edriverstate}

    returnOnError

    # NEXT, produce the report
    set undo [list]
    lappend undo [$type imp driver $parms(state)]

    setundo [join $undo \n]
}







