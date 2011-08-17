#-----------------------------------------------------------------------
# TITLE:
#    service.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Service Manager
#
#    This module is responsible for managing the provision of
#    services to civilian groups.  At present, the only service
#    defined is Essential Non-Infrastructure Services (ENI), 
#    aka "governmental services".  The ENI service allows an actor
#    to pump money into neighborhoods, thus raising group moods
#    and vertical relationships.
#
#-----------------------------------------------------------------------

snit::type service {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Look-up tables

    # deltav: deltaV.eni magnitude given these variables:
    #
    # Control: C, NC
    #
    #   C   - Actor is in control of group's neighborhood.
    #   NC  - Actor is not in control of group's neighborhood.
    #
    # Credit: N, S, M
    #
    #   N   - Actor's contribution is a Negligible fraction of total
    #   S   - Actor has contributed Some of the total
    #   M   - Actor has contributed Most of the total
    #
    # case: R-, E-, E, E+
    #
    #   R-  - actual LOS is less than required.
    #   E-  - actual LOS is at least the required amount, but less than
    #         expected.
    #   E   - actual LOS is approximately the same as expected
    #   E+  - actual LOS is more than expected.

    typevariable deltav -array {
        C,N,R-  XXL-
        C,N,E-  XL-
        C,N,E   L+
        C,N,E+  XL+

        C,S,R-  XL-
        C,S,E-  L-
        C,S,E   L+
        C,S,E+  XL+

        C,M,R-  L-
        C,M,E-  M-
        C,M,E   L+
        C,M,E+  XL+

        NC,N,R- 0
        NC,N,E- 0
        NC,N,E  0
        NC,N,E+ 0

        NC,S,R- S+
        NC,S,E- M+
        NC,S,E  L+
        NC,S,E+ XL+

        NC,M,R- M+
        NC,M,E- L+
        NC,M,E  XL+
        NC,M,E+ XXL+
    }



    #-------------------------------------------------------------------
    # Simulation 

    # start
    #
    # This routine is called when the scenario is locked and the 
    # simulation starts.  It populates the service_* tables.
    # tables.

    typemethod start {} {
        # FIRST, populate the tables with the status quo data
        # and defaults.
        rdb eval {
            -- Populate service_ga table from status quo
            INSERT INTO service_ga(g,a, funding)
            SELECT g, a, funding
            FROM sqservice_view;

            -- Populate service_g table.
            INSERT INTO service_g(g)
            SELECT g FROM civgroups;
        }

        # NEXT, compute the actual and expected levels of 
        # service for the status quo.
        $type ComputeLOS -start
    }

    # load
    #
    # Populates the working tables for strategy execution.

    typemethod load {} {
        rdb eval {
            DELETE FROM working_service_ga;
            INSERT INTO working_service_ga(g,a)
            SELECT g, a FROM civgroups JOIN actors;
        }
    }

    # fundeni a amount glist
    #
    # a        - An actor
    # amount   - ENI funding, in $/week
    # glist    - List of groups to be funded.
    #
    # This routine is called by the FUNDENI tactic.  It allocates
    # the funding to the listed groups in proportion to their
    # population.

    typemethod fundeni {a amount glist} {
        require {$amount > 0} \
            "Attempt to fund ENI with zero or negative amount: $amount"

        require {[llength $glist] != 0} \
            "Attempt to fund ENI for empty list of groups"

        # FIRST, get the "in" clause
        set gclause "g IN ('[join $glist ',']')"

        # NEXT, get the total number of personnel in the groups
        set total [rdb onecolumn "
            SELECT total(population) FROM demog_g
            WHERE $gclause
        "]

        require {$total > 0} \
            "Attempt to fund ENI for zero population"

        # NEXT, get the proportion of people in each group:
        set fracs [rdb eval "
            SELECT g, (CAST (population AS REAL))/\$total
            FROM demog_g
            WHERE $gclause
        "]

        # NEXT, fund each group with their proportion of the money.
        dict for {g frac} $fracs {
            let share {$frac*$amount}

            rdb eval {
                UPDATE working_service_ga
                SET funding = funding + $share
                WHERE g=$g AND a=$a
            }
        }
    }

    # save
    #
    # Saves the working data back to the persistent tables,
    # and computes the current level of service for all groups.

    typemethod save {} {
        # FIRST, log all changed levels of funding
        $type LogFundingChanges

        # NEXT, save data back to the persistent tables
        rdb eval {
            SELECT g, a, funding
            FROM working_service_ga
        } {
            rdb eval {
                UPDATE service_ga
                SET funding = $funding
                WHERE g=$g AND a=$a
            }
        }

        # NEXT, Compute the actual and expected levels of service.
        $type ComputeLOS
    }


    # ComputeLOS ?-start?
    #
    # -start    - Set expected LOS to actual LOS
    #
    # Computes the actual and expected levels of service.  If
    # -start is given, the expected LOS is initialized to the
    # actual; otherwise, it follows the actual LOS using 
    # exponential smoothing.

    typemethod ComputeLOS {{mode ""}} {
        foreach {g n urb pop Fg oldX} [rdb eval {
            SELECT G.g                AS g,
                   G.n                AS n,
                   N.urbanization     AS urb,
                   D.population       AS pop,
                   total(SGA.funding) AS Fg,
                   SG.expected        AS oldX
            FROM civgroups  AS G 
            JOIN nbhoods    AS N   USING (n)
            JOIN demog_g    AS D   ON (D.g = G.g)
            JOIN service_ga AS SGA ON (SGA.g = G.g)
            JOIN service_g  AS SG  ON (SG.g = G.g)
            GROUP BY G.g
        }] {
            # Compute the actual value
            set Sr   [parm get service.ENI.saturationCost.$urb]
            let Pg   {$pop * $Sr}
            set Rg   [parm get service.ENI.required.$urb]
            set beta [parm get service.ENI.beta.$urb]

            let Ag   {($Fg/$Pg)**$beta}

            # The status quo expected value is the same as the
            # status quo actual value (but not more than 1.0).
            if {$mode eq "-start"} {
                let oldX {min(1.0,$Ag)}
            }

            # Get the smoothing constant.
            if {$Ag > $oldX} {
                set alpha [parm get service.ENI.alphaA]
            } else {
                set alpha [parm get service.ENI.alphaX]
            }

            # Compute the expected value
            let Xg {$oldX + $alpha*(min(1.0,$Ag) - $oldX)}

            # Compute the excess value
            let excess {min(1.0,$Ag) - $Xg}

            # Compute the enough value
            # What if Rg is 1.0?  What if Rg is 0.0?
            if {$Ag == 0.0} {
                set enough 0.0
            } elseif {$Ag >= 1.0} {
                set enough 1.0
            } elseif {$Ag <= $Rg} {
                let enough {($Ag - $Rg)/$Rg}
            } else {
                let enough {($Ag - $Rg)/(1-$Rg)}
            }

            # Save the new values
            rdb eval {
                UPDATE service_g
                SET saturation_funding = $Pg,
                    required           = $Rg,
                    funding            = $Fg,
                    actual             = $Ag,
                    expected           = $Xg,
                    excess             = $excess,
                    enough             = $enough
                WHERE g=$g;
            }
        }
    }


    # LogFundingChanges
    #
    # Logs all funding changes.

    typemethod LogFundingChanges {} {
        rdb eval {
            SELECT OLD.g                         AS g,
                   OLD.a                         AS a,
                   OLD.funding                   AS old,
                   NEW.funding                   AS new,
                   NEW.funding - OLD.funding     AS delta,
                   civgroups.n                   AS n
            FROM service_ga AS OLD
            JOIN working_service_ga AS NEW USING (g,a)
            JOIN civgroups ON (civgroups.g = OLD.g)
            WHERE abs(delta) >= 1.0
            ORDER BY delta DESC, a, g
        } {
            if {$delta > 0} {
                sigevent log 1 strategy "
                    Actor {actor:$a} increased ENI funding to {group:$g}
                    by [moneyfmt $delta] to [moneyfmt $new].
                " $a $g $n
            } else {
                let delta {-$delta}

                sigevent log 1 strategy "
                    Actor {actor:$a} decreased ENI funding to {group:$g}
                    by [moneyfmt $delta] to [moneyfmt $new].
                " $a $g $n
            }
        }
    }

    #-------------------------------------------------------------------
    # Assessment
    #
    # This section contains the code to compute each actor's credit
    # wrt each group, and the deltaV.eni.ga
    #
    # This is separate from the LOS code because it needs to be computed
    # as part of V.ga by control(sim).

    # assess deltav
    #
    # Compute each actor's service_ga.credit in service_ga, and set 
    # vrel_ga.dv_eni

    typemethod {assess deltav} {} {
        # FIRST, compute each actor's credit.
        $type ComputeCredit

        # NEXT, compute dv_eni
        $type ComputeDV_eni
    }

    # ComputeCredit
    #
    # Credits each actor with the fraction of service provided to each
    # civilian group.  First, the actor in control of the neighborhood
    # gets credit for the fraction of service he provides, up to 
    # saturation.  Credit for any fraction of service beyond that but
    # still below saturation is split between the other actors
    # in proportion to their funding.

    typemethod ComputeCredit {} {
        # FIRST, initialize every actor's credit to 0.0
        rdb eval { UPDATE service_ga SET credit = 0.0; }

        # NEXT, Prepare to compute the controlling actor's credit.
        foreach g [civgroup names] {
            set controller($g) ""
            set conCredit($g)  0.0
        }

        # NEXT, For each controlling actor and group, get the actor's 
        # credit for funding that group.
        rdb eval {
            SELECT C.g                   AS g, 
                   CN.controller         AS a,
                   SGA.funding           AS funding,
                   SG.saturation_funding AS saturation,
                   SG.funding            AS total
            FROM civgroups AS C
            JOIN control_n AS CN USING (n)
            JOIN service_ga AS SGA ON (SGA.g = C.g AND SGA.a = CN.controller)
            JOIN service_g  AS SG  USING (g);
        } {
            if {$funding == 0.0} {
                set credit 0.0
            } else {
                let credit {min(1.0, $funding / min($total, $saturation))}
            }

            set controller($g) $a
            set conCredit($g) $credit
        }

        # NEXT, get the total funding for each group by actors
        # who do NOT control the neighborhood.
        array set denom [rdb eval {
            SELECT g, total(funding)
            FROM service_ga
            JOIN civgroups USING (g)
            JOIN control_n USING (n)
            WHERE coalesce(controller,'') != a
            GROUP BY g
        }]

        # NEXT, compute the credit
        foreach {g a funding} [rdb eval {
            SELECT g, a, funding
            FROM service_ga
        }] {
            if {$a eq $controller($g)} {
                set credit $conCredit($g)
            } elseif {$funding > 0.0} {
                let credit {($funding/$denom($g))*(1 - $conCredit($g))}
            } else {
                set credit 0.0
            }
            
            rdb eval {
                UPDATE service_ga
                SET credit = $credit
                WHERE g=$g AND a=$a
            }
        }
    }

    # ComputeDV_eni
    #
    # Computes vrel_ga.dv_eni, the deltaV due to ENI services.  Does
    # not update the vertical relationship itself.

    typemethod ComputeDV_eni {} {
        # FIRST, get the delta parameter
        set delta [parmdb get service.ENI.delta]

        # FIRST, compute dv_eni for all actors and groups.
        rdb eval {
            SELECT SGA.g                             AS g,
                   SGA.a                             AS a,
                   SGA.credit                        AS credit,
                   SG.actual                         AS actual,
                   SG.expected                       AS expected,
                   SG.required                       AS required,
                   CASE WHEN (C.controller = SGA.a)
                        THEN 'C' ELSE 'NC' END       AS inControl
            FROM service_ga AS SGA
            JOIN service_g  AS SG USING (g)
            JOIN civgroups  AS G  USING (g)
            JOIN control_n  AS C  USING (n)
        } {
            # FIRST, compute contribution
            if {$credit < 0.2} {
                # Contribution is negligible
                set cont N
            } elseif {$credit <= 0.5} {
                # actor is contributing some of the funding.
                set cont S
            } else {
                # actor is contributing most of the funding.
                set cont M
            }

            # NEXT, compute case.
            if {$actual < $required} {
                set case R-
            } elseif {abs($actual - $expected) < $delta * $expected} {
                set case E
            } elseif {$actual < $expected} {
                set case E-
            } else {
                set case E+
            }

            # NEXT, get the deltaV
            set dv_eni [qmag value $deltav($inControl,$cont,$case)]

            rdb eval {
                UPDATE vrel_ga
                SET dv_eni=$dv_eni
                WHERE g=$g AND a=$a
            }
        }
    }

}



