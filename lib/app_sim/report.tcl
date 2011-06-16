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
#    This module contains the orders that produce customized reports
#    in the Detail browser.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# report

snit::type ::report {
    pragma -hasinstances no

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
                set values [civgroup gIn $n]

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



# REPORT:DRIVER
#
# Produces an Attitude Driver Report.

order define REPORT:DRIVER {
    title "Attitude Driver Report"
    options \
        -schedulestates {PREP PAUSED} \
        -sendstates     PAUSED

    parm state enum  "Driver State"  -enumtype {::report::edriverstate} \
                                    -defval    active
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

    parm state    enum "Parameter State" -enumtype ::report::eparmstate \
                                         -defval   ALL
    parm wildcard text "Wild Card"
} {
    # FIRST, prepare the parameters
    prepare state     -required -type ::report::eparmstate
    prepare wildcard

    returnOnError -final

    # NEXT, produce the report
    if {$parms(state) eq "ALL"} {
        set url "my://app/parmdb"
    } else {
        set url "my://app/parmdb/changed"
    }

    if {$parms(wildcard) ne ""} {
        append url "?$parms(wildcard)"
    }

    app show $url
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


    parm n      enum  "Nbhood"        -enumtype {ptype n}
    parm g      enum  "Group"
    parm c      enum  "Concern"       -enumtype {ptype c+mood} -defval "MOOD"
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






