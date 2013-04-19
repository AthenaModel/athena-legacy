#-----------------------------------------------------------------------
# TITLE:
#    appserver_firing.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: firings
#
#    my://app/firings
#    my://app/firing/{id}
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# appserver module

appserver module firing {

    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /firings {firings/?}          \
            tcl/linkdict [myproc /firings:linkdict]      \
            text/html    [myproc /firings:html]          \
            "Links to all of the rule firings to date, with filtering."

        appserver register /firings/{dtype} {firings/(\w+)/?}  \
            text/html    [myproc /firings:html]                \
            "Links to all of the rule firings by rule set, with filtering."

        appserver register /firing/{id} {firing/(\w+)/?} \
            text/html [myproc /firing:html]            \
            "Detail page for rule firing {id}."
    }



    #-------------------------------------------------------------------
    # /firings:           All rule firings
    # /firings/{dtype}:   Firings by rule set
    #
    # Match Parameters:
    #
    # {dtype} ==> $(1)     - Driver type, i.e., rule set (optional)

    # /firings:linkdict udict matcharray
    #
    # Returns a /firings resource as a tcl/linkdict.  Only rule sets
    # for which rules have fired are included.  Does not handle
    # subsets or queries.

    proc /firings:linkdict {udict matchArray} {
        set result [dict create]

        rdb eval {
            SELECT DISTINCT ruleset
            FROM rule_firings
            ORDER BY ruleset
        } {
            set url /firings/$ruleset

            dict set result $url label $ruleset
            dict set result $url listIcon ::projectgui::icon::orangeheart12
        }

        return $result
    }


    # /firings:html udict matchArray
    #
    # Tabular display of firing data; content depends on 
    # simulation state.
    #
    # The udict query is a "parm=value[+parm=value]" string with the
    # following parameters:
    #
    #    start       - Start time in ticks
    #    end         - End time in ticks
    #    page_size   - The number of items on a single page, or ALL.
    #    page        - The page number, 1 to N
    #
    # Unknown query parameters and invalid query values are ignored.


    proc /firings:html {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the rule set, if any.
        set ruleset [string trim [string toupper $(1)]]

        if {$ruleset ne ""} {
            if {$ruleset ni [edamruleset names]} {
                throw NOTFOUND "Unknown rule set: \"$ruleset\""
            }

            set label "$ruleset"
        } else {
            set label "All Rule Sets"
        }

        # NEXT, get the query parameters and bring them into scope.
        set qdict [GetFiringParms $udict]
        dict with qdict {}
        
        # Begin the page
        ht page "DAM Rule Firings ($label)"
        ht title "DAM Rule Firings ($label)"

        # NEXT, if we're not locked we're done.
        if {![locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        # NEXT, insert the control form.
        ht hr
        ht form
        ht label page_size "Page Size:"
        ht input page_size enum $page_size -src enum/pagesize -content tcl/enumdict
        ht label start 
        ht put "Time Interval &mdash; "
        ht link my://help/term/timespec "From:"
        ht /label
        ht input start text $start -size 12
        ht label end
        ht link my://help/term/timespec "To:"
        ht /label
        ht input end text $end -size 12
        ht submit
        ht /form
        ht hr
        ht para

        # NEXT, get output stats
        if {$ruleset eq ""} {
            set items [rdb onecolumn {SELECT count(*) FROM gui_firings}]
        } else {
            set items [rdb onecolumn {
                SELECT count(*) FROM gui_firings
                WHERE ruleset=$ruleset
            }]
        }
     
        if {$page_size eq "ALL"} {
            set page_size $items
        }

        let pages {entier(ceil(double($items)/$page_size))}

        if {$page > $pages} {
            set page 1
        }

        let offset {($page - 1)*$page_size}

        ht putln "The selected time interval contains the following rule firings:"
        ht para

        # NEXT, show the page navigation
        ht pager $qdict $page $pages

        set query {
            SELECT link                     AS "ID",
                   t                        AS "Tick",
                   timestr(t)               AS "Week",
                   driver_id                AS "Driver",
                   rule                     AS "Rule",
                   narrative                AS "Narrative"
            FROM gui_firings
            WHERE t >= $start_ AND t <= $end_
        }

        if {$ruleset ne ""} {
            append query {
                AND ruleset=$ruleset
            }
        }

        append query {
            ORDER BY firing_id
            LIMIT $page_size OFFSET $offset
        }

        ht query $query -default "None." -align RRLRLL

        ht para

        ht pager $qdict $page $pages

        ht /page

        return [ht get]
    }

     # GetFiringParms udict
    #
    # udict    - The URL dictionary, as passed to the handler
    #
    # Retrieves the parameter names using [querydict]; then
    # does the required validation and processing.
    # Where appropriate, cooked parameter values appear in the output
    # with a "_" suffix.
    
    proc GetFiringParms {udict} {
        # FIRST, get the query parameter dictionary.
        set query [dict get $udict query]
        set qdict [urlquery get $query {page_size page start end}]

        # NEXT, do the standard validation.
        dict set qdict start_ ""
        dict set qdict end_ ""

        dict with qdict {
            restrict page_size epagesize 20
            restrict page      ipositive 1

            # NEXT, get the user's time specs in ticks, or "".
            set start_ $start
            set end_   $end

            restrict start_ {simclock timespec} [simclock cget -tick0]
            restrict end_   {simclock timespec} [simclock now]

            # If they picked the defaults, clear their entries.
            if {$start_ == [simclock cget -tick0]} { set start "" }
            if {$end_   == [simclock now]} { set end   "" }

            # NEXT, end_ can't be later than mystart.
            let end_ {max($start_,$end_)}
        }

        return $qdict
    }


    #-------------------------------------------------------------------
    # /firing/{id}: A single firing {id}
    #
    # Match Parameters:
    #
    # {id} => $(1)    - The firing's short name

    # /firing:html udict matchArray
    #
    # Detail page for a single firing {id}

    proc /firing:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Accumulate data
        set id $(1)

        if {![rdb exists {SELECT * FROM rule_firings WHERE firing_id=$id}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        # Begin the page
        rdb eval {SELECT * FROM gui_firings WHERE firing_id=$id} data {}
        set sigline [rdb onecolumn {
            SELECT sigline(dtype,signature)
            FROM drivers
            WHERE driver_id = $data(driver_id)
        }]

        ht page "Rule Firing: $id"
        ht title "Rule Firing: $id" 

        ht record {
            ht field "Rule:" {
                ht put "<b>$data(rule)</b> -- $data(narrative)"
            }
            ht field "Driver:" { 
                ht put "$data(driver_id) -- $sigline"
            }
            ht field "Week:"   { 
                ht put "[simclock toString $data(t)] (Tick $data(t))"
            }
        }

        ht para

        driver call detail $data(fdict) [namespace origin ht]

        ht para

        ht putln "The rule firing produced the following inputs:"
        ht para

        ht query {
            SELECT input_id AS "ID",
                   curve    AS "Curve",
                   mode     AS "P/T",
                   mag      AS "Mag",
                   note     AS "Note",
                   cause    AS "Cause",
                   s        AS "Here",
                   p        AS "Near",
                   q        AS "Far"
            FROM gui_inputs
            WHERE firing_id = $id
            ORDER BY input_id;
        } -align RLLRLLRRR

        ht /page

        return [ht get]
    }
}



