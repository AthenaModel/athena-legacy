#-----------------------------------------------------------------------
# TITLE:
#    projinfo.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Project Info Manager
#
#    This object is responsible for querying and managing Athena 
#    project info: the current version and build numbers.  This data
#    is stored in lib/projectlib in the projinfo.txt file.
#
#    This module allows the contents of this file to be set and queried.
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export \
        projinfo \
        version
}

#-----------------------------------------------------------------------
# projinfo

snit::type ::projectlib::projinfo {
    # Make it a singleton
    pragma -hasinstances no -hastypedestroy no

    #-------------------------------------------------------------------
    # Type variables

    # info - the project info array
    #
    #   version  - The version number, x.y.z
    #   build    - The build number, Bn or Rn
    #
    # If values are "", the data has not yet been loaded.

    typevariable info -array {
        version ""
        build   ""
    }

    #-------------------------------------------------------------------
    # Public Type Methods

    # version ?number?
    #
    # number  - A new version number
    #
    # Returns the version number, x.y.z, optionally setting it first.

    typemethod version {{number ""}} {
        # FIRST, initialize from disk, if needed.
        if {$info(version) eq ""} {
            $type LoadProjectInfo
        }

        # NEXT, set if needed.
        if {$number ne ""} {
            require {[regexp {^\d+\.\d+\.\d+$} $number]} \
                "Invalid version number: \"$number\""

            set info(version) $number
        }

        return $info(version)
    }

    # build
    #
    # Returns the build number, Bn or Rn.

    typemethod build {{number ""}} {
        if {$info(build) eq ""} {
            $type LoadProjectInfo
        }

        # NEXT, set if needed.
        if {$number ne ""} {
            require {[regexp {^(B|R)\d+$} $number]} \
                "Invalid build number: \"$number\""

            set info(build) $number
        }

        return $info(build)
    }

    # filename
    #
    # The name of the project info file.

    typemethod filename {} {
        return [file join $::projectlib::library projinfo.txt]
    }

    # save
    #
    # Saves the current info to the disk file.

    typemethod save {} {
        set f [open [$type filename] w]
        try {
            puts $f [array get info]
        } finally {
            close $f
        }

        return
    }

    # clear
    #
    # Clears project data back to place holders.  This is mostly used
    # for test purposes.

    typemethod clear {} {
        set info(version) "x.y.z"
        set info(build)   "Bn"

        return
    }

    #-------------------------------------------------------------------
    # Private Type Methods
    
    # LoadProjectInfo
    #
    # Retrieves the version and build numbers from version.txt.

    typemethod LoadProjectInfo {} {
        # FIRST, set variables to a stopgap value
        $type clear

        # NEXT, try to read it from the project file.
        catch {
            set file [$type filename]
            set dict [readfile $file]

            set info(version) [dict get $dict version]
            set info(build)   [dict get $dict build]
        } 
    }
}

#-------------------------------------------------------------------
# For backwards compatibility

# version
#
# Returns the Athena version.

proc ::projectlib::version {} {
    return [projinfo version]
}










