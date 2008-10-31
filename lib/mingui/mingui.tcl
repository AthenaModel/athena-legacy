#-----------------------------------------------------------------------
# TITLE:
#    mingui.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Minerva: mingui(n) main package
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# External Package Dependencies

package require snit
package require sqlite3

#-----------------------------------------------------------------------
# Internal Package Dependencies

package require marsutil
package require marsgui
package require minlib

#-----------------------------------------------------------------------
# Package Definition

package provide mingui 1.0

#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::mingui:: {
    variable library [file dirname [info script]]

    namespace import ::marsutil::* 
    namespace import ::marsgui::*
    namespace import ::minlib::*
}

#-----------------------------------------------------------------------
# Load mingui(n) submodules

source [file join $::mingui::library mapcanvas.tcl]


