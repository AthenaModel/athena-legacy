#-----------------------------------------------------------------------
# FILE: app_sim_ui.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_sim_ui(n) -- Athena(1) User Interface code.
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

namespace eval ::app_sim_ui:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_sim_ui(n) package

package provide app_sim_ui 1.0

#-------------------------------------------------------------------
# Require packages

# From ActiveTclEE
package require snit 2.2

# From Mars
package require marsutil
package require marsgui
package require simlib
package require projectlib
package require projectgui

namespace import ::marsutil::*
namespace import ::marsgui::*
namespace import ::simlib::* 
namespace import ::projectlib::*
namespace import ::projectgui::*

# Patch to tablelist 5.6 bug
if {[package require tablelist] eq "5.6"} {
proc tablelist::reconfigWindows win {
    #
    # Force any geometry manager calculations to be completed first
    #
    update idletasks
    if {![namespace exists ::tablelist::ns${win}]} {
	return ""
    }

    #
    # Reconfigure the cells specified in the list data(cellsToReconfig)
    #
    upvar ::tablelist::ns${win}::data data
    foreach cellIdx $data(cellsToReconfig) {
	foreach {row col} [split $cellIdx ","] {}
	set key [lindex $data(keyList) $row]
	if {[info exists data($key,$col-window)]} {
	    doCellConfig $row $col $win -window $data($key,$col-window)
	}
    }

    unset data(reconfigId)
    set data(cellsToReconfig) {}
}
}

#-----------------------------------------------------------------------
# Load app_sim_ui(n) modules

source [file join $::app_sim_ui::library activitybrowser.tcl    ]
source [file join $::app_sim_ui::library actorbrowser.tcl       ]
source [file join $::app_sim_ui::library actsitbrowser.tcl      ]
source [file join $::app_sim_ui::library appserver.tcl          ]
source [file join $::app_sim_ui::library appserver_actor.tcl    ]
source [file join $::app_sim_ui::library appserver_cap.tcl      ]
source [file join $::app_sim_ui::library appserver_contribs.tcl ]
source [file join $::app_sim_ui::library appserver_docs.tcl     ]
source [file join $::app_sim_ui::library appserver_drivers.tcl  ]
source [file join $::app_sim_ui::library appserver_econ.tcl     ]
source [file join $::app_sim_ui::library appserver_enums.tcl    ]
source [file join $::app_sim_ui::library appserver_group.tcl    ]
source [file join $::app_sim_ui::library appserver_home.tcl     ]
source [file join $::app_sim_ui::library appserver_hook.tcl     ]
source [file join $::app_sim_ui::library appserver_image.tcl    ]
source [file join $::app_sim_ui::library appserver_iom.tcl      ]
source [file join $::app_sim_ui::library appserver_marsdocs.tcl ]
source [file join $::app_sim_ui::library appserver_nbhood.tcl   ]
source [file join $::app_sim_ui::library appserver_objects.tcl  ]
source [file join $::app_sim_ui::library appserver_overview.tcl ]
source [file join $::app_sim_ui::library appserver_parmdb.tcl   ]
source [file join $::app_sim_ui::library appserver_plot.tcl     ]
source [file join $::app_sim_ui::library appserver_sanity.tcl   ]
source [file join $::app_sim_ui::library appserver_sigevents.tcl]
source [file join $::app_sim_ui::library appwin.tcl             ]
source [file join $::app_sim_ui::library attritbrowser.tcl      ]
source [file join $::app_sim_ui::library bookmarkbrowser.tcl    ]
source [file join $::app_sim_ui::library bsystembrowser.tcl     ]
source [file join $::app_sim_ui::library civgroupbrowser.tcl    ]
source [file join $::app_sim_ui::library capbrowser.tcl         ]
source [file join $::app_sim_ui::library cgesheet.tcl           ]
source [file join $::app_sim_ui::library coopbrowser.tcl        ]
source [file join $::app_sim_ui::library coopbrowser_sim.tcl    ]
source [file join $::app_sim_ui::library demogbrowser.tcl       ]
source [file join $::app_sim_ui::library demognbrowser.tcl      ]
source [file join $::app_sim_ui::library demsitbrowser.tcl      ]
source [file join $::app_sim_ui::library detailbrowser.tcl      ]
source [file join $::app_sim_ui::library econcapbrowser.tcl     ]
source [file join $::app_sim_ui::library econngbrowser.tcl      ]
source [file join $::app_sim_ui::library econpopbrowser.tcl     ]
source [file join $::app_sim_ui::library ensitbrowser.tcl       ]
source [file join $::app_sim_ui::library frcgroupbrowser.tcl    ]
source [file join $::app_sim_ui::library gradient.tcl           ]
source [file join $::app_sim_ui::library hookbrowser.tcl        ]
source [file join $::app_sim_ui::library hrelbrowser.tcl        ]
source [file join $::app_sim_ui::library hrelbrowser_sim.tcl    ]
source [file join $::app_sim_ui::library iombrowser.tcl         ]
source [file join $::app_sim_ui::library madbrowser.tcl         ]
source [file join $::app_sim_ui::library mapicon_situation.tcl  ]
source [file join $::app_sim_ui::library mapicon_unit.tcl       ]
source [file join $::app_sim_ui::library mapicons.tcl           ]
source [file join $::app_sim_ui::library mapviewer.tcl          ]
source [file join $::app_sim_ui::library nbchart.tcl            ]
source [file join $::app_sim_ui::library nbcoopbrowser.tcl      ]
source [file join $::app_sim_ui::library nbhoodbrowser.tcl      ]
source [file join $::app_sim_ui::library nbrelbrowser.tcl       ]
source [file join $::app_sim_ui::library ordersentbrowser.tcl   ]
source [file join $::app_sim_ui::library orggroupbrowser.tcl    ]
source [file join $::app_sim_ui::library plotviewer.tcl         ] 
source [file join $::app_sim_ui::library samsheet.tcl           ]
source [file join $::app_sim_ui::library satbrowser.tcl         ]
source [file join $::app_sim_ui::library satbrowser_sim.tcl     ]
source [file join $::app_sim_ui::library securitybrowser.tcl    ]
source [file join $::app_sim_ui::library strategybrowser.tcl    ]
source [file join $::app_sim_ui::library timechart.tcl          ]
source [file join $::app_sim_ui::library toolbutton.tcl         ]
source [file join $::app_sim_ui::library view.tcl               ]
source [file join $::app_sim_ui::library vrelbrowser.tcl        ]
source [file join $::app_sim_ui::library vrelbrowser_sim.tcl    ]

