#-----------------------------------------------------------------------
# TITLE:
#    appserver_nbhood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Neighborhoods
#
#    my://app/nbhoods/...
#    my://app/nbhood/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module NBHOOD {
    #-------------------------------------------------------------------
    # Type Variables

    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /nbhoods {nbhoods/?} \
            tcl/linkdict [myproc /nbhoods:linkdict] \
            tcl/enumlist [asproc enum:enumlist nbhood] \
            text/html    [myproc /nbhoods:html]                 {
                Links to the currently defined neighborhoods.  The
                HTML content includes neighborhood attributes.
            }

        appserver register /nbhoods/prox {nbhoods/prox/?} \
            text/html    [myproc /nbhoods/prox:html] {
                A tabular listing of neighborhood-to-neighborhood
                proximities.
            }

        appserver register /nbhood/{n} {nbhood/(\w+)/?} \
            text/html [myproc /nbhood:html]             \
            "Detail page for neighborhood {n}."
    }

    #-------------------------------------------------------------------
    # /nbhoods:         - All neighborhoods
    #
    # No match parameters.

    # /nbhoods:linkdict udict matchArray
    #
    # tcl/linkdict of all neighborhoods.
    
    proc /nbhoods:linkdict {udict matchArray} {
        return [objects:linkdict {
            label    "Neighborhoods"
            listIcon ::projectgui::icon::nbhood12
            table    gui_nbhoods
        }]
    }

    # /nbhoods:html udict matchArray
    #
    # Tabular display of neighborhood data; content depends on 
    # simulation state.

    proc /nbhoods:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Neighborhoods"
        ht title "Neighborhoods"

        ht putln "The scenario currently includes the following neighborhoods:"
        ht para

        if {![locked]} {
            ht query {
                SELECT longlink      AS "Neighborhood",
                       local         AS "Local?",
                       urbanization  AS "Urbanization",
                       controller    AS "Controller",
                       vtygain       AS "VtyGain",
                       pcf           AS "Prod. Capacity Factor"
                FROM gui_nbhoods 
                ORDER BY longlink
            } -default "None." -align LLLLRR

        } else {
            ht query {
                SELECT longlink      AS "Neighborhood",
                       local         AS "Local?",
                       urbanization  AS "Urbanization",
                       controller    AS "Controller",
                       since         AS "Since",
                       population    AS "Population",
                       mood0         AS "Mood at T0",
                       mood          AS "Mood Now",
                       vtygain       AS "VtyGain",
                       volatility    AS "Vty",
                       pcf           AS "Prod. Capacity Factor"
                FROM gui_nbhoods
                ORDER BY longlink
            } -default "None." -align LLLLR
        }

        if {![locked]} {
            # Population adjusted for production capacity to aid in 
            # determining manufacturing plant distribution by neighborhood
            set adjpop 0.0

            rdb eval {
                SELECT total(C.basepop) AS nbpop,
                       N.pcf            AS pcf
                FROM civgroups AS C
                JOIN nbhoods AS N ON (N.n=C.n)
                GROUP BY N.n
            } row {
                let adjpop {$adjpop + $row(nbpop)*$row(pcf)}
            }

            if {$adjpop > 0} {
                ht para

                ht put   "The following table is an estimate of manufacturing"
                ht put   " plant distribution in the playbox given the"
                ht put   " neighborhoods and neighborhood populations currently"
                ht putln " defined."
                ht para 

                ht table {
                    "Neighborhood" "Capacity Factor" "Base Pop."
                    "% of Manufacturing Plants"
                } {
                    rdb eval {
                        SELECT nlonglink      AS link,
                               pcf            AS pcf,
                               nbpop          AS nbpop 
                        FROM gui_plants_n
                    } row {
                        set pct  [expr {$row(nbpop)*$row(pcf)/$adjpop*100.0}]

                        ht tr {
                            ht td left  { ht put $row(link)                 }
                            ht td right { ht put [format "%4.1f" $row(pcf)] }
                            ht td right { ht put $row(nbpop)                }
                            ht td right { ht put [format "%4.1f" $pct]      }
                        }
                    }
                }
            }
        } else {

            ht para
            ht put   "The following table shows the current laydown of "
            ht put   "manufacturing plants and the agents that own them "
            ht putln "along with their repair levels."
            ht para 

            ht query {
                SELECT nlink         AS "Neighborhood",
                       alink         AS "Agent",
                       quant         AS "Owned Plants",
                       rho           AS "Average Repair Level"
                FROM gui_plants_na
                ORDER BY nlink
            } -default "None." -align LLLL
        }

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /nbhoods/prox:         - All neighborhood proximities
    #
    # No match parameters.

    # html_Nbrel udict matchArray
    #
    #
    # Tabular display of neighborhood relationship data.

    proc /nbhoods/prox:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Neighborhood Proximities"
        ht title "Neighborhood Proximities"

        ht putln {
            The neighborhoods in the scenario have the following 
            proximities.
        }

        ht para

        ht query {
            SELECT m_longlink      AS "Of Nbhood",
                   n_longlink      AS "With Nbhood",
                   proximity       AS "Proximity"
            FROM gui_nbrel_mn 
            ORDER BY m_longlink, n_longlink
        } -default "No neighborhood proximities exist." -align LLL

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /nbhood/{n}:         - Detail page for neighborhood {n}
    #
    # Match Parameters:
    #
    # {n} ==> $(1)   - Neighborhood name

    # /nbhood:html udict matchArray
    #
    # Formats the summary page for /nbhood/{n}.

    proc /nbhood:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Get the neighborhood
        set n [string toupper $(1)]

        if {![rdb exists {SELECT * FROM nbhoods WHERE n=$n}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        rdb eval {SELECT * FROM gui_nbhoods WHERE n=$n} data {}
        rdb eval {SELECT * FROM econ_n_view WHERE n=$n} econ {}
        rdb eval {
            SELECT * FROM gui_actors  
            WHERE a=$data(controller)
        } cdata {}

        # Begin the page
        ht page "Neighborhood: $n"
        ht title $data(fancy) "Neighborhood" 

        ht linkbar {
            "#civs"      "Civilian Groups"
            "#forces"    "Forces Present"
            "#eni"       "ENI Services"
            "#cap"       "CAP Coverage"
            "#infra"     "Manufacturing Infrastructure"
            "#control"   "Support and Control"
            "#conflicts" "Force Conflicts" 
            "#sigevents" "Significant Events"
        }

        ht para
        
        # Non-local?
        if {!$data(local)} {
            ht putln "$n is located outside of the main playbox."
        }

        # When not locked.
        if {![locked]} {
            ht putln "Resident groups: "

            ht linklist -default "None" [rdb eval {
                SELECT url, g
                FROM gui_civgroups
                WHERE n=$n
                AND basepop > 0 
            }]

            ht put ". "

            if {$data(controller) eq "NONE"} {
                ht putln "No actor is initially in control."
            } else {
                ht putln "Actor "
                ht put "$cdata(link) is initially in control."
            }

            ht para
        }

        # Population, groups.
        if {[locked -disclaimer]} {
            if {$data(population) > 0} {
                set urb    [eurbanization longname $data(urbanization)]
                let labPct {double($data(labor_force))/$data(population)}
                let sagPct {double($data(subsistence))/$data(population)}
                set mood   [qsat name $data(mood)]
        
                ht putln "$data(fancy) is "
                ht putif {$urb eq "Urban"} "an " "a "
                ht put "$urb neighborhood with a population of "
                ht put [commafmt $data(population)]
                ht put ", [percent $labPct] of which are in the labor force and "
                ht put "[percent $sagPct] of which are engaged in subsistence "
                ht put "agriculture."
        
                ht putln "The population belongs to the following groups: "
        
                ht linklist -default "None" [rdb eval {
                    SELECT url,g
                    FROM gui_civgroups
                    WHERE n=$n AND population > 0
                }]
                
                ht put "."
        
                ht putln "Their overall mood is [qsat format $data(mood)] "
                ht put "([qsat longname $data(mood)])."
        
                if {$data(local)} {
                    if {$data(labor_force) > 0} {
                        let rate {double($data(unemployed))/$data(labor_force)}
                        ht putln "The unemployment rate is [percent $rate]."
                    }
                    ht putln "$n's production capacity is [percent $econ(pcf)]."
                }
                ht para
            } else {
                ht putln "The neighborhood currently has no civilian population."
                ht para
            }
            
            # Actors
            if {$data(controller) eq "NONE"} {
                ht putln "$n is currently in a state of chaos: "
                ht put   "no actor is in control."
            } else {
                ht putln "Actor $cdata(link) is currently in control of $n."
            }
    
            ht putln "Actors with forces in $n: "
    
            ht linklist -default "None" [rdb eval {
                SELECT DISTINCT '/actor/' || a, a
                FROM gui_agroups
                JOIN force_ng USING (g)
                WHERE n=$n AND personnel > 0
                ORDER BY personnel DESC
            }]
    
            ht put "."
    
            ht putln "Actors with influence in $n: "
    
            ht linklist -default "None" [rdb eval {
                SELECT DISTINCT A.url, A.a
                FROM influence_na AS I
                JOIN gui_actors AS A USING (a)
                WHERE I.n=$n AND I.influence > 0
                ORDER BY I.influence DESC
            }]
    
            ht put "."
    
            ht para
    
            # Groups
            ht putln \
                "The following force and organization groups are" \
                "active in $n: "
    
            ht linklist -default "None" [rdb eval {
                SELECT G.url, G.g
                FROM gui_agroups AS G
                JOIN force_ng    AS F USING (g)
                WHERE F.n=$n AND F.personnel > 0
            }]
    
            ht put "."
        }   

        ht para

        # Civilian groups
        ht subtitle "Civilian Groups" civs

        if {[locked -disclaimer]} {
            
            ht putln "The following civilian groups live in $n:"
            ht para
    
            ht query {
                SELECT G.longlink  
                           AS 'Name',
                       G.population 
                           AS 'Population',
                       pair(qsat('format',G.mood), qsat('longname',G.mood))
                           AS 'Mood',
                       pair(qsecurity('format',S.security), 
                            qsecurity('longname',S.security))
                           AS 'Security'
                FROM gui_civgroups AS G
                JOIN force_ng      AS S USING (g)
                WHERE G.n=$n AND S.n=$n AND population > 0
                ORDER BY G.g
            }
        }

        ht para

        # Force/Org groups
        ht subtitle "Forces Present" forces

        if {[locked -disclaimer]} {
            ht query {
                SELECT G.longlink
                           AS 'Group',
                       P.personnel 
                           AS 'Personnel', 
                       G.fulltype
                           AS 'Type',
                       CASE WHEN G.gtype='FRC'
                       THEN pair(C.coop, qcoop('longname',C.coop))
                       ELSE 'n/a' END
                           AS 'Coop. of Nbhood'
                FROM force_ng     AS P
                JOIN gui_agroups  AS G USING (g)
                LEFT OUTER JOIN gui_coop_ng  AS C ON (C.n=P.n AND C.g=P.g)
                WHERE P.n=$n
                AND   personnel > 0
                ORDER BY G.g
            } -default "None."
        }
        
        ht para

        # ENI Services
        ht subtitle "ENI Services" eni

        if {$data(population) == 0} {
            ht putln {
                This neighborhood has no population to require
                services.
            }
            ht para
        } elseif {[locked -disclaimer]} {
            ht putln {
                Actors can provide Essential Non-Infrastructure (ENI) 
                services to the civilians in this neighborhood.  The level
                of service currently provided to the groups in this
                neighborhood is as follows.
            }
    
            ht para
    
            rdb eval {
                SELECT g,alink FROM gui_service_ga WHERE numeric_funding > 0.0
            } {
                lappend funders($g) $alink
            }
    
            ht table {
                "Group" "Funding,<br>$/week" "Actual" "Required" "Expected" 
                "Funding<br>Actors"
            } {
                rdb eval {
                    SELECT g, longlink, funding, pct_required, 
                           pct_actual, pct_expected 
                    FROM gui_service_g
                    JOIN nbhoods USING (n)
                    JOIN demog_g USING (g)
                    WHERE n = $n AND demog_g.population > 0
                    ORDER BY g
                } row {
                    if {![info exists funders($row(g))]} {
                        set funders($row(g)) "None"
                    }
                    
                    ht tr {
                        ht td left  { ht put $row(longlink)                }
                        ht td right { ht put $row(funding)                 }
                        ht td right { ht put $row(pct_actual)              }
                        ht td right { ht put $row(pct_required)            }
                        ht td right { ht put $row(pct_expected)            }
                        ht td left  { ht put [join $funders($row(g)) ", "] }
                    }
                }
            }
    
            ht para
            ht putln {
                Service is said to be saturated when additional funding
                provides no additional service to the civilians.  We peg
                this level of service as 100% service, and express the actual,
                required, and expected levels of service as percentages.
                level required for survival.  The expected level of
                service is the level the civilians expect to receive
                based on past history.
            }
        }

        ht para

        # CAP coverage
        ht subtitle "CAP Coverage" cap
        
        set hascapcov [rdb eval {
                           SELECT count(*) FROM capcov 
                           WHERE n=$n AND nbcov > 0.0
                       }]

        if {$hascapcov} {
            ht putln {
                Some groups in this neighborhood can be reached by 
                Communication Asset Packages (CAPs). The following is 
                a list of the groups resident in this neighborhood
                with the CAPs cover them.
            }

            ht para

            ht query {
                SELECT C.longlink                   AS "CAP",
                       C.owner                      AS "Owned By",
                       C.capacity                   AS "Capacity",
                       CC.glink                     AS "Group",
                       CC.nbcov                     AS "Nbhood Coverage",
                       CC.pen                       AS "Group Penetration",
                       "<b>" || CC.capcov || "</b>" AS "CAP Coverage"
                FROM gui_caps AS C
                JOIN gui_capcov AS CC USING( k)
                JOIN demog_g AS G USING (g)
                WHERE CC.n = $n
                AND CC.raw_nbcov > 0.0
                AND G.population > 0
            } -default "None." -align LLRLRRR
        } else {
            ht putln "This neighborhood is not covered by any"
            ht putln "Communication Asset Packages."
        }

        ht para

        # Manufacturing Infrastructure
        ht subtitle "Manufacturing Infrastructure" infra

        ht put {
            The number and laydown of manufacturing plants when the 
            scenario is locked depends on a number of things: the 
            production capacity of a neighborhood, the amount of goods
            a single plant can produce, and the repair level of plants
            at initialization.  
        }
            
        if {![locked]} {
            ht put {
                Given the production capacity of a single
                manufacturing plant, Athena will allocate just enough plants
                to meet the initial production demanded by the economic model
                taking into account repair level and neighborhood production 
                capacity.  Athena will then lay them down according to agent
                shares of ownership.  To increase capacity after lock, either
                plants in disrepair need to be fixed or new plants built or
                both.
            }
        }

        ht para

        if {![locked]} {
            ht put {
                The percentage of plants that this neighborhood will get 
                when locked is approximately shown as follows.  When the 
                scenario is locked the actual number of plants and their 
                owning agent will be shown along with the average repair 
                level.  These numbers are approximate because the 
                demographics may be different after the scenario is locked.
            }

            ht para

            set adjpop 0.0

            rdb eval {
                SELECT total(C.basepop) AS nbpop,
                       N.pcf            AS pcf
                FROM civgroups AS C
                JOIN nbhoods AS N ON (N.n=C.n)
                GROUP BY N.n
            } row {
                let adjpop {$adjpop + $row(nbpop)*$row(pcf)}
            }

            if {$adjpop > 0} {
                ht table {
                    "Neighborhood" "Prod. Capacity Factor" "Base Pop."
                    "% of Manufacturing Plants"
                } {
                    rdb eval {
                        SELECT nlonglink      AS link,
                               pcf            AS pcf,
                               nbpop          AS nbpop 
                        FROM gui_plants_n
                        WHERE n=$n
                    } row {
                        set pct  [expr {$row(nbpop)*$row(pcf)/$adjpop*100.0}]

                        ht tr {
                            ht td left  { ht put $row(link)                 }
                            ht td right { ht put [format "%4.1f" $row(pcf)] }
                            ht td right { ht put $row(nbpop)                }
                            ht td right { ht put [format "%4.1f" $pct]      }
                        }
                    }
                }
            } else {
                ht put {
                    The scenario has no population defined yet.
                }
            }
        } else {
            ht para
            ht put   "The following table shows the current laydown of "
            ht put   "manufacturing plants in $n and the agents that own "
            ht putln "them along with the average repair levels."
            ht para 

            ht query {
                SELECT nlink         AS "Neighborhood",
                       alink         AS "Agent",
                       quant         AS "Owned Plants",
                       rho           AS "Average Repair Level"
                FROM gui_plants_na
                WHERE n=$n
            } -default "None." -align LLLL

            ht para

            set capN [plant capacity n $n]
            set capT [plant capacity total]
            set pct  [format "%.2f" [expr {($capN/$capT) * 100.0}]]

            ht put "
                The manufacturing plants in this neighborhood are currently
                producing [moneyfmt $capN] goods baskets annually.  This is
                $pct% of the goods production capacity of the entire economy.  
                This neighborhood has a production capacity factor of 
                $econ(pcf).
            "

        }
        # Support and Control
        ht subtitle "Support and Control" control

        if {[locked -disclaimer]} {
            if {$data(controller) eq "NONE"} {
                ht putln "$n is currently in a state of chaos: "
                ht put   "no actor is in control."
            } else {
                ht putln "Actor $cdata(link) is currently in control of $n."
            }
    
            ht putln "The actors with support in this neighborhood are "
            ht putln "as follows."
            ht putln "Note that an actor has influence in a neighborhood"
            ht putln "only if his total support from groups exceeds"
            ht putln [format %.2f [parm get control.support.min]].
            ht para
    
            ht query {
                SELECT A.longlink                      AS 'Actor',
                       format('%.2f',I.influence)      AS 'Influence',
                       format('%.2f',I.direct_support) AS 'Direct Support',
                       format('%.2f',I.support)        AS 'Total Support'
                FROM influence_na AS I
                JOIN gui_actors   AS A USING (a)
                WHERE I.n = $n AND I.influence > 0.0
                ORDER BY I.influence DESC
            } -default "None." -align LR
    
            ht para
            ht putln "Actor support comes from the following groups."
            ht putln "Note that a group only supports an actor if"
            ht putln "its vertical relationship with the actor is at"
            ht putln "least [parm get control.support.vrelMin], or if"
            ht putln "another actor lends his direct support to the"
            ht putln "first actor.  See each actor's page for a"
            ht putln "detailed analysis of the actor's support and"
            ht putln "influence."
            ht para
    
            ht query {
                SELECT A.link                            AS 'Actor',
                       G.link                            AS 'Group',
                       format('%.2f',S.influence)        AS 'Influence',
                       qaffinity('format',S.vrel)        AS 'Vert. Rel.',
                       G.g || ' ' || 
                         qaffinity('longname',S.vrel) ||
                         ' ' || A.a                      AS 'Narrative',
                       commafmt(S.personnel)             AS 'Personnel',
                       qfancyfmt('qsecurity',S.security) AS 'Security'
                FROM support_nga AS S
                JOIN gui_groups  AS G ON (G.g = S.g)
                JOIN gui_actors  AS A ON (A.a = S.a)
                WHERE S.n=$n AND S.personnel > 0
                ORDER BY S.influence DESC, S.vrel DESC, A.a
            } -default "None." -align LLRRLRL
        }

        ht para

        ht subtitle "Force Conflicts" conflicts

        if {[locked -disclaimer]} {
            ht putln "The following force groups are actively in conflict "
            ht put   "in neighborhood $n:"
            ht para
    
            ht query {
                SELECT flink                AS "Attacker",
                       froe                 AS "Att. ROE",
                       fpersonnel           AS "Att. Personnel",
                       glink                AS "Defender",
                       groe                 AS "Def. ROE",
                       gpersonnel           AS "Def. Personnel"
                FROM gui_conflicts
                WHERE n=$n
                AND   fpersonnel > 0
                AND   gpersonnel > 0
            } -default "None."
        }

        ht para

        ht subtitle "Significant Events" sigevents

        if {[locked -disclaimer]} {
            appserver::SIGEVENTS recent $n
        }

        ht /page

        return [ht get]
    }
}



