#-----------------------------------------------------------------------
# TITLE:
#    projectlib.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: projectlib(n) main package
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# External Package Dependencies

package require snit

#-----------------------------------------------------------------------
# Internal Package Dependencies

package require sqlite3
package require tdom
package require marsutil
package require simlib

#-----------------------------------------------------------------------
# Package Definition

package provide projectlib 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::projectlib:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 

    namespace export version
}

#-------------------------------------------------------------------
# Load binary extensions, if present.

set binlib [file join $::projectlib::library libVersion.so]

if {[file exists $binlib]} {
    load $binlib
} else {
    proc version {} {
        return "x.y.z"
    }
}

#-----------------------------------------------------------------------
# Load projectlib(n) submodules

source [file join $::projectlib::library projtypes.tcl      ]
source [file join $::projectlib::library calpattern.tcl     ]
source [file join $::projectlib::library prefs.tcl          ]
source [file join $::projectlib::library parmdb.tcl         ]
source [file join $::projectlib::library scenariodb.tcl     ]
source [file join $::projectlib::library appdir.tcl         ]
source [file join $::projectlib::library workdir.tcl        ]
source [file join $::projectlib::library verman.tcl         ]





