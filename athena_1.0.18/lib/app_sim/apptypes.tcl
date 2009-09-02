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


# esimstate: The current simulation state

enum esimstate {
    PREP     Prep
    RUNNING  Running
    PAUSED   Paused
    SNAPSHOT Snapshot
}

# satgradient: A fill color gradient for satisfaction levels

::marsgui::gradient satgradient \
    -mincolor \#FF0000          \
    -midcolor \#FFFFFF          \
    -maxcolor \#00FF00          \
    -minlevel -100.0            \
    -midlevel 0.0               \
    -maxlevel 100.0

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






