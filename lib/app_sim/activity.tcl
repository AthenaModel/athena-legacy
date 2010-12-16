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
    # Analysis: Staffing

    # analyze staffing
    #
    # Analyzes the schedule to determine staffing of activities.
    # Must precede [security analyze].
    #
    # Note: this command may safely be called prior to "activity start".

    typemethod {analyze staffing} {} {
        # FIRST, Get the available personnel for all groups; we need to
        # decrement it as we staff, to see what's left over.
        set pers [dict create]

        rdb eval {
            SELECT P.n         AS n,
                   P.g         AS g, 
                   P.personnel AS bp,
                   U.personnel AS up
            FROM personnel_ng AS P
            LEFT OUTER JOIN units AS U
            ON (U.n = P.n AND U.g = P.g AND U.cid = 0)
            WHERE bp > 0 OR up > 0
            UNION
            SELECT P.n                     AS n,
                   P.g                     AS g, 
                   P.basepop - P.attrition AS bp,
                   U.personnel             AS up
            FROM gui_civgroups AS P
            LEFT OUTER JOIN units AS U
            ON (U.n = P.n AND U.g = P.g AND U.cid = 0)
            WHERE bp > 0 OR up > 0
        } {
            dict set pers $n $g $bp
        }

        # NEXT, Run through all of the scheduled activities and assign
        # nominal personnel.
        rdb eval {
            SELECT C.cid       AS cid,
                   C.n         AS n,
                   C.g         AS g,
                   C.a         AS a,
                   C.tn        AS tn,
                   C.personnel AS personnel,
                   C.start     AS start,
                   C.finish    AS finish,
                   C.pattern   AS pattern,
                   U.u         AS u,
                   U.personnel AS old_personnel,
                   U.active    AS active
            FROM calendar AS C LEFT OUTER JOIN units AS U USING (cid)
            ORDER BY C.priority
        } row {
            # FIRST, is it currently active or not?
            set now [simclock now]

            if {($row(finish) eq "" || $now <= $row(finish)) &&
                [calpattern isactive $row(pattern) $row(start) $now]
            } {
                # FIRST, if the pattern is "once" and the unit was
                # previously staffed, we leave it alone.
                if {$row(pattern) eq "once" &&
                    $row(start) < $now
                } {
                    continue
                }

                # FIRST, The item is active.  
                # How many people can staff it?
                if {[dict exists $pers $row(n) $row(g)]} {
                    set avail [dict get $pers $row(n) $row(g)]
                } else {
                    set avail 0
                }

                if {$row(personnel) < $avail} {
                    set staff $row(personnel)
                    let avail {$avail - $staff}
                } else {
                    set staff $avail
                    set avail 0
                }

                dict set pers $row(n) $row(g) $avail

                # NEXT, deploy units.
                #
                # * If there's no unit already existing, and the activity
                #   is staffed, create the unit.
                #
                # * Otherwise, if the activity is staffed, update the unit's
                #   personnel.
                #
                # * If the activity is not staffed, deactivate the unit.

                if {$row(u) eq ""} {
                    if {$staff > 0} {
                        set row(personnel) $staff
                        unit create [array get row]
                    } 
                } elseif {$staff > 0} {
                    unit mutate personnel $row(u) $staff
                } else {
                    unit deactivate $row(u)
                }
            } else {
                # FIRST, The item is inactive.  We need to deactivate the
                # corresponding unit, if any.
                if {$row(u) ne "" && $row(active)} {
                    unit deactivate $row(u)
                }
            }
        }

        # NEXT, Find any units whose activity has been cancelled, and
        # delete them.
        rdb eval {
            SELECT u
            FROM units LEFT OUTER JOIN calendar USING (cid)
            WHERE cid > 0
            AND calendar.a IS NULL
        } {
            unit delete $u
        }

        # NEXT, staff the NONE activity for all remaining personnel
        dict for {n gdict} $pers {
            dict for {g remaining} $gdict {
                $type DeployBaseUnit $n $g $remaining
            }
        }

    }

    # DeployBaseUnit
    #
    #   n          The unit's neighborhood of origin
    #   g          The group to which it belongs
    #   personnel  The number of personnel unallocated
    #
    # Creates a base unit with these parameters if one doesn't already
    # exist, Otherwise, assigns it the specified number of personnel.

    typemethod DeployBaseUnit {n g personnel} {
        # FIRST, does the desired unit already exist?
        set u [format "%s-%s/%04d" $g $n 0]
 
        if {![rdb exists {SELECT u FROM units WHERE u=$u}]} {
            set parmdict [dict create              \
                              n         $n         \
                              g         $g         \
                              a         NONE       \
                              tn        $n         \
                              personnel $personnel \
                              cid       0]
                          
            unit create $parmdict
        } else {
            unit mutate personnel $u $personnel
        }
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

    # cal names
    #
    # Returns a list of the names of the calendar items.

    typemethod {cal names} {} {
        rdb eval {SELECT cid FROM calendar}
    }

    # cal validate cid
    #
    # cid    Possibly, a calendar item ID
    #
    # Validates an existing item ID

    typemethod {cal validate} {cid} {
        if {$cid ni [activity cal names]} {
            return -code error -errorcode INVALID \
                "Invalid calendar item ID: \"$cid\""
        }

        return $cid
    }

    # cal+end names
    #
    # Returns a list of the names of the calendar items, plus "END"

    typemethod {cal+end names} {} {
        set names [rdb eval {SELECT cid FROM calendar}]

        lappend names END

        return $names
    }

    # cal+end validate cid
    #
    # cid    Possibly, a calendar item ID, or END
    #
    # Validates an existing item ID or END

    typemethod {cal+end validate} {cid} {
        set cid [string toupper $cid]

        if {$cid ni [activity cal+end names]} {
            return -code error -errorcode INVALID \
                "Invalid value: \"$cid\", should be \"END\" or a calendar item ID"
        }

        return $cid
    }

    #-------------------------------------------------------------------
    # Mutators

    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate reconcile
    #
    # Deletes calendar items for which the owning neighborhood or group 
    # no longer exists.

    typemethod {mutate reconcile} {} {
        # FIRST, delete orphaned calendar items.
        set undo [list]

        rdb eval {
            SELECT cid
            FROM calendar
            LEFT OUTER JOIN groups USING (g)
            WHERE longname IS NULL
        } {
            
            lappend undo [$type mutate delete $cid]
        }

        rdb eval {
            SELECT cid
            FROM calendar
            LEFT OUTER JOIN nbhoods USING (n)
            WHERE longname IS NULL
        } {
            lappend undo [$type mutate delete $cid]
        }

        rdb eval {
            SELECT cid
            FROM calendar
            LEFT OUTER JOIN nbhoods ON (nbhoods.n == calendar.tn)
            WHERE longname IS NULL
        } {
            lappend undo [$type mutate delete $cid]
        }

        return [join $undo \n]
    }

    # mutate create parmdict
    #
    # parmdict     A dictionary of calendar item parms
    #
    #    n              The ID of the nbhood where g is stationed
    #    g              The acting group
    #    a              The activity to schedule
    #    tn             The target neighborhood
    #    personnel      The personnel to schedule
    #    start          Start tick for the activity
    #    finish         Finish tick for the activity, or "NEVER"
    #    pattern        Schedule pattern, calpattern(sim)
    #    priority       "top" or "bottom".
    #
    # Schedules the desired activity.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the item in the database
            rdb eval {
                INSERT INTO calendar
                (n,g,a,tn,personnel,start,finish,pattern,priority)
                VALUES($n,
                       $g,
                       $a,
                       $tn,
                       $personnel,
                       $start,
                       $finish,
                       $pattern,
                       0)
            }

            set cid [rdb last_insert_rowid]

            lappend undo [mytypemethod mutate delete $cid]
            lappend undo [$type mutate priority $cid $priority]

            # NEXT, Return the undo command
            return [join $undo \n]
        }
    }

    # mutate delete cid
    #
    # cid     A calendar item ID
    #
    # Deletes the item

    typemethod {mutate delete} {cid} {
        # FIRST, delete the item, grabbing the undo information
        set data [rdb delete -grab calendar {cid=$cid}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of calendar item parms
    #
    #    cid              The item ID
    #    personnel        A new personnel, or ""
    #    start            A new start, or ""
    #    finish           A new finish, or ""
    #    pattern          A new pattern, or ""
    #
    # Updates an item given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab calendar {cid=$cid}]

            # NEXT, Update the group; finish is special.
            rdb eval {
                UPDATE calendar
                SET personnel = nonempty($personnel, personnel),
                    start     = nonempty($start,     start),
                    pattern   = nonempty($pattern,   pattern)
                WHERE cid=$cid
            }

            if {$finish ne ""} {
                if {$finish eq "NEVER"} {
                    set finish ""
                }

                rdb eval {
                    UPDATE calendar
                    SET finish=$finish
                    WHERE cid=$cid
                }
            }

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }


    # mutate priority cid priority
    #
    # cid       The item ID whose priority is changing.
    # priority  An ePrioUpdate value
    #
    # Re-prioritizes the items for cid's n,g so that cid has the
    # desired position.

    typemethod {mutate priority} {cid priority} {
        # FIRST, get cid's n and g.
        lassign [rdb eval {
            SELECT n,g FROM calendar WHERE cid=$cid
        }] n g

        # NEXT, get the existing priority ranking
        set oldRanking [rdb eval {
            SELECT cid,priority FROM calendar
            WHERE n=$n AND g=$g
            ORDER BY priority
        }]

        # NEXT, Reposition cid in the ranking.
        set ranking [lprio [dict keys $oldRanking] $cid $priority]

        # NEXT, assign new priority numbers
        set prio 1

        foreach id $ranking {
            rdb eval {
                UPDATE calendar
                SET   priority=$prio
                WHERE cid=$id
            }
            incr prio
        }
        
        # NEXT, return the undo script
        return [mytypemethod RestorePriority $oldRanking]
    }

    # RestorePriority ranking
    #
    # ranking  The ranking to restore
    # 
    # Restores an old ranking

   typemethod RestorePriority {ranking} {
       # FIRST, restore the data
        foreach {id prio} $ranking {
            rdb eval {
                UPDATE calendar
                SET priority=$prio
                WHERE cid=$id
            }
        }
    }

    #-------------------------------------------------------------------
    # Helper Procs

    # lprio list item prio
    #
    # list    A list of unique items
    # item    An item in the list
    # prio    top, raise, lower, or bottom
    #
    # Moves the item in the list, and returns the new list.

    proc lprio {list item prio} {
        # FIRST, get item's position in the list.
        set index [lsearch -exact $list $item]

        # NEXT, get the new position
        let end {[llength $list] - 1}

        switch -exact -- $prio {
            top     { set newpos 0                       }
            raise   { let newpos {max(0,    $index - 1)} }
            lower   { let newpos {min($end, $index + 1)} }
            bottom  { set newpos $end                    }
            default { error "Unknown prio: \"$prio\""    }
        }

        # NEXT, if the item is already in its position, we're done.
        if {$newpos == $index} {
            return $list
        }

        # NEXT, put the item in its list.
        ldelete list $item
        set list [linsert $list $newpos $item]

        # FINALLY, return the new list.
        return $list
    }

    #-------------------------------------------------------------------
    # Refresh Commands

    # RefreshStartUpdate field parmdict
    #
    # field     The field for A:UPDATE's start parameter
    # parmdict  The values of upstream parameters
    #
    # If the start is empty, or if it's early than now, initialize 
    # start to NOW in PREP or NOW+1 in PAUSED.

    typemethod RefreshStartUpdate {field parmdict} {
        set timespec [$field get]

        if {[catch {
            set timespec [simclock timespec validate $timespec]
        }]} {
            set timespec ""
        }

        
        if {[order state] eq "PREP"} {
            if {$timespec eq ""} {
                $field set "NOW"
            }
        } else {
            if {$timespec eq "" || $timespec <= [simclock now]} {
                $field set "NOW+1"
            }
        }
    }

    
    # Refresh_AS dlg fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the fields for ACTIVITY:SCHEDULE

    typemethod Refresh_AS {dlg fields fdict} {
        set disabled [list]

        dict with fdict {
            # Configure a
            if {$g ne ""} {
                set gtype [string tolower [group gtype $g]]

                # n field
                if {$gtype eq "civ"} {
                    set n [civgroup getg $g n]
                    $dlg field configure n -values [list $n]
                    $dlg set n $n
                    lappend disabled n
                } else {
                    $dlg field configure n -values [nbhood names]
                }

                # a field
                set values [activity $gtype names]
                $dlg field configure a -values $values

            } else {
                lappend disabled n a
                $dlg set n ""
                $dlg set a ""
            }

            # Configure start
            if {$start eq ""} {
                if {[order state] eq "PREP"} {
                    $dlg set start "NOW"
                } else {
                    $dlg set start "NOW+1"
                }
            }
        }

        $dlg disabled $disabled
    }

    # Refresh_AU dlg fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the fields for ACTIVITY:UPDATE

    typemethod Refresh_AU {dlg fields fdict} {
        if {"cid" in $fields} {
            $dlg loadForKey cid *
        }

        set fdict [$dlg get]

        dict with fdict {
            if {[catch {
                set start [simclock timespec validate $start]
            }]} {
                set start ""
            }

            
            if {[order state] eq "PREP"} {
                if {$start eq ""} {
                    $dlg set start "NOW"
                }
            } else {
                if {$start eq "" || $start <= [simclock now]} {
                    $dlg set start "NOW+1"
                }
            }
        }
    }
}

