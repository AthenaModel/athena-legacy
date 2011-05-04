#-----------------------------------------------------------------------
# TITLE:
#    personnel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): FRC/ORG Group Personnel Manager
#
#    This module is responsible for managing personnel of FRC and ORG
#    groups in neighborhoods.
#
# CREATION/DELETION:
#    deploy_ng records are created explicitly by the 
#    nbhood(sim), frcgroup(sim), and orggroup(sim) modules, and
#    deleted by cascading delete.
#
#-----------------------------------------------------------------------

snit::type personnel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Simulation 

    # start
    #
    # This routine is called when the scenario is locked and the 
    # simulation starts.  It populates the population_g and deploy_ng
    # tables.

    typemethod start {} {
        rdb eval {
            -- Populate personnel_g table.
            INSERT INTO personnel_g(g,personnel)
            SELECT g, basepop
            FROM groups
            WHERE gtype IN ('FRC', 'ORG');

            -- Populate deploy_ng table.  
            -- TBD: For now, insert everything; later, maybe we can
            -- let it be sparse.
            INSERT INTO deploy_ng(n,g,personnel)
            SELECT N.n, G.g, 0
            FROM nbhoods AS N
            JOIN groups AS G
            WHERE G.gtype IN ('FRC', 'ORG');
        }
    }

    # reset
    #
    # This routine is called at each strategy tock.  It clears all
    # deployments, and resets each group's available count back to 
    # its total personnel.

    typemethod reset {} {
        rdb eval {
            UPDATE personnel_g SET available = personnel;

            UPDATE deploy_ng   
            SET personnel  = 0,
                unassigned = 0;
        }
    }

    # deploy n g personnel
    #
    # This routine is called by the DEPLOY tactic.  It deploys the
    # requested number of available personnel.

    typemethod deploy {n g personnel} {
        set available [rdb onecolumn {
            SELECT available FROM personnel_g WHERE g=$g
        }]

        require {$personnel <= $available} \
            "Insufficient personnel available: $personnel > $available"

        rdb eval {
            UPDATE personnel_g
            SET available = available - $personnel
            WHERE g=$g;

            UPDATE deploy_ng
            SET personnel  = personnel  + $personnel,
                unassigned = unassigned + $personnel
            WHERE n=$n AND g=$g;
        }
    }


    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate attrit n g casualties
    #
    # n            - A neighborhood
    # g            - A FRC/ORG group
    # casualties   - The number of casualties
    #
    # Updates deploy_ng and personnel_g given the casualties.  If
    # casualties is negative, personnel are returned.

    typemethod {mutate attrit} {n g casualties} {
        # FIRST, get the undo information
        set deployed [rdb onecolumn {
            SELECT personnel FROM deploy_ng
            WHERE n=$n AND g=$g
        }]

        if {$casualties > 0} {
            # Can't kill more than are there.
            let casualties {min($casualties,$deployed)}
        } else {
            # We're putting people back.
            # Nothing to do.
        }
        
        # We undo by putting the same number of people back.
        let undoCasualties {-$casualties}
        
        # NEXT, Update the group
        rdb eval {
            UPDATE deploy_ng
            SET personnel = personnel - $casualties
            WHERE n=$n AND g=$g;

            UPDATE personnel_g
            SET personnel = personnel - $casualties
            WHERE g=$g
        } {}
        
        # NEXT, Return the undo command
        return [mytypemethod mutate attrit $n $g $undoCasualties]
    }
}



