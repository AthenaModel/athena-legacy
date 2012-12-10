#-----------------------------------------------------------------------
# FILE: app_log.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_log(n) -- mars_log(1) implementation package
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

namespace eval ::app_log:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_log(n) package

package provide app_log 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Active Tcl
package require snit

# Mars Packages
package require marsutil
package require marsgui

namespace import ::marsutil::*
namespace import ::marsgui::*

#-----------------------------------------------------------------------
# Load app_log(n) submodules

source [file join $::app_log::library app.tcl]










