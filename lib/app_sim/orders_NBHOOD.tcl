#-----------------------------------------------------------------------
# TITLE:
#    orders_NBHOOD.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    minerva_sim(1): NBHOOD:* Orders
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# NBHOOD:*

ordergui entrytype enum nbhood -valuecmd [list nbhood names]

# NBHOOD:CREATE
#
# Creates new neighborhoods.

ordergui define NBHOOD:CREATE {
    title "Create Neighborhood"
    parms {
        longname     {ptype text          label "Long Name"       }
        urbanization {ptype urbanization  label "Urbanization"    }
        refpoint     {ptype point         label "Reference Point" }
        polygon      {ptype polygon       label "Polygon"         }
    }
}

order define NBHOOD:CREATE {
    # FIRST, prepare the parameters
    prepare longname      -normalize          -required 
    prepare urbanization  -trim      -toupper -required
    prepare refpoint      -trim      -toupper -required
    prepare polygon       -normalize -toupper -required

    # NEXT, validate the parameters
    
    # longname
    if {[valid longname] && [rdb exists {
        SELECT n FROM nbhoods 
        WHERE longname=$parms(longname)
        OR    n=$parms(longname)
    }]} {
        reject longname "A neighborhood with this name already exists"
    }

    # urbanization
    validate urbanization {
        set parms(urbanization) [eurbanization validate $parms(urbanization)]
    }

    # polygon
    #
    # Is the point a valid map reference string?
    # Is the resulting polygon a valid polygon?

    validate polygon {
        map ref validate {*}$parms(polygon)
        set parms(polygon) [map ref2m {*}$parms(polygon)]
        polygon validate $parms(polygon)
    }

    # refpoint
    #
    # Is the point a valid map reference string?
    # Is the point within the polygon?

    validate refpoint {
        map ref validate $parms(refpoint)
        set parms(refpoint) [map ref2m $parms(refpoint)]
    }

    if {[valid refpoint] && [valid polygon]} {
        if {![ptinpoly $parms(polygon) $parms(refpoint)]} {
            reject refpoint "not in polygon"
        }
    }
    
    returnOnError

    # NEXT, create the neighborhood
    nbhood create [array get parms]
}

# NBHOOD:DELETE

ordergui define NBHOOD:DELETE {
    title "Delete Neighborhood"
    parms {
        n {ptype nbhood label "Neighborhood"}
    }
}

order define NBHOOD:DELETE {
    # FIRST, prepare the parameters
    prepare n  -trim -toupper -required 

    # Validate
    validate n { nbhood validate $parms(n) }

    returnOnError

    # NEXT, raise the neighborhood
    nbhood delete $parms(n)
}

# NBHOOD:LOWER

ordergui define NBHOOD:LOWER {
    title "Lower Neighborhood"
    parms {
        n {ptype nbhood label "Neighborhood"}
    }
}

order define NBHOOD:LOWER {
    # FIRST, prepare the parameters
    prepare n  -trim -toupper -required 

    # Validate
    validate n { nbhood validate $parms(n) }

    returnOnError

    # NEXT, raise the neighborhood
    nbhood lower $parms(n)
}

# NBHOOD:RAISE

ordergui define NBHOOD:RAISE {
    title "Raise Neighborhood"
    parms {
        n {ptype nbhood label "Neighborhood"}
    }
}

order define NBHOOD:RAISE {
    # FIRST, prepare the parameters
    prepare n  -trim -toupper -required 

    # Validate
    validate n { nbhood validate $parms(n) }

    returnOnError

    # NEXT, raise the neighborhood
    nbhood raise $parms(n)
}

# NBHOOD:UPDATE
#
# Updates existing neighborhoods.

ordergui define NBHOOD:UPDATE {
    title "Update Neighborhood"
    parms {
        n            {ptype nbhood        label "Neighborhood"    }
        longname     {ptype text          label "Long Name"       }
        urbanization {ptype urbanization  label "Urbanization"    }
        refpoint     {ptype point         label "Reference Point" }
        polygon      {ptype polygon       label "Polygon"         }
    }
}

order define NBHOOD:UPDATE {
    # FIRST, prepare the parameters
    prepare n             -trim      -toupper -required
    prepare longname      -normalize
    prepare urbanization  -trim      -toupper
    prepare refpoint      -trim      -toupper
    prepare polygon       -normalize -toupper

    # NEXT, validate the neighborhood
    validate n { nbhood validate $parms(n) }

    # NEXT, validate the other parameters

    # longname
    if {$parms(longname) ne ""} {
        set n ""

        rdb eval {
            SELECT n FROM nbhoods
            WHERE longname=$parms(longname)
            OR    n=$parms(longname)
        } {}

        if {$n ne "" && $n ne $parms(n)} {
            reject longname "A neighborhood with this name already exists"
        }
    }

    # urbanization
    validate urbanization {
        set parms(urbanization) [eurbanization validate $parms(urbanization)]
    }

    # polygon
    #
    # Is the point a valid map reference string?
    # Is the resulting polygon a valid polygon?

    validate polygon {
        map ref validate {*}$parms(polygon)
        set parms(polygon) [map ref2m {*}$parms(polygon)]
        polygon validate $parms(polygon)
    }

    # refpoint
    #
    # Is the point a valid map reference string?
    # Is the point within the polygon?

    validate refpoint {
        map ref validate $parms(refpoint)
        set parms(refpoint) [map ref2m $parms(refpoint)]
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

    nbhood update $n [array get parms]

    setundo [nbhood lastundo]
}
