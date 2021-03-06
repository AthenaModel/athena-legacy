#-----------------------------------------------------------------------
# TITLE:
#    pkgModules.tcl
#
# PROJECT:
#    athena-sim - Athena Regional Stability Simulation
#
# DESCRIPTION:
#    projectgui(n) package modules file
#
#    Generated by Kite.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Package Definition

# -kite-provide-start  DO NOT EDIT THIS BLOCK BY HAND
package provide app_cellide 6.3.1a0
# -kite-provide-end

#-----------------------------------------------------------------------
# Required Packages

# Add 'package require' statements for this package's external 
# dependencies to the following block.  Kite will update the versions 
# numbers automatically as they change in project.kite.

# -kite-require-start ADD EXTERNAL DEPENDENCIES
package require snit 2.3
package require sqlite3 3.8.5
package require ctext 3.3

package require marsutil 3.0.2a0
package require marsgui 3.0.2a0
package require simlib 3.0.2a0

package require projectlib
package require projectgui
# -kite-require-end

namespace import ::marsutil::* 
namespace import ::marsgui::*
namespace import ::simlib::*
namespace import ::projectlib::*
namespace import ::projectgui::*

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_cellide:: {
    variable library [file dirname [info script]]
}


#-----------------------------------------------------------------------
# Load app_cellide(n) submodules

source [file join $::app_cellide::library app.tcl           ]
source [file join $::app_cellide::library app_types.tcl     ]
source [file join $::app_cellide::library cmscript.tcl      ]
source [file join $::app_cellide::library snapshot.tcl      ]

source [file join $::app_cellide::library appserver.tcl     ]

source [file join $::app_cellide::library appwin.tcl        ]
source [file join $::app_cellide::library cmscripteditor.tcl]
source [file join $::app_cellide::library detailbrowser.tcl ]
source [file join $::app_cellide::library ctexteditor.tcl   ]
source [file join $::app_cellide::library dynaforms.tcl     ]
