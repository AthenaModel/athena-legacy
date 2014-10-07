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
   
package require Tk 8.6
package require Img
package require BWidget  1.9
package require treectrl 2.2.10
package require tablelist 5.11
package require Tktable 2.10
package require Tkhtml 3.0

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
source [file join $::marsgui::library osgui.tcl          ]
source [file join $::marsgui::library mkicon.tcl         ]
source [file join $::marsgui::library marsicons.tcl      ]
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
source [file join $::marsgui::library databrowser.tcl    ]
source [file join $::marsgui::library datagrid.tcl       ]
source [file join $::marsgui::library scrollinglog.tcl   ]
source [file join $::marsgui::library reportbrowser.tcl  ]
source [file join $::marsgui::library reportviewer.tcl   ]
source [file join $::marsgui::library reportviewerwin.tcl]
source [file join $::marsgui::library rb_bintree.tcl     ]
source [file join $::marsgui::library sqlbrowser.tcl     ]
source [file join $::marsgui::library querybrowser.tcl   ]
source [file join $::marsgui::library isearch.tcl        ]
source [file join $::marsgui::library hbarchart.tcl      ]
source [file join $::marsgui::library stripchart.tcl     ]
source [file join $::marsgui::library pwin.tcl           ]
source [file join $::marsgui::library pwinman.tcl        ]
source [file join $::marsgui::library cmsheet.tcl        ]
source [file join $::marsgui::library colorfield.tcl     ]
source [file join $::marsgui::library dispfield.tcl      ]
source [file join $::marsgui::library enumfield.tcl      ]
source [file join $::marsgui::library keyfield.tcl       ]
source [file join $::marsgui::library listfield.tcl      ]
source [file join $::marsgui::library multifield.tcl     ]
source [file join $::marsgui::library newkeyfield.tcl    ]
source [file join $::marsgui::library rangefield.tcl     ]
source [file join $::marsgui::library textfield.tcl      ]
source [file join $::marsgui::library form.tcl           ]
source [file join $::marsgui::library mapcanvas.tcl      ]
source [file join $::marsgui::library orderdialog.tcl    ]
source [file join $::marsgui::library zcurvefield.tcl    ]
source [file join $::marsgui::library htmlviewer.tcl     ]
source [file join $::marsgui::library htmlframe.tcl      ]
source [file join $::marsgui::library dynaview.tcl       ]
source [file join $::marsgui::library dynabox.tcl        ]
source [file join $::marsgui::library checkfield.tcl     ]
