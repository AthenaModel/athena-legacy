#-----------------------------------------------------------------------
# TITLE:
#    orders_MAP.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    minerva_sim(1): MAP:* Orders
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# MAP:*

# MAP:IMPORT
#
# Imports a map into the scenario

ordergui define MAP:IMPORT {
    title "Import Map"
    parms {
        filename { ptype imagefile  label "Map File" }
    }
}

order define MAP:IMPORT {
    # FIRST, prepare the parameters
    prepare filename -trim -required 

    # NEXT, validate the parameters
    if {[catch {
        # In this case, simply try it.
        map import $parms(filename)
    } result]} {
        reject filename $result
    }

    returnOnError
}

