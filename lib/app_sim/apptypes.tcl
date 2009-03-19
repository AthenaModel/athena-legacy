#-----------------------------------------------------------------------
# TITLE:
#    apptypes.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Application Data Types
#
#    This module defines simple data types are application-specific and
#    hence don't fit in projtypes(n).
#
#-----------------------------------------------------------------------

# simstate: The current simulation state

enum simstate {
    PREP    Prep
    RUNNING Running
    PAUSED  Paused
}

# refpoint
#
# A refpoint is a location expressed as a map reference.  On validation,
# it is transformed into a location in map coordinates.

snit::type refpoint {
    pragma -hasinstances no

    typemethod validate {point} {
        map ref validate $point
        return [map ref2m $point]
    }
}

# refpoly
#
# A refpoly is a polygon expressed as a list of map reference strings.
# On validation, it is transformed into a flat list of locations in
# map coordinates.

snit::type refpoly {
    pragma -hasinstances no

    typemethod validate {poly} {
        map ref validate {*}$poly
        set coords [map ref2m {*}$poly]
        return polygon validate $coords
    }
}





