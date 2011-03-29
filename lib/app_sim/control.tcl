#-----------------------------------------------------------------------
# TITLE:
#    control.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Neighborhood Control
#
#    This module is part of the political model.  It is responsible for
#    computing, at initialization and each tock, 
#
#    * The vertical relationship of each group with each actor.
#    * The support each actor has in each neighborhood.
#    * The influence of each actor in each neighborhood, relative to 
#      other actors.
#    * Which actor is in control in each neighborhood (if any).
#
#    In addition, this module is responsible for the bookkeeping when
#    control of a neighborhood shifts.  The relevant DAM rules are 
#    found in control_rules.tcl.
#
#-----------------------------------------------------------------------

snit::type control {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Lookup Tables

    # moodTable - deltaV to do change in mood since last shift in control.
    #
    # Array (sign,inControl) => qmag(n) symbolc
    #
    # sign      - 1 if change is very positive, -1 if change is very 
    #             negative, and 0 otherwise.
    # inControl - 1 if actor is in control of the neighborhood, and 0 
    #             otherwise.

    typevariable moodTable -array {
        -1,1 XL-
        -1,0 M+
         0,1 0
         0,0 0
         1,1 XL+
         1,0 M-
    }



    #-------------------------------------------------------------------
    # Simulation Start

    # start
    #
    # This command is called when the scenario is locked to initialize
    # the model and populate the relevant tables.

    typemethod start {} {
        # FIRST, initialize the control tables
        $type PopulateVerticalRelationships
        $type PopulateActorInfluence
        $type ComputeActorInfluence
        $type PopulateNbhoodControl
    }

    # PopulateVerticalRelationships
    #
    # Populates the vrel_ga table for all groups and actors.
    #
    # For FRC and ORG groups, the vrel is 1.0 when a is their owning actor,
    # and the affinity of their owning actor for a otherwise.
    #
    # For CIV groups, the initial vrel is their affinity for the actor,
    # plus a delta based on the provision of basic services.

    typemethod PopulateVerticalRelationships {} {
        rdb eval {
            SELECT G.g           AS g,
                   G.gtype       AS gtype, 
                   G.rel_entity  AS rel_entity, 
                   A.a           AS a, 
                   V.affinity    AS vrel
            FROM groups       AS G
            JOIN actors       AS A
            JOIN mam_affinity AS V
            ON (V.f=G.rel_entity AND V.g=A.a)
        } {
            # FIRST, if the group's "relationship entity" is the
            # actor itself, the vertical relationship is 1.0.
            # This only happens for FRC and ORG groups.
            if {$rel_entity eq $a} {
                set vrel 1.0
            }

            # NEXT, if this is a civilian group we must add the
            # services term.
            if {$gtype eq "CIV"} {
                # TBD: We don't have civilian services yet.
            }

            rdb eval {
                INSERT INTO vrel_ga(g, a, vrel, bvrel)
                VALUES($g, $a, $vrel, $vrel)
            }
        }
    }

    # PopulateActorInfluence
    #
    # Computes the support for and influence of each actor in
    # each neighborhood.
    
    typemethod PopulateActorInfluence {} {
        # FIRST, populate the influence_na table
        rdb eval {
            INSERT INTO influence_na(n, a)
            SELECT n, a FROM nbhoods JOIN actors
        }
    }

    # PopulateNbhoodControl
    #
    # The actor initially in control in the neighborhood is specified
    # in the nbhoods table.  This routine, consequently, simply 
    # populates the control_n table with that information.

    typemethod PopulateNbhoodControl {} {
        rdb eval {
            INSERT INTO control_n(n, controller, since)
            SELECT n, controller, 0 FROM nbhoods
        }
    }


    #-------------------------------------------------------------------
    # Tock
    #
    # These routines are called during the strategy tock to determine
    # who's in control before assessing strategies.

    # tock
    #
    # Update vrel, influence, and control.

    typemethod tock {} {
        # FIRST, update vertical relationships based on current
        # circumstances.
        $type ComputeVerticalRelationships

        # NEXT, Compute each actor's influence in each neighborhood.
        $type ComputeActorInfluence

        # NEXT, See if control has shifted
        if 0 {
            foreach {n a} {[rdb eval {
                # TBD
            }]} {
                $type ShiftControl $n $a
            }
        }
    }

    # ComputeVerticalRelationships
    #
    # Computes the vertical relationships between each civilian 
    # group and each actor.  (The FRC and ORG group vrel's don't
    # currently change over time.)
    #
    # vrel.ga = bvrel.ga 
    #         + deltaV.beliefs           <== Not yet pertinent
    #         + deltaV.mood 
    #         + deltaV.services          <== Modeling in progress
    #         + deltaV.tactics           <== Not yet modeled
    #
    # So for now, it's the base value plus deltaV.mood.
    # To compute deltaV.mood, I need:
    #
    # * g and a
    # * g's neighborhood, n
    # * Whether a is in control of n or not
    # * g's mood now
    # * g's mood at the time control of n last shifted
    #
    # TBD: Log intermediate results
    
    typemethod ComputeVerticalRelationships {} {
        foreach {g n a bvrel inControl moodNow moodThen} [rdb eval {
            SELECT G.g                               AS g,
                   G.n                               AS n,
                   A.a                               AS a,
                   V.bvrel                           AS bvrel,
                   CASE WHEN (C.controller = A.a)
                        THEN 1 ELSE 0 END            AS inControl,
                   GG.sat                            AS moodNow,
                   HM.sat                            AS moodThen
            FROM civgroups AS G
            JOIN actors    AS A
            JOIN vrel_ga   AS V ON (V.g = G.g AND V.a = A.a)
            JOIN control_n AS C ON (C.n = G.n)
            JOIN gram_g    AS GG ON (G.g = GG.g)
            JOIN hist_mood AS HM ON (HM.g = G.g AND HM.t = C.since)
        }] {
            # FIRST, compute deltaV.mood
            # TBD: These bounds should be model parameters.
            set upper  30.0
            set lower -30.0

            let moodDiff {$moodNow - $moodThen}

            # Look up the magnitude in the table
            if {$moodDiff > $upper} {
                set deltaVmood [qmag value $moodTable(1,$inControl)]
            } elseif {$moodDiff < $lower} {
                set deltaVmood [qmag value $moodTable(-1,$inControl)]
            } else {
                set deltaVmood [qmag value $moodTable(0,$inControl)]
            }

            # NEXT, accumulate, scale,and apply the deltaV's.
            # TBD: When we have multiple deltaV's, we'll need to
            # scale and apply the positive and negative effects 
            # separately.  (Ugh!)
            let deltaV {$deltaVmood/100.0}

            if {$deltaV >= 0.0} {
                let scaledDeltaV {abs(2.0*$deltaV*(1.0 - $bvrel)/2.0)}
            } else {
                let scaledDeltaV {abs(2.0*$deltaV*(1.0 + $bvrel)/2.0)}
            }

            let vrel {$bvrel + $scaledDeltaV}

            rdb eval {
                UPDATE vrel_ga
                SET vrel = $vrel
                WHERE g=$g AND a=$a
            }

            log detail control \
                [format "vrel(%s,%s) = %.3f = %.3f + %.3f, dVmood=%.1f" \
                     $g $a $vrel $bvrel $scaledDeltaV $deltaVmood]
        }
    }

    # ComputeActorInfluence
    #
    # Computes the support for and influence of each actor in
    # each neighborhood.

    typemethod ComputeActorInfluence {} {
        # FIRST, set support and influence to 0.
        rdb eval {
            UPDATE influence_na
            SET support   = 0,
                influence = 0
        }

        # NEXT, add the support of each group in each neighborhood
        # to each actor.
        #
        # TBD: min parameters should come from parmdb
        set vrelMin 0.2
        set secMin 0

        rdb eval {
            SELECT NG.n         AS n,
                   NG.g         AS g,
                   NG.personnel AS personnel,
                   NG.security  AS security, 
                   A.a          AS a,
                   V.vrel       AS vrel
            FROM force_ng AS NG
            JOIN actors   AS A
            JOIN vrel_ga  AS V ON (V.g=NG.g AND V.a=A.a)
            WHERE NG.personnel > 0
            AND   V.vrel >= $vrelMin
            AND   NG.security >= $secMin
        } {
            # TBD: Save contrib in a table, so we can query it for
            # reports. Possibly, a temporary table.
            set contrib [expr {$vrel * $personnel * $security}]

            rdb eval {
                UPDATE influence_na
                SET support = support + $contrib
                WHERE n=$n AND a=$a
            }
        }

        # NEXT, compute the total support for each neighborhood
        rdb eval {
            SELECT n, total(support) AS denom
            FROM influence_na
            GROUP BY n
        } {
            set nsupport($n) $denom
        }
        
        # NEXT, compute the influence of each actor in the 
        # neighborhood.
        rdb eval {
            SELECT n, a, support FROM influence_na
        } {
            if {$nsupport($n) > 0} {
                set influence [expr {double($support) / $nsupport($n)}]
            } else {
                set influence 0.0
            }

            rdb eval {
                UPDATE influence_na
                SET influence=$influence
                WHERE n=$n AND a=$a
            }
        }
    }
}
