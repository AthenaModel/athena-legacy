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
    #    shape          The group's unit shape (eunitshape(n))
    #    orgtype          The group's eorgtype
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
                INSERT INTO groups(g,longname,color,shape,symbol,gtype)
                VALUES($g,
                       $longname,
                       $color,
                       $shape,
                       'organization',
                       'ORG');

                INSERT INTO orggroups(g,orgtype,rollup_weight,effects_factor)
                VALUES($g,
                       $orgtype,
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
        rdb eval {SELECT * FROM groups    WHERE g=$g} row1 { unset row1(*) }
        rdb eval {SELECT * FROM orggroups WHERE g=$g} row2 { unset row2(*) }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM groups    WHERE g=$g;
            DELETE FROM orggroups WHERE g=$g;
        }

        # NEXT, notify the app
        notifier send ::orggroup <Entity> delete $g

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row1] [array get row2]]
    }

    # Restore gdict odict
    #
    # gdict    row dict for deleted entity in groups
    # odict    row dict for deleted entity in orggroups
    #
    # Restores the rows to the database

    typemethod Restore {gdict odict} {
        rdb insert groups    $gdict
        rdb insert orggroups $odict
        notifier send ::orggroup <Entity> create [dict get $gdict g]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g                A group short name
    #    longname         A new long name, or ""
    #    color            A new color, or ""
    #    shape            A new shape, or ""
    #    orgtype          A new eorgtype, or ""
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
                    color     = nonempty($color,     color),
                    shape     = nonempty($shape,     shape)
                WHERE g=$g;

                UPDATE orggroups
                SET orgtype        = nonempty($orgtype,        orgtype),
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
    options -sendstates PREP

    parm g              text  "ID"
    parm longname       text  "Long Name"
    parm color          color "Color"
    parm shape          enum  "Unit Shape"    -type eunitshape -defval NEUTRAL
    parm orgtype        enum  "Org. Type"     -type eorgtype
    parm rollup_weight  text  "RollupWeight"  -defval 1.0
    parm effects_factor text  "EffectsFactor" -defval 1.0
} {
    # FIRST, prepare and validate the parameters
    prepare g              -toupper   -required -unused -type ident
    prepare longname       -normalize -required -unused
    prepare color          -tolower   -required -type hexcolor
    prepare shape          -toupper   -required -type eunitshape
    prepare orgtype        -toupper   -required -type eorgtype
    prepare rollup_weight             -required -type weight
    prepare effects_factor            -required -type weight

    returnOnError

    # NEXT, do cross-validation
    if {$parms(g) eq $parms(longname)} {
        reject longname "longname must not be identical to ID"
    }

    returnOnError

    # NEXT, create the group and dependent entities
    lappend undo [$type mutate create [array get parms]]
    lappend undo [scenario mutate reconcile]
    
    setundo [join $undo \n]
}

# GROUP:ORGANIZATION:DELETE

order define ::orggroup GROUP:ORGANIZATION:DELETE {
    title "Delete Organization Group"
    options -sendstates PREP -table gui_orggroups

    parm g  key "Group" -tags group
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
    lappend undo [scenario mutate reconcile]
    
    setundo [join $undo \n]
}


# GROUP:ORGANIZATION:UPDATE
#
# Updates existing groups.

order define ::orggroup GROUP:ORGANIZATION:UPDATE {
    title "Update Organization Group"
    options -sendstates PREP -table gui_orggroups

    parm g              key   "ID"            -tags group
    parm longname       text  "Long Name"
    parm color          color "Color"
    parm shape          enum  "Unit Shape"    -type eunitshape
    parm orgtype        enum  "Org. Type"     -type eorgtype
    parm rollup_weight  text  "RollupWeight"  
    parm effects_factor text  "EffectsFactor" 
} {
    # FIRST, prepare the parameters
    prepare g              -toupper  -required -type orggroup

    set oldname [rdb onecolumn {SELECT longname FROM groups WHERE g=$parms(g)}]

    prepare longname       -normalize      -oldvalue $oldname -unused
    prepare color          -tolower  -type hexcolor
    prepare shape          -toupper  -type eunitshape
    prepare orgtype        -toupper  -type eorgtype
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
    options -sendstates PREP -table gui_orggroups

    parm ids            multi "Groups"
    parm color          color "Color"
    parm shape          enum  "Unit Shape"    -type eunitshape
    parm orgtype        enum  "Org. Type"     -type eorgtype
    parm rollup_weight  text  "RollupWeight"  
    parm effects_factor text  "EffectsFactor" 
} {
    # FIRST, prepare the parameters
    prepare ids            -toupper  -required -listof orggroup
    prepare color          -tolower            -type   hexcolor
    prepare shape          -toupper            -type   eunitshape
    prepare orgtype        -toupper            -type   eorgtype
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



