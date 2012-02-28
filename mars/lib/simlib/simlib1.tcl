#-----------------------------------------------------------------------
# TITLE:
#	simlib1.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: simlib(n) main package for simlib 1.0
#
#       simlib 1.0 contains gram(n) and gramdb(n) V1.0.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# External Package Dependencies

package require snit

#-----------------------------------------------------------------------
# Internal Package Dependencies

package require marsutil
package require sqlite3
package require tdom ;# Why is this here?

#-----------------------------------------------------------------------
# Package Definition

package provide simlib 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::simlib:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 
}


#-----------------------------------------------------------------------
# Load simlib(n) submodules

source [file join $::simlib::library simtypes.tcl ]
source [file join $::simlib::library coverage.tcl ]
source [file join $::simlib::library rmf.tcl      ]
source [file join $::simlib::library gram.tcl     ]
source [file join $::simlib::library gramdb.tcl   ]
source [file join $::simlib::library mam.tcl      ]






