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

        if {![$type exists $id]} {
            return -code error -errorcode INVALID \
               "Group $f has no ROE for group $g in $n."
        }

        return [list $n $f $g]
    }

    # exists id
    #
    # id      list {n f g}
    #
    # Returns 1 if f has an attroe with g in n

    typemethod exists {id} {
        lassign $id n f g

        rdb exists {
            SELECT * FROM attroe_nfg WHERE n=$n AND f=$f AND g=$g
        }
    }


    # uniformed validate id
    #
    # id     An nfg attroe ID, [list $n $f $g]
    #
    # Throws INVALID if there's no ROE for the 
    # specified combination, or if f isn't uniformed.

    typemethod {uniformed validate} {id} {
        lassign $id n f g

        set n [nbhood validate $n]
        set f [frcgroup uniformed validate $f]
        set g [frcgroup nonuniformed validate $g]

        if {![$type exists $id]} {
            return -code error -errorcode INVALID \
               "Group $f has no ROE for group $g in $n."
        }

        return [list $n $f $g]
    }


    # uf_unused validate id
    #
    # id     An nfg attroe ID, [list $n $f $g]
    #
    # Throws INVALID if the id can't be a valid attroeuf ID, or
    # if it's already in use.

    typemethod {uf_unused validate} {id} {
        lassign $id n f g

        set n [nbhood validate $n]
        set f [frcgroup uniformed validate $f]
        set g [frcgroup nonuniformed validate $g]

        if {[$type exists $id]} {
            return -code error -errorcode INVALID \
                "Group $f already has an ROE with group $g in $n"
        }

        return [list $n $f $g]
    }


    # nonuniformed validate id
    #
    # id     An nfg attroe ID, [list $n $f $g]
    #
    # Throws INVALID if there's no ROE for the 
    # specified combination, or if f is uniformed.

    typemethod {nonuniformed validate} {id} {
        lassign $id n f g

        set n [nbhood validate $n]
        set f [frcgroup nonuniformed validate $f]
        set g [frcgroup uniformed validate $g]

        if {![$type exists $id]} {
            return -code error -errorcode INVALID \
               "Group $f has no ROE for group $g in $n."
        }

        return [list $n $f $g]
    }


    # nf_unused validate id
    #
    # id     An nfg attroe ID, [list $n $f $g]
    #
    # Throws INVALID if the id can't be a valid attroenf ID, or
    # if it's already in use.

    typemethod {nf_unused validate} {id} {
        lassign $id n f g

        set n [nbhood validate $n]
        set f [frcgroup nonuniformed validate $f]
        set g [frcgroup uniformed validate $g]

        if {[$type exists $id]} {
            return -code error -errorcode INVALID \
                "Group $f already has an ROE with group $g in $n"
        }

        return [list $n $f $g]
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
            lappend undo [$type mutate delete [list $n $f $g]]
        }

        # NEXT, delete entries for which group f does not exist.
        rdb eval {
            SELECT n, f, attroe_nfg.g AS g
            FROM attroe_nfg 
            LEFT OUTER JOIN frcgroups ON (attroe_nfg.f = frcgroups.g)
            WHERE frcgroups.uniformed IS NULL
        } {
            lappend undo [$type mutate delete [list $n $f $g]]
        }

        # NEXT, delete entries for which group g does not exist.
        rdb eval {
            SELECT n, f, attroe_nfg.g AS g
            FROM attroe_nfg 
            LEFT OUTER JOIN frcgroups ON (attroe_nfg.g = frcgroups.g)
            WHERE frcgroups.uniformed IS NULL
        } {
            lappend undo [$type mutate delete [list $n $f $g]]
        }

        # NEXT, return the undo script
        return [join $undo \n]
    }


    # mutate create parmdict
    #
    # parmdict     A dictionary of ROE parms
    #
    #    id               list {n f g}
    #    uniformed        Flag, Group f is uniformed
    #    roe              The ROE value
    #    cooplimit        The cooperation limit
    #    rate             Attacks/day (when f is non-uniformed)
    #
    # Creates an attacking ROE given the parms, which are presumed to be
    # valid.
    # table.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            lassign $id n f g

            # FIRST, Put the group in the database
            rdb eval {
                INSERT INTO attroe_nfg(n,f,g,uniformed,roe,cooplimit,rate)
                VALUES($n,
                       $f,
                       $g,
                       $uniformed,
                       $roe,
                       $cooplimit,
                       $rate);
            }

            # NEXT, Return the undo command
            set undo [list]
            lappend undo [mytypemethod mutate delete $id]

            return [join $undo \n]
        }
    }


    # mutate delete id
    #
    # id     An attacking ROE ID, list {n f g}
    #
    # Deletes the entry.

    typemethod {mutate delete} {id} {
        # FIRST, get the undo information
        lassign $id n f g

        rdb eval {
            SELECT * FROM attroe_nfg WHERE n=$n AND f=$f AND g=$g
        } row {
            unset row(*)
        }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM attroe_nfg WHERE n=$n AND f=$f AND g=$g;
        }

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
    }



    # mutate update parmdict
    #
    # parmdict     A dictionary of attacking ROE parms
    #
    #    id               list {n f g}
    #    roe              The ROE value
    #    cooplimit        The cooperation limit
    #    rate             Attacks/day (when f is non-uniformed)
    #
    # Updates a entry given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n f g
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM attroe_nfg
                WHERE n=$n AND f=$f AND g=$g
            } undoData {
                unset undoData(*)
                set undoData(id) $id
            }

            # NEXT, Update the entry
            rdb eval {
                UPDATE attroe_nfg
                SET roe       = nonempty($roe,       roe),
                    cooplimit = nonempty($cooplimit, cooplimit),
                    rate      = nonempty($rate,      rate)
                WHERE n=$n AND f=$f AND g=$g
            } {}

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }
}


