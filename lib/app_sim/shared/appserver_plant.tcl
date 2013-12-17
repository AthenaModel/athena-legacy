#-----------------------------------------------------------------------
# TITLE:
#    appserver_plant.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Manufacturing Infrastructure
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
                Links to defined manufacturing infrastructure.
            }
    }

    # /plants:html udict matchArray
    #
    # Tabular display of manufacturing infrastructure data.

    proc /plants:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Manufacturing Plants"
        ht title "Manufacturing Infrastructure"

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
            ht put   "manufacturing plants, owning agents and repair levels."
            ht para 

            ht query {
                SELECT nlink         AS "Neighborhood",
                       alink         AS "Agent",
                       num           AS "Owned Plants",
                       auto_maintain AS "Automatic Maintenance?",
                       rho           AS "Average Repair Level"
                FROM gui_plants_na
                ORDER BY nlink
            } -default "None." -align LLLLL
        }

        ht /page

        return [ht get]
    }
}



