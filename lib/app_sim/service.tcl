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
    # Simulation 

    # start
    #
    # This routine is called when the scenario is locked and the 
    # simulation starts.  It populates the service_* tables.
    # tables.

    typemethod start {} {
        rdb eval {
            -- Populate service_ga table.
            INSERT INTO service_ga(g,a)
            SELECT g, a
            FROM civgroups JOIN actors;

            -- Populate service_g table.
            INSERT INTO service_g(g)
            SELECT g FROM civgroups;
        }
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

            # At time 0, the old expected value is
            # exactly the just-computed actual.
            if {[simclock now] == 0} {
                set oldX $Ag
            }

            # Get the smoothing constant.
            if {$Ag > $oldX} {
                set alpha [parm get service.ENI.alphaA]
            } else {
                set alpha [parm get service.ENI.alphaX]
            }

            # Compute the expected value
            let Xg {$oldX + $alpha*(min(1.0,$Ag) - $oldX)}

            # Save the new values
            rdb eval {
                UPDATE service_g
                SET saturation_funding = $Pg,
                    required           = $Rg,
                    funding            = $Fg,
                    actual             = $Ag,
                    expected           = $Xg
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
                   NEW.funding - OLD.funding     AS delta
            FROM service_ga AS OLD
            JOIN working_service_ga AS NEW USING (g,a)
            WHERE abs(delta) >= 1.0
            ORDER BY delta DESC, a, g
        } {
            if {$delta > 0} {
                sigevent log 1 strategy "
                    Actor {actor:$a} increased ENI funding to {group:$g}
                    by [moneyfmt $delta] to [moneyfmt $new].
                " $a $g
            } else {
                let delta {-$delta}

                sigevent log 1 strategy "
                    Actor {actor:$a} decreased ENI funding to {group:$g}
                    by [moneyfmt $delta] to [moneyfmt $new].
                " $a $g
            }
        }
    }
}



