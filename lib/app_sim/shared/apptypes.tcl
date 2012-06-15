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
# NOTE:
#    Certain types defined in this module assume that there is a valid 
#    mapref(n) object (or equivalent) called "::map".
#
#-----------------------------------------------------------------------

# Priority tokens

enum ePrioSched {
    top    "Top Priority"
    bottom "Bottom Priority"
}

enum ePrioUpdate {
    top    "To Top"
    raise  "Raise"
    lower  "Lower"
    bottom "To Bottom"
}

# esanity: Severity levels used by sanity checkers
enum esanity {
    OK      OK
    WARNING Warning
    ERROR   Error
}

# esimstate: The current simulation state

enum esimstate {
    PREP     Prep
    RUNNING  Running
    PAUSED   Paused
    SNAPSHOT Snapshot
}

# esector: Econ Model sectors, used for the economic display variables
# in view(sim).

enum esector {
    GOODS goods
    POP   pop
    ELSE  else
}

# Magic Input Mode

enum einputmode {
    transient  "Transient"
    persistent "Persistent"
}

# Top Items for contributions reports

enum etopitems {
    ALL    "All Items"
    TOP5   "Top 5" 
    TOP10  "Top 10"
    TOP20  "Top 20"
    TOP50  "Top 50"
    TOP100 "Top 100"
}


# rgamma: The range for the belief system playbox gamma

::marsutil::range rgamma -min 0.0 -max 2.0

# rcoverage: The range for the coverage fractions

::marsutil::range rcov -min 0.0 -max 1.0

# rpcf: The range for the Production Capacity Factor

::marsutil::range rpcf -min 0.0

# rpcf0: The range for the Production Capacity Factor at time 0.

::marsutil::range rpcf0 -min 0.1 -max 1.0

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






