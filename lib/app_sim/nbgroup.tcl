#-----------------------------------------------------------------------
# TITLE:
#    nbgroup.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Nbhood Group Manager
#
#    This module is responsible for managing nbhood groups and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type nbgroup {
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
        log detail nbgroup "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module's in-memory data from the database.
    
    typemethod reconfigure {} {
        # Nothing to do
    }

    #-------------------------------------------------------------------
    # Queries

    # exists n g
    #
    # n       A neighborhood ID
    # g       A group ID
    #
    # Returns 1 if there is such an nbgroup, and 0 otherwise.

    typemethod exists {n g} {
        rdb exists {
            SELECT * FROM nbgroups WHERE n=$n AND g=$g
        }
    }

    # gIn n
    #
    # n      A neighborhood ID
    #
    # Returns a list of the civ groups that reside in this neighborhood.

    typemethod gIn {n} {
        rdb eval {
            SELECT g FROM nbgroups WHERE n=$n
            ORDER BY g
        }
    }

    # nFor g
    #
    # g    A CIV group ID
    #
    # Returns a list of the neighborhoods in which g resides.

    typemethod nFor {g} {
        rdb eval {
            SELECT n FROM nbgroups WHERE g=$g
            ORDER BY n
        }
    }


    # validate id
    #
    # id      A group ID, [list $n $g]
    #
    # Validates an nbgroup ID

    typemethod validate {id} {
        lassign $id n g

        set n [nbhood   validate $n]
        set g [civgroup validate $g]

        if {![$type exists $n $g]} { 
            return -code error -errorcode INVALID \
                "Group $g does not reside in neighborhood $n"
        }

        return [list $n $g]
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.


    # mutate create parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                The neighborhood ID
    #    g                The civgroup ID
    #    local_name       The nbgroup's local name
    #    population       The nbgroup's population
    #    demeanor         The nbgroup's demeanor (edemeanor(n))
    #    rollup_weight    The group's rollup weight (JRAM)
    #    effects_factor   The group's indirect effects factor (JRAM)
    #
    # Creates a nbhood group given the parms, which are presumed to be
    # valid.
    #
    # Creating a nbhood group requires adding entries to the nbgroups 
    # table.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO nbgroups(n,g,local_name,population,demeanor,
                                     rollup_weight,effects_factor)
                VALUES($n,
                       $g,
                       $local_name,
                       $population,
                       $demeanor,
                       $rollup_weight,
                       $effects_factor);

                -- All population is implicit, initially.
                INSERT INTO demog_ng(n,g,implicit,population) 
                VALUES($n,
                       $g,
                       $population,
                       $population);
            }

            # NEXT, notify the app.
            notifier send ::nbgroup <Entity> create [list $n $g]

            # NEXT, Return the undo command
            set undo [list]
            lappend undo [mytypemethod mutate delete $n $g]
            lappend undo [list ::demog analyze]

            return [join $undo \n]
        }
    }


    # mutate delete n g
    #
    # n g     An nbgroup ID
    #
    # Deletes the group, including all references.

    typemethod {mutate delete} {n g} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM nbgroups WHERE n=$n AND g=$g} row1 {
            unset row1(*)
        }

        rdb eval {SELECT * FROM demog_ng WHERE n=$n AND g=$g} row2 {
            unset row2(*)
        }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM nbgroups WHERE n=$n AND g=$g;
            DELETE FROM demog_ng WHERE n=$n AND g=$g;
        }

        # NEXT, notify the app.
        notifier send ::nbgroup <Entity> delete [list $n $g]

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row1] [array get row2]]
    }

    # Restore parmdict1 parmdict2
    #
    # parmdict1     row dict for deleted entity
    # parmdict2     row dict for deleted entity
    #
    # Restores the entity in the database

    typemethod Restore {parmdict1 parmdict2} {
        rdb insert nbgroups $parmdict1
        rdb insert demog_ng $parmdict2

        dict with parmdict1 {
            demog analyze
            notifier send ::nbgroup <Entity> create [list $n $g]
        }
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID of nbgroup
    #    g                Group ID of nbgroup
    #    local_name       A new local name, or ""
    #    population       A new population, or ""
    #    demeanor         A new demeanor, or ""
    #    rollup_weight    A new rollup weight, or ""
    #    effects_factor   A new effects factor, or ""
    #
    # Updates a nbgroup given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM nbgroups
                WHERE n=$n AND g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE nbgroups
                SET local_name     = nonempty($local_name,     local_name),
                    population     = nonempty($population,     population),
                    demeanor       = nonempty($demeanor,       demeanor),
                    rollup_weight  = nonempty($rollup_weight,  rollup_weight),
                    effects_factor = nonempty($effects_factor, effects_factor)
                WHERE n=$n AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::nbgroup <Entity> update [list $n $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

    # mutate reconcile
    #
    # Deletes nbgroups for which either the neighborhood or the
    # civilian group no longer exists.

    typemethod {mutate reconcile} {} {
        # FIRST, get the set of possible nbgroups
        set valid [dict create]

        rdb eval {
            SELECT n, g 
            FROM nbhoods 
            JOIN civgroups_view
        } {
            dict set valid [list $n $g] 0
        }

        # NEXT, delete the ones that are no longer valid, accumulating
        # an undo script.
        set undo [list]

        rdb eval {
            SELECT n,g FROM nbgroups
        } {
            if {![dict exists $valid [list $n $g]]} {
                lappend undo [$type mutate delete $n $g]
            }
        }

        return [join $undo \n]
    }

    #---------------------------------------------------------------
    # Order Helpers

    # RefreshCreateG field parmdict
    #
    # field     The enumfield for G:N:CREATE's g parameter
    # parmdict  The values of upstream parameters
    #
    # Sets the valid values to those for which no group exists.

    typemethod RefreshCreateG {field parmdict} {
        # FIRST, get the list of existing g's
        set n [dict get $parmdict n]

        set nbgs [rdb eval {SELECT g FROM nbgroups WHERE n=$n}]

        # NEXT, build a list of the missing civ groups
        set values [list]
        foreach g [civgroup names] {
            if {$g ni $nbgs} {
                lappend values $g
            }
        }

        # NEXT, update the field.
        if {[llength $values] > 0} {
            $field configure -values $values
        } else {
            $field configure -state disabled
        }

        if {[dict get $parmdict g] ni $values} {
            $field set ""
        }
            
    }


}

#-------------------------------------------------------------------
# Orders: GROUP:NBHOOD:*

# GROUP:NBHOOD:CREATE
#
# Creates new nbhood groups.

order define ::nbgroup GROUP:NBHOOD:CREATE {
    title "Create Nbhood Group"

    options -sendstates PREP

    parm n              enum "Neighborhood"   \
        -type ::nbhood -tags nbhood -refresh
    parm g              enum "Civ Group" \
        -tags group -refreshcmd [list ::nbgroup RefreshCreateG]
    parm local_name     text "Local Name"
    parm population     text "Population"
    parm demeanor       enum "Demeanor"       -type edemeanor
    parm rollup_weight  text "RollupWeight"   -defval 1.0
    parm effects_factor text "EffectsFactor"  -defval 1.0
} {
    # FIRST, prepare and validate the parameters
    prepare n              -toupper -required -type nbhood
    prepare g              -toupper -required -type civgroup
    prepare local_name     -normalize
    prepare population              -required -type ingpopulation
    prepare demeanor       -toupper -required -type edemeanor
    prepare rollup_weight           -required -type weight
    prepare effects_factor          -required -type weight

    returnOnError

    # NEXT, do cross-validation
    if {[$type exists $parms(n) $parms(g)]} {
        reject g "Group $parms(g) already resides in $parms(n)"
    }

    returnOnError

    # NEXT, if local_name is not given, use the group's long name
    if {$parms(local_name) eq ""} {
        set parms(local_name) [rdb onecolumn {
            SELECT longname FROM groups WHERE g=$parms(g)
        }]
    }

    # NEXT, create the group and dependent entities.
    lappend undo [$type mutate create [array get parms]]
    lappend undo [scenario mutate reconcile]
    demog analyze
    
    setundo [join $undo \n]
}

# GROUP:NBHOOD:DELETE

order define ::nbgroup GROUP:NBHOOD:DELETE {
    title "Delete Nbhood Group"
    options -sendstates PREP -table gui_nbgroups -tags ng

    parm n  key  "Neighborhood"  -tags nbhood
    parm g  key  "Civ Group"     -tags group
} {
    # FIRST, prepare the parameters
    prepare n -toupper -required -type nbhood
    prepare g -toupper -required -type civgroup

    returnOnError

    # NEXT, do cross-validation
    validate g {
        $type validate [list $parms(n) $parms(g)]
    }

    returnOnError

    # NEXT, Delete all entities that depend on this group, unless the
    # user says no.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     GROUP:NBHOOD:DELETE                    \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure 
                            you really want to delete this neighborhood 
                            group and all data that depends on it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, delete the group and dependent entities
    lappend undo [$type mutate delete $parms(n) $parms(g)]
    lappend undo [scenario mutate reconcile]
    demog analyze
    
    setundo [join $undo \n]
}


# GROUP:NBHOOD:UPDATE
#
# Updates existing groups.

order define ::nbgroup GROUP:NBHOOD:UPDATE {
    title "Update Nbhood Group"
    options -sendstates PREP -table gui_nbgroups -tags ng

    parm n              key  "Neighborhood"  -tags nbhood
    parm g              key  "Civ Group"     -tags group
    parm local_name     text "Local Name"
    parm population     text "Population"
    parm demeanor       enum "Demeanor"      -type edemeanor
    parm rollup_weight  text "RollupWeight"
    parm effects_factor text "EffectsFactor"
} {
    # FIRST, prepare the parameters
    prepare n              -toupper  -required -type nbhood
    prepare g              -toupper  -required -type civgroup
    prepare local_name     -normalize      
    prepare population               -type ingpopulation
    prepare demeanor       -toupper  -type edemeanor
    prepare rollup_weight            -type weight
    prepare effects_factor           -type weight

    returnOnError

    # NEXT, do cross-validation
    validate g {
        $type validate [list $parms(n) $parms(g)]
    }

    returnOnError

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
    demog analyze
}


# GROUP:NBHOOD:UPDATE:MULTI
#
# Updates multiple groups.

order define ::nbgroup GROUP:NBHOOD:UPDATE:MULTI {
    title "Update Multiple Nbhood Groups"
    options -sendstates PREP -table gui_nbgroups

    parm ids            multi "Groups"
    parm local_name     text  "Local Name"
    parm population     text  "Population"
    parm demeanor       enum  "Demeanor"       -type edemeanor
    parm rollup_weight  text  "RollupWeight"
    parm effects_factor text  "EffectsFactor"
} {
    # FIRST, prepare the parameters
    prepare ids            -toupper  -required -listof nbgroup
    prepare local_name     -normalize      
    prepare population               -type ingpopulation
    prepare demeanor       -toupper  -type edemeanor
    prepare rollup_weight            -type weight
    prepare effects_factor           -type weight

    returnOnError

    # NEXT, modify the group
    set undo [list]

    foreach id $parms(ids) {
        lassign $id parms(n) parms(g)
        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]

    demog analyze
}



