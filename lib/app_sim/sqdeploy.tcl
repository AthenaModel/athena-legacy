#-----------------------------------------------------------------------
# TITLE:
#    sqdeploy.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): FRC/ORG Group initial deployments manager
#
#    This module is responsible for managing the editing of the
#    initial deployment of FRC and ORG groups in neighborhoods.  This
#    data is used to establish the initial conditions on scenario lock,
#    before the actor strategies are first executed.
#
#    Force deployments default to 0.  The user creates records in
#    sqdeploy_ng for non-zero deployments.  The gui_sqdeploy_ng view
#    pulls any existing records in, filling in the missing spots with
#    0's.  deploy_ng records are deleted explicitly by the user, or 
#    with the relevant neighborhood and group.
#
#-----------------------------------------------------------------------

snit::type sqdeploy {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id      A group ID, [list $n $g]
    #
    # Validates an n,g pair, where g is a FRC or ORG group.

    typemethod validate {id} {
        lassign $id n g

        set n [nbhood validate $n]
        set g [group  validate $g]

        if {[group gtype $g] ni {FRC ORG}} { 
            return -code error -errorcode INVALID \
                "Group $g is neither a FRC nor an ORG group."
        }

        return [list $n $g]
    }

    # exists id
    #
    # id     An ng deployment ID, [list $n $g]
    #
    # Returns 1 if there's an explicit status quo deployment 
    # of g in n, and 0 otherwise.

    typemethod exists {id} {
        lassign $id n g

        rdb exists {
            SELECT * FROM sqdeploy_ng WHERE n=$n AND g=$g
        }
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
    # parmdict     A dictionary of rel parms
    #
    #    id          list {n g}
    #    personnel   The number of g personnel deployed in n.
    #
    # Creates a sqdeploy_ng record given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            lassign $id n g

            rdb eval {
                INSERT INTO 
                sqdeploy_ng(n,g,personnel)
                VALUES($n, $g, $personnel);
            }

            # NEXT, Return the undo command
            return [list rdb delete sqdeploy_ng "n='$n' AND g='$g'"]
        }
    }

    # mutate delete id
    #
    # id        list {n g}
    #
    # Deletes the deployment, returning it to 0.

    typemethod {mutate delete} {id} {
        lassign $id n g

        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab sqdeploy_ng {n=$n AND g=$g}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {n g}
    #    personnel      A new personnel number.
    #
    # Updates a sqdeploy record given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n g

            # FIRST, get the undo information
            set data [rdb grab sqdeploy_ng {n=$n AND g=$g}]

            # NEXT, Update the group
            rdb eval {
                UPDATE sqdeploy_ng
                SET personnel = $personnel
                WHERE n=$n AND g=$g
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}

#-------------------------------------------------------------------
# Orders: SQDEPLOY:*

# SQDEPLOY:SET
#
# Sets the status quo deployment for a FRC/ORG group in a neighborhood.

order define SQDEPLOY:SET {
    title "Set Status Quo Group Deployment"
    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey id *}



    parm id            key  "Nbhood/Group"  -table gui_sqdeploy_ng \
                                            -keys {n g}
    parm personnel     text "Personnel"
} {
    # FIRST, prepare the parameters
    prepare id             -toupper  -required -type sqdeploy
    prepare personnel                -required -type iquantity

    returnOnError -final

    # NEXT, modify the deployment
    if {[sqdeploy exists $parms(id)]} {
        if {$parms(personnel) > 0} {
            setundo [sqdeploy mutate update [array get parms]]
        } else {
            setundo [sqdeploy mutate delete $parms(id)]
        }
    } else {
        if {$parms(personnel) > 0} {
            setundo [sqdeploy mutate create [array get parms]]
        } else {
            setundo "# No undo required"
        }
    }

    return
}

# SQDEPLOY:DELETE
#
# Deletes the deployment for a group, returning it to 0.

order define SQDEPLOY:DELETE {
    title "Delete Status Quo Group Deployment"
    options \
        -sendstates     PREP

    parm id             key  "Nbhood/Group"    -table gui_sqdeploy_ng \
                                               -keys  {n g}
} {
    # FIRST, prepare the parameters
    prepare id             -toupper  -required -type sqdeploy

    returnOnError -final

    # NEXT, modify the group
    lappend undo [sqdeploy mutate delete $parms(id)]

    setundo [join $undo \n]
    return
}




