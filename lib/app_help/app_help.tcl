#-----------------------------------------------------------------------
# TITLE:
#	app_help.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: app_help(n) loader
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_help:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_help(n) package

package provide app_help 1.0

#-----------------------------------------------------------------------
# Require infrastructure packages

# Load Tk and Img, and withdraw the main window
package require Tk 8.5
package require Img

wm withdraw .

# From Tcllib
package require snit

# Mars Packages
package require marsutil

namespace import ::marsutil::*

# Athena Packages

package require projectlib

namespace import ::projectlib::*


#-----------------------------------------------------------------------
# Load app_help(n) submodules

source [file join $::app_help::library app.tcl   ]
source [file join $::app_help::library macro.tcl ]
source [file join $::app_help::library object.tcl]




