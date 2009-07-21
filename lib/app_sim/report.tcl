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
#    It also defines a number of specific reports.
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

        reporter bin define gram_sat "Satisfaction" gram {
            SELECT * FROM REPORTS WHERE rtype='GRAM' AND subtype='SAT'
        }

        reporter bin define civ "Civilian" "" {
            SELECT * FROM reports WHERE meta1='CIV'
        }

        reporter bin define civ_sat "Satisfaction" civ {
            SELECT * FROM REPORTS WHERE meta1='CIV' AND subtype='SAT'
        }

        reporter bin define org "Organization" "" {
            SELECT * FROM reports WHERE meta1='ORG'
        }

        reporter bin define org_sat "Satisfaction" org {
            SELECT * FROM REPORTS WHERE meta1='ORG' AND subtype='SAT'
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

    # imp sat gtype n g
    #
    # gtype   Group type, CIV or ORG
    # n       Neighborhood, or "ALL"
    # g       Group, or "ALL"
    #
    # Generates a detailed report of group satisfaction, including mood
    # and deltas from time 0.

    typemethod {imp sat} {gtype n g} {
        # FIRST, CIV or ORG
        if {$gtype eq "CIV"} {
            set title "Civilian Satisfaction"
        } elseif {$gtype eq "ORG"} {
            set title "Organization Satisfaction"
        } else {
            error "Expected CIV or ORG group type, got:\"$gtype\""
        }

        # NEXT, Determine the effects of the arguments.
        set modifiers [list]

        if {$g ne "ALL"} {
            set andGroup "AND g='$g'"

            lappend modifiers "of $g"
        } else {
            set andGroup ""
        }

        if {$n ne "ALL"} {
            set andNbhood "AND n='$n'"

            lappend modifiers "in $n"
        } else {
            set andNbhood ""
        }

        if {[llength $modifiers] > 0} {
            set title "$title ([join $modifiers { }])"
        }

        # NEXT, we need to accumulate the desired data.  Create a 
        # temporary table to contain it.
        rdb eval {
            DROP TABLE IF EXISTS temp_sat_report_table;
            CREATE TEMP TABLE temp_sat_report_table (
                 n, g, c, sat, delta, sat0
            );
        }

        # NEXT, If we're spanning neighborhoods, include the playbox data.

        if {$n eq "ALL"} {
            rdb eval "
                -- Playbox moods
                INSERT INTO temp_sat_report_table(n,g,c,sat,delta,sat0)
                SELECT '*', 
                       g, 
                       '*', 
                       sat,
                       sat-sat0, 
                       sat0
                FROM gram_g
                WHERE object='::aram' AND gtype=\$gtype
                $andGroup;
              

                -- Playbox satisfaction levels
                INSERT INTO temp_sat_report_table(n,g,c,sat,delta,sat0)
                SELECT '*', 
                       g, 
                       c, 
                       gram_gc.sat,
                       gram_gc.sat-gram_gc.sat0, 
                       gram_gc.sat0
                FROM gram_gc JOIN gram_g USING (object, g)
                WHERE object='::aram' AND gtype=\$gtype
                $andGroup;
            "
        }

        # NEXT, include the neighborhood data
        rdb eval "
            -- Nbhood moods
            INSERT INTO temp_sat_report_table(n,g,c,sat,delta,sat0)
            SELECT n, 
                   g, 
                   '*', 
                   gram_ng.sat,
                   gram_ng.sat - gram_ng.sat0, 
                   gram_ng.sat0
            FROM gram_ng JOIN gram_g USING (object, g)
            WHERE object='::aram' AND gtype=\$gtype AND sat_tracked=1
            $andNbhood
            $andGroup;
          
             -- Nbhood satisfaction levels
            INSERT INTO temp_sat_report_table(n,g,c,sat,delta,sat0)
            SELECT n, 
                   g, 
                   c, 
                   sat,
                   sat - sat0, 
                   sat0
            FROM gram_sat
            WHERE object='::aram' AND gtype=\$gtype
            $andNbhood
            $andGroup;
        "

        # NEXT, format the report for all groups or group-specific
        set text [rdb query {
            SELECT CASE WHEN n='*' THEN 'Playbox' ELSE n END,
                   g,
                   CASE WHEN c='*' THEN 'Mood' ELSE c END,
                   format('%7.2f = %-2s', sat,  qsat('name',sat)),
                   format('%7.2f', delta),
                   format('%7.2f = %-2s', sat0, qsat('name',sat0))
            FROM temp_sat_report_table
            ORDER BY n, g, c
        } -headercols 3 -labels {
            "Nbhood" "Group" "Con" "Satisfaction" "  Delta" 
            " Initial Sat"
        }]

        if {$text eq ""} {
            set text "No data found."
        }

        # NEXT, save the report
        set id [reporter save \
                    -title     $title                       \
                    -text      $text                        \
                    -requested 1                            \
                    -type      GRAM                         \
                    -subtype   SAT                          \
                    -meta1     ${gtype}]

        return [list reporter delete $id]
    }



    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod save to reporter

    #-------------------------------------------------------------------
    # Parameter types
    #
    # TBD: This should perhaps go somewhere else.

    # EnumVal ptype enum value
    #
    # ptype    Parameter type
    # enum     List of valid values
    # value    Value to validate
    #
    # Validates the value, returning it, or throws a good error message.

    proc EnumVal {ptype enum value} {
        if {$value ni $enum} {
            set enum [join $enum ", "]
            return -code error -errorcode INVALID \
                "Invalid $ptype, should be one of: $enum"
        }

        return $value
    }

    # ptype n+all
    #
    # Neighborhood names + ALL

    typemethod {ptype n+all names} {} {
        linsert [nbhood names] 0 ALL
    }

    typemethod {ptype n+all validate} {value} {
        EnumVal "neighborhood" [$type ptype n+all names] $value
    }


    # ptype civg+all names
    typemethod {ptype civg+all names} {} {
        linsert [civgroup names] 0 ALL
    }

    typemethod {ptype civg+all validate} {value} {
        EnumVal "civilian group" [$type ptype civg+all names] $value
    }


    # ptype orgg+all names
    typemethod {ptype orgg+all names} {} {
        linsert [orggroup names] 0 ALL
    }

    typemethod {ptype orgg+all validate} {value} {
        EnumVal "organization group" [$type ptype orgg+all names] $value
    }
}


