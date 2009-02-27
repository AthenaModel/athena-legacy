#-----------------------------------------------------------------------
# TITLE:
#	app_import.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Athena: app(import) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_import:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the athena_import(n) package

package provide app_import 1.0

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
# Load app(import) submodules

source [file join $::app_import::library app.tcl]













