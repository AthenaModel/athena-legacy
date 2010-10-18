#-----------------------------------------------------------------------
# TITLE:
#    civgroup.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Civilian Group Manager
#
#    This module is responsible for managing civilian groups and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type civgroup {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # TBD

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of neighborhood names

    typemethod names {} {
        set names [rdb eval {
            SELECT g FROM civgroups_view
        }]
    }


    # validate g
    #
    # g         Possibly, a civilian group short name.
    #
    # Validates a civilian group short name

    typemethod validate {g} {
        if {![rdb exists {SELECT g FROM civgroups_view WHERE g=$g}]} {
            set names [join [civgroup names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid civilian group, $msg"
        }

        return $g
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
    #    g              The group's ID
    #    longname       The group's long name
    #    color          The group's color
    #    shape          The group's unit shape (eunitshape(n))
    #
    # Creates a civilian group given the parms, which are presumed to be
    # valid.
    #
    # Creating a civilian group requires adding entries to the groups table.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO groups(g,longname,color,shape,symbol,gtype)
                VALUES($g,
                       $longname,
                       $color,
                       $shape,
                       'civilian',
                       'CIV');
            }

            # NEXT, notify the app.
            notifier send ::civgroup <Entity> create $g

            # NEXT, Return undo command.
            return [list $type mutate delete $g]
        }
    }

    # mutate delete g
    #
    # g     A group short name
    #
    # Deletes the group.

    typemethod {mutate delete} {g} {
        # FIRST, get the undo information
        rdb eval {
            SELECT * FROM civgroups_view
            WHERE g=$g
        } row {
            unset row(*)
        }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM groups WHERE g=$g;
        }

        # NEXT, notify the app
        notifier send ::civgroup <Entity> delete $g

        # NEXT, return aggregate undo script.
        return [mytypemethod Restore [array get row]]
    }


    # Restore parmdict
    #
    # parmdict     row dict for deleted entity
    #
    # Restores the entity in the database

    typemethod Restore {parmdict} {
        rdb insert groups $parmdict
        notifier send ::civgroup <Entity> create [dict get $parmdict g]
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g              A group short name
    #    longname       A new long name, or ""
    #    color          A new color, or ""
    #    shape          A new shape, or ""
    #
    # Updates a civgroup given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM civgroups_view
                WHERE g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE groups
                SET longname  = nonempty($longname,  longname),
                    color     = nonempty($color,     color),
                    shape     = nonempty($shape,     shape)
                WHERE g=$g;
            } {}

            # NEXT, notify the app.
            notifier send ::civgroup <Entity> update $g

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}

#-----------------------------------------------------------------------
# Orders: GROUP:CIVILIAN:*

# GROUP:CIVILIAN:CREATE
#
# Creates new civilian groups.

order define GROUP:CIVILIAN:CREATE {
    title "Create Civilian Group"

    options -sendstates PREP

    parm g         text   "Group"
    parm longname  text   "Long Name"
    parm color     color  "Color"
    parm shape     enum   "Unit Shape" -type eunitshape -defval NEUTRAL
} {
    # FIRST, prepare and validate the parameters
    prepare g        -toupper   -required -unused -type ident
    prepare longname -normalize -required -unused
    prepare color    -tolower   -required         -type hexcolor
    prepare shape    -toupper   -required         -type eunitshape

    returnOnError

    # NEXT, do cross-validation
    if {$parms(g) eq $parms(longname)} {
        reject longname "longname must not be identical to ID"
    }

    returnOnError -final

    # NEXT, create the group and dependent entities
    lappend undo [civgroup mutate create [array get parms]]
    lappend undo [scenario mutate reconcile]

    setundo [join $undo \n]
}

# GROUP:CIVILIAN:DELETE

order define GROUP:CIVILIAN:DELETE {
    title "Delete Civilian Group"
    options -sendstates PREP

    parm g  key  "Group"  -tags group -table civgroups_view -key g
} {
    # FIRST, prepare the parameters
    prepare g -toupper -required -type civgroup

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     GROUP:CIVILIAN:DELETE            \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this group and all of the
                            entities that depend upon it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the group and dependent entities
    lappend undo [civgroup mutate delete $parms(g)]
    lappend undo [scenario mutate reconcile]

    setundo [join $undo \n]
}


# GROUP:CIVILIAN:UPDATE
#
# Updates existing groups.

order define GROUP:CIVILIAN:UPDATE {
    title "Update Civilian Group"
    options \
        -sendstates PREP                             \
        -refreshcmd {orderdialog refreshForKey g *}

    parm g         key    "Group"         \
        -table civgroups_view -key g -tags group
    parm longname  text   "Long Name"
    parm color     color  "Color"
    parm shape     enum   "Unit Shape" -type eunitshape
} {
    # FIRST, prepare the parameters
    prepare g         -toupper  -required -type civgroup

    set oldname [rdb onecolumn {SELECT longname FROM groups WHERE g=$parms(g)}]

    prepare longname  -normalize      -oldvalue $oldname -unused
    prepare color     -tolower  -type hexcolor
    prepare shape     -toupper  -type eunitshape

    returnOnError -final

    # NEXT, modify the group
    setundo [civgroup mutate update [array get parms]]
}

order define GROUP:CIVILIAN:UPDATE:MULTI {
    title "Update Multiple Civilian Groups"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids    multi  "Groups"  -table gui_civgroups -key g
    parm color  color  "Color"
    parm shape  enum   "Unit Shape" -type eunitshape
} {
    # FIRST, prepare the parameters
    prepare ids    -toupper -required -listof civgroup
    prepare color  -tolower           -type   hexcolor
    prepare shape  -toupper           -type   eunitshape

    returnOnError -final

    # NEXT, clear the other parameters expected by the mutator
    prepare longname

    # NEXT, modify the group
    set undo [list]

    foreach parms(g) $parms(ids) {
        lappend undo [civgroup mutate update [array get parms]]
    }

    setundo [join $undo \n]
}

