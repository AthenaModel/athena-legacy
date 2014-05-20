#-----------------------------------------------------------------------
# FILE: app_ingest.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_ingest(n) -- athena_ingest(1) implementation package
#
# PROJECT:
#   Athena Regional Stability Simulation
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

namespace eval ::app_ingest:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_ingest(n) package

package provide app_ingest 1.0

#-------------------------------------------------------------------
# Require packages

# From ActiveTclEE
package require snit             2.2
package require sqlite3          3.5

# From Mars
package require marsutil
package require marsgui

# From Athena
package require projectlib
package require projectgui
        
namespace import ::marsutil::* 
namespace import ::marsgui::*
namespace import ::projectlib::*
namespace import ::projectgui::*

#-----------------------------------------------------------------------
# Load app_ingest(n) submodules

# Non-GUI
source [file join $::app_ingest::library app.tcl              ]
source [file join $::app_ingest::library rdb.tcl              ]
source [file join $::app_ingest::library tigr.tcl             ]
source [file join $::app_ingest::library ingester.tcl         ]
source [file join $::app_ingest::library helpers.tcl          ]
source [file join $::app_ingest::library simevent.tcl         ]
source [file join $::app_ingest::library simevent_drought.tcl ]
source [file join $::app_ingest::library simevent_flood.tcl   ]
source [file join $::app_ingest::library simevent_violence.tcl]

# GUI
source [file join $::app_ingest::library wizman.tcl           ]
source [file join $::app_ingest::library wizscenario.tcl      ]
source [file join $::app_ingest::library wiztigr.tcl          ]
source [file join $::app_ingest::library wizsorter.tcl        ]
source [file join $::app_ingest::library wizevents.tcl        ]
source [file join $::app_ingest::library wizexport.tcl        ]
source [file join $::app_ingest::library wizdummy.tcl         ]
source [file join $::app_ingest::library appwin.tcl           ]
