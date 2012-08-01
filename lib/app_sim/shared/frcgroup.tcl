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

    # ownedby a
    #
    # a - An actor
    #
    # Returns a list of the force groups owned by actor a.

    typemethod ownedby {a} {
        return [rdb eval {
            SELECT g FROM frcgroups
            WHERE a=$a
        }]
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
    #    training       The group's training level (etraining(n))
    #    base_personnel The group's base personnel
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
        # FIRST, bring the parameters into scope.
        dict with parmdict {}

        # NEXT, get the symbol
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

            INSERT INTO frcgroups(g, a, forcetype, training,
                                  base_personnel, attack_cost,
                                  uniformed, local)
            VALUES($g,
                   nullif($a,''),
                   $forcetype,
                   $training,
                   $base_personnel,
                   $attack_cost,
                   $uniformed,
                   $local);

            INSERT INTO coop_fg(f,g)
            SELECT g, $g FROM civgroups;
        }

        # NEXT, Return the undo command
        return [mytypemethod mutate delete $g]
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
    #    training       A new training level, or ""
    #    base_personnel A new base personnel, or ""
    #    demeanor       A new demeanor, or ""
    #    cost           A new cost, or ""
    #    attack_cost    A new attack cost, or ""
    #    uniformed      A new uniformed flag, or ""
    #    local          A new local flag, or ""
    #
    # Updates a frcgroup given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, bring the parameters into scope.
        dict with parmdict {}

        # NEXT, grab the group data that might change.
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
            SET a              = coalesce(nullif($a,''),   a),
                forcetype      = nonempty($forcetype,      forcetype),
                training       = nonempty($training,       training),
                base_personnel = nonempty($base_personnel, base_personnel),
                attack_cost    = nonempty($attack_cost,    attack_cost),
                uniformed      = nonempty($uniformed,      uniformed),
                local          = nonempty($local,          local)
            WHERE g=$g
        } {}

        # NEXT, Return the undo command
        return [list rdb ungrab $data]
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

    form {
        rcc "Group:" -for g
        text g

        rcc "Long Name:" -for longname
        longname longname

        rcc "Owning Actor:" -for a
        actor a

        rcc "Color:" -for color
        color color -defvalue #3B61FF

        rcc "Unit Shape:" -for shape
        enumlong shape -dictcmd {eunitshape deflist} -defvalue NEUTRAL
        
        rcc "Force Type" -for forcetype
        enumlong forcetype -dictcmd {eforcetype deflist} -defvalue REGULAR

        rcc "Training" -for training
        enumlong training -dictcmd {etraining deflist} -defvalue FULL

        rcc "Base Personnel:" -for base_personnel
        text base_personnel -defvalue 0

        rcc "Demeanor:" -for demeanor
        enumlong demeanor -dictcmd {edemeanor deflist} -defvalue AVERAGE

        rcc "Cost:" -for cost
        text cost -defvalue 0
        label "$/person/week"

        rcc "Attack Cost:" -for attack_cost
        text attack_cost -defvalue 0
        label "$/attack"

        rcc "Uniformed?" -for uniformed
        yesno uniformed -defvalue 1

        rcc "Local Group?" -for local
        yesno local -defvalue 0
    }
} {
    # FIRST, prepare and validate the parameters
    prepare g              -toupper   -required -unused -type ident
    prepare longname       -normalize
    prepare a              -toupper             -type actor
    prepare color          -tolower   -required -type hexcolor
    prepare shape          -toupper   -required -type eunitshape
    prepare forcetype      -toupper   -required -type eforcetype
    prepare training       -toupper   -required -type etraining
    prepare base_personnel -toupper   -required -type iquantity
    prepare demeanor       -toupper   -required -type edemeanor
    prepare cost           -toupper   -required -type money
    prepare attack_cost    -toupper   -required -type money
    prepare uniformed      -toupper   -required -type boolean
    prepare local          -toupper   -required -type boolean

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

    form {
        rcc "Group:" -for g
        frcgroup g
    }
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
    options -sendstates PREP

    form {
        rcc "Group:" -for g
        key g -table gui_frcgroups -keys g \
            -loadcmd {orderdialog keyload g *}

        rcc "Long Name:" -for longname
        longname longname

        rcc "Owning Actor:" -for a
        actor a

        rcc "Color:" -for color
        color color

        rcc "Unit Shape:" -for shape
        enumlong shape -dictcmd {eunitshape deflist}
        
        rcc "Force Type" -for forcetype
        enumlong forcetype -dictcmd {eforcetype deflist}

        rcc "Training" -for training
        enumlong training -dictcmd {etraining deflist}

        rcc "Base Personnel:" -for base_personnel
        text base_personnel

        rcc "Demeanor:" -for demeanor
        enumlong demeanor -dictcmd {edemeanor deflist}

        rcc "Cost:" -for cost
        text cost
        label "$/person/week"

        rcc "Attack Cost:" -for attack_cost
        text attack_cost
        label "$/attack"

        rcc "Uniformed?" -for uniformed
        yesno uniformed

        rcc "Local Group?" -for local
        yesno local
    }
} {
    # FIRST, prepare the parameters
    prepare g              -toupper   -required -type frcgroup
    prepare a              -toupper   -type actor
    prepare longname       -normalize
    prepare color          -tolower   -type hexcolor
    prepare shape          -toupper   -type eunitshape
    prepare forcetype      -toupper   -type eforcetype
    prepare training       -toupper   -type etraining
    prepare base_personnel -toupper   -type iquantity
    prepare demeanor       -toupper   -type edemeanor
    prepare cost           -toupper   -type money
    prepare attack_cost    -toupper   -type money
    prepare uniformed      -toupper   -type boolean
    prepare local          -toupper   -type boolean

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
    options -sendstates PREP

    form {
        rcc "Groups:" -for ids
        multi ids -table gui_frcgroups -key g \
            -loadcmd {orderdialog multiload ids *}

        rcc "Owning Actor:" -for a
        actor a

        rcc "Color:" -for color
        color color

        rcc "Unit Shape:" -for shape
        enumlong shape -dictcmd {eunitshape deflist}
        
        rcc "Force Type" -for forcetype
        enumlong forcetype -dictcmd {eforcetype deflist}

        rcc "Training" -for training
        enumlong training -dictcmd {etraining deflist}

        rcc "Base Personnel:" -for base_personnel
        text base_personnel

        rcc "Demeanor:" -for demeanor
        enumlong demeanor -dictcmd {edemeanor deflist}

        rcc "Cost:" -for cost
        text cost
        label "$/person/week"

        rcc "Attack Cost:" -for attack_cost
        text attack_cost
        label "$/attack"

        rcc "Uniformed?" -for uniformed
        yesno uniformed

        rcc "Local Group?" -for local
        yesno local
    }
} {
    # FIRST, prepare the parameters
    prepare ids            -toupper  -required -listof frcgroup
    prepare a              -toupper            -type   actor
    prepare color          -tolower            -type   hexcolor
    prepare shape          -toupper            -type   eunitshape
    prepare forcetype      -toupper            -type   eforcetype
    prepare training       -toupper            -type   etraining
    prepare base_personnel -toupper            -type   iquantity
    prepare demeanor       -toupper            -type   edemeanor
    prepare cost           -toupper            -type   money
    prepare attack_cost    -toupper            -type   money
    prepare uniformed      -toupper            -type   boolean
    prepare local          -toupper            -type   boolean

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



