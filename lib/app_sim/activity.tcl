#-----------------------------------------------------------------------
# TITLE:
#    activity.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): nbstat(sim) Activity Coverage module
#
#    This module is responsible for defining the unit activities and
#    for determining activity coverage.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type activity {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Initialization

    # start
    #
    # Initializes the module before the simulation first starts to run.

    typemethod start {} {
        log normal activity "start"

        # FIRST, Initialize activity_nga.
        rdb eval {
            DELETE FROM activity_nga;
        }

        # NEXT, Add groups and activities for each neighborhood.
        rdb eval {
            SELECT n, g, a, stype
            FROM nbhoods JOIN groups JOIN activity_gtype USING (gtype)
            WHERE stype != ''
        } {
            rdb eval {
                INSERT INTO activity_nga(n,g,a,stype)
                VALUES($n,$g,$a,$stype)
            }
        }
    
        # NEXT, do an initial analysis.
        activity analyze

        # NEXT, Activity is up.
        log normal activity "start complete"
    }

    # clear
    #
    # Clears the data from the activity_nga table

    typemethod clear {} {
        rdb eval { DELETE FROM activity_nga }
    }

    #-------------------------------------------------------------------
    # Analysis

    # analyze
    #
    # Computes coverage fractions for all activities

    typemethod analyze {} {
        # FIRST, compute activity coverage fractions for all force
        # and ORG groups in all neighborhoods.
        activity InitializeActivityTable
        
        activity ComputeForceActivityFlags
        activity ComputeOrgActivityFlags
        activity ComputeActivityPersonnel
        activity ComputeCoverage
    }

    # InitializeActivityTable
    #
    # Initializes the activity_nga table prior to computing FRC and ORG
    # activities.

    typemethod InitializeActivityTable {} {
        # FIRST, clear the previous results.
        rdb eval {
            UPDATE activity_nga
            SET security_flag = 1,
                can_do        = 1,
                nominal       = 0,
                active        = 0,
                effective     = 0,
                coverage      = 0.0;
        }
    }


    # ComputeForceActivity
    #
    # Computes the presence and activity personnel for all FRC groups.

    typemethod ComputeForceActivityFlags {} {
        # FIRST, clear security flags when security is too low
        rdb eval {
            SELECT activity_nga.n      AS n,
                   activity_nga.g      AS g,
                   activity_nga.a      AS a,
                   force_ng.security   AS security
            FROM activity_nga 
            JOIN force_ng USING (n, g)
            JOIN frcgroups USING (g)
        } {
            set minSecurity \
                [qsecurity value [parmdb get activity.FRC.$a.minSecurity]]

            # Compare using the symbolic values.
            set security [qsecurity strictvalue $security]

            if {$security >= $minSecurity} {
                set security_flag 1
            } else {
                set security_flag 0
            }

            rdb eval {
                UPDATE activity_nga
                SET security_flag = $security_flag
                WHERE n=$n AND g=$g AND a=$a
            }
        }
    }

    # ComputeOrgActivityFlags
    #
    # Computes personnel engaged in activities for all ORG groups.

    typemethod ComputeOrgActivityFlags {} {
        # FIRST, Clear security_flag when security is too low.
        rdb eval {
            SELECT activity_nga.n      AS n,
                   activity_nga.g      AS g,
                   activity_nga.a      AS a,
                   orggroups.orgtype   AS orgtype,
                   force_ng.security   AS security
            FROM activity_nga 
            JOIN force_ng USING (n, g)
            JOIN orggroups USING (g)
        } {
            # can_do
            # TBD: Need to set this based on whether the group
            # is active in the neighborhood or not!
            if 0 {
                # Old JNEM code
                set can_do [jout orgIsActive $n $g]
            } else {
                # For now, assume that it can.
                set can_do 1
            }

            # security
            set minSecurity \
                [qsecurity value [parmdb get \
                    activity.ORG.$a.minSecurity.$orgtype]]

            set security [qsecurity strictvalue $security]

            if {$security < $minSecurity} {
                set security_flag 0
            } else {
                set security_flag 1
            }

            # Save values
            rdb eval {
                UPDATE activity_nga
                SET can_do        = $can_do,
                    security_flag = $security_flag
                WHERE n=$n AND g=$g AND a=$a
            }
        }
    }


    # ComputeActivityPersonnel
    #
    # Computes the activity personnel for both group types.

    typemethod ComputeActivityPersonnel {} {
        # FIRST, PRESENCE personnel
        rdb eval {
            SELECT n                AS n,
                   g                AS g, 
                   total(personnel) AS troops
            FROM units
            WHERE gtype = 'FRC'
            AND   n != ''
            GROUP BY n, g
        } {
            # All troops are active and effective at being present
            rdb eval {
                UPDATE activity_nga
                SET nominal   = nominal   + $troops,
                    active    = active    + $troops,
                    effective = effective + $troops
                WHERE n=$n AND g=$g AND a='PRESENCE'
            }
        }

        # NEXT, Determine which units are tasked with an activity but are
        # ineffective.  Begin by assuming that all are effective.
        rdb eval {
            UPDATE units
            SET a_effective = 1
        }

        # NEXT, clear the flag if the group has insufficient
        # security or is otherwise incapable of doing the activity.
        rdb eval {
            UPDATE units
            SET a_effective = 0
            WHERE a != ''
            AND   a != 'NONE'
            AND EXISTS(
                SELECT a FROM activity_nga
                WHERE activity_nga.n = units.n
                AND   activity_nga.g = units.g
                AND   activity_nga.a = units.a
                AND   ((activity_nga.security_flag = 0) OR
                       (activity_nga.can_do = 0)));
        }

        # NEXT, compute the personnel statistics
        rdb eval {
            SELECT units.n                      AS n,
                   units.g                      AS g, 
                   units.a                      AS a,
                   a_effective                  AS a_effective,
                   total(units.personnel)       AS troops,
                   groups.gtype                 AS gtype
            FROM units JOIN activity_nga USING (n,g,a)
            JOIN groups USING (g)
            WHERE units.a != 'PRESENCE'
            GROUP BY units.n, units.g, units.a
        } {
            log detail activity \
                "n=$n g=$g a=$a eff=$a_effective troops=$troops"

            # How many are active?
            set shifts [parmdb get activity.$gtype.$a.shifts]
            let activeTroops {$troops / $shifts}

            # And are they effective?
            if {$a_effective} {
                set effectiveTroops $activeTroops
            } else {
                set effectiveTroops 0
            }

            # Update the personnel figures
            rdb eval {
                UPDATE activity_nga
                SET nominal   = nominal   + $troops,
                    active    = active    + $activeTroops,
                    effective = effective + $effectiveTroops
                WHERE n=$n AND g=$g AND a=$a
            }
        }
    }


    # ComputeCoverage
    #
    # Computes activity coverage for all activities, both FRC and ORG>

    typemethod ComputeCoverage {} {
        rdb eval {
            SELECT activity_nga.n      AS n,
                   activity_nga.g      AS g,
                   activity_nga.a      AS a,
                   effective           AS personnel,
                   demog_n.population  AS population,
                   groups.gtype        AS gtype
            FROM activity_nga JOIN demog_n JOIN groups
            WHERE demog_n.n=activity_nga.n
            AND   activity_nga.g=groups.g
            AND   effective > 0
        } {
            set cov [coverage eval \
                         [parmdb get activity.$gtype.$a.coverage] \
                         $personnel                               \
                         $population]

            rdb eval {
                UPDATE activity_nga
                SET coverage = $cov
                WHERE n=$n AND g=$g AND a=$a
            }
        }
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.

    # names
    #
    # Returns the list of all activity names

    typemethod names {} {
        set names [rdb eval {
            SELECT a FROM activity
        }]
    }


    # validate a
    #
    # a         Possibly, an activity ID
    #
    # Validates an activity ID

    typemethod validate {a} {
        if {![rdb exists {SELECT a FROM activity WHERE a=$a}]} {
            set names [join [activity names] ", "]

            return -code error -errorcode INVALID \
                "Invalid activity, should be one of: $names"
        }

        return $a
    }


    # civ names
    #
    # Returns the list of activities assignable to civilian units

    typemethod {civ names} {} {
        set names [rdb eval {
            SELECT a FROM activity_gtype
            WHERE gtype='CIV' AND assignable
        }]
    }


    # civ validate a
    #
    # a         Possibly, an activity ID
    #
    # Validates an activity ID as assignable to civilian units

    typemethod {civ validate} {a} {
        if {$a ni [activity civ names]} {
            set names [join [activity civ names] ", "]

            return -code error -errorcode INVALID \
                "Invalid activity, should be one of: $names"
        }

        return $a
    }


    # frc names
    #
    # Returns the list of activities assignable to force units

    typemethod {frc names} {} {
        set names [rdb eval {
            SELECT a FROM activity_gtype
            WHERE gtype='FRC' AND assignable
        }]
    }


    # frc validate a
    #
    # a         Possibly, an activity ID
    #
    # Validates an activity ID as assignable to force units

    typemethod {frc validate} {a} {
        if {$a ni [activity frc names]} {
            set names [join [activity frc names] ", "]

            return -code error -errorcode INVALID \
                "Invalid activity, should be one of: $names"
        }

        return $a
    }

    
    # org names
    #
    # Returns the list of activities assignable to organization units

    typemethod {org names} {} {
        set names [rdb eval {
            SELECT a FROM activity_gtype
            WHERE gtype='ORG' AND assignable
        }]
    }


    # org validate a
    #
    # a         Possibly, an activity ID
    #
    # Validates an activity ID as assignable to org units

    typemethod {org validate} {a} {
        if {$a ni [activity org names]} {
            set names [join [activity org names] ", "]

            return -code error -errorcode INVALID \
                "Invalid activity, should be one of: $names"
        }

        return $a
    }
}

