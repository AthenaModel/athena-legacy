#-----------------------------------------------------------------------
# TITLE:
#	app_version.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Athena: app(version) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_version:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the athena_version(n) package

package provide app_version 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Active Tcl
package require snit

# Athena Packages
package require marsutil
package require athlib

namespace import ::marsutil::* 
namespace import ::marsutil::*
namespace import ::athlib::*

#-----------------------------------------------------------------------
# Load app(version) submodules

source [file join $::app_version::library app.tcl]










