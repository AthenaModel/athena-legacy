#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mars_sequence(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_sequence
#        app init $argv
#
#    This program is a document processor for sequence(5) sequence
#    diagram format.  It produces GIF images from sequence(5) input
#    using sequence(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Variables

    # Destination directory
    typevariable destdir "."

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv         Command line arguments
    #
    # This the main program.

    typemethod init {argv} {
        # FIRST, process the arguments
        while {[string match "-*" [lindex $argv 0]]} {
            set opt [lshift argv]
            
            switch -exact -- $opt {
                -destdir {
                    set val [lshift argv]
                    if {![file exists $val] && [file isdirectory $val]} {
                        puts stderr "Error: '$val' is not a valid directory."
                        exit 1
                    }
                    set destdir $val
                }
                default {
                    puts stderr "Unknown option: '$opt'."

                    ShowUsage
                    exit 1
                }
            }
        }

        if {[llength $argv] == 0} {
            ShowUsage
            exit 1
        }

        foreach infile $argv {
            set outtail [file tail [file root $infile]].gif
            set outfile [file join $destdir $outtail]

            if {[catch {
                set input [readfile $infile]
                sequence renderas $outfile $input
            } result]} {
                puts stderr $result
                exit 1
            }

            puts $outfile
        }
    }

    #-------------------------------------------------------------------
    # Utility Routines

    # ShowUsage
    #
    # Display command line syntax.

    proc ShowUsage {} {
        puts {Usage: mars_sequence [options...] file.seq [file.seq....]

Options:
    -destdir <path>            Destination directory.

For each file.seq on the command line,, produces file.gif in the 
destination directory, which defaults to the current working directory.
}
    }
}




