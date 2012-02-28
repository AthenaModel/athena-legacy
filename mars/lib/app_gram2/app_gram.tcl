#-----------------------------------------------------------------------
# FILE: app_gram.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_gram2(n) -- mars_gram21) implementation package, V2.0
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

namespace eval ::app_gram:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_gram2(n) package

package provide app_gram 2.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Active Tcl
package require sqlite3
package require snit

# JNEM Packages
package require marsutil
package require marsgui
package require simlib 2.0

namespace import ::marsutil::* 
namespace import ::marsgui::*
namespace import ::simlib::*

#-----------------------------------------------------------------------
# Load app_gram2(n) submodules

source [file join $::app_gram::library app.tcl       ]
source [file join $::app_gram::library appwin.tcl    ]
source [file join $::app_gram::library executive.tcl ] 
source [file join $::app_gram::library parmdb.tcl    ]
source [file join $::app_gram::library sim.tcl       ]













