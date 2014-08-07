#-----------------------------------------------------------------------
# FILE: app_sim.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
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

namespace eval ::app_sim:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_sim(n) package

package provide app_sim 1.0

#-------------------------------------------------------------------
# Require packages

# From ActiveTcl
package require snit             2.2
package require sqlite3          3.5
package require textutil::adjust 0.7
package require TclOO

# From Mars
package require marsutil
package require simlib

# From Athena
package require projectlib
package require app_sim_shared
        
namespace import ::marsutil::* 
namespace import ::simlib::*
namespace import ::projectlib::*

# For Tk applications
if {$::loadTk} {
    # From Mars
    package require marsgui

    # From Athena
    package require projectgui
    package require app_sim_ui
    package require wintel

    namespace import ::marsgui::*
    namespace import ::projectgui::*
}

#-----------------------------------------------------------------------
# Load app_sim(n) submodules

source [file join $::app_sim::library app.tcl      ]
source [file join $::app_sim::library scenario.tcl ]
source [file join $::app_sim::library sim.tcl      ]
source [file join $::app_sim::library engine.tcl   ]
source [file join $::app_sim::library log.tcl      ]
source [file join $::app_sim::library cif.tcl      ]
source [file join $::app_sim::library map.tcl      ]
source [file join $::app_sim::library sanity.tcl   ]
source [file join $::app_sim::library axdb.tcl     ]







