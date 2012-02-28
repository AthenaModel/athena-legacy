#-----------------------------------------------------------------------
# TITLE:
#	app_man.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       JNEM: app_man(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_man:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_man(n) package

package provide app_man 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# From Tcllib
package require snit

# Mars Packages
package require marsutil

namespace import ::marsutil::*

#-----------------------------------------------------------------------
# Load app_man(n) submodules

source [file join $::app_man::library app.tcl   ]
