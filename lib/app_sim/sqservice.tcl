#-----------------------------------------------------------------------
# TITLE:
#    sqservice.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Status Quo service provision manager.
#
#    This module is responsible for managing the editing of the 
#    status quo level of ENI service provided to civilian groups
#    by actors.  This data is used to establish the initial conditions 
#    on scenario lock, before the actor strategies are first executed.
#
#    Funding of ENI service defaults to 0. The user creates records in
#    sqservice_ga for non-zero funding.  The sqservice_view view
#    pulls any existing records in, filling in the missing spots with
#    0's.  sqservice_ga records are deleted explicitly by the user, or 
#    with the relevant group and actor.
#
#-----------------------------------------------------------------------

snit::type sqservice {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id      A group ID, [list $g $a]
    #
    # Validates an g,a pair, where g is a civilian group
    # and a is an actor.

    typemethod validate {id} {
        lassign $id g a

        set g [civgroup validate $g]
        set a [actor validate $a]

        return [list $g $a]
    }

    # exists id
    #
    # id     An sqservice ID, [list $g $a]
    #
    # Returns 1 if there's an explicit sqservice record for g and a,
    # and 0 otherwise.

    typemethod exists {id} {
        lassign $id g a

        rdb exists {
            SELECT * FROM sqservice_ga WHERE g=$g AND a=$a
        }
    }


    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.


    # mutate set parmdict
    #
    # parmdict     A dictionary of sqservice parms
    #
    #    id        list {g a}
    #    funding   The funding for ENI provided to g by a
    #
    # Sets the specified value, creating a new sqservice_ga record
    # if need be.

    typemethod {mutate set} {parmdict} {
        dict with parmdict {
            lassign $id g a

            if {[$type exists $id]} {
                # FIRST, get the undo information
                set data [rdb grab sqservice_ga {g=$g AND a=$a}]

                # NEXT, Update the group
                rdb eval {
                    UPDATE sqservice_ga
                    SET funding = $funding
                    WHERE g=$g AND a=$a
                }

                # NEXT, Return the undo command
                return [list rdb ungrab $data]

            } else {
                # FIRST a new record
                rdb eval {
                    INSERT INTO 
                    sqservice_ga(g,a,funding)
                    VALUES($g, $a, $funding);
                }

                # NEXT, Return the undo command
                return [list rdb delete sqservice_ga "g='$g' AND a='$a'"]
            }
        }
    }

    # mutate reset id
    #
    # id        list {g a}
    #
    # Resets the data for the given record back to the default, i.e.,
    # deletes the sqservice_ga record.

    typemethod {mutate reset} {id} {
        lassign $id g a

        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab sqservice_ga {g=$g AND a=$a}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }
}

#-------------------------------------------------------------------
# Orders: SQSERVICE:*

# SQSERVICE:SET
#
# Sets the status quo ENI funding by an actor to a civilian group.

order define SQSERVICE:SET {
    title "Set Status Quo ENI Funding"
    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey id *}



    parm id          key  "Group/Actor"     -table gui_sqservice_ga \
                                            -keys {g a}
    parm funding     text "Funding, $/week"
} {
    # FIRST, prepare the parameters
    prepare id             -toupper  -required -type sqservice
    prepare funding                  -required -type money

    returnOnError -final

    # NEXT, modify the funding level
    setundo [sqservice mutate set [array get parms]]

    return
}

# SQSERVICE:RESET
#
# Resets an sqservice_ga record, effectively returning it to 0.

order define SQSERVICE:RESET {
    title "Reset Status Quo ENI Funding"
    options \
        -sendstates     PREP

    parm id             key  "Group/Actor"    -table gui_sqservice_ga \
                                              -keys  {g a}
} {
    # FIRST, prepare the parameters
    prepare id             -toupper  -required -type sqservice

    returnOnError -final

    # NEXT, modify the group
    lappend undo [sqservice mutate reset $parms(id)]

    setundo [join $undo \n]
    return
}




