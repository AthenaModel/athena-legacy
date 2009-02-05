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

    # TBD

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail orggroup "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module's in-memory data from the database.
    
    typemethod reconfigure {} {
        # Nothing to do
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

    typemethod {mutate create} {parmdict} {
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

            # NEXT, notify the app.
            notifier send ::orggroup <Entity> create $g

            # NEXT, Return the undo command
            return [mytypemethod mutate delete $g]
        }
    }


    # mutate delete g
    #
    # g     A group short name
    #
    # Deletes the group, including all references.

    typemethod {mutate delete} {g} {
        # FIRST, get the undo information
        rdb eval {
            SELECT * FROM orggroups_view
            WHERE g=$g
        } undoData {
            unset undoData(*)
        }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM groups    WHERE g=$g;
            DELETE FROM orggroups WHERE g=$g;
        }

        # NEXT, notify the app
        notifier send ::orggroup <Entity> delete $g

        # NEXT, Return the undo script
        return [mytypemethod mutate create [array get undoData]]

    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g                A group short name
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

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM orggroups_view
                WHERE g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
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

            # NEXT, notify the app.
            notifier send ::orggroup <Entity> update $g

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
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
    prepare g              -toupper -required -unused -type ident
    prepare longname       -normalize     -required -unused
    prepare color          -tolower -required -type hexcolor
    prepare orgtype        -toupper -required -type eorgtype
    prepare medical                 -required -type boolean
    prepare engineer                -required -type boolean
    prepare support                 -required -type boolean
    prepare rollup_weight           -required -type weight
    prepare effects_factor          -required -type weight

    returnOnError

    # NEXT, do cross-validation
    if {$parms(g) eq $parms(longname)} {
        reject longname "longname must not be identical to ID"
    }

    returnOnError

    # NEXT, create the group and dependent entities
    lappend undo [$type mutate create [array get parms]]
    lappend undo [sat mutate reconcile]
    lappend undo [rel mutate reconcile]
    
    setundo [join $undo \n]
}

# GROUP:ORGANIZATION:DELETE

order define ::orggroup GROUP:ORGANIZATION:DELETE {
    title "Delete Organization Group"
    table gui_orggroups
    parms {
        g {ptype key label "Group"}
    }
} {
    # FIRST, prepare the parameters
    prepare g -toupper -required -type orggroup

    returnOnError

    # NEXT, make sure the user knows what he is getting into.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     GROUP:ORGANIZATION:DELETE        \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you really want to delete this 
                            group, along with all of the entities that 
                            depend upon it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the group and dependent entities
    lappend undo [$type mutate delete $parms(g)]
    lappend undo [sat mutate reconcile]
    lappend undo [rel mutate reconcile]
    
    setundo [join $undo \n]
}


# GROUP:ORGANIZATION:UPDATE
#
# Updates existing groups.

order define ::orggroup GROUP:ORGANIZATION:UPDATE {
    title "Update Organization Group"
    table gui_orggroups
    parms {
        g              {ptype key       label "ID"            }
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
    prepare g              -toupper  -required -type orggroup

    set oldname [rdb onecolumn {SELECT longname FROM groups WHERE g=$parms(g)}]

    prepare longname       -normalize      -oldvalue $oldname -unused
    prepare color          -tolower  -type hexcolor
    prepare orgtype        -toupper  -type eorgtype
    prepare medical                  -type boolean
    prepare engineer                 -type boolean
    prepare support                  -type boolean
    prepare rollup_weight            -type weight
    prepare effects_factor           -type weight

    returnOnError

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}


# GROUP:ORGANIZATION:UPDATE:MULTI
#
# Updates multiple groups.

order define ::orggroup GROUP:ORGANIZATION:UPDATE:MULTI {
    title "Update Multiple Organization Groups"
    multi yes
    table gui_orggroups
    parms {
        ids            {ptype ids       label "Groups"        }
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
    prepare ids            -toupper  -required -listof orggroup
    prepare color          -tolower            -type   hexcolor
    prepare orgtype        -toupper            -type   eorgtype
    prepare medical                            -type   boolean
    prepare engineer                           -type   boolean
    prepare support                            -type   boolean
    prepare rollup_weight                      -type   weight
    prepare effects_factor                     -type   weight

    returnOnError

    # NEXT, clear the other parameters expected by the mutator
    prepare longname

    # NEXT, modify the group
    set undo [list]

    foreach parms(g) $parms(ids) {
        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}



