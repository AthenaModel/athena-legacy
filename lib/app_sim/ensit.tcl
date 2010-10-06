#-----------------------------------------------------------------------
# TITLE:
#    ensit.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1) Environmental Situation module
#
#    This module defines a singleton, "ensit", which is used to
#    manage the collection of environmental situation objects, or ensits.
#    Ensits are situations; see situation(sim) for additional details.
#
#    Entities defined in this file:
#
#    ensit      -- The ensit ensemble
#    ensitType  -- The type for the ensit objects.
#
#    A single snit::type could do both jobs--but at the expense
#    of accidentally creating an ensit object if an incorrect ensit
#    method name is used.
#
#    * Ensits are created, updated, and deleted via the "mutate *" 
#      commands and the SITUATION:ENVIRONMENTAL:* orders.
#
#    * This module calls the ensit rule on "ensit assess", which is 
#      done as part of the time advance.
#
# EVENT NOTIFICATIONS:
#    The ::ensit module sends the following notifier(n) events:
#
#    <Entity> op s
#        When called, the op will be one of 'create', 'update' or 'delete',
#        and s will be the ID of the situation.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# ensit singleton

snit::type ensit {
    # Make it an ensemble
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Assessment of Attitudinal Effects

    # assess
    #
    # Calls the DAM rule sets for each situation requiring assessment.

    typemethod assess {} {
        # FIRST, get a list of the IDs of ensits that need to be
        # assessed: those that are "live", and those that have
        # been resolved but the resolution has not yet been assessed.
        set ids [rdb eval {
            SELECT s FROM ensits 
            WHERE state != 'ENDED' OR rdriver=0
        }]
        
        foreach s $ids {
            # FIRST, get the situation.
            set sit [$type get $s]

            # NEXT, if it's in the initial state, make it active.
            # As part of this, schedule related events.
            if {[$sit get state] eq "INITIAL"} {
                # FIRST, set the state
                $sit set state ACTIVE

                # NEXT, set the start and change times to right now.
                # TBD: This probably isn't necessary
                # $sit set ts [simclock now]
                # $sit set tc [simclock now]

                # NEXT, if it spawns, schedule the spawn
                $sit ScheduleSpawn

                # NEXT, if it auto-resolves, schedule the auto-resolution.
                $sit ScheduleAutoResolve
                
                # NEXT, notify the app that the state has changed.
                notifier send $type <Entity> update $s
            }

            # NEXT, create a driver if it lacks one.
            if {[$sit get driver] == -1} {
                $sit set driver [aram driver add \
                                     -dtype    [$sit get stype] \
                                     -name     "Sit $s"         \
                                     -oneliner [$sit oneliner]]
            }

            # NEXT, assess inception affects if need be.
            if {[$sit get inception]} {
                $sit set inception 0
                ensit_rules inception $sit
                notifier send $type <Entity> update $s
            }

            # NEXT, it's on going; monitor its coverage
            ensit_rules monitor $sit

            # NEXT, assess resolution affects if need be.
            if {[$sit get state] eq "ENDED"} {
                $sit set rdriver [aram driver add \
                                     -dtype    [$sit get stype] \
                                     -name     "Sit $s"         \
                                     -oneliner "Resolution of [$sit oneliner]"]

                ensit_rules resolution $sit
                notifier send $type <Entity> update $s
            }
        }
    }

    #-------------------------------------------------------------------
    # Queries

    # table
    #
    # Return the name of the RDB table for this type.

    typemethod table {} {
        return "ensits_t"
    }


    # get s -all|-live
    #
    # s               The situation ID
    #
    # -all   Default.  All situations are included
    # -live  Only live situations are included.
    #
    # Returns the object associated with the ID.  A record must already
    # exist in the RDB.

    typemethod get {s {opt -all}} {
        set sit [situation get $s $opt]

        if {$sit ne "" && [$sit kind] ne $type} {
            error "no such situation: \"$s\""
        }

        return $sit
    }


    # existsInNbhood n ?stype?
    #
    # n          A neighborhood ID
    # stype      An ensit type
    #
    # If stype is given, returns 1 if there's a live ensit of the 
    # specified type already present in n, and 0 otherwise.  Otherwise,
    # returns a list of the ensit types that exist in n.

    typemethod existsInNbhood {n {stype ""}} {
        if {$stype eq ""} {
            return [rdb eval {
                SELECT stype FROM ensits
                WHERE n     =  $n
                AND   state != 'ENDED'
            }]
        } else {
            return [rdb exists {
                SELECT stype FROM ensits
                WHERE n     =  $n
                AND   state != 'ENDED'
                AND   stype =  $stype
            }]
        }
    }


    # absentFromNbhood n
    #
    # n          A neighborhood ID
    #
    # Returns a list of the ensits which do not exist in this
    # neighborhood.

    typemethod absentFromNbhood {n} {
        # TBD: Consider writing an lsetdiff routine
        set present [$type existsInNbhood $n]

        set absent [list]

        foreach stype [eensit names] {
            if {$stype ni $present} {
                lappend absent $stype
            }
        }

        return $absent
    }


    # names
    #
    # List of ensit IDs.

    typemethod names {} {
        return [rdb eval {
            SELECT s FROM ensits
        }]
    }


    # validate s
    #
    # s      A situation ID
    #
    # Verifies that s is an ensit.

    typemethod validate {s} {
        if {$s ni [$type names]} {
            return -code error -errorcode INVALID \
                "Invalid environmental situation ID: \"$s\""
        }

        return $s
    }

    # initial names
    #
    # List of IDs of ensits in the INITIAL state.

    typemethod {initial names} {} {
        return [rdb eval {
            SELECT s FROM ensits
            WHERE state = 'INITIAL'
        }]
    }


    # initial validate s
    #
    # s      A situation ID
    #
    # Verifies that s is in the INITIAL state

    typemethod {initial validate} {s} {
        if {$s ni [$type initial names]} {
            if {$s in [$type live names]} {
                return -code error -errorcode INVALID \
                    "operation is invalid; time has passed."
            } else {
                return -code error -errorcode INVALID \
                    "not a \"live\" situation: \"$s\""
            }
        }

        return $s
    }

    # live names
    #
    # List of IDs of ensits that are still "live"

    typemethod {live names} {} {
        return [rdb eval {
            SELECT s FROM ensits WHERE state != 'ENDED'
        }]
    }


    # live validate s
    #
    # s      A situation ID
    #
    # Verifies that s is still "live"

    typemethod {live validate} {s} {
        if {$s ni [$type live names]} {
            return -code error -errorcode INVALID \
                "not a \"live\" situation: \"$s\"."
        }

        return $s
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
    # Updates ensits as neighborhoods and groups change:
    #
    # 1. If the "g" or "resolver" group no longer exists, that
    #    field is set to "NONE".
    #
    # 2. Updates every ensit's "n" attribute to reflect the
    #    current state of the neighborhood.

    typemethod {mutate reconcile} {} {
        set undo [list]

        # FIRST, set g to NONE if g doesn't exist.
        rdb eval {
            SELECT *
            FROM ensits LEFT OUTER JOIN groups USING (g)
            WHERE ensits.g != 'NONE'
            AND   longname IS NULL
        } row {
            set row(g) NONE

            lappend undo [$type mutate update [array get row]]
        }

        # NEXT, set resolver to NONE if resolver doesn't exist.
        rdb eval {
            SELECT *
            FROM ensits LEFT OUTER JOIN groups 
            ON (ensits.resolver = groups.g)
            WHERE ensits.resolver != 'NONE'
            AND   longname IS NULL
        } row {
            set row(resolver) NONE

            lappend undo [$type mutate update [array get row]]
        }

        # NEXT, set n for all ensits
        rdb eval {
            SELECT s, n, location 
            FROM ensits
        } { 
            set newNbhood [nbhood find {*}$location]

            if {$newNbhood ne $n} {
                set sit [ensit get $s]

                $sit set n $newNbhood

                lappend undo [mytypemethod RestoreNbhood $s $n]

                notifier send ::ensit <Entity> update $s
            }
        }

        return [join [lreverse $undo] \n]
    }


    # RestoreNbhood s n
    #
    # s     An ensit
    # n     A nbhood
    # 
    # Sets the ensit's nbhood.

    typemethod RestoreNbhood {s n} {
        # FIRST, save it, and notify the app.
        set sit [ensit get $s]

        $sit set n $n

        notifier send ::ensit <Entity> update $s
    }



    # mutate create parmdict
    #
    # parmdict     A dictionary of ensit parms
    #
    #    stype          The situation type
    #    location       The situation's initial location (map coords)
    #    coverage       The situation's coverage
    #    g              The group causing the situation, or ""
    #    inception      1 if there are inception effects, and 0 otherwise.
    #    resolver       The group that will resolve the situation, or ""
    #    rduration      Auto-resolution duration, in days
    #
    # Creates an ensit given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, get the remaining attribute values
            set n [nbhood find {*}$location]
            assert {$n ne ""}

            if {$rduration eq ""} {
                set rduration [parmdb get ensit.$stype.duration]
            }

            # NEXT, Create the situation
            set s [situation create $type   \
                       stype     $stype     \
                       n         $n         \
                       coverage  $coverage  \
                       g         $g]

            rdb eval {
                INSERT INTO ensits_t(s,location,inception,resolver,rduration)
                VALUES($s,$location,$inception,$resolver,$rduration)
            }

            # NEXT, inform all clients about the new object.
            log detail ensit "$s: created for $n,$stype,$coverage"
            notifier send $type <Entity> create $s

            # NEXT, Return the undo command
            return [mytypemethod mutate delete $s]
        }
    }

    # mutate delete s
    #
    # s     A situation ID
    #
    # Deletes the situation.  This should be done only if the
    # situation is in the INITIAL state.

    typemethod {mutate delete} {s} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM situations WHERE s=$s} row1 { unset row1(*) }
        rdb eval {SELECT * FROM ensits_t  WHERE s=$s} row2 { unset row2(*) }

        # NEXT, remove it from the object cache
        situation uncache $s

        # NEXT, delete it.
        rdb eval {
            DELETE FROM situations WHERE s=$s;
            DELETE FROM ensits_t  WHERE s=$s;
        }

        # NEXT, notify the app
        notifier send $type <Entity> delete $s

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row1] [array get row2]]
    }

    # Restore bdict ddict
    #
    # bdict    row dict for base entity
    # ddict    row dict for derived entity
    #
    # Restores the rows to the database

    typemethod Restore {bdict ddict} {
        rdb insert situations $bdict
        rdb insert ensits_t  $ddict

        set s [dict get $bdict s]
        situation uncache $s

        notifier send $type <Entity> create $s
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of entity parms
    #
    #    s              The situation ID
    #    stype          A new situation type, or ""
    #    location       A new location (map coords), or ""
    #                   (Must be in same neighborhood.)
    #    coverage       A new coverage, or ""
    #    inception      A new inception, or ""
    #    g              A new causing group, or ""
    #    resolver       A new resolving group, or ""
    #    rduration      A new auto-resolution duration, or ""
    #
    # Updates a situation given the parms, which are presumed to be
    # valid.
    #
    # Only the "location" parameter can be updated if the state isn't
    # INITIAL.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {SELECT * FROM situations WHERE s=$s} row1 {unset row1(*)}
            rdb eval {SELECT * FROM ensits_t  WHERE s=$s} row2 {unset row2(*)}

            # NEXT, Update the entity
            set sit [$type get $s]

            if {[$sit get change] eq ""} {
                $sit set change UPDATED
            }

            if {$stype ne ""} { 
                $sit set stype $stype
            }

            if {$g ne ""} { 
                $sit set g $g
            }

            if {$resolver ne ""} { 
                $sit set resolver $resolver
            }

            if {$rduration ne ""} {
                $sit set rduration $rduration
            }

            if {$inception ne ""} {
                $sit set inception $inception
            }

            if {$location ne ""} { 
                $sit set location $location 
                $sit set n [nbhood find {*}$location]
            }

            if {$coverage ne "" && $coverage ne [$sit get coverage]} {
                $sit set coverage $coverage
                $sit set tc       [simclock now]

                # Set state to ACTIVE/INACTIVE based on coverage,
                # unless we're still in the INITIAL state.
                if {[$sit get state] ne "INITIAL"} {
                    if {$coverage > 0.0} {
                        $sit set state ACTIVE
                    } else {
                        # NOTE: At this time, coverage can't be set to 0.
                        $sit set state INACTIVE
                    }
                }
            }

            # NEXT, notify the app.
            notifier send $type <Entity> update $s

            # NEXT, Return the undo command
            return [mytypemethod Replace [array get row1] [array get row2]]
        }
    }


    # mutate resolve parmdict
    #
    # parmdict     A dictionary of order parms
    #
    #    s              The situation ID
    #    resolver       Group responsible for resolving the situation, or "NONE"
    #                   or "".
    #
    # Resolves the situation, assigning credit where credit is due.

    typemethod {mutate resolve} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {SELECT * FROM situations WHERE s=$s} row1 {unset row1(*)}
            rdb eval {SELECT * FROM ensits_t  WHERE s=$s} row2 {unset row2(*)}
        
            # NEXT, Update the entity
            set sit [$type get $s]

            $sit set change     RESOLVED

            if {$resolver ne ""} {
                $sit set resolver   $resolver
            }

            $sit set state      ENDED
            $sit set tc         [simclock now]

            # NEXT, cancel pending events
            $sit CancelSpawn
            $sit CancelAutoResolve

            # NEXT, notify the app
            notifier send $type <Entity> update $s
        }

        # NEXT, Return the undo script
        return [mytypemethod Replace [array get row1] [array get row2]]
    }

    # Replace bdict ddict
    #
    # bdict    row dict for base entity
    # ddict    row dict for derived entity
    #
    # Restores the rows to the database, and reschedules any spawns.

    typemethod Replace {bdict ddict} {
        set s [dict get $bdict s]
        situation uncache $s
        
        rdb replace situations $bdict
        rdb replace ensits_t  $ddict

        set sit [situation get $s]

        if {[$sit get state] eq "ACTIVE"} {
            # Reschedule events, if any.
            $sit ScheduleSpawn
            $sit ScheduleAutoResolve
        }

        notifier send $type <Entity> update $s
    }

    #-------------------------------------------------------------------
    # Order Helpers


    # Refresh_SEC dlg fields fdict
    #
    # dlg       The order dialog
    # fields    A list of the fields that have changed.
    # fdict     The current field values.
    #
    # Refreshes the SITUATION:ENVIRONMENTAL:CREATE dialog.

    typemethod Refresh_SEC {dlg fields fdict} {
        # FIRST, if the location changed, determine the valid ensit
        # types
        if {"location" in $fields} {
            # NEXT, update the list of valid situation types.
            dict with fdict {
                puts "location is $location"

                if {$location ne "" && 
                    ![catch {
                        set mxy [map ref2m $location]
                        set n [nbhood find {*}$mxy]
                    }]
                } {
                    puts "$location is in nbhood $n"
                    set stypes [$type absentFromNbhood $n]
                    puts "The stypes are <$stypes>"
                    if {[llength $stypes] > 0} {
                        $dlg field configure stype \
                            -values [lsort $stypes]

                        $dlg disabled {}
                        return
                    }
                }
            }

            # NEXT, there's no valid location, or all ensits have
            # been created.  SO disable the stype
            $dlg set stype ""
            $dlg disabled stype
        }
    }

    # Refresh_SEU dlg fields fdict
    #
    # dlg       The order dialog
    # fields    A list of the fields that have changed.
    # fdict     The current field values.
    #
    # Refreshes the SITUATION:ENVIRONMENTAL:UPDATE dialog.

    typemethod Refresh_SEU {dlg fields fdict} {
        # FIRST, if the selected situation changed, load the 
        # rest of the fields.
        if {"s" in $fields} {
            # FIRST, set the list of valid values for the stype
            # field; if it's empty, we won't be able to load this
            # situation's stype.
            $dlg field configure stype -values [eensit names]

            # NEXT, load the ensit's data.
            $dlg loadForKey s
        }

        # NEXT, update the list of valid situation types.
        dict with fdict {
            if {$s ne ""} {
                set sit [situation get $s]

                set stypes [$type absentFromNbhood [$sit get n]]

                if {[llength $stypes] > 0} {
                    $dlg field configure stype \
                        -values [lsort [concat [$sit get stype] $stypes]]
                    $dlg disabled {}

                    return
                }
            }
        }

        # There is no situation selected, or there are no valid
        # stypes remaining.
        $dlg field configure stype -values {}
        $dlg disabled stype
    }
}

