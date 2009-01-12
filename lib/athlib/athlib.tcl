#-----------------------------------------------------------------------
# TITLE:
#    athlib.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: athlib(n) main package
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

package provide athlib 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::athlib:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 

    namespace export version
}

#-------------------------------------------------------------------
# Load binary extensions, if present.

set binlib [file join $::athlib::library libVersion.so]

if {[file exists $binlib]} {
    load $binlib
}

#-----------------------------------------------------------------------
# Load athlib(n) submodules

source [file join $::athlib::library athtypes.tcl   ]
source [file join $::athlib::library mapref.tcl     ]
source [file join $::athlib::library scenariodb.tcl ]
source [file join $::athlib::library workdir.tcl    ]
source [file join $::athlib::library verman.tcl     ]




