#-----------------------------------------------------------------------
# TITLE:
#    projectgui.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: projectgui(n) main package
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

source [file join $::projectgui::library icons.tcl           ]
source [file join $::projectgui::library zulufield.tcl       ]
source [file join $::projectgui::library calpatternfield.tcl ]
source [file join $::projectgui::library entitytree.tcl      ]
source [file join $::projectgui::library linktree.tcl        ]
source [file join $::projectgui::library mybrowser.tcl       ]
source [file join $::projectgui::library textwin.tcl         ]









