#-----------------------------------------------------------------------
# FILE: app_cmtool.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_cmtool(n) -- mars_cmtool(1) implementation package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_cmtool:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_cmtool(n) package

package provide app_cmtool 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Active Tcl
package require snit

# JNEM Packages
package require marsutil

namespace import ::marsutil::* 

#-----------------------------------------------------------------------
# Load app_cmtool(n) submodules

source [file join $::app_cmtool::library app.tcl]
source [file join $::app_cmtool::library app_check.tcl]
source [file join $::app_cmtool::library app_dump.tcl]
source [file join $::app_cmtool::library app_mash.tcl]
source [file join $::app_cmtool::library app_run.tcl]
source [file join $::app_cmtool::library app_solve.tcl]
source [file join $::app_cmtool::library app_xref.tcl]












