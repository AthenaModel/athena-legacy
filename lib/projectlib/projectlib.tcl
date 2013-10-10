#-----------------------------------------------------------------------
# TITLE:
#    projectlib.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: projectlib(n) main package
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# External Package Dependencies

package require snit

#-----------------------------------------------------------------------
# Internal Package Dependencies

package require TclOO
package require sqlite3
package require uri
package require fileutil
package require platform
package require marsutil
package require simlib

#-----------------------------------------------------------------------
# Package Definition

package provide projectlib 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::projectlib:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 
}

#-----------------------------------------------------------------------
# Load projectlib(n) submodules

source [file join $::projectlib::library os.tcl          ]
source [file join $::projectlib::library version.tcl     ]
source [file join $::projectlib::library enumx.tcl       ]
source [file join $::projectlib::library projtypes.tcl   ]
source [file join $::projectlib::library prefs.tcl       ]
source [file join $::projectlib::library parmdb.tcl      ]
source [file join $::projectlib::library scenariodb.tcl  ]
source [file join $::projectlib::library appdir.tcl      ]
source [file join $::projectlib::library workdir.tcl     ]
source [file join $::projectlib::library prefsdir.tcl    ]
source [file join $::projectlib::library verman.tcl      ]
source [file join $::projectlib::library htools.tcl      ]
source [file join $::projectlib::library myagent.tcl     ]
source [file join $::projectlib::library myserver.tcl    ]
source [file join $::projectlib::library urlquery.tcl    ]
source [file join $::projectlib::library rdbserver.tcl   ]
source [file join $::projectlib::library helpserver.tcl  ]
source [file join $::projectlib::library profiler.tcl    ]
source [file join $::projectlib::library week.tcl        ]
source [file join $::projectlib::library weekclock.tcl   ]
source [file join $::projectlib::library experimentdb.tcl]
source [file join $::projectlib::library gofer.tcl       ]
source [file join $::projectlib::library rolemap.tcl     ]
source [file join $::projectlib::library oohelpers.tcl   ]
source [file join $::projectlib::library beanclass.tcl   ]
source [file join $::projectlib::library bean.tcl        ]
source [file join $::projectlib::library clipboardx.tcl  ]

