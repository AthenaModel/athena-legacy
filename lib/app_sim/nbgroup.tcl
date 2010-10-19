#-----------------------------------------------------------------------
# TITLE:
#    nbgroup.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Nbhood Group Manager
#
#    This module is responsible for managing nbhood groups and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type nbgroup {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # exists n g
    #
    # n       A neighborhood ID
    # g       A group ID
    #
    # Returns 1 if there is such an nbgroup, and 0 otherwise.

    typemethod exists {n g} {
        rdb exists {
            SELECT * FROM nbgroups WHERE n=$n AND g=$g
        }
    }

    # gIn n
    #
    # n      A neighborhood ID
    #
    # Returns a list of the civ groups that reside in this neighborhood.

    typemethod gIn {n} {
        rdb eval {
            SELECT g FROM nbgroups WHERE n=$n
            ORDER BY g
        }
    }

    # nFor g
    #
    # g    A CIV group ID
    #
    # Returns a list of the neighborhoods in which g resides.

    typemethod nFor {g} {
        rdb eval {
            SELECT n FROM nbgroups WHERE g=$g
            ORDER BY n
        }
    }


    # validate id
    #
    # id      A group ID, [list $n $g]
    #
    # Validates an nbgroup ID

    typemethod validate {id} {
        lassign $id n g

        set n [nbhood   validate $n]
        set g [civgroup validate $g]

        if {![$type exists $n $g]} { 
            return -code error -errorcode INVALID \
                "Group $g does not reside in neighborhood $n"
        }

        return [list $n $g]
    }

    # unsed validate id
    #
    # id      A group ID, [list $n $g]
    #
    # Validates an nbgroup ID as a possible ID, and verifies that it isn't
    # in use.

    typemethod {unused validate} {id} {
        lassign $id n g

        set n [nbhood   validate $n]
        set g [civgroup validate $g]

        if {[$type exists $n $g]} { 
            return -code error -errorcode INVALID \
                "Group $g already resides in neighborhood $n"
        }

        return [list $n $g]
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
    # parmdict     A dictionary of group parms
    #
    #    id               list {n g}
    #    local_name       The nbgroup's local name
    #    basepop          The nbgroup's base population
    #    sap              The nbgroup's subsistence agriculture percentage
    #
    # Creates a nbhood group given the parms, which are presumed to be
    # valid.
    #
    # Creating a nbhood group requires adding entries to the nbgroups 
    # table.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            lassign $id n g

            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO nbgroups(n,g,local_name,basepop,sap)
                VALUES($n,
                       $g,
                       $local_name,
                       $basepop,
                       $sap);

                -- All population is implicit, initially.
                INSERT INTO demog_ng(n,g) 
                VALUES($n,$g);
            }

            # NEXT, notify the app.
            notifier send ::nbgroup <Entity> create $id

            # NEXT, Return the undo command
            set undo [list]
            lappend undo [mytypemethod mutate delete $n $g]

            return [join $undo \n]
        }
    }


    # mutate delete n g
    #
    # n g     An nbgroup ID
    #
    # Deletes the group, including all references.

    typemethod {mutate delete} {n g} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM nbgroups WHERE n=$n AND g=$g} row1 {
            unset row1(*)
        }

        rdb eval {SELECT * FROM demog_ng WHERE n=$n AND g=$g} row2 {
            unset row2(*)
        }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM nbgroups WHERE n=$n AND g=$g;
            DELETE FROM demog_ng WHERE n=$n AND g=$g;
        }

        # NEXT, notify the app.
        notifier send ::nbgroup <Entity> delete [list $n $g]

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row1] [array get row2]]
    }

    # Restore parmdict1 parmdict2
    #
    # parmdict1     row dict for deleted entity
    # parmdict2     row dict for deleted entity
    #
    # Restores the entity in the database

    typemethod Restore {parmdict1 parmdict2} {
        rdb insert nbgroups $parmdict1
        rdb insert demog_ng $parmdict2

        dict with parmdict1 {
            notifier send ::nbgroup <Entity> create [list $n $g]
        }
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {n g}
    #    local_name       A new local name, or ""
    #    basepop          A new basepop, or ""
    #    sap              A new sap, or ""
    #
    # Updates a nbgroup given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n g

            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM nbgroups
                WHERE n=$n AND g=$g
            } undoData {
                unset undoData(*)
                set undoData(id) $id
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE nbgroups
                SET local_name     = nonempty($local_name,     local_name),
                    basepop        = nonempty($basepop,        basepop),
                    sap            = nonempty($sap,            sap)
                WHERE n=$n AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::nbgroup <Entity> update [list $n $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

    # mutate reconcile
    #
    # Deletes nbgroups for which either the neighborhood or the
    # civilian group no longer exists.

    typemethod {mutate reconcile} {} {
        # FIRST, get the set of possible nbgroups
        set valid [dict create]

        rdb eval {
            SELECT n, g 
            FROM nbhoods 
            JOIN civgroups_view
        } {
            dict set valid [list $n $g] 0
        }

        # NEXT, delete the ones that are no longer valid, accumulating
        # an undo script.
        set undo [list]

        rdb eval {
            SELECT n,g FROM nbgroups
        } {
            if {![dict exists $valid [list $n $g]]} {
                lappend undo [$type mutate delete $n $g]
            }
        }

        return [join $undo \n]
    }
}

#-------------------------------------------------------------------
# Orders: GROUP:NBHOOD:*

# GROUP:NBHOOD:CREATE
#
# Creates new nbhood groups.

order define GROUP:NBHOOD:CREATE {
    title "Create Nbhood Group"

    options -sendstates PREP

    parm id             newkey "Nbhood Group"  -universe nbgroups_univ \
                                               -table    nbgroups      \
                                               -key      {n g}
    parm local_name     text "Local Name"
    parm basepop        text "Base Population"
    parm sap            text "Subs. Agri. %"   -defval 0
} {
    # FIRST, prepare and validate the parameters
    prepare id             -toupper -required -type {nbgroup unused}
    prepare local_name     -normalize
    prepare basepop                 -required -type ingpopulation
    prepare sap                     -required -type ipercent

    returnOnError -final

    # NEXT, if local_name is not given, use the group's long name
    if {$parms(local_name) eq ""} {
        lassign $parms(id) n g
        set parms(local_name) [rdb onecolumn {
            SELECT longname FROM groups WHERE g=$g
        }]
    }

    # NEXT, create the group and dependent entities.
    lappend undo [nbgroup mutate create [array get parms]]
    lappend undo [scenario mutate reconcile]
    
    setundo [join $undo \n]

    return
}

# GROUP:NBHOOD:DELETE

order define GROUP:NBHOOD:DELETE {
    title "Delete Nbhood Group"
    options \
        -sendstates PREP

    parm id key  "Nbhood Group"  -table gui_nbgroups \
                                 -key {n g}
} {
    # FIRST, prepare the parameters
    prepare id -toupper -required -type nbgroup

    returnOnError -final

    # NEXT, Delete all entities that depend on this group, unless the
    # user says no.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     GROUP:NBHOOD:DELETE                    \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure 
                            you really want to delete this neighborhood 
                            group and all data that depends on it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, delete the group and dependent entities
    lappend undo [nbgroup mutate delete {*}$parms(id)]
    lappend undo [scenario mutate reconcile]
    
    setundo [join $undo \n]

    return
}


# GROUP:NBHOOD:UPDATE
#
# Updates existing groups.

order define GROUP:NBHOOD:UPDATE {
    title "Update Nbhood Group"
    options \
        -sendstates PREP                               \
        -refreshcmd {::orderdialog refreshForKey id *}

    parm id             key  "Nbhood Group"    -table gui_nbgroups \
                                               -key {n g}
    parm local_name     text "Local Name"
    parm basepop        text "Base Population"
    parm sap            text "Subs. Agri. %" 
} {
    # FIRST, prepare the parameters
    prepare id             -toupper  -required -type nbgroup
    prepare local_name     -normalize      
    prepare basepop                  -type ingpopulation
    prepare sap                      -type ipercent

    returnOnError -final

    # NEXT, modify the group
    lappend undo [nbgroup mutate update [array get parms]]

    setundo [join $undo \n]
    return
}


# GROUP:NBHOOD:UPDATE:MULTI
#
# Updates multiple groups.

order define GROUP:NBHOOD:UPDATE:MULTI {
    title "Update Multiple Nbhood Groups"
    options \
        -sendstates PREP                                  \
        -refreshcmd {::orderdialog refreshForMulti ids *}

    parm ids            multi "Groups"          -table gui_nbgroups \
                                                -key   id
    parm local_name     text  "Local Name"
    parm basepop        text  "Base Population"
    parm sap            text  "Subs. Agri. %"
} {
    # FIRST, prepare the parameters
    prepare ids            -toupper  -required -listof nbgroup
    prepare local_name     -normalize      
    prepare basepop                  -type ingpopulation
    prepare sap                      -type ipercent

    returnOnError -final

    # NEXT, modify the group
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [nbgroup mutate update [array get parms]]
    }

    setundo [join $undo \n]

    return
}

