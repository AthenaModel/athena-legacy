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

        enum eparmstate { 
            ALL       "All Parameters"
            CHANGED   "Changed Parameters"
        }
    }

    #-------------------------------------------------------------------
    # Initialization
    
    typemethod init {} {
        log normal report "init"

        # FIRST, support delegation to reporter(n)
        set reporter ::projectlib::reporter

        # NEXT, configure the reporter
        reporter configure \
            -db        ::rdb                                \
            -clock     ::simclock                           \
            -deletecmd [list notifier send $type <Update>]  \
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
            SELECT * FROM reports WHERE rtype='GRAM' AND subtype='COOP'
        }

        reporter bin define gram_driver "Drivers" gram {
            SELECT * FROM reports WHERE rtype='GRAM' AND subtype='DRIVER'
        }

        reporter bin define gram_sat "Satisfaction" gram {
            SELECT * FROM reports WHERE rtype='GRAM' AND subtype='SAT'
        }

        reporter bin define gram_satcontrib "Sat. Contrib." gram {
            SELECT * FROM reports WHERE rtype='GRAM' AND subtype='SATCONTRIB'
        }

        reporter bin define civ "Civilian" "" {
            SELECT * FROM reports WHERE meta1='CIV'
        }

        reporter bin define civ_coop "Cooperation" civ {
            SELECT * FROM reports WHERE rtype='GRAM' AND subtype='COOP'
        }

        reporter bin define civ_sat "Satisfaction" civ {
            SELECT * FROM reports WHERE meta1='CIV' AND subtype='SAT'
        }

        reporter bin define org "Organization" "" {
            SELECT * FROM reports WHERE meta1='ORG'
        }

        reporter bin define org_sat "Satisfaction" org {
            SELECT * FROM reports WHERE meta1='ORG' AND subtype='SAT'
        }

        reporter bin define scenario "Scenario" "" {
            SELECT * FROM reports WHERE rtype='SCENARIO'
        }

        reporter bin define scenario_sanity "Sanity Check" scenario {
            SELECT * FROM reports WHERE rtype='SCENARIO' AND subtype='SANITY'
        }

        reporter bin define scenario_sanity_lock "On Lock" scenario_sanity {
            SELECT * FROM reports WHERE rtype='SCENARIO' AND subtype='SANITY'
            AND meta1='ONLOCK'
        }

        reporter bin define scenario_sanity_tick "On Tick" scenario_sanity {
            SELECT * FROM reports WHERE rtype='SCENARIO' AND subtype='SANITY'
            AND meta1='ONTICK'
        }

        reporter bin define scenario_parmdb "Model Parameters" scenario {
            SELECT * FROM reports WHERE rtype='SCENARIO' AND subtype='PARMDB'
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

        log normal report "init complete"
    }

    #-------------------------------------------------------------------
    # Reports

    # hotlist save
    #
    # Saves the reports on the hot list to a disk file.

    typemethod {hotlist save} {} {
        # FIRST, are there any to save?
        if {![rdb exists {SELECT id FROM reports WHERE hotlist=1}]} {
            messagebox popup \
                -title    "Cannot Save Reports" \
                -icon     error                 \
                -buttons  {cancel "Cancel"}     \
                -parent   [app topwin]          \
                -message  [normalize {
                    No reports have been added to the Report Hot List,
                    so there's nothing to save.  To add a report to the 
                    Hot List, view the report in the Report Browser, 
                    and check the "Hot List" check box on the toolbar
                    above the report's header.
                }]

            return
        }

        # NEXT, query for the file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                                 \
                          -parent      [app topwin]                  \
                          -title       "Save Hot Listed Reports As"  \
                          -initialfile "hotlist.txt"                 \
                          -filetypes {
                              {{Text File} {.txt} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the reports on the hotlist.
        if {[catch {
            $type SaveHotList $filename
        } result]} {
            messagebox popup \
                -title    "Cannot Save Reports" \
                -icon     error                 \
                -buttons  {cancel "Cancel"}     \
                -parent   [app topwin]          \
                -message  [normalize {
                    Athena was unable to save the reports to the
                    requested file:  $result
                }]
        } else {
            app puts "Reports saved to $filename"
        }
    }

    # SaveHotList filename
    #
    # filename     A file to which to save the hot list.
    #
    # Saves the hot listed reports.

    typemethod SaveHotList {filename} {
        # FIRST, open the file
        set f [open $filename w]

        try {
            set count 0

            rdb eval {
                SELECT * FROM reports
                WHERE hotlist=1
                ORDER BY id
            } data {
                if {$count > 0} {
                    puts $f "\f"
                }

                puts $f [$type FormatReport data]

                incr count
            }

        } finally {
            close $f
        }
    }

    # FormatReport dataVar
    #
    # dataVar     An array of the report attributes
    #
    # Formats the report so that it can saved to disk.

    typemethod FormatReport {dataVar} {
        upvar 1 $dataVar data

        tsubst {
            |<--
            ID:    $data(id)
            Time:  $data(stamp) (Tick $data(time))
            Title: $data(title)
            Type:  $data(rtype)/$data(subtype)

            $data(text)
        }
    }

    # hotlist clear
    #
    # Clears all hotlist flags, if the user so chooses.

    typemethod {hotlist clear} {} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Clear" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     "report:hotlist:clear"           \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you really want to clear the
                            report hot list?  Your hot listed reports
                            will no longer be available in the Hot List
                            bin in the report browser.
                        }]]

        if {$answer eq "cancel"} {
            return
        }

        reporter hotlist set all 0

        notifier send $type <Update> all
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
                    -rtype     GRAM                         \
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
        
        set where1 [list]
        set where2 [list]

        if {$f ne "ALL"} {
            lappend where2 "f='$f'"

            lappend modifiers "of $f"
        }

        if {$g ne "ALL"} {
            lappend where1 "g='$g'"
            lappend where2 "g='$g'"

            lappend modifiers "with $g"
        }

        if {$n ne "ALL"} {
            lappend where1 "n='$n'"
            lappend where2 "n='$n'"

            lappend modifiers "in $n"
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
                [tif {$where1 ne ""} {WHERE [join $where1 { AND }]}];
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
            [tif {$where2 ne ""} {WHERE [join $where2 { AND }]}];
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
                    -rtype     GRAM                         \
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
        # FIRST, get summary statistics
        rdb eval {
            DROP TABLE IF EXISTS temp_report_driver_effects;
            DROP TABLE IF EXISTS temp_report_driver_contribs;

            CREATE TEMPORARY TABLE temp_report_driver_effects AS
            SELECT driver, 
                   CASE WHEN min(ts) IS NULL THEN 0
                                             ELSE 1 END AS has_effects,
                   CASE WHEN min(ts) NOT NULL    THEN tozulu(min(ts)) 
                                                 ELSE '' END AS ts,
                   CASE WHEN max(te) IS NULL     THEN ''
                        WHEN max(te) != 99999999 THEN tozulu(max(te)) 
                                                 ELSE 'On-going' END AS te
            FROM gram_driver LEFT OUTER JOIN gram_effects USING (driver)
            GROUP BY driver;

            CREATE TEMPORARY TABLE temp_report_driver_contribs AS
            SELECT driver, 
                   CASE WHEN min(time) IS NULL THEN 0
                                               ELSE 1 END AS has_contribs
            FROM gram_driver LEFT OUTER JOIN gram_contribs USING (driver)
            GROUP BY driver;
        }

        # NEXT, produce the query.
        if {$state eq "all"} {
            set clause ""
        } else {
            set clause "WHERE state = '$state'"
        }

        set query "
            SELECT gram_driver.driver AS driver, 
                   dtype, 
                   name, 
                   oneliner,
                   CASE WHEN NOT has_effects AND NOT has_contribs 
                        THEN 'empty'
                        WHEN NOT has_effects AND has_contribs  
                        THEN 'inactive'
                        ELSE 'active'
                        END AS state,
                   ts,
                   te
            FROM gram_driver
            JOIN temp_report_driver_effects USING (driver)
            JOIN temp_report_driver_contribs USING (driver)
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
                    -rtype     GRAM                         \
                    -subtype   DRIVER]

        return [list reporter delete $id]
    }

    # imp parmdb state pattern
    #
    # state    CHANGED|ALL
    # pattern  Glob-pattern
    #
    # Produces a report of all parameter values, or only those
    # whose values differ from the default.

    typemethod {imp parmdb} {state pattern} {
        # FIRST, get everybody if there's no pattern.
        if {$pattern eq ""} {
            set pattern "*"
        }

        # NEXT, get the width of the longest parameter name
        set parmwid [lmaxlen [parmdb names $pattern]]
        set fmt     "%-${parmwid}s = %s\n"
        let indent  {$parmwid + 3}

        # NEXT, get the text.
        set text ""

        foreach {parm value} [parmdb list $pattern] {
            set defvalue [parmdb getdefault $parm]

            if {$value ne $defvalue} {
                append text [format $fmt $parm [WrapVal $indent $value]]
                append text [format $fmt "    Default Setting" \
                                 [WrapVal $indent $defvalue]]
            } elseif {$state eq "ALL"} {
                append text [format $fmt $parm [WrapVal $indent $value]]
            } {
                # Current == default, and we're not showing that.
                continue
            }
        }

        if {$text eq ""} {
            set text "No such parameters found.\n"
        }

        # NEXT, indicate which ones we're showing
        set header "This report lists the values of all model parameters"
 
        if {$state eq "CHANGED"} {
            set title "Changed"

            append header \
                "\nthat have been changed from their default settings"
        } else {
            set title "All"
        }

        if {$pattern ne "*"} {
            append title " matching \"$pattern\""
            append header \
                "\nand match the pattern \"$pattern\""
        }

        append header "."

        # NEXT, save the report
        set id [reporter save \
                    -title     "Model Parameters ($title)"  \
                    -text      "$header\n\n$text"           \
                    -requested 1                            \
                    -rtype     SCENARIO                     \
                    -subtype   PARMDB]

        return [list reporter delete $id]
    }

    # WrapVal indent value
    #
    # indent    Indent in characters for the second and subsequent lines
    # value     Value to wrap
    #
    # Wraps the value to fit within a field (75 - indent) characters wide,
    # breaking on whitespace, and indenting the second and subsequent
    # lines.

    proc WrapVal {indent value} {
        # FIRST, does it need to be wrapped?
        let wid {80 - $indent}

        if {[string length $value] <= $wid} {
            return $value
        }

        # NEXT, it does.  Compute the indent leader.
        set leader  "\n[string repeat " " $indent]"

        # NEXT, split the input into tokens
        set lines [list]
        set line ""

        foreach token [split $value] {
            # FIRST, if it's the empty string ignore it; we'll get that
            # if there are multiple adjacent whitespaces in the value.
            if {$token eq ""} {
                continue
            }

            # NEXT, can the token be added to the current line without
            # making it too long?

            if {[string length $line] + [string length $token] + 1 < $wid} {
                if {$line ne ""} {
                    append line " "
                }
                append line $token
            } elseif {$line eq ""} {
                # This token is too long all by itself
                lappend lines $token
            } else {
                lappend lines $line
                set line $token
            }
        }

        return [join $lines $leader]
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
                WHERE gtype=\$gtype
                $andGroup;
              

                -- Playbox satisfaction levels
                INSERT INTO temp_sat_report_table(n,g,c,sat,delta,sat0)
                SELECT '*', 
                       g, 
                       c, 
                       gram_gc.sat,
                       gram_gc.sat-gram_gc.sat0, 
                       gram_gc.sat0
                FROM gram_gc JOIN gram_g USING (g)
                WHERE gtype=\$gtype
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
            FROM gram_ng JOIN gram_g USING (g)
            WHERE gtype=\$gtype AND sat_tracked=1
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
            WHERE gtype=\$gtype
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
                    -rtype     GRAM                         \
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
                WHERE n=\$n AND g=\$g AND c=\$c
                ORDER BY abs(acontrib) DESC
                LIMIT $top
            "

            # NEXT, get the total contribution to this curve in this
            # time window.
            # for.

            set totContrib [rdb onecolumn {
                SELECT total(abs(acontrib))
                FROM gram_sat_drivers
                WHERE n=$n AND g=$g AND c=$c
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
                       driver,
                       name,
                       oneliner
                FROM temp_satcontribs
                JOIN gram_driver USING (driver);

                DROP TABLE temp_satcontribs;
            }  -maxcolwidth 0 -labels {
                "Rank" "  Actual" "ID" "Name" "Description"
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
                        -rtype     GRAM                         \
                        -subtype   SATCONTRIB]
        }

        return [list reporter delete $id]
    }

    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod save to reporter

    #-------------------------------------------------------------------
    # Order Helper procs

    # Refresh_RSC_g dlg fields
    #
    # dlg       The order dialog
    # fields    List of field names
    # fdict     Dictionary of field values.
    #
    # Refreshes the g and c fields when the upstream fields change.

    proc Refresh_RSC {dlg fields fdict} {
        set disabled [list]

        dict with fdict {
            # Refresh g
            if {"n" in $fields} {
                set values [nbgroup gIn $n]

                $dlg field configure g -values $values

                if {[llength $values] == 0} {
                    lappend disabled g
                }
            }
        }

        $dlg disabled $disabled
    }
}


