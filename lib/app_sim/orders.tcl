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
        n            {ptype text          label "Neighborhood ID" }
        longname     {ptype text          label "Long Name"       }
        refpoint     {ptype point         label "Reference Point" }
        polygon      {ptype polygon       label "Polygon"         }
        urbanization {ptype urbanization  label "Urbanization"    }
    }
} {
    # FIRST, validate the parameters
    parray parms
    
    # n
    set parms(n) [string toupper $parms(n)]

    # TBD: identifier doesn't return the value.  This is a problem.
    validate identifier n

    if {![invalid n]} {
        if {[rdb exists {SELECT n FROM nbhoods WHERE n=$parms(n)}]} {
            reject n "A neighborhood with this ID already exists."
        } 
    }

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
        INSERT INTO nbhoods(n,longname,refpoint,polygon,urbanization)
        VALUES($parms(n),
               $parms(longname),
               $parms(refpoint),
               $parms(polygon),
               $parms(urbanization));
    }

    # NEXT, notify the app.
    notifier send ::order <NbhoodChanged> $parms(n)
}
