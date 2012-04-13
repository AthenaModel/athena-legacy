#-----------------------------------------------------------------------
# TITLE:
#    coop.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Cooperation Manager
#
#    This module is responsible for managing cooperations between
#    groups as groups come and ago, and for allowing the analyst
#    to update particular cooperations.
#
#    Every civ group has a cooperation with every frc group.
#
# CREATION/DELETION:
#    coop_fg records are created explicitly by the civgroup(sim)
#    and frcgroup(sim) modules when groups of these types are deleted,
#    and are destroyed via cascading delete when groups of these
#    types are destroyed.
#
#-----------------------------------------------------------------------

snit::type coop {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An fg cooperation ID, [list $f $g]
    #
    # Throws INVALID if there's no cooperation for the 
    # specified combination.

    typemethod validate {id} {
        lassign $id f g

        set f [civgroup validate $f]
        set g [frcgroup validate $g]

        return [list $f $g]
    }

    # exists f g
    #
    # f       A group ID
    # g       A group ID
    #
    # Returns 1 if cooperation is tracked between f and g.

    typemethod exists {f g} {
        rdb exists {
            SELECT * FROM coop_fg WHERE f=$f AND g=$g
        }
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.


    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    id               list {f g}
    #    coop0            Cooperation of f with g at time 0.
    #
    # Updates a cooperation given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id f g

            # FIRST, get the undo information
            set data [rdb grab coop_fg {f=$f AND g=$g}]

            # NEXT, Update the group
            rdb eval {
                UPDATE coop_fg
                SET coop0 = nonempty($coop0, coop0)
                WHERE f=$f AND g=$g
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}


#-------------------------------------------------------------------
# Orders: COOP:*

# COOP:UPDATE
#
# Updates existing cooperations

order define COOP:UPDATE {
    title "Update Initial Cooperation"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey id *}

    parm id      key   "Curve"           -table  gui_coop_fg    \
                                         -keys   {f g}          \
                                         -labels {"Of" "With"}
    parm coop0   coop  "Cooperation"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type coop
    prepare coop0    -toupper            -type qcooperation \
        -xform [list qcooperation value]

    returnOnError -final

    # NEXT, modify the curve
    setundo [coop mutate update [array get parms]]
}


# COOP:UPDATE:MULTI
#
# Updates multiple existing cooperations

order define COOP:UPDATE:MULTI {
    title "Update Initial Cooperation (Multi)"
    options \
        -sendstates PREP                                  \
        -refreshcmd {orderdialog refreshForMulti ids *}
 
    parm ids     multi  "IDs"              -table gui_coop_fg \
                                           -key id
    parm coop0   coop   "Cooperation"
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof coop

    prepare coop0    -toupper            -type qcooperation \
        -xform [list qcooperation value]

    returnOnError -final

    # NEXT, modify the curves
    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [coop mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


