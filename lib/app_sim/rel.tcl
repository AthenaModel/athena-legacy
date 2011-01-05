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
#    by the bsystem module, an instance of mam(n).  However, the analyst
#    is allowed to override any of the belief system-based relationships.
#    This module is responsible for managing the creation, update,
#    and deletion of these relationship overrides in the rel_fg table.
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
    # Throws INVALID if there's no overridden relationship for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id f g

        set f [group validate $f]
        set g [group validate $g]

        if {![$type exists $id]} {
            return -code error -errorcode INVALID \
  "There is no manual override on the relationship between groups $f and $g."
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

    # unused validate id
    #
    # id     A rel_fg ID, [list $f $g]
    #
    # Throws INVALID if the id can't be a valid rel_fg ID, or
    # if it's already in use.

    typemethod {unused validate} {id} {
        lassign $id f g

        set f [group validate $f]
        set g [group validate $g]

        if {[$type exists $id]} {
            return -code error -errorcode INVALID \
          "Override already exists on relationship between groups $f and $g"
        }

        return [list $f $g]
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

# REL:CREATE
#
# Creates new relationship overrides

order define REL:CREATE {
    title "Create Group Relationship Override"

    options -sendstates PREP

    parm id   newkey "Groups"        -universe rel_view      \
                                     -table    rel_fg        \
                                     -key      {f g}         \
                                     -labels   {"Of" "With"}
    parm rel  rel    "Relationship"
} {
    # FIRST, prepare and validate the parameters
    prepare id  -toupper  -required -type {rel unused}
    prepare rel -toupper            -type qrel

    returnOnError

    # NEXT, cross checks
    lassign $parms(id) f g

    if {$f eq $g} {
        reject id "Cannot override a group's relationship with itself."
    }

    returnOnError -final

    # NEXT, create the group and dependent entities
    lappend undo [rel mutate create [array get parms]]

    setundo [join $undo \n]
}

# REL:DELETE
#
# Deletes existing relationship override

order define REL:DELETE {
    title "Delete Group Relationship Override"
    options \
        -sendstates PREP

    parm id   key   "Groups"         -table  gui_rel_fg \
                                     -key    {f g}      \
                                     -labels {Of With}
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type rel

    returnOnError -final

    # NEXT, delete the record
    setundo [rel mutate delete $parms(id)]
}

# REL:UPDATE
#
# Updates existing override

order define REL:UPDATE {
    title "Update Group Relationship Override"
    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey id *}

    parm id   key   "Groups"         -table  gui_rel_fg \
                                     -key    {f g}      \
                                     -labels {Of With}
    parm rel  rel   "Relationship"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type rel
    prepare rel      -toupper            -type qrel

    returnOnError -final

    # NEXT, modify the curve
    setundo [rel mutate update [array get parms]]
}


# REL:UPDATE:MULTI
#
# Updates multiple existing relationship overrides

order define REL:UPDATE:MULTI {
    title "Update Multiple Relationship Overrides"
    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids  multi  "IDs"           -table gui_rel_fg \
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
        lappend undo [rel mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