#-----------------------------------------------------------------------
# ensitType

snit::type ensitType {
    #-------------------------------------------------------------------
    # Components

    component base   ;# situationType instance


    #-------------------------------------------------------------------
    # Instance Variables

    # base and derived info arrays, aliased to the matching
    # situationType arrays.
    variable binfo
    variable dinfo

    #-------------------------------------------------------------------
    # Constructor

    constructor {s} {
        # FIRST, create the base situation object; this will retrieve
        # the data from disk.
        set base [situationType ${selfns}::base ::ensit $s]

        # NEXT, alias our arrays to the base arrays.
        upvar 0 [$base info vars binfo] ${selfns}::binfo
        upvar 0 [$base info vars dinfo] ${selfns}::dinfo
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to base

    #-------------------------------------------------------------------
    # Private Methods

    # ScheduleSpawn
    #
    # If this situation type spawns another situation, schedule the spawn.

    method ScheduleSpawn {} {
        # FIRST, cancel any previous spawn, since evidently it is 
        # changing.
        $self CancelSpawn

        # NEXT, does it spawn?
        set spawnTime [parmdb get ensit.$binfo(stype).spawnTime]

        if {$spawnTime == -1} {
            return
        }

        # NEXT, schedule the event.  First, get the spawn time in
        # ticks.
        set spawnTicks [simclock fromDays $spawnTime]

        # NEXT, get the time at which the spawn should occur: spawnTicks
        # after the ensit first begins to take effect.
        let spawnTime {$binfo(ts) + $spawnTicks}

        # NEXT, if this time has already passed, the ensit has
        # already spawned; don't reschedule it.
        if {$spawnTime <= [simclock now]} {
            return
        }

        # NEXT, schedule it.
        eventq schedule ensitSpawn $spawnTime $binfo(s)
    }


    # CancelSpawn
    #
    # If this situation type has a scheduled spawn,
    # cancel it.

    method CancelSpawn {} {
        log detail ensit "CancelSpawn s=$binfo(s)"
        rdb eval {
            SELECT id FROM eventq_etype_ensitSpawn 
            WHERE CAST (s AS INTEGER) = $binfo(s)
        } {
            log detail ensit "Cancelling eventq event $id"

            eventq cancel $id
        }
    }

    # ScheduleAutoResolve
    #
    # If this situation auto-resolves, schedules the resolution

    method ScheduleAutoResolve {} {
        # FIRST, cancel any previous event, since evidently it is 
        # changing.
        $self CancelAutoResolve

        # NEXT, does it auto-resolve?  If not, we're done.
        if {$dinfo(rduration) == 0} {
            return
        }

        # NEXT, schedule the event.  First, get the resolution time in
        # ticks.
        set ticks [simclock fromDays $dinfo(rduration)]


        # NEXT, get the time at which the resolution should occur:
        # rduration after the ensit first begins to take effect.  
        let t {$binfo(ts) + $ticks}
        eventq schedule ensitAutoResolve $t $binfo(s)
    }


    # CancelAutoResolve
    #
    # If this situation type has a scheduled auto-resolution,
    # cancel it.

    method CancelAutoResolve {} {
        log detail ensit "CancelAutoResolve s=$binfo(s)"
        rdb eval {
            SELECT id FROM eventq_etype_ensitAutoResolve 
            WHERE CAST (s AS INTEGER) = $binfo(s)
        } {
            log detail ensit "Cancelling eventq event $id"

            eventq cancel $id
        }
    }
}


#-----------------------------------------------------------------------
# Eventq: ensitSpawn

# ensitSpawn s
#
# s      An ensit ID
#
# Ensit s spawns another ensit, provide that s is still "live"

eventq define ensitSpawn {s} {
    # FIRST, is is still "live"?  If not, nothing to do.
    set sit [ensit get $s]

    if {![$sit islive]} {
        # TBD: This should probably be an assertion, really.
        return
    }

    # NEXT, try to spawn each dependent situation
    foreach stype [parmdb get ensit.[$sit get stype].spawns] {
        log normal ensit \
            "spawn $s: [$sit get stype] spawns $stype in [$sit get n]"

        # FIRST, if there's already an ensit of this type, don't spawn.
        if {[ensit existsInNbhood [$sit get n] $stype]} {
            log warning ensit \
                "can't spawn $stype in [$sit get n]: already present"
            continue
        }

        # NEXT, schedule it.  Use bgcatch, so that one bad absit doesn't
        # prevent others.

        bgcatch {
            set parmDict {}
            lappend parmDict stype     $stype
            lappend parmDict location  [$sit get location]
            lappend parmDict coverage  [$sit get coverage]
            lappend parmDict g         [$sit get g]
            lappend parmDict resolver  [$sit get resolver]
            lappend parmDict rduration [parmdb get ensit.$stype.duration]
            lappend parmDict inception 1

            ensit mutate create $parmDict
        }
    }
}

# ensitAutoResolve s
#
# s     An ensit ID
#
# Ensit s is auto-resolved, provided that s is still alive

eventq define ensitAutoResolve {s} {
    # FIRST, is is still "live"?  If not, nothing to do.
    set sit [ensit get $s]

    if {![$sit islive]} {
        # TBD: This should probably be an assertion, really.
        return
    }

    # NEXT, resolve the situation, using the preset resolver.
    ensit mutate resolve [list s $s resolver ""]
}


#-------------------------------------------------------------------
# Orders

# SITUATION:ENVIRONMENTAL:CREATE
#
# Creates new ensits.

order define ::ensit SITUATION:ENVIRONMENTAL:CREATE {
    title "Create Environmental Situation"
    options \
        -schedulestates {PREP PAUSED}         \
        -sendstates     {PREP PAUSED}         \
        -refreshcmd     {::ensit Refresh_SEC}

    parm location   text  "Location"      -tags nbpoint
    parm stype      enum  "Type"          -schedwheninvalid
    parm coverage   text  "Coverage"      -defval 1.0
    parm inception  enum  "Inception?"    -type eyesno -defval "YES"
    parm g          enum  "Caused By"     -type {ptype g+none} \
        -defval NONE
    parm resolver   enum  "Resolved By"   -type {ptype g+none} \
        -defval NONE
    parm rduration  text  "Duration"
} {
    # FIRST, prepare and validate the parameters
    prepare location  -toupper   -required -type refpoint
    prepare stype     -toupper   -required -type eensit
    prepare coverage             -required -type rfraction
    prepare inception -toupper   -required -type boolean
    prepare g         -toupper   -required -type {ptype g+none}
    prepare resolver  -toupper   -required -type {ptype g+none}
    prepare rduration                      -type idays

    returnOnError

    # NEXT, additional validation steps.

    validate location {
        set n [nbhood find {*}$parms(location)]
        
        if {$n eq ""} {
            reject location "Should be within a neighborhood"
        }
    }

    validate coverage {
        if {$parms(coverage) == 0.0} {
            reject coverage "Coverage must be greater than 0."
        }
    }

    returnOnError

    validate stype {
        if {[ensit existsInNbhood $n $parms(stype)]} {
            reject stype \
                "An ensit of this type already exists in this neighborhood."
        }
    }

    returnOnError -final

    # NEXT, create the situation.
    lappend undo [$type mutate create [array get parms]]
    
    setundo [join $undo \n]
}


# SITUATION:ENVIRONMENTAL:DELETE
#
# Deletes an ensit.

order define ::ensit SITUATION:ENVIRONMENTAL:DELETE {
    title "Delete Environmental Situation"
    options \
        -sendstates {PREP PAUSED}

    parm s  key  "Situation"  -table    gui_ensits_initial \
                              -key      s                  \
                              -dispcols longid             \
                              -tags     situation
} {
    # FIRST, prepare the parameters
    prepare s -required -type {ensit initial}

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     SITUATION:ENVIRONMENTAL:DELETE   \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this situation?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }


    # NEXT, delete the situation.
    lappend undo [$type mutate delete $parms(s)]
    
    setundo [join $undo \n]
}


