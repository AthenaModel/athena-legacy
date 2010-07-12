#-----------------------------------------------------------------------
# TITLE:
#    unit.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Unit Manager
#
#    This module is responsible for managing units of all kinds, and 
#    operations upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type unit {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # TBD

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of unit names

    typemethod names {} {
        rdb eval {SELECT u FROM units}
    }


    # validate u
    #
    # u         Possibly, a unit name.
    #
    # Validates a unit name

    typemethod validate {u} {
        if {![rdb exists {SELECT u FROM units WHERE u=$u}]} {
            return -code error -errorcode INVALID \
                "Invalid unit name: \"$u\""
        }

        return $u
    }


    # get u ?parm?
    #
    # u      The unit ID
    # parm   A parameter name
    #
    # Retrieves a unit dictionary, or a particular parm value.
    # This is for use when dealing with one single unit, e.g., in
    # an order routine; when dealing with many units in a loop, always
    # use rdb eval.

    typemethod get {u {parm ""}} {
        # FIRST, get the unit
        rdb eval {SELECT * FROM units WHERE u=$u} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }

    #-------------------------------------------------------------------
    # Non-Mutators
    #
    # The following commands act on units on behalf of other simulation
    # modules.  They should not be used from orders, as they are not
    # mutators.


    # create parmdict
    #
    # parmdict   A parameter dictionary
    #
    #   n          The unit's neighborhood of origin
    #   g          The group to which it belongs
    #   a          The activity it is doing, or NONE
    #   tn         The unit's target neighborhood, i.e., where it is.
    #   personnel  The number of personnel in the unit.
    #   cid        The calendar ID driving this unit, or 0.
    #
    # Creates a unit with these parameters, picking a name, u,
    # and a random location in tn. The unit is presumed to be active.
    # Note that cid is 0 only for "base" units.
    #
    # NOTE: No notification is sent to the GUI!  Deployment is done
    # by the staffing algorithm in activity(sim), which is done at
    # start and during the time tick, which should be sufficient 
    # notification to the app.

    typemethod create {parmdict} {
        dict with parmdict {
            # FIRST, generate a name
            set u [format "%s-%s/%04d" $g $n $cid]

            # NEXT, generate a random location in tn
            set location [nbhood randloc $tn]

            # NEXT, retrieve the group type
            set gtype [group gtype $g]

            # NEXT, save the unit in the database.
            rdb eval {
                INSERT INTO units(u,cid,active,n,g,gtype,origin,a,
                                  personnel,location)
                VALUES($u,
                       $cid,
                       1,
                       $tn,
                       $g,
                       $gtype,
                       $n,
                       $a,
                       $personnel,
                       $location);
            }
        }
    }

    # deactivate u
    #
    # u    A unit name
    #
    # Marks the unit inactive, and assigns it 0 personnel.

    typemethod deactivate {u} {
        rdb eval {
            UPDATE units
            SET personnel = 0,
                active    = 0
            WHERE u=$u
        }
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  test/app_sim/Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # a change cannot be undone, the mutator returns the empty string.


    # mutate delete u
    #
    # u     A unit name
    #
    # Deletes the unit.

    typemethod {mutate delete} {u} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM units WHERE u=$u} row { unset row(*) }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM units WHERE u=$u;
        }

        # NEXT, notify the app
        notifier send ::unit <Entity> delete $u

        # NEXT, Return the undo script
        return [mytypemethod Restore [array get row]]
    }

    # Restore udict
    #
    # udict    row dict for deleted entity in units
    #
    # Restores the rows to the database

    typemethod Restore {udict} {
        rdb insert units $udict

        notifier send ::unit <Entity> create [dict get $udict u]
    }

    # mutate move u location
    #
    # u              The unit's ID
    # location       A new location (map coords) or ""
    #
    # Moves a unit given the parms, which are presumed to be
    # valid.

    typemethod {mutate move} {u location} {
        # FIRST, get the undo information
        rdb eval {
            SELECT location AS oldLocation FROM units
            WHERE u=$u
        } {}

        # NEXT, Update the unit
        rdb eval {
            UPDATE units
            SET location = $location
            WHERE u=$u
        }

        # NEXT, notify the app.
        notifier send ::unit <Entity> update $u

        # NEXT, Return the undo command
        return [mytypemethod mutate move $u $oldLocation]
    }

    # mutate personnel u personnel
    #
    # u              The unit's ID
    # personnel      The new number of personnel
    #
    # Sets the unit's personnel given the parms, which are presumed to be
    # valid, and marks the unit active.

    typemethod {mutate personnel} {u personnel} {
        # FIRST, get the undo information
        rdb eval {
            SELECT personnel AS oldPersonnel FROM units
            WHERE u=$u
        } {}

        # NEXT, Update the unit
        rdb eval {
            UPDATE units
            SET   personnel = $personnel,
                  active    = 1
            WHERE u=$u
        }

        # NEXT, notify the app.
        notifier send ::unit <Entity> update $u

        # NEXT, Return the undo command
        return [mytypemethod mutate personnel $u $oldPersonnel]
    }


    #-------------------------------------------------------------------
    # Order Helpers

    # ValidateActivity gtypes a
    #
    # gtypes     List of one or more group types
    # a          An activity
    #
    # Ensures that the activity is valid for the group type(s)

    typemethod ValidateActivity {gtypes a} {

        foreach gtype $gtypes {
            switch -exact -- $gtype {
                CIV     { activity civ validate $a }
                FRC     { activity frc validate $a }
                ORG     { activity org validate $a }
                default { error "Unexpected gtype: \"$gtype\""   }
            }
        }
    }

    # RefreshUnitOrigin field parmdict
    #
    # field     The "origin" field in a U:CREATE order.
    # parmdict  The current values of the various fields.
    #
    # Sets the valid origin values, if it's not set.

    typemethod RefreshUnitOrigin {field parmdict} {
        dict with parmdict {
            set gtype [group gtype $g]

            if {$gtype eq "CIV"} {
                $field configure -values [nbgroup nFor $g] -state normal
            } else {
                $field configure -values [list NONE]
                $field set NONE
                $field configure -state disabled
            }
        }
    }

    # RefreshUnitName field parmdict
    #
    # field     The "u" field in a U:CREATE order.
    # parmdict  The current values of the various fields.
    #
    # Initializes the unit name, if it's not set.
    #
    # TBD: Need a better mechanism for generating names!

    typemethod RefreshUnitName {field parmdict} {
        dict with parmdict {
            # FIRST, leave it alone if the group is unknown.
            if {$g eq ""} {
                return
            }

            # NEXT, if the name is already set, and doesn't look like
            # an automatically generated name, you can't replace it.
            if {$u ne ""} {
                if {![regexp {(.*)/\d\d\d\d$} $u]} {
                    return
                }
            }

            # NEXT, get the group type; if it's CIV, leave it
            # alone if the origin is unknown.  Determine the
            # root and the initial count.
            set gtype [group gtype $g]

            if {$gtype eq "CIV"} {
                if {$origin eq ""} {
                    return
                }

                set root $g-$origin

                set count [rdb onecolumn {
                    SELECT count(u) FROM units
                    WHERE g=$g AND origin=$origin;
                }]

            } else {
                set root $g

                set count [rdb onecolumn {
                    SELECT count(u) FROM units
                    WHERE g=$g;
                }]
            }
            

            # NEXT, generate a unit name for this group.
            set u [format "%s/%04d" $root [incr count]]

            while {[rdb exists {SELECT u FROM units WHERE u=$u}]} {
                set u [format "%s/%04d" $root [incr count]]
            }

            $field set $u
        }
    }


}

#-------------------------------------------------------------------
# Orders: UNIT:*

# UNIT:MOVE
#
# Moves an existing unit.

order define ::unit UNIT:MOVE {
    title "Move Unit"
    options \
        -table          gui_units     \
        -sendstates     {PREP PAUSED}

    parm u          key   "Unit"       -tags unit
    parm location   text  "Location"   -tags point
} {
    # FIRST, prepare the parameters
    prepare u          -toupper -required -type unit
    prepare location   -toupper -required -type refpoint

    returnOnError

    validate location {
        set n [nbhood find {*}$parms(location)]

        if {$n ne [unit get $parms(u) n]} {
            reject location "Cannot remove unit from its neighborhood"
        }
    }

    returnOnError -final

    # NEXT, move the unit
    lappend undo [$type mutate move $parms(u) $parms(location)]


    setundo [join $undo \n]
}










