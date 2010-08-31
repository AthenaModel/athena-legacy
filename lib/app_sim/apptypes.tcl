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

# esector: Econ Model sectors, used for the economic display variables
# in view(sim).

enum esector {
    GOODS goods
    POP   pop
    ELSE  else
}

# rcoverage: The range for the coverage fractions

::marsutil::range rcov -min 0.0 -max 1.0

# rpcf: The range for the Production Capacity Factor

::marsutil::range rpcf -min 0.0

# rpcf0: The range for the Production Capacity Factor at time 0.

::marsutil::range rpcf0 -min 0.1 -max 1.0

# coopgradient: A fill color gradient for satisfaction levels

::marsgui::gradient coopgradient \
    -mincolor \#FF0000          \
    -midcolor \#FFFFFF          \
    -maxcolor \#00FF00          \
    -minlevel 0.0               \
    -midlevel 50.0              \
    -maxlevel 100.0

# covgradient: A fill color gradient for coverage fractions

::marsgui::gradient covgradient \
    -mincolor \#FFFFFF          \
    -midcolor \#FFFFFF          \
    -maxcolor \#0000FF          \
    -minlevel 0.0               \
    -midlevel 0.0               \
    -maxlevel 1.0

# pcfgradient: A fill color gradient for econ_n pcf's

::marsgui::gradient pcfgradient \
    -mincolor \#FF0000          \
    -midcolor \#FFFFFF          \
    -maxcolor \#00FF00          \
    -minlevel 0.0               \
    -midlevel 1.0               \
    -maxlevel 2.0

# satgradient: A fill color gradient for satisfaction levels

::marsgui::gradient satgradient \
    -mincolor \#FF0000          \
    -midcolor \#FFFFFF          \
    -maxcolor \#00FF00          \
    -minlevel -100.0            \
    -midlevel 0.0               \
    -maxlevel 100.0

# secgradient: A fill color gradient for security levels

::marsgui::gradient secgradient \
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