# SITUATION:ENVIRONMENTAL:UPDATE
#
# Updates existing ensits.

order define ::ensit SITUATION:ENVIRONMENTAL:UPDATE {
    title "Update Environmental Situation"
    options \
        -sendstates {PREP PAUSED} \
        -refreshcmd {ensit Refresh_SEU}

    parm s          key  "Situation"    -table    gui_ensits_initial \
                                        -key      s                  \
                                        -dispcols longid             \
                                        -tags     situation
    parm location   text  "Location"    -tags     nbpoint
    parm stype      enum  "Type"
    parm coverage   text  "Coverage"
    parm inception  enum  "Inception?"  -type     eyesno
    parm g          enum  "Caused By"   -type     {ptype g+none}
    parm resolver   enum  "Resolved By" -type     {ptype g+none}
    parm rduration  text  "Duration"    

} {
    # FIRST, check the situation
    prepare s                    -required -type {ensit initial}

    returnOnError

    # NEXT, get the situation object
    set sit [ensit get $parms(s)]

    # NEXT, prepare the remaining parameters
    prepare location  -toupper  -type refpoint 
    prepare stype     -toupper  -type eensit   -oldvalue [$sit get stype]
    prepare coverage            -type rfraction
    prepare inception -toupper  -type boolean
    prepare g         -toupper  -type {ptype g+none}
    prepare resolver  -toupper  -type {ptype g+none}
    prepare rduration           -type idays

    returnOnError

    # NEXT, get the old neighborhood
    set n [$sit get n]


    # NEXT, validate the other parameters.
    validate location {
        set n [nbhood find {*}$parms(location)]
            
        if {$n eq ""} {
            reject location "Should be within a neighborhood"
        }
    }

    validate stype {
        if {[ensit existsInNbhood $n $parms(stype)]} {
            reject stype \
                "An ensit of this type already exists in this neighborhood."
        }
    }


    validate coverage {
        if {$parms(coverage) == 0.0} {
            reject coverage "Coverage must be greater than 0."
        }
    }

    returnOnError -final

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}


