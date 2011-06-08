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
    
        # NEXT, Activity is up.
        log normal activity "start complete"
    }


    #-------------------------------------------------------------------
    # Analysis: Coverage


    # analyze coverage
    #
    # Computes activity coverage given staffing and activity
    # effectiveness. Must follow [security analyze].

    typemethod {analyze coverage} {} {
        activity InitializeActivityTable
        activity ComputeActivityPersonnel
        activity ComputeForceActivityFlags
        activity ComputeOrgActivityFlags
        activity ComputeCoverage
    }

    # InitializeActivityTable
    #
    # Initializes the activity_nga table prior to computing 
    # FRC and ORG activities.

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

    # ComputeActivityPersonnel
    #
    # Computes the activity personnel for FRC and ORG groups.

    typemethod ComputeActivityPersonnel {} {
        # NEXT, set the PRESENCE of each FRC group.
        rdb eval {
            SELECT n, 
                   g, 
                   total(personnel) AS nominal
            FROM units
            WHERE gtype='FRC' AND personnel > 0
            GROUP BY n,g
        } {
            # All troops are active at being present
            rdb eval {
                UPDATE activity_nga
                SET nominal   = $nominal,
                    active    = $nominal
                WHERE n=$n AND g=$g AND a='PRESENCE'
            }
        }

        # NEXT, Run through all of the deployed units and compute
        # nominal and active personnel.
        rdb eval {
            SELECT n, 
                   g, 
                   a,
                   total(personnel) AS nominal,
                   gtype
            FROM units
            JOIN activity_gtype USING (a,gtype)
            WHERE stype != ''
            AND personnel > 0
            GROUP BY n,g,a
        } {
            # FIRST, how many of the nominal personnel are active given 
            # the shift schedule?
            set shifts [parmdb get activity.$gtype.$a.shifts]
            let active {$nominal / $shifts}


            # NEXT, accumulate the staff for the target neighborhood
            rdb eval {
                UPDATE activity_nga
                SET nominal = $nominal,
                    active  = $active
                WHERE n=$n AND g=$g AND a=$a;
            }
        }
    }

    # ComputeForceActivityFlags
    #
    # Computes the effectiveness of force activities based on security.

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
    # Computes effectiveness of ORG activities based on security and mood.

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




    # ComputeCoverage
    #
    # Computes activity coverage for all activities, both FRC and ORG>

    typemethod ComputeCoverage {} {
        # FIRST, compute effective staff for each activity
        rdb eval {
            UPDATE activity_nga
            SET effective = active
            WHERE can_do AND security_flag
        }

        # NEXT, compute coverage
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

    # asched names
    #
    # Returns the list of schedulable activities

    typemethod {asched names} {} {
        set names [rdb eval {
            SELECT DISTINCT a FROM activity_gtype
            WHERE assignable
        }]
    }


    # asched validate
    #
    # a         Possibly, an activity ID
    #
    # Validates a schedulable activity ID

    typemethod {asched validate} {a} {
        if {$a ni [activity asched names]} {
            set names [join [activity asched names] ", "]

            return -code error -errorcode INVALID \
                "Invalid activity, should be one of: $names"
        }

        return $a
    }

    # check g a
    #
    # g    A group
    # a    An activity
    #
    # Verifies that a can be assigned to g.

    typemethod check {g a} {
        set gtype [group gtype $g]

        switch -exact -- $gtype {
            CIV     { set names [activity civ names] }
            FRC     { set names [activity frc names] }
            ORG     { set names [activity org names] }
            default { error "Unexpected gtype: \"$gtype\""   }
        }

        if {$a ni $names} {
            return -code error -errorcode INVALID \
                "Group $g cannot be assigned activity $a"
        }
    }
}


