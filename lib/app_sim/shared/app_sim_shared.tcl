#-----------------------------------------------------------------------
# FILE: app_sim_shared.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_sim_shared(n) -- Master package for athena(1) shared code.
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

namespace eval ::app_sim_shared:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_sim_shared(n) package

package provide app_sim_shared 1.0

#-------------------------------------------------------------------
# Require packages

# From ActiveTclEE
package require snit 2.2

# From Mars
package require marsutil
package require simlib
package require projectlib

namespace import ::marsutil::* ::simlib::* ::projectlib::*

#-----------------------------------------------------------------------
# Load app_sim_shared(n) modules

# FIRST, load modules that must be defined before the rest.
source [file join $::app_sim_shared::library field_types.tcl        ]

# NEXT, define the remaining modules in alphabetical order.
source [file join $::app_sim_shared::library aam.tcl                ]
source [file join $::app_sim_shared::library aam_rules.tcl          ]
source [file join $::app_sim_shared::library activity.tcl           ]
source [file join $::app_sim_shared::library actor.tcl              ]
source [file join $::app_sim_shared::library actsit.tcl             ]
source [file join $::app_sim_shared::library actsit_rules.tcl       ]
source [file join $::app_sim_shared::library agent.tcl              ]
source [file join $::app_sim_shared::library apptypes.tcl           ]
source [file join $::app_sim_shared::library bookmark.tcl           ]
source [file join $::app_sim_shared::library bsystem.tcl            ]
source [file join $::app_sim_shared::library cap.tcl                ]
source [file join $::app_sim_shared::library cash.tcl               ]
source [file join $::app_sim_shared::library civgroup.tcl           ]
source [file join $::app_sim_shared::library cond_collection.tcl    ]
source [file join $::app_sim_shared::library condition.tcl          ]
source [file join $::app_sim_shared::library condition_after.tcl    ]
source [file join $::app_sim_shared::library condition_at.tcl       ]
source [file join $::app_sim_shared::library condition_before.tcl   ]
source [file join $::app_sim_shared::library condition_cash.tcl     ]
source [file join $::app_sim_shared::library condition_control.tcl  ]
source [file join $::app_sim_shared::library condition_during.tcl   ]
source [file join $::app_sim_shared::library condition_expr.tcl     ]
source [file join $::app_sim_shared::library condition_met.tcl      ]
source [file join $::app_sim_shared::library condition_mood.tcl     ]
source [file join $::app_sim_shared::library condition_nbcoop.tcl   ]
source [file join $::app_sim_shared::library condition_nbmood.tcl   ]
source [file join $::app_sim_shared::library condition_influence.tcl]
source [file join $::app_sim_shared::library condition_troops.tcl   ]
source [file join $::app_sim_shared::library condition_unmet.tcl    ]
source [file join $::app_sim_shared::library control.tcl            ]
source [file join $::app_sim_shared::library control_model.tcl      ]
source [file join $::app_sim_shared::library control_rules.tcl      ]
source [file join $::app_sim_shared::library coop.tcl               ]
source [file join $::app_sim_shared::library coverage_model.tcl     ]
source [file join $::app_sim_shared::library dam.tcl                ]
source [file join $::app_sim_shared::library demog.tcl              ]
source [file join $::app_sim_shared::library demsit.tcl             ]
source [file join $::app_sim_shared::library demsit_rules.tcl       ]
source [file join $::app_sim_shared::library driver.tcl             ]
source [file join $::app_sim_shared::library econ.tcl               ]
source [file join $::app_sim_shared::library ensit.tcl              ]
source [file join $::app_sim_shared::library ensit_rules.tcl        ]
source [file join $::app_sim_shared::library executive.tcl          ]
source [file join $::app_sim_shared::library firings.tcl            ]
source [file join $::app_sim_shared::library frcgroup.tcl           ]
source [file join $::app_sim_shared::library goal.tcl               ]
source [file join $::app_sim_shared::library group.tcl              ]
source [file join $::app_sim_shared::library helpers.tcl            ]
source [file join $::app_sim_shared::library hist.tcl               ]
source [file join $::app_sim_shared::library hook.tcl               ]
source [file join $::app_sim_shared::library hrel.tcl               ]
source [file join $::app_sim_shared::library iom.tcl                ]
source [file join $::app_sim_shared::library iom_rules.tcl          ]
source [file join $::app_sim_shared::library mad.tcl                ]
source [file join $::app_sim_shared::library misc_rules.tcl         ]
source [file join $::app_sim_shared::library nbhood.tcl             ]
source [file join $::app_sim_shared::library nbrel.tcl              ]
source [file join $::app_sim_shared::library nbstat.tcl             ]
source [file join $::app_sim_shared::library orggroup.tcl           ]
source [file join $::app_sim_shared::library parm.tcl               ]
source [file join $::app_sim_shared::library payload.tcl            ]
source [file join $::app_sim_shared::library payload_coop.tcl       ]
source [file join $::app_sim_shared::library payload_hrel.tcl       ]
source [file join $::app_sim_shared::library payload_sat.tcl        ]
source [file join $::app_sim_shared::library payload_vrel.tcl       ]
source [file join $::app_sim_shared::library personnel.tcl          ]
source [file join $::app_sim_shared::library ptype.tcl              ]
source [file join $::app_sim_shared::library sat.tcl                ]
source [file join $::app_sim_shared::library security_model.tcl     ]
source [file join $::app_sim_shared::library service.tcl            ]
source [file join $::app_sim_shared::library service_rules.tcl      ]
source [file join $::app_sim_shared::library sigevent.tcl           ]
source [file join $::app_sim_shared::library situation.tcl          ]
source [file join $::app_sim_shared::library strategy.tcl           ]
source [file join $::app_sim_shared::library tactic.tcl             ]
source [file join $::app_sim_shared::library tactic_assign.tcl      ]
source [file join $::app_sim_shared::library tactic_attroe.tcl      ]
source [file join $::app_sim_shared::library tactic_broadcast.tcl   ]
source [file join $::app_sim_shared::library tactic_defroe.tcl      ]
source [file join $::app_sim_shared::library tactic_demob.tcl       ]
source [file join $::app_sim_shared::library tactic_deploy.tcl      ]
source [file join $::app_sim_shared::library tactic_deposit.tcl     ]
source [file join $::app_sim_shared::library tactic_executive.tcl   ]
source [file join $::app_sim_shared::library tactic_flow.tcl        ]
source [file join $::app_sim_shared::library tactic_fund.tcl        ]
source [file join $::app_sim_shared::library tactic_fundeni.tcl     ]
source [file join $::app_sim_shared::library tactic_grant.tcl       ]
source [file join $::app_sim_shared::library tactic_mobilize.tcl    ]
source [file join $::app_sim_shared::library tactic_stance.tcl      ]
source [file join $::app_sim_shared::library tactic_support.tcl     ]
source [file join $::app_sim_shared::library tactic_withdraw.tcl    ]
source [file join $::app_sim_shared::library unit.tcl               ]
source [file join $::app_sim_shared::library vrel.tcl               ]
