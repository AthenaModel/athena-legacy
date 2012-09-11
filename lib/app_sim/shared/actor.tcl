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

    # income a
    #
    # a - An actor
    #
    # Returns the actor's most recent income.
    #
    # TBD: This will need to be updated when the link with the CGE is
    # made.

    typemethod income {a} {
        return [rdb onecolumn {
            SELECT income FROM actors_view WHERE a=$a
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
    # parmdict     A dictionary of actor parms
    #
    #    a                 The actor's ID
    #    longname          The actor's long name
    #    supports          Actor name, SELF, or NONE.
    #    cash_reserve      Cash reserve (starting balance)
    #    cash_on_hand      Cash-on-hand (starting balance)
    #    overhead          Overhead fraction, 0.0 to 1.0
    #    income_goods      Income from "goods" sector, $/week
    #    shares_black_nr   Income, shares of net revenues from "black" sector
    #    income_black_tax  Income, "taxes" on "black" sector, $/week
    #    income_pop        Income from "pop" sector, $/week
    #    income_graft      Income, graft on foreign aid to "region", $/week
    #    income_world      Income from "world" sector, $/week
    #
    # Creates an actor given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, get the "supports" actor
            if {$supports eq "SELF"} {
                set supports $a
            }

            # FIRST, Put the actor in the database
            rdb eval {
                INSERT INTO 
                actors(a,  
                       longname,  
                       supports, 
                       cash_reserve, 
                       cash_on_hand,
                       overhead,
                       income_goods, 
                       shares_black_nr, 
                       income_black_tax, 
                       income_pop, 
                       income_graft,
                       income_world)
                VALUES($a, 
                       $longname, 
                       nullif($supports, 'NONE'),
                       $cash_reserve, 
                       $cash_on_hand,
                       $overhead,
                       $income_goods, 
                       $shares_black_nr, 
                       $income_black_tax, 
                       $income_pop, 
                       $income_graft, 
                       $income_world)
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
        set gdata [rdb grab \
                       groups    {rel_entity=$a}          \
                       frcgroups {a=$a}                   \
                       orggroups {a=$a}                   \
                       caps      {owner=$a}               \
                       actors    {a != $a AND supports=$a}]
        
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
    #    a                  An actor short name
    #    longname           A new long name, or ""
    #    supports           A new supports (SELF, NONE, actor), or ""
    #    cash_reserve       A new reserve amount, or ""
    #    cash_on_hand       A new cash-on-hand amount, or ""
    #    overhead           A new overhead amount, or ""
    #    income_goods       A new income, or ""
    #    shares_black_nr    A new share of revenue, or ""
    #    income_black_tax   A new income, or ""
    #    income_pop         A new income, or ""
    #    income_graft       A new income, or ""
    #    income_world       A new income, or ""
    #
    # Updates a actor given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab actors {a=$a}]

            # NEXT, handle SELF
            if {$supports eq "SELF"} {
                set supports $a
            }

            # NEXT, Update the actor
            rdb eval {
                UPDATE actors
                SET longname     = nonempty($longname,     longname),
                    supports     = nullif(nonempty($supports,supports),'NONE'),
                    cash_reserve = nonempty($cash_reserve, cash_reserve),
                    cash_on_hand = nonempty($cash_on_hand, cash_on_hand),
                    overhead     = nonempty($overhead,     overhead),
                    income_goods = nonempty($income_goods, income_goods),
                    shares_black_nr = 
                        nonempty($shares_black_nr, shares_black_nr),
                    income_black_tax = 
                        nonempty($income_black_tax, income_black_tax),
                    income_pop   = nonempty($income_pop,   income_pop),
                    income_graft = nonempty($income_graft, income_graft),
                    income_world = nonempty($income_world, income_world)
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

    form {
        rcc "Actor:" -for a
        text a
        
        rcc "Long Name:" -for longname
        longname longname

        rcc "Supports:" -for supports
        enum supports -defvalue SELF -listcmd {ptype a+self+none names}

        rcc "Cash Reserve:" -for cash_reserve
        text cash_reserve -defvalue 0
        label "$"

        rcc "Cash On Hand:" -for cash_on_hand
        text cash_on_hand -defvalue 0
        label "$"

        rcc "Overhead:" -for overhead
        percent overhead -defvalue 0
        label "% of income"

        rcc "Income, GOODS Sector:" -for income_goods
        text income_goods -defvalue 0
        label "$/week"

        rcc "Income, BLACK Profits:" -for shares_black_nr
        text shares_black_nr -defvalue 0
        label "shares"

        rcc "Income, BLACK Taxes:" -for income_black_tax
        text income_black_tax -defvalue 0
        label "$/week"

        rcc "Income, POP Sector:" -for income_pop
        text income_pop -defvalue 0
        label "$/week"

        rcc "Income, Graft on FA:" -for income_graft
        text income_graft -defvalue 0
        label "$/week"

        rcc "Income, WORLD Sector:" -for income_world
        text income_world -defvalue 0
        label "$/week"
    }
} {
    # FIRST, prepare and validate the parameters
    prepare a                -toupper -required -unused -type ident
    prepare longname         -normalize
    prepare supports         -toupper  -required        -type {ptype a+self+none}
    prepare cash_reserve     -toupper                   -type money
    prepare cash_on_hand     -toupper                   -type money
    prepare overhead         -num                       -type ipercent
    prepare income_goods     -toupper                   -type money
    prepare shares_black_nr  -num                       -type iquantity
    prepare income_black_tax -toupper                   -type money
    prepare income_pop       -toupper                   -type money
    prepare income_graft     -toupper                   -type money
    prepare income_world     -toupper                   -type money

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

    form {
        rcc "Actor:" -for a
        actor a
    }
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

proc DummyLoadCommand {args} {
    puts stderr "DummyLoadCommand: [list $args]"
    return [dict create]
}

# ACTOR:UPDATE
#
# Updates existing actors.

order define ACTOR:UPDATE {
    title "Update Actor"
    options -sendstates PREP

    form {
        rcc "Select Actor:" -for a
        key a -table gui_actors -keys a \
            -loadcmd {::orderdialog keyload a *} 
        
        rcc "Long Name:" -for longname
        longname longname

        rcc "Supports:" -for supports
        enum supports -listcmd {ptype a+self+none names}

        rcc "Cash Reserve:" -for cash_reserve
        text cash_reserve
        label "$"

        rcc "Cash On Hand:" -for cash_on_hand
        text cash_on_hand
        label "$"

        rcc "Overhead:" -for overhead
        percent overhead -defvalue 0
        label "% of income"

        rcc "Income, GOODS Sector:" -for income_goods
        text income_goods
        label "$/week"

        rcc "Income, BLACK Profits:" -for shares_black_nr
        text shares_black_nr
        label "shares"

        rcc "Income, BLACK Taxes:" -for income_black_tax
        text income_black_tax
        label "$/week"

        rcc "Income, POP Sector:" -for income_pop
        text income_pop
        label "$/week"

        rcc "Income, Graft on FA:" -for income_graft
        text income_graft
        label "$/week"

        rcc "Income, WORLD Sector:" -for income_world
        text income_world
        label "$/week"
    }
} {
    # FIRST, prepare the parameters
    prepare a                -toupper   -required -type actor
    prepare longname         -normalize
    prepare supports         -toupper             -type {ptype a+self+none}
    prepare cash_reserve     -toupper             -type money
    prepare cash_on_hand     -toupper             -type money
    prepare overhead         -num                 -type ipercent
    prepare income_goods     -toupper             -type money
    prepare shares_black_nr  -num                 -type iquantity
    prepare income_black_tax -toupper             -type money
    prepare income_pop       -toupper             -type money
    prepare income_graft     -toupper             -type money
    prepare income_world     -toupper             -type money

    returnOnError -final

    # NEXT, modify the actor
    setundo [actor mutate update [array get parms]]
}

# ACTOR:INCOME
#
# Updates existing actor's income.

order define ACTOR:INCOME {
    title "Update Actor Income"
    options -sendstates {PREP PAUSED TACTIC}

    form {
        rcc "Select Actor:" -for a
        key a -table gui_actors -keys a \
            -loadcmd {::orderdialog keyload a *} 

        rcc "Overhead:" -for overhead
        percent overhead -defvalue 0
        label "% of income"

        rcc "Income, GOODS Sector:" -for income_goods
        text income_goods
        label "$/week"

        rcc "Income, BLACK Profits:" -for shares_black_nr
        text shares_black_nr
        label "shares"

        rcc "Income, BLACK Taxes:" -for income_black_tax
        text income_black_tax
        label "$/week"

        rcc "Income, POP Sector:" -for income_pop
        text income_pop
        label "$/week"

        rcc "Income, Graft on FA:" -for income_graft
        text income_graft
        label "$/week"

        rcc "Income, WORLD Sector:" -for income_world
        text income_world
        label "$/week"
    }
} {
    # FIRST, prepare the parameters
    prepare a                -toupper   -required -type actor
    prepare overhead         -num                 -type ipercent
    prepare income_goods     -toupper             -type money
    prepare shares_black_nr  -num                 -type iquantity
    prepare income_black_tax -toupper             -type money
    prepare income_pop       -toupper             -type money
    prepare income_graft     -toupper             -type money
    prepare income_world     -toupper             -type money

    returnOnError -final

    # NEXT, fill in the empty parameters
    array set parms {
        longname     {}
        supports     {}
        cash_reserve {}
        cash_on_hand {}
    }

    # NEXT, modify the actor
    setundo [actor mutate update [array get parms]]
}

# ACTOR:SUPPORTS
#
# Updates existing actor's "supports" attribute.

order define ACTOR:SUPPORTS {
    title "Update Actor Supports"
    options -sendstates {PREP PAUSED TACTICS}

    form {
        rcc "Select Actor:" -for a
        key a -table gui_actors -keys a \
            -loadcmd {::orderdialog keyload a *} 
        
        rcc "Supports:" -for supports
        enum supports -listcmd {ptype a+self+none names}
    }
} {
    # FIRST, prepare the parameters
    prepare a            -toupper   -required -type actor
    prepare supports     -toupper   -required -type {ptype a+self+none}

    returnOnError -final

    # NEXT, fill in the empty parameters
    array set parms {
        longname         {}
        cash_reserve     {}
        cash_on_hand     {}
        overhead         {}
        income_goods     {}
        shares_black_nr  {}
        income_black_tax {}
        income_pop       {}
        income_graft     {}
        income_world     {}
    }

    # NEXT, modify the actor
    setundo [actor mutate update [array get parms]]
}

