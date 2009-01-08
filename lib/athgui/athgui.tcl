#-----------------------------------------------------------------------
# TITLE:
#    athgui.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: athgui(n) main package
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# External Package Dependencies

package require snit
package require sqlite3
package require pixane
package require tablelist

#-----------------------------------------------------------------------
# Internal Package Dependencies

package require marsutil
package require marsgui
package require athlib

#-----------------------------------------------------------------------
# Package Definition

package provide athgui 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::athgui:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 
    namespace import ::marsgui::*
    namespace import ::athlib::*
}

#-----------------------------------------------------------------------
# Load athgui(n) submodules

source [file join $::athgui::library icons.tcl        ]
source [file join $::athgui::library mapcanvas.tcl    ]
source [file join $::athgui::library tablebrowser.tcl ]
source [file join $::athgui::library messagebox.tcl   ]