#-------------------------------------------------------------------
# Orders: ATTROE:*

# ATTROE:UF:CREATE
#
# Creates new attacking ROEs for UF vs NF.

order define ATTROE:UF:CREATE {
    title "Create Attacking ROE (Uniformed)"

    options \
        -sendstates {PREP PAUSED}

    parm id         newkey "Combatants"   -universe gui_attroeuf_univ    \
                                          -table gui_attroeuf_nfg        \
                                          -key   {n f g}                 \
                                          -labels {"In" "Frc" "Attacks"}
    parm roe        enum   "ROE"          -type eattroeuf -defval "ATTACK"
    parm cooplimit  coop   "Coop. Limit"  -defval 50.0
} {
    # FIRST, prepare and validate the parameters
    prepare id             -toupper -required -type {attroe uf_unused}
    prepare roe            -toupper -required -type eattroeuf
    prepare cooplimit      -toupper -required -type qcooperation

    returnOnError -final

    # NEXT, create the ROE
    set parms(uniformed) 1
    set parms(rate)      ""

    lappend undo [attroe mutate create [array get parms]]
    
    setundo [join $undo \n]

    return
}

# ATTROE:NF:CREATE
#
# Creates new attacking ROEs for NF vs UF

order define ATTROE:NF:CREATE {
    title "Create Attacking ROE (Non-Uniformed)"

    options \
        -sendstates {PREP PAUSED}

    parm id         newkey "Combatants"  -universe gui_attroenf_univ    \
                                         -table gui_attroenf_nfg        \
                                         -key   {n f g}                 \
                                         -labels {"In" "Frc" "Attacks"}
    parm roe        enum   "ROE"         -type eattroenf \
                                         -defval "HIT_AND_RUN"
    parm cooplimit  coop   "Coop. Limit" -defval 50.0
    parm rate       text   "Attacks/Day" -defval 0.5
} {
    # FIRST, prepare and validate the parameters
    prepare id             -toupper -required -type {attroe nf_unused}
    prepare roe            -toupper -required -type eattroenf
    prepare cooplimit      -toupper -required -type qcooperation
    prepare rate           -toupper -required -type rrate

    returnOnError -final

    # NEXT, create the ROE
    set parms(uniformed) 0

    lappend undo [attroe mutate create [array get parms]]
    
    setundo [join $undo \n]

    return
}


# ATTROE:DELETE

order define ATTROE:DELETE {
    title "Delete Attacking ROE"
    options \
        -sendstates {PREP PAUSED}

    parm id key  "Combatants"    -table gui_attroe_nfg          \
                                 -key   {n f g}                 \
                                 -labels {"In" "Frc" "Attacks"} 
} {
    # FIRST, prepare the parameters
    prepare id -toupper -required -type attroe

    returnOnError -final

    # NEXT, Delete the ROE, unless the user says no.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     ATTROE:DELETE                \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure 
                            you really want to delete this ROE?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, delete the ROE
    lappend undo [attroe mutate delete $parms(id)]
    
    setundo [join $undo \n]

    return
}


