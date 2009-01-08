#-----------------------------------------------------------------------
# TITLE:
#    frcgroup.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Force Group Manager
#
#    This module is responsible for managing force groups and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type frcgroup {
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
        log detail frcgroup "Initialized"
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
            SELECT g FROM frcgroups 
        }]
    }


    # validate g
    #
    # g         Possibly, a force group short name.
    #
    # Validates a force group short name

    typemethod validate {g} {
        if {![rdb exists {SELECT g FROM frcgroups WHERE g=$g}]} {
            set names [join [frcgroup names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid force group, $msg"
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
    #    forcetype      The group's eforcetype
    #    local          The group's local flag
    #    coalition      The group's coalition flag
    #
    # Creates a force group given the parms, which are presumed to be
    # valid.
    #
    # Creating a force group requires adding entries to the groups and
    # frcgroups tables.

    typemethod CreateGroup {parmdict} {
        dict with parmdict {
            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO groups(g,longname,color,gtype)
                VALUES($g,
                       $longname,
                       $color,
                       'FRC');

                INSERT INTO frcgroups(g,forcetype,local,coalition)
                VALUES($g,
                       $forcetype,
                       $local,
                       $coalition);
            }

            # NEXT, Not yet undoable; clear the undo command
            set info(undo) [list $type DeleteGroup $g]
            
            # NEXT, notify the app.
            notifier send ::frcgroup <Entity> create $g
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
            DELETE FROM frcgroups WHERE g=$g;
        }

        # NEXT, Clean up entities which refer to this force group,
        # i.e., either clear the field, or delete the entities.
        
        # TBD.

        # NEXT, Not undoable; clear the undo command
        set info(undo) {}

        notifier send ::frcgroup <Entity> delete $g
    }


    # UpdateGroup g parmdict
    #
    # g            A group short name
    # parmdict     A dictionary of group parms
    #
    #    longname       A new long name, or ""
    #    color          A new color, or ""
    #    forcetype      A new eforcetype, or ""
    #    local          A new local flag, or ""
    #    coalition      A new coalition flag, or ""
    #
    # Updates a frcgroup given the parms, which are presumed to be
    # valid.

    typemethod UpdateGroup {g parmdict} {
        # FIRST, get the undo information
        rdb eval {
            SELECT longname, color, forcetype, local, coalition
            FROM frcgroups_view
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

                UPDATE frcgroups
                SET forcetype = nonempty($forcetype, forcetype),
                    local     = nonempty($local,     local),
                    coalition = nonempty($coalition, coalition)
                WHERE g=$g
            } {}
        }

        # NEXT, Not undoable; clear the undo command
        set info(undo) [mytypemethod UpdateGroup $g [array get row]]

        # NEXT, notify the app.
        notifier send ::frcgroup <Entity> update $g
    }
}

#-------------------------------------------------------------------
# Orders: GROUP:FORCE:*

# GROUP:FORCE:CREATE
#
# Creates new force groups.

order define ::frcgroup GROUP:FORCE:CREATE {
    title "Create Force Group"
    parms {
        g            {ptype text          label "ID"                }
        longname     {ptype text          label "Long Name"         }
        color        {ptype color         label "Color"             }
        forcetype    {ptype forcetype     label "Force Type"        }
        local        {ptype yesno         label "Local Group?"      }
        coalition    {ptype yesno         label "Coalition Member?" }
    }
} {
    # FIRST, prepare the parameters
    prepare g             -trim      -toupper -required
    prepare longname      -normalize          -required 
    prepare color         -trim      -tolower -required
    prepare forcetype     -trim      -toupper -required
    prepare local         -trim      -toupper -required
    prepare coalition     -trim      -toupper -required

    returnOnError

    # NEXT, validate the parameters

    if {[valid g] && [rdb exists {
        SELECT g FROM groups 
        WHERE g        = $parms(g)
        OR    longname = $parms(g)
    }]} {
        reject g "A group with this name already exists"
    }

    validate g {
        ident validate $parms(g)
    }
    
    # longname
    if {[valid longname] && [rdb exists {
        SELECT g FROM groups 
        WHERE g        = $parms(longname)
        OR    longname = $parms(longname)
    }]} {
        reject longname "A group with this name already exists"
    }

    # color
    validate color {
        set parms(color) [hexcolor validate $parms(color)]
    }

    # forcetype
    validate forcetype {
        set parms(forcetype) [eforcetype validate $parms(forcetype)]
    }

    # local
    validate local {
        set parms(local) [boolean validate $parms(local)]
    }

    # coalition
    validate coalition {
        set parms(coalition) [boolean validate $parms(coalition)]
    }
    
    returnOnError

    # NEXT, create the group
    $type CreateGroup [array get parms]

    setundo [$type LastUndo]
}

# GROUP:FORCE:DELETE

order define ::frcgroup GROUP:FORCE:DELETE {
    title "Delete Force Group"
    parms {
        g {ptype frcgroup label "Group"}
    }
} {
    # FIRST, prepare the parameters
    prepare g -trim -toupper -required 

    # Validate
    validate g { frcgroup validate $parms(g) }

    # TBD: Verify that we can safely delete this.  We can't have
    # any entities whose identity depends on this group.

    returnOnError

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     GROUP:FORCE:DELETE                    \
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


# GROUP:FORCE:UPDATE
#
# Updates existing groups.

order define ::frcgroup GROUP:FORCE:UPDATE {
    title "Update Force Group"
    table gui_frcgroups
    keys  g
    parms {
        g            {ptype frcgroup      label "ID"                }
        longname     {ptype text          label "Long Name"         }
        color        {ptype color         label "Color"             }
        forcetype    {ptype forcetype     label "Force Type"        }
        local        {ptype yesno         label "Local Group?"      }
        coalition    {ptype yesno         label "Coalition Member?" }
    }
} {
    # FIRST, prepare the parameters
    prepare g             -trim      -toupper -required
    prepare longname      -normalize
    prepare color         -trim      -tolower
    prepare forcetype     -trim      -toupper
    prepare local         -trim      -toupper
    prepare coalition     -trim      -toupper

    # NEXT, validate the group
    validate g { frcgroup validate $parms(g) }

    # NEXT, validate the other parameters

    # longname
    if {$parms(longname) ne ""} {
        set g ""

        rdb eval {
            SELECT g FROM groups
            WHERE g        = $parms(longname)
            OR    longname = $parms(longname)
        } {}

        if {$g ne "" && $g ne $parms(g)} {
            reject longname "A group with this name already exists"
        }
    }

    # color
    validate color {
        set parms(color) [hexcolor validate $parms(color)]
    }

    # forcetype
    validate forcetype {
        set parms(forcetype) [eforcetype validate $parms(forcetype)]
    }

    # local
    validate local {
        eyesno validate $parms(local)

        # Convert to integer
        set parms(local) [expr {!!$parms(local)}]
    }

    # coalition
    validate coalition {
        eyesno validate $parms(coalition)

        # Convert to integer
        set parms(coalition) [expr {!!$parms(coalition)}]
    }

    returnOnError

    # NEXT, modify the group
    set g $parms(g)
    unset parms(g)

    $type UpdateGroup $g [array get parms]

    setundo [$type LastUndo]
}

