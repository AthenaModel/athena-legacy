#-----------------------------------------------------------------------
# TITLE:
#    appserver_plant.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: GOODS Production Infrastructure
#
#    my://app/plants
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module PLANT {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /plants/ {plants/?} \
            text/html    [myproc /plants:html] {
                Links to defined GOODS production infrastructure.
            }

        appserver register /plants/detail/  {plants/detail/?} \
            text/html  [myproc /plants/detail:html]            \
            "Links to the bins of plants under construction."
    }

    # /plants:html udict matchArray
    #
    # Tabular display of GOODS production infrastructure data.

    proc /plants:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "GOODS Production Plants"
        ht title "GOODS Production Infrastructure"

        if {![locked]} {
            # Population adjusted for production capacity to aid in 
            # determining GOODS production plant distribution by neighborhood
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

                ht put   "The following table is an estimate of GOODS "
                ht put   "production plant distribution in the playbox "
                ht put   "given the neighborhoods and neighborhood "
                ht put   "populations currently defined.  Only local "
                ht put   "neighborhoods can contain GOODS production "
                ht putln "GOODS production infrastructure."
                ht para 

                ht table {
                    "Neighborhood" "Capacity<br>Factor" "Base Pop."
                    "% of GOODS<br>Production Plants"
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
            } else {

                ht put "None."
                ht para
            }

        } else {

            if {[parmdb get econ.disable]} {
                ht para
                ht put "The Economic model is disabled, so the infrastructure "
                ht put "model is not in use."
                ht para
                ht /page
                return [ht get]
            }

            ht para
            ht put   "The following table shows the current laydown of "
            ht put   "GOODS production plants, owning agents and repair "
            ht put   "levels.  Plants under construction will appear in "
            ht put   "this table when they are 100% complete.  Non-local "
            ht put   "neighborhoods do not appear in this table since GOODS "
            ht put   "production infrastructure cannot exist in them."
            ht para 

            ht query {
                SELECT nlink          AS "Neighborhood",
                       alink          AS "Agent",
                       num            AS "Plants In<br>Operation",
                       auto_maintain  AS "Automatic<br>Maintenance?",
                       rho            AS "Average<br>Repair Level"
                FROM gui_plants_na
                ORDER BY nlink
            } -default "None." -align LLLLL
        }

        ht para

        ht put "The following table breaks down GOODS production plants under "
        ht put "construction by neighborhood and actor into ranges of "
        ht put "percentage complete.  Clicking on "
        ht put "[ht link /plants/detail "detail"] will break construction "
        ht put "levels down even further."
        ht para

        ht push 

        ht table {
            "Nbhood" "Owner" "Total" "&lt 20%" "20%-40%" 
            "40%-60%" "60%-80%" "&gt 80%" "" 
        } {
            rdb eval {
                SELECT n, a, nlink, alink, levels
                FROM gui_plants_build
            } {
                array set bins {0 0 20 0 40 0 60 0 80 0}
                set total [llength $levels]
                foreach lvl $levels {
                    if {$lvl < 0.2} {
                        incr bins(0)
                    } elseif {$lvl >= 0.2 && $lvl < 0.4} {
                        incr bins(20)
                    } elseif {$lvl >= 0.4 && $lvl < 0.6} {
                        incr bins(40)
                    } elseif {$lvl >= 0.6 && $lvl < 0.8} {
                        incr bins(60)
                    } elseif {$lvl >= 0.8} {
                        incr bins(80)
                    }
                }

                ht tr {
                    ht td left {
                        ht put $nlink
                    }

                    ht td left {
                        ht put $alink
                    }

                    ht td center {
                        ht put $total
                    }

                    ht td center {
                        ht put $bins(0)
                    }

                    ht td center {
                        ht put $bins(20)
                    }

                    ht td center {
                        ht put $bins(40)
                    }

                    ht td center {
                        ht put $bins(60)
                    }

                    ht td center {
                        ht put $bins(80)
                    }

                    ht td center {
                        ht link /plants/detail/ "Detail"
                    }
                }
            }
        }

        set text [ht pop]

        if {[ht rowcount] > 0} {
            ht putln $text
        } else {
            ht putln "None."
        }

        ht /page

        return [ht get]
    }

    proc /plants/detail:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "GOODS Production Plants Under Construction"
        ht title "GOODS Production Plants Under Construction"

        if {![locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        set data [dict create]

        rdb eval {
            SELECT n, nlink, a, alink, levels
            FROM gui_plants_build
        } {
            if {![dict exists $data [list $nlink $alink]]} {
                dict set data [list $nlink $alink] {}
            }

            set pcts [lmap $levels x {format %.1f%% [expr {100*$x}]}]

            set pdict [dict create]

            foreach pct $pcts {
                if {[dict exists $pdict $pct]} {
                    let count {[dict get $pdict $pct] + 1}
                    dict set pdict $pct $count
                } else {
                    dict set pdict $pct 1
                }
            }

            set clist [list]
            foreach key [dict keys $pdict] {
                lappend clist "[dict get $pdict $key]@$key"
            }

            dict set data [list $nlink $alink] $clist
        }


        ht put {
            The following table shows the number of plants completed
            by neighborhood and actor grouped by approximate percentage
            complete.  For instance, if an actor has 10 plants under 
            construction in a neighborhood that are all within a tenth 
            of a percent of 30.0% complete then those plants are shown 
            as \"10@30.0%\".
        }

        ht para

        ht push

        ht table {"Nbhood" "Owner" "Plants<br>% Complete"} {
            dict with data {}

            set nalist [dict keys $data]

            foreach pair $nalist {
                lassign $pair nlink alink

                set plants [dict get $data $pair]

                if {[llength $plants] == 0} {
                    continue
                }

                ht tr {
                    ht td left {
                        ht put $nlink
                    }

                    ht td left {
                        ht put $alink
                    }

                    ht td left {
                        ht put $plants
                    }
                }
            }
        }

        set text [ht pop]

        if {[ht rowcount] > 0} {
            ht putln $text
        } else {
            ht putln "No plants under construction."
        }

        ht /page

        return [ht get]
    }
}



