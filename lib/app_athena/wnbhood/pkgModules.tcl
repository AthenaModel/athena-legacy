#-----------------------------------------------------------------------
# FILE: pkgModules.
#
#   Package loader.  This file provides the package, requires all
#   other packages upon which this package depends, and sources in
#   all of the package's modules.
#
# PACKAGE:
#   wnbhood(n) -- package for athena(1) nbhood ingestion wizard.
#
# PROJECT:
#   Athena Regional Stability Simulation
#
# AUTHOR:
#   Dave Hanks
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Namespace definition
#
# Because this is an application package, the namespace is mostly
# unused.

namespace eval ::wnbhood:: {
    variable library [file dirname [info script]]
}

#-----------------------------------------------------------------------
# Provide the wnbhood(n) package

package provide wnbhood 1.0

#-----------------------------------------------------------------------
# Load modules

# NEXT, define the remaining modules in alphabetical order.

# Non-GUI modules
source [file join $::wnbhood::library wizard.tcl    ]
source [file join $::wnbhood::library wizdb.tcl     ]

# GUI modules
source [file join $::wnbhood::library wizwin.tcl    ]
source [file join $::wnbhood::library wiznbhood.tcl ]
source [file join $::wnbhood::library nbchooser.tcl ]