#-----------------------------------------------------------------------
# Helper Types

# Priority tokens

enum ePrioSched {
    top    "Top Priority"
    bottom "Bottom Priority"
}

enum ePrioUpdate {
    top    "To Top"
    raise  "Raise"
    lower  "Lower"
    bottom "To Bottom"
}



#-----------------------------------------------------------------------
# Orders: ACTIVITY:*
#
# Note: these orders are sent by custom order dialogs.  The standard
# dialogs are not used.

# ACTIVITY:SCHEDULE
#
# Schedules a new activity.

order define ACTIVITY:SCHEDULE {
    title "Schedule Activity"

    options \
        -sendstates {PREP PAUSED}           \
        -refreshcmd {::activity Refresh_AS}

    parm g         key  "Group"            -table groups -key g
    parm n         enum "From Nbhood"  
    parm a         enum "Activity"
    parm tn        key  "In Nbhood"        -table nbhoods -key n
    parm personnel text "Personnel"
    parm start     text "Start"
    parm finish    text "Finish"           -defval Never
    parm pattern   cpat "Schedule"         -defval daily
    parm priority  enum "Priority"         -type ePrioSched -displaylong \
                                           -defval bottom
} {
    # FIRST, prepare and validate the parameters
    prepare g          -toupper -required -type group
    prepare n          -toupper -required -type nbhood
    prepare a          -toupper -required -type {activity asched}
    prepare tn         -toupper           -type nbhood
    prepare personnel           -required -type ipositive
    prepare start      -toupper -required -type {simclock timespec} 
    prepare finish     -toupper
    prepare pattern    -toupper -required -type calpattern
    prepare priority   -tolower           -type ePrioSched

    returnOnError

    # g and a are consistent
    validate g {
        if {[group gtype $parms(g)] eq "CIV"      &&
            ![civgroup gInN $parms(g) $parms(n)]
        } {
            reject n \
                "Group $parms(g) does not reside in neighborhood $parms(n)"
        }
    }

    # g and a are consistent
    validate a {
        activity check $parms(g) $parms(a)
    }

    # tn defaults to n
    if {$parms(tn) eq ""} {
        set parms(tn) $parms(n)
    }

    # start must be later than now, unless we're in PREP.
    validate start {
        if {[order state] eq "PREP"} {
            if {$parms(start) < [simclock now]} {
                reject start "The scheduled time must not be in the past."
            }
        } else {
            if {$parms(start) <= [simclock now]} {
                reject start \
                    "The scheduled time must be strictly in the future."
            }
        }
    }

    # finish should be undefined or greater than start or "NEVER"
    validate finish {
        # "NEVER" is a placeholder for ""
        if {$parms(finish) eq "NEVER"} {
            set parms(finish) ""
        } else {
            if {[catch {simclock future validate $parms(finish)} result]} {
                reject finish \
                    "invalid value \"$parms(finish)\", should be \"NEVER\" or a timespec with base time of \"NOW\", \"T0\", an integer tick, or a zulu-time string"
            }

            set parms(finish) $result

            if {$parms(finish) < $parms(start)} {
                reject finish "The end of the interval, \"$parms(finish)\", is prior to the start, \"$parms(start)\"" 
            }
        }
    }

    if {$parms(priority) eq ""} {
        set parms(priority) bottom
    }

    returnOnError -final

    setundo [activity mutate create [array get parms]]
}


