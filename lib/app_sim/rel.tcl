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

    # fg validate id
    #
    # id     An fg relationship ID, [list $f $g]
    #
    # Throws INVALID if there's no relationship for the 
    # specified combination.

    typemethod {fg validate} {id} {
        lassign $id f g

        # TBD: What should be validated here?
        set f [groups validate $f]
        set g [groups validate $g]

        if {![$type fg exists $f $g]} {
            return -code error -errorcode INVALID \
                "Relationship is not tracked for groups $f and $g."
        }

        return [list $f $g]
    }

    # fg exists f g
    #
    # f       A group ID
    # g       A group ID
    #
    # Returns 1 if relationship is tracked between f and g.

    typemethod exists {f g} {
        rdb exists {
            SELECT * FROM rel_fg WHERE f=$f AND g=$g
        }
    }

    # nfg validate id
    #
    # id     An nfg relationship ID, [list $n $f $g]
    #
    # Throws INVALID if there's no relationship for the 
    # specified combination.

    typemethod {nfg validate} {id} {
        lassign $id n f g

        # TBD: What should be validated here?
        set n [nbhood validate $n]
        set f [groups validate $f]
        set g [groups validate $g]

        if {![$type nfg exists $n $f $g]} {
            return -code error -errorcode INVALID \
               "Relationship is not tracked for groups $f and $g in nbhood $n."
        }

        return [list $n $f $g]
    }

    # nfg exists n f g
    #
    # n       A nbhood ID
    # f       A group ID
    # g       A group ID
    #
    # Returns 1 if relationship is tracked between f and g in n.

    typemethod exists {n f g} {
        rdb exists {
            SELECT * FROM rel_nfg WHERE n=$n f=$f AND g=$g
        }
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate fogroupCreated g
    #
    # g    Name of a force or organization group
    #
    # Create relationships f,g for all frc/org groups f
    # Create relationships g,f for all frc/org groups f, f !=g
    # Create relationships nfg for all nbgroups nf
    # Create relationships ngf for all nbgroups nf

    typemethod {mutate fogroupCreated} {g} {
        
    }

    # mutate fogroupDeleted g
    #
    # g    Name of a force or organization group
    #
    # Delete all relationships created by fogroupCreated
    
    # mutate nbgroupCreated n g
    #
    # n    Name of nbhood
    # g    Name of civ group
    #
    # Create relationships nfg for all frc/org groups f
    # Create relationships ngf for all frc/org groups f
    #
    # If this is the first nbgroup in n,
    #   Create relationships nfg for all civ groups f and g.

    # mutate nbgroupDeleted n g
    #
    # n    Name of nbhood
    # g    Name of civ group
    #
    # Delete relationships nfg for all frc/org groups f
    # Delete relationships ngf for all frc/org groups f
    #
    # If this is the last nbgroup in n,
    #   Delete relationships nfg for all civ groups f and g in n.

}

