#-----------------------------------------------------------------------
# TITLE:
#    minlib.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Minerva: minlib(n) main package
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

package provide minlib 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::minlib:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 

    namespace export version
}

#-------------------------------------------------------------------
# Load binary extensions, if present.

set binlib [file join $::minlib::library libVersion.so]

if {[file exists $binlib]} {
    load $binlib
}

#-----------------------------------------------------------------------
# Load minlib(n) submodules

source [file join $::minlib::library mintypes.tcl]
source [file join $::minlib::library mapref.tcl]


