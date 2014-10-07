#-----------------------------------------------------------------------
# TITLE:
#	simlib.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#   Mars: simlib(n) main package for simlib 3.0
#
#   simlib 3.0 contains GRAM 1 and URAM.
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

package provide simlib 3.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::simlib:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 
}


#-----------------------------------------------------------------------
# Load simlib(n) submodules

source [file join $::simlib::library simtypes.tcl  ]
source [file join $::simlib::library coverage.tcl  ]
source [file join $::simlib::library rmf.tcl       ]
source [file join $::simlib::library mam.tcl       ]
source [file join $::simlib::library gram.tcl      ]
source [file join $::simlib::library gramdb.tcl    ]
source [file join $::simlib::library uramdb.tcl    ]
source [file join $::simlib::library ucurve.tcl    ]
source [file join $::simlib::library uram.tcl      ]





