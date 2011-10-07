#-----------------------------------------------------------------------
# TITLE:
#    version.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Version Command
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectlib:: {
    namespace export     \
        version

    variable version ""
}

#-------------------------------------------------------------------
# Public Commands

# version
#
# Returns the version number of the software, as read from 
# version.txt.

proc ::projectlib::version {} {
    variable library
    variable version

    # FIRST, if we've already set version just return it.
    if {$version ne ""} {
        return $version
    }

    # NEXT, set version to a stopgap value
    set version x.y.z

    # NEXT, try to read it from version.txt.
    catch {
        set file [file join $library version.txt]
        set text [readfile $file]
        set version [string trim $text]
    } 

    return $version
}


