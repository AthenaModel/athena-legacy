#-----------------------------------------------------------------------
# TITLE:
#	app_doc.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       JNEM: app_doc(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_doc:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_doc(n) package

package provide app_doc 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# From Tcllib
package require snit

# Mars Packages
package require marsutil

namespace import ::marsutil::*

#-----------------------------------------------------------------------
# Load app_doc(n) submodules

source [file join $::app_doc::library app.tcl   ]

