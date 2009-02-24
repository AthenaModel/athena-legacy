#-----------------------------------------------------------------------
# TITLE:
#    verman.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Version Manager
#
#    This object is responsible for querying and managing Athena 
#    directory trees.  At run-time, athena(1) requires access only
#    to itself; however, it is possible to have multiple installations
#    Athena side-by-side, and multiple development directories in
#    the development environment, and this tool allows the user to 
#    easily switch between them.
#
#    The general purpose of this object is to query the available 
#    version directories and switch between them.
#
# VERSION DIRECTORIES
#
#    Athena presumes that version x.y.z of Athena is untarred as
#
#        ~/athena_pkgs/athena_x.y.z
#
#    and that the currently active version is indicated by a 
#    symlink
#
#        ~/athena -> ~/athena_pkgs/athena_x.y.z
#
#    The syntax of the version number, "x.y.z", is unconstrained; any
#    string following "athena_" is accepted as a version.  In operations,
#    it will always be the version number as built, but in development
#    it's convenient to be more forgiving.
#
#    NOTE: The version-as-installed, i.e., the version in 
#    "athena_<version>" may be different (especially in development) than
#    the version-as-built (e.g., 4.0.3) or the development branch
#    (e.g., 4.0.x).
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export verman
}

#-----------------------------------------------------------------------
# verman

snit::type ::projectlib::verman {
    # Make it a singleton
    pragma -hasinstances no -hastypedestroy no

    #-------------------------------------------------------------------
    # Type variables

    # None yet

    #-------------------------------------------------------------------
    # Typemethods

    # list
    #
    # Returns a list of the available versions, in no particular order

    typemethod list {} {
        set versions {}

        foreach name [glob -nocomplain ~/athena_pkgs/*] {
            if {![file isdirectory $name]} {
                continue
            }

            if {![catch {$type parse $name} result]} {
                lappend versions $result
            }
        }

        return $versions
    }

    # parse dirname
    #
    # dirname       A Athena version directory, presumably
    #
    # Returns the <version> from ".../athena_<version>".  Throws an
    # error if it can't be done.

    typemethod parse {dirname} {
        set name [file tail $dirname]

        if {[regexp {^athena_(.+)$} $name dummy version]} {
            return $version
        } else {
            error "no embedded Athena version number: $dirname"
        }
    }

    # current
    #
    # Returns the version number of the active version, or "" if none.

    typemethod current {} {
        if {![catch {
            set linkname [file readlink ~/athena]
            set version [$type parse $linkname]
        } result]} {
            return $version
        }

        return ""
    }

    # dirname version
    #
    # version    Version number of an installed Athena version
    #
    # Returns the full path name of the specified version

    typemethod dirname {version} {
        return [file normalize ~/athena_pkgs/athena_$version]
    }

    # set version
    #
    # version    Version number of an installed Athena version
    #
    # Links ~/athena to ~/athena_pkgs/athena_<version>

    typemethod set {version} {
        # FIRST, does the version exist?
        set dirname ~/athena_pkgs/athena_$version

        if {![file exists $dirname] ||
            ![file isdirectory $dirname]} {
            error "no such version installed: $version"
        }

        # NEXT, delete the old link and create the new link
        file delete -- ~/athena
        file link -symbolic ~/athena $dirname 
    }

}









