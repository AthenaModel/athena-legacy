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



    # imp satcontrib parmdict
    #
    # parmdict      Parameters for this report
    #
    # n          Neighborhood
    # g          Group
    # c          Concern, or "MOOD".
    # top        Number of drivers to include.
    # start      Start of time window, in ticks
    # end        End of time window, in ticks
    #
    # List of top-contributing drivers for a particular satisfaction curve,
    # with contributions.

    typemethod {imp satcontrib} {parmdict} {
        dict with parmdict {
            # FIRST, fix up the concern
            if {$c eq "MOOD"} {
                set c "mood"
            }

            # NEXT, Get the drivers for this time period.
            aram sat drivers    \
                -nbhood  $n     \
                -group   $g     \
                -concern $c     \
                -start   $start \
                -end     $end

            # NEXT, pull them into a temporary table, in sorted order,
            # so that we can use the "rowid" as the rank.  Note that
            # if we asked for "mood", we have all of the
            # concerns as well; only take what we asked for.
            rdb eval "
                DROP TABLE IF EXISTS temp_satcontribs;
    
                CREATE TEMP TABLE temp_satcontribs AS
                SELECT driver,
                       acontrib
                FROM gram_sat_drivers
                WHERE object='::aram'
                AND   n=\$n AND g=\$g AND c=\$c
                ORDER BY abs(acontrib) DESC
                LIMIT $top
            "

            # NEXT, get the total contribution to this curve in this
            # time window.
            # for.

            set totContrib [rdb onecolumn {
                SELECT total(abs(acontrib))
                FROM gram_sat_drivers
                WHERE object='::aram'
                AND   n=$n AND g=$g AND c=$c
            }]

            # NEXT, get the total contribution represented by the report.
            # Note: This query is passed as a string, because the LIMIT
            # is an integer, not an expression, so we can't use an SQL
            # variable.

            set totReported [rdb onecolumn "
                SELECT total(abs(acontrib)) 
                FROM temp_satcontribs
            "]

            # NEXT, format the body of the report.
            set results [rdb query {
                SELECT format('%4d', temp_satcontribs.rowid),
                       format('%8.3f', acontrib),
                       name,
                       oneliner
                FROM temp_satcontribs
                JOIN gram_driver USING (driver)
                WHERE gram_driver.object='::aram';

                DROP TABLE temp_satcontribs;
            }  -maxcolwidth 0 -labels {
                "Rank" "  Actual" "Driver" "Description"
            }]

            # NEXT, always include the options 
            set text "Total Contributions to Satisfaction Curve:\n\n"
            append text "  Nbhood:  $n\n"
            append text "  Group:   $g\n"
            append text "  Concern: $c\n"
            append text "  Window:  [simclock toZulu $start] to "

            if {$end == [simclock now]} {
                append text "now\n\n"
            } else {
                append text "[simclock toZulu $end]\n\n"
            }

            # NEXT, produce the text of the report if any
            if {$results eq ""} {
                append text "None known."
            } else {
                append text $results

                append text "\n"

                if {$totContrib > 0.0} {
                    set pct [percent [expr {$totReported / $totContrib}]]

                    append text [tsubst {
             |<--
             Reported events and situations represent $pct of the contributions
             made to this curve during the specified time window.
                    }]
                }
            }

            # NEXT, save the report
            set title \
                "Contributions to Satisfaction (to $c of $g in $n)"

            set id [reporter save \
                        -title     $title                       \
                        -text      $text                        \
                        -requested 1                            \
                        -type      GRAM                         \
                        -subtype   SATCONTRIB]
        }

        return [list reporter delete $id]
    }

    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod save to reporter
}


#-----------------------------------------------------------------------
# Orders

# REPORT:SATISFACTION:CIVILIAN
#
# Produces a Civilian Satisfaction Report

order define ::report REPORT:SATISFACTION:CIVILIAN {
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

# REPORT:SATISFACTION:ORGANIZATION
#
# Produces a Organization Satisfaction Report

order define ::report REPORT:SATISFACTION:ORGANIZATION {
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


# REPORT:SATISFACTION:CONTRIB
#
# Produces a Contribution to Satisfaction Report

order define ::report REPORT:SATISFACTION:CONTRIB {
    title "Contribution to Satisfaction Report"
    options \
        -sendstates {PAUSED RUNNING} \
        -alwaysunsaved

    parm n      enum  "Neighborhood"  -type nbhood
    parm g      enum  "Group"         -type civgroup
    parm c      enum  "Concern"       -type {::ptype c+mood}
    parm top    text  "Number"        -type ipositive -defval 20
    parm start  text  "Start Time"    -type zulu
    parm end    text  "End Time"      -type zulu
} {
    # FIRST, prepare the parameters
    prepare n      -toupper -required -type nbhood
    prepare g      -toupper -required -type civgroup
    prepare c      -toupper -required -type {::ptype c+mood}
    prepare top                       -type ipositive
    prepare start  -toupper           -type zulu
    prepare end    -toupper           -type zulu

    returnOnError

    # NEXT, convert the data
    if {$parms(top) eq ""} {
        set parms(top) 20
    }

    if {$parms(start) eq ""} {
        set parms(start) 0
    } else {
        set parms(start) [simclock fromZulu $parms(start)]
    }

    if {$parms(end) eq ""} {
        set parms(end) [simclock now]
    } else {
        set parms(end) [simclock fromZulu $parms(end)]
    }

    # NEXT, produce the report
    set undo [list]
    lappend undo [$type imp satcontrib [array get parms]]

    setundo [join $undo \n]
}










