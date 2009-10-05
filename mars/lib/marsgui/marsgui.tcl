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

#-----------------------------------------------------------------------
# Package Definition

package provide marsgui 1.0

#-----------------------------------------------------------------------
# Namespace and packages


namespace eval ::marsgui:: {
    variable library [file dirname [info script]]
}

source [file join $::marsgui::library global.tcl]
source [file join $::marsgui::library mkicon.tcl]
source [file join $::marsgui::library gradient.tcl]
source [file join $::marsgui::library cli.tcl]
source [file join $::marsgui::library cmdbrowser.tcl]
source [file join $::marsgui::library winbrowser.tcl]
source [file join $::marsgui::library debugger.tcl]
source [file join $::marsgui::library texteditor.tcl]
source [file join $::marsgui::library zuluspinbox.tcl]
source [file join $::marsgui::library messageline.tcl]
source [file join $::marsgui::library filter.tcl]
source [file join $::marsgui::library finder.tcl]
source [file join $::marsgui::library logdisplay.tcl]
source [file join $::marsgui::library commandentry.tcl]
source [file join $::marsgui::library loglist.tcl]
source [file join $::marsgui::library subwin.tcl]
source [file join $::marsgui::library paner.tcl]
source [file join $::marsgui::library rotext.tcl]
source [file join $::marsgui::library datagrid.tcl]
source [file join $::marsgui::library scrollinglog.tcl]


