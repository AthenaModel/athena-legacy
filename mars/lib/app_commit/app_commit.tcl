#-----------------------------------------------------------------------
# TITLE:
#	app_commit.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       JNEM: app_commit(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_commit:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_commit(n) package

package provide app_commit 1.0

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
# Load app_commit(n) submodules

source [file join $::app_commit::library app.tcl   ]



