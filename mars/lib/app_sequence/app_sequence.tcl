#-----------------------------------------------------------------------
# TITLE:
#	app_sequence.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       JNEM: app_sequence(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_sequence:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_sequence(n) package

package provide app_sequence 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# From Tcllib
package require snit

# Mars Packages
package require marsutil

namespace import ::marsutil::*

#-----------------------------------------------------------------------
# Load app_sequence(n) submodules

source [file join $::app_sequence::library app.tcl   ]

