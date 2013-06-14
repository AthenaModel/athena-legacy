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
source [file join $::app_sim_shared::library activity.tcl           ]
source [file join $::app_sim_shared::library actor.tcl              ]
source [file join $::app_sim_shared::library agent.tcl              ]
source [file join $::app_sim_shared::library appserver.tcl          ]
source [file join $::app_sim_shared::library appserver_actor.tcl    ]
source [file join $::app_sim_shared::library appserver_cap.tcl      ]
source [file join $::app_sim_shared::library appserver_contribs.tcl ]
source [file join $::app_sim_shared::library appserver_curses.tcl   ]
source [file join $::app_sim_shared::library appserver_docs.tcl     ]
source [file join $::app_sim_shared::library appserver_drivers.tcl  ]
source [file join $::app_sim_shared::library appserver_econ.tcl     ]
source [file join $::app_sim_shared::library appserver_enums.tcl    ]
source [file join $::app_sim_shared::library appserver_firing.tcl   ]
source [file join $::app_sim_shared::library appserver_group.tcl    ]
source [file join $::app_sim_shared::library appserver_home.tcl     ]
source [file join $::app_sim_shared::library appserver_hook.tcl     ]
source [file join $::app_sim_shared::library appserver_image.tcl    ]
source [file join $::app_sim_shared::library appserver_iom.tcl      ]
source [file join $::app_sim_shared::library appserver_mads.tcl     ]
source [file join $::app_sim_shared::library appserver_marsdocs.tcl ]
source [file join $::app_sim_shared::library appserver_nbhood.tcl   ]
source [file join $::app_sim_shared::library appserver_objects.tcl  ]
source [file join $::app_sim_shared::library appserver_overview.tcl ]
source [file join $::app_sim_shared::library appserver_parmdb.tcl   ]
source [file join $::app_sim_shared::library appserver_plot.tcl     ]
source [file join $::app_sim_shared::library appserver_sanity.tcl   ]
source [file join $::app_sim_shared::library appserver_sigevents.tcl]
source [file join $::app_sim_shared::library apptypes.tcl           ]
source [file join $::app_sim_shared::library autogen.tcl            ]
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
source [file join $::app_sim_shared::library coop.tcl               ]
source [file join $::app_sim_shared::library coverage_model.tcl     ]
source [file join $::app_sim_shared::library curse.tcl              ]
source [file join $::app_sim_shared::library dam.tcl                ]
source [file join $::app_sim_shared::library demog.tcl              ]
source [file join $::app_sim_shared::library driver.tcl             ]
source [file join $::app_sim_shared::library driver_actsit.tcl      ]
source [file join $::app_sim_shared::library driver_civcas.tcl      ]
source [file join $::app_sim_shared::library driver_consump.tcl     ]
source [file join $::app_sim_shared::library driver_control.tcl     ]
source [file join $::app_sim_shared::library driver_curse.tcl       ]
source [file join $::app_sim_shared::library driver_eni.tcl         ]
source [file join $::app_sim_shared::library driver_ensit.tcl       ]
source [file join $::app_sim_shared::library driver_iom.tcl         ]
source [file join $::app_sim_shared::library driver_magic.tcl       ]
source [file join $::app_sim_shared::library driver_mood.tcl        ]
source [file join $::app_sim_shared::library driver_unemp.tcl       ]
source [file join $::app_sim_shared::library econ.tcl               ]
source [file join $::app_sim_shared::library ensit.tcl              ]
source [file join $::app_sim_shared::library executive.tcl          ]
source [file join $::app_sim_shared::library frcgroup.tcl           ]
source [file join $::app_sim_shared::library goal.tcl               ]
source [file join $::app_sim_shared::library gofer_helpers.tcl      ]
source [file join $::app_sim_shared::library gofer_actors.tcl       ]
source [file join $::app_sim_shared::library gofer_civgroups.tcl    ]
source [file join $::app_sim_shared::library gofer_frcgroups.tcl    ]
source [file join $::app_sim_shared::library gofer_groups.tcl       ]
source [file join $::app_sim_shared::library gradient.tcl           ]
source [file join $::app_sim_shared::library group.tcl              ]
source [file join $::app_sim_shared::library helpers.tcl            ]
source [file join $::app_sim_shared::library hist.tcl               ]
source [file join $::app_sim_shared::library hook.tcl               ]
source [file join $::app_sim_shared::library hrel.tcl               ]
source [file join $::app_sim_shared::library inject.tcl             ]
source [file join $::app_sim_shared::library inject_coop.tcl        ]
source [file join $::app_sim_shared::library inject_hrel.tcl        ]
source [file join $::app_sim_shared::library inject_sat.tcl         ]
source [file join $::app_sim_shared::library inject_vrel.tcl        ]
source [file join $::app_sim_shared::library iom.tcl                ]
source [file join $::app_sim_shared::library mad.tcl                ]
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
source [file join $::app_sim_shared::library rebase.tcl             ]
source [file join $::app_sim_shared::library sat.tcl                ]
source [file join $::app_sim_shared::library security_model.tcl     ]
source [file join $::app_sim_shared::library service.tcl            ]
source [file join $::app_sim_shared::library sigevent.tcl           ]
source [file join $::app_sim_shared::library strategy.tcl           ]
source [file join $::app_sim_shared::library tactic.tcl             ]
source [file join $::app_sim_shared::library tactic_aaaa.tcl        ]
source [file join $::app_sim_shared::library tactic_assign.tcl      ]
source [file join $::app_sim_shared::library tactic_attroe.tcl      ]
source [file join $::app_sim_shared::library tactic_broadcast.tcl   ]
source [file join $::app_sim_shared::library tactic_curse.tcl       ]
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
source [file join $::app_sim_shared::library tactic_spend.tcl       ]
source [file join $::app_sim_shared::library tactic_stance.tcl      ]
source [file join $::app_sim_shared::library tactic_support.tcl     ]
source [file join $::app_sim_shared::library tactic_withdraw.tcl    ]
source [file join $::app_sim_shared::library unit.tcl               ]
source [file join $::app_sim_shared::library view.tcl               ]
source [file join $::app_sim_shared::library vrel.tcl               ]

