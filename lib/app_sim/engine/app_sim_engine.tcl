#-----------------------------------------------------------------------
# FILE: app_sim_engine.tcl
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   app_sim_engine(n) -- Master package for athena(1) Engine thread.
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::app_sim_engine:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the app_sim_engine(n) package

package provide app_sim_engine 1.0

#-------------------------------------------------------------------
# Require packages

# From ActiveTclEE
package require snit 2.2

# From Mars
package require marsutil
package require simlib
package require projectlib

namespace import ::marsutil::* ::simlib::* ::projectlib::*

#-----------------------------------------------------------------------
# Load app_sim_engine(n) modules

# TBD: We don't need main until this is really a thread
# source [file join $::app_sim_engine::library app.tcl]

