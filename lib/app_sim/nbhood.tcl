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
    
    # info -- array of scalars
    #
    # undo       Command to undo the last operation, or ""

    typevariable info -array {
        undo {}
    }

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

        # NEXT, clear the undo command
        set info(undo) {}
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
            SELECT n FROM nbhoods 
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
    # Order Handling Routines

    # LastUndo
    #
    # Returns the undo command for the last mutator, or "" if none.

    typemethod LastUndo {} {
        set undo $info(undo)
        unset info(undo)

        return $undo
    }

    # CreateNbhood parmdict
    #
    # parmdict     A dictionary of neighborhood parms
    #
    #    longname       The neighborhood's long name
    #    urbanization   eurbanization level
    #    refpoint       Reference point, map coordinates
    #    polygon        Boundary polygon, in map coordinates.
    #
    # Creates a nbhood given the parms, which are presumed to be
    # valid.  When validity checks are needed, use the NBHOOD:CREATE
    # order.

    typemethod CreateNbhood {parmdict} {
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

            # NEXT, Not yet undoable; clear the undo command
            set info(undo) [list $type DeleteNbhood $n]
            
            # NEXT, notify the app.
            notifier send ::nbhood <Entity> create $n
        }
    }

    # DeleteNbhood n
    #
    # n     A neighborhood short name
    #
    # Deletes the neighborhood, including all references.

    typemethod DeleteNbhood {n} {
        # FIRST, delete it.
        rdb eval {
            DELETE FROM nbhoods WHERE n=$n
        }

        $geo delete $n

        # NEXT, clear the nbhood field for entities which 
        # refer to this nbhood (e.g., units in the nbhood).
        
        # TBD.

        # NEXT, recompute the obscured_by field; this nbhood might
        # have obscured some other neighborhood's refpoint.
        $type SetObscuredBy

        # NEXT, Not undoable; clear the undo command
        set info(undo) {}

        notifier send ::nbhood <Entity> delete $n
    }

    # LowerNbhood n
    #
    # n     A neighborhood short name
    #
    # Sends the neighborhood to the bottom of the stacking order.

    typemethod LowerNbhood {n} {
        # FIRST, reorder the neighborhoods
        set oldNames [rdb eval {
            SELECT n FROM nbhoods 
            ORDER BY stacking_order
        }]

        set names $oldNames
        ldelete names $n
        set names [linsert $names 0 $n]

        $type RestackNbhoods $names $oldNames
    }

    # RaiseNbhood n
    #
    # n     A neighborhood short name
    #
    # Brings the neighborhood to the top of the stacking order.

    typemethod RaiseNbhood {n} {
        # FIRST, reorder the neighborhoods
        set oldNames [rdb eval {
            SELECT n FROM nbhoods 
            ORDER BY stacking_order
        }]

        set names $oldNames

        ldelete names $n
        lappend names $n

        $type RestackNbhoods $names $oldNames
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

        # NEXT, refresh the geoset
        $type reconfigure
        
        # NEXT, determine who obscures who
        $type SetObscuredBy

        # NEXT, set the undo information
        set info(undo) [list $type RestackNbhoods $old]

        # NEXT, notify the GUI of the change.
        notifier send ::nbhood <Entity> stack
    }

    # UpdateNbhood n parmdict
    #
    # n            A neighborhood short name
    # parmdict     A dictionary of neighborhood parms
    #
    #    longname       A new long name, or ""
    #    urbanization   A new eurbanization level, or ""
    #    refpoint       A new reference point, or ""
    #    polygon        A new polygon, or ""
    #
    # Updates a nbhood given the parms, which are presumed to be
    # valid.  When validity checks are needed, use the NBHOOD:UPDATE
    # order.

    typemethod UpdateNbhood {n parmdict} {
        # FIRST, get the undo information
        rdb eval {
            SELECT longname, refpoint, polygon, urbanization 
            FROM nbhoods
            WHERE n=$n
        } row {
            unset row(*)
        }

        # NEXT, Update the neighborhood
        dict with parmdict {
            # FIRST, Put the neighborhood in the database
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
        }

        # NEXT, Not undoable; clear the undo command
        set info(undo) [mytypemethod UpdateNbhood $n [array get row]]

        # NEXT, notify the app.
        notifier send ::nbhood <Entity> update $n
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
    prepare n             -trim -toupper      -required -unused -type ident
    prepare longname      -normalize          -required -unused
    prepare urbanization  -trim -toupper      -required -type eurbanization
    prepare refpoint      -trim -toupper      -required -type refpoint
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

    # NEXT, create the neighborhood
    $type CreateNbhood [array get parms]

    setundo [$type LastUndo]
}

# NBHOOD:DELETE

order define ::nbhood NBHOOD:DELETE {
    title "Delete Neighborhood"
    parms {
        n {ptype nbhood label "Neighborhood"}
    }
} {
    # FIRST, prepare the parameters
    prepare n  -trim -toupper -required -type nbhood

    # TBD: It isn't clear whether we will delete all entities that depend on
    # this nbhood, or whether all such entities must already have been
    # deleted.  In the latter case, we must verify that we can safely 
    # delete this nbhood; but then, we can reasonably undo the deletion,
    # and so we won't need to do the following verification.

    returnOnError

    if {[interface] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     NBHOOD:DELETE                    \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       "This order cannot be undone.  Are you sure you really want to delete this neighborhood?"]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, raise the neighborhood
    $type DeleteNbhood $parms(n)

    # NEXT, this order is not undoable.
}

# NBHOOD:LOWER

order define ::nbhood NBHOOD:LOWER {
    title "Lower Neighborhood"
    parms {
        n {ptype nbhood label "Neighborhood"}
    }
} {
    # FIRST, prepare the parameters
    prepare n  -trim -toupper -required -type nbhood

    returnOnError

    # NEXT, raise the neighborhood
    $type LowerNbhood $parms(n)

    setundo [$type LastUndo]
}

# NBHOOD:RAISE

order define ::nbhood NBHOOD:RAISE {
    title "Raise Neighborhood"
    parms {
        n {ptype nbhood label "Neighborhood"}
    }
} {
    # FIRST, prepare the parameters
    prepare n  -trim -toupper -required -type nbhood

    returnOnError

    # NEXT, raise the neighborhood
    $type RaiseNbhood $parms(n)

    setundo [$type LastUndo]
}

# NBHOOD:UPDATE
#
# Updates existing neighborhoods.

order define ::nbhood NBHOOD:UPDATE {
    title "Update Neighborhood"
    table gui_nbhoods
    keys  n
    parms {
        n            {ptype nbhood        label "Neighborhood"    }
        longname     {ptype text          label "Long Name"       }
        urbanization {ptype urbanization  label "Urbanization"    }
        refpoint     {ptype point         label "Reference Point" }
        polygon      {ptype polygon       label "Polygon"         }
    }
} {
    # FIRST, prepare the parameters
    prepare n            -trim -toupper       -required -type nbhood

    set oldname [rdb onecolumn {
        SELECT longname FROM nbhoods WHERE n=$parms(n)
    }]

    prepare longname     -normalize           -oldvalue $oldname -unused
    prepare urbanization -trim -toupper       -type eurbanization
    prepare refpoint     -trim -toupper       -type refpoint
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
    set n $parms(n)
    unset parms(n)

    $type UpdateNbhood $n [array get parms]

    setundo [$type LastUndo]
}

