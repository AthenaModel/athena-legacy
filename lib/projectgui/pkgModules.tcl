#-----------------------------------------------------------------------
# TITLE:
#    pkgModules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: projectgui(n) package loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# External Package Dependencies

package require snit
package require Img


#-----------------------------------------------------------------------
# Internal Package Dependencies

package require marsutil
package require marsgui
package require projectlib
package require Tkhtml 3.0

#-----------------------------------------------------------------------
# Package Definition

package provide projectgui 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::projectgui:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 
    namespace import ::marsgui::*
    namespace import ::projectlib::*
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