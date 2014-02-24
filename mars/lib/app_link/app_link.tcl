#-----------------------------------------------------------------------
# TITLE:
#	app_link.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       JNEM: app_link(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_link:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_link(n) package

package provide app_link 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# From Tcllib
package require snit

# Mars Packages
package require marsutil

namespace import ::marsutil::*

#-----------------------------------------------------------------------
# Load app_link(n) submodules

source [file join $::app_link::library app.tcl   ]


