#-----------------------------------------------------------------------
# TITLE:
#    orders.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Sample Orders
#
#-----------------------------------------------------------------------

order define NBHOOD:CREATE {
    title "Create Neighborhood"
    parms {
        id           {ptype text          label "Neighborhood ID" }
        longname     {ptype text          label "Long Name"       }
        polygon      {ptype polygon       label "Polygon"         }
        refpoint     {ptype point         label "Reference Point" }
        urbanization {ptype urbanization  label "Urbanization"    }
    }
} {
    # FIRST, validate
    parray parms

    if {[regexp {\s} $parms(id)]} {
        reject id "Contains white space"
    }

    if {[string length $parms(refpoint)] > 6} {
        reject refpoint "Ref point too long"
    }

    returnOnError

    puts "Creating nbhood."

    # NEXT, execute
}