#-----------------------------------------------------------------------
# Orders

# REPORT:COOP
#
# Produces a Cooperation Report

order define REPORT:COOP {
    title "Cooperation Report"
    options \
        -schedulestates {PREP PAUSED} \
        -sendstates     PAUSED

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

    returnOnError -final

    # NEXT, produce the report
    set undo [list]
    lappend undo [report imp coop $parms(n) $parms(f) $parms(g)]

    setundo [join $undo \n]
}


# REPORT:DRIVER
#
# Produces an Attitude Driver Report.

order define REPORT:DRIVER {
    title "Attitude Driver Report"
    options \
        -schedulestates {PREP PAUSED} \
        -sendstates     PAUSED

    parm state enum  "Driver State"  -type {::report::edriverstate} \
        -defval active
} {
    # FIRST, prepare the parameters
    prepare state      -toupper -required -type {::report::edriverstate}

    returnOnError -final

    # NEXT, produce the report
    set undo [list]
    lappend undo [report imp driver $parms(state)]

    setundo [join $undo \n]
}


# REPORT:PARMDB
#
# Produces a parmdb(5) report.

order define REPORT:PARMDB {
    title "Model Parameters Report"
    options \
        -schedulestates {PREP PAUSED} \
        -sendstates     {PREP PAUSED}

    parm state    enum "Parameter State" -type ::report::eparmstate -defval ALL
    parm wildcard text "Wild Card"
} {
    # FIRST, prepare the parameters
    prepare state     -required -type ::report::eparmstate
    prepare wildcard

    returnOnError -final

    # NEXT, produce the report
    set undo [list]
    lappend undo [report imp parmdb $parms(state) $parms(wildcard)]

    setundo [join $undo \n]
}

