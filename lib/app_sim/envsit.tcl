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


    # existsInNbhood stype n
    #
    # stype      An envsit type
    # n          A neighborhood ID
    #
    # Returns 1 if there's a live envsit of the specified type
    # already present in n, and 0 otherwise.

    typemethod existsInNbhood {stype n} {
        return [rdb exists {
            SELECT s FROM envsits
            WHERE stype =  $stype 
            AND   n     =  $n
            AND   state != 'ENDED'
            
        }]
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

            # TBD: Verify that nbhood hasn't changed if driver exists.

            if {$location ne ""} { $sit set location $location }
            if {$g        ne ""} { $sit set g        $g        }
            if {$flist    ne ""} { $sit set flist    $flist    }

            $sit set change   UPDATED
            $sit set assess   1

            if {$coverage ne "" && $coverage ne [$sit get coverage]} {
                $sit set coverage $coverage
                $sit set assess   1
                $sit set tc       [simclock now]

                if {$coverage > 0.0} {
                    $sit set state ACTIVE
                } else {
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
        if {[envsit existsInNbhood $stype [$sit get n]]} {
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
# Rules

# SITUATION:ENVIRONMENTAL:CREATE
#
# Creates new environment situations.

order define ::envsit SITUATION:ENVIRONMENTAL:CREATE {
    title "Create Environmental Situation"

    # TBD: stype should be limited by the envsits already in existence.
    parm stype      enum  "Type"          -type eenvsit
    parm location   text  "Location"      -tags point
    parm coverage   text  "Coverage"      -defval 1.0
    parm inception  enum  "Inception?"    -type eyesno -defval "YES"

    # TBD: Name of group, or empty
    parm g          text  "Caused By"

    # TBD: List of affected groups, or ALL
    parm flist      text  "Affected Groups" -defval ALL
} {
    # FIRST, prepare and validate the parameters
    prepare stype     -toupper   -required -type eenvsit
    prepare coverage             -required -type rfraction
    prepare location  -toupper   -required -type refpoint
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

    returnOnError

    validate stype {
        if {[envsit existsInNbhood $parms(stype) $n]} {
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



