#-----------------------------------------------------------------------
# FILE: app_sim.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
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

namespace eval ::app_sim:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_sim(n) package

package provide app_sim 1.0

#-------------------------------------------------------------------
# Require packages

# From ActiveTclEE
package require snit             2.2
package require sqlite3          3.5
package require textutil::adjust 0.7
package require fileutil         1.14

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
# Load app_sim(n) submodules

# Non-GUI: Application
source [file join $::app_sim::library app.tcl                ]
source [file join $::app_sim::library apptypes.tcl           ]
source [file join $::app_sim::library executive.tcl          ]
source [file join $::app_sim::library cif.tcl                ]
source [file join $::app_sim::library ptype.tcl              ]
source [file join $::app_sim::library report.tcl             ]
source [file join $::app_sim::library dam.tcl                ]
source [file join $::app_sim::library firings.tcl            ]
source [file join $::app_sim::library view.tcl               ]
source [file join $::app_sim::library hist.tcl               ]
source [file join $::app_sim::library helpers.tcl            ]
source [file join $::app_sim::library sigevent.tcl           ]

# Non-GUI: Scenario
source [file join $::app_sim::library scenario.tcl           ]
source [file join $::app_sim::library parm.tcl               ]
source [file join $::app_sim::library map.tcl                ]
source [file join $::app_sim::library nbhood.tcl             ]
source [file join $::app_sim::library nbrel.tcl              ]
source [file join $::app_sim::library actor.tcl              ]
source [file join $::app_sim::library group.tcl              ]
source [file join $::app_sim::library civgroup.tcl           ]
source [file join $::app_sim::library frcgroup.tcl           ]
source [file join $::app_sim::library orggroup.tcl           ]
source [file join $::app_sim::library agent.tcl              ]
source [file join $::app_sim::library strategy.tcl           ]
source [file join $::app_sim::library cond_collection.tcl    ]
source [file join $::app_sim::library goal.tcl               ]
source [file join $::app_sim::library tactic.tcl             ]
source [file join $::app_sim::library tactic_assign.tcl      ]
source [file join $::app_sim::library tactic_attroe.tcl      ]
source [file join $::app_sim::library tactic_defroe.tcl      ]
source [file join $::app_sim::library tactic_demob.tcl       ]
source [file join $::app_sim::library tactic_deploy.tcl      ]
source [file join $::app_sim::library tactic_displace.tcl    ]
source [file join $::app_sim::library tactic_executive.tcl   ]
source [file join $::app_sim::library tactic_fundeni.tcl     ]
source [file join $::app_sim::library tactic_mobilize.tcl    ]
source [file join $::app_sim::library tactic_save.tcl        ]
source [file join $::app_sim::library tactic_spend.tcl       ]
source [file join $::app_sim::library condition.tcl          ]
source [file join $::app_sim::library condition_after.tcl    ]
source [file join $::app_sim::library condition_at.tcl       ]
source [file join $::app_sim::library condition_before.tcl   ]
source [file join $::app_sim::library condition_cash.tcl     ]
source [file join $::app_sim::library condition_control.tcl  ]
source [file join $::app_sim::library condition_during.tcl   ]
source [file join $::app_sim::library condition_expr.tcl     ]
source [file join $::app_sim::library condition_met.tcl      ]
source [file join $::app_sim::library condition_mood.tcl     ]
source [file join $::app_sim::library condition_nbcoop.tcl   ]
source [file join $::app_sim::library condition_nbmood.tcl   ]
source [file join $::app_sim::library condition_influence.tcl]
source [file join $::app_sim::library condition_troops.tcl   ]
source [file join $::app_sim::library condition_unmet.tcl    ]
source [file join $::app_sim::library sqdeploy.tcl           ]
source [file join $::app_sim::library personnel.tcl          ]
source [file join $::app_sim::library cash.tcl               ]
source [file join $::app_sim::library sqservice.tcl          ]
source [file join $::app_sim::library service.tcl            ]
source [file join $::app_sim::library sat.tcl                ]
source [file join $::app_sim::library rel.tcl                ]
source [file join $::app_sim::library coop.tcl               ]
source [file join $::app_sim::library unit.tcl               ]
source [file join $::app_sim::library mad.tcl                ]
source [file join $::app_sim::library bsystem.tcl            ]
source [file join $::app_sim::library appserver.tcl          ]
source [file join $::app_sim::library sanity.tcl             ]

