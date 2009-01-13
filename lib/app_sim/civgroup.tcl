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
    
    # info -- array of scalars
    #
    # undo       Command to undo the last operation, or ""

    typevariable info -array {
        undo {}
    }

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail civgroup "Initialized"
    }

    # reconfigure
    #
    # Refreshes the geoset with the current neighborhood data from
    # the database.
    
    typemethod reconfigure {} {
        # Clear the undo command
        set info(undo) {}
    }

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
    # Order Handling Routines

    # LastUndo
    #
    # Returns the undo command for the last mutator, or "" if none.

    typemethod LastUndo {} {
        set undo $info(undo)
        unset info(undo)

        return $undo
    }

    # CreateGroup parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g              The group's ID
    #    longname       The group's long name
    #    color          The group's color
    #
    # Creates a civilian group given the parms, which are presumed to be
    # valid.
    #
    # Creating a civilian group requires adding entries to the groups table.

    typemethod CreateGroup {parmdict} {
        dict with parmdict {
            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO groups(g,longname,color,gtype)
                VALUES($g,
                       $longname,
                       $color,
                       'CIV');
            }

            # NEXT, Set undo command.
            set info(undo) [list $type DeleteGroup $g]
            
            # NEXT, notify the app.
            notifier send ::civgroup <Entity> create $g
        }
    }

    # DeleteGroup g
    #
    # g     A group short name
    #
    # Deletes the group, including all references.

    typemethod DeleteGroup {g} {
        # FIRST, delete it.
        rdb eval {
            DELETE FROM groups    WHERE g=$g;
        }

        # NEXT, Clean up entities which refer to this civilian group,
        # i.e., either clear the field, or delete the entities.
        
        # TBD.

        # NEXT, Not undoable; clear the undo command
        set info(undo) {}

        notifier send ::civgroup <Entity> delete $g
    }


    # UpdateGroup g parmdict
    #
    # g            A group short name
    # parmdict     A dictionary of group parms
    #
    #    longname       A new long name, or ""
    #    color          A new color, or ""
    #
    # Updates a civgroup given the parms, which are presumed to be
    # valid.

    typemethod UpdateGroup {g parmdict} {
        # FIRST, get the undo information
        rdb eval {
            SELECT * FROM civgroups_view
            WHERE g=$g
        } undoData {
            unset undoData(*)
        }

        # NEXT, Update the group
        dict with parmdict {
            # FIRST, Put the group in the database
            rdb eval {
                UPDATE groups
                SET longname  = nonempty($longname,  longname),
                    color     = nonempty($color,     color)
                WHERE g=$g;
            } {}
        }

        # NEXT, Set the undo command
        set info(undo) [mytypemethod UpdateGroup $g [array get undoData]]

        # NEXT, notify the app.
        notifier send ::civgroup <Entity> update $g
    }
}

#-------------------------------------------------------------------
# Orders: GROUP:CIVILIAN:*

# GROUP:CIVILIAN:CREATE
#
# Creates new civilian groups.

order define ::civgroup GROUP:CIVILIAN:CREATE {
    title "Create Civilian Group"
    parms {
        g            {ptype text          label "ID"                }
        longname     {ptype text          label "Long Name"         }
        color        {ptype color         label "Color"             }
    }
} {
    # FIRST, prepare and validate the parameters
    prepare g          -trim -toupper -required -unused -type ident
    prepare longname   -normalize     -required -unused
    prepare color      -trim -tolower -required -type hexcolor

    returnOnError

    # NEXT, do cross-validation
    if {$parms(g) eq $parms(longname)} {
        reject longname "longname must not be identical to ID"
    }

    returnOnError

    # NEXT, create the group
    $type CreateGroup [array get parms]

    setundo [$type LastUndo]
}

# GROUP:CIVILIAN:DELETE

order define ::civgroup GROUP:CIVILIAN:DELETE {
    title "Delete Civilian Group"
    parms {
        g {ptype civgroup label "Group"}
    }
} {
    # FIRST, prepare the parameters
    prepare g -trim -toupper -required -type civgroup

    returnOnError

    # TBD: It isn't clear whether we will delete all entities that depend on
    # this group, or whether all such entities must already have been
    # deleted.  In the latter case, we must verify that we can safely 
    # delete this group; but then, we can reasonably undo the deletion,
    # and so we won't need to do the following verification.

    # NEXT, if this is done from the GUI verify this.
    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     GROUP:CIVILIAN:DELETE                    \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       "This order cannot be undone.  Are you sure you really want to delete this group?"]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, raise the group
    $type DeleteGroup $parms(g)

    # NEXT, this order is not undoable.
}


# GROUP:CIVILIAN:UPDATE
#
# Updates existing groups.

order define ::civgroup GROUP:CIVILIAN:UPDATE {
    title "Update Civilian Group"
    table civgroups_view
    keys  g
    parms {
        g            {ptype civgroup      label "ID"                }
        longname     {ptype text          label "Long Name"         }
        color        {ptype color         label "Color"             }
    }
} {
    # FIRST, prepare the parameters
    prepare g         -trim -toupper  -required -type civgroup

    set oldname [rdb onecolumn {SELECT longname FROM groups WHERE g=$parms(g)}]

    prepare longname  -normalize      -oldvalue $oldname -unused
    prepare color     -trim -tolower  -type hexcolor

    returnOnError

    # NEXT, modify the group
    set g $parms(g)
    unset parms(g)

    $type UpdateGroup $g [array get parms]

    setundo [$type LastUndo]
}

