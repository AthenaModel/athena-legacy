#-----------------------------------------------------------------------
# TITLE:
#    workdir.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Minerva Working Directory Access
#
#    This object is responsible for providing access to
#    the Minerva working directory tree, which resides at
#    
#      ~/.minerva/<version>/
#
#    where <version> is the current version of Minerva.
#    Within this directory, "workdir init" will create the following
#    directories:
#
#        log/         For application logs
#        rdb/         For the RDB file(s)
#
#    Other directories are TBD.
#
#-----------------------------------------------------------------------

namespace eval ::minlib:: {
    namespace export workdir
}

#-----------------------------------------------------------------------
# workdir

snit::type ::minlib::workdir {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Instance variables

    typevariable workdir ""   ;# The absolute path of the working 
                               # directory, ~/.minerva/<version>/


    #-------------------------------------------------------------------
    # Public Methods

    # init
    #
    # Initializes workdir, creating all directories as needed.
    #
    # Returns the working directory name.

    typemethod init {} {
        if {$workdir ne ""} {
            # Already initialized
            return
        }

        # FIRST, get the absolute path of the working directory
        set workdir [file normalize ~/.minerva/[version]]

        # NEXT, create it, if it doesn't exist.
        file mkdir $workdir

        # NEXT, create the log, checkpoint, and scripts directories.
        file mkdir [file join $workdir log]
        file mkdir [file join $workdir rdb]

        # NEXT, return the local directory
        return $workdir
    }

    # join args
    #
    # Called with no arguments, returns the working directory.  Any arguments
    # are joined to the working directory using [file join].

    typemethod join {args} {
        eval file join [list $workdir] $args
    }
}







