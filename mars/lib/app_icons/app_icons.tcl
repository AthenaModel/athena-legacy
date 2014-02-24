#-----------------------------------------------------------------------
# TITLE:
#	app_icons.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: app_icons(n) package
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_icons:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_icons(n) package

package provide app_icons 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# From Tcllib
package require snit

# Mars Packages
package require marsutil
package require marsgui

namespace import ::marsutil::*
namespace import ::marsgui::*

#-----------------------------------------------------------------------
# Load app_icons(n) submodules

source [file join $::app_icons::library app.tcl   ]