# Non-GUI: Simulation
source [file join $::app_sim::library sim.tcl                ]
source [file join $::app_sim::library demog.tcl              ]
source [file join $::app_sim::library econ.tcl               ]
source [file join $::app_sim::library aam.tcl                ]
source [file join $::app_sim::library aam_rules.tcl          ]
source [file join $::app_sim::library nbstat.tcl             ]
source [file join $::app_sim::library security.tcl           ]
source [file join $::app_sim::library activity.tcl           ]
source [file join $::app_sim::library control.tcl            ]
source [file join $::app_sim::library control_rules.tcl      ]
source [file join $::app_sim::library situation.tcl          ]
source [file join $::app_sim::library actsit.tcl             ]
source [file join $::app_sim::library actsit_rules.tcl       ]
source [file join $::app_sim::library demsit.tcl             ]
source [file join $::app_sim::library demsit_rules.tcl       ]
source [file join $::app_sim::library ensit.tcl              ]
source [file join $::app_sim::library ensit_rules.tcl        ]
source [file join $::app_sim::library service_rules.tcl      ]

# GUI: Infrastructure
source [file join $::app_sim::library toolbutton.tcl         ]
source [file join $::app_sim::library appwin.tcl             ]
source [file join $::app_sim::library mapviewer.tcl          ]
source [file join $::app_sim::library mapicons.tcl           ]
source [file join $::app_sim::library mapicon_unit.tcl       ]
source [file join $::app_sim::library mapicon_situation.tcl  ]
source [file join $::app_sim::library nbchart.tcl            ]
source [file join $::app_sim::library timechart.tcl          ]
source [file join $::app_sim::library plotviewer.tcl         ]

# GUI: Browsers
source [file join $::app_sim::library activitybrowser.tcl    ]
source [file join $::app_sim::library actorbrowser.tcl       ]
source [file join $::app_sim::library actsitbrowser.tcl      ]
source [file join $::app_sim::library civgroupbrowser.tcl    ]
source [file join $::app_sim::library coopbrowser.tcl        ]   
source [file join $::app_sim::library demogbrowser.tcl       ]
source [file join $::app_sim::library demognbrowser.tcl      ]
source [file join $::app_sim::library demsitbrowser.tcl      ]
source [file join $::app_sim::library detailbrowser.tcl      ]
source [file join $::app_sim::library econcapbrowser.tcl     ]
source [file join $::app_sim::library econngbrowser.tcl      ]
source [file join $::app_sim::library econpopbrowser.tcl     ]
source [file join $::app_sim::library econsheet.tcl          ]
source [file join $::app_sim::library ensitbrowser.tcl       ]
source [file join $::app_sim::library frcgroupbrowser.tcl    ]
source [file join $::app_sim::library madbrowser.tcl         ]
source [file join $::app_sim::library nbcoopbrowser.tcl      ]   
source [file join $::app_sim::library nbhoodbrowser.tcl      ]
source [file join $::app_sim::library nbrelbrowser.tcl       ]
source [file join $::app_sim::library orderbrowser.tcl       ]
source [file join $::app_sim::library ordersentbrowser.tcl   ]
source [file join $::app_sim::library orggroupbrowser.tcl    ]
source [file join $::app_sim::library strategybrowser.tcl    ]
source [file join $::app_sim::library bsystembrowser.tcl     ]
source [file join $::app_sim::library relbrowser.tcl         ]
source [file join $::app_sim::library sqdeploybrowser.tcl    ]
source [file join $::app_sim::library sqservicebrowser.tcl   ]
source [file join $::app_sim::library satbrowser.tcl         ]
source [file join $::app_sim::library securitybrowser.tcl    ]





