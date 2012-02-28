#-----------------------------------------------------------------------
# TITLE:
#	app_helpbrowser.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: app_helpbrowser(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_helpbrowser:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_helpbrowser(n) package

package provide app_helpbrowser 1.0

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
# Load app_helpbrowser(n) submodules

source [file join $::app_helpbrowser::library app.tcl   ]



