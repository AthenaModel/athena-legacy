#-----------------------------------------------------------------------
# TITLE:
#    appserver_actor.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Actors
#
#    my://app/actors
#    my://app/actor
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module ACTOR {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /actors {actors/?}      \
            tcl/linkdict [myproc /actors:linkdict] \
            text/html    [myproc /actors:html] {
                Links to all of the currently 
                defined actors.  HTML content 
                includes actor attributes.
            }

        appserver register /actor/{a} {actor/(\w+)/?} \
            text/html [myproc /actor:html]            \
            "Detail page for actor {a}."
    }



    #-------------------------------------------------------------------
    # /actors: All defined actors
    #
    # No match parameters

    # /actors:linkdict udict matchArray
    #
    # tcl/linkdict of all actors.
    
    proc /actors:linkdict {udict matchArray} {
        return [objects:linkdict {
            label    "Actors"
            listIcon ::projectgui::icon::actor12
            table    gui_actors
        }]
    }

    # /actors:html udict matchArray
    #
    # Tabular display of actor data; content depends on 
    # simulation state.

    proc /actors:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Actors"
        ht title "Actors"

        ht putln "The scenario currently includes the following actors:"
        ht para

        ht query {
            SELECT longlink      AS "Actor",
                   supports_link AS "Usually Supports",
                   cash_reserve  AS "Reserve, $",
                   income        AS "Income, $/week",
                   cash_on_hand  AS "On Hand, $"
            FROM gui_actors
        } -default "None." -align LLRRR

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /actor/{a}: A single actor {a}
    #
    # Match Parameters:
    #
    # {a} => $(1)    - The actor's short name

    # /actor:html udict matchArray
    #
    # Detail page for a single actor {a}

    proc /actor:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Accumulate data
        set a [string toupper $(1)]

        if {![rdb exists {SELECT * FROM actors WHERE a=$a}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        # Begin the page
        rdb eval {SELECT * FROM gui_actors WHERE a=$a} data {}

        ht page "Actor: $a"
        ht title $data(fancy) "Actor" 

        ht linkbar {
            "#goals"     "Goals"
            "#sphere"    "Sphere of Influence"
            "#base"      "Power Base"
            "#eni"       "ENI Funding"
            "#cap"       "CAP Ownership"
            "#forces"    "Force Deployment"
            "#attack"    "Attack Status"
            "#defense"   "Defense Status"
            "#sigevents" "Significant Events"
        }
        
        # Asset Summary
        ht putln "Fiscal assets: \$$data(income) per week, with "
        ht put "\$$data(cash_on_hand) cash on hand and "
        ht put "\$$data(cash_reserve) in reserve."

        ht putln "Groups owned: "

        ht linklist [rdb eval {
            SELECT url, g FROM gui_agroups 
            WHERE a=$a
            ORDER BY g
        }]

        ht put "."

        ht para

        # Goals
        ht subtitle "Goals" goals

        ht push
        rdb eval {
            SELECT narrative, flag, goal_id FROM goals
            WHERE owner=$a AND state = 'normal'
        } {
            ht ul {
                ht li {
                    if {$flag ne ""} {
                        if {$flag} {
                            ht image ::marsgui::icon::smthumbupgreen middle
                        } else {
                            ht image ::marsgui::icon::smthumbdownred middle
                        }
                    }
                    ht put $narrative
                    ht tinyi " (goal=$goal_id)"
                }
            }
            ht para
        }

        set text [ht pop]

        if {$text ne ""} {
            ht put $text
        } else {
            ht put "None."
            ht para
        }

        # Sphere of Influence
        ht subtitle "Sphere of Influence" sphere

        if {[locked -disclaimer]} {
            ht putln "Actor $a has support from groups in the"
            ht putln "following neighborhoods."
            ht putln "Note that an actor has influence in a neighborhood"
            ht putln "only if his total support from groups exceeds"
            ht putln [format %.2f [parm get control.support.min]].
            ht para

            set supports [rdb onecolumn {
                SELECT supports_link FROM gui_actors
                WHERE a=$a
            }]

            ht putln 

            if {$supports eq "SELF"} {
                ht putln "Actor $a usually supports himself"
            } elseif {$supports eq "NONE"} {
                ht putln "Actor $a doesn't usually support anyone,"
                ht putln "including himself,"
            } else {
                ht putln "Actor $a usually supports actor $supports"
            }

            ht putln "across the playbox."

            ht para

            ht query {
                SELECT N.longlink                      AS 'Neighborhood',
                       format('%.2f',I.direct_support) AS 'Direct Support',
                       S.supports_link                 AS 'Supports Actor',
                       format('%.2f',I.support)        AS 'Total Support',
                       format('%.2f',I.influence)      AS 'Influence'
                FROM influence_na AS I
                JOIN gui_nbhoods  AS N USING (n)
                JOIN gui_supports AS S ON (I.n = S.n AND I.a = S.a)
                WHERE I.a=$a AND (I.direct_support > 0.0 OR I.support > 0.0)
                ORDER BY I.influence DESC, I.support DESC, N.fancy
            } -default "None." -align LRLRR

            ht para
        }

        # Power Base
        ht subtitle "Power Base" base

        if {[locked -disclaimer]} {
            set vmin [parm get control.support.vrelMin]

            ht putln "Actor $a receives direct support from the following"
            ht putln "supporters (and would-be supporters)."
            ht putln "Note that a group only supports an actor if"
            ht putln "its vertical relationship with the actor is at"
            ht putln "least $vmin."
            ht para

            ht query {
                SELECT N.link                            AS 'In Nbhood',
                       G.link                            AS 'Group',
                       G.gtype                           AS 'Type',
                       format('%.2f',S.influence)        AS 'Influence',
                       qaffinity('format',S.vrel)        AS 'Vert. Rel.',
                       G.g || ' ' || 
                       qaffinity('longname',S.vrel) ||
                       ' ' || S.a                        AS 'Narrative',
                       commafmt(S.personnel)             AS 'Personnel',
                       qfancyfmt('qsecurity',S.security) AS 'Security'
                FROM support_nga AS S
                JOIN gui_groups  AS G ON (G.g = S.g)
                JOIN gui_nbhoods AS N ON (N.n = S.n)
                WHERE S.a=$a AND S.personnel > 0 AND S.vrel >= $vmin
                ORDER BY S.influence DESC, S.vrel DESC, N.n
            } -default "None." -align LLRRLRL

            ht para

            ht putln "In addition, actor $a receives indirect support from"
            ht putln "the following actors in the following neighborhoods:"

            ht para
            
            ht query {
                SELECT S.alonglink                      AS 'From Actor',
                       S.nlonglink                      AS 'In Nbhood',
                       format('%.2f',I.direct_support)  AS 'Contributed<br>Support'
                FROM gui_supports AS S
                JOIN influence_na AS I USING (n,a)
                WHERE S.supports = $a
                ORDER BY S.a, S.n
            } -default "None." -align LLR
        }

        # ENI Funding
        ht subtitle "ENI Funding" eni

        if {[locked -disclaimer]} {
            ht put {
                The funding of ENI services by this actor is as
                follows.  Civilian groups judge actors by whether
                they are getting sufficient ENI services, and whether
                they are getting more or less than they expect.  
                ENI services also affect each group's mood.
            }

            ht para

            ht query {
                SELECT GA.nlink                AS 'Nbhood',
                       GA.glink                AS 'Group',
                       GA.funding              AS 'Funding<br>$/week',
                       GA.pct_credit           AS 'Actor''s<br>Credit',
                       G.pct_actual            AS 'Actual<br>LOS',
                       G.pct_expected          AS 'Expected<br>LOS',
                       G.pct_required          AS 'Required<br>LOS'
                FROM gui_service_ga AS GA
                JOIN gui_service_g  AS G USING (g)
                WHERE GA.a=$a AND numeric_funding > 0.0
                ORDER BY GA.numeric_funding;
            } -align LLRRRRR
        } 

        # CAP Ownership
        ht subtitle "CAP Ownership" cap

        ht put {
            This actor owns the following Communication Asset
            Packages (CAPs):
        }

        ht para

        ht query {
            SELECT longlink AS "Name",
                   capacity AS "Capacity",
                   cost     AS "Cost, $"
            FROM gui_caps WHERE owner=$a
        } -default "None." -align LRR

        # Deployment
        ht subtitle "Force Deployment" forces

        if {[locked]} {
            ht query {
                SELECT N.longlink              AS 'Neighborhood',
                       P.personnel             AS 'Personnel',
                       G.longlink              AS 'Group',
                       G.fulltype              AS 'Type'
                FROM deploy_ng AS P
                JOIN gui_agroups  AS G ON (G.g=P.g)
                JOIN gui_nbhoods  AS N ON (N.n=P.n)
                WHERE G.a=$a AND personnel > 0
            } -default "No forces are deployed."
        }


        ht subtitle "Attack Status" attack

        if {[locked -disclaimer]} {
            # There might not be any.
            ht push

            rdb eval {
                SELECT nlink,
                       flink,
                       froe,
                       fpersonnel,
                       glink,
                       fattacks,
                       gpersonnel,
                       groe
                FROM gui_conflicts
                WHERE factor = $a;
            } {
                if {$fpersonnel && $gpersonnel > 0} {
                    set bgcolor white
                } else {
                    set bgcolor lightgray
                }

                ht tr bgcolor $bgcolor {
                    ht td left  { ht put $nlink      }
                    ht td left  { ht put $flink      }
                    ht td left  { ht put $froe       }
                    ht td right { ht put $fpersonnel }
                    ht td right { ht put $fattacks   }
                    ht td left  { ht put $glink      }
                    ht td right { ht put $gpersonnel }
                    ht td left  { ht put $groe       }
                }
            }

            set text [ht pop]

            if {$text ne ""} {
                ht putln "Actor $a's force groups have the following "
                ht put   "attacking ROEs."
                ht putln {
                    The background will be gray for potential conflicts,
                    i.e., those in which one or the other group (or both)
                    has no personnel in the neighborhood in question.
                }
                ht para

                ht table {
                    "Nbhood" "Attacker" "Att. ROE" "Att. Personnel"
                    "Max Attacks" "Defender" "Def. Personnel" "Def. ROE"
                } {
                    ht putln $text
                }
            } else {
                ht putln "No group owned by actor $a is attacking any other "
                ht put   "groups."
            }
        }

        ht para


        ht subtitle "Defense Status" defense

        if {[locked -disclaimer]} {
            ht putln "Actor $a's force groups are defending against "
            ht put   "the following attacks:"
            ht para

            ht query {
                SELECT nlink                AS "Neighborhood",
                       glink                AS "Defender",
                       groe                 AS "Def. ROE",
                       gpersonnel           AS "Def. Personnel",
                       flink                AS "Attacker",
                       froe                 AS "Att. ROE",
                       fpersonnel           AS "Att. Personnel"
                FROM gui_conflicts
                WHERE gactor = $a
                AND   fpersonnel > 0
                AND   gpersonnel > 0
            } -default "None."

            ht para
        }

        ht subtitle "Significant Events" sigevents

        if {[locked -disclaimer]} {
            ht putln "
                The following are the most recent significant events 
                involving this actor, oldest first.
            "

            ht para
            
            sigevents -tags $a -mark run
        }

        ht /page

        return [ht get]
    }
}