# SITUATION:ENVIRONMENTAL:MOVE
#
# Moves an existing ensit.

order define ::ensit SITUATION:ENVIRONMENTAL:MOVE {
    title "Move Environmental Situation"
    options \
        -sendstates {PREP PAUSED}

    parm s          key   "Situation"   -table    gui_ensits \
                                        -key      s          \
                                        -dispcols longid     \
                                        -tags     situation
    parm location   text  "Location"    -tags     nbpoint
} {
    # FIRST, check the situation
    prepare s                    -required -type ensit

    returnOnError

    # NEXT, get the situation object
    set sit [ensit get $parms(s)]

    # NEXT, prepare the remaining parameters
    prepare location  -toupper  -required -type refpoint 

    returnOnError

    # NEXT, get the old neighborhood
    set n [$sit get n]


    # NEXT, validate the other parameters.  In the INITIAL state, the
    # ensit can be moved to any neighborhood; in any other state it
    # can only be moved within the neighborhood.
    # location can be changed.

    if {[$sit get state] eq "INITIAL"} {
        validate location {
            set n [nbhood find {*}$parms(location)]
            
            if {$n eq ""} {
                reject location "Should be within a neighborhood"
            }
        }
    } else {
        # Not INITIAL
        validate location {
            set n [nbhood find {*}$parms(location)]

            if {$n ne [$sit get n]} {
                reject location "Cannot remove situation from its neighborhood"
            }
        }
    }

    returnOnError -final

    # NEXT, add blank parms
    array set parms {
        stype     ""
        coverage  ""
        inception ""
        g         ""
        resolver  ""
        rduration ""
    }

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}


# SITUATION:ENVIRONMENTAL:RESOLVE
#
# Resolves an ensit.

order define ::ensit SITUATION:ENVIRONMENTAL:RESOLVE {
    title "Resolve Environmental Situation"
    options \
        -schedulestates {PREP PAUSED}                    \
        -sendstates     {PREP PAUSED}                    \
        -refreshcmd     {orderdialog refreshForKey s *}

    parm s          key  "Situation"    -table    gui_ensits \
                                        -key      s          \
                                        -dispcols longid     \
                                        -tags     situation
    parm resolver  enum  "Resolved By"  -type     {ptype g+none}
} {
    # FIRST, prepare the parameters
    prepare s         -required -type {ensit live}
    prepare resolver  -toupper  -type {ptype g+none}

    returnOnError -final

    # NEXT, resolve the situation.
    lappend undo [$type mutate resolve [array get parms]]
    
    setundo [join $undo \n]
}



