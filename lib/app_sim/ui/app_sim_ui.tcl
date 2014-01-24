#-----------------------------------------------------------------------
# FILE: app_sim_ui.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_sim_ui(n) -- Athena(1) User Interface (i.e., Tk) code.
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
package require ctext

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

#-----------------------------------------------------------------------
# Load app_sim_ui(n) modules

source [file join $::app_sim_ui::library activitybrowser.tcl    ]
source [file join $::app_sim_ui::library actorbrowser.tcl       ]
source [file join $::app_sim_ui::library appwin.tcl             ]
source [file join $::app_sim_ui::library bookmarkbrowser.tcl    ]
source [file join $::app_sim_ui::library bsystembrowser.tcl     ]
source [file join $::app_sim_ui::library civgroupbrowser.tcl    ]
source [file join $::app_sim_ui::library capbrowser.tcl         ]
source [file join $::app_sim_ui::library cgesheet.tcl           ]
source [file join $::app_sim_ui::library coopbrowser.tcl        ]
source [file join $::app_sim_ui::library coopbrowser_sim.tcl    ]
source [file join $::app_sim_ui::library ctexteditor.tcl        ]
source [file join $::app_sim_ui::library cursebrowser.tcl       ]
source [file join $::app_sim_ui::library demogbrowser.tcl       ]
source [file join $::app_sim_ui::library demognbrowser.tcl      ]
source [file join $::app_sim_ui::library detailbrowser.tcl      ]
source [file join $::app_sim_ui::library econexpbrowser.tcl     ]
source [file join $::app_sim_ui::library econngbrowser.tcl      ]
source [file join $::app_sim_ui::library econpopbrowser.tcl     ]
source [file join $::app_sim_ui::library ensitbrowser.tcl       ]
source [file join $::app_sim_ui::library frcgroupbrowser.tcl    ]
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
source [file join $::app_sim_ui::library plantbrowser.tcl       ] 
source [file join $::app_sim_ui::library samsheet.tcl           ]
source [file join $::app_sim_ui::library satbrowser.tcl         ]
source [file join $::app_sim_ui::library scriptbrowser.tcl      ]
source [file join $::app_sim_ui::library securitybrowser.tcl    ]
source [file join $::app_sim_ui::library strategybrowser.tcl    ]
source [file join $::app_sim_ui::library timechart.tcl          ]
source [file join $::app_sim_ui::library toolbutton.tcl         ]
source [file join $::app_sim_ui::library vrelbrowser.tcl        ]
source [file join $::app_sim_ui::library vrelbrowser_sim.tcl    ]


