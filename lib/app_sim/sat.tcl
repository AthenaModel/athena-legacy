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
#    Civilian Satisfaction curves are created and deleted when nbgroups 
#    are created and deleted.
#
#    Organization Satisfaction curves are created and deleted:
#
#    * For each neighborhood when an org group is created/deleted.
#    * For each org group when a neighborhood is created/deleted.
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
            SELECT $n, $g, c, 'CIV', 0.0, 0.0, 1.0 FROM civ_concerns;
        }

        foreach c [rdb eval {SELECT c FROM civ_concerns}] {
            notifier send $type <Entity> create $n $g $c
        }

        # Note: No undo script is required; undoing an nbgroup creation
        # requires an nbgroup deletion, which will call nbgroupDeleted
        # explicitly.
        return
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

    # mutate nbhoodCreated n
    #
    # n   Neighborhood ID
    #
    # When a neighborhood is created, nbhood calls this mutator to create
    # satisfaction curves for the neighborhood and all org groups.

    typemethod {mutate nbhoodCreated} {n} {
        rdb eval {
            INSERT INTO sat_ngc
            SELECT $n, g, c, 'ORG', 0.0, 0.0, 1.0 
            FROM orggroups JOIN org_concerns;
        }

        foreach {g c} [rdb eval {
            SELECT g,c FROM sat_ngc
            WHERE n = $n
        }] {
            notifier send $type <Entity> create $n $g $c
        }

        # Note: No undo script is required; undoing a nbhood creation
        # requires a nbhood deletion, which will call nbhoodDeleted
        # explicitly.
        return
    }


    # mutate nbhoodDeleted n
    #
    # n   Neighborhood ID
    #
    # When a neighborhood is deleted, nbhood calls this mutator to delete
    # the satisfaction curves for the neighborhood and all org groups.
    
    typemethod {mutate nbhoodDeleted} {n} {
        # FIRST, get the undo information: updates to restore any
        # non-default values.
        set undo [list]
        set keys [list]

        rdb eval {
            SELECT * FROM sat_ngc
            WHERE n=$n AND gtype='ORG'
        } row {
            unset -nocomplain row(*)
            lappend keys $row(n) $row(g) $row(c)
            lappend undo [mytypemethod mutate update [array get row]]
        }

        # NEXT, Delete the satisfaction levels
        rdb eval {
            DELETE FROM sat_ngc
            WHERE n=$n AND gtype='ORG';
        } {}

        # NEXT, notify the app.
        foreach {n g c} $keys {
            notifier send $type <Entity> delete $n $g $c
        }
        
        # NEXT, Return the undo script
        return [join $undo \n]
    }

    # mutate orggroupCreated g
    #
    # g   ORG Group ID
    #
    # When an ORG group is created, orggroup calls this mutator to create
    # satisfaction curves for this group in all neighborhoods.

    typemethod {mutate orggroupCreated} {g} {
        rdb eval {
            INSERT INTO sat_ngc
            SELECT n, $g, c, 'ORG', 0.0, 0.0, 1.0 
            FROM nbhoods JOIN org_concerns;
        }

        foreach {n c} [rdb eval {
            SELECT n,c FROM sat_ngc
            WHERE g = $g
        }] {
            notifier send $type <Entity> create $n $g $c
        }

        # Note: No undo script is required; undoing an ORG group creation
        # requires an ORG group deletion, which will call orggroupDeleted
        # explicitly.
        return
    }


    # mutate orggroupDeleted g
    #
    # g   ORG Group ID
    #
    # When an ORG group is deleted, orggroup calls this mutator to delete
    # the satisfaction curves for this group in all neighborhoods.

    typemethod {mutate orggroupDeleted} {g} {
        # FIRST, get the undo information: updates to restore any
        # non-default values.
        set undo [list]
        set keys [list]

        rdb eval {
            SELECT * FROM sat_ngc
            WHERE g=$g
        } row {
            unset -nocomplain row(*)
            lappend keys $row(n) $row(g) $row(c)
            lappend undo [mytypemethod mutate update [array get row]]
        }

        # NEXT, Delete the satisfaction levels
        rdb eval {
            DELETE FROM sat_ngc
            WHERE g=$g;
        } {}

        # NEXT, notify the app.
        foreach {n g c} $keys {
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

