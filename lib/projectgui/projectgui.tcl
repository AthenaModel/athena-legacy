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
package require sqlite3
package require pixane
package require tablelist
package require treectrl  2.2.6


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
source [file join $::projectgui::library mapcanvas.tcl       ]
source [file join $::projectgui::library tablebrowser.tcl    ]
source [file join $::projectgui::library messagebox.tcl      ]
source [file join $::projectgui::library enumfield.tcl       ]
source [file join $::projectgui::library multifield.tcl      ]
source [file join $::projectgui::library textfield.tcl       ]
source [file join $::projectgui::library zulufield.tcl       ]
source [file join $::projectgui::library reportviewer.tcl    ]
source [file join $::projectgui::library reportviewerwin.tcl ]
source [file join $::projectgui::library rb_bintree.tcl      ]
source [file join $::projectgui::library reportbrowser.tcl   ]






