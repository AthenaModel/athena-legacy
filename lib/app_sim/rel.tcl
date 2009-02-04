#-----------------------------------------------------------------------
# TITLE:
#    rel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Relationship Manager
#
#    This module is responsible for managing relationships between
#    groups as groups come and ago, and for allowing the analyst
#    to update particular relationships.
#
#    Every frc and org group has a bidirectional relationship with 
#    every other frc and org group; these are stored in the rel_fg
#    table.
#
#    Every frc and org group has a bidirectional relationship with
#    every neighborhood group; these are stored in the rel_nfg table.
#
#    Every civ group has a relationship with every other civ group
#    in every neighborhood.
#   
#
#-----------------------------------------------------------------------

snit::type rel {
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
        log detail rel "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module's in-memory data from the database.
    
    typemethod reconfigure {} {
        # Nothing to do
    }

    #-------------------------------------------------------------------
    # Queries

    # nfg validate id
    #
    # id     An nfg relationship ID, [list $n $f $g]
    #
    # Throws INVALID if there's no relationship for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id n f g

        if {$n ne "PLAYBOX"} {
            set n [nbhood validate $n]
        }

        set f [groups validate $f]
        set g [groups validate $g]

        if {![$type exists $n $f $g]} {
            return -code error -errorcode INVALID \
               "Relationship is not tracked for groups $f and $g in $n."
        }

        return [list $n $f $g]
    }

    # exists n f g
    #
    # n       A nbhood ID, or PLAYBOX
    # f       A group ID
    # g       A group ID
    #
    # Returns 1 if relationship is tracked between f and g in n.

    typemethod exists {n f g} {
        rdb exists {
            SELECT * FROM rel_nfg WHERE n=$n AND f=$f AND g=$g
        }
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID
    #    f                Group ID
    #    g                Group ID
    #    rel              Relationship of f with g in n.
    #
    # Updates a relationship given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM rel_nfg
                WHERE n=$n AND f=$f AND g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE rel_nfg
                SET rel = nonempty($rel, rel)
                WHERE n=$n AND f=$f AND g=$g
            } {}

            # NEXT, notify the app.
            $type SendEntity update [list [list $n $g $c]]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

    # mutate frcgroupCreated g
    #
    # g    Name of a force group
    #
    # A force group has been created.  Create relevant relationships.

    typemethod {mutate frcgroupCreated} {g} {
        $type FrcOrgGroupCreated $g
    }

    # mutate frcgroupDeleted g
    #
    # g    Name of a force group
    #
    # Delete all relationships created by frcgroupCreated

    typemethod {mutate frcgroupDeleted} {g} {
        $type GroupDeleted $g
    }
    

    # mutate orggroupCreated g
    #
    # g    Name of an organization group
    #
    # An org group has been created.  Create relevant relationships.

    typemethod {mutate orggroupCreated} {g} {
        $type FrcOrgGroupCreated $g
    }

    # mutate orggroupDeleted g
    #
    # g    Name of a force or organization group
    #
    # Delete all relationships created by orggroupCreated

    typemethod {mutate orggroupDeleted} {g} {
        $type GroupDeleted $g
    }

    
    # mutate civgroupCreated g
    #
    # g    Name of a civilian group
    #
    # A civ group has been created.  Create relationships
    # in each neighborhood with each existing nbgroup.

    typemethod {mutate civgroupCreated} {g} {
        # FIRST, create a list of the new relationships
        set ids [list]

        # NEXT, add relationships with each nbgroup.

        rdb eval {
            SELECT n AS n,
                   g AS f
            FROM nbgroups
        } {
            lappend ids [list $n $f $g] [list $n $g $f]
        }

        # NEXT, create the relationships
        $type MakeRelationships $ids

        # NEXT, notify the app
        $type SendEntity create $ids

        # Note: No undo script is required; undoing a group creation
        # requires a group deletion, which will call this routine
        # explicitly
        return
    }

    # mutate civgroupDeleted g
    #
    # g    Name of a civilian group
    #
    # Delete all relationships created by civgroupCreated

    typemethod {mutate civgroupDeleted} {g} {
        $type GroupDeleted $g
    }
    
    # mutate nbgroupCreated n g
    #
    # n    Name of nbhood
    # g    Name of civ group
    #
    # Create relationship ngg with self
    # Create relationships nfg and ngf for all frc/org groups f
    # Create relationships nfg and ngf with all civ groups f, provided
    #    that they don't already exist.

    typemethod {mutate nbgroupCreated} {n g} {
        # FIRST, create a list of the new relationships
        set ids [list]

        # NEXT, add relationship with self: 1.0
        lappend ids [list $n $g $g]

        # NEXT, get a list of groups with which g already has
        # relationships in n
        set existing [rdb eval {
            SELECT f FROM rel_nfg WHERE n=$n AND g=$g
        }]

        # NEXT, create relationships between g and all other groups
        # except those in $existing
        rdb eval {
            SELECT g AS f FROM groups
        } {
            # Skip existing relationships
            if {$g IN $existing} {
                continue
            }

            lappend ids [list $n $f $g] [list $n $g $f]
        }

        # NEXT, create the relationships
        $type MakeRelationships $ids

        # NEXT, notify the app
        $type SendEntity create $ids

        # Note: No undo script is required; undoing a group creation
        # requires a group deletion, which will call this routine
        # explicitly
        return
    }


    # mutate nbgroupDeleted n g
    #
    # n    Name of nbhood
    # g    Name of civ group
    #
    # Delete all relationships nfg and ngf where nf is NOT a 
    # nbgroup.  Create an undo script to restore the deleted
    # values.

    typemethod {mutate nbgroupDeleted} {n g} {
        # FIRST, get a list of the groups (other than g) that
        # are still resident in n.

        set existing [rdb eval {
            SELECT g AS f
            FROM nbgroups
            WHERE n=$n AND f != $g
        }]

        # NEXT, get the undo information: updates to restore any
        # non-default values.
        set undo [list]
        set ids [list]

        rdb eval {
            SELECT * FROM rel_nfg
            WHERE n=$n AND (f=$g OR g=$g)
        } row {
            if {$row(f) IN $existing ||
                $row(g) IN $existing} {
                continue
            }

            unset -nocomplain row(*)
            lappend ids [list $row(n) $row(f) $row(g)]
            lappend undo [mytypemethod mutate update [array get row]]

            rdb eval {
                DELETE FROM rel_nfg
                WHERE n=$row(n) AND f=$row(f) AND g=$row(g)
            }
        }

        # NEXT, notify the app.
        $type SendEntity delete $ids
        
        # NEXT, Return the undo script
        return [join $undo \n]
    }

    # FrcOrgGroupCreated g
    #
    # g    Name of a force or organization group
    #
    # Create relationships with other groups.

    typemethod FrcOrgGroupCreated {g} {
        # FIRST, create a list of the new relationships
        set ids [list]

        # NEXT, add playbox-wide relationships with other groups.
        set n PLAYBOX

        # With self: 1.0
        lappend ids [list $n $g $g]

        # With other groups
        rdb eval {
            -- Force and ORG groups
            SELECT 'PLAYBOX' AS n,
                   g         AS f
            FROM groups WHERE gtype IN ('FRC', 'ORG') AND g != $g

            UNION

            -- Nbhood groups
            SELECT n AS n,
                   g AS f
            FROM nbgroups
        } {
            lappend ids [list $n $f $g] [list $n $g $f]
        }

        # NEXT, create the relationships
        $type MakeRelationships $ids

        # NEXT, notify the app
        $type SendEntity create $ids

        # Note: No undo script is required; undoing a group creation
        # requires a group deletion, which will call this routine
        # explicitly
        return
    }

    # GroupDeleted g
    #
    # g    Name of any group
    #
    # Delete all relationships involving this group,
    # and prepare an undo script to restore deleted values.

    typemethod GroupDeleted {g} {
        # FIRST, get the undo information: updates to restore any
        # non-default values.
        set undo [list]
        set ids [list]

        rdb eval {
            SELECT * FROM rel_nfg
            WHERE f=$g OR g=$g
        } row {
            unset -nocomplain row(*)
            lappend ids [list $row(n) $row(f) $row(g)]
            lappend undo [mytypemethod mutate update [array get row]]
        }

        # NEXT, Delete the relationships
        rdb eval {
            DELETE FROM rel_nfg
            WHERE f=$g OR g=$g;
        } {}

        # NEXT, notify the app.
        $type SendEntity delete $ids
        
        # NEXT, Return the undo script
        return [join $undo \n]
    }

    # MakeRelationships ids
    #
    # ids     List of ids {n f g} for which relationships are needed.
    #
    # Inserts default relationship entities into the database.
    # It's assumed that none of the relationships exist.

    typemethod MakeRelationships {ids} {
        foreach id $ids {
            lassign $id n f g

            if {$f eq $g} {
                # Relationship with self is always 1.0
                rdb eval {
                    INSERT INTO rel_nfg(n,f,g,rel)
                    VALUES($n,$g,$g,1.0)
                }
            } else {
                # Accept default rel.
                rdb eval {
                    INSERT INTO rel_nfg(n,f,g)
                    VALUES($n,$f,$g);
                }
            }
        }
    }

    # SendEntity op ids
    #
    # op     create, delete, or update
    # ids    List of ids {n f g}
    #
    # Sends the <Entity> events for a set of relationships

    typemethod SendEntity {op ids} {
        foreach id $ids {
            notifier send ::rel <Entity> $op $id
        }
    }
}

