#-----------------------------------------------------------------------
# TITLE:
#    workdir.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Working Directory Access
#
#    This object is responsible for providing access to
#    the Athena working directory tree, which resides at
#    
#      [os workdir]/<pid>/
#
#    where <pid> is the process ID of the running instance of Athena.
#    Within this directory, "workdir init" will create the following
#    directories:
#
#        log/         For application logs
#        rdb/         For the RDB file(s)
#
# In applications which use the Tcl event loop, the working directory
# will be "touched" once a minute, so that it's easy for other Athena
# applications to determine which working directories are still in use
# and which are old.
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export workdir
}

#-----------------------------------------------------------------------
# workdir

snit::type ::projectlib::workdir {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent toucher   ;# timeout(n)

    #-------------------------------------------------------------------
    # Type Variables

    # The interval in milliseconds between touches of the working
    # directory.
    typevariable touchInterval 10000   ;# 10 seconds
    
    # Working directories with timestamps older than this number of
    # seconds are considered "inactive" and eligible to be purged.

    typevariable inactiveAge 600

    # The absolute path of the working directory.
    typevariable workdir ""


    #-------------------------------------------------------------------
    # Public Methods

    # init
    #
    # Initializes workdir, creating all directories as needed and 
    # creating the toucher.  Returns the working directory name.

    typemethod init {} {
        if {$workdir ne ""} {
            # Already initialized
            return
        }

        # FIRST, get the absolute path of the working directory
        set workdir [file join [os workdir] [pid]]

        # NEXT, create it, if it doesn't exist.
        file mkdir $workdir

        # NEXT, create the log, checkpoint, and scripts directories.
        file mkdir [file join $workdir log]
        file mkdir [file join $workdir rdb]

        # NEXT, create and schedule the toucher
        set toucher [::marsutil::timeout ${type}::toucher  \
                         -interval   $touchInterval        \
                         -repetition yes                   \
                         -command    [mytypemethod Touch]]

        $toucher schedule

        # NEXT, return the local directory
        return $workdir
    }

    # join args
    #
    # Called with no arguments, returns the working directory.  
    # Any arguments are joined to the working directory using [file join].

    typemethod join {args} {
        require {$workdir ne ""} "workdir(n): Not initialized"
        eval file join [list $workdir] $args
    }

    # purge hours
    #
    # hours        An age, in hours.
    #
    # Purges inactive working directories named by PIDs that are older
    # than the specified age.  A working directory is inactive if its 
    # timestamp is older than 10 minutes. 
    #
    # Pass an age of 0 to purge all inactive working directories.

    typemethod purge {hours} {
        # FIRST, get the time now and the age in seconds
        set now [clock seconds]
        set inactiveLimit [expr {$now - $inactiveAge}]

        set purgeLimit [expr {$now - $hours * 3600}]

        # NEXT, loop over the entries in [os workdir], and delete
        # the old working directories.
        foreach name [glob -nocomplain [os workdir]/*] {
            # FIRST, get the timestamp.
            set timestamp [file mtime $name]

            # NEXT, Skip the file if:
            #
            # * It's our own working directory
            # * It's not a directory
            # * It doesn't look like a pid
            # * It's not inactive
            if {$name eq $workdir                      ||
                ![file isdirectory $name]              ||
                ![string is integer [file tail $name]] ||
                $timestamp > $inactiveLimit
            } {
                continue
            }

            # NEXT, is it older?
            if {$timestamp < $purgeLimit} {
                if {[catch {
                    file delete -force -- $name
                } result]} {
                    puts "Error, could not purge old working directory:"
                    puts "--> $name"
                    puts "$result"
                }
            }
        }
    }

    # cleanup
    #
    # Removes the working directory and cancels the toucher.

    typemethod cleanup {} {
        require {$workdir ne ""} "workdir(n): Not initialized"

        $toucher cancel

        file delete -force -- $workdir

        set workdir ""
    }

    #-------------------------------------------------------------------
    # Private Type Methods

    # Touch
    #
    # Touches the working directory with the current time.

    typemethod Touch {} {
        file mtime $workdir [clock seconds]
    }
}











