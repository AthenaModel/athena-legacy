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
                INSERT INTO nbgroups(n,g,local_name,demeanor,
                                     rollup_weight,effects_factor)
                VALUES($n,
                       $g,
                       $local_name,
                       $demeanor,
                       $rollup_weight,
                       $effects_factor);
            }

            # NEXT, population the sat_ngc table with satisfaction
            # levels
            sat mutate nbgroupCreated $n $g

            # NEXT, notify the app.
            notifier send ::nbgroup <Entity> create $n $g

            # NEXT, finish the undo script
            lappend undo [mytypemethod mutate delete $n $g]

            # NEXT, Return the undo command
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
        rdb eval {
            SELECT * FROM nbgroups
            WHERE n=$n AND g=$g
        } undoData {
            unset undoData(*)
            lappend undo [mytypemethod mutate create [array get undoData]]
        }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM nbgroups WHERE n=$n AND g=$g;
        }

        # NEXT, Clean up entities which refer to this nbhood group,
        # i.e., either clear the field, or delete the entities.
        
        lappend undo [sat mutate nbgroupDeleted $n $g]

        # NEXT, notify the app.
        notifier send ::nbgroup <Entity> delete $n $g

        # NEXT, Return the undo script
        return [join $undo \n]
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID of nbgroup
    #    g                Group ID of nbgroup
    #    local_name       A new local name, or ""
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
                    demeanor       = nonempty($demeanor,       demeanor),
                    rollup_weight  = nonempty($rollup_weight,  rollup_weight),
                    effects_factor = nonempty($effects_factor, effects_factor)
                WHERE n=$n AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::nbgroup <Entity> update $n $g

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

    # mutate nbhoodDeleted n
    #
    # Called *by* nbhood when nbhood n is deleted.  Deletes all 
    # nbgroups for this nbhood.

    typemethod {mutate nbhoodDeleted} {n} {
        set undo [list]

        rdb eval {
            SELECT g FROM nbgroups WHERE n=$n
        } {
            lappend undo [$type mutate delete $n $g]
        }

        return [join $undo \n]
    }


    # mutate civgroupDeleted g
    #
    # Called *by* civgroup when civgroup g is deleted.  Deletes all 
    # nbgroups for this civgroup.

    typemethod {mutate civgroupDeleted} {g} {
        set undo [list]

        rdb eval {
            SELECT n FROM nbgroups WHERE g=$g
        } {
            lappend undo [$type mutate delete $n $g]
        }

        return [join $undo \n]
    }

}

#-------------------------------------------------------------------
# Orders: GROUP:NBHOOD:*

# GROUP:NBHOOD:CREATE
#
# Creates new nbhood groups.

order define ::nbgroup GROUP:NBHOOD:CREATE {
    title "Create Nbhood Group"
    parms {
        n              {ptype nbhood   label "Neighborhood"            }
        g              {ptype civgroup label "Civ Group"               }
        local_name     {ptype text     label "Local Name"              }
        demeanor       {ptype demeanor label "Demeanor"                }
        rollup_weight  {ptype weight   label "RollupWeight"  defval 1.0}
        effects_factor {ptype weight   label "EffectsFactor" defval 1.0}
    }
} {
    # FIRST, prepare and validate the parameters
    prepare n              -toupper -required -type nbhood
    prepare g              -toupper -required -type civgroup
    prepare local_name     -normalize
    prepare demeanor       -toupper -required -type edemeanor
    prepare rollup_weight           -required -type weight
    prepare effects_factor          -required -type weight

    returnOnError

    # NEXT, do cross-validation
    if {[$type exists $parms(n) $parms(g)]} {
        reject g "This group already resides in this neighborhood"
    }

    returnOnError

    # NEXT, if local_name is not given, use the group's long name
    if {$parms(local_name) eq ""} {
        set parms(local_name) [rdb onecolumn {
            SELECT longname FROM groups WHERE g=$parms(g)
        }]
    }

    # NEXT, create the group
    setundo [$type mutate create [array get parms]]
}

# GROUP:NBHOOD:DELETE

order define ::nbgroup GROUP:NBHOOD:DELETE {
    title "Delete Nbhood Group"
    table gui_nbgroups
    parms {
        n {ptype key label "Neighborhood" }
        g {ptype key label "Civ Group"    }
    }
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

    # NEXT, delete the group
    setundo [$type mutate delete $parms(n) $parms(g)]
}


# GROUP:NBHOOD:UPDATE
#
# Updates existing groups.

order define ::nbgroup GROUP:NBHOOD:UPDATE {
    title "Update Nbhood Group"
    table gui_nbgroups
    parms {
        n              {ptype key       label "Neighborhood"  }
        g              {ptype key       label "Civ Group"     }
        local_name     {ptype text      label "Local Name"    }
        demeanor       {ptype demeanor  label "Demeanor"      }
        rollup_weight  {ptype weight    label "RollupWeight"  }
        effects_factor {ptype weight    label "EffectsFactor" }
    }
} {
    # FIRST, prepare the parameters
    prepare n              -toupper  -required -type nbhood
    prepare g              -toupper  -required -type civgroup
    prepare local_name     -normalize      
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
}


# GROUP:NBHOOD:UPDATE:MULTI
#
# Updates multiple groups.

order define ::nbgroup GROUP:NBHOOD:UPDATE:MULTI {
    title "Update Multiple Nbhood Groups"
    multi yes
    table gui_nbgroups
    parms {
        ids            {ptype ids       label "Groups"  }
        local_name     {ptype text      label "Local Name"    }
        demeanor       {ptype demeanor  label "Demeanor"      }
        rollup_weight  {ptype weight    label "RollupWeight"  }
        effects_factor {ptype weight    label "EffectsFactor" }
    }
} {
    # FIRST, prepare the parameters
    prepare ids            -toupper  -required -listof nbgroup
    prepare local_name     -normalize      
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
}
