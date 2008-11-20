#-----------------------------------------------------------------------
# TITLE:
#	app_sim.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Minerva: app_sim(n) loader
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

# From ActiveTclEE
package require snit     2.2
package require sqlite3  3.5

# From Mars
package require marsutil
package require marsgui

# From Minerva
package require minlib
package require mingui
        
namespace import ::marsutil::* 
namespace import ::marsgui::*
namespace import ::minlib::*
namespace import ::mingui::*

#-----------------------------------------------------------------------
# Load app_sim(n) submodules

# Non-GUI
source [file join $::app_sim::library app.tcl           ]
source [file join $::app_sim::library scenario.tcl      ]
source [file join $::app_sim::library map.tcl           ]
source [file join $::app_sim::library nbhood.tcl        ]
source [file join $::app_sim::library order.tcl         ]

# GUI
source [file join $::app_sim::library ordergui.tcl      ]
source [file join $::app_sim::library mainwin.tcl       ]
source [file join $::app_sim::library mapviewer.tcl     ]
source [file join $::app_sim::library mapicons.tcl      ]

# Orders
source [file join $::app_sim::library orders_NBHOOD.tcl ]


