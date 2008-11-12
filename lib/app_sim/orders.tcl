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

order define NBHOOD:CREATE {
    title "Create Neighborhood"
    parms {
        longname     {ptype text          label "Long Name"       }
        urbanization {ptype urbanization  label "Urbanization"    }
        refpoint     {ptype point         label "Reference Point" }
        polygon      {ptype polygon       label "Polygon"         }
    }
} {
    # FIRST, validate the parameters
    parray parms
    
    # longname
    set parms(longname) [string trim $parms(longname)]

    if {[rdb exists {
        SELECT n FROM nbhoods 
        WHERE longname=$parms(longname)
        OR    n=$parms(longname)
    }]} {
        reject longname "A neighborhood with this name already exists"
    }

    # urbanization
    validate eurbanization urbanization
    
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
    
    notifier send ::order <NbhoodChanged> $n
}
