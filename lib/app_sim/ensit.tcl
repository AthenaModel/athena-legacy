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
    # Initialization method

    typemethod init {} {
        # FIRST, ensit is up.
        log normal ensit "Initialized"
    }

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

            # NEXT, if it's in the initial state, make it active
            if {[$sit get state] eq "INITIAL"} {
                $sit set state ACTIVE

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


    # doer names
    #
    # List of names of groups that can cause and resolve ensits,
    # plus "NONE".

    typemethod {doer names} {} {
        linsert [group names] 0 NONE
    }


    # doer validate g
    #
    # g       Potentially, a doing group g
    #
    # Verifies that g is a valid doing group.

    typemethod {doer validate} {g} {
        if {$g ni [$type doer names]} {
            set names [join [$type doer names] ", "]

            set msg "should be one of: $names"

            return -code error -errorcode INVALID \
                "Invalid doing group, $msg"
        }

        return $g
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
            SELECT s
            FROM ensits LEFT OUTER JOIN groups 
            ON (ensits.resolver = groups.g)
            WHERE state = 'ENDED'
            AND   ensits.resolver != 'NONE'
            AND   longname IS NULL
        } {
            lappend undo [$type mutate resolve [list s $s resolver NONE]]
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
    #
    # Creates an ensit given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, get the remaining attribute values
            set n [nbhood find {*}$location]
            assert {$n ne ""}

            # NEXT, Create the situation
            set s [situation create $type   \
                       stype     $stype     \
                       n         $n         \
                       coverage  $coverage  \
                       g         $g]

            rdb eval {
                INSERT INTO ensits_t(s,location,inception)
                VALUES($s,$location,$inception)
            }

            # NEXT, if it spawns, schedule the spawn
            set sit [$type get $s]

            $sit ScheduleSpawn

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

        # NEXT, unschedule any spawn
        set sit [$type get $s]
        
        $sit CancelSpawn

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

        set sit [$type get $s]

        $sit ScheduleSpawn

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

                # The spawn parameters vary by stype; update accordingly.
                $sit CancelSpawn
                $sit ScheduleSpawn
            }

            if {$g ne ""} { 
                $sit set g $g
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
    #    resolver       Group responsible for resolving the situation, or ""
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
            $sit set resolver   $resolver

            $sit set state      ENDED
            $sit set tc         [simclock now]

            $sit CancelSpawn

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
        
        $sit CancelSpawn
        $sit ScheduleSpawn

        notifier send $type <Entity> update $s
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # RefreshSType field parmdict
    #
    # field     The "stype" field in an S:E:CREATE dialog
    # parmdict  The current values of the various fields
    #
    # Updates the "stype" field's state.

    typemethod RefreshSType {field parmdict} {
        dict with parmdict {
            set nbhood ""
            catch {
                set location [string trim [string toupper $location]]
                set nbhood [nbhood find {*}[refpoint validate $location]]
            }

            if {$nbhood ne ""} {
                set stypes [$type absentFromNbhood $nbhood]
            } else {
                set stypes [list]
            }

            if {[llength $stypes] > 0} {
                $field configure -values $stypes
                $field configure -state normal
            } else {
                $field configure -values {}
                $field configure -state disabled
            }
        }
    }


    # RefreshUpdateParm parm field parmdict
    #
    # parm      The field's parm
    # field     A field in an S:E:UPDATE dialog
    # parmdict  The current values of the various fields
    #
    # Updates the field's state.

    typemethod RefreshUpdateParm {parm field parmdict} {
        dict with parmdict {
            set sit [situation get $s]

            # FIRST, assume we can edit.
            $field configure -state normal

            # NEXT, for stype get the valid (unused) types, plus the
            # current type
            if {$parm eq "stype"} {
                set stypes [$type absentFromNbhood [$sit get n]]]]

                if {[llength $stypes] > 0} {
                    $field configure \
                        -values [lsort [concat [$sit get stype] $stypes]]
                    $field configure -state normal
                } else {
                    $field configure -values {}
                    $field configure -state disabled
                }
            }
        }
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
        # FIRST, does it spawn?
        set spawnTime [parmdb get ensit.$binfo(stype).spawnTime]

        if {$spawnTime == -1} {
            return
        }

        # NEXT, schedule the event.  First, get the spawn time in
        # ticks.
        set spawnTicks [simclock fromDays $spawnTime]

        # NEXT, get the time at which the spawn should occur: spawnTicks
        # after the ensit first begins to take effect.  Since 
        # ensits are created at time t, but take effect at time t+1,
        # we need to add a tick.
        incr spawnTicks

        eventq schedule ensitSpawn [simclock now $spawnTicks] $binfo(s)
    }


    # CancelSpawn
    #
    # If this situation type spawns another situation, cancel the spawn.

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
            lappend parmDict inception 1

            ensit mutate create $parmDict
        }
    }
}

