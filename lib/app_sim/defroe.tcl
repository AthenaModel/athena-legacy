#-----------------------------------------------------------------------
# TITLE:
#    defroe.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Athena Attrition Model: Defending Rules of Engagement
#
#    This module implements the Defending ROE entity.  Every uniformed
#    force group has a defending ROE of FIRE_BACK_IF_PRESSED by
#    default.  The default is overridden by the DEFEND tactic, which
#    inserts an entry into the defroe_ng table.  The override lasts
#    until the next strategy execution tock.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module Singleton

snit::type ::defroe {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # the change cannot be undone, the mutator returns the empty string.

    # mutate create n g roe
    #
    # n    - Neighborhood ID
    # g    - Group ID
    # roe  - The edefroeuf(n) value
    #
    # Creates a ROE given the parms, which are presumed to be
    # valid.  Any exist ROE is deleted.
    #
    # NOT UNDOABLE.

    typemethod {mutate create} {n g roe} {
        rdb eval {
            DELETE FROM defroe_ng WHERE n=$n AND g=$g;

            INSERT INTO defroe_ng(n, g, roe)
            VALUES($n, $g, $roe);
        }

        return 
    }

    # mutate clear
    #
    # Deletes all entries from defroe_ng.
    #
    # NOT UNDOABLE

    typemethod {mutate clear} {} {
        rdb eval { DELETE FROM defroe_ng }
    }
}

