#-----------------------------------------------------------------------
# TITLE:
#    actor.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Actor Manager
#
#    This module is responsible for managing political actors and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type actor {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of actor names

    typemethod names {} {
        set names [rdb eval {
            SELECT a FROM actors
        }]
    }


    # validate a
    #
    # a - Possibly, an actor short name.
    #
    # Validates an actor short name

    typemethod validate {a} {
        set names [$type names]

        if {$a ni $names} {
            set nameString [join $names ", "]

            if {$nameString ne ""} {
                set msg "should be one of: $nameString"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid actor, $msg"
        }

        return $a
    }

    # get a ?parm?
    #
    # a    - An actor
    # parm - A actors column name
    #
    # Retrieves a row dictionary, or a particular column value, from
    # actors.

    typemethod get {a {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM actors WHERE a=$a} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }

    # frcgroups a 
    #
    # a - An actor
    #
    # Returns a list of the force groups owned by the actor.
    
    typemethod frcgroups {a} {
        rdb eval {SELECT g FROM frcgroups WHERE a=$a}
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
    # parmdict     A dictionary of actor parms
    #
    #    a              The actor's ID
    #    longname       The actor's long name
    #    cash_reserve   The actor's cash reserve (starting balance)
    #    income         The actor's income per tactics tock
    #    cash_on_hand   The actor's cash-on-hand (starting balance)
    #
    # Creates an actor given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the actor in the database
            rdb eval {
                INSERT INTO 
                actors(a,  longname,  cash_reserve, income, cash_on_hand)
                VALUES($a, $longname, $cash_reserve, $income, $cash_on_hand)
            }

            # NEXT, create a matching bsystem entity
            bsystem entity add $a

            # NEXT, Return undo command.
            return [mytypemethod UndoCreate $a]
        }
    }

    # UndoCreate a
    #
    # a - An actor short name
    #
    # Undoes the creation of the actor.

    typemethod UndoCreate {a} {
        # FIRST, undo the belief system change
        bsystem edit undo
        
        # NEXT, delete the actor record.
        rdb delete actors {a=$a}
    }


    # mutate delete a
    #
    # a     An actor short name
    #
    # Deletes the actor.

    typemethod {mutate delete} {a} {
        # FIRST, get the undo information
        set gdata [rdb grab groups \
                       {rel_entity=$a} frcgroups {a=$a} orggroups {a=$a}]
        
        set adata [rdb delete -grab actors {a=$a}]

        
        # NEXT, delete the bsystem entity
        bsystem entity delete $a

        # NEXT, Return the undo script
        return [mytypemethod UndoDelete [concat $adata $gdata]]
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
    # parmdict     A dictionary of actor parms
    #
    #    a              An actor short name
    #    longname       A new long name, or ""
    #    cash_reserve   A new reserve amount, or ""
    #    income         A new income, or ""
    #    cash_on_hand   A new cash-on-hand amount, or ""
    #
    # Updates a actor given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab actors {a=$a}]

            # NEXT, Update the actor
            rdb eval {
                UPDATE actors
                SET longname     = nonempty($longname,     longname),
                    cash_reserve = nonempty($cash_reserve, cash_reserve),
                    income       = nonempty($income,       income),
                    cash_on_hand = nonempty($cash_on_hand, cash_on_hand)
                WHERE a=$a;
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}

#-----------------------------------------------------------------------
# Orders: ACTOR:*

# ACTOR:CREATE
#
# Creates new actors.

order define ACTOR:CREATE {
    title "Create Actor"

    options \
        -sendstates PREP

    parm a            text  "Actor"
    parm longname     text  "Long Name"
    parm cash_reserve text  "Cash Reserve $"        -defval 0
    parm income       text  "Income $/week"         -defval 0
    parm cash_on_hand text  "Cash On Hand $"        -defval 0
} {
    # FIRST, prepare and validate the parameters
    prepare a            -toupper   -required -unused -type ident
    prepare longname     -normalize
    prepare cash_reserve -toupper                     -type money
    prepare income       -toupper                     -type money
    prepare cash_on_hand -toupper                     -type money

    returnOnError -final

    # NEXT, If longname is "", defaults to ID.
    if {$parms(longname) eq ""} {
        set parms(longname) $parms(a)
    }

    # NEXT, create the actor
    setundo [actor mutate create [array get parms]]
}

# ACTOR:DELETE

order define ACTOR:DELETE {
    title "Delete Actor"
    options -sendstates PREP

    parm a  key  "Actor"  -tags actor -table actors -keys a
} {
    # FIRST, prepare the parameters
    prepare a -toupper -required -type actor

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     ACTOR:DELETE            \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this actor and all of the
                            entities that depend upon it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the actor and dependent entities
    lappend undo 

    setundo [actor mutate delete $parms(a)]
}


# ACTOR:UPDATE
#
# Updates existing actors.

order define ACTOR:UPDATE {
    title "Update Actor"
    options \
        -sendstates PREP                             \
        -refreshcmd {orderdialog refreshForKey a *}

    parm a            key    "Select Actor"    -table gui_actors -keys a \
                                               -tags actor
    parm longname     text   "Long Name"
    parm cash_reserve text   "Cash Reserve $"
    parm income       text   "Income $/week"
    parm cash_on_hand text   "Cash On Hand $"
} {
    # FIRST, prepare the parameters
    prepare a            -toupper   -required -type actor
    prepare longname     -normalize
    prepare cash_reserve -toupper             -type money
    prepare income       -toupper             -type money
    prepare cash_on_hand -toupper             -type money

    returnOnError -final

    # NEXT, modify the actor
    setundo [actor mutate update [array get parms]]
}

# ACTOR:UPDATE
#
# Updates existing actors.

order define ACTOR:INCOME {
    title "Update Actor Income"
    options \
        -sendstates {PREP PAUSED TACTIC}            \
        -refreshcmd {orderdialog refreshForKey a *}

    parm a            key    "Select Actor"    -table gui_actors -keys a \
                                               -tags actor
    parm income       text   "Income $/week"
} {
    # FIRST, prepare the parameters
    prepare a            -toupper   -required -type actor
    prepare income       -toupper   -required -type money

    returnOnError -final

    # NEXT, fill in the empty parameters
    array set parms {
        longname     {}
        cash_reserve {}
        cash_on_hand {}
    }

    # NEXT, modify the actor
    setundo [actor mutate update [array get parms]]
}


