#-----------------------------------------------------------------------
# FILE: app_cell.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_cell(n) -- athena_cell(1) implementation package
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

namespace eval ::app_cell:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_cell(n) package

package provide app_cell 1.0

#-------------------------------------------------------------------
# Require packages

# From ActiveTclEE
package require snit             2.2
package require sqlite3          3.5
package require ctext

# From Mars
package require marsutil
package require marsgui
package require simlib 2.0

# From Athena
package require projectlib
package require projectgui
        
namespace import ::marsutil::* 
namespace import ::marsgui::*
namespace import ::simlib::*
namespace import ::projectlib::*
namespace import ::projectgui::*

#-----------------------------------------------------------------------
# Load app_cell(n) submodules

source [file join $::app_cell::library app.tcl           ]
source [file join $::app_cell::library app_types.tcl     ]
source [file join $::app_cell::library cmscript.tcl      ]

source [file join $::app_cell::library appserver.tcl     ]

source [file join $::app_cell::library appwin.tcl        ]
source [file join $::app_cell::library cmscripteditor.tcl]
source [file join $::app_cell::library detailbrowser.tcl ]
source [file join $::app_cell::library ctexteditor.tcl   ]

