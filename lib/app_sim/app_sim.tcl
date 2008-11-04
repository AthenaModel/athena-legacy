#-----------------------------------------------------------------------
# TITLE:
#	app_sim.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Minerva: app_sim(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_sim:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_sim(n) package

package provide app_sim 1.0

#-------------------------------------------------------------------
# Require packages

# From ActiveTcl
package require snit     2.2
package require sqlite3  3.5

# From Mars
package require marsutil
package require marsgui

# From Minerva

package require minlib
package require mingui
        
namespace import ::marsutil::* 
namespace import ::minlib::*
namespace import ::mingui::*

#-----------------------------------------------------------------------
# Load app_sim(n) submodules

source [file join $::app_sim::library app.tcl]

