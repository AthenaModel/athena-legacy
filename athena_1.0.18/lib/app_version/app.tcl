#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_version(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_version
#        app init $argv
#
#    This program queries and sets the ~/athena symlink, which links to
#    a specific version of Athena in ~/athena_pkgs.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv         Command line arguments
    #
    # This the main program.

    typemethod init {argv} {
        # FIRST, if there are no arguments then list available versions.
        if {[llength $argv] == 0} {
            ListVersions
            return
        }

        # NEXT, show usage if there are too many arguments.
        if {[llength $argv] != 1} {
            ShowUsage
            exit 1
        }

        # NEXT, try to link the requested version
        set version [lindex $argv 0]
        if {[catch {verman set $version} result]} {
            puts $result
            exit 1
        }

        # NEXT, print new version
        puts "Athena Version: [verman current]"
        
    }

    #-----------------------------------------------------------------------
    # Utility Routines

    # ShowUsage
    #
    # Display command line syntax.

    proc ShowUsage {} {
        puts {Usage: athena version [x.y.z]

With no arguments, queries the current version and lists all available
versions.  If a version number is specified, symlinks that version to
$HOME/athena.  See athena_version(1) for more information.}
    }

    # ListVersions
    #
    # Lists the current version and the available versions.

    proc ListVersions {} {
        puts "Athena Version: [verman current] (~/athena -> [verman dirname [verman current]])"

        puts "\nAvailable Versions:"

        puts -nonewline "    "

        set versions [verman list]

        if {[llength $versions] == 0} {
            puts "none"
        } else {
            puts [join $versions "\n    "]
        }
    }
}












