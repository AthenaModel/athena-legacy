#-----------------------------------------------------------------------
# TITLE:
#	simlib2.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: simlib(n) main package for simlib 2.0
#
#       simlib 2.0 contains gram(n) and gramdb(n) V2.0.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# External Package Dependencies

package require snit

#-----------------------------------------------------------------------
# Internal Package Dependencies

package require marsutil
package require sqlite3

#-----------------------------------------------------------------------
# Package Definition

package provide simlib 2.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::simlib:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 
}


#-----------------------------------------------------------------------
# Load simlib(n) submodules

# Same for both v1.0 and v2.0
source [file join $::simlib::library simtypes.tcl  ]
source [file join $::simlib::library coverage.tcl  ]
source [file join $::simlib::library rmf.tcl       ]
source [file join $::simlib::library mam.tcl       ]

# Different for v2.0
source [file join $::simlib::library gram2.tcl     ]
source [file join $::simlib::library gramdb2.tcl   ]





