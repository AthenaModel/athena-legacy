#-----------------------------------------------------------------------
# TITLE:
#    appserver_contribs.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Contributions to Attitude Curves
#
#    my://app/contribs/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module CONTRIBS {
    #-------------------------------------------------------------------
    # Look up tables

    # Limit values

    typevariable limit -array {
        ALL    0
        TOP5   5
        TOP10  10
        TOP20  20
        TOP50  50
        TOP100 100
    }

    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /contribs {contribs/?}    \
            tcl/linkdict [myproc /contribs:linkdict] \
            text/html [myproc /contribs:html]        \
            "Contributions to attitude curves."

        appserver register /contribs/coop {contribs/coop/?} \
            text/html [myproc /contribs/coop:html]          \
            "Contributions to cooperation curves."

        appserver register /contribs/hrel {contribs/hrel/?} \
            text/html [myproc /contribs/hrel:html]          \
            "Contributions to horizontal relationships."

        appserver register /contribs/mood {contribs/mood/?} \
            text/html [myproc /contribs/mood:html]         \
            "Contributions to civilian group mood."

        appserver register /contribs/nbcoop {contribs/nbcoop/?} \
            text/html [myproc /contribs/nbcoop:html]         \
            "Contributions to neighborhood cooperation."

        appserver register /contribs/nbmood {contribs/nbmood/?} \
            text/html [myproc /contribs/nbmood:html]         \
            "Contributions to neighborhood mood."

        appserver register /contribs/sat {contribs/sat/?} \
            text/html [myproc /contribs/sat:html]         \
            "Contributions to satisfaction curves."

        appserver register /contribs/vrel {contribs/vrel/?} \
            text/html [myproc /contribs/vrel:html]          \
            "Contributions to vertical relationships."
    }

    #-------------------------------------------------------------------
    # /contribs: All defined attitude types.
    #
    # No match parameters

    # /contribs:linkdict udict matchArray
    #
    # Returns a tcl/linkdict of contributions pages

    proc /contribs:linkdict {udict matchArray} {
        return {
            /contribs/coop { 
                label "Cooperation" 
                listIcon ::projectgui::icon::heart12
            }
            /contribs/hrel { 
                label "Horizontal Relationships" 
                listIcon ::projectgui::icon::heart12
            }
            /contribs/mood { 
                label "Group Mood" 
                listIcon ::projectgui::icon::heart12
            }
            /contribs/nbcoop { 
                label "Neighborhood Cooperation" 
                listIcon ::projectgui::icon::heart12
            }
            /contribs/nbmood { 
                label "Neighborhood Mood" 
                listIcon ::projectgui::icon::heart12
            }
            /contribs/sat { 
                label "Satisfaction" 
                listIcon ::projectgui::icon::heart12
            }
            /contribs/vrel { 
                label "Vertical Relationships" 
                listIcon ::projectgui::icon::heart12
            }
        }
    }

    # /contribs:html udict matchArray
    #
    # Returns a page that allows the user to drill down to the contributions
    # for a specific kind of attitude curve.

    proc /contribs:html {udict matchArray} {
        ht page "Contributions to Attitude Curves" {
            ht title "Contributions to Attitude Curves"

            ht ul {
                ht li {
                    ht link /contribs/coop "Cooperation (TBD)"
                }

                ht li {
                    ht link /contribs/hrel "Horizontal Relationships (TBD)"
                }

                ht li {
                    ht link /contribs/mood "Civilian Group Mood (TBD)"
                }
                
                ht li {
                    ht link /contribs/nbcoop "Neighborhood Cooperation (TBD)"
                }
                
                ht li {
                    ht link /contribs/nbmood "Neighborhood Mood (TBD)"
                }
                
                ht li {
                    ht link /contribs/sat "Satisfaction"
                }
                
                ht li {
                    ht link /contribs/vrel "Vertical Relationships (TBD)"
                }
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/coop:  All cooperation curves.
    #
    # No match parameters

    # /contribs/coop:html udict matchArray
    #
    # Returns a page that allows the user to drill down to the contributions
    # for a specific cooperation curve.

    proc /contribs/coop:html {udict matchArray} {
        ht page "Contributions to Cooperation" {
            ht title "Contributions to Cooperation"

            ht putln {
                The ability to query contributions to cooperation has
                not yet been implemented.
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/hrel:  All horizontal relationship curves.
    #
    # No match parameters

    # /contribs/hrel:html udict matchArray
    #
    # Returns a page that allows the user to drill down to the contributions
    # for a specific horizontal relationship curve.

    proc /contribs/hrel:html {udict matchArray} {
        ht page "Contributions to Horizontal Relationships" {
            ht title "Contributions to Horizontal Relationships"

            ht putln {
                The ability to query contributions to horizontal
                relationships has not yet been implemented.
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/mood:  Contributions to civilian group mood.
    #
    # No match parameters

    # /contribs/mood:html udict matchArray
    #
    # TBD

    proc /contribs/mood:html {udict matchArray} {
        ht page "Contributions to Mood" {
            ht title "Contributions to Mood"

            ht putln {
                The ability to query contributions to 
                civilian group mood has
                not yet been implemented.
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/nbcoop: Contributions to nbhood cooperation
    #
    # No match parameters

    # /contribs/nbcoop:html udict matchArray
    #
    # TBD

    proc /contribs/nbcoop:html {udict matchArray} {
        ht page "Contributions to Neighborhood Cooperation" {
            ht title "Contributions to Neighborhood Cooperation"

            ht putln {
                The ability to query contributions to neighborhood 
                cooperation has
                not yet been implemented.
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/nbmood:  Contributions to neighborhood mood.
    #
    # No match parameters

    # /contribs/nbmood:html udict matchArray
    #
    # TBD

    proc /contribs/nbmood:html {udict matchArray} {
        ht page "Contributions to Neighborhood Mood" {
            ht title "Contributions to Neighborhood Mood"

            ht putln {
                The ability to query contributions to 
                neighborhood mood has
                not yet been implemented.
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/sat?query
    #
    # No match parameters


    # /contribs/sat:html udict matchArray
    #
    # Returns a page that allows the user to see the contributions
    # for a specific satisfaction curve for a specific group during
    # a particular time interval.
    #
    # The udict query is a "parm=value[+parm=value]" string with the
    # following parameters:
    #
    #    g      The civilian group
    #    c      The concern
    #    top    Max number of top contributors to include.
    #    start  Start time in ticks
    #    end    End time in ticks
    #
    # Unknown query parameters and invalid query values are ignored.

    proc /contribs/sat:html {udict matchArray} {
        # FIRST, get the query parameters 
        set qdict [querydict $udict {g c top start end}]

        # NEXT, bring the query parms into scope
        dict with qdict {}

        # NEXT, get the group and concern
        set g [string toupper $g]
        set c [string toupper $c]

        if {$g ni [civgroup names]} {
            set g "?"
        }

        if {$c ni [econcern names]} {
            set c "?"
        }

        # NEXT, Make sure the other query parameters have valid
        # values.
        restrict top etopitems TOP20

        # We don't want to overwrite the user's time specs.
        set mystart $start
        set myend   $end

        restrict mystart {simclock timespec} 0
        restrict myend   {simclock timespec} [simclock now]

        # If they picked the defaults, clear their entries.
        if {$mystart == 0             } { set start "" }
        if {$myend   == [simclock now]} { set end   "" }

        # NEXT, myend can't be later than mystart.
        let myend {max($mystart,$myend)}
        
        # NEXT, begin to format the report
        ht page "Contributions to Satisfaction"
        ht title "Contributions to Satisfaction"

        # NEXT, if we're not locked we're done.
        if {![locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        # NEXT, insert subtitle, indicating the group and concern
        ht subtitle "Of $g with $c"

        # NEXT, insert the control form.
        ht hr
        ht form contribs/satnew
        ht label g "Group:"
        ht input g enum $g -src groups/civ
        ht label c "Concern:"
        ht input c enum $c -src enum/concerns
        ht label top "Show:"
        ht input top enum $top -src enum/topitems -content tcl/enumdict
        ht submit
        ht br
        ht label start 
        ht put "Time Interval &mdash; "
        ht link my://help/term/timespec "From:"
        ht /label
        ht input start text $start -size 12
        ht label end
        ht link my://help/term/timespec "To:"
        ht /label
        ht input end text $end -size 12
        ht /form
        ht hr
        ht para

        # NEXT, if we don't have the group and concern, ask for them.
        if {$g eq "?" || $c eq "?"} {
            ht putln "Please select a group and concern."
            ht /page
            return [ht get]
        }

        # NEXT, Get the drivers for this time period.
        aram contribs sat $g $c \
            -start $mystart     \
            -end   $myend

        # NEXT, pull them into a temporary table, in sorted order,
        # so that we can use the "rowid" as the rank.
        # Note: This query is passed as a string, because the LIMIT
        # is an integer, not an expression, so we can't use an SQL
        # variable.
        set query "
            DROP TABLE IF EXISTS temp_satcontribs;
    
            CREATE TEMP TABLE temp_satcontribs AS
            SELECT driver, contrib
            FROM uram_contribs
            ORDER BY abs(contrib) DESC
        "

        if {$limit($top) != 0} {
            append query "LIMIT $limit($top)"
        }

        rdb eval $query

        # NEXT, get the total contribution to this curve in this
        # time window.
        # for.

        set totContrib [rdb onecolumn {
            SELECT total(abs(contrib))
            FROM uram_contribs
        }]

        # NEXT, get the total contribution represented by the report.

        set totReported [rdb onecolumn {
            SELECT total(abs(contrib)) 
            FROM temp_satcontribs
        }]


        # NEXT, format the body of the report.

        ht ul {
            ht li {
                ht put "Group: "
                ht put [GroupLongLink $g]
            }
            ht li {
                ht put "Concern: $c"
            }
            ht li {
                ht put "Window: [simclock toZulu $mystart] to "

                if {$end == [simclock now]} {
                    ht put "now"
                } else {
                    ht put "[simclock toZulu $myend]"
                }
            }
        }

        ht para

        # NEXT, format the body of the report.
        ht query {
            SELECT format('%4d', temp_satcontribs.rowid) AS "Rank",
                   format('%8.3f', contrib)              AS "Actual",
                   driver                                AS "Driver",
                   dtype                                 AS "Type",
                   narrative                             AS "Narrative"
            FROM temp_satcontribs
            JOIN drivers ON (driver = driver_id);

            DROP TABLE temp_satcontribs;
        }  -default "None known." -align "RRRLL"

        ht para

        if {$totContrib > 0.0} {
            set pct [percent [expr {$totReported / $totContrib}]]

            ht putln "Reported events and situations represent"
            ht putln "$pct of the contributions made to this curve"
            ht putln "during the specified time window."
            ht para
        }

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/vrel:  All vertical relationship curves.
    #
    # No match parameters

    # /contribs/vrel:html udict matchArray
    #
    # Returns a page that allows the user to drill down to the contributions
    # for a specific horizontal relationship curve.

    proc /contribs/vrel:html {udict matchArray} {
        ht page "Contributions to Vertical Relationships" {
            ht title "Contributions to Vertical Relationships"

            ht putln {
                The ability to query contributions to vertical
                relationships has not yet been implemented.
            }
        }

        return [ht get]
    }



    #-------------------------------------------------------------------
    # Utilities
    
    # GroupLongLink g
    #
    # g      A group name
    #
    # Returns the group's long link.

    proc GroupLongLink {g} {
        rdb onecolumn {
            SELECT longlink FROM gui_groups WHERE g=$g
        }
    }
}



