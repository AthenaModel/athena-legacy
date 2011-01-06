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
#    By default, group relationships are computed from belief systems
#    by the bsystem module, an instance of mam(n), with the exception
#    that rel.gg is always 1.0.  The analyst is allowed to override
#    any relationship for which f != g.  These overrides are stored in
#    the rel_fg table and viewed in relbrowser(sim).  The rel_view
#    view pulls all of the data together.
#
#    Because rel_fg stores overrides values computed elsewhere, this
#    module follows a rather different pattern than other scenario
#    editing modules.  The relationships come into being automatically
#    with the groups.  Thus, there is no REL:CREATE order.  Instead,
#    REL:OVERRIDE and REL:OVERRIDE:MULTI will create new records as 
#    needed.  REL:RESTORE will delete overrides.
#
#    Note that overridden relationships are deleted via cascading
#    delete if the relevant groups are deleted.
#
#-----------------------------------------------------------------------

snit::type rel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An fg relationship ID, [list $f $g]
    #
    # Throws INVALID if id doesn't name an overrideable relationship.

    typemethod validate {id} {
        lassign $id f g

        set f [group validate $f]
        set g [group validate $g]

        if {$f eq $g} {
            return -code error -errorcode INVALID \
                "A group's relationship with itself cannot be overridden."
        }

        return [list $f $g]
    }

    # exists id
    #
    # id     An fg relationship ID, [list $f $g]
    #
    # Returns 1 if there's an overridden relationship 
    # between f and g, and 0 otherwise.

    typemethod exists {id} {
        lassign $id f g

        rdb exists {
            SELECT * FROM rel_fg WHERE f=$f AND g=$g
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
    #    id               list {f g}
    #    rel              The relationship of f with g
    #
    # Creates a relationship record given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            lassign $id f g

            # FIRST, default rel to 0.0
            if {$rel eq ""} {
                set rel 0.0
            }

            # NEXT, Put the group in the database
            rdb eval {
                INSERT INTO 
                rel_fg(f,g,rel)
                VALUES($f, $g, $rel);
            }

            # NEXT, Return the undo command
            return [list rdb delete rel_fg "f='$f' AND g='$g'"]
        }
    }


    # mutate delete id
    #
    # id        list {f g}
    #
    # Deletes the relationship override.

    typemethod {mutate delete} {id} {
        lassign $id f g

        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab rel_fg {f=$f AND g=$g}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {f g}
    #    rel              Relationship of f with g
    #
    # Updates a relationship given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id f g

            # FIRST, get the undo information
            set data [rdb grab rel_fg {f=$f AND g=$g}]

            # NEXT, Update the group
            rdb eval {
                UPDATE rel_fg
                SET rel = nonempty($rel, rel)
                WHERE f=$f AND g=$g
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}


#-------------------------------------------------------------------
# Orders: REL:*

# REL:RESTORE
#
# Deletes existing relationship override

order define REL:RESTORE {
    title "Restore Computed Relationship"
    options \
        -sendstates PREP

    parm id   key   "Groups"         -table  gui_rel_view \
                                     -key    {f g}      \
                                     -labels {Of With}
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type rel

    returnOnError -final

    # NEXT, delete the record
    setundo [rel mutate delete $parms(id)]
}

# REL:OVERRIDE
#
# Updates existing override

order define REL:OVERRIDE {
    title "Override Computed Relationship"
    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey id *}

    parm id   key   "Groups"         -table  gui_rel_view \
                                     -key    {f g}      \
                                     -labels {Of With}
    parm rel  rel   "Relationship"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type rel
    prepare rel      -toupper            -type qrel

    returnOnError -final

    # NEXT, modify the curve
    if {[rel exists $parms(id)]} {
        setundo [rel mutate update [array get parms]]
    } else {
        setundo [rel mutate create [array get parms]]
    }
}


# REL:OVERRIDE:MULTI
#
# Updates multiple existing relationship overrides

order define REL:OVERRIDE:MULTI {
    title "Override Multiple Relationships"
    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids  multi  "IDs"           -table gui_rel_view \
                                     -key   id
    parm rel  rel    "Relationship"
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof rel
    prepare rel      -toupper            -type qrel

    returnOnError -final


    # NEXT, modify the records
    set undo [list]

    foreach parms(id) $parms(ids) {
        if {[rel exists $parms(id)]} {
            lappend undo [rel mutate update [array get parms]]
        } else {
            lappend undo [rel mutate create [array get parms]]
        }
    }

    setundo [join $undo \n]
}


