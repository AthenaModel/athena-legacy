#-----------------------------------------------------------------------
# TITLE:
#    nbhood.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Neighborhood Manager
#
#    This module is responsible for managing neighborhoods and operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type nbhood {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    typecomponent geo   ;# A geoset, for polygon computations

    #-------------------------------------------------------------------
    # Type Variables
    
    # TBD

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        # FIRST, create the geoset
        set geo [geoset ${type}::geo]

        log detail nbhood "Initialized"
    }

    # reconfigure
    #
    # Refreshes the geoset with the current neighborhood data from
    # the database.
    
    typemethod reconfigure {} {
        # FIRST, populate the geoset
        $geo clear

        rdb eval {
            SELECT n, polygon FROM nbhoods
            ORDER BY stacking_order
        } {
            # Create the polygon with the neighborhood's name and
            # polygon coordinates; tag it with "nbhood".
            $geo create polygon $n $polygon nbhood
        }

        # NEXT, update the obscured_by fields
        $type SetObscuredBy
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # find mx my
    #
    # mx,my    A point in map coordinates
    #
    # Returns the short name of the neighborhood which contains the
    # coordinates, or the empty string.

    typemethod find {mx my} {
        return [$geo find [list $mx $my] nbhood]
    }

    # names
    #
    # Returns the list of neighborhood names

    typemethod names {} {
        set names [rdb eval {
            SELECT n FROM nbhoods ORDER BY n
        }]
    }


    # validate n
    #
    # n         Possibly, a neighborhood short name.
    #
    # Validates a neighborhood short name

    typemethod validate {n} {
        if {![rdb exists {SELECT n FROM nbhoods WHERE n=$n}]} {
            set names [join [nbhood names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid neighborhood, $msg"
        }

        return $n
    }

    #-------------------------------------------------------------------
    # Private Type Methods

    # SetObscuredBy
    #
    # Checks the neighborhoods for obscured reference points, and
    # sets the obscured_by field accordingly.
    #
    # TBD: This could be more efficient if it took into account
    # the neighborhood that changed and only looked at overlapping
    # neighborhoods.

    typemethod SetObscuredBy {} {
        rdb eval {
            SELECT n, refpoint, obscured_by FROM nbhoods
        } {
            set in [$geo find $refpoint nbhood]

            if {$in eq $n} {
                set in ""
            }

            if {$in ne $obscured_by} {
                rdb eval {
                    UPDATE nbhoods
                    SET obscured_by=$in
                    WHERE n=$n
                }
            }
        }
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
    # parmdict     A dictionary of neighborhood parms
    #
    #    n              The neighborhood's ID
    #    longname       The neighborhood's long name
    #    urbanization   eurbanization level
    #    refpoint       Reference point, map coordinates
    #    polygon        Boundary polygon, in map coordinates.
    #
    # Creates a nbhood given the parms, which are presumed to be
    # valid.  When validity checks are needed, use the NBHOOD:CREATE
    # order.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the neighborhood in the database
            rdb eval {
                INSERT INTO nbhoods(n,longname,refpoint,polygon,urbanization)
                VALUES($n,
                       $longname,
                       $refpoint,
                       $polygon,
                       $urbanization);
            } {}

            # NEXT, set the stacking order
            rdb eval {
                SELECT COALESCE(MAX(stacking_order)+1, 1) AS top FROM nbhoods
            } {
                rdb eval {
                    UPDATE nbhoods
                    SET stacking_order=$top
                    WHERE n=$n;
                }
            }

            # NEXT, add the nbhood to the geoset
            $geo create polygon $n $polygon nbhood

            # NEXT, recompute the obscured_by field; this nbhood might
            # have obscured some other neighborhood's refpoint.
            $type SetObscuredBy

            # NEXT, notify the app.
            notifier send ::nbhood <Entity> create $n

            # NEXT, Set the undo command
            return [mytypemethod mutate delete $n]
        }
    }

    # mutate delete n
    #
    # n     A neighborhood short name
    #
    # Deletes the neighborhood, including all references.

    typemethod {mutate delete} {n} {
        # FIRST, get this neighborhood's undo information
        rdb eval {
            SELECT * FROM nbhoods WHERE n=$n
        } undoData {
            unset undoData(*)
        }

        # FIRST, delete it.
        rdb eval {
            DELETE FROM nbhoods WHERE n=$n
        }

        $geo delete $n

        # NEXT, recompute the obscured_by field; this nbhood might
        # have obscured some other neighborhood's refpoint.
        $type SetObscuredBy

        # NEXT, notify the app
        notifier send ::nbhood <Entity> delete $n

        # NEXT, return aggregate undo script.
        return [mytypemethod RestoreNbhood [array get undoData]]
    }

    # RestoreNbhood parmdict
    #
    # parmdict     A complete nbhoods row, to be restored as is.
    #
    # Restores a row in the nbhoods table.

    typemethod RestoreNbhood {parmdict} {
        # FIRST, restore the database row
        rdb insert nbhoods $parmdict

        # NEXT, reconfigure: this will update the geoset and the stacking
        # order.
        $type reconfigure

        # NEXT, notify the app.
        notifier send ::nbhood <Entity> create [dict get $parmdict n]
    }

    # mutate lower n
    #
    # n     A neighborhood short name
    #
    # Sends the neighborhood to the bottom of the stacking order.

    typemethod {mutate lower} {n} {
        # FIRST, reorder the neighborhoods
        set oldNames [rdb eval {
            SELECT n FROM nbhoods 
            ORDER BY stacking_order
        }]

        set names $oldNames
        ldelete names $n
        set names [linsert $names 0 $n]

        return [$type RestackNbhoods $names $oldNames]
    }

    # mutate raise n
    #
    # n     A neighborhood short name
    #
    # Brings the neighborhood to the top of the stacking order.

    typemethod {mutate raise} {n} {
        # FIRST, reorder the neighborhoods
        set oldNames [rdb eval {
            SELECT n FROM nbhoods 
            ORDER BY stacking_order
        }]

        set names $oldNames

        ldelete names $n
        lappend names $n

        return [$type RestackNbhoods $names $oldNames]
    }
  
    # RestackNbhoods new ?old?
    #
    # new      A list of all nbhood names in the desired stacking
    #          order
    # old      The previous order
    #
    # Sets the stacking_order according to the order of the names.

    typemethod RestackNbhoods {new {old ""}} {
        # FIRST, set the stacking_order
        set i 0

        foreach name $new {
            incr i

            rdb eval {
                UPDATE nbhoods
                SET stacking_order=$i
                WHERE n=$name
            }
        }

        # NEXT, refresh the geoset and set the "obscured_by" field
        $type reconfigure
        
        # NEXT, notify the GUI of the change.
        notifier send ::nbhood <Entity> stack

        # NEXT, set the undo information
        return [mytypemethod RestackNbhoods $old]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of neighborhood parms
    #
    #    n              A neighborhood short name
    #    longname       A new long name, or ""
    #    urbanization   A new eurbanization level, or ""
    #    refpoint       A new reference point, or ""
    #    polygon        A new polygon, or ""
    #
    # Updates a nbhood given the parms, which are presumed to be
    # valid.  When validity checks are needed, use the NBHOOD:UPDATE
    # order.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT n, longname, refpoint, polygon, urbanization 
                FROM nbhoods
                WHERE n=$n
            } row {
                unset row(*)
            }

            # NEXT, Put the neighborhood in the database
            rdb eval {
                UPDATE nbhoods
                SET longname     = nonempty($longname,     longname),
                    refpoint     = nonempty($refpoint,     refpoint),
                    polygon      = nonempty($polygon,      polygon),
                    urbanization = nonempty($urbanization, urbanization)
                WHERE n=$n
            } {}

            # NEXT, recompute the obscured_by field if necessary; this 
            # nbhood might have obscured some other neighborhood's refpoint.
            if {$polygon ne ""} {
                $type SetObscuredBy
            }

            # NEXT, notify the app.
            notifier send ::nbhood <Entity> update $n

            # NEXT, Set the undo command
            return [mytypemethod mutate update [array get row]]
        }
    }
}

