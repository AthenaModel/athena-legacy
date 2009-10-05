#-----------------------------------------------------------------------
# TITLE:
#	simlib.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: simlib(n) main package
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# External Package Dependencies

package require snit

#-----------------------------------------------------------------------
# Internal Package Dependencies

package require marsutil
package require sqlite3
package require tdom

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

source [file join $::simlib::library simtypes.tcl]
source [file join $::simlib::library coverage.tcl]
source [file join $::simlib::library rmf.tcl     ]
source [file join $::simlib::library gram.tcl    ]





