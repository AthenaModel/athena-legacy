#-----------------------------------------------------------------------
# TITLE:
#    os.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena OS-dependence Package
#
#    This module is intended to contain most or all non-GUI 
#    OS-dependent code for the Athena project.  In particular, it 
#    determines locations of directories, use of external tools, and so 
#    forth.
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export os
}

#-----------------------------------------------------------------------
# workdir

snit::type ::projectlib::os {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Variables

    # info: array of cached values
    #
    #   type     - OS type, one of "linux", "win32", or "macosx"
    #   prefsdir - Location of the preferences directory.
    #   workdir  - Location of the working data directory.

    typevariable info -array {
        type     ""
        prefsdir ""
        workdir  ""
    }


    #-------------------------------------------------------------------
    # Public Methods

    # types
    #
    # Returns a list of the valid OS types.

    typemethod types {} {
        return [list linux win32 macosx]
    }

    # type
    # 
    # Returns "linux", "win32", or "macosx".

    typemethod type {} {
        if {$info(type) eq ""} {
            set info(type) [lindex [split [platform::generic] -] 0]
        }

        return $info(type)
    }

    # prefsdir
    #
    # Returns the name of a directory for storing preference data and
    # the like.

    typemethod prefsdir {} {
        if {$info(prefsdir) eq ""} {
            if {[$type type] eq "win32"} {
                set info(prefsdir) \
                    [file normalize [file join $::env(APPDATA) JPL Athena]]
            } else {
                set info(prefsdir) \
                    [file normalize "~/.athena"]
            }
        }

        return $info(prefsdir)
    }

    # workdir
    #
    # Returns the name of a directory for storing working data
    # (e.g., the RDB, logs, etc).

    typemethod workdir {} {
        if {$info(workdir) eq ""} {
            if {[$type type] eq "win32"} {
                set info(workdir) \
                    [file normalize [file join [fileutil::tempdir] JPL Athena]]
            } else {
                set info(workdir) \
                    [file normalize "~/.athena"]
            }
        }

        return $info(workdir)
    }
}











