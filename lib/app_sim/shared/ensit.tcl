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
#      commands and the ENSIT:* orders.
#
#    * This module calls the ensit rule on "ensit assess", which is 
#      done as part of the time advance.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# ensit singleton

snit::type ensit {
    # Make it an ensemble
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Scenario Control
    
    # rebase
    #
    # Create a new scenario prep baseline based on the current simulation
    # state.
    
    typemethod rebase {} {
        # FIRST, Delete all ensits that have ended.
        foreach s [rdb eval {
            SELECT s FROM ensits WHERE state == 'RESOLVED'
        }] {
            rdb eval {
                DELETE FROM ensits WHERE s=$s;
            }
        }

        # NEXT, clean up remaining ensits
        foreach {s ts} [rdb eval {
            SELECT s, ts FROM ensits WHERE state != 'INITIAL'
        }] {
            rdb eval {
                UPDATE ensits
                SET state='INITIAL',
                    ts=now(),
                    inception=0,
                    rduration=CASE WHEN rduration = 0 THEN 0 
                                   ELSE rduration+$ts-now() END;
            }
        }
    }
    
    #-------------------------------------------------------------------
    # Assessment of Attitudinal Effects

    # assess
    #
    # Calls the DAM rule sets for each situation requiring assessment.
    #
    # TBD: Make this [ensit tick]

    typemethod assess {} {
        # FIRST, delete ensits that were resolved during past ticks.
        rdb eval {
            DELETE FROM ensits
            WHERE state == 'RESOLVED' AND tr < now()
        }

        # NEXT, Determine the correct state for each ensit.  Those in the
        # INITIAL state are now ONGOING, and those ONGOING whose resolution 
        # time has been reached are now RESOLVED.
        set now [simclock now]

        foreach {s state rduration tr} [rdb eval {
            SELECT s, state, rduration, tr FROM ensits
        }] {
            # FIRST, put it in the correct state.
            if {$state eq "INITIAL"} {
                # FIRST, set the state
                rdb eval {UPDATE ensits SET state='ONGOING' WHERE s=$s}
            } elseif {$rduration > 0 && $tr == $now} {
                rdb eval {UPDATE ensits SET state='RESOLVED' WHERE s=$s}
            }
        }

        # NEXT, assess all ensits.
        driver::ensit assess

        # NEXT, clear all inception flags.
        rdb eval {UPDATE ensits SET inception=0}
    }

    #-------------------------------------------------------------------
    # Queries

    # get s ?parm?
    #
    # s     - A situation ID
    # parm  - An ensits column name
    #
    # Retrieves a row dictionary, or a particular column value, from
    # ensits.

    typemethod get {s {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM ensits WHERE s=$s} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
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
                AND   state != 'RESOLVED'
            }]
        } else {
            return [rdb exists {
                SELECT stype FROM ensits
                WHERE n     =  $n
                AND   state != 'RESOLVED'
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
            SELECT s FROM ensits WHERE state != 'RESOLVED'
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
    # *  If the "resolver" group no longer exists, that
    #    field is set to "NONE".
    #
    # *  Updates every ensit's "n" attribute to reflect the
    #    current state of the neighborhood.
    #
    # TBD: In the long run, I want to get rid of this routine.
    # But that's a big job.  Ensits can be created in PREP, and an 
    # ensit's neighborhood depends on its location.  As neighborhoods come 
    # and go, an ensit's neighborhood really can change; and this needs
    # to be updated at that time.  This routine handles this.
    #
    # Ultimately, ensit neighborhood should be primary, and location should
    # be only for visualization.

    typemethod {mutate reconcile} {} {
        set undo [list]

        # FIRST, set resolver to NONE if resolver doesn't exist.
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
        foreach {s n location} [rdb eval {
            SELECT s, n, location FROM ensits
        }] { 
            set newNbhood [nbhood find {*}$location]

            if {$newNbhood ne $n} {

                rdb eval {
                    UPDATE ensits SET n=$newNbhood
                    WHERE s=$s;
                }

                lappend undo [mytypemethod RestoreNbhood $s $n]
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
        # FIRST, save it
        rdb eval { UPDATE ensits SET n=$n WHERE s=$s; }
    }



    # mutate create parmdict
    #
    # parmdict     A dictionary of ensit parms
    #
    #    stype          The situation type
    #    location       The situation's initial <loc></loc>ation (map coords)
    #    coverage       The situation's coverage
    #    inception      1 if there are inception effects, and 0 otherwise.
    #    resolver       The group that will resolve the situation, or ""
    #    rduration      Auto-resolution duration, in weeks
    #
    # Creates an ensit given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {}

        # FIRST, get the remaining attribute values
        set n [nbhood find {*}$location]
        assert {$n ne ""}

        if {$rduration eq ""} {
            set rduration [parmdb get ensit.$stype.duration]
        }


        # NEXT, Create the situation.  The start time is the 
        # time of the first assessment. In PREP, that will be t=0; while
        # PAUSED, it will be t+1, i.e., the next time tick; if created
        # by a tactic or by a scheduled order, it will be t, i.e., 
        # right now.

        if {[sim state] eq "PREP"} {
            set ts [simclock cget -tick0]
        } elseif {[sim state] eq "PAUSED"} {
            set ts [simclock now 1]
        } else {
            set ts [simclock now]
        }

        if {$rduration ne ""} {
            let tr {$ts + $rduration}
        } else {
            set tr ""
        }

        rdb eval {
            INSERT INTO 
            ensits(stype, location, n, coverage, inception, 
                   state, ts, resolver, rduration, tr)
            VALUES($stype, $location, $n, $coverage, $inception,
                   'INITIAL', $ts, $resolver, $rduration,
                   nullif($tr,''))
        }

        set s [rdb last_insert_rowid]

        # NEXT, inform all clients about the new object.
        log detail ensit "$s: created for $n,$stype,$coverage"

        # NEXT, Return the undo command
        return [mytypemethod mutate delete $s]
    }

    # mutate delete s
    #
    # s     A situation ID
    #
    # Deletes the situation.  This should be done only if the
    # situation is in the INITIAL state.

    typemethod {mutate delete} {s} {
        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab ensits {s=$s}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of entity parms
    #
    #    s           - The situation ID
    #    stype       - A new situation type, or ""
    #    location    - A new location (map coords), or ""
    #                  (Must be in same neighborhood.)
    #    coverage    - A new coverage, or ""
    #    inception   - A new inception, or ""
    #    resolver    - A new resolving group, or ""
    #    rduration   - A new auto-resolution duration, or ""
    #
    # Updates a situation given the parms, which are presumed to be
    # valid.
    #
    # Only the "location" parameter can be updated if the state isn't
    # INITIAL.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {}

        # FIRST, get the undo information
        set data [rdb grab ensits {s=$s}]

        # NEXT, get the new neighborhood if the location changed.
        if {$location ne ""} { 
            set n [nbhood find {*}$location]
        } else {
            set n ""
        }

        if {$rduration ne ""} {
            set ts [$type get $s ts]
            let tr {$ts + $rduration}
        } else {
            set tr ""
        }

        # NEXT, update the situation
        rdb eval {
            UPDATE ensits
            SET stype     = nonempty($stype,     stype),
                location  = nonempty($location,  location),
                n         = nonempty($n,         n),
                coverage  = nonempty($coverage,  coverage),
                inception = nonempty($inception, inception),
                resolver  = nonempty($resolver,  resolver),
                rduration = nonempty($rduration, rduration),
                tr        = nonempty($tr,        tr)
            WHERE s=$s;
        }

        # NEXT, Return the undo command
        return [list rdb ungrab $data] 
    }


    # mutate resolve parmdict
    #
    # parmdict     A dictionary of order parms
    #
    #    s         - The situation ID
    #    resolver  - Group responsible for resolving the situation, or "NONE"
    #                or "".
    #
    # Resolves the situation, assigning credit where credit is due.

    typemethod {mutate resolve} {parmdict} {
        dict with parmdict {}

        # FIRST, get the undo information
        set data [rdb grab ensits {s=$s}]

        # NEXT, update the situation
        rdb eval {
            UPDATE ensits
            SET state     = 'RESOLVED',
                resolver  = nonempty($resolver, resolver),
                tr        = now(),
                rduration = now() - ts
            WHERE s=$s;
        }

        # NEXT, Return the undo script
        return [list rdb ungrab $data] 
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # AbsentTypes location
    #
    # location  - A map location
    #
    # Returns a list of the ensit types that are not represented in 
    # the neighborhood containing the given location.

    typemethod AbsentTypes {location} {
        if {$location ne "" && 
            ![catch {
                set mxy [map ref2m $location]
                set n [nbhood find {*}$mxy]
            }]
        } {
            return [$type absentFromNbhood $n]
        }

        return [list]
    }

    # AbsentTypesBySit s
    #
    # s  - A situation ID
    #
    # Returns a list of the ensit types that are not represented in 
    # the neighborhood containing the situation, plus the situation's
    # own type.

    typemethod AbsentTypesBySit {s} {
        if {$s ne ""} {
            set n [ensit get $s n]

            set stypes [$type absentFromNbhood $n]
            lappend stypes [ensit get $s stype]

            return [lsort $stypes]
        }

        return [list]
    }
}

#-------------------------------------------------------------------
# Orders

# ENSIT:CREATE
#
# Creates new ensits.

order define ENSIT:CREATE {
    title "Create Environmental Situation"
    options -sendstates {PREP PAUSED TACTIC}

    form {
        rcc "Location:" -for location
        text location

        rcc "Type:" -for stype
        enum stype -listcmd {ensit AbsentTypes $location}

        rcc "Coverage:" -for coverage
        frac coverage -defvalue 1.0

        rcc "Inception?" -for inception
        yesno inception -defvalue 1

        rcc "Resolver:" -for resolver
        enum resolver -listcmd {ptype g+none names} -defvalue NONE

        rcc "Duration:" -for duration
        text rduration -defvalue 1
        label "weeks"
    }

    parmtags location nbpoint
} {
    # FIRST, prepare and validate the parameters
    prepare location  -toupper   -required -type refpoint
    prepare stype     -toupper   -required -type eensit
    prepare coverage  -num       -required -type rfraction
    prepare inception -toupper   -required -type boolean
    prepare resolver  -toupper   -required -type {ptype g+none}
    prepare rduration -num                 -type iticks

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
    lappend undo [ensit mutate create [array get parms]]
    
    setundo [join $undo \n]
}


# ENSIT:DELETE
#
# Deletes an ensit.

order define ENSIT:DELETE {
    title "Delete Environmental Situation"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Situation:" -for s
        key s -table gui_ensits_initial -keys s -dispcols longid
    }

    parmtags s situation
} {
    # FIRST, prepare the parameters
    prepare s -required -type {ensit initial}

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     ENSIT:DELETE   \
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
    lappend undo [ensit mutate delete $parms(s)]
    
    setundo [join $undo \n]
}


# ENSIT:UPDATE
#
# Updates existing ensits.

order define ENSIT:UPDATE {
    title "Update Environmental Situation"
    options -sendstates {PREP PAUSED TACTIC} 

    form {
        rcc "Situation:" -for s
        key s -table gui_ensits_initial -keys s -dispcols longid \
            -loadcmd {orderdialog keyload s *}

        rcc "Location:" -for location
        text location

        rcc "Type:" -for stype
        enum stype -listcmd {ensit AbsentTypesBySit $s}

        rcc "Coverage:" -for coverage
        frac coverage

        rcc "Inception?" -for inception
        yesno inception

        rcc "Resolver:" -for resolver
        enum resolver -listcmd {ptype g+none names}

        rcc "Duration:" -for duration
        text rduration
        label "weeks"
    }

    parmtags s situation
    parmtags location nbpoint
} {
    # FIRST, check the situation
    prepare s                    -required -type {ensit initial}

    returnOnError

    set stype [ensit get $parms(s) stype]

    # NEXT, prepare the remaining parameters
    prepare location  -toupper  -type refpoint 
    prepare stype     -toupper  -type eensit -oldvalue $stype
    prepare coverage  -num      -type rfraction
    prepare inception -toupper  -type boolean
    prepare resolver  -toupper  -type {ptype g+none}
    prepare rduration -num      -type iticks

    returnOnError

    # NEXT, get the old neighborhood
    set n [ensit get $parms(s) n]

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
    setundo [ensit mutate update [array get parms]]
}


# ENSIT:MOVE
#
# Moves an existing ensit.

order define ENSIT:MOVE {
    title "Move Environmental Situation"
    options \
        -sendstates {PREP PAUSED}

    form {
        rcc "Situation:" -for s
        key s -table gui_ensits -keys s -dispcols longid

        rcc "Location:" -for location
        text location
    }

    parmtags s situation
    parmtags location nbpoint
} {
    # FIRST, check the situation
    prepare s                    -required -type ensit

    returnOnError

    # NEXT, prepare the remaining parameters
    prepare location  -toupper  -required -type refpoint 

    returnOnError

    # NEXT, validate the other parameters.  In the INITIAL state, the
    # ensit can be moved to any neighborhood; in any other state it
    # can only be moved within the neighborhood.
    # location can be changed.

    if {[ensit get $parms(s) state] eq "INITIAL"} {
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

            if {$n ne [ensit get $parms(s) n]} {
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
        resolver  ""
        rduration ""
    }

    # NEXT, modify the group
    setundo [ensit mutate update [array get parms]]
}


# ENSIT:RESOLVE
#
# Resolves an ensit.

order define ENSIT:RESOLVE {
    title "Resolve Environmental Situation"
    options -sendstates {PREP PAUSED TACTIC}

    form {
        rcc "Situation:" -for s
        key s -table gui_ensits -keys s -dispcols longid \
            -loadcmd {orderdialog keyload s *}

        rcc "Resolved By:" -for resolver
        enum resolver -listcmd {ptype g+none names}
    }

    parmtags s situation
} {
    # FIRST, prepare the parameters
    prepare s         -required -type {ensit live}
    prepare resolver  -toupper  -type {ptype g+none}

    returnOnError -final

    # NEXT, resolve the situation.
    lappend undo [ensit mutate resolve [array get parms]]
    
    setundo [join $undo \n]
}