#-----------------------------------------------------------------------
# Orders

# REPORT:CIVILIAN:SAT
#
# Produces a Civilian Satisfaction Report

order define ::report REPORT:CIVILIAN:SAT {
    title "Civilian Satisfaction Report"
    options \
        -sendstates {PAUSED RUNNING} \
        -alwaysunsaved

    parm n enum  "Neighborhood"  -type {::report ptype n+all} \
        -defval ALL
    parm g enum  "Group"         -type {::report ptype civg+all} \
        -defval ALL
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type {::report ptype n+all}
    prepare g  -toupper -required -type {::report ptype civg+all}

    returnOnError

    # NEXT, produce the report
    set undo [list]
    lappend undo [$type imp sat CIV $parms(n) $parms(g)]

    setundo [join $undo \n]
}


# REPORT:DRIVER
#
# Produces an Attitude Driver Report.

order define ::report REPORT:DRIVER {
    title "Attitude Driver Report"
    options \
        -sendstates {PAUSED RUNNING} \
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

# REPORT:ORGANIZATION:SAT
#
# Produces a Organization Satisfaction Report

order define ::report REPORT:ORGANIZATION:SAT {
    title "Organization Satisfaction Report"
    options \
        -sendstates {PAUSED RUNNING} \
        -alwaysunsaved

    parm n enum  "Neighborhood"  -type {::report ptype n+all} \
        -defval ALL
    parm g enum  "Group"         -type {::report ptype orgg+all} \
        -defval ALL
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type {::report ptype n+all}
    prepare g  -toupper -required -type {::report ptype orgg+all}

    returnOnError

    # NEXT, produce the report
    set undo [list]
    lappend undo [$type imp sat ORG $parms(n) $parms(g)]

    setundo [join $undo \n]
}








