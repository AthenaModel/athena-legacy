#-----------------------------------------------------------------------
# TITLE:
#    mad.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Magic Attitude Driver (MAD) Manager
#
#    This module is responsible for managing the creation, editing,
#    and deletion of MADs.
#
#-----------------------------------------------------------------------

snit::type mad {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail mad "Initialized"
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of MAD ids

    typemethod names {} {
        rdb eval {SELECT id FROM mads}
    }


    # validate id
    #
    # id         Possibly, a MAD ID.
    #
    # Validates a MAD id

    typemethod validate {id} {
        if {![rdb exists {SELECT id FROM mads WHERE id=$id}]} {
            return -code error -errorcode INVALID \
                "MAD does not exist: \"$id\""
        }

        return $id
    }

    # extended names
    #
    # Returns the list of extended MAD ids (id + oneliner)

    typemethod {extended names} {} {
        rdb eval {SELECT id FROM gui_mads_orders}
    }


    # extended validate id
    #
    # id         Possibly, a MAD ID or extended MAD ID
    #
    # Validates a MAD id

    typemethod {extended validate} {id} {
        set realid [lindex [split $id " "] 0]

        if {![rdb exists {SELECT id FROM mads WHERE id=$realid}]} {
            return -code error -errorcode INVALID \
                "MAD does not exist: \"$id\""
        }

        return $realid
    }


    # initial names
    #
    # Returns the list of MAD ids for MADs in the initial state

    typemethod {initial names} {} {
        rdb eval {SELECT id FROM mads_initial}
    }


    # initial validate id
    #
    # id         Possibly, a MAD ID.
    #
    # Validates a MAD id for a MAD in the initial state

    typemethod {initial validate} {id} {
        set realid [lindex [split $id " "] 0]

        if {![rdb exists {SELECT id FROM mads_initial WHERE id=$realid}]} {
            return -code error -errorcode INVALID \
                "MAD does not exist or is not in initial state: \"$id\""
        }

        return $realid
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
    # parmdict     A dictionary of MAD parms
    #
    #    oneliner       The MAD's description.
    #
    # Creates a MAD given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, get the next ID.
            set id [rdb onecolumn {
                SELECT COALESCE(max(id)+1, 1) FROM mads
            }]

            # FIRST, Put the MAD in the database
            rdb eval {
                INSERT INTO mads(id,oneliner)
                VALUES($id,
                       $oneliner);
            }

            # NEXT, notify the app.
            notifier send ::mad <Entity> create $id

            # NEXT, Return the undo command
            return [mytypemethod mutate delete $id]
        }
    }

    # mutate delete id
    #
    # id     A MAD ID
    #
    # Deletes the MAD.

    typemethod {mutate delete} {id} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM mads WHERE id=$id} row { unset row(*) }

        # NEXT, delete it.
        rdb eval {DELETE FROM mads WHERE id=$id}

        # NEXT, notify the app
        notifier send ::mad <Entity> delete $id

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row]]
    }

    # Restore dict
    #
    # dict    row dict for deleted entity in mads
    #
    # Restores the row to the database

    typemethod Restore {dict} {
        rdb insert mads $dict

        notifier send ::mad <Entity> create [dict get $dict id]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of order parms
    #
    #   id           The MAD's ID
    #   oneliner     A new description
    #
    # Updates the MAD given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM mads
                WHERE id=$id
            } row {
                unset row(*)
            }
            
            # NEXT, Update the MAD
            rdb eval {
                UPDATE mads
                SET oneliner = $oneliner
                WHERE id=$id
            }

            # NEXT, notify the app.
            notifier send ::mad <Entity> update $id
            
            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get row]]
        }
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # TBD
}

#-------------------------------------------------------------------
# Orders: MAD:*

# MAD:CREATE
#
# Creates a new MAD.

order define ::mad MAD:CREATE {
    title "Create Magic Attitude Driver"

    options -sendstates {PREP PAUSED}

    parm oneliner text  "Description" 
} {
    # FIRST, prepare and validate the parameters
    prepare oneliner   -required

    returnOnError -final

    # NEXT, create the mad
    lappend undo [$type mutate create [array get parms]]

    setundo [join $undo \n]
}


# MAD:DELETE
#
# Deletes a MAD in the initial state

order define ::mad MAD:DELETE {
    title "Delete Magic Attitude Driver"
    options \
        -table      gui_mads_orders_initial   \
        -sendstates {PREP PAUSED}


    parm id  key "MAD ID"
} {
    # FIRST, prepare the parameters
    prepare id -toupper -required -type {mad initial}

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     MAD:DELETE                      \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this magic attitude
                            driver?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the mad
    lappend undo [$type mutate delete $parms(id)]

    setundo [join $undo \n]
}


# MAD:UPDATE
#
# Updates an existing mad's description

order define ::mad MAD:UPDATE {
    title "Update Magic Attitude Driver"
    options \
        -table       gui_mads_orders_initial  \
        -sendstates  {PREP PAUSED}

    parm id          key   "MAD ID"
    parm oneliner    text  "Description"
} {
    # FIRST, prepare the parameters
    prepare id         -required -type {mad initial}
    prepare oneliner   -required

    returnOnError -final

    # NEXT, update the MAD
    lappend undo [$type mutate update [array get parms]]

    setundo [join $undo \n]
}






