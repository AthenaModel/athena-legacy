#-----------------------------------------------------------------------
# TITLE:
#	app_projinfo.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Athena: app_projinfo(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_projinfo:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_projinfo(n) package

package provide app_projinfo 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Active Tcl
package require snit

# Athena Packages
package require marsutil
package require projectlib

namespace import ::marsutil::* 
namespace import ::projectlib::*

#-----------------------------------------------------------------------
# Load app(version) submodules

source [file join $::app_projinfo::library app.tcl]











