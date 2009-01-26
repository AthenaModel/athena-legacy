#-----------------------------------------------------------------------
# TITLE:
#    sat.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Satisfaction Curve Inputs Manager
#
#    This module is responsible for managing the scenario's satisfaction
#    curve inputs as groups come and ago, and for allowing the analyst
#    to update particular satisfaction levels.
#
#-----------------------------------------------------------------------

snit::type sat {
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

    typemethod init {} {
        log detail sat "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module's in-memory data from the database.
    
    typemethod reconfigure {} {
        # Nothing to do
    }

    #-------------------------------------------------------------------
    # Queries

    # validate n g c
    #
    # n       A neighborhood ID
    # g       A group ID
    # c       A concern ID
    #
    # Throws INVALID if there's no satisfaction level for the 
    # specified combination.

    typemethod validate {n g c} {
        if {![$type exists $n $g $c]} {
            return -code error -errorcode INVALID \
      "Satisfaction is not tracked for this neighborhood, group, and concern."
        }
    }

    # exists n g c
    #
    # n       A neighborhood ID
    # g       A group ID
    # c       A concern ID
    #
    # Returns 1 if there is such a satisfaction curve, and 0 otherwise.

    typemethod exists {n g c} {
        rdb exists {
            SELECT * FROM sat_ngc WHERE n=$n AND g=$g AND c=$c
        }
    }

    # group validate g
    #
    # g    A group name
    #
    # Throws INVALID if g is not the name of a group for which 
    # satisfaction can be tracked.

    typemethod {group validate} {g} {
        set groups [$type group names]

        if {$g ni $groups} {
            return -code error -errorcode INVALID \
                "Invalid group, should be one of: [join $groups {, }]"
        }

        return $g
    }

    # group names
    #
    # Returns a list of the names of the satisfaction groups.

    typemethod {group names} {} {
        return [rdb eval {
            SELECT g FROM groups
            WHERE gtype IN ('CIV', 'ORG')
        }]

        return $g
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate nbgroupCreated n g
    #
    # n     Neighborhood ID of nbgroup
    # g     CIV Group ID of nbgroup
    #
    # When a new neighborhood group is created, nbgroup calls this
    # mutator to populate the sat_ngc table with the initial
    # satisfaction levels.

    typemethod {mutate nbgroupCreated} {n g} {
        rdb eval {
            INSERT INTO sat_ngc
            SELECT $n, $g, c, 0.0, 0.0, 1.0 FROM civ_concerns;
        }

        foreach c [rdb eval {SELECT c FROM civ_concerns}] {
            notifier send $type <Entity> create $n $g $c
        }

        return [mytypemethod mutate nbgroupDeleted $n $g]
    }

    # mutate nbgroupDeleted n g
    #
    # n     Neighborhood ID of nbgroup
    # g     CIV Group ID of nbgroup
    #
    # When a neighborhood group is deleted, nbgroup calls this
    # mutator to delete the group's satisfaction levels.

    typemethod {mutate nbgroupDeleted} {n g} {
        # FIRST, get the undo information
        set undo [list]

        rdb eval {
            SELECT * FROM sat_ngc
            WHERE n=$n AND g=$g
        } row {
            unset -nocomplain row(*)
            lappend undo [mytypemethod mutate update [array get row]]
        }

        assert {[llength $undo] > 0}

        # NEXT, Delete the satisfaction levels
        rdb eval {
            DELETE FROM sat_ngc
            WHERE n=$n AND g=$g;
        } {}

        foreach c [rdb eval {SELECT c FROM civ_concerns}] {
            notifier send $type <Entity> delete $n $g $c
        }
        
        # NEXT, Return the undo script
        return [join $undo \n]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
    #
    #    n                Neighborhood ID
    #    g                Group ID
    #    c                Concern
    #    sat0             A new initial satisfaction, or ""
    #    trend0           A new long-term trend, or ""
    #    saliency         A new saliency, or ""
    #
    # Updates a satisfaction level the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM sat_ngc
                WHERE n=$n AND g=$g AND c=$c
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE sat_ngc
                SET sat0     = nonempty($sat0,     sat0),
                    trend0   = nonempty($trend0,   trend0),
                    saliency = nonempty($saliency, saliency)
                WHERE n=$n AND g=$g AND c=$c
            } {}

            # NEXT, notify the app.
            notifier send ::sat <Entity> update $n $g $c

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

}

#-------------------------------------------------------------------
# Orders: SAT:*

# GROUP:NBHOOD:UPDATE
#
# Updates existing groups.

order define ::sat SAT:UPDATE {
    title "Update Satisfaction Curve"
    table sat_ngc
    keys  {n g c}
    parms {
        n              {ptype nbhood    label "Neighborhood"  }
        g              {ptype satgroup  label "Group"         }
        c              {ptype concern   label "Concern"       }
        sat0           {ptype sat       label "Sat at T0"     }
        trend0         {ptype trend     label "Trend0"        }
        saliency       {ptype saliency  label "Saliency"      }
    }
} {
    # FIRST, prepare the parameters
    prepare n        -trim -toupper  -required -type nbhood
    prepare g        -trim -toupper  -required -type [list sat group]
    prepare c        -trim -toupper  -required -type econcern

    prepare sat0     -trim -toupper \
        -type qsat      -xform [list qsat value]
    prepare trend0   -trim -toupper \
        -type qtrend    -xform [list qtrend value]
    prepare saliency -trim -toupper \
        -type qsaliency -xform [list qsaliency value]

    returnOnError

    # NEXT, do cross-validation
    validate c {
        sat validate $parms(n) $parms(g) $parms(c)
    }

    returnOnError

    # NEXT, modify the curve
    setundo [$type mutate update [array get parms]]
}

