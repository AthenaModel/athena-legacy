#-----------------------------------------------------------------------
# TITLE:
#    pkgModules.tcl
#
# PROJECT:
#    athena-sim - Athena Regional Stability Simulation
#
# DESCRIPTION:
#    projectgui(n) package modules file
#
#    Generated by Kite.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Package Definition

# -kite-provide-start  DO NOT EDIT THIS BLOCK BY HAND
package provide projectgui 6.3.1a0
# -kite-provide-end


#-----------------------------------------------------------------------
# Required Packages

# Add 'package require' statements for this package's external 
# dependencies to the following block.  Kite will update the versions 
# numbers automatically as they change in project.kite.

# -kite-require-start ADD EXTERNAL DEPENDENCIES
package require snit 2.3
package require Img 1.4.1
package require Tkhtml 3.0
package require -exact marsutil 3.0.2a0
package require projectlib
package require -exact marsgui 3.0.2a0
# -kite-require-end

#-----------------------------------------------------------------------
# Namespace definition

namespace import ::marsgui::*

namespace eval ::projectgui:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Load projectgui(n) submodules

source [file join $::projectgui::library toolbutton.tcl      ]
source [file join $::projectgui::library beanbrowser.tcl     ]
source [file join $::projectgui::library enumbutton.tcl      ]
source [file join $::projectgui::library goferfield.tcl      ]
source [file join $::projectgui::library icons.tcl           ]
source [file join $::projectgui::library linktree.tcl        ]
source [file join $::projectgui::library listbuttonfield.tcl ]
source [file join $::projectgui::library mybrowser.tcl       ]
source [file join $::projectgui::library modaltextwin.tcl    ]
source [file join $::projectgui::library textwin.tcl         ]
source [file join $::projectgui::library rolemapfield.tcl    ]
source [file join $::projectgui::library sorter.tcl          ]
source [file join $::projectgui::library sorterbin.tcl       ]
source [file join $::projectgui::library wizman.tcl          ]