#-------------------------------------------------------------------
# Orders: NBHOOD:*

# NBHOOD:CREATE
#
# Creates new neighborhoods.

order define ::nbhood NBHOOD:CREATE {
    title "Create Neighborhood"
    parms {
        n            {ptype text          label "Neighborhood"    }
        longname     {ptype text          label "Long Name"       }
        urbanization {ptype urbanization  label "Urbanization"    }
        refpoint     {ptype point         label "Reference Point" }
        polygon      {ptype polygon       label "Polygon"         }
    }
} {
    # FIRST, prepare the parameters
    prepare n             -toupper      -required -unused -type ident
    prepare longname      -normalize          -required -unused
    prepare urbanization  -toupper      -required -type eurbanization
    prepare refpoint      -toupper      -required -type refpoint
    prepare polygon       -normalize -toupper -required -type refpoly

    returnOnError

    # NEXT, perform custom checks

    # n vs. longname
    if {$parms(n) eq $parms(longname)} {
        reject longname "longname must not be identical to ID"
    }
    
    # polygon
    #
    # Must be unique.

    if {[valid polygon] && [rdb exists {
        SELECT n FROM nbhoods
        WHERE polygon = $parms(polygon)
    }]} {
        reject polygon "A neighborhood with this polygon already exists"
    }

    # refpoint
    #
    # Must be unique

    if {[valid refpoint] && [rdb exists {
        SELECT n FROM nbhoods
        WHERE refpoint = $parms(refpoint)
    }]} {
        reject refpoint \
            "A neighborhood with this reference point already exists"
    }

    # NEXT, do cross-validation.

    if {[valid refpoint] && [valid polygon]} {
        if {![ptinpoly $parms(polygon) $parms(refpoint)]} {
            reject refpoint "not in polygon"
        }
    }
    
    returnOnError

    # NEXT, create the neighborhood and dependent entities
    lappend undo [$type mutate create [array get parms]]
    lappend undo [sat mutate reconcile]

    setundo [join $undo \n]
}

