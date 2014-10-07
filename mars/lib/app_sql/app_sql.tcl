#-----------------------------------------------------------------------
# TITLE:
#	app_sql.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       JNEM: app_sql(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_sql:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_sql(n) package

package provide app_sql 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Active Tcl
package require sqlite3

package require marsutil
package require marsgui

namespace import ::marsutil::*
namespace import ::marsgui::*

#-----------------------------------------------------------------------
# Load app_sql(n) submodules

source [file join $::app_sql::library app.tcl]










