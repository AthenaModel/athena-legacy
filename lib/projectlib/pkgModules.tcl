#-----------------------------------------------------------------------
# TITLE:
#    pkgModules.tcl
#
# PROJECT:
#    athena-sim - Athena Regional Stability Simulation
#
# DESCRIPTION:
#    projectlib(n) package modules file
#
#    Generated by Kite.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Package Definition

# -kite-provide-start  DO NOT EDIT THIS BLOCK BY HAND
package provide projectlib 6.3.1a0
# -kite-provide-end

#-----------------------------------------------------------------------
# Required Packages

# Add 'package require' statements for this package's external 
# dependencies to the following block.  Kite will update the versions 
# numbers automatically as they change in project.kite.

# -kite-require-start ADD EXTERNAL DEPENDENCIES
package require platform
package require http
package require sqlite3 3.8.5
package require uri 1.2
package require fileutil 1.14
package require tls 1.6
package require tdom 0.8
package require struct::set 2.2
package require -exact kiteutils 0.4.0a0
package require -exact marsutil 3.0.2a0
package require -exact simlib 3.0.2a0
# -kite-require-end

package require kiteinfo

#-----------------------------------------------------------------------
# Namespace definition

namespace import ::kiteutils::*
namespace import ::marsutil::* 
namespace import ::simlib::*

namespace eval ::projectlib:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Modules

source [file join $::projectlib::library osdir.tcl          ]
source [file join $::projectlib::library domparser.tcl      ]
source [file join $::projectlib::library enumx.tcl          ]
source [file join $::projectlib::library projtypes.tcl      ]
source [file join $::projectlib::library prefs.tcl          ]
source [file join $::projectlib::library parmdb.tcl         ]
source [file join $::projectlib::library scenariodb.tcl     ]
source [file join $::projectlib::library appdir.tcl         ]
source [file join $::projectlib::library workdir.tcl        ]
source [file join $::projectlib::library prefsdir.tcl       ]
source [file join $::projectlib::library htools.tcl         ]
source [file join $::projectlib::library myagent.tcl        ]
source [file join $::projectlib::library myserver.tcl       ]
source [file join $::projectlib::library urlquery.tcl       ]
source [file join $::projectlib::library rdbserver.tcl      ]
source [file join $::projectlib::library helpserver.tcl     ]
source [file join $::projectlib::library profiler.tcl       ]
source [file join $::projectlib::library week.tcl           ]
source [file join $::projectlib::library weekclock.tcl      ]
source [file join $::projectlib::library wfscap.tcl         ]
source [file join $::projectlib::library wmscap.tcl         ]
source [file join $::projectlib::library wmsexcept.tcl      ]
source [file join $::projectlib::library tigrmsg.tcl        ]
source [file join $::projectlib::library kmlpoly.tcl        ]
source [file join $::projectlib::library experimentdb.tcl   ]
source [file join $::projectlib::library gofer.tcl          ]
source [file join $::projectlib::library field_types.tcl    ]
source [file join $::projectlib::library rolemap.tcl        ]
source [file join $::projectlib::library oohelpers.tcl      ]
source [file join $::projectlib::library beanclass.tcl      ]
source [file join $::projectlib::library bean.tcl           ]
source [file join $::projectlib::library clipboardx.tcl     ]
source [file join $::projectlib::library httpagent.tcl      ]
source [file join $::projectlib::library httpagentsim.tcl   ]
source [file join $::projectlib::library wmsclient.tcl      ]
source [file join $::projectlib::library wfsclient.tcl      ]