# NBHOOD:DELETE

order define ::nbhood NBHOOD:DELETE {
    title "Delete Neighborhood"
    table gui_nbhoods
    parms {
        n {ptype key label "Neighborhood"}
    }
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type nbhood

    returnOnError

    # NEXT, make sure the user knows what he is getting into.

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     NBHOOD:DELETE                    \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this neighborhood, along
                            with all of the entities that depend upon it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, delete the neighborhood and dependent entities
    lappend undo [$type mutate delete $parms(n)]
    lappend undo [nbgroup mutate reconcile]
    lappend undo [sat    mutate reconcile]
    lappend undo [rel    mutate reconcile]

    setundo [join $undo \n]
}

# NBHOOD:LOWER

order define ::nbhood NBHOOD:LOWER {
    title "Lower Neighborhood"
    table gui_nbhoods
    parms {
        n {ptype key label "Neighborhood"}
    }
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type nbhood

    returnOnError

    # NEXT, raise the neighborhood
    setundo [$type mutate lower $parms(n)]
}

# NBHOOD:RAISE

order define ::nbhood NBHOOD:RAISE {
    title "Raise Neighborhood"
    table gui_nbhoods
    parms {
        n {ptype key label "Neighborhood"}
    }
} {
    # FIRST, prepare the parameters
    prepare n  -toupper -required -type nbhood

    returnOnError

    # NEXT, raise the neighborhood
    setundo [$type mutate raise $parms(n)]
}

# NBHOOD:UPDATE
#
# Updates existing neighborhoods.

order define ::nbhood NBHOOD:UPDATE {
    title "Update Neighborhood"
    table gui_nbhoods
    parms {
        n            {ptype key           label "Neighborhood"    }
        longname     {ptype text          label "Long Name"       }
        urbanization {ptype urbanization  label "Urbanization"    }
        refpoint     {ptype point         label "Reference Point" }
        polygon      {ptype polygon       label "Polygon"         }
    }
} {
    # FIRST, prepare the parameters
    prepare n            -toupper       -required -type nbhood

    set oldname [rdb onecolumn {
        SELECT longname FROM nbhoods WHERE n=$parms(n)
    }]

    prepare longname     -normalize           -oldvalue $oldname -unused
    prepare urbanization -toupper             -type eurbanization
    prepare refpoint     -toupper             -type refpoint
    prepare polygon      -normalize -toupper  -type refpoly

    returnOnError

    # NEXT, validate the other parameters

    # polygon
    #
    # Must be unique

    if {[valid polygon]} { 
        rdb eval {
            SELECT n FROM nbhoods
            WHERE polygon = $parms(polygon)
        } {
            if {$n ne $parms(n)} {
                reject polygon \
                    "A neighborhood with this polygon already exists"
            }
        }
    }

    # refpoint
    #
    # Must be unique

    if {[valid refpoint]} { 
        rdb eval {
            SELECT n FROM nbhoods
            WHERE refpoint = $parms(refpoint)
        } {
            if {$n ne $parms(n)} {
                reject polygon \
                    "A neighborhood with this reference point already exists"
            }
        }
    }

    returnOnError

    # NEXT, is the refpoint in the polygon?
    rdb eval {SELECT refpoint, polygon FROM nbhoods WHERE n = $parms(n)} {}

    if {$parms(refpoint) ne ""} {
        set refpoint $parms(refpoint)
    }

    if {$parms(polygon) ne ""} {
        set polygon $parms(polygon)
    }

    if {![ptinpoly $polygon $refpoint]} {
        reject refpoint "not in polygon"
    }
    
    returnOnError

    # NEXT, modify the neighborhood
    setundo [$type mutate update [array get parms]]
}

# NBHOOD:UPDATE:MULTI
#
# Updates multiple neighborhoods.

order define ::nbhood NBHOOD:UPDATE:MULTI {
    title "Update Multiple Neighborhoods"
    multi yes
    table gui_nbhoods
    parms {
        ids          {ptype ids           label "Neighborhoods"   }
        urbanization {ptype urbanization  label "Urbanization"    }
     }
} {
    # FIRST, prepare the parameters
    prepare ids          -toupper -required -listof nbhood
    prepare urbanization -toupper           -type   eurbanization
    returnOnError

    # NEXT, clear the other parameters expected by the mutator
    prepare longname
    prepare refpoint
    prepare polygon

    # NEXT, modify the neighborhoods
    set undo [list]

    foreach parms(n) $parms(ids) {
        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}




