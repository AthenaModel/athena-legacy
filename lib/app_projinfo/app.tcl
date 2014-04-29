#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_projinfo(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_projinfo
#        app init $argv
#
#    This program manages the content of the lib/projectlib/projinfo.txt
#    project info file via the projinfo(n) module.
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
        # FIRST, process the subcommand.
        set cmd [lshift argv]

        switch -exact -- $cmd {
            ""   -
            help {
                ShowUsage
                exit 0
            }

            version {
                puts [projinfo version]
                exit 0
            }

            versionfull {
                puts "[projinfo version]-[projinfo build]"
                exit 0
            }

            build {
                puts [projinfo build]
                exit 0
            }

            set {
                $type SetValues $argv
            }

            default {
                puts "Error, unknown subcommand: \"$cmd\""
                ShowUsage
                exit 1
            }
        }

        exit 0
    }

    # SetValues argv
    #
    # argv - The options and values from the command line.
    #
    # Sets values and optionally commits projinfo.txt to disk.

    typemethod SetValues {argv} {
        # FIRST, get the options
        set opts(-version) [projinfo version]
        set opts(-build)   [projinfo build]
        set opts(-commit)  0

        while {[llength $argv] > 0} {
            set opt [lshift argv]

            switch -exact -- $opt {
                -version -
                -build   {
                    set opts($opt) [lshift argv]
                }
                -commit {
                    set opts(-commit) 1
                }
            }
        }

        # NEXT, set the the values
        if {$opts(-version) eq ""} {
            puts "Error, -version is empty."
            exit 1
        }

        if {[catch {projinfo version $opts(-version)} result]} {
            puts "Error, $result"
            exit 1
        }

        if {$opts(-build) eq ""} {
            puts "Error, -build is empty."
            exit 1
        }

        if {[catch {projinfo build $opts(-build)} result]} {
            puts "Error, $result"
            exit 1
        }

        # NEXT, save them to disk.
        projinfo save

        puts "Saved -version $opts(-version) -build $opts(-build)"

        # NEXT, commit them if desired.
        if {$opts(-commit)} {
            $type CommitChange
        }

        return
    }

    # CommitChange
    #
    # Commits the current contents of projinfo.txt to disk.

    typemethod CommitChange {} {
        set fname [projinfo filename]
        set cmd [list svn commit -m "Saving Athena project version info" \
            $fname]

        set code [catch {
            puts "Calling: $cmd"
            eval exec $cmd
        } result]

        if {$code} {
            puts "Error, $result"
            exit 1
        }

        puts "Committed changes to $fname"
    }

    #-----------------------------------------------------------------------
    # Utility Routines

    # ShowUsage
    #
    # Display command line syntax.

    proc ShowUsage {} {
        puts {Usage: athena_projinfo subcommand ?options?

See athena_projinfo(1) for more information.}
    }

}
