#-----------------------------------------------------------------------
# TITLE:
#   gtifreader.tcl
#
# AUTHOR:
#   Dave Hanks
#
# DESCRIPTION:
#       Mars: Geo tiff reading stubs if no C++ code is loaded
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Exported commands

namespace eval ::marsgui:: {
    namespace export gtifreader
}

if {[llength [info commands ::marsgui::gtifreader]] == 0} {

snit::type ::marsgui::gtifreader {

    constructor {args} {
        error "GeoTIFF library not loaded, cannot instantiate gtifreader"
    }
}

}

