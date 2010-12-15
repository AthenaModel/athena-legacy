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
#    This module implements the Defending ROE entity
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module Singleton

snit::type ::defroe {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Initialization

    # TBD: nothing to do

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An ng defroe ID, [list $n $g]
    #
    # Throws INVALID if there's no ROE for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id n g

        set n [nbhood validate $n]
        set g [frcgroup uniformed validate $g]

        # Note: no need to test the combination; entries exist
        # for all n's and valid g's.

        return [list $n $g]
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # the change cannot be undone, the mutator returns the empty string.

    # mutate reconcile
    #
    # Determines which defending ROEs should exist, and 
    # adds or deletes them.

    typemethod {mutate reconcile} {} {
        # FIRST, List required defend entries
        set valid [dict create]

        rdb eval {
            SELECT n,g
            FROM nbhoods JOIN frcgroups
            WHERE uniformed
        } {
            dict set valid [list $n $g] 0
        }

        # NEXT, Begin the undo script.
        set undo [list]

        # NEXT, delete the ones that are no longer valid,
        # accumulating undo entries for them.  Also, note which ones
        # *do* exist.

        rdb eval {
            SELECT * FROM defroe_ng
        } row {
            unset -nocomplain row(*)

            set id [list $row(n) $row(g)]

            if {[dict exists $valid $id]} {
                dict incr valid $id
            } else {
                lappend undo [mytypemethod Restore [array get row]]

                rdb eval {
                    DELETE FROM defroe_ng
                    WHERE n=$row(n) AND g=$row(g)
                }
            }
        }

        # NEXT, create any that don't exist and should.
        foreach id [dict keys $valid] {
            if {[dict get $valid $id] == 1} {
                continue
            }

            lassign $id n g

            rdb eval {
                INSERT INTO defroe_ng(n,g)
                VALUES($n,$g)
            }

            lappend undo [mytypemethod Delete $n $g]
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
        rdb insert defroe_ng $parmdict
    }


    # Delete n g
    #
    # n,g    The indices of the entity
    #
    # Deletes the entity.  Used only in undo scripts.
    
    typemethod Delete {n g} {
        rdb eval {
            DELETE FROM defroe_ng WHERE n=$n AND g=$g
        }
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID
    #    g                Group ID
    #    roe              The edefroeuf(n) value
    #
    # Updates an ROE given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n g
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM defroe_ng
                WHERE n=$n AND g=$g
            } undoData {
                unset undoData(*)
                set undoData(id) $id
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE defroe_ng
                SET roe = nonempty($roe, roe)
                WHERE n=$n AND g=$g
            } {}

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}

#-------------------------------------------------------------------
# Orders: DEFROE:*

# DEFROE:UPDATE
#
# Updates existing relationships

order define DEFROE:UPDATE {
    title "Update Defending ROE"
    options \
        -schedulestates {PREP PAUSED}                     \
        -sendstates     {PREP PAUSED}                     \
        -refreshcmd     {orderdialog refreshForKey id *}

    parm id   key   "Defender"       -table  gui_defroe_ng \
                                     -key    {n g}         \
                                     -labels {"In" "Grp"}
    parm roe  enum  "ROE"            -type edefroeuf   
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type defroe
    prepare roe      -toupper            -type edefroeuf

    returnOnError -final

    # NEXT, modify the entity
    setundo [defroe mutate update [array get parms]]
}


# DEFROE:UPDATE:MULTI
#
# Updates multiple existing relationships

order define DEFROE:UPDATE:MULTI {
    title "Update Multiple Defending ROEs"
    options \
        -schedulestates {PREP PAUSED} \
        -sendstates     {PREP PAUSED} \
        -refreshcmd     {orderdialog refreshForMulti ids *}

    parm ids  multi  "IDs" -table gui_defroe_ng \
                           -key id
    parm roe  enum   "ROE" -type edefroeuf   
} {
    # FIRST, prepare the parameters
    prepare ids  -toupper  -required -listof defroe
    prepare roe  -toupper            -type edefroeuf

    returnOnError -final


    # NEXT, modify the curves
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [defroe mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


