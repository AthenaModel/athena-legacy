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

                notifier send ::defroe <Entity> delete $id
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

            notifier send ::defroe <Entity> create $id
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

        dict with parmdict {
            notifier send ::defroe <Entity> create [list $n $g]
        }
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

        notifier send ::defroe <Entity> delete [list $n $g]
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
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM defroe_ng
                WHERE n=$n AND g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE defroe_ng
                SET roe = nonempty($roe, roe)
                WHERE n=$n AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::defroe <Entity> update [list $n $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}

#-------------------------------------------------------------------
# Orders: ROE:DEFEND:*

# ROE:DEFEND:UPDATE
#
# Updates existing relationships

order define ::defroe ROE:DEFEND:UPDATE {
    title "Update Defending ROE"
    options \
        -table          gui_defroe_ng \
        -schedulestates {PREP PAUSED} \
        -sendstates     {PREP PAUSED}

    parm n    key   "Neighborhood"   -tags nbhood
    parm g    key   "Group"          -tags group
    parm roe  enum  "ROE"            -type edefroeuf   
} {
    # FIRST, prepare the parameters
    prepare n        -toupper  -required -type nbhood
    prepare g        -toupper  -required -type {frcgroup uniformed}
    prepare roe      -toupper            -type edefroeuf

    returnOnError -final

    # NEXT, modify the entity
    setundo [$type mutate update [array get parms]]
}


# ROE:DEFEND:UPDATE:MULTI
#
# Updates multiple existing relationships

order define ::defroe ROE:DEFEND:UPDATE:MULTI {
    title "Update Multiple Defending ROEs"
    options \
        -table          gui_defroe_ng \
        -schedulestates {PREP PAUSED} \
        -sendstates     {PREP PAUSED}

    parm ids  multi  "IDs"
    parm roe  enum   "ROE" -type edefroeuf   
} {
    # FIRST, prepare the parameters
    prepare ids  -toupper  -required -listof defroe
    prepare roe  -toupper            -type edefroeuf

    returnOnError -final


    # NEXT, modify the curves
    set undo [list]

    foreach id $parms(ids) {
        lassign $id parms(n) parms(g)

        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}

