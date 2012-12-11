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
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of neighborhood names

    typemethod names {} {
        return [rdb eval {
            SELECT g FROM civgroups_view
        }]
    }


    # namedict
    #
    # Returns ID/longname dictionary

    typemethod namedict {} {
        return [rdb eval {
            SELECT g, longname FROM civgroups_view ORDER BY g
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

    # gInN g n
    #
    # g       A group ID
    # n       A neighborhood ID
    #
    # Returns 1 if g resides in n, and 0 otherwise.

    typemethod gInN {g n} {
        rdb exists {
            SELECT * FROM civgroups WHERE g=$g AND n=$n
        }
    }

    # gIn n
    #
    # n      A neighborhood ID
    #
    # Returns a list of the civ groups that reside in the neighborhood.

    typemethod gIn {n} {
        rdb eval {
            SELECT g FROM civgroups WHERE n=$n
            ORDER BY g
        }
    }



    # Type Method: getg
    #
    # Retrieves a row dictionary, or a particular column value, from
    # civgroups.
    #
    # Syntax:
    #   getg _g ?parm?_
    #
    #   g    - A group in the neighborhood
    #   parm - A civgroups column name

    typemethod getg {g {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM civgroups_view WHERE g=$g} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
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
    #    n              The group's nbhood
    #    longname       The group's long name
    #    color          The group's color
    #    shape          The group's unit shape (eunitshape(n))
    #    demeanor       The group's demeanor (edemeanor(n))
    #    basepop        The group's base population
    #    sa_flag        The group's subsistence agriculture flag. 
    #
    # Creates a civilian group given the parms, which are presumed to be
    # valid.
    #
    # Creating a civilian group requires adding entries to the groups table.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, create a bsystem entity
            bsystem entity add $g

            # NEXT, Put the group in the database
            rdb eval {
                INSERT INTO 
                groups(g, longname, color, shape, symbol, demeanor,
                       rel_entity, gtype)
                VALUES($g,
                       $longname,
                       $color,
                       $shape,
                       'civilian',
                       $demeanor,
                       $g,
                       'CIV');

                INSERT INTO
                civgroups(g,n,basepop,sa_flag)
                VALUES($g,
                       $n,
                       $basepop,
                       $sa_flag);

                INSERT INTO demog_g(g)
                VALUES($g);

                INSERT INTO sat_gc(g,c)
                SELECT $g, c FROM concerns;

                INSERT INTO coop_fg(f,g)
                SELECT $g, g FROM frcgroups;
            }

            # NEXT, Return undo command.
            return [mytypemethod UndoCreate $g]
        }
    }

    # UndoCreate g
    #
    # g - A group short name
    #
    # Undoes creation of the group.

    typemethod UndoCreate {g} {
        rdb delete groups {g=$g} civgroups {g=$g} demog_g {g=$g}
        bsystem edit undo
    }

    # mutate delete g
    #
    # g     A group short name
    #
    # Deletes the group.

    typemethod {mutate delete} {g} {
        # FIRST, delete the group, grabbing the undo information
        set data [rdb delete -grab \
                      groups {g=$g} civgroups {g=$g} demog_g {g=$g}]

        # NEXT, delete the bsystem entity.
        bsystem entity delete $g

        # NEXT, Return the undo script
        return [mytypemethod UndoDelete $data]
    }

    # UndoDelete data
    #
    # data - An RDB grab data set
    #
    # Restores the data into the RDB, and undoes the bsystem change.
    
    typemethod UndoDelete {data} {
        bsystem edit undo
        rdb ungrab $data
    }


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g              A group short name
    #    n              A new nbhood, or ""
    #    longname       A new long name, or ""
    #    color          A new color, or ""
    #    shape          A new shape, or ""
    #    demeanor       The group's demeanor (edemeanor(n))
    #    basepop        A new basepop, or ""
    #    sa_flag        A new sa_flag, or ""
    #
    # Updates a civgroup given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab groups {g=$g} civgroups {g=$g}]

            # NEXT, Update the group
            rdb eval {
                UPDATE groups
                SET longname  = nonempty($longname, longname),
                    color     = nonempty($color,    color),
                    shape     = nonempty($shape,    shape),
                    demeanor  = nonempty($demeanor, demeanor)
                WHERE g=$g;

                UPDATE civgroups
                SET n       = nonempty($n, n),
                    basepop = nonempty($basepop,  basepop),
                    sa_flag = nonempty($sa_flag, sa_flag)
                WHERE g=$g

            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}

#-----------------------------------------------------------------------
# Orders: CIVGROUP:*

# CIVGROUP:CREATE
#
# Creates new civilian groups.

order define CIVGROUP:CREATE {
    title "Create Civilian Group"

    options -sendstates PREP

    form {
        rcc "Group:" -for g
        text g

        rcc "Long Name:" -for longname
        longname longname

        rcc "Nbhood:" -for n
        nbhood n

        rcc "Color:" -for color
        color color -defvalue #45DD11

        rcc "Shape:" -for shape
        enumlong shape -dictcmd {eunitshape deflist} -defvalue NEUTRAL
        
        rcc "Demeanor:" -for demeanor
        enumlong demeanor -dictcmd {edemeanor deflist} -defvalue AVERAGE

        rcc "Base Pop.:" -for basepop
        text basepop -defvalue 10000
        label "people"

        rcc "Subs. Agri. Flag" -for sa_flag
        yesno sa_flag -defvalue 0

    }
} {
    # FIRST, prepare and validate the parameters
    prepare g        -toupper   -required -unused -type ident
    prepare longname -normalize
    prepare n        -toupper   -required         -type nbhood
    prepare color    -tolower   -required         -type hexcolor
    prepare shape    -toupper   -required         -type eunitshape
    prepare demeanor -toupper   -required         -type edemeanor
    prepare basepop  -num       -required         -type ingpopulation
    prepare sa_flag             -required         -type boolean

    returnOnError -final

    # NEXT, If longname is "", defaults to ID.
    if {$parms(longname) eq ""} {
        set parms(longname) $parms(g)
    }

    # NEXT, create the group and dependent entities
    lappend undo [civgroup mutate create [array get parms]]

    setundo [join $undo \n]
}

# CIVGROUP:DELETE

order define CIVGROUP:DELETE {
    title "Delete Civilian Group"
    options -sendstates PREP

    form {
        rcc "Group:" -for g
        civgroup g
    }
} {
    # FIRST, prepare the parameters
    prepare g -toupper -required -type civgroup

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     CIVGROUP:DELETE            \
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
    lappend undo [ensit mutate reconcile]

    setundo [join $undo \n]
}


# CIVGROUP:UPDATE
#
# Updates existing groups.

order define CIVGROUP:UPDATE {
    title "Update Civilian Group"
    options -sendstates PREP

    form {
        rcc "Select Group:" -for g
        key g -table civgroups_view -keys g \
            -loadcmd {orderdialog keyload g *}

        rcc "Long Name:" -for longname
        longname longname

        rcc "Nbhood:" -for n
        nbhood n

        rcc "Color:" -for color
        color color

        rcc "Shape:" -for shape
        enumlong shape -dictcmd {eunitshape deflist}
        
        rcc "Demeanor:" -for demeanor
        enumlong demeanor -dictcmd {edemeanor deflist}

        rcc "Base Pop.:" -for basepop
        text basepop
        label "people"

        rcc "Subs. Agri. Flag" -for sa_flag
        yesno sa_flag
    }
} {
    # FIRST, prepare the parameters
    prepare g         -toupper   -required -type civgroup
    prepare longname  -normalize
    prepare n         -toupper   -type nbhood
    prepare color     -tolower   -type hexcolor
    prepare shape     -toupper   -type eunitshape
    prepare demeanor  -toupper   -type edemeanor
    prepare basepop   -num       -type ingpopulation
    prepare sa_flag              -type boolean

    returnOnError -final

    # NEXT, modify the group
    setundo [civgroup mutate update [array get parms]]
}

# CIVGROUP:UPDATE:MULTI
#
# Updates existing groups.

order define CIVGROUP:UPDATE:MULTI {
    title "Update Multiple Civilian Groups"
    options -sendstates PREP

    form {
        rcc "Groups:" -for ids
        multi ids -table gui_civgroups -key g \
            -loadcmd {orderdialog multiload ids *}

        rcc "Nbhood:" -for n
        nbhood n

        rcc "Color:" -for color
        color color

        rcc "Shape:" -for shape
        enumlong shape -dictcmd {eunitshape deflist}
        
        rcc "Demeanor:" -for demeanor
        enumlong demeanor -dictcmd {edemeanor deflist}

        rcc "Base Pop.:" -for basepop
        text basepop
        label "people"

        rcc "Subs. Agri. Flag" -for sa_flag
        yesno sa_flag
    }
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper -required -listof civgroup
    prepare n        -toupper           -type nbhood
    prepare color    -tolower           -type hexcolor
    prepare shape    -toupper           -type eunitshape
    prepare demeanor -toupper           -type edemeanor
    prepare basepop  -num               -type ingpopulation
    prepare sa_flag                     -type boolean

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



