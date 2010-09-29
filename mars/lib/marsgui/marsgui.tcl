#-------------------------------------------------------------------------
# TITLE:
#       marsgui.tcl
#
# AUTHOR:
#       William H. Duquette
#
# DESCRIPTION:
#       Mars marsgui(n) Package: Generic GUI Code
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Package Dependencies

package require snit     2.2
package require marsutil
   
package require Tk 8.5
package require BWidget  1.8
package require treectrl 2.2.6
package require tablelist 4.11.2
package require Plotchart 1.6
package require Tktable 2.10

#-----------------------------------------------------------------------
# Package Definition

package provide marsgui 1.0

#-----------------------------------------------------------------------
# Namespace and packages


namespace eval ::marsgui:: {
    variable library [file dirname [info script]]
    
    # Make marsutil calls visible in marsgui
    namespace import ::marsutil::*
}

source [file join $::marsgui::library global.tcl         ]
source [file join $::marsgui::library mkicon.tcl         ]
source [file join $::marsgui::library marsicons.tcl      ]
source [file join $::marsgui::library gradient.tcl       ]
source [file join $::marsgui::library cli.tcl            ]
source [file join $::marsgui::library cmdbrowser.tcl     ]
source [file join $::marsgui::library winbrowser.tcl     ]
source [file join $::marsgui::library modeditor.tcl      ]
source [file join $::marsgui::library debugger.tcl       ]
source [file join $::marsgui::library texteditor.tcl     ]
source [file join $::marsgui::library texteditorwin.tcl  ]
source [file join $::marsgui::library zuluspinbox.tcl    ]
source [file join $::marsgui::library menubox.tcl        ]
source [file join $::marsgui::library messageline.tcl    ]
source [file join $::marsgui::library messagebox.tcl     ]
source [file join $::marsgui::library filter.tcl         ]
source [file join $::marsgui::library finder.tcl         ]
source [file join $::marsgui::library logdisplay.tcl     ]
source [file join $::marsgui::library commandentry.tcl   ]
source [file join $::marsgui::library loglist.tcl        ]
source [file join $::marsgui::library subwin.tcl         ]
source [file join $::marsgui::library paner.tcl          ]
source [file join $::marsgui::library rotext.tcl         ]
source [file join $::marsgui::library datagrid.tcl       ]
source [file join $::marsgui::library scrollinglog.tcl   ]
source [file join $::marsgui::library reportbrowser.tcl  ]
source [file join $::marsgui::library reportviewer.tcl   ]
source [file join $::marsgui::library reportviewerwin.tcl]
source [file join $::marsgui::library rb_bintree.tcl     ]
source [file join $::marsgui::library sqlbrowser.tcl     ]
source [file join $::marsgui::library querybrowser.tcl   ]
source [file join $::marsgui::library isearch.tcl        ]
source [file join $::marsgui::library timeline.tcl       ]
source [file join $::marsgui::library hbarchart.tcl      ]
source [file join $::marsgui::library stripchart.tcl     ]
source [file join $::marsgui::library pwin.tcl           ]
source [file join $::marsgui::library pwinman.tcl        ]
source [file join $::marsgui::library cmsheet.tcl        ]


