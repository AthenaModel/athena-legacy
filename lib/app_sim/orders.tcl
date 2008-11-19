#-----------------------------------------------------------------------
# TITLE:
#    orders.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    minerva_sim(1): Simulation Orders
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Orders

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
    if {![invalid longname] && [rdb exists {
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
        set points [map ref2m {*}$parms(polygon)]
        polygon validate $points
    }

    # refpoint
    #
    # Is the point a valid map reference string?
    # Is the point within the polygon?

    validate refpoint {
        map ref validate $parms(refpoint)
    }

    if {![invalid refpoint] && ![invalid polygon]} {
        lassign [map ref2m $parms(refpoint)] mx my

        if {![ptinpoly $points [list $mx $my]]} {
            reject refpoint "not in polygon"
        }
    }
    
    returnOnError

    # NEXT, Put the neighborhood in the database
    rdb eval {
        INSERT INTO nbhoods(longname,refpoint,polygon,urbanization)
        VALUES($parms(longname),
               $parms(refpoint),
               $parms(polygon),
               $parms(urbanization));

        -- Set the "n" based on the uid.
        UPDATE nbhoods
        SET    n=format('N%03d',last_insert_rowid())
        WHERE uid=last_insert_rowid();
        
        -- Get the "n" value
        SELECT n FROM nbhoods WHERE uid=last_insert_rowid();
    } {}

    # NEXT, notify the app.
    # TBD: This should perhaps come from some other module.
    # TBD: This should perhaps be <NbhoodCreated>.
    
    notifier send ::order <NbhoodChanged> $n
}
