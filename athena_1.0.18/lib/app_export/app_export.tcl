#-----------------------------------------------------------------------
# TITLE:
#	app_export.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Athena: app(export) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_export:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the athena_export(n) package

package provide app_export 1.0

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
# Load app(export) submodules

source [file join $::app_export::library app.tcl]