# GROUP:NBHOOD:UPDATE:POSTPREP
#
# Updates existing groups outside the PREP state.

order define GROUP:NBHOOD:UPDATE:POSTPREP {
    title "Update Nbhood Group (Post-PREP)"
    options \
        -sendstates {PREP PAUSED}                      \
        -refreshcmd {::orderdialog refreshForKey id *}

    parm id             key  "Nbhood Group"    -table gui_nbgroups \
                                               -key {n g}
    parm sap            text "Subs. Agri. %" 
} {
    # FIRST, prepare the parameters
    prepare id             -toupper  -required -type nbgroup
    prepare sap                      -type ipercent

    returnOnError -final

    # NEXT, modify the group
    lappend undo [nbgroup mutate update [array get parms]]

    setundo [join $undo \n]
    return
}


# GROUP:NBHOOD:UPDATE:POSTPREP:MULTI
#
# Updates multiple groups.

order define GROUP:NBHOOD:UPDATE:POSTPREP:MULTI {
    title "Update Multiple Nbhood Groups (Post-PREP)"
    options \
        -sendstates {PREP PAUSED}                         \
        -refreshcmd {::orderdialog refreshForMulti ids *}

    parm ids            multi "Groups"          -table gui_nbgroups \
                                                -key   id
    parm sap            text  "Subs. Agri. %"
} {
    # FIRST, prepare the parameters
    prepare ids            -toupper  -required -listof nbgroup
    prepare local_name     -normalize      
    prepare sap                      -type ipercent

    returnOnError -final

    # NEXT, modify the group
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [nbgroup mutate update [array get parms]]
    }

    setundo [join $undo \n]

    return
}