# ATTROE:UF:UPDATE
#
# Updates existing ROEs for UF vs NF

order define ATTROE:UF:UPDATE {
    title "Update Attacking ROE (Uniformed)"
    options \
        -schedulestates {PREP PAUSED}                    \
        -sendstates     {PREP PAUSED}                    \
        -refreshcmd     {orderdialog refreshForKey id *}

    parm id         key  "Combatants"  -table  gui_attroeuf_nfg       \
                                       -key    {n f g}                \
                                       -labels {"In" "Frc" "Attacks"}
    parm roe        enum "ROE"         -type   eattroeuf
    parm cooplimit  coop "Coop. Limit"
} {
    # FIRST, prepare the parameters
    prepare id             -toupper -required -type {attroe uniformed}
    prepare roe            -toupper           -type eattroeuf
    prepare cooplimit      -toupper           -type qcooperation

    returnOnError -final

    # NEXT, modify the group
    set parms(rate) ""
    lappend undo [attroe mutate update [array get parms]]

    setundo [join $undo \n]

    return
}


# ATTROE:NF:UPDATE
#
# Updates existing ROEs for NF vs UF

order define ATTROE:NF:UPDATE {
    title "Update Attacking ROE (Non-Uniformed)"
    options \
        -schedulestates {PREP PAUSED}                    \
        -sendstates     {PREP PAUSED}                    \
        -refreshcmd     {orderdialog refreshForKey id *}

    parm id         key  "Combatants"  -table  gui_attroenf_nfg       \
                                       -key    {n f g}                \
                                       -labels {"In" "Frc" "Attacks"}
    parm roe        enum "ROE"         -type eattroenf
    parm cooplimit  coop "Coop. Limit"
    parm rate       text "Attacks/Day"

} {
    # FIRST, prepare the parameters
    prepare id             -toupper -required -type {attroe nonuniformed}
    prepare roe            -toupper           -type eattroenf
    prepare cooplimit      -toupper           -type qcooperation
    prepare rate           -toupper           -type rrate

    returnOnError -final

    # NEXT, modify the group
    lappend undo [attroe mutate update [array get parms]]

    setundo [join $undo \n]

    return
}


# ATTROE:UF:UPDATE:MULTI
#
# Updates multiple ROEs (UF vs NF)

order define ATTROE:UF:UPDATE:MULTI {
    title "Update Multiple Attacking ROEs (Uniformed)"
    options \
        -schedulestates {PREP PAUSED}    \
        -sendstates     {PREP PAUSED}

    parm ids        multi "Combatants"   -table gui_attroeuf_nfg \
                                         -key id
    parm roe        enum  "ROE"          -type  eattroeuf
    parm cooplimit  coop  "Coop. Limit"
} {
    # FIRST, prepare the parameters
    prepare ids            -toupper  -required -listof {attroe uniformed}
    prepare roe            -toupper            -type eattroeuf
    prepare cooplimit      -toupper            -type qcooperation

    returnOnError -final

    # NEXT, modify the group
    set undo [list]

    set parms(rate) ""

    foreach parms(id) $parms(ids) {
        lappend undo [attroe mutate update [array get parms]]
    }

    setundo [join $undo \n]

    return
}


# ATTROE:NF:UPDATE:MULTI
#
# Updates multiple ROEs (NF vs UF)

order define ATTROE:NF:UPDATE:MULTI {
    title "Update Multiple Attacking ROEs (Non-Uniformed)"
    options \
        -schedulestates {PREP PAUSED}    \
        -sendstates     {PREP PAUSED}

    parm ids        multi "Combatants"  -table gui_attroenf_nfg \
                                        -key id
    parm roe        enum  "ROE"         -type eattroenf
    parm cooplimit  coop  "Coop. Limit"
    parm rate       text  "Attacks/Day"
} {
    # FIRST, prepare the parameters
    prepare ids            -toupper  -required -listof {attroe nonuniformed}
    prepare roe            -toupper            -type eattroenf
    prepare cooplimit      -toupper            -type qcooperation
    prepare rate           -toupper            -type rrate

    returnOnError -final

    # NEXT, modify the group
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [attroe mutate update [array get parms]]
    }

    setundo [join $undo \n]

    return
}




