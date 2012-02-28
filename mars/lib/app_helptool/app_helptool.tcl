#-----------------------------------------------------------------------
# TITLE:
#	app_helptool.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: app_helptool(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_helptool:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_helptool(n) package

package provide app_helptool 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Load Tk and Img, and withdraw the main window
package require Tk 8.5
package require Img

wm withdraw .

# From Tcllib
package require snit

# Mars Packages
package require marsutil

namespace import ::marsutil::*


#-----------------------------------------------------------------------
# Load app_helptool(n) submodules

source [file join $::app_helptool::library app.tcl   ]
source [file join $::app_helptool::library macro.tcl ]




