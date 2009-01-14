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
    
    # info -- array of scalars
    #
    # undo       Command to undo the last operation, or ""

    typevariable info -array {
        undo {}
    }

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail nbgroup "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module data from the database.
    
    typemethod reconfigure {} {
        # Clear the undo command
        set info(undo) {}
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


    #-------------------------------------------------------------------
    # Order Handling Routines

    # LastUndo
    #
    # Returns the undo command for the last mutator, or "" if none.

    typemethod LastUndo {} {
        set undo $info(undo)
        unset info(undo)

        return $undo
    }

    # CreateGroup parmdict
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

    typemethod CreateGroup {parmdict} {
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

            # NEXT, Set the undo command
            set info(undo) [list $type DeleteGroup $n $g]
            
            # NEXT, notify the app.
            notifier send ::nbgroup <Entity> create $n $g
        }
    }

    # DeleteGroup n g
    #
    # n g     An nbgroup ID
    #
    # Deletes the group, including all references.

    typemethod DeleteGroup {n g} {
        # FIRST, delete it.
        rdb eval {
            DELETE FROM nbgroups WHERE n=$n AND g=$g;
        }

        # NEXT, Clean up entities which refer to this nbhood group,
        # i.e., either clear the field, or delete the entities.
        
        # TBD.

        # NEXT, Not undoable; clear the undo command
        set info(undo) {}

        notifier send ::nbgroup <Entity> delete $n $g
    }


    # UpdateGroup parmdict
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

    typemethod UpdateGroup {parmdict} {
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

            # NEXT, Set the undo command
            set info(undo) [mytypemethod UpdateGroup [array get undoData]]

            # NEXT, notify the app.
            notifier send ::nbgroup <Entity> update $n $g
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
    prepare n              -trim -toupper -required -type nbhood
    prepare g              -trim -toupper -required -type civgroup
    prepare local_name     -normalize
    prepare demeanor       -trim -toupper -required -type edemeanor
    prepare rollup_weight  -trim          -required -type weight
    prepare effects_factor -trim          -required -type weight

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
    $type CreateGroup [array get parms]

    setundo [$type LastUndo]
}

# GROUP:NBHOOD:DELETE

order define ::nbgroup GROUP:NBHOOD:DELETE {
    title "Delete Nbhood Group"
    parms {
        n {ptype nbhood   label "Neighborhood" }
        g {ptype civgroup label "Civ Group"    }
    }
} {
    # FIRST, prepare the parameters
    prepare n -trim -toupper -required -type nbhood
    prepare g -trim -toupper -required -type civgroup

    returnOnError

    # NEXT, do cross-validation
    if {![$type exists $parms(n) $parms(g)]} {
        reject g "This group does not reside in this neighborhood"
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
                            This order cannot be undone.  Are you sure 
                            you really want to delete this neighborhood 
                            group and all data that depends on it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, raise the group
    $type DeleteGroup $parms(n) $parms(g)

    # NEXT, this order is not undoable.
}


# GROUP:NBHOOD:UPDATE
#
# Updates existing groups.

order define ::nbgroup GROUP:NBHOOD:UPDATE {
    title "Update Nbhood Group"
    table gui_nbgroups
    keys  {n g}
    parms {
        n              {ptype nbhood    label "Neighborhood"  }
        g              {ptype civgroup  label "Civ Group"     }
        local_name     {ptype text      label "Local Name"    }
        demeanor       {ptype demeanor  label "Demeanor"      }
        rollup_weight  {ptype weight    label "RollupWeight"  }
        effects_factor {ptype weight    label "EffectsFactor" }
    }
} {
    # FIRST, prepare the parameters
    prepare n              -trim -toupper  -required -type nbhood
    prepare g              -trim -toupper  -required -type civgroup
    prepare local_name     -normalize      
    prepare demeanor       -trim -toupper  -type edemeanor
    prepare rollup_weight  -trim           -type weight
    prepare effects_factor -trim           -type weight

    returnOnError

    # NEXT, do cross-validation
    if {![$type exists $parms(n) $parms(g)]} {
        reject g "This group does not reside in this neighborhood"
    }

    returnOnError

    # NEXT, modify the group
    $type UpdateGroup [array get parms]

    setundo [$type LastUndo]
}

