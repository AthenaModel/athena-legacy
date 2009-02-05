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

    # mutate autopop
    #
    # Determines which relationships should exist, and 
    # adds or deletes them, returning an undo script.

    typemethod {mutate autopop} {} {
        # FIRST, List required relationships
        set valid [dict create]

        rdb eval {
            -- Force/Org vs. Force/Org
            SELECT 'PLAYBOX' AS n, 
                   F.g       AS f, 
                   G.g       AS g
            FROM groups AS F
            JOIN groups AS G
            WHERE F.gtype IN ('FRC', 'ORG')
            AND   G.gtype IN ('FRC', 'ORG')

            UNION

            -- Nbgroup with all other groups
            SELECT nbgroups.n AS n, 
                   groups.g   AS f, 
                   nbgroups.g AS g
            FROM nbgroups JOIN groups
        } {
            # Some of these will be set more often than is necessary,
            # but that's OK.
            dict set valid [list $n $f $g] 0
            dict set valid [list $n $g $f] 0
        }

        # NEXT, Begin the undo script.  Any undo will begin by 
        # calling this routine to create or delete relationships; then,
        # if relationships were restored, there will be additional entries
        # in the script to restore the old data values.

        lappend undo [mytypemethod mutate autopop]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM rel_nfg
        } row {
            unset -nocomplain row(*)

            set id [list $row(n) $row(f) $row(g)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod mutate update [array get row]]

                rdb eval {
                    DELETE FROM rel_nfg
                    WHERE n=$row(n) AND f=$row(f) AND g=$row(g)
                }

                notifier send ::rel <Entity> delete $id
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id n f g

            if {$f eq $g} {
                # Every group has a relationship of 1.0 with itself.
                rdb eval {
                    INSERT INTO rel_nfg(n,f,g,rel)
                    VALUES($n,$f,$g,1.0)
                }

            } else {
                # Otherwise, we get the default relationship.
                rdb eval {
                    INSERT INTO rel_nfg(n,f,g)
                    VALUES($n,$f,$g)
                }
            }

            notifier send ::rel <Entity> create $id
        }

        # NEXT, return the undo script
        return [join $undo \n]
    }

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
            notifier send ::rel <Entity> update [list $n $f $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}

