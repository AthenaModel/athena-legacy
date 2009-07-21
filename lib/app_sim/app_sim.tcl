#-----------------------------------------------------------------------
# TITLE:
#    app_sim.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: app_sim(n) loader
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
package require simlib

# From Athena
package require projectlib
package require projectgui
        
namespace import ::marsutil::* 
namespace import ::marsgui::*
namespace import ::simlib::*
namespace import ::projectlib::*
namespace import ::projectgui::*

#-----------------------------------------------------------------------
# Load app_sim(n) submodules

# Non-GUI: Application
source [file join $::app_sim::library app.tcl              ]
source [file join $::app_sim::library apptypes.tcl         ]
source [file join $::app_sim::library executive.tcl        ]
source [file join $::app_sim::library cif.tcl              ]
source [file join $::app_sim::library order.tcl            ]
source [file join $::app_sim::library ptype.tcl            ]
source [file join $::app_sim::library report.tcl           ]
source [file join $::app_sim::library dam.tcl              ]

# Non-GUI: Scenario
source [file join $::app_sim::library scenario.tcl         ]
source [file join $::app_sim::library parm.tcl             ]
source [file join $::app_sim::library map.tcl              ]
source [file join $::app_sim::library nbhood.tcl           ]
source [file join $::app_sim::library nbrel.tcl            ]
source [file join $::app_sim::library group.tcl            ]
source [file join $::app_sim::library civgroup.tcl         ]
source [file join $::app_sim::library frcgroup.tcl         ]
source [file join $::app_sim::library orggroup.tcl         ]
source [file join $::app_sim::library nbgroup.tcl          ]
source [file join $::app_sim::library sat.tcl              ]
source [file join $::app_sim::library rel.tcl              ]
source [file join $::app_sim::library coop.tcl             ]
source [file join $::app_sim::library attroe.tcl           ]
source [file join $::app_sim::library defroe.tcl           ]
source [file join $::app_sim::library unit.tcl             ]

# Non-GUI: Simulation
source [file join $::app_sim::library sim.tcl              ]
source [file join $::app_sim::library demog.tcl            ]
source [file join $::app_sim::library aam.tcl              ]
source [file join $::app_sim::library aam_rules.tcl        ]
source [file join $::app_sim::library nbstat.tcl           ]
source [file join $::app_sim::library security.tcl         ]
source [file join $::app_sim::library activity.tcl         ]
source [file join $::app_sim::library situation.tcl        ]
source [file join $::app_sim::library actsit.tcl           ]
source [file join $::app_sim::library actsit_rules.tcl     ]
source [file join $::app_sim::library ensit.tcl            ]
source [file join $::app_sim::library ensit_rules.tcl      ]

# GUI
source [file join $::app_sim::library helpbrowserwin.tcl   ]
source [file join $::app_sim::library orderdialog.tcl      ]
source [file join $::app_sim::library appwin.tcl           ]
source [file join $::app_sim::library mapviewer.tcl        ]
source [file join $::app_sim::library mapicons.tcl         ]
source [file join $::app_sim::library mapicon_unit.tcl     ]
source [file join $::app_sim::library mapicon_situation.tcl]
source [file join $::app_sim::library browser_base.tcl     ]
source [file join $::app_sim::library activitybrowser.tcl  ]
source [file join $::app_sim::library actsitbrowser.tcl    ]
source [file join $::app_sim::library ensitbrowser.tcl     ]
source [file join $::app_sim::library nbhoodbrowser.tcl    ]
source [file join $::app_sim::library nbrelbrowser.tcl     ]
source [file join $::app_sim::library civgroupbrowser.tcl  ]
source [file join $::app_sim::library frcgroupbrowser.tcl  ]
source [file join $::app_sim::library orggroupbrowser.tcl  ]
source [file join $::app_sim::library nbgroupbrowser.tcl   ]
source [file join $::app_sim::library demogbrowser.tcl     ]
source [file join $::app_sim::library satbrowser.tcl       ]
source [file join $::app_sim::library securitybrowser.tcl  ]
source [file join $::app_sim::library relbrowser.tcl       ]
source [file join $::app_sim::library coopbrowser.tcl      ] 
source [file join $::app_sim::library nbcoopbrowser.tcl    ] 
source [file join $::app_sim::library attroeufbrowser.tcl  ]
source [file join $::app_sim::library attroenfbrowser.tcl  ]
source [file join $::app_sim::library defroebrowser.tcl    ]
source [file join $::app_sim::library unitbrowser.tcl      ]










