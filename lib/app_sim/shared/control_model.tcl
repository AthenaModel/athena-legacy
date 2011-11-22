#-----------------------------------------------------------------------
# TITLE:
#    control_model.tcl
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

snit::type control_model {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Lookup Tables

    # moodTable - deltaV to do change in mood since last shift in control.
    #
    # Array (sign,inControl) => qmag(n) symbol
    #
    # sign      - 1 if change is very positive, -1 if change is very 
    #             negative, and 0 otherwise.
    # inControl - 1 if actor is in control of the neighborhood, and 0 
    #             otherwise.
    #
    # TBD: Eventually, this should probably be a set of model parameters.

    typevariable moodTable -array {
        -1,1 XL-
        -1,0 M+
         0,1 0
         0,0 0
         1,1 XL+
         1,0 M-
    }

    # controlTable - deltaV to bvrel due to change in control
    #
    # Array (vrel,change) => qmag(n) symbol
    #
    # vrel     - vrel.ga, expressed as a qaffinity symbol.
    # change   - 1 if a has just gained control, -1 if a has just lost
    #            control, and 0 otherwise.
    #
    # TBD: Eventually, this should probably be a set of model parameters.

    typevariable controlTable -array {
        SUPPORT,1   L+
        SUPPORT,0   M-
        SUPPORT,-1  L-

        LIKE,1      M+
        LIKE,0      S-
        LIKE,-1     M-

        INDIFF,1    0
        INDIFF,0    0
        INDIFF,-1   0

        DISLIKE,1   M-
        DISLIKE,0   0
        DISLIKE,-1  XS-

        OPPOSE,1    L-
        OPPOSE,0    0
        OPPOSE,-1   S-
    }

    #-------------------------------------------------------------------
    # Simulation Start

    # start
    #
    # This command is called when the scenario is locked to initialize
    # the model and populate the relevant tables.

    typemethod start {} {
        log normal control_model "start"

        # FIRST, initialize the control tables
        $type PopulateNbhoodControl
        $type PopulateVerticalRelationships
        $type PopulateActorSupports
        $type PopulateActorInfluence

        log normal control_model "start complete"
    }

    # PopulateNbhoodControl
    #
    # The actor initially in control in the neighborhood is specified
    # in the nbhoods table.  This routine, consequently, simply 
    # populates the control_n table with that information.  Note
    # that "controller" is NULL if no actor controls the neighborhood.

    typemethod PopulateNbhoodControl {} {
        rdb eval {
            INSERT INTO control_n(n, controller, since)
            SELECT n, controller, 0 FROM nbhoods
        }
    }

    # PopulateVerticalRelationships
    #
    # Populates the vrel_ga table for all groups and actors.
    #
    # For FRC and ORG groups, the vrel is 1.0 when a is their owning actor,
    # and the affinity of their owning actor for a otherwise.
    #
    # For CIV groups, the initial vrel is their affinity for the actor,
    # plus a delta based on the provision of ENI services.

    typemethod PopulateVerticalRelationships {} {
        # FIRST, initialize vrel_ga with the affinities, or 1.0 for
        # FRC/ORG groups with their rel_entity.
        rdb eval {
            INSERT INTO vrel_ga(g, a, vrel)
            SELECT G.g                             AS g,
                   A.a                             AS a, 
                   CASE WHEN G.rel_entity = A.a 
                   THEN 1.0 ELSE V.affinity END    AS vrel
            FROM groups       AS G
            JOIN actors       AS A
            JOIN mam_affinity AS V
            ON (V.f=G.rel_entity AND V.g=A.a);
        }

        # NEXT, for civilian groups set bvrel(0).  It's just
        # the affinity.
        rdb eval {
            INSERT INTO bvrel_tga(t, g, a, bvrel)
            SELECT 0, g, a, vrel FROM vrel_ga;
        }


        # NEXT, Compute the status quo vrel for civilian groups
        # by adding deltaV.eni(0)
        service assess deltav

        foreach {g a vrel dv_eni} [rdb eval {
            SELECT g, a, vrel, dv_eni
            FROM vrel_ga
        }] {
            let vrel [scale $vrel $dv_eni]

            rdb eval {
                UPDATE vrel_ga
                SET vrel = $vrel
                WHERE g=$g AND a=$a
            }
        }
    }

    # PopulateActorSupports
    #
    # Each actor can give his political support to himself, another actor,
    # or no one.  This routine populates the supports_na table with the 
    # default supports from actors.

    typemethod PopulateActorSupports {} {
        rdb eval {
            INSERT INTO supports_na(n, a, supports)
            SELECT n, a, supports
            FROM nbhoods JOIN actors
        }
    }

    # PopulateActorInfluence
    #
    # Populates the influence_na table, and computes the
    # initial influence of each actor.
    
    typemethod PopulateActorInfluence {} {
        # FIRST, populate the influence_na table
        rdb eval {
            INSERT INTO influence_na(n, a)
            SELECT n, a FROM nbhoods JOIN actors
        }

        # NEXT, compute the actor's initial influence.
        $type ComputeActorInfluence
    }


    #-------------------------------------------------------------------
    # Analysis
    #
    # These routines are called to determine vertical relationships and
    # the support and influence of every actor in every neighborhood.

    # analyze
    #
    # Update vrel and influence.

    typemethod analyze {} {
        # FIRST, update vertical relationships based on current
        # circumstances.
        $type ComputeVerticalRelationships

        # NEXT, Compute each actor's influence in each neighborhood.
        $type ComputeActorInfluence
    }

    # ComputeVerticalRelationships
    #
    # Computes the vertical relationships between each civilian 
    # group and each actor.  (The FRC and ORG group vrel's don't
    # currently change over time.)
    #
    # vrel.ga = bvrel.ga 
    #         + deltaV.mood              <== Implemented
    #         + deltaV.eni               <== Implemented
    #         + deltaV.beliefs           <== Not yet modeled
    #         + deltaV.tactics           <== Not yet modeled
    #
    # First the deltaV's are computed; then all the deltaVs are 
    # applied at once.
    
    typemethod ComputeVerticalRelationships {} {
        # FIRST, Compute deltaV.mood and deltaV.eni
        $type ComputeDV_mood
        service assess deltav

        # NEXT, update vrel.
        foreach {g a dv_mood dv_eni bvrel bvt} [rdb eval {
            SELECT V.g                               AS g,
                   V.a                               AS a,
                   V.dv_mood                         AS dv_mood,
                   V.dv_eni                          AS dv_eni,
                   B.bvrel                           AS bvrel,
                   B.t                               AS bvt
            FROM vrel_ga   AS V
            JOIN civgroups AS G  USING (g)
            JOIN control_n AS C  ON (C.n = G.n)
            JOIN bvrel_tga AS B  ON (B.t = C.since AND B.g = V.g AND B.a = V.a)
        }] {

            # NEXT, accumulate, scale,and apply the deltaV's.
            let vrel [scale $bvrel $dv_mood $dv_eni]

            rdb eval {
                UPDATE vrel_ga
                SET vrel    = $vrel,
                    bvt     = $bvt
                WHERE g=$g AND a=$a
            }

            log detail control \
                [format "vrel(%s,%s)=%.3f; bv=%.3f, dv_mood=%s dv_eni=%s " \
                     $g $a $vrel $bvrel   \
                     [qmag name $dv_mood] \
                     [qmag name $dv_eni]]
        }
    }


    # ComputeDV_mood
    #
    # Computes the vrel_ga.dv_mood for all g,a
    
    typemethod ComputeDV_mood {} {
        # FIRST, get model parameters
        set better [parm get control.dvmood.better]
        set worse  [parm get control.dvmood.worse]

        # NEXT, compute dv_mood.
        rdb eval {
            SELECT G.g                               AS g,
                   G.n                               AS n,
                   A.a                               AS a,
                   CASE WHEN (C.controller = A.a)
                        THEN 1 ELSE 0 END            AS inControl,
                   GG.sat                            AS moodNow,
                   HM.sat                            AS moodThen
            FROM civgroups AS G
            JOIN actors    AS A
            JOIN control_n AS C  ON (C.n = G.n)
            JOIN gram_g    AS GG ON (G.g = GG.g)
            JOIN hist_mood AS HM ON (HM.g = G.g AND HM.t = C.since)
        } {
            # FIRST, compute deltaV.mood
            let moodDiff {$moodNow - $moodThen}

            # Look up the magnitude in the table
            if {$moodDiff > $better} {
                set dv_mood [qmag value $moodTable(1,$inControl)]
            } elseif {$moodDiff < $worse} {
                set dv_mood [qmag value $moodTable(-1,$inControl)]
            } else {
                set dv_mood [qmag value $moodTable(0,$inControl)]
            }

            rdb eval {
                UPDATE vrel_ga
                SET vrel    = $vrel,
                    dv_mood = $dv_mood
                WHERE g=$g AND a=$a
            }
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
            SET direct_support = 0,
                support        = 0,
                influence      = 0;
   
            DELETE FROM support_nga;
        }

        # NEXT, get the total number of personnel in each neighborhood.
        array set tp [rdb eval {
            SELECT n, total(personnel)
            FROM force_ng
            GROUP BY n
        }]

        # NEXT, add the support of each group in each neighborhood
        # to each actor's direct support
        set minSupport [parm get control.support.min]
        set vrelMin    [parm get control.support.vrelMin]
        set Zsecurity  [parm get control.support.Zsecurity]

        foreach {n g personnel security a vrel} [rdb eval {
            SELECT NG.n,
                   NG.g,
                   NG.personnel,
                   NG.security,
                   A.a,
                   V.vrel
            FROM force_ng AS NG
            JOIN actors   AS A
            JOIN vrel_ga  AS V ON (V.g=NG.g AND V.a=A.a)
            WHERE NG.personnel > 0
        }] {
            set factor [zcurve eval $Zsecurity $security]

            if {$vrel >= $vrelMin && $factor > 0.0} {
                let contrib {$vrel * $personnel * $factor / $tp($n) }
            } else {
                set contrib 0.0
            }

            rdb eval {
                UPDATE influence_na
                SET direct_support = direct_support + $contrib
                WHERE n=$n AND a=$a;

                INSERT INTO 
                support_nga(n,g,a,vrel,personnel,security,direct_support)
                VALUES($n,$g,$a,$vrel,$personnel,$security,$contrib);
            }
        }

        # NEXT, compute a's actual support, given the support relationships
        # in support_na.
        foreach {n g a direct_support supports} [rdb eval {
            SELECT G.n                  AS n,
                   G.g                  AS g,
                   G.a                  AS a,
                   G.direct_support     AS direct_support,
                   S.supports           AS supports
            FROM support_nga AS G
            JOIN supports_na AS S USING (n,a)
            WHERE S.supports IS NOT NULL
        }] {
            # FIRST, update the supported actor's support from this group.
            # Also, update the actor's actual support.
            rdb eval {
                UPDATE support_nga 
                SET support = support + $direct_support
                WHERE n=$n AND g=$g AND a=$supports;

                UPDATE influence_na
                SET support = support + $direct_support
                WHERE n=$n AND a=$supports;
            }
        }

        # NEXT, compute the total support for each neighborhood.
        # Exclude actors with less than the minimum required support.
        rdb eval {
            SELECT n, total(support) AS denom
            FROM influence_na
            WHERE support >= $minSupport
            GROUP BY n
        } {
            set nsupport($n) $denom
        }

        # NEXT, compute the contribution to influence of each group
        foreach n [array names nsupport] {
            set denom $nsupport($n)

            if {$denom > 0} {
                rdb eval {
                    UPDATE support_nga
                    SET influence = support/$denom
                    WHERE n=$n
                }
            }
        }

        # NEXT, compute the influence of each actor in the 
        # neighborhood.  The actor requires a minimum level of
        # support to have any influence.

        rdb eval {
            SELECT n, a, support FROM influence_na
        } {
            if {![info exists nsupport($n)] || $nsupport($n) == 0} {
                # Nobody has any support
                set influence 0.0
            } elseif {$support < $minSupport} {
                # Actor has too little support to be influential
                set influence 0.0
            } else {
                # At least one actor has support in the neighborhood
                set influence [expr {double($support) / $nsupport($n)}]
            }

            rdb eval {
                UPDATE influence_na
                SET influence=$influence
                WHERE n=$n AND a=$a
            }
        }
    }





    #-------------------------------------------------------------------
    # Assessment
    #
    # These routines are called during the strategy tock to determine
    # who's in control before strategy execution

    # assess
    #
    # Looks for shifts of control in all neighborhoods, and takes the
    # action that follows from that.
    
    typemethod assess {} {
        # FIRST, get the actor in control of each neighborhood,
        # and their influence, and then see if control has shifted
        # for that neighborhood.
        #
        # Note that a neighborhood can be in a state of chaos; the
        # controller will be NULL and his influence 0.0.

        foreach {n controller influence} [rdb eval {
            SELECT C.n                        AS n,
                   C.controller               AS controller,
                   COALESCE(I.influence, 0.0) AS influence
            FROM control_n               AS C
            LEFT OUTER JOIN influence_na AS I
            ON (I.n=C.n AND I.a=C.controller)
        }] {
            $type DetectControlShift $n $controller $influence
        }
    }

    # DetectControlShift n controller cInfluence
    #
    # n           - A neighborhood
    # controller  - The actor currently in control, or ""
    # cInfluence  - The current controller's influence in n, or 0 if none.
    # 
    # Determines whether there is a shift in control in the neighborhood.

    typemethod DetectControlShift {n controller cInfluence} {
        # FIRST, get the actor with the most influence in the neighborhood,
        # and see how much it is.
        rdb eval {
            SELECT a         AS maxA,
                   influence AS maxInf
            FROM influence_na
            WHERE n=$n
            ORDER BY influence DESC
            LIMIT 1
        } {}

        # NEXT, if the current controller has the most influence in the
        # neighborhood, then he is still in control.  Control has not
        # shifted; we're done.

        if {$cInfluence >= $maxInf} {
            return
        }

        # NEXT, maxA is NOT the current controller.  If he has more than
        # the control threshold, he's the new controller; control has
        # shifted.

        if {$maxInf > [parm get control.threshold]} {
            $type ShiftControl $n $maxA $controller
            return
        }

        # NEXT, actor maxA has more influence than the current controller,
        # but not enough to actually be "in control".  We now have a
        # state of chaos.  Unless we were already in a state of chaos,
        # control has shifted.

        if {$controller ne ""} {
            $type ShiftControl $n "" $controller
            return
        }

        # NEXT, we were already in a state of chaos; control has not
        # shifted.
        return
    }

    # ShiftControl n cNew cOld
    #
    # n      - A neighborhood
    # cNew   - The new controller, or ""
    # cOld   - The old controller, or ""
    #
    # Handles the shift in control from cOld to cNew in n.
    
    typemethod ShiftControl {n cNew cOld} {
        log normal control_model "shift in $n to <$cNew> from <$cOld>"

        if {$cNew eq ""} {
            sigevent log 1 control "
                Actor {actor:$cOld} has lost control of {nbhood:$n}; 
                no actor has control.
            " $n $cOld
        } elseif {$cOld eq ""} {
            sigevent log 1 control "
                Actor {actor:$cNew} has won control of {nbhood:$n}; 
                no actor had been in control previously.
            " $n $cNew 
        } else {
            sigevent log 1 control "
                Actor {actor:$cNew} has won control of {nbhood:$n}
                from {actor:$cOld}.
            " $n $cNew $cOld
        }

        # FIRST, update control_n.
        rdb eval {
            UPDATE control_n 
            SET controller = nullif($cNew,''),
                since      = now()
            WHERE n=$n;
        }

        # NEXT, recompute bvrel.ga for all CIV groups that reside
        # in n.
        foreach {g a vrel} [rdb eval {
            SELECT V.g,
                   V.a,
                   V.vrel
            FROM vrel_ga AS V
            JOIN civgroups AS C USING (g)
            WHERE C.n=$n
        }] {
            set vsym [qaffinity name $vrel]
            
            if {$a eq $cNew} {
                set change 1
            } elseif {$a eq $cOld} {
                set change -1
            } else {
                set change 0
            }

            set mag   $controlTable($vsym,$change)
            set delta [qmag value $mag]

            set bvrel [scale $vrel $delta]
            log detail control_model "bvrel.$g,$a = $bvrel ($vrel + $mag)"

            rdb eval {
                INSERT INTO bvrel_tga(t, g, a, bvrel,dv_control)
                VALUES(now(), $g, $a, $bvrel, $mag)
            }
        }
        
        # NEXT, invoke the CONTROL rule set for this transition.
        dict set rdict n $n
        dict set rdict a $cOld
        dict set rdict b $cNew
        dict set rdict driver     \
            [aram driver add      \
                 -dtype   CONTROL \
                 -oneliner "Shift in control of nbhood $n"]

        control_rules analyze $rdict
    }



    #-------------------------------------------------------------------
    # Helper Procs

    # scale base delta...
    #
    # base   - A base value
    # delta  - One or more numeric qmag(n) magnitude values
    #
    # Given a base value and one or more deltas expressed as numeric
    # qmag(n) magnitudes (e.g., percentage changes from base to 
    # extreme), scales the deltas, applies them to the base, and returns
    # the new value.
    #
    # More specifically, the deltas are divided into positive and negative
    # deltas.  Each set is totalled, scaled, and applied separately.

    proc scale {base args} {
        # FIRST, total up the deltas by sign.
        set plus  0.0
        set minus 0.0

        foreach delta $args {
            if {$delta >= 0} {
                set plus [expr {min($plus + $delta, 100.0)}]
            } else {
                set minus [expr {max($minus + $delta, -100.0)}]
            }
        }

        # NEXT, add the plusses and minuses
        set result $base

        if {$plus > 0.0} {
            set result [expr {$result + abs($plus*(1.0 - $base)/100.0)}]
        }

        if {$minus < 0.0} {
            set result [expr {$result - abs($minus*(1.0 + $base)/100.0)}]
        }

        return $result
    }


}