#-----------------------------------------------------------------------
# TITLE:
#    attroe.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Athena Attrition Model: Attacking Ruels of Engagement.
#
#    This module implements the Attacking ROE entity.
#
#-----------------------------------------------------------------------

snit::type ::attroe {
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

    # TBD: nothing to do

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # validate id
    #
    # id     An nfg attroe ID, [list $n $f $g]
    #
    # Throws INVALID if there's no ROE for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id n f g

        set n [nbhood validate $n]
        set f [frcgroup validate $f]
        set g [frcgroup validate $g]

        if {![$type exists $n $f $g]} {
            return -code error -errorcode INVALID \
               "Group $f has no ROE for group $g in $n."
        }

        return [list $n $f $g]
    }

    # exists n f g
    #
    # n       A nbhood ID
    # f       A force group ID
    # g       A force group ID
    #
    # Returns 1 if f has an attroe with g in n

    typemethod exists {n f g} {
        rdb exists {
            SELECT * FROM attroe_nfg WHERE n=$n AND f=$f AND g=$g
        }
    }


    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate reconcile
    #
    # Deletes attacking ROEs for groups or neighborhoods that no 
    # longer exist, returning an undo script.

    typemethod {mutate reconcile} {} {
        # FIRST, prepare to return an undo script
        set undo [list]

        # NEXT, delete entries for which no nbhood exists.
        rdb eval {
            SELECT n,f,g
            FROM attroe_nfg LEFT OUTER JOIN nbhoods USING (n)
            WHERE longname IS NULL
        } {
            lappend undo [$type mutate delete $n $f $g]
        }

        # NEXT, delete entries for which group f does not exist.
        rdb eval {
            SELECT n, f, attroe_nfg.g AS g
            FROM attroe_nfg 
            LEFT OUTER JOIN frcgroups ON (attroe_nfg.f = frcgroups.g)
            WHERE uniformed IS NULL
        } {
            lappend undo [$type mutate delete $n $f $g]
        }

        # NEXT, delete entries for which group g does not exist.
        rdb eval {
            SELECT n, f, attroe_nfg.g AS g
            FROM attroe_nfg 
            LEFT OUTER JOIN frcgroups ON (attroe_nfg.g = frcgroups.g)
            WHERE uniformed IS NULL
        } {
            lappend undo [$type mutate delete $n $f $g]
        }

        # NEXT, return the undo script
        return [join $undo \n]
    }


    # mutate create parmdict
    #
    # parmdict     A dictionary of ROE parms
    #
    #    n                The neighborhood ID
    #    f                The attacking force group ID
    #    g                The attacked force group ID
    #    roe              The ROE value
    #    cooplimit        The cooperation limit
    #    rate             Attacks/day (when f is non-uniformed)
    #
    # Creates an attacking ROE given the parms, which are presumed to be
    # valid.
    # table.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO attroe_nfg(n,f,g,roe,cooplimit,rate)
                VALUES($n,
                       $f,
                       $g,
                       $roe,
                       $cooplimit,
                       $rate);
            }

            # NEXT, notify the app.
            notifier send ::attroe <Entity> create [list $n $f $g]

            # NEXT, Return the undo command
            set undo [list]
            lappend undo [mytypemethod mutate delete $n $f $g]

            return [join $undo \n]
        }
    }


    # mutate delete n f g
    #
    # n f g     An attacking ROE ID
    #
    # Deletes the entry.

    typemethod {mutate delete} {n f g} {
        # FIRST, get the undo information
        rdb eval {
            SELECT * FROM attroe_nfg WHERE n=$n AND f=$f AND g=$g
        } row {
            unset row(*)
        }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM attroe_nfg WHERE n=$n AND f=$f AND g=$g;
        }

        # NEXT, notify the app.
        notifier send ::attroe <Entity> delete [list $n $f $g]

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row]]
    }

    # Restore parmdict
    #
    # parmdict     row dict for deleted entity
    #
    # Restores the entity in the database

    typemethod Restore {parmdict} {
        rdb insert attroe_nfg $parmdict

        dict with parmdict {
            notifier send ::attroe <Entity> create [list $n $f $g]
        }
    }



    # mutate update parmdict
    #
    # parmdict     A dictionary of attacking ROE parms
    #
    #    n                Neighborhood ID
    #    f                Force Group ID
    #    g                Force Group ID
    #    roe              The ROE value
    #    cooplimit        The cooperation limit
    #    rate             Attacks/day (when f is non-uniformed)
    #
    # Updates a entry given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM attroe_nfg
                WHERE n=$n AND f=$f AND g=$g
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the entry
            rdb eval {
                UPDATE attroe_nfg
                SET roe       = nonempty($roe,       roe),
                    cooplimit = nonempty($cooplimit, cooplimit),
                    rate      = nonempty($rate,      rate)
                WHERE n=$n AND f=$f AND g=$g
            } {}

            # NEXT, notify the app.
            notifier send ::attroe <Entity> update [list $n $f $g]

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}


#-------------------------------------------------------------------
# Orders: ROE:ATTACK:*

# ROE:ATTACK:UPDATE
#
# Updates existing relationships

order define ::rel ROE:ATTACK:UPDATE {
    title "Update Relationship"
    options -sendstates PREP -table gui_attroe_nfg -tags nfg

    parm n    key   "Neighborhood"   -tags nbhood
    parm f    key   "Of Group"       -tags group
    parm g    key   "With Group"     -tags group
    parm rel  text  "Relationship"   ;# TBD: Might want -refreshcmd
} {
    # FIRST, prepare the parameters
    prepare n        -toupper  -required -type [list ::rel nbhood]
    prepare f        -toupper  -required -type group
    prepare g        -toupper  -required -type group
    prepare rel      -toupper            -type rgrouprel

    returnOnError

    # NEXT, do cross-validation
    validate g {
        rel validate [list $parms(n) $parms(f) $parms(g)]
    }

    returnOnError

    # NEXT, modify the curve
    setundo [$type mutate update [array get parms]]
}


# ROE:ATTACK:UPDATE:MULTI
#
# Updates multiple existing relationships

order define ::rel ROE:ATTACK:UPDATE:MULTI {
    title "Update Multiple Relationships"
    options -sendstates PREP -table gui_attroe_nfg

    parm ids  multi  "IDs"
    parm rel  text   "Relationship"  ;# TBD: Might want -refreshcmd
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof rel

    prepare rel      -toupper            -type rgrouprel

    returnOnError


    # NEXT, modify the curves
    set undo [list]

    foreach id $parms(ids) {
        lassign $id parms(n) parms(f) parms(g)

        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}






