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
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /contribs {contribs/?} \
            text/html [myproc /contribs:html]   \
            "Contributions to attitude curves."

        appserver register /contribs/coop {contribs/coop/?} \
            text/html [myproc /contribs/coop:html]          \
            "Contributions to cooperation curves."

        appserver register /contribs/hrel {contribs/hrel/?} \
            text/html [myproc /contribs/hrel:html]          \
            "Contributions to horizontal relationships."

        appserver register /contribs/sat {contribs/sat/?} \
            text/html [myproc /contribs/sat:html]         \
            "Contributions to satisfaction curves."

        appserver register /contribs/sat/{g} {contribs/sat/(\w+)/?} \
            text/html [myproc /contribs/sat/g:html]                   \
            "Contributions to civilian group {g}'s satisfaction curves."

        appserver register /contribs/sat/{g}/{c} {contribs/sat/(\w+)/(\w+)?} \
            text/html [myproc /contribs/sat/g/c:html] {
                Contributions to civilian group {g}'s satisfaction with {c},
                where {c} may be AUT, CUL, QOL, SFT, or "mood".
            }

        appserver register /contribs/vrel {contribs/vrel/?} \
            text/html [myproc /contribs/vrel:html]          \
            "Contributions to vertical relationships."
    }

    #-------------------------------------------------------------------
    # /contribs: All defined attitude types.
    #
    # No match parameters

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
    # /contribs/sat:  All satisfaction curves.
    #
    # No match parameters

    # /contribs/sat:html udict matchArray
    #
    # Returns a page that allows the user to drill down to the contributions
    # for a specific satisfaction curve.

    proc /contribs/sat:html {udict matchArray} {
        ht page "Contributions to Satisfaction" {
            ht title "Contributions to Satisfaction"

            ht putln "Of group:"
            ht para

            ht ul {
                foreach g [lsort [civgroup names]] {
                    ht li {
                        ht link /contribs/sat/$g $g
                    }
                }
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/sat/{g}:  All satisfaction curves for a particular group,
    # including mood.
    #
    # Match Parameters:
    #
    # {g} => $(1)    - The civilian group's short name

    # /contribs/sat/g:html udict matchArray
    #
    # Returns a page that allows the user to drill down to the contributions
    # for a specific satisfaction curve for a specific group.

    proc /contribs/sat/g:html {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the group
        set g [string toupper $(1)]

        if {[catch {civgroup validate $g} result]} {
            return -code error -errorcode NOTFOUND \
                $result
        }

        # NEXT, output the content
        ht page "Contributions to Satisfaction of $g" {
            ht title "Contributions to Satisfaction of $g"

            ht putln "With respect to:"
            ht para

            ht ul {
                ht li {
                    ht link /contribs/sat/$g/mood Mood
                }

                foreach c [lsort [econcern names]] {
                    ht li {
                        ht link /contribs/sat/$g/$c $c
                    }
                }
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs/sat/{g}/{c}:  A particular satisfaction curve or 
    # mood.
    #
    # Match Parameters:
    #
    # {g} => $(1)    - The civilian group's short name
    # {c} => $(2)    - The concern name, or "mood"


    # /contribs/sat/g/c:html udict matchArray
    #
    # Returns a page that allows the user to drill down to the contributions
    # for a specific satisfaction curve for a specific group.
    #
    # Returns a page that documents the contributions to the given
    # satisfaction curve.
    #
    # The udict query is a "parm=value[+parm=value]" string with the
    # following parameters:
    #
    #    top    Max number of top contributors to include.
    #    start  Start time in ticks
    #    end    End time in ticks
    #
    # Unknown query parameters and invalid query values are ignored.

    proc /contribs/sat/g/c:html {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the group and concern
        set g [string toupper $(1)]
        set c [string toupper $(2)]

        if {[catch {civgroup validate $g} result]} {
            return -code error -errorcode NOTFOUND \
                $result
        }

        if {[catch {ptype c+mood validate $c} result]} {
            return -code error -errorcode NOTFOUND \
                $result
        }

        # NEXT, begin to format the report
        ht page "Contributions to Satisfaction (to $c of $g)"
        ht title "Contributions to Satisfaction (to $c of $g)"

        # NEXT, if we're not locked we're done.
        if {![locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        # NEXT, get the query parameters
        set q [split [dict get $udict query] "=+"]

        set top   [restrict $q top   ipositive 20]
        set start [restrict $q start iquantity 0]
        set end   [restrict $q end   iquantity [simclock now]]

        # NEXT, Get the drivers for this time period.
        if {$c eq "MOOD"} {
            aram contribs mood $g \
                -start $start     \
                -end   $end
        } else {
            aram contribs sat $g $c \
                -start $start       \
                -end   $end
        }

        # NEXT, pull them into a temporary table, in sorted order,
        # so that we can use the "rowid" as the rank.
        # Note: This query is passed as a string, because the LIMIT
        # is an integer, not an expression, so we can't use an SQL
        # variable.
        rdb eval "
            DROP TABLE IF EXISTS temp_satcontribs;
    
            CREATE TEMP TABLE temp_satcontribs AS
            SELECT driver, contrib
            FROM uram_contribs
            ORDER BY abs(contrib) DESC
            LIMIT $top
        "

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
                ht put "Window: [simclock toZulu $start] to "

                if {$end == [simclock now]} {
                    ht put "now"
                } else {
                    ht put "[simclock toZulu $end]"
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