#-------------------------------------------------------------------
# Orders

# SITUATION:ENVIRONMENTAL:CREATE
#
# Creates new ensits.

order define ::ensit SITUATION:ENVIRONMENTAL:CREATE {
    title "Create Environmental Situation"
    options -sendstates {PREP PAUSED RUNNING}

    parm location   text  "Location"      -tags nbpoint -refresh
    parm stype      enum  "Type"  \
        -refreshcmd {::ensit RefreshSType}
    parm coverage   text  "Coverage"      -defval 1.0
    parm inception  enum  "Inception?"    -type eyesno -defval "YES"
    parm g          enum  "Caused By"     -type [list ensit doer] \
        -defval NONE
} {
    # FIRST, prepare and validate the parameters
    prepare location  -toupper   -required -type refpoint
    prepare stype     -toupper   -required -type eensit
    prepare coverage             -required -type rfraction
    prepare inception -toupper   -required -type boolean
    prepare g         -toupper             -type [list ensit doer]

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

    returnOnError

    # NEXT, g defaults to NONE
    if {$parms(g) eq ""} {
        set parms(g) NONE
    }

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
        -table      gui_ensits_initial     \
        -sendstates {PREP PAUSED RUNNING}

    parm s  key  "Situation"  -tags situation
} {
    # FIRST, prepare the parameters
    prepare s -required -type {ensit initial}

    returnOnError

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
        -table      gui_ensits_initial     \
        -sendstates {PREP PAUSED RUNNING}

    parm s          key   "Situation"   -tags situation
    parm location   text  "Location"    -tags nbpoint

    parm stype      enum  "Type" \
        -refreshcmd [list ::ensit RefreshUpdateParm stype]
    parm coverage   text  "Coverage"    -defval 1.0 
    parm inception  enum  "Inception?"  -type eyesno -defval "YES"
    parm g          enum  "Caused By"   -type [list ensit doer]

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
    prepare g -toupper  -type {ensit doer}

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

    returnOnError

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}


# SITUATION:ENVIRONMENTAL:MOVE
#
# Moves an existing ensit.

order define ::ensit SITUATION:ENVIRONMENTAL:MOVE {
    title "Move Environmental Situation"
    options \
        -table      gui_ensits           \
        -sendstates {PREP PAUSED RUNNING}

    parm s          key   "Situation"   -tags situation
    parm location   text  "Location"    -tags nbpoint
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

    returnOnError

    # NEXT, add blank parms
    array set parms {
        stype     ""
        coverage  ""
        inception ""
        g         ""
    }

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}


# SITUATION:ENVIRONMENTAL:RESOLVE
#
# Resolves an ensit.

order define ::ensit SITUATION:ENVIRONMENTAL:RESOLVE {
    title "Resolve Environmental Situation"
    options -sendstates {PREP PAUSED RUNNING}

    parm s         enum  "Situation"    -tags situation -type {ensit live}
    parm resolver  enum  "Resolved By"  -type [list ensit doer] \
        -defval NONE
} {
    # FIRST, prepare the parameters
    prepare s         -required -type {ensit live}
    prepare resolver  -toupper  -type [list ensit doer]

    returnOnError

    # NEXT, resolve the situation.
    lappend undo [$type mutate resolve [array get parms]]
    
    setundo [join $undo \n]
}