# REPORT:SAT:CURRENT
#
# Produces a Civilian Satisfaction Report

order define REPORT:SAT:CURRENT {
    title "Civilian Satisfaction Report"
    options \
        -schedulestates {PREP PAUSED} \
        -sendstates     PAUSED

    parm n enum  "Neighborhood"  -type {::ptype n+all}     -defval ALL
    parm g enum  "Group"         -type {::ptype civg+all}  -defval ALL
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type {::ptype n+all}
    prepare g  -toupper -required -type {::ptype civg+all}

    returnOnError -final

    # NEXT, produce the report
    set undo [list]
    lappend undo [report imp sat CIV $parms(n) $parms(g)]

    setundo [join $undo \n]
}


# REPORT:SAT:CONTRIB
#
# Produces a Contribution to Satisfaction Report

order define REPORT:SAT:CONTRIB {
    title "Contribution to Satisfaction Report"
    options \
        -schedulestates {PREP PAUSED}          \
        -sendstates     PAUSED                 \
        -refreshcmd     ::report::Refresh_RSC


    parm n      enum  "Nbhood"        -type {ptype n}
    parm g      enum  "Group"
    parm c      enum  "Concern"       -type {ptype c+mood} -defval "MOOD"
    parm top    text  "Number"        -defval 20
    parm start  text  "Start Time"    -defval "T0"
    parm end    text  "End Time"      -defval "NOW"
} {
    # FIRST, prepare the parameters
    prepare n      -toupper -required -type {ptype n}
    prepare g      -toupper -required -type civgroup
    prepare c      -toupper -required -type {ptype c+mood}
    prepare top                       -type ipositive
    prepare start  -toupper           -type {simclock past}
    prepare end    -toupper           -type {simclock past}

    returnOnError

    # NEXT, validate the start and end times.

    if {$parms(start) eq ""} {
        set parms(start) 0
    }

    if {$parms(end) eq ""} {
        set parms(end) [simclock now]
    }


    validate end {
        if {$parms(end) < $parms(start)} {
            reject end "End time is prior to start time"
        }
    }

    returnOnError -final

    # NEXT, convert the data
    if {$parms(top) eq ""} {
        set parms(top) 20
    }

    # NEXT, produce the report
    set undo [list]
    lappend undo [report imp satcontrib [array get parms]]

    setundo [join $undo \n]
}






