#-----------------------------------------------------------------------
# TITLE:
#    orggroup.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Organization Group Manager
#
#    This module is responsible for managing organization groups and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type orggroup {
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
        log detail orggroup "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module data from the database.
    
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
            SELECT g FROM orggroups 
        }]
    }


    # validate g
    #
    # g         Possibly, a organization group short name.
    #
    # Validates a organization group short name

    typemethod validate {g} {
        if {![rdb exists {SELECT g FROM orggroups WHERE g=$g}]} {
            set names [join [orggroup names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid organization group, $msg"
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
    #    g                The group's ID
    #    longname         The group's long name
    #    color            The group's color
    #    orgtype          The group's eorgtype
    #    medical          The group's medical capability flag
    #    engineer         The group's engineer capability flag
    #    support          The group's support capability flag
    #    rollup_weight    The group's rollup weight (JRAM)
    #    effects_factor   The group's indirect effects factor (JRAM)
    #
    # Creates a organization group given the parms, which are presumed to be
    # valid.
    #
    # Creating a organization group requires adding entries to the groups and
    # orggroups tables.

    typemethod CreateGroup {parmdict} {
        dict with parmdict {
            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO groups(g,longname,color,gtype)
                VALUES($g,
                       $longname,
                       $color,
                       'ORG');

                INSERT INTO orggroups(g,orgtype,medical,engineer,support,
                                      rollup_weight,effects_factor)
                VALUES($g,
                       $orgtype,
                       $medical,
                       $engineer,
                       $support,
                       $rollup_weight,
                       $effects_factor);
            }

            # NEXT, Set the undo command
            set info(undo) [list $type DeleteGroup $g]
            
            # NEXT, notify the app.
            notifier send ::orggroup <Entity> create $g
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
            DELETE FROM orggroups WHERE g=$g;
        }

        # NEXT, Clean up entities which refer to this organization group,
        # i.e., either clear the field, or delete the entities.
        
        # TBD.

        # NEXT, Not undoable; clear the undo command
        set info(undo) {}

        notifier send ::orggroup <Entity> delete $g
    }


    # UpdateGroup g parmdict
    #
    # g            A group short name
    # parmdict     A dictionary of group parms
    #
    #    longname         A new long name, or ""
    #    color            A new color, or ""
    #    orgtype          A new eorgtype, or ""
    #    medical          A new medical flag, or ""
    #    engineer         A new engineer flag, or ""
    #    support          A new support flag, or ""
    #    rollup_weight    A new rollup weight, or ""
    #    effects_factor   A new effects factor, or ""
    #
    # Updates a orggroup given the parms, which are presumed to be
    # valid.

    typemethod UpdateGroup {g parmdict} {
        # FIRST, get the undo information
        rdb eval {
            SELECT * FROM orggroups_view
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

                UPDATE orggroups
                SET orgtype        = nonempty($orgtype,        orgtype),
                    medical        = nonempty($medical,        medical),
                    engineer       = nonempty($engineer,       engineer),
                    support        = nonempty($support,        support),
                    rollup_weight  = nonempty($rollup_weight,  rollup_weight),
                    effects_factor = nonempty($effects_factor, effects_factor)
                WHERE g=$g
            } {}
        }

        # NEXT, Set the undo command
        set info(undo) [mytypemethod UpdateGroup $g [array get undoData]]

        # NEXT, notify the app.
        notifier send ::orggroup <Entity> update $g
    }
}

#-------------------------------------------------------------------
# Orders: GROUP:ORGANIZATION:*

# GROUP:ORGANIZATION:CREATE
#
# Creates new organization groups.

order define ::orggroup GROUP:ORGANIZATION:CREATE {
    title "Create Organization Group"
    parms {
        g              {ptype text    label "ID"            }
        longname       {ptype text    label "Long Name"     }
        color          {ptype color   label "Color"         }
        orgtype        {ptype orgtype label "Org. Type"     }
        medical        {ptype yesno   label "Medical?"      }
        engineer       {ptype yesno   label "Engineer?"     }
        support        {ptype yesno   label "Support?"      }
        rollup_weight  {ptype weight  label "RollupWeight"  defval 1.0}
        effects_factor {ptype weight  label "EffectsFactor" defval 1.0}
    }
} {
    # FIRST, prepare and validate the parameters
    prepare g              -trim -toupper -required -unused -type ident
    prepare longname       -normalize     -required -unused
    prepare color          -trim -tolower -required -type hexcolor
    prepare orgtype        -trim -toupper -required -type eorgtype
    prepare medical        -trim          -required -type boolean
    prepare engineer       -trim          -required -type boolean
    prepare support        -trim          -required -type boolean
    prepare rollup_weight  -trim          -required -type weight
    prepare effects_factor -trim          -required -type weight

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

# GROUP:ORGANIZATION:DELETE

order define ::orggroup GROUP:ORGANIZATION:DELETE {
    title "Delete Organization Group"
    parms {
        g {ptype orggroup label "Group"}
    }
} {
    # FIRST, prepare the parameters
    prepare g -trim -toupper -required -type orggroup

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
                        -ignoretag     GROUP:ORGANIZATION:DELETE                    \
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


# GROUP:ORGANIZATION:UPDATE
#
# Updates existing groups.

order define ::orggroup GROUP:ORGANIZATION:UPDATE {
    title "Update Organization Group"
    table gui_orggroups
    keys  g
    parms {
        g              {ptype orggroup  label "ID"            }
        longname       {ptype text      label "Long Name"     }
        color          {ptype color     label "Color"         }
        orgtype        {ptype orgtype   label "Org. Type"     }
        medical        {ptype yesno     label "Medical?"      }
        engineer       {ptype yesno     label "Engineer?"     }
        support        {ptype yesno     label "Support?"      }
        rollup_weight  {ptype weight    label "RollupWeight"  }
        effects_factor {ptype weight    label "EffectsFactor" }
    }
} {
    # FIRST, prepare the parameters
    prepare g              -trim -toupper  -required -type orggroup

    set oldname [rdb onecolumn {SELECT longname FROM groups WHERE g=$parms(g)}]

    prepare longname       -normalize      -oldvalue $oldname -unused
    prepare color          -trim -tolower  -type hexcolor
    prepare orgtype        -trim -toupper  -type eorgtype
    prepare medical        -trim           -type boolean
    prepare engineer       -trim           -type boolean
    prepare support        -trim           -type boolean
    prepare rollup_weight  -trim           -type weight
    prepare effects_factor -trim           -type weight

    returnOnError

    # NEXT, modify the group
    set g $parms(g)
    unset parms(g)

    $type UpdateGroup $g [array get parms]

    setundo [$type LastUndo]
}

