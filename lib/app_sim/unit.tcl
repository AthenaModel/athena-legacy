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
    # Initialization

    typemethod init {} {
        log detail unit "Initialized"
    }

    # reconfigure
    #
    # Reconfigures the module's in-memory data from the database.
    
    typemethod reconfigure {} {
        # Nothing to do
    }

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

    # group names
    #
    # Returns the names of groups for which units can be created.

    typemethod {group names} {} {
        rdb eval {
            SELECT g FROM groups WHERE gtype IN ('FRC', 'ORG')
            ORDER BY g
        }
    }

    # unit group validate g
    #
    # g     A group name
    #
    # Validates a group name.

    typemethod {group validate} {g} {
        set names [$type group names]

        if {$g ni $names} {
            set names [join $names ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid unit group, $msg"
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

    # mutate reconcile
    #
    # Deletes units for which the owning group no longer exists.
    # Clears the "n" field for neighborhoods that no longer exist.
    # civilian group no longer exists.

    typemethod {mutate reconcile} {} {
        # FIRST, delete units for which no group exists.
        set undo [list]

        rdb eval {
            SELECT u
            FROM units LEFT OUTER JOIN groups USING (g)
            WHERE longname IS NULL
        } {
            lappend undo [$type mutate delete $u]
        }

        # NEXT, try to set n for units that have no neighborhood.

        rdb eval {
            SELECT u, location
            FROM units WHERE n = ''
        } { 
            if {[$type FindNbhood $u $location]} {
                lappend undo [mytypemethod ClearNbhood $u]
            }
        }

        # NEXT, clear n for neighborhoods that
        # no longer exist.

        rdb eval {
            SELECT u, location
            FROM units LEFT OUTER JOIN nbhoods USING (n)
            WHERE n != '' AND refpoint IS NULL
        } {
            $type ClearNbhood $u

            lappend undo [mytypemethod FindNbhood $u $location]
        }

        return [join $undo \n]
    }

    # FindNbhood u location
    #
    # u     A unit
    # 
    # Computes and saves the neighborhood for the unit on reconcile.
    # Returns 1 if nbhood found, and 0 otherwise.

    typemethod FindNbhood {u location} {
        # FIRST, find the neighborhood.
        set n [nbhood find {*}$location]

        if {$n eq ""} {
            return 0
        }

        # NEXT, save it, and notify the app.
        rdb eval {
            UPDATE units
            SET n = $n
            WHERE u = $u
        }

        notifier send ::unit <Entity> update $u

        return 1
    }

    # ClearNbhood u
    #
    # u     A unit
    # 
    # Clears the neighborhood for the unit on reconcile.

    typemethod ClearNbhood {u} {
        rdb eval {
            UPDATE units
            SET n = ''
            WHERE u = $u
        }

        notifier send ::unit <Entity> update $u
    }


    # mutate create parmdict
    #
    # parmdict     A dictionary of unit parms
    #
    #    u              The unit's ID
    #    g              The group to which the unit belongs
    #    location       The unit's initial location (map coords)
    #    personnel      The unit's total personnel
    #    activity       The unit's current activity (eactivity(n))
    #
    # Creates a unit given the parms, which are presumed to be
    # valid.  n should be "" unless g is a CIV group.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, get the group type.
            set gtype [group gtype $g]

            # NEXT, get the neighborhood
            set n [nbhood find {*}$location]

            # NEXT, Put the unit in the database
            rdb eval {
                INSERT INTO units(u,gtype,g,personnel,location,n,activity)
                VALUES($u,
                       $gtype,
                       $g,
                       $personnel,
                       $location,
                       $n,
                       $activity);
            }

            # NEXT, notify the app.
            notifier send ::unit <Entity> create $u

            # NEXT, Return the undo command
            return [mytypemethod mutate delete $u]
        }
    }

    # mutate delete u
    #
    # u     A unit name
    #
    # Deletes the unit, including all references.

    typemethod {mutate delete} {u} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM units WHERE u=$u} row { unset row(*) }

        # NEXT, delete it.
        rdb eval {
            DELETE FROM units    WHERE u=$u;
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

    # mutate update parmdict
    #
    # parmdict     A dictionary of unit parms
    #
    #    u              The unit's ID
    #    g              A new group, or ""
    #    location       A new location (map coords) or ""
    #    personnel      A new quantity of personnel, or ""
    #    activity       A new activity, or ""
    #
    # Updates a unit given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM units
                WHERE u=$u
            } undoData {
                unset undoData(*)
            }

            # NEXT, get the new gtype
            if {$g ne ""} {
                set gtype [group gtype $g]
            } else {
                set gtype $undoData(gtype)
            }

            # NEXT, get the new neighborhood
            if {$location ne ""} {
                set n [nbhood find {*}$location]
            } else {
                set n ""
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE units
                SET g         = nonempty($g, g),
                    gtype     = $gtype,
                    location  = nonempty($location,  location),
                    personnel = nonempty($personnel, personnel),
                    activity  = nonempty($activity,  activity)
                WHERE u=$u
            }

            if {$location ne ""} {
                rdb eval {
                    UPDATE units
                    SET   n = $n
                    WHERE u = $u
                }
            }

            # NEXT, notify the app.
            notifier send ::unit <Entity> update $u

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # ValidateActivity gtypes activity
    #
    # gtypes     List of one or more group types
    # activity   An activity
    #
    # Ensures that the activity is valid for the group type(s)

    typemethod ValidateActivity {gtypes activity} {

        foreach gtype $gtypes {
            switch -exact -- $gtype {
                FRC     { efrcactivity validate $activity }
                ORG     { eorgactivity validate $activity }
                default { error "Unexpected gtype: \"$gtype\""   }
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
    # TBD: Need a better mechanism for this!

    typemethod RefreshUnitName {field parmdict} {
        dict with parmdict {
            # FIRST, leave it alone if the group is unknown.
            if {$g eq ""} {
                return
            }

            # NEXT, if the name is already set, but it looks like
            # an automatically generated name, you can replace it.
            if {$u ne ""} {
                if {![regexp {(.*)/\d\d\d\d$} $u dummy prefix] ||
                    $prefix ni [unit group names]
                } {
                    return
                }
            }

            # NEXT, generate a unit name for this group.
            set count [rdb onecolumn {
                SELECT count(u) FROM units
                WHERE g=$g;
            }]

            set u [format "%s/%04d" $g [incr count]]

            while {[rdb exists {SELECT u FROM units WHERE u=$u}]} {
                set u [format "%s/%04d" $g [incr count]]
            }

            $field set $u
        }
    }

    # RefreshActivityCreate field parmdict
    #
    # field     The "activity" field in a U:CREATE order.
    # parmdict  The current values of the various fields.
    #
    # Sets the list of valid activities.

    typemethod RefreshActivityCreate {field parmdict} {
        dict with parmdict {
            set gtype [group gtype $g]

            $type SetActivityValues $field $gtype
        }
    }


    # RefreshActivityUpdate field parmdict
    #
    # field     The "activity" field in a U:UPDATE order.
    # parmdict  The current values of the various fields.
    #
    # Sets the list of valid activities.

    typemethod RefreshActivityUpdate {field parmdict} {
        dict with parmdict {
            set gtype [rdb onecolumn {
                SELECT gtype FROM units WHERE u=$u
            }]

            $type SetActivityValues $field $gtype
        }
    }


    # SetActivityValues field gtype
    #
    # field     The activity field in an order
    # gtype     The group type
    # 
    # Sets the list of values appropriately.

    typemethod SetActivityValues {field gtype} {
        switch -exact -- $gtype {
            FRC     { set values [efrcactivity cget -values]    }
            ORG     { set values [eorgactivity cget -values]    }
            ""      { set values {}                             }
            default { error "Unexpected group type: \"$gtype\"" }
        }

        $field configure -values $values
    }


    # RefreshActivityMulti field parmdict
    #
    # field     The "activity" field in a U:UPDATE:MULTI order.
    # parmdict  The current values of the various fields.
    #
    # Sets the list of valid activities.

    typemethod RefreshActivityMulti {field parmdict} {
        dict with parmdict {
            if {$g ne ""} {
                set gtypes [group gtype $g]
            } else {
                set fragment [join $ids ',']

                set gtypes [rdb eval "
                    SELECT DISTINCT gtype
                    FROM units
                    WHERE u IN ('$fragment');
                "]
            }

            if {"" eq $gtypes || "" in $gtypes} {
                set values {}
            } elseif {"ORG" in $gtypes} {
                set values [eorgactivity cget -values]
            } elseif {"FRC" in $gtypes} {
                set values [efrcactivity cget -values]
            } else {
                set values {}
            }

            $field configure -values $values
        }
    }
}

#-------------------------------------------------------------------
# Orders: UNIT:*

# UNIT:CREATE
#
# Creates new force groups.

order define ::unit UNIT:CREATE {
    title "Create Unit"
    options -sendstates PREP

    parm g          enum  "Group" -type {unit group} -tags group -refresh
    parm u          text  "Name" \
        -refreshcmd [list ::unit RefreshUnitName]
    parm personnel  text  "Personnel"  -defval 1
    parm location   text  "Location"   -tags point
    parm activity   enum  "Activity"   -tags activity \
        -refreshcmd [list ::unit RefreshActivityCreate]
} {
    # FIRST, prepare and validate the parameters
    prepare g          -toupper -required         -type {unit group}
    prepare u          -toupper -required -unused -type unitname
    prepare personnel           -required         -type iquantity
    prepare location            -required         -type refpoint
    prepare activity   -toupper -required         -type eactivity

    returnOnError

    # NEXT, do cross-validation

    validate activity {
        $type ValidateActivity [group gtype $parms(g)] $parms(activity)
    }

    returnOnError

    # NEXT, create the unit
    lappend undo [$type mutate create [array get parms]]

    setundo [join $undo \n]
}

# UNIT:DELETE

order define ::unit UNIT:DELETE {
    title "Delete Unit"
    options -sendstates PREP -table units

    parm u  key "Unit" -tags unit
} {
    # FIRST, prepare the parameters
    prepare u -toupper -required -type unit

    returnOnError

    # NEXT, make sure the user knows what he is getting into.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     UNIT:DELETE                      \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this unit?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the unit
    lappend undo [$type mutate delete $parms(u)]

    setundo [join $undo \n]
}


# UNIT:UPDATE
#
# Updates existing groups.

order define ::unit UNIT:UPDATE {
    title "Update Unit"
    options -sendstates PREP -table gui_units

    parm u          key   "Unit"       -tags unit
    parm g          enum  "Group"      -type {unit group}
    parm personnel  text  "Personnel"  
    parm location   text  "Location"   -tags point
    parm activity   enum  "Activity"   -tags activity \
        -refreshcmd [list ::unit RefreshActivityUpdate]
} {
    # FIRST, prepare the parameters
    prepare u          -toupper -required -type unit
    prepare g          -toupper           -type {unit group}
    prepare personnel                     -type iquantity
    prepare location                      -type refpoint
    prepare activity   -toupper           -type eactivity

    returnOnError

    # NEXT, do cross-validation
    validate activity {
        if {$parms(g) ne ""} {
            set gtype [group gtype $parms(g)]
        } else {
            set gtype [rdb onecolumn {
                SELECT gtype FROM units WHERE u=$parms(u)
            }]
        }

        $type ValidateActivity $gtype $parms(activity)
    }

    returnOnError

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}

# UNIT:UPDATE:MULTI
#
# Updates multiple groups.

order define ::unit UNIT:UPDATE:MULTI {
    title "Update Multiple Units"
    options -sendstates PREP -table gui_units

    parm ids        multi "Units"
    parm g          enum  "Group"      -type {unit group} -refresh
    parm personnel  text  "Personnel"  
    parm location   text  "Location"   -tags point
    parm activity   enum  "Activity"   -tags activity \
        -refreshcmd [list ::unit RefreshActivityMulti]
} {
    # FIRST, prepare the parameters
    prepare ids        -toupper -required -listof unit
    prepare g          -toupper           -type {unit group}
    prepare personnel                     -type iquantity
    prepare location                      -type refpoint
    prepare activity   -toupper           -type eactivity

    returnOnError

    # NEXT, do cross-validation

    validate activity {
        if {$parms(g) ne ""} {
            set gtypes [group gtype $parms(g)]
        } else {
            set fragment [join $parms(ids) ',']

            set gtypes [rdb eval "
                SELECT DISTINCT gtype
                FROM units
                WHERE u IN ('$fragment');
            "]
        }

        $type ValidateActivity $gtypes $parms(activity)
    }

    # NEXT, modify the group
    set undo [list]

    foreach parms(u) $parms(ids) {
        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}






