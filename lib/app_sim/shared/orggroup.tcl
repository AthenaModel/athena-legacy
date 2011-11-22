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
    #    a                The group's owning actor
    #    color            The group's color
    #    shape            The group's unit shape (eunitshape(n))
    #    orgtype          The group's eorgtype
    #    demeanor         The group's demeanor (edemeanor(n))
    #    cost             The group's maintenance cost, $/person/week
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
                INSERT INTO 
                groups(g, longname, color, shape, symbol, demeanor,
                       cost, rel_entity, gtype)
                VALUES($g,
                       $longname,
                       $color,
                       $shape,
                       'organization',
                       $demeanor,
                       $cost,
                       nullif($a,''),
                       'ORG');

                INSERT INTO orggroups(g,a,orgtype)
                VALUES($g,
                       nullif($a,''),
                       $orgtype);
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
        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab groups {g=$g} orggroups {g=$g}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    g                A group short name
    #    longname         A new long name, or ""
    #    a                A new owning actor, or ""
    #    color            A new color, or ""
    #    shape            A new shape, or ""
    #    orgtype          A new orgtype, or ""
    #    demeanor         A new demeanor, or ""
    #    cost             A new cost, or ""
    #
    # Updates a orggroup given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab groups {g=$g} orggroups {g=$g}]

            # NEXT, Update the group
            rdb eval {
                UPDATE groups
                SET longname   = nonempty($longname,     longname),
                    color      = nonempty($color,        color),
                    demeanor   = nonempty($demeanor,     demeanor),
                    cost       = nonempty($cost,         cost),
                    shape      = nonempty($shape,        shape),
                    rel_entity = coalesce(nullif($a,''), rel_entity)
                WHERE g=$g;

                UPDATE orggroups
                SET a         = coalesce(nullif($a,''), a),
                    orgtype   = nonempty($orgtype,      orgtype)
                WHERE g=$g
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}

#-------------------------------------------------------------------
# Orders: ORGGROUP:*

# ORGGROUP:CREATE
#
# Creates new organization groups.

order define ORGGROUP:CREATE {
    title "Create Organization Group"
    options -sendstates PREP

    parm g           text  "Group"
    parm longname    text  "Long Name"
    parm a           enum  "Owning Actor"        -enumtype actor
    parm color       color "Color"               -defval   \#10DDD7
    parm shape       enum  "Unit Shape"          -enumtype eunitshape \
                                                 -defval   NEUTRAL
    parm orgtype     enum  "Organization Type"   -enumtype eorgtype   \
                                                 -defval   NGO
    parm demeanor    enum  "Demeanor"            -enumtype edemeanor  \
                                                 -defval   AVERAGE
    parm cost        text  "Cost, $/person/week" -defval   0
} {
    # FIRST, prepare and validate the parameters
    prepare g              -toupper   -required -unused -type ident
    prepare longname       -normalize
    prepare a              -toupper             -type actor
    prepare color          -tolower   -required -type hexcolor
    prepare shape          -toupper   -required -type eunitshape
    prepare orgtype        -toupper   -required -type eorgtype
    prepare demeanor       -toupper   -required -type edemeanor
    prepare cost           -toupper   -required -type money

    returnOnError -final

    # NEXT, If longname is "", defaults to ID.
    if {$parms(longname) eq ""} {
        set parms(longname) $parms(g)
    }

    # NEXT, create the group and dependent entities
    lappend undo [orggroup mutate create [array get parms]]
    
    setundo [join $undo \n]
}

# ORGGROUP:DELETE

order define ORGGROUP:DELETE {
    title "Delete Organization Group"
    options -sendstates PREP

    parm g  key "Group" -tags group -table gui_orggroups -keys g
} {
    # FIRST, prepare the parameters
    prepare g -toupper -required -type orggroup

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     ORGGROUP:DELETE        \
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
    lappend undo [orggroup mutate delete $parms(g)]
    lappend undo [ensit mutate reconcile]
    
    setundo [join $undo \n]
}


# ORGGROUP:UPDATE
#
# Updates existing groups.

order define ORGGROUP:UPDATE {
    title "Update Organization Group"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey g *}

    parm g              key   "Select Group"        -table gui_orggroups \
                                                    -keys  g             \
                                                    -tags group 
    parm longname       text  "Long Name"
    parm a              enum  "Owning Actor"        -enumtype actor
    parm color          color "Color" 
    parm shape          enum  "Unit Shape"          -enumtype eunitshape
    parm orgtype        enum  "Organization Type"   -enumtype eorgtype
    parm demeanor       enum  "Demeanor"            -enumtype edemeanor
    parm cost           text  "Cost, $/person/week"
} {
    # FIRST, prepare the parameters
    prepare g              -toupper   -required -type orggroup
    prepare a              -toupper   -type actor
    prepare longname       -normalize 
    prepare color          -tolower   -type hexcolor
    prepare shape          -toupper   -type eunitshape
    prepare orgtype        -toupper   -type eorgtype
    prepare demeanor       -toupper   -type edemeanor
    prepare cost           -toupper   -type money

    returnOnError -final

    # NEXT, modify the group
    setundo [orggroup mutate update [array get parms]]
}


# ORGGROUP:UPDATE:MULTI
#
# Updates multiple groups.

order define ORGGROUP:UPDATE:MULTI {
    title "Update Multiple Organization Groups"
    options \
        -sendstates PREP                                  \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids        multi "Groups"              -table gui_orggroups -key g
    parm a          enum  "Owning Actor"        -enumtype actor
    parm color      color "Color"
    parm shape      enum  "Unit Shape"          -enumtype eunitshape
    parm orgtype    enum  "Organization Type"   -enumtype eorgtype
    parm demeanor   enum  "Demeanor"            -enumtype edemeanor
    parm cost       text  "Cost, $/person/week"
} {
    # FIRST, prepare the parameters
    prepare ids        -toupper  -required -listof orggroup
    prepare a          -toupper            -type   actor
    prepare color      -tolower            -type   hexcolor
    prepare shape      -toupper            -type   eunitshape
    prepare orgtype    -toupper            -type   eorgtype
    prepare demeanor   -toupper            -type   edemeanor
    prepare cost       -toupper            -type   money

    returnOnError -final

    # NEXT, clear the other parameters expected by the mutator
    prepare longname

    # NEXT, modify the group
    set undo [list]

    foreach parms(g) $parms(ids) {
        lappend undo [orggroup mutate update [array get parms]]
    }

    setundo [join $undo \n]
}





