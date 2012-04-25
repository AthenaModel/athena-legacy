#-----------------------------------------------------------------------
# TITLE:
#    vrel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Vertical Relationship Manager
#
#    By default, the initial vertical group relationships (vrel)
#    are computed from belief systems by the bsystem module, an
#    instance of mam(n), with the exception that vrel.ga is always 1.0
#    when g is a group owned by actor a. The analyst is allowed to override 
#    any initial relationship.  The natural relationship is always 
#    1.0 when a owns g, and the affinity otherwise.
#
#    These overrides are stored in the vrel_ga table and viewed in
#    vrelbrowser(sim).  The vrel_view view pulls all of the data together.
#
#    Because vrel_ga overrides values computed elsewhere, this
#    module follows a rather different pattern than other scenario
#    editing modules.  The relationships come into being automatically
#    with the groups.  Thus, there is no VREL:CREATE order.  Instead,
#    VREL:OVERRIDE and VREL:OVERRIDE:MULTI will create new records as 
#    needed.  VREL:RESTORE will delete overrides.
#
#    Note that overridden relationships are deleted via cascading
#    delete if the relevant groups are deleted.
#
#-----------------------------------------------------------------------

snit::type vrel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An fg relationship ID, [list $g $a]
    #
    # Throws INVALID if id doesn't name an overrideable relationship.

    typemethod validate {id} {
        lassign $id g a

        set g [group validate $g]
        set a [actor validate $a]

        return [list $g $a]
    }

    # exists id
    #
    # id     A ga relationship ID, [list $g $a]
    #
    # Returns 1 if there's an overridden relationship 
    # between g and a, and 0 otherwise.

    typemethod exists {id} {
        lassign $id g a

        rdb exists {
            SELECT * FROM vrel_ga WHERE g=$g AND a=$a
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
    # parmdict  - A dictionary of vrel parms
    #
    #    id     - list {g a}
    #    vrel   - The relationship of g with a
    #
    # Creates a relationship record given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            lassign $id g a

            # FIRST, default vrel to 0.0
            if {$vrel eq ""} {
                set vrel 0.0
            }

            # NEXT, Put the group in the database
            rdb eval {
                INSERT INTO 
                vrel_ga(g,a,vrel)
                VALUES($g, $a, $vrel);
            }

            # NEXT, Return the undo command
            return [list rdb delete vrel_ga "g='$g' AND a='$a'"]
        }
    }


    # mutate delete id
    #
    # id   - list {g a}
    #
    # Deletes the relationship override.

    typemethod {mutate delete} {id} {
        lassign $id g a

        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab vrel_ga {g=$g AND a=$a}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }


    # mutate update parmdict
    #
    # parmdict  - A dictionary og aroup parms
    #
    #    id     - list {g a}
    #    vrel   - Relationship of g with a
    #
    # Updates a relationship given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id g a

            # FIRST, get the undo information
            set data [rdb grab vrel_ga {g=$g AND a=$a}]

            # NEXT, Update the group
            rdb eval {
                UPDATE vrel_ga
                SET vrel = nonempty($vrel, vrel)
                WHERE g=$g AND a=$a
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}


#-------------------------------------------------------------------
# Orders: VREL:*

# VREL:RESTORE
#
# Deletes existing relationship override

order define VREL:RESTORE {
    title "Restore Initial Vertical Relationship"
    options \
        -sendstates PREP

    parm id   key   "Groups"         -table  gui_vrel_view \
                                     -keys   {g a}      \
                                     -labels {Of With}
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type vrel

    returnOnError -final

    # NEXT, delete the record
    setundo [vrel mutate delete $parms(id)]
}

# VREL:OVERRIDE
#
# Updates existing override

order define VREL:OVERRIDE {
    title "Override Initial Vertical Relationship"
    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey id *}

    parm id   key   "Groups"         -table  gui_vrel_view \
                                     -keys   {g a}         \
                                     -labels {Of With}
    parm vrel rel   "Relationship"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type vrel
    prepare vrel     -toupper            -type qaffinity

    returnOnError -final

    # NEXT, modify the curve
    if {[vrel exists $parms(id)]} {
        setundo [vrel mutate update [array get parms]]
    } else {
        setundo [vrel mutate create [array get parms]]
    }
}


# VREL:OVERRIDE:MULTI
#
# Updates multiple existing relationship overrides

order define VREL:OVERRIDE:MULTI {
    title "Override Multiple Vertical Relationships"
    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids  multi  "IDs"           -table gui_vrel_view \
                                     -key   id
    parm vrel rel    "Relationship"
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof vrel
    prepare vrel     -toupper            -type qaffinity

    returnOnError -final


    # NEXT, modify the records
    set undo [list]

    foreach parms(id) $parms(ids) {
        if {[vrel exists $parms(id)]} {
            lappend undo [vrel mutate update [array get parms]]
        } else {
            lappend undo [vrel mutate create [array get parms]]
        }
    }

    setundo [join $undo \n]
}


