#-----------------------------------------------------------------------
# TITLE:
#    nbrel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Neighborhood Relationship Manager
#
#    This module is responsible for managing relationships between
#    neighborhoods (proximity and effects delay), and for allowing the 
#    analyst to update particular neighborhood relationships.
#    These relationships come and go as neighborhoods come and go.
#
#-----------------------------------------------------------------------

snit::type nbrel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # TBD

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail nbrel "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module's in-memory data from the database.
    
    typemethod reconfigure {} {
        # Nothing to do
    }

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An mn neighborhood relationship ID, [list $n $f $g]
    #
    # Throws INVALID if there's no neighborhood relationship for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id m n

        set m [nbhood validate $m]
        set n [nbhood validate $n]

        # No need to check for existence of the record in nbrel_mn; 
        # there are relationships for every pair of neighborhoods.

        return [list $m $n]
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
    # Determines which neighborhood relationships should exist, and 
    # adds or deletes them, returning an undo script.

    typemethod {mutate reconcile} {} {
        # FIRST, List required neighborhood relationships
        set valid [dict create]

        rdb eval {
            -- Nbgroup with force groups
            SELECT M.n   AS m, 
                   N.n   AS n
            FROM nbhoods AS M JOIN nbhoods AS N
        } {
            dict set valid [list $m $n] 0
        }

        # NEXT, Begin the undo script.
        set undo [list]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM nbrel_mn
        } row {
            unset -nocomplain row(*)

            set id [list $row(m) $row(n)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod Restore [array get row]]

                rdb eval {
                    DELETE FROM nbrel_mn
                    WHERE m=$row(m) AND n=$row(n)
                }

                notifier send ::nbrel <Entity> delete $id
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id m n

            if {$m eq $n} {
                # A neighborhood is always "HERE" to itself.
                rdb eval {
                    INSERT INTO nbrel_mn(m,n,proximity)
                    VALUES($m,$n,'HERE')
                }
            } else {
                rdb eval {
                    INSERT INTO nbrel_mn(m,n)
                    VALUES($m,$n)
                }
            }

            lappend undo [mytypemethod Delete $m $n]

            notifier send ::nbrel <Entity> create $id
        }

        # NEXT, return the undo script
        return [join $undo \n]
    }


    # Restore parmdict
    #
    # parmdict     row dict for deleted entity
    #
    # Restores the entity in the database

    typemethod Restore {parmdict} {
        rdb insert nbrel_mn $parmdict
        dict with parmdict {
            notifier send ::nbrel <Entity> create [list $m $n]
        }
    }


    # Delete m n
    #
    # m,n    The indices of the entity
    #
    # Deletes the entity.  Used only in undo scripts.
    
    typemethod Delete {m n} {
        rdb eval {
            DELETE FROM nbrel_mn WHERE m=$m AND n=$n
        }

        notifier send ::nbrel <Entity> delete [list $m $n]
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    m                Neighborhood ID
    #    n                Neighborhood ID
    #    proximity        Proximity of m to n from m's point of view
    #    effects_delay    Delay in days for effects to reach m from n
    #
    # Updates a neighborhood relationship given the parms, which are 
    # presumed to be valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM nbrel_mn
                WHERE m=$m AND n=$n
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE nbrel_mn
                SET proximity     = nonempty($proximity,     proximity),
                    effects_delay = nonempty($effects_delay, effects_delay)
                WHERE m=$m AND n=$n
            } {}

            # NEXT, notify the app.
            notifier send ::nbrel <Entity> update [list $m $n]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}


#-------------------------------------------------------------------
# Orders: NBHOOD:RELATIONSHIP:*

# NBHOOD:RELATIONSHIP:UPDATE
#
# Updates existing neighborhood relationships


order define ::nbrel NBHOOD:RELATIONSHIP:UPDATE {
        m             {ptype key        label "Of Neighborhood"      }
        n             {ptype key        label "With Neighborhood"    }
        proximity     {ptype proximity  label "Proximity"            }
        effects_delay {ptype days       label "Effects Delay (Days)" }
} {
    # FIRST, prepare the parameters
    prepare m             -toupper  -required -type nbhood
    prepare n             -toupper  -required -type nbhood
    prepare proximity     -toupper            -type eproximity
    prepare effects_delay -toupper            -type rdays

    returnOnError

    # NEXT, can't change HERE for a neighborhood with itself
    if {[valid proximity]} {
        if {$parms(m) eq $parms(n) && $parms(proximity) ne "HERE"} { 
            reject proximity "Proximity of $parms(m) to itself must be HERE"
        } elseif {$parms(m) ne $parms(n) && $parms(proximity) eq "HERE"} { 
            reject proximity \
                "Proximity of $parms(m) to $parms(n) cannot be HERE"
        }
    }

    returnOnError

    # NEXT, modify the curve
    setundo [$type mutate update [array get parms]]
}


# NBHOOD:RELATIONSHIP:UPDATE:MULTI
#
# Updates multiple existing neighborhood relationships

order define ::nbrel NBHOOD:RELATIONSHIP:UPDATE:MULTI {
        ids           {ptype ids        label "IDs"                  }
        proximity     {ptype proximity  label "Proximity"            }
        effects_delay {ptype days       label "Effects Delay (Days)" }
} {
    # FIRST, prepare the parameters
    prepare ids           -toupper  -required -listof nbrel
    prepare proximity     -toupper            -type eproximity
    prepare effects_delay -toupper            -type rdays

    returnOnError

    # NEXT, make sure that we're not changing the proximity
    if {[valid proximity]} {
        foreach id $parms(ids) {
            lassign $id parms(m) parms(n)
            
            if {$parms(m) eq $parms(n) && $parms(proximity) ne "HERE"} {
                reject proximity \
           "Proximity cannot be HERE for these neighborhoods."
                break
            } elseif {$parms(m) ne $parms(n) && $parms(proximity) eq "HERE"} {
                reject proximity \
           "Proximity cannot be $parms(proximity) for these neighborhoods."
                break
            }
        }
    }

    returnOnError

    # NEXT, modify the curves
    set undo [list]

    foreach id $parms(ids) {
        lassign $id parms(m) parms(n)

        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}