# ACTIVITY:UPDATE
#
# Updates an existing calendar item.

order define ACTIVITY:UPDATE {
    title "Update Scheduled Activity"

    options \
        -sendstates {PREP PAUSED}           \
        -refreshcmd {::activity Refresh_AU}

    parm cid       key  "Item ID" -table gui_calendar -key cid
    parm g         disp "Group"
    parm n         disp "From Nbhood"
    parm a         disp "Activity"
    parm tn        disp "In Nbhood"
    parm personnel text "Personnel"
    parm start     text "Start"
    parm finish    text "Finish"
    parm pattern   cpat "Schedule"
} {
    # FIRST, prepare and validate the parameters
    prepare cid        -toupper -required -type {activity cal}
    prepare personnel                     -type ipositive
    prepare start      -toupper           -type {simclock timespec}
    prepare finish     -toupper
    prepare pattern                       -type calpattern

    returnOnError

    # NEXT, retrieve the existing schedule data, and
    # merge in the new data for error checking purposes.
    rdb eval {SELECT * FROM calendar WHERE cid=$parms(cid)} old {}

    foreach parm [array names parms] {
        if {$parms($parm) ne ""} {
            set old($parm) $parms($parm)
        }
    }

    # NEXT, do the remaining validation.

    # start must be later than now, unless we're in PREP.
    validate start {
        if {[order state] eq "PREP"} {
            if {$parms(start) < [simclock now]} {
                reject start "The scheduled time must not be in the past."
            }
        } else {
            if {$parms(start) <= [simclock now]} {
                reject start \
                    "The scheduled time must be strictly in the future."
            }
        }
    }

    # finish should be undefined or greater than start or "NEVER"
    validate finish {
        # "NEVER" is a placeholder for ""
        if {$parms(finish) ne "NEVER"} {
            if {[catch {simclock future validate $parms(finish)} result]} {
                reject finish \
                    "invalid value \"$parms(finish)\", should be \"NEVER\" or a timespec with base time of \"NOW\", \"T0\", an integer tick, or a zulu-time string"
            }

            set parms(finish) $result

            if {$parms(finish) < $old(start)} {
                reject finish "The end of the interval, \"$parms(finish)\", is prior to the start, \"$old(start)\"" 
            }
        }
    }

    returnOnError -final

    setundo [activity mutate update [array get parms]]
}

# ACTIVITY:CANCEL
#
# Cancels an existing calendar item.

order define ACTIVITY:CANCEL {
    title "Cancel Scheduled Activity"

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {orderdialog refreshForKey cid *}

    parm cid       key  "Item ID" -table gui_calendar -key cid
    parm g         disp "Group"
    parm n         disp "From Nbhood"
    parm a         disp "Activity"
    parm tn        disp "In Nbhood"
    parm personnel disp "Personnel"
    parm narrative disp "Schedule"
} {
    # FIRST, prepare and validate the parameters
    prepare cid -required -type {activity cal}

    returnOnError -final

    setundo [activity mutate delete $parms(cid)]
}


# ACTIVITY:PRIORITY
#
# Re-prioritizes a calendar item.

order define ACTIVITY:PRIORITY {
    title "Prioritize Scheduled Activity"

    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {orderdialog refreshForKey cid *}

    parm cid       key  "Item ID"  -table gui_calendar -key cid
    parm priority  enum "Priority" -type ePrioUpdate
} {
    # FIRST, prepare and validate the parameters
    prepare cid      -required          -type {activity cal}
    prepare priority -required -tolower -type ePrioUpdate

    returnOnError -final

    setundo [activity mutate priority $parms(cid) $parms(priority)]
}



