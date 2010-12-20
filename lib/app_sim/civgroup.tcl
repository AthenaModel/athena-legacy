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
    #    sap            The group's subsistence agriculture percentage 
    #
    # Creates a civilian group given the parms, which are presumed to be
    # valid.
    #
    # Creating a civilian group requires adding entries to the groups table.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO 
                groups(g,longname,color,shape,symbol,demeanor,gtype)
                VALUES($g,
                       $longname,
                       $color,
                       $shape,
                       'civilian',
                       $demeanor,
                       'CIV');

                INSERT INTO
                civgroups(g,n,basepop,sap)
                VALUES($g,
                       $n,
                       $basepop,
                       $sap);

                INSERT INTO demog_g(g)
                VALUES($g);
            }

            # NEXT, create a bsystem entity
            bsystem entity add $g

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
        bsystem edit undo
        rdb delete groups {g=$g} civgroups {g=$g} demog_g {g=$g}

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
    #    sap            A new sap, or ""
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
                SET longname  = nonempty($longname,  longname),
                    color     = nonempty($color,     color),
                    shape     = nonempty($shape,     shape),
                    demeanor  = nonempty($demeanor,  demeanor)
                WHERE g=$g;

                UPDATE civgroups
                SET n       = nonempty($n, n),
                    basepop = nonempty($basepop, basepop),
                    sap     = nonempty($sap, sap)
                WHERE g=$g

            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }

    # mutate reconcile
    #
    # Deletes civgroups for which the neighborhood no longer exists.

    typemethod {mutate reconcile} {} {
        # FIRST, delete the ones that are no longer valid, accumulating
        # an undo script.

        set undo [list]

        set nbhoods [nbhood names]

        rdb eval {
            SELECT g,n FROM civgroups            
        } {
            if {$n ni $nbhoods} {
                lappend undo [$type mutate delete $g]
            }
        }

        return [join $undo \n]
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

    parm g         text   "Group"
    parm longname  text   "Long Name"
    parm n         enum   "Nbhood"          -type nbhood
    parm color     color  "Color"           -defval \#45DD11
    parm shape     enum   "Unit Shape"      -type eunitshape \
                                            -defval NEUTRAL
    parm demeanor  enum   "Demeanor"        -type edemeanor \
                                            -defval AVERAGE
    parm basepop   text   "Base Pop."       -defval 10000
    parm sap       pct    "Subs. Agri. %"   -defval 0
} {
    # FIRST, prepare and validate the parameters
    prepare g        -toupper   -required -unused -type ident
    prepare longname -normalize
    prepare n        -toupper   -required         -type nbhood
    prepare color    -tolower   -required         -type hexcolor
    prepare shape    -toupper   -required         -type eunitshape
    prepare demeanor -toupper   -required         -type edemeanor
    prepare basepop             -required         -type ingpopulation
    prepare sap                 -required         -type ipercent

    returnOnError -final

    # NEXT, If longname is "", defaults to ID.
    if {$parms(longname) eq ""} {
        set parms(longname) $parms(g)
    }

    # NEXT, create the group and dependent entities
    lappend undo [civgroup mutate create [array get parms]]
    lappend undo [scenario mutate reconcile]

    setundo [join $undo \n]
}

# CIVGROUP:DELETE

order define CIVGROUP:DELETE {
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
    lappend undo [scenario mutate reconcile]

    setundo [join $undo \n]
}


# CIVGROUP:UPDATE
#
# Updates existing groups.

order define CIVGROUP:UPDATE {
    title "Update Civilian Group"
    options \
        -sendstates PREP                             \
        -refreshcmd {orderdialog refreshForKey g *}

    parm g         key    "Group"         \
        -table civgroups_view -key g -tags group
    parm longname  text   "Long Name"
    parm n         enum   "Nbhood"     -type nbhood
    parm color     color  "Color"
    parm shape     enum   "Unit Shape"       -type eunitshape
    parm demeanor  enum   "Demeanor"         -type edemeanor
    parm basepop   text   "Base Population"
    parm sap       pct    "Subs. Agri. %"  
} {
    # FIRST, prepare the parameters
    prepare g         -toupper   -required -type civgroup
    prepare longname  -normalize
    prepare n         -toupper   -type nbhood
    prepare color     -tolower   -type hexcolor
    prepare shape     -toupper   -type eunitshape
    prepare demeanor  -toupper   -type edemeanor
    prepare basepop              -type ingpopulation
    prepare sap                  -type ipercent

    returnOnError -final

    # NEXT, modify the group
    setundo [civgroup mutate update [array get parms]]
}

# CIVGROUP:UPDATE:MULTI
#
# Updates existing groups.

order define CIVGROUP:UPDATE:MULTI {
    title "Update Multiple Civilian Groups"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids      multi  "Groups"  -table gui_civgroups -key g
    parm n        enum   "Nbhood"     -type nbhood
    parm color    color  "Color"
    parm shape    enum   "Unit Shape" -type eunitshape
    parm demeanor enum   "Demeanor"   -type edemeanor
    parm basepop  text   "Base Population"
    parm sap      pct    "Subs. Agri. %"  
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper -required -listof civgroup
    prepare n        -toupper           -type nbhood
    prepare color    -tolower           -type hexcolor
    prepare shape    -toupper           -type eunitshape
    prepare demeanor -toupper           -type edemeanor
    prepare basepop                     -type ingpopulation
    prepare sap                         -type ipercent

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

# CIVGROUP:UPDATE:POSTPREP
#
# Updates existing groups.

order define CIVGROUP:UPDATE:POSTPREP {
    title "Update Civilian Group (Post-PREP)"
    options \
        -sendstates {PREP PAUSED}                   \
        -refreshcmd {orderdialog refreshForKey g *}

    parm g         key    "Group"         \
        -table civgroups_view -key g -tags group
    parm sap       pct    "Subs. Agri. %"  
} {
    # FIRST, prepare the parameters
    prepare g         -toupper  -required -type civgroup
    prepare sap                 -type ipercent

    returnOnError -final

    # NEXT, modify the group
    setundo [civgroup mutate update [array get parms]]
}

# CIVGROUP:UPDATE:MULTI:POSTPREP
#
# Updates existing groups.

order define CIVGROUP:UPDATE:MULTI:POSTPREP {
    title "Update Multiple Civilian Groups (Post-PREP)"
    options -sendstates {PREP PAUSED} \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids      multi  "Groups"  -table gui_civgroups -key g
    parm sap      pct    "Subs. Agri. %"  
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper -required -listof civgroup
    prepare sap                         -type ipercent

    returnOnError -final

    # NEXT, modify the group
    set undo [list]

    foreach parms(g) $parms(ids) {
        lappend undo [civgroup mutate update [array get parms]]
    }

    setundo [join $undo \n]
}

