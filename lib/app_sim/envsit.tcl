#-----------------------------------------------------------------------
# TITLE:
#    envsit.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1) Environmental Situation module
#
#    This module defines a singleton, "envsit", which is used to
#    manage the collection of environmental situation objects, or envsits.
#    Envsits are situations; see situation(sim) for additional details.
#
#    Entities defined in this file:
#
#    envsit      -- The envsit ensemble
#    envsitType  -- The type for the envsit objects.
#
#    A single snit::type could do both jobs--but at the expense
#    of accidentally creating an envsit object if an incorrect envsit
#    method name is used.
#
#    * Envsits are created, updated, and deleted via the "mutate *" 
#      commands and the SITUATION:ENVIRONMENTAL:* orders.
#
#    * This module calls the envsit rule sets when it detects 
#      relevant state transitions.
#
# EVENT NOTIFICATIONS:
#    The ::envsit module sends the following notifier(n) events:
#
#    <Entity> op s
#        When called, the op will be one of 'create', 'update' or 'delete',
#        and s will be the ID of the situation.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# envsit singleton

snit::type envsit {
    # Make it an ensemble
    pragma -hasinstances 0

   
    #-------------------------------------------------------------------
    # Initialization method

    typemethod init {} {
        # FIRST, envsit is up.
        log normal envsit "Initialized"
    }

    #-------------------------------------------------------------------
    # Assessment of Attitudinal Effects

    # assess
    #
    # Calls the DAM rule sets for each situation requiring assessment.

    typemethod assess {} {
        set ids [rdb eval {SELECT s FROM envsits WHERE assess=1}]
        
        foreach s $ids {
            # FIRST, get the situation and clear the assess flag
            set sit [$type get $s]
            $sit set assess 0

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
                # envsit_rules begin $sit
            }

            # NEXT, monitor its coverage
            # envsit_rules monitor $sit

            # NEXT, if it's ended then get the resolution effects.
            if {[$sit get state] eq "ENDED"} {
                # envsit_rules resolve $sit
            }
        }
    }

    #-------------------------------------------------------------------
    # Queries

    # table
    #
    # Return the name of the RDB table for this type.

    typemethod table {} {
        return "envsits_t"
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
    # stype      An envsit type
    #
    # If stype is given, returns 1 if there's a live envsit of the 
    # specified type already present in n, and 0 otherwise.  Otherwise,
    # returns a list of the envsit types that exist in n.

    typemethod existsInNbhood {n {stype ""}} {
        if {$stype eq ""} {
            return [rdb eval {
                SELECT stype FROM envsits
                WHERE n     =  $n
                AND   state != 'ENDED'
            }]
        } else {
            return [rdb exists {
                SELECT stype FROM envsits
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
    # Returns a list of the envsits which do not exist in this
    # neighborhood.

    typemethod absentFromNbhood {n} {
        # TBD: Consider writing an lsetdiff routine
        set present [$type existsInNbhood $n]

        set absent [list]

        foreach stype [eenvsit names] {
            if {$stype ni $present} {
                lappend absent $stype
            }
        }

        return $absent
    }


    # names
    #
    # List of envsit IDs.

    typemethod names {} {
        return [rdb eval {
            SELECT s FROM envsits
        }]
    }


    # validate s
    #
    # s      A situation ID
    #
    # Verifies that s is an envsit.

    typemethod validate {s} {
        if {$s ni [$type names]} {
            return -code error -errorcode INVALID \
                "Invalid environmental situation ID: \"$s\""
        }

        return $s
    }

    # pending names
    #
    # List of pending envsit IDs.  An envsit is pending if it has
    # been created but hasn't yet been assessed.  While it is pending,
    # it can be edited and deleted as desired; after that, many
    # fewer things can be done to it.

    typemethod {pending names} {} {
        return [rdb eval {
            SELECT s FROM envsits
            WHERE driver == -1
        }]
    }


    # pending validate s
    #
    # s      A situation ID
    #
    # Verifies that s is pending.

    typemethod {pending validate} {s} {
        if {$s ni [$type pending names]} {
            return -code error -errorcode INVALID \
                "operation is invalid; time has passed."
        }

        return $s
    }


    #-------------------------------------------------------------------
    # Mutators

    # mutate create parmdict
    #
    # parmdict     A dictionary of envsit parms
    #
    #    stype          The situation type
    #    location       The situation's initial location (map coords)
    #    coverage       The situation's coverage
    #    g              The group causing the situation, or ""
    #    flist          Civ groups affected by the situation, or "ALL" 
    #                   for all.
    #    inception      1 if there are inception effects, and 0 otherwise.
    #
    # Creates an envsit given the parms, which are presumed to be
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
                       flist     $flist     \
                       g         $g]

            rdb eval {
                INSERT INTO envsits_t(s,location,assess,inception)
                VALUES($s,$location,1,$inception)
            }

            # NEXT, if it spawns, schedule the spawn
            set sit [$type get $s]

            $sit ScheduleSpawn

            # NEXT, inform all clients about the new object.
            log detail envsit "$s: created for $n,$stype,$coverage"
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
    # situation has not yet been assessed for the first time.

    typemethod {mutate delete} {s} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM situations WHERE s=$s} row1 { unset row1(*) }
        rdb eval {SELECT * FROM envsits_t  WHERE s=$s} row2 { unset row2(*) }

        # NEXT, unschedule any spawn
        set sit [$type get $s]
        
        $sit CancelSpawn

        # NEXT, remove it from the object cache
        situation uncache $s

        # NEXT, delete it.
        rdb eval {
            DELETE FROM situations WHERE s=$s;
            DELETE FROM envsits_t  WHERE s=$s;
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
        rdb insert envsits_t  $ddict

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
    #    g              A new causing group, or ""
    #    flist          A new list of affected groups, or ""
    #
    # Updates a situation given the parms, which are presumed to be
    # valid.
    #
    # The following parameters should be updated only if the situation
    # has not yet been assessed:  g, flist

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {SELECT * FROM situations WHERE s=$s} row1 {unset row1(*)}
            rdb eval {SELECT * FROM envsits_t  WHERE s=$s} row2 {unset row2(*)}

            # NEXT, Update the entity
            set sit [$type get $s]

            $sit set change   UPDATED

            if {$stype    ne ""} { $sit set stype    $stype    }
            if {$g        ne ""} { $sit set g        $g        }
            if {$flist    ne ""} { $sit set flist    $flist    }

            if {$location ne ""} { 
                $sit set location $location 
                $sit set n [nbhood find {*}$location]
            }

            if {$coverage ne "" && $coverage ne [$sit get coverage]} {
                $sit set coverage $coverage
                $sit set assess   1
                $sit set tc       [simclock now]

                if {$coverage > 0.0} {
                    $sit set state ACTIVE
                } else {
                    # NOTE: At this time, coverage can't be set to 0.
                    $sit set state INACTIVE
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
            rdb eval {SELECT * FROM envsits_t  WHERE s=$s} row2 {unset row2(*)}
        
            # NEXT, Update the entity
            set sit [$type get $s]

            $sit set change   RESOLVED
            $sit set coverage 0.0
            $sit set resolver $resolver

            $sit set assess   1
            $sit set state    ENDED
            $sit set tc       [simclock now]

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
    # Restores the rows to the database

    typemethod Replace {bdict ddict} {
        situation uncache [dict get $bdict s]
        rdb replace situations $bdict
        rdb replace envsits_t  $ddict
        notifier send $type <Entity> update [dict get $bdict s]
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
}

#-----------------------------------------------------------------------
# envsitType

snit::type envsitType {
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
        set base [situationType ${selfns}::base ::envsit $s]

        # NEXT, alias our arrays to the base arrays.
        upvar 0 [$base info vars binfo] ${selfns}::binfo
        upvar 0 [$base info vars dinfo] ${selfns}::dinfo
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to base

    # isPending
    #
    # Returns 1 if the situation is pending, and 0 otherwise.

    method pending {} {
        expr {$binfo(driver) == -1}
    }

    #-------------------------------------------------------------------
    # Private Methods

    # ScheduleSpawn
    #
    # If this situation type spawns another situation, schedule the spawn.

    method ScheduleSpawn {} {
        # FIRST, does it spawn?
        set spawnTime [parmdb get envsit.$binfo(stype).spawnTime]

        if {$spawnTime == -1} {
            return
        }

        # NEXT, schedule the event
        set spawnTicks [simclock fromDays $spawnTime]

        eventq schedule envsitSpawn [simclock now $spawnTicks] $binfo(s)
    }


    # CancelSpawn
    #
    # If this situation type spawns another situation, cancel the spawn.

    method CancelSpawn {} {
        rdb eval {
            SELECT id FROM eventq_etype_envsitSpawn WHERE s=$binfo(s)
        } {
            eventq cancel $id
        }
    }
}


#-----------------------------------------------------------------------
# Eventq: envsitSpawn

# envsitSpawn s
#
# s      An envsit ID
#
# Envsit s spawns another envsit, provide that s is still "live"

eventq define envsitSpawn {s} {
    # FIRST, is is still "live"?  If not, nothing to do.
    set sit [envsit get $s]

    if {![$sit islive]} {
        return
    }

    # NEXT, try to spawn each dependent situation
    foreach stype [parmdb get envsit.[$sit get stype].spawns] {
        log normal envsit \
            "spawn $s: [$sit get stype] spawns $stype in [$sit get n]"

        # FIRST, if there's already an envsit of this type, don't spawn.
        if {[envsit existsInNbhood [$sit get n] $stype]} {
            log warning envsit \
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
            lappend parmDict flist     [$sit get flist]
            lappend parmDict inception 1

            envsit mutate create $parmDict
        }
    }
}

#-------------------------------------------------------------------
# Orders

# SITUATION:ENVIRONMENTAL:CREATE
#
# Creates new envsits.

order define ::envsit SITUATION:ENVIRONMENTAL:CREATE {
    title "Create Environmental Situation"
    options -sendstates {PREP PAUSED RUNNING}

    parm location   text  "Location"      -tags point -refresh
    parm stype      enum  "Type"  \
        -refreshcmd {::envsit RefreshSType}
    parm coverage   text  "Coverage"      -defval 1.0
    parm inception  enum  "Inception?"    -type eyesno -defval "YES"

    # TBD: Name of group, or empty
    parm g          text  "Caused By"

    # TBD: List of affected groups, or ALL
    parm flist      text  "Affected Groups" -defval ALL
} {
    # FIRST, prepare and validate the parameters
    prepare location  -toupper   -required -type refpoint
    prepare stype     -toupper   -required -type eenvsit
    prepare coverage             -required -type rfraction
    prepare inception -toupper   -required -type boolean
    prepare g         -toupper             -type group

    # TBD: Should be a list of groups resident in the nbhood, or ALL
    prepare flist     -toupper   -required

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
        if {[envsit existsInNbhood $n $parms(stype)]} {
            reject stype \
                "An envsit of this type already exists in this neighborhood."
        }
    }

    # TBD: Verify that groups in flist are in nbhood.

    returnOnError

    # NEXT, create the situation.
    lappend undo [$type mutate create [array get parms]]
    
    setundo [join $undo \n]
}


# SITUATION:ENVIRONMENTAL:DELETE
#
# Deletes an envsit.

order define ::envsit SITUATION:ENVIRONMENTAL:DELETE {
    title "Delete Environmental Situation"
    options -sendstates {PREP PAUSED RUNNING}

    parm s  enum  "Situation"  -tags situation -type {envsit pending}
} {
    # FIRST, prepare the parameters
    prepare s -required -type {envsit pending}

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


    # NEXT, create the situation.
    lappend undo [$type mutate delete $parms(s)]
    
    setundo [join $undo \n]
}


# SITUATION:ENVIRONMENTAL:UPDATE
#
# Updates existing envsits.

order define ::envsit SITUATION:ENVIRONMENTAL:UPDATE {
    title "Update Environmental Situation"
    options \
        -table      gui_envsits           \
        -sendstates {PREP PAUSED RUNNING}

    parm s          key   "Situation"   -tags situation
    parm location   text  "Location"    -tags point

    # TBD: Only allow current type, or an absent type
    parm stype      enum  "Type"        -type eenvsit
    parm coverage   text  "Coverage"    -defval 1.0
    parm inception  enum  "Inception?"  -type eyesno -defval "YES"

    # TBD: Name of group, or NONE
    parm g          text  "Caused By"

    # TBD: List of affected groups, or ALL
    parm flist      text  "Affected Groups" -defval ALL

} {
    # FIRST, check the situation
    prepare s                    -required -type envsit

    # NEXT, get the situation object
    set sit [envsit get $parms(s)]

    # NEXT, Can we even update this situation?
    validate s {
        if {[$sit get state] eq "ENDED"} {
            reject s "Cannot update a situation that has ended."
        }
    }
    returnOnError

    # NEXT, prepare the remaining parameters
    prepare location  -toupper  -type refpoint 
    prepare stype     -toupper  -type eenvsit   -oldvalue [$sit get stype]
    prepare coverage            -type rfraction -oldvalue [$sit get coverage]
    prepare inception -toupper  -type boolean   -oldvalue [$sit get inception]
    prepare g         -toupper  -type group     -oldvalue [$sit get g]
    prepare flist     -toupper                  -oldvalue [$sit get flist]

    returnOnError


    # NEXT, validate the other parameters

    validate location {
        set n [nbhood find {*}$parms(location)]

        if {[$sit pending]} {
            if {$n eq ""} {
                reject location "Should be within a neighborhood"
            }
        } else {
            if {$n ne [$sit get n]} {
                reject location "Cannot remove situation from its neighborhood"
            }
        }
    }

    validate stype {
        if {[$sit pending]} {
            if {[envsit existsInNbhood $n $parms(stype)]} {
                reject stype \
                "An envsit of this type already exists in this neighborhood."
            }
        } else {
            reject coverage "Cannot update this parameter; time has advanced."
        }
    }


    validate coverage {
        if {[$sit pending]} {
            if {$parms(coverage) == 0.0} {
                reject coverage "Coverage must be greater than 0."
            }
        } else {
            reject coverage "Cannot update this parameter; time has advanced."
        }
    }


    validate inception {
        if {![$sit pending]} {
            reject inception "Cannot update this parameter; time has advanced."
        }
    }


    validate flist {
        if {![$sit pending]} {
            reject flist "Cannot update this parameter; time has advanced."
        }
    }
    

    validate g {
        if {![$sit pending]} {
            reject g "Cannot update this parameter; time has advanced."
        }
    }

    returnOnError

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}

