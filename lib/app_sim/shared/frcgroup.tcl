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
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of force group names

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


    # uniformed names
    #
    # Returns the list of uniformed frcgroups

    typemethod {uniformed names} {} {
        set names [rdb eval {
            SELECT g FROM frcgroups WHERE uniformed
        }]
    }


    # uniformed validate g
    #
    # g         Possibly, a uniformed force group short name.
    #
    # Validates a uniformed force group short name

    typemethod {uniformed validate} {g} {
        set names [$type uniformed names]

        if {$g ni $names} {
            set names [join $names ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid uniformed force group, $msg"
        }

        return $g
    }


    # nonuniformed names
    #
    # Returns the list of nonuniformed frcgroups

    typemethod {nonuniformed names} {} {
        set names [rdb eval {
            SELECT g FROM frcgroups WHERE NOT uniformed
        }]
    }


    # nonuniformed validate g
    #
    # g         Possibly, a non-uniformed force group short name.
    #
    # Validates a non-uniformed force group short name

    typemethod {nonuniformed validate} {g} {
        set names [$type nonuniformed names]

        if {$g ni $names} {
            set names [join $names ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid non-uniformed force group, $msg"
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
    #    a              The group's owning actor
    #    color          The group's color
    #    shape          The group's unit shape (eunitshape(n))
    #    forcetype      The group's eforcetype
    #    demeanor       The group's demeanor (edemeanor(n))
    #    cost           The group's maintenance cost, $/person/week
    #    attack_cost    The group's cost per attack, $.
    #    uniformed      The group's uniformed flag
    #    local          The group's local flag
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
                INSERT INTO 
                groups(g, longname, color, shape, symbol, demeanor, 
                       cost, rel_entity, gtype)
                VALUES($g,
                       $longname,
                       $color,
                       $shape,
                       $symbol,
                       $demeanor,
                       $cost,
                       nullif($a,''),
                       'FRC');

                INSERT INTO frcgroups(g,a,forcetype,attack_cost,
                                      uniformed,local)
                VALUES($g,
                       nullif($a,''),
                       $forcetype,
                       $attack_cost,
                       $uniformed,
                       $local);

                INSERT INTO coop_fg(f,g)
                SELECT g, $g FROM civgroups;
            }

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
        # FIRST, Delete the group, grabbing the undo information
        set data [rdb delete -grab groups {g=$g} frcgroups {g=$g}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g              A group short name
    #    longname       A new long name, or ""
    #    a              A new owning actor, or ""
    #    color          A new color, or ""
    #    shape          A new shape, or ""
    #    forcetype      A new eforcetype, or ""
    #    demeanor       A new demeanor, or ""
    #    cost           A new cost, or ""
    #    attack_cost    A new attack cost, or ""
    #    uniformed      A new uniformed flag, or ""
    #    local          A new local flag, or ""
    #
    # Updates a frcgroup given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, grab the group data that might change.
            set data [rdb grab groups {g=$g} frcgroups {g=$g}]

            # NEXT, get the new unit symbol, if need be.
            if {$forcetype ne ""} {
                set symbol $symbols($forcetype)
            } else {
                set symbol ""
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE groups
                SET longname   = nonempty($longname,     longname),
                    color      = nonempty($color,        color),
                    shape      = nonempty($shape,        shape),
                    symbol     = nonempty($symbol,       symbol),
                    demeanor   = nonempty($demeanor,     demeanor),
                    cost       = nonempty($cost,         cost),
                    rel_entity = coalesce(nullif($a,''), rel_entity)
                WHERE g=$g;

                UPDATE frcgroups
                SET a           = coalesce(nullif($a,''), a),
                    forcetype   = nonempty($forcetype,   forcetype),
                    attack_cost = nonempty($attack_cost, attack_cost),
                    uniformed   = nonempty($uniformed,   uniformed),
                    local       = nonempty($local,       local)
                WHERE g=$g
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}

#-------------------------------------------------------------------
# Orders: FRCGROUP:*

# FRCGROUP:CREATE
#
# Creates new force groups.

order define FRCGROUP:CREATE {
    title "Create Force Group"
    
    options -sendstates PREP

    parm g           text  "Group"
    parm longname    text  "Long Name"
    parm a           enum  "Owning Actor"        -enumtype actor
    parm color       color "Color"               -defval   "#3B61FF"
    parm shape       enum  "Unit Shape"          -enumtype eunitshape \
                                                 -defval   NEUTRAL
    parm forcetype   enum  "Force Type"          -enumtype eforcetype \
                                                 -defval  REGULAR
    parm demeanor    enum  "Demeanor"            -enumtype edemeanor  \
                                                 -defval   AVERAGE
    parm cost        text  "Cost, $/person/week" -defval   0
    parm attack_cost text  "Cost, $/attack"      -defval   0
    parm uniformed   enum  "Uniformed?"          -enumtype eyesno     \
                                                 -defval   YES
    parm local       enum  "Local Group?"        -enumtype eyesno     \
                                                 -defval   NO
} {
    # FIRST, prepare and validate the parameters
    prepare g           -toupper   -required -unused -type ident
    prepare longname    -normalize
    prepare a           -toupper             -type actor
    prepare color       -tolower   -required -type hexcolor
    prepare shape       -toupper   -required -type eunitshape
    prepare forcetype   -toupper   -required -type eforcetype
    prepare demeanor    -toupper   -required -type edemeanor
    prepare cost        -toupper   -required -type money
    prepare attack_cost -toupper   -required -type money
    prepare uniformed   -toupper   -required -type boolean
    prepare local       -toupper   -required -type boolean

    returnOnError -final

    # NEXT, If longname is "", defaults to ID.
    if {$parms(longname) eq ""} {
        set parms(longname) $parms(g)
    }

    # NEXT, create the group and dependent entities
    lappend undo [frcgroup mutate create [array get parms]]

    setundo [join $undo \n]
}

# FRCGROUP:DELETE

order define FRCGROUP:DELETE {
    title "Delete Force Group"
    options -sendstates PREP

    parm g  key "Group" -tags group -table gui_frcgroups -keys g
} {
    # FIRST, prepare the parameters
    prepare g -toupper -required -type frcgroup

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     FRCGROUP:DELETE                    \
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
    lappend undo [frcgroup mutate delete $parms(g)]
    lappend undo [ensit mutate reconcile]

    setundo [join $undo \n]
}


# FRCGROUP:UPDATE
#
# Updates existing groups.

order define FRCGROUP:UPDATE {
    title "Update Force Group"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey g *}

    parm g           key   "Select Group"        -table gui_frcgroups -keys g \
                                                 -tags group 
    parm longname    text  "Long Name"
    parm a           enum  "Owning Actor"        -enumtype actor
    parm color       color "Color"
    parm shape       enum  "Unit Shape"          -enumtype eunitshape
    parm forcetype   enum  "Force Type"          -enumtype eforcetype
    parm demeanor    enum  "Demeanor"            -enumtype edemeanor
    parm cost        text  "Cost, $/person/week"
    parm attack_cost text  "Cost, $/attack"
    parm uniformed   enum  "Uniformed?"          -enumtype eyesno
    parm local       enum  "Local Group?"        -enumtype eyesno
} {
    # FIRST, prepare the parameters
    prepare g           -toupper   -required -type frcgroup
    prepare a           -toupper   -type actor
    prepare longname    -normalize
    prepare color       -tolower   -type hexcolor
    prepare shape       -toupper   -type eunitshape
    prepare forcetype   -toupper   -type eforcetype
    prepare demeanor    -toupper   -type edemeanor
    prepare cost        -toupper   -type money
    prepare attack_cost -toupper   -type money
    prepare uniformed   -toupper   -type boolean
    prepare local       -toupper   -type boolean

    returnOnError -final

    # NEXT, modify the group.
    set undo [list]
    lappend undo [frcgroup mutate update [array get parms]]

    setundo [join $undo \n]
}

# FRCGROUP:UPDATE:MULTI
#
# Updates multiple groups.

order define FRCGROUP:UPDATE:MULTI {
    title "Update Multiple Force Groups"
    options \
        -sendstates PREP                                  \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids         multi "Groups"               -table gui_frcgroups -key g
    parm a           enum  "Owning Actor"         -enumtype actor
    parm color       color "Color"
    parm shape       enum  "Unit Shape"           -enumtype eunitshape
    parm forcetype   enum  "Force Type"           -enumtype eforcetype
    parm demeanor    enum  "Demeanor"             -enumtype edemeanor
    parm cost        text  "Cost, $/person/week"
    parm attack_cost text  "Cost, $/attack"
    parm uniformed   enum  "Uniformed?"           -enumtype eyesno
    parm local       enum  "Local Group?"         -enumtype eyesno
} {
    # FIRST, prepare the parameters
    prepare ids         -toupper  -required -listof frcgroup
    prepare a           -toupper            -type   actor
    prepare color       -tolower            -type   hexcolor
    prepare shape       -toupper            -type   eunitshape
    prepare forcetype   -toupper            -type   eforcetype
    prepare demeanor    -toupper            -type   edemeanor
    prepare cost        -toupper            -type   money
    prepare attack_cost -toupper            -type   money
    prepare uniformed   -toupper            -type   boolean
    prepare local       -toupper            -type   boolean

    returnOnError -final

    # NEXT, clear the other parameters expected by the mutator
    prepare longname

    # NEXT, modify the group
    set undo [list]

    foreach parms(g) $parms(ids) {
        lappend undo [frcgroup mutate update [array get parms]]
    }

    setundo [join $undo \n]
}



