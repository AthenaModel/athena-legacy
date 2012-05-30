#-----------------------------------------------------------------------
# TITLE:
#    appserver_overview.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Overview Pages
#
#    my://app/overview/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module OVERVIEW {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /overview {overview/?}    \
            tcl/linkdict [myproc /overview:linkdict] \
            text/html    [myproc /overview:html]     \
            "Overview"

        appserver register /overview/attroe {overview/attroe/?} \
            text/html [myproc /overview/attroe:html] {
                All attacking ROEs for all force groups in all 
                neighborhoods.
            }

        appserver register /overview/defroe {overview/defroe/?} \
            text/html [myproc /overview/defroe:html] {
                All defending ROEs for all uniformed force groups in all 
                neighborhoods.
            }

        appserver register /overview/deployment {overview/deployment/?} \
            text/html [myproc /overview/deployment:html] {
                Deployment of force and organization group personnel
                to neighborhoods.
            }

    }

    #-------------------------------------------------------------------
    # /overview:     Overview of simulation data
    #
    # No match parameters

    # /overview:linkdict udict matchArray
    #
    # Returns a tcl/linkdict of overview pages

    proc /overview:linkdict {udict matchArray} {
        return {
            /sigevents { 
                label "Sig. Events: Recent" 
                listIcon ::projectgui::icon::eye12
            }
            /sigevents/all { 
                label "Sig. Events: All" 
                listIcon ::projectgui::icon::eye12
            }
            /overview/attroe { 
                label "Attacking ROEs" 
                listIcon ::projectgui::icon::eye12
            }
            /overview/defroe { 
                label "Defending ROEs" 
                listIcon ::projectgui::icon::eye12
            }
            /overview/deployment { 
                label "Personnel Deployment" 
                listIcon ::projectgui::icon::eye12
            }
            /nbhoods/prox { 
                label "Neighborhood Proximities" 
                listIcon ::projectgui::icon::eye12
            }
        }
    }

    # /overview:html udict matchArray
    #
    # Formats and displays the overview.ehtml page.

    proc /overview:html {udict matchArray} {
        if {[catch {
            set text [readfile [file join $::app_sim::library overview.ehtml]]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "The Overview page could not be loaded from disk: $result"
        }

        return [tsubst $text]
    }


    #-------------------------------------------------------------------
    # /overview/attroe:  Attacking ROEs
    #
    # No Match Parameters

    # /overview/attroe:html udict matchArray
    #
    # All Attacking ROEs.

    proc /overview/attroe:html {udict matchArray} {
        # Begin the page
        ht page "Attacking ROEs"
        ht title "Attacking ROEs"

        if {![locked -disclaimer]} {
            ht /page
            return [ht get]
        }

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
        } {
            if {$fpersonnel && $gpersonnel > 0} {
                set bgcolor white
            } else {
                set bgcolor lightgray
            }

            ht tr bgcolor $bgcolor {
                ht td left  { ht put $nlink }
                ht td left  { ht put $flink }
                ht td left  { ht put $froe }
                ht td right { ht put $fpersonnel }
                ht td right { ht put $fattacks }
                ht td left  { ht put $glink }
                ht td right { ht put $gpersonnel }
                ht td left  { ht put $groe }
            }
        }

        set text [ht pop]

        if {$text ne ""} {
            ht putln {
                The following attacking ROEs are in force across the
                playbox.  The background will be gray for potential conflicts,
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
            ht putln "No attacking ROEs are in force."
        }

        ht para

        ht /page
        
        return [ht get]
    }


    #-------------------------------------------------------------------
    # /overview/defroe:  Defending ROEs
    #
    # No Match Parameters

    # /overview/defroe:html udict matchArray
    #
    # All Defending ROEs.

    proc /overview/defroe:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Defending ROEs"
        ht title "Defending ROEs"

        if {![locked -disclaimer]} {
            ht /page
            return [ht get]
        }


        ht putln {
            Uniformed force groups are defending themselves given the
            following ROEs across the playbox:
        }

        ht para

        ht query {
            SELECT ownerlink           AS "Owning Actor",
                   glink               AS "Defender",
                   nlink               AS "Neighborhood",
                   roe                 AS "Def. ROE",
                   personnel           AS "Def. Personnel"
            FROM gui_defroe
            WHERE personnel > 0
            ORDER BY owner, g, n
        } -default "None."

        ht para

        ht /page
        
        return [ht get]
    }

    #-------------------------------------------------------------------
    # /overview/deployment:  FRC/ORG group deployments
    #
    # No Match Parameters

    # /overview/deployment:html udict matchArray
    #
    # Returns a text/html of FRC/ORG group deployment.

    proc /overview/deployment:html {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Personnel Deployment"
        ht title "Personnel Deployment"

        if {![locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        ht putln {
            Force and organization group personnel
            are deployed to neighborhoods as follows:
        }
        ht para

        if {![locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        ht query {
            SELECT G.longlink     AS "Group",
                   G.gtype        AS "Type",
                   N.longlink     AS "Neighborhood",
                   D.personnel    AS "Personnel"
            FROM deploy_ng AS D
            JOIN gui_agroups AS G USING (g)
            JOIN gui_nbhoods AS N ON (D.n = N.n)
            WHERE D.personnel > 0
            ORDER BY G.longlink, N.longlink
        } -default "No personnel are deployed." -align LLLR

        ht /page
        
        return [ht get]
    }
}



