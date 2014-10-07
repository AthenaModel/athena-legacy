#-----------------------------------------------------------------------
# TITLE:
#	app_replace.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       JNEM: app_replace(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_replace:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_replace(n) package

package provide app_replace 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Active Tcl
package require snit

# Mars Packages
package require marsutil

namespace import ::marsutil::*

#-----------------------------------------------------------------------
# Load app_replace(n) submodules

source [file join $::app_replace::library app.tcl]









