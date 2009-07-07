#-----------------------------------------------------------------------
# TITLE:
#    appdir.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Directory Access
#
#    This object is responsible for creating and providing access to
#    the Athena directory tree.  It assumes that the toplevel script
#    being executed is in either athena/bin or athena/tools/bin.
#
#    appdir is a singleton.
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export appdir
}

#-----------------------------------------------------------------------
# appdir

snit::type ::projectlib::appdir {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type variables

    typevariable appdir ""   ;# The absolute path of the Athena directory.


    #-------------------------------------------------------------------
    # Public Methods

    # init
    #
    # Initializes appdir.  Gets the full path name of the top level
    # script, and removes either /tools/bin or /bin from the end to 
    # get the Athena directory name.
    #
    # Returns the Athena directory name.

    typemethod init {} {
        global argv0

        # FIRST, if appdir is already set, just return.
        if {$appdir ne ""} {
            return
        }

        # FIRST, get the script directory
        set bindir [file normalize [file dirname $argv0]]

        # NEXT, if we're running in a starpack, the bindir
        # is deep within the starpack.  Find the bin directory
        # containing the starpack.
        if {[string match "*/application/bin" $bindir]} {
            # FIRST, strip off the last bin
            set bindir [file dirname $bindir]

            # NEXT, work up to the containing bin directory
            while {$bindir ne ""} {
                if {[file tail $bindir] eq "bin"} {
                    break
                }

                set bindir [file dirname $bindir]
            }

            if {$bindir eq ""} {
                set argv0 [file normalize $argv0]
                error "Can't determine Athena directory (argv0 is \"$argv0\")"
            }

            # NEXT, this might be bin or tools/bin; either is OK.
        }

        # NEXT, Determine which case we're in!
        if {[string match "*/tools/bin" $bindir]} {
            # Development: dev tool in athena/tools/bin.
            set appdir [file dirname [file dirname $bindir]]
        } elseif {[string match "*/bin" $bindir]} {
            # Development: Normal app in athena/bin
            set appdir [file dirname $bindir]
        } else {
            set appdir ""

            while {$bindir ne "/"} {
                if {[string match "*/athena" $bindir]} {
                    set appdir $bindir
                    break
                }

                set bindir [file dirname $bindir]
            }

            if {$appdir eq ""} {
                set argv0 [file normalize $argv0]
                error "Can't determine Athena directory (argv0 is \"$argv0\")"
            }
        }

        # NEXT, ensure that required subdirectories exist.
        # TBD: None yet

        # NEXT, return the athena directory
        return $appdir
    }

    # join args
    #
    # Called with no arguments, returns the athena directory.  Any arguments
    # are joined to the athena directory using [file join].

    typemethod join {args} {
        eval file join [list $appdir] $args
    }
}









