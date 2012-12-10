#-----------------------------------------------------------------------
# TITLE:
#    marsutil.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Mars: marsutil(n) Tcl Utilities
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Package Dependencies

package require snit    2.3
package require textutil::expander
package require sqlite3 3.6
package require comm

#-----------------------------------------------------------------------
# Package Definition

package provide marsutil 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::marsutil:: {
    variable library [file dirname [info script]]
}

#-------------------------------------------------------------------
# Load binary extensions, if present.

catch {package require Marsbin}

#-----------------------------------------------------------------------
# Submodules
#
# Note: modules are listed in order of dependencies; be careful if you
# change the order!

source [file join $::marsutil::library marsmisc.tcl       ]
source [file join $::marsutil::library template.tcl       ]
source [file join $::marsutil::library sequence.tcl       ]
source [file join $::marsutil::library ehtml.tcl          ]
source [file join $::marsutil::library logger.tcl         ]
source [file join $::marsutil::library logreader.tcl      ]
source [file join $::marsutil::library simclock.tcl       ]
source [file join $::marsutil::library zulu.tcl           ]
source [file join $::marsutil::library notifier.tcl       ]
source [file join $::marsutil::library enum.tcl           ]
source [file join $::marsutil::library quality.tcl        ]
source [file join $::marsutil::library range.tcl          ]
source [file join $::marsutil::library vec.tcl            ]
source [file join $::marsutil::library mat.tcl            ]
source [file join $::marsutil::library mat3d.tcl          ]
source [file join $::marsutil::library smartinterp.tcl    ]
source [file join $::marsutil::library parmset.tcl        ]
source [file join $::marsutil::library commserver.tcl     ]
source [file join $::marsutil::library commclient.tcl     ]
source [file join $::marsutil::library gtclient.tcl       ]
source [file join $::marsutil::library gtserver.tcl       ]
source [file join $::marsutil::library zcurve.tcl         ]
source [file join $::marsutil::library sqlib.tcl          ]
source [file join $::marsutil::library sqldocument.tcl    ]
source [file join $::marsutil::library statecontroller.tcl]
source [file join $::marsutil::library geometry.tcl       ]
source [file join $::marsutil::library geoset.tcl         ]
source [file join $::marsutil::library latlong.tcl        ]
source [file join $::marsutil::library timeout.tcl        ]
source [file join $::marsutil::library lazyupdater.tcl    ]
source [file join $::marsutil::library callbacklist.tcl   ]
source [file join $::marsutil::library eventq.tcl         ]
source [file join $::marsutil::library cmdinfo.tcl        ]
source [file join $::marsutil::library reporter.tcl       ]
source [file join $::marsutil::library tabletext.tcl      ]
source [file join $::marsutil::library cellmodel.tcl      ]
source [file join $::marsutil::library mapref.tcl         ]
source [file join $::marsutil::library mapsimple.tcl      ]
source [file join $::marsutil::library dynaform.tcl       ]
source [file join $::marsutil::library dynaform_fields.tcl]
source [file join $::marsutil::library order.tcl          ]
source [file join $::marsutil::library undostack.tcl      ]

