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

    # Unit Symbols, by force type

    typevariable symbols -array {
        REGULAR       infantry
        IRREGULAR     {irregular infantry}
        PARAMILITARY  {infantry police}
        POLICE        police
        CRIMINAL      criminal
    }

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        log detail frcgroup "Initialized"
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
    #    forcetype      The group's eforcetype
    #    local          The group's local flag
    #    coalition      The group's coalition flag
    #
    # Creates a force group given the parms, which are presumed to be
    # valid.
    #
    # Creating a force group requires adding entries to the groups and
    # frcgroups tables.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, get the symbol
            set symbol $symbols($forcetype)

            # NEXT, Put the group in the database
            rdb eval {
                INSERT INTO groups(g,longname,color,shape,symbol,gtype)
                VALUES($g,
                       $longname,
                       $color,
                       $shape,
                       $symbol,
                       'FRC');

                INSERT INTO frcgroups(g,forcetype,local,coalition)
                VALUES($g,
                       $forcetype,
                       $local,
                       $coalition);
            }

            # NEXT, notify the app.
            notifier send ::frcgroup <Entity> create $g

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
        rdb eval {SELECT * FROM frcgroups WHERE g=$g} row2 { unset row2(*) }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM groups    WHERE g=$g;
            DELETE FROM frcgroups WHERE g=$g;
        }

        # NEXT, notify the app
        notifier send ::frcgroup <Entity> delete $g

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row1] [array get row2]]
    }

    # Restore gdict fdict
    #
    # gdict    row dict for deleted entity in groups
    # fdict    row dict for deleted entity in frcgroups
    #
    # Restores the rows to the database

    typemethod Restore {gdict fdict} {
        rdb insert groups    $gdict
        rdb insert frcgroups $fdict
        notifier send ::frcgroup <Entity> create [dict get $gdict g]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g              A group short name
    #    longname       A new long name, or ""
    #    color          A new color, or ""
    #    shape          A new shape, or ""
    #    forcetype      A new eforcetype, or ""
    #    local          A new local flag, or ""
    #    coalition      A new coalition flag, or ""
    #
    # Updates a frcgroup given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM frcgroups_view
                WHERE g=$g
            } undoData {
                unset undoData(*)
            }
            
            # NEXT, get the new unit symbol, if need be.
            if {$forcetype ne ""} {
                set symbol $symbols($forcetype)
            } else {
                set symbol ""
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE groups
                SET longname  = nonempty($longname,  longname),
                    color     = nonempty($color,     color),
                    shape     = nonempty($shape,     shape),
                    symbol    = nonempty($symbol,    symbol)
                WHERE g=$g;

                UPDATE frcgroups
                SET forcetype = nonempty($forcetype, forcetype),
                    local     = nonempty($local,     local),
                    coalition = nonempty($coalition, coalition)
                WHERE g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::frcgroup <Entity> update $g

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}

#-------------------------------------------------------------------
# Orders: GROUP:FORCE:*

# GROUP:FORCE:CREATE
#
# Creates new force groups.

order define ::frcgroup GROUP:FORCE:CREATE {
    title "Create Force Group"

    parm g          text  "ID"
    parm longname   text  "Long Name"
    parm color      color "Color"
    parm shape      enum  "Unit Shape"        -type eunitshape -defval NEUTRAL
    parm forcetype  enum  "Force Type"        -type eforcetype
    parm local      enum  "Local Group?"      -type eyesno
    parm coalition  enum  "Coalition Member?" -type eyesno
} {
    # FIRST, prepare and validate the parameters
    prepare g          -toupper   -required -unused -type ident
    prepare longname   -normalize -required -unused
    prepare color      -tolower   -required -type hexcolor
    prepare shape      -toupper   -required -type eunitshape
    prepare forcetype  -toupper   -required -type eforcetype
    prepare local      -toupper   -required -type boolean
    prepare coalition  -toupper   -required -type boolean

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

# GROUP:FORCE:DELETE

order define ::frcgroup GROUP:FORCE:DELETE {
    title "Delete Force Group"
    options -table gui_frcgroups

    parm g  key "Group" -tags group
} {
    # FIRST, prepare the parameters
    prepare g -toupper -required -type frcgroup

    returnOnError

    # NEXT, make sure the user knows what he is getting into.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     GROUP:FORCE:DELETE                    \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this group, along
                            with all of the entities that depend upon it?
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


# GROUP:FORCE:UPDATE
#
# Updates existing groups.

order define ::frcgroup GROUP:FORCE:UPDATE {
    title "Update Force Group"
    options -table gui_frcgroups

    parm g          key   "ID"                 -tags group
    parm longname   text  "Long Name"
    parm color      color "Color"
    parm shape      enum  "Unit Shape"         -type eunitshape
    parm forcetype  enum  "Force Type"         -type eforcetype
    parm local      enum  "Local Group?"       -type eyesno
    parm coalition  enum  "Coalition Member?"  -type eyesno
} {
    # FIRST, prepare the parameters
    prepare g         -toupper  -required -type frcgroup

    set oldname [rdb onecolumn {SELECT longname FROM groups WHERE g=$parms(g)}]

    prepare longname  -normalize -oldvalue $oldname -unused
    prepare color     -tolower   -type hexcolor
    prepare shape     -toupper   -type eunitshape
    prepare forcetype -toupper   -type eforcetype
    prepare local     -toupper   -type boolean
    prepare coalition -toupper   -type boolean

    returnOnError

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}

# GROUP:FORCE:UPDATE:MULTI
#
# Updates multiple groups.

order define ::frcgroup GROUP:FORCE:UPDATE:MULTI {
    title "Update Multiple Force Groups"
    options -table gui_frcgroups

    parm ids        multi "Groups"
    parm color      color "Color"
    parm shape      enum  "Unit Shape"         -type eunitshape
    parm forcetype  enum  "Force Type"         -type eforcetype
    parm local      enum  "Local Group?"       -type eyesno
    parm coalition  enum  "Coalition Member?"  -type eyesno
} {
    # FIRST, prepare the parameters
    prepare ids       -toupper  -required -listof frcgroup
    prepare color     -tolower            -type   hexcolor
    prepare shape     -toupper            -type   eunitshape
    prepare forcetype -toupper            -type   eforcetype
    prepare local     -toupper            -type   boolean
    prepare coalition -toupper            -type   boolean

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






