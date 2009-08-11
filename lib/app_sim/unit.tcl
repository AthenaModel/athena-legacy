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

            set msg "should be one of: $names"

            return -code error -errorcode INVALID \
                "Invalid unit origin, $msg"
        }

        return $origin
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

        # NEXT, delete CIV units for which no nbgroup exists
        rdb eval {
            SELECT u
            FROM units 
            LEFT OUTER JOIN nbgroups 
            ON (units.g=nbgroups.g AND nbgroups.n = units.origin)
            WHERE gtype = 'CIV'
            AND   nbgroups.local_name IS NULL
        } {
            lappend undo [$type mutate delete $u]
        }

        # NEXT, set n for all units
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

    typemethod RestoreOrigin {u origin} {
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
    # Deletes the unit.

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

        # NEXT, get the new neighborhood
        set n [nbhood find {*}$location]

        # NEXT, Update the unit
        rdb eval {
            UPDATE units
            SET location  = $location,
                n         = $n
            WHERE u=$u
        }

        # NEXT, notify the app.
        notifier send ::unit <Entity> update $u

        # NEXT, Return the undo command
        return [mytypemethod mutate move $u $oldLocation]
    }


    # mutate activity u a
    #
    # u              The unit's ID
    # a              A new activity
    #
    # Sets the unit's activity given the parms, which are presumed to be
    # valid.

    typemethod {mutate activity} {u a} {
        # FIRST, get the undo information
        rdb eval {
            SELECT a AS oldActivity FROM units
            WHERE u=$u
        } {}

        # NEXT, Update the unit
        rdb eval {
            UPDATE units
            SET a = $a
            WHERE u=$u
        }

        # NEXT, notify the app.
        notifier send ::unit <Entity> update $u

        # NEXT, Return the undo command
        return [mytypemethod mutate activity $u $oldActivity]
    }


    # mutate personnel u personnel
    #
    # u              The unit's ID
    # personnel      The new number of personnel
    #
    # Sets the unit's personnel given the parms, which are presumed to be
    # valid.

    typemethod {mutate personnel} {u personnel} {
        # FIRST, get the undo information
        rdb eval {
            SELECT personnel AS oldPersonnel FROM units
            WHERE u=$u
        } {}

        # NEXT, Update the unit
        rdb eval {
            UPDATE units
            SET   personnel = $personnel
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

            if {[$field get] eq ""} {
                $field set NONE
            }
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
}

#-------------------------------------------------------------------
# Orders: UNIT:*

# UNIT:CREATE
#
# Creates a new unit.

order define ::unit UNIT:CREATE {
    title "Create Unit"

    options -sendstates {PREP PAUSED}

    parm g          enum  "Group"  -type group -tags group
    parm origin     enum  "Origin"             -tags nbhood \
        -refreshcmd [list ::unit RefreshUnitOrigin]
    parm u          text  "Name" \
        -refreshcmd [list ::unit RefreshUnitName]
    parm personnel  text  "Personnel"  -defval 1
    parm location   text  "Location"   -tags point
    parm a          enum  "Activity"   -tags activity \
        -refreshcmd [list ::unit RefreshActivityCreate]
} {
    # FIRST, prepare and validate the parameters
    prepare g          -toupper -required         -type group
    prepare origin     -toupper -required         -type {unit origin}
    prepare u          -toupper -required -unused -type unitname
    prepare personnel           -required         -type iquantity
    prepare location            -required         -type refpoint
    prepare a          -toupper -required         -type activity

    returnOnError

    # NEXT, do cross-validation
    set gtype [group gtype $parms(g)]

    validate origin {
        if {$gtype eq "CIV"} {
            nbgroup validate [list $parms(origin) $parms(g)]
        } elseif {$parms(origin) ne "NONE"} {
            reject origin "Only civilian units have a neighborhood of origin"
        }
    }

    validate a {
        $type ValidateActivity $gtype $parms(a)
    }

    returnOnError

    validate personnel {
        if {$gtype eq "CIV"} {
            set imp [demog getng $parms(origin) $parms(g) implicit]

            let max {$imp - 1}

            if {$parms(personnel) > $max} {
                reject personnel \
                    "Insufficient implicit population; check demographics."
            }
        }
    }

    returnOnError -final

    # NEXT, create the unit
    lappend undo [$type mutate create [array get parms]]

    # NEXT, if it's a civilian unit, update the demographics
    if {$gtype eq "CIV"} {
        lappend undo [demog analyze]
    }

    setundo [join $undo \n]
}

# UNIT:DELETE

order define ::unit UNIT:DELETE {
    title "Delete Unit"
    options \
        -table      units                 \
        -sendstates {PREP PAUSED}


    parm u  key "Unit" -tags unit
} {
    # FIRST, prepare the parameters
    prepare u -toupper -required -type unit

    returnOnError -final

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

    # NEXT, get the unit's group type
    set gtype [unit get $parms(u) gtype]

    # NEXT, Delete the unit
    lappend undo [$type mutate delete $parms(u)]

    # NEXT, if it's a civilian unit, update the demographics
    if {$gtype eq "CIV"} {
        lappend undo [demog analyze]
    }

    setundo [join $undo \n]
}


# UNIT:MOVE
#
# Moves an existing unit.

order define ::unit UNIT:MOVE {
    title "Move Unit"
    options \
        -canschedule               \
        -table       gui_units     \
        -sendstates  {PREP PAUSED}

    parm u          key   "Unit"       -tags unit
    parm location   text  "Location"   -tags point
} {
    # FIRST, prepare the parameters
    prepare u          -toupper -required -type unit
    prepare location   -toupper -required -type refpoint

    returnOnError -final

    # NEXT, get the unit's group type
    set gtype [unit get $parms(u) gtype]

    # NEXT, move the unit
    lappend undo [$type mutate move $parms(u) $parms(location)]

    # NEXT, if it's a civilian unit, update the demographics
    if {$gtype eq "CIV"} {
        lappend undo [demog analyze]
    }

    setundo [join $undo \n]
}


# UNIT:ACTIVITY
#
# Sets an existing unit's activity.

order define ::unit UNIT:ACTIVITY {
    title "Set Unit Activity"
    options \
        -canschedule                \
        -table        gui_units     \
        -sendstates   {PREP PAUSED}

    parm u          key   "Unit"       -tags unit
    parm a          enum  "Activity"   -tags activity \
        -refreshcmd [list ::unit RefreshActivityUpdate]
} {
    # FIRST, prepare the parameters
    prepare u          -toupper -required -type unit
    prepare a          -toupper -required -type activity

    returnOnError

    # NEXT, get the unit's group type
    set gtype [unit get $parms(u) gtype]

    # NEXT, do cross-validation
    validate a {
        $type ValidateActivity $gtype $parms(a)
    }

    returnOnError -final

    # NEXT, modify the unit
    lappend undo [$type mutate activity $parms(u) $parms(a)]

    # NEXT, if it's a civilian unit, update the demographics
    if {$gtype eq "CIV"} {
        lappend undo [demog analyze]
    }

    setundo [join $undo \n]
}


# UNIT:PERSONNEL
#
# Sets the number of people in the unit

order define ::unit UNIT:PERSONNEL {
    title "Set Unit Personnel"
    options \
        -canschedule               \
        -table       gui_units     \
        -sendstates  {PREP PAUSED}

    parm u          key   "Unit"       -tags unit
    parm personnel  text  "Personnel"  
} {
    # FIRST, prepare the parameters
    prepare u          -toupper -required -type unit
    prepare personnel           -required -type iquantity

    returnOnError

    # NEXT, get the old unit data
    array set old [unit get $parms(u)]

    # NEXT, do cross-validation
    validate personnel {

        if {$old(gtype) eq "CIV"} {
            set imp [demog getng $old(origin) $old(g) implicit]

            let maxIncrease {$imp - 1}

            if {$parms(personnel) - $old(personnel) > $maxIncrease} {
                reject personnel \
                    "Insufficient implicit population; check demographics."
            }
        }
    }

    returnOnError -final

    # NEXT, modify the unit
    lappend undo [$type mutate personnel $parms(u) $parms(personnel)]

    # NEXT, if it's a civilian unit update the demographics
    if {$old(gtype) eq "CIV"} {
        lappend undo [demog analyze]
    }

    setundo [join $undo \n]
}






