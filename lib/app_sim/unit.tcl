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


    # origin names
    #
    # Returns the names of valid unit origins: NONE, plus all neighborhoods.

    typemethod {origin names} {} {
        linsert [nbhood names] 0 NONE
    }

    # origin validate origin
    #
    # origin     A unit neighborhood of origin
    #
    # Validates an origin

    typemethod {origin validate} {origin} {
        set names [$type origin names]

        if {$origin ni $names} {
            set names [join $names ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid unit origin, $msg"
        }

        return $origin
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
    # Updates the "n" field to reflect neighborhood changes.

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

        # NEXT, clear origin if no such nbhood exists.
        rdb eval {
            SELECT u, origin
            FROM units 
            LEFT OUTER JOIN nbhoods ON (nbhoods.n = units.origin)
            WHERE origin != 'NONE'
            WHERE longname IS NULL
        } {
            rdb eval {
                UPDATE units
                SET   origin = 'NONE'
                WHERE u = $u
            }

            lappend undo [mytypemethod RestoreOrigin $u $origin]
        }

        # NEXT, set origin and n for all units
        rdb eval {
            SELECT u, n, location 
            FROM units
        } { 
            set newNbhood [nbhood find {*}$location]

            if {$newNbhood ne $n} {
                rdb eval {
                    UPDATE units
                    SET   n = $newNbhood
                    WHERE u = $u
                }

                lappend undo [mytypemethod RestoreNbhood $u $n]

                notifier send ::unit <Entity> update $u
            }
        }

        return [join $undo \n]
    }

    # RestoreOrigin u origin
    #
    # u          A unit
    # origin     A nbhood
    # 
    # Sets the unit's neighborhood of origin

    typemethod RestoreNbhood {u origin} {
        # FIRST, save it, and notify the app.
        rdb eval {
            UPDATE units
            SET origin = $origin
            WHERE u = $u
        }

        notifier send ::unit <Entity> update $u
    }

    # RestoreNbhood u n
    #
    # u     A unit
    # n     A nbhood
    # 
    # Sets the unit's nbhood.

    typemethod RestoreNbhood {u n} {
        # FIRST, save it, and notify the app.
        rdb eval {
            UPDATE units
            SET n = $n
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
    #    origin         The unit's neighborhood of origin, or "NONE"
    #    location       The unit's initial location (map coords)
    #    personnel      The unit's total personnel
    #    a              The unit's current activity
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
                INSERT INTO units(u,gtype,g,origin,personnel,location,n,a)
                VALUES($u,
                       $gtype,
                       $g,
                       $origin,
                       $personnel,
                       $location,
                       $n,
                       $a);
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
    #    origin         A new origin, or ""
    #    location       A new location (map coords) or ""
    #    personnel      A new quantity of personnel, or ""
    #    a              A new activity, or ""
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
                SET g         = nonempty($g,         g),
                    origin    = nonempty($origin,    origin),
                    gtype     = $gtype,
                    location  = nonempty($location,  location),
                    personnel = nonempty($personnel, personnel),
                    a         = nonempty($a,         a)
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
    # field     The "a" field in a U:CREATE order.
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
    # field     The "a" field in a U:UPDATE order.
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
    # field     The "a" field in an order
    # gtype     The group type
    # 
    # Sets the list of values appropriately.

    typemethod SetActivityValues {field gtype} {
        switch -exact -- $gtype {
            CIV     { set values [activity civ names]           }
            FRC     { set values [activity frc names]           }
            ORG     { set values [activity org names]           }
            ""      { set values {}                             }
            default { error "Unexpected group type: \"$gtype\"" }
        }

        $field configure -values $values
    }


    # RefreshActivityMulti field parmdict
    #
    # field     The "a" field in a U:UPDATE:MULTI order.
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
            } elseif {"CIV" in $gtypes} {
                set values [activity civ names]
            } elseif {"FRC" in $gtypes} {
                set values [activity frc names]
            } elseif {"ORG" in $gtypes} {
                set values [activity org names]
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

    options -sendstates {PREP PAUSED RUNNING}

    parm g          enum  "Group" -type group -tags group -refresh
    parm u          text  "Name" \
        -refreshcmd [list ::unit RefreshUnitName]
    parm origin     enum  "Origin"     -type {unit origin} -tags nbhood
    parm personnel  text  "Personnel"  -defval 1
    parm location   text  "Location"   -tags point
    parm a          enum  "Activity"   -tags activity \
        -refreshcmd [list ::unit RefreshActivityCreate]
} {
    # FIRST, prepare and validate the parameters
    prepare g          -toupper -required         -type group
    prepare u          -toupper -required -unused -type unitname
    prepare origin     -toupper -required         -type {unit origin}
    prepare personnel           -required         -type iquantity
    prepare location            -required         -type refpoint
    prepare a          -toupper -required         -type activity

    returnOnError

    # NEXT, do cross-validation

    validate a {
        $type ValidateActivity [group gtype $parms(g)] $parms(a)
    }

    returnOnError

    # NEXT, create the unit
    lappend undo [$type mutate create [array get parms]]

    setundo [join $undo \n]
}

# UNIT:DELETE

order define ::unit UNIT:DELETE {
    title "Delete Unit"
    options \
        -table      units                 \
        -sendstates {PREP PAUSED RUNNING}


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
# Updates existing units.

order define ::unit UNIT:UPDATE {
    title "Update Unit"
    options \
        -table      gui_units             \
        -sendstates {PREP PAUSED RUNNING}

    parm u          key   "Unit"       -tags unit
    parm g          enum  "Group"      -type group
    parm origin     enum  "Origin"     -type {unit origin} -tags nbhood
    parm personnel  text  "Personnel"  
    parm location   text  "Location"   -tags point
    parm a          enum  "Activity"   -tags activity \
        -refreshcmd [list ::unit RefreshActivityUpdate]
} {
    # FIRST, prepare the parameters
    prepare u          -toupper -required -type unit
    prepare g          -toupper           -type group
    prepare origin     -toupper           -type {unit origin}
    prepare personnel                     -type iquantity
    prepare location                      -type refpoint
    prepare a          -toupper           -type activity

    returnOnError

    # NEXT, do cross-validation
    validate a {
        if {$parms(g) ne ""} {
            set gtype [group gtype $parms(g)]
        } else {
            set gtype [rdb onecolumn {
                SELECT gtype FROM units WHERE u=$parms(u)
            }]
        }

        $type ValidateActivity $gtype $parms(a)
    }

    returnOnError

    # NEXT, modify the group
    setundo [$type mutate update [array get parms]]
}

# UNIT:UPDATE:MULTI
#
# Updates multiple units.

order define ::unit UNIT:UPDATE:MULTI {
    title "Update Multiple Units"
    options \
        -table      gui_units             \
        -sendstates {PREP PAUSED RUNNING}

    parm ids        multi "Units"
    parm g          enum  "Group"      -type group -refresh
    parm origin     enum  "Origin"     -type {unit origin} -tags nbhood
    parm personnel  text  "Personnel"  
    parm location   text  "Location"   -tags point
    parm a          enum  "Activity"   -tags activity \
        -refreshcmd [list ::unit RefreshActivityMulti]
} {
    # FIRST, prepare the parameters
    prepare ids        -toupper -required -listof unit
    prepare g          -toupper           -type group
    prepare origin     -toupper           -type {unit origin}
    prepare personnel                     -type iquantity
    prepare location                      -type refpoint
    prepare a          -toupper           -type activity

    returnOnError

    # NEXT, do cross-validation

    validate a {
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

        $type ValidateActivity $gtypes $parms(a)
    }

    # NEXT, modify the group
    set undo [list]

    foreach parms(u) $parms(ids) {
        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}



