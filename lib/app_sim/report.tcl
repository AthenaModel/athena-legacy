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

snit::type ::report {
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

        reporter bin define gram_coop "Cooperation" gram {
            SELECT * FROM REPORTS WHERE rtype='GRAM' AND subtype='COOP'
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

        reporter bin define civ_coop "Cooperation" civ {
            SELECT * FROM REPORTS WHERE rtype='GRAM' AND subtype='COOP'
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

    # imp coop n f g
    #
    # n    Neighborhood, or "ALL"
    # f    Civilian Group, or "ALL"
    # g    Force Group, or "ALL"
    #
    # Generates a detailed report of group cooperation.

    typemethod {imp coop} {n f g} {
        # FIRST, Set the title
        set modifiers [list]

        if {$f ne "ALL"} {
            lappend modifiers "of $f"
        } else {
            set f "*"
        }

        if {$g ne "ALL"} {
            lappend modifiers "with $g"
        } else {
            set g "*"
        }

        if {$n ne "ALL"} {
            lappend modifiers "in $n"
        } else {
            set n "*"
        }

        set title "Cooperation Report"

        if {[llength $modifiers] > 0} {
            append title " ([join $modifiers { }])"
        }

        # NEXT, get the text
        set text [aram dump coop.nfg -nbhood $n -civ $f -frc $g]

        # NEXT, save the report
        set id [reporter save \
                    -title     $title                       \
                    -text      $text                        \
                    -requested 1                            \
                    -type      GRAM                         \
                    -subtype   COOP]

        return [list reporter delete $id]
    }


    # imp coop n f g
    #
    # n    Neighborhood, or "ALL"
    # f    Civilian Group, or "ALL"
    # g    Force Group, or "ALL"
    #
    # Generates a detailed report of group cooperation, including
    # composite cooperation and deltas from time 0.

    typemethod {imp coop} {n f g} {
        # FIRST, Set the base title
        set title "Cooperation"

        # NEXT, Determine the effects of the arguments.
        set modifiers [list]

        if {$f ne "ALL"} {
            set andF "AND f='$f'"

            lappend modifiers "of $f"
        } else {
            set andF ""
        }

        if {$g ne "ALL"} {
            set andG "AND g='$g'"

            lappend modifiers "with $g"
        } else {
            set andG ""
        }

        if {$n ne "ALL"} {
            set andN "AND n='$n'"

            lappend modifiers "in $n"
        } else {
            set andN ""
        }

        # NEXT, add the modifiers (if any) to the title
        if {[llength $modifiers] > 0} {
            set title "$title ([join $modifiers { }])"
        }

        # NEXT, we need to accumulate the desired data.  Create a 
        # temporary table to contain it.
        rdb eval {
            DROP TABLE IF EXISTS temp_coop_report_table;
            CREATE TEMP TABLE temp_coop_report_table (
                 n, f, g, coop, delta, coop0
            );
        }


        # NEXT, include the neighborhood data
        if {$f eq "ALL"} {
            rdb eval "
                -- Nbhood cooperation with force groups
                INSERT INTO temp_coop_report_table(n,f,g,coop,delta,coop0)
                SELECT n,
                       '*', 
                       g, 
                       gram_frc_ng.coop,
                       gram_frc_ng.coop - gram_frc_ng.coop0, 
                       gram_frc_ng.coop0
                FROM gram_frc_ng
                WHERE object='::aram'
                $andN
                $andG;
            "
        }

        rdb eval "
             -- Cooperation levels
            INSERT INTO temp_coop_report_table(n,f,g,coop,delta,coop0)
            SELECT n, 
                   f,
                   g, 
                   coop,
                   coop - coop0, 
                   coop0
            FROM gram_coop
            WHERE object='::aram'
            $andN
            $andF
            $andG;
        "

        # NEXT, format the report for all groups or group-specific
        set text [rdb query {
            SELECT n,
                   CASE WHEN f='*' THEN 'Nbhood' ELSE f END,
                   g,
                   format('%7.2f = %-2s', coop,  qcoop('name',coop)),
                   format('%7.2f', delta),
                   format('%7.2f = %-2s', coop0, qcoop('name',coop0))
            FROM temp_coop_report_table
            ORDER BY n, f, g
        } -headercols 3 -labels {
            "Nbhood" "Of" "With" "Cooperation" "  Delta" 
            " Initial Coop"
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
                    -subtype   COOP]

        return [list reporter delete $id]
    }


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
}


#-----------------------------------------------------------------------
# Orders

# REPORT:CIVILIAN:SATISFACTION
#
# Produces a Civilian Satisfaction Report

order define ::report REPORT:CIVILIAN:SATISFACTION {
    title "Civilian Satisfaction Report"
    options \
        -sendstates {PAUSED RUNNING} \
        -alwaysunsaved

    parm n enum  "Neighborhood"  -type {::ptype n+all} \
        -defval ALL
    parm g enum  "Group"         -type {::ptype civg+all} \
        -defval ALL
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type {::ptype n+all}
    prepare g  -toupper -required -type {::ptype civg+all}

    returnOnError

    # NEXT, produce the report
    set undo [list]
    lappend undo [$type imp sat CIV $parms(n) $parms(g)]

    setundo [join $undo \n]
}


# REPORT:COOPERATION
#
# Produces a Cooperation Report

order define ::report REPORT:COOPERATION {
    title "Cooperation Report"
    options \
        -sendstates {PAUSED RUNNING} \
        -alwaysunsaved

    parm n enum  "Neighborhood"  -type {::ptype n+all}    \
        -defval ALL
    parm f enum  "Of Group"      -type {::ptype civg+all} \
        -defval ALL
    parm g enum  "With Group"    -type {::ptype frcg+all} \
        -defval ALL
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type {::ptype n+all}
    prepare f  -toupper -required -type {::ptype civg+all}
    prepare g  -toupper -required -type {::ptype frcg+all}

    returnOnError

    # NEXT, produce the report
    set undo [list]
    lappend undo [$type imp coop $parms(n) $parms(f) $parms(g)]

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

# REPORT:ORGANIZATION:SATISFACTION
#
# Produces a Organization Satisfaction Report

order define ::report REPORT:ORGANIZATION:SATISFACTION {
    title "Organization Satisfaction Report"
    options \
        -sendstates {PAUSED RUNNING} \
        -alwaysunsaved

    parm n enum  "Neighborhood"  -type {::ptype n+all} \
        -defval ALL
    parm g enum  "Group"         -type {::ptype orgg+all} \
        -defval ALL
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type {::ptype n+all}
    prepare g  -toupper -required -type {::ptype orgg+all}

    returnOnError

    # NEXT, produce the report
    set undo [list]
    lappend undo [$type imp sat ORG $parms(n) $parms(g)]

    setundo [join $undo \n]
}








