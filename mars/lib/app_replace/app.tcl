#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mars_replace(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_replace
#        app init $argv
#
#    This program is a bulk search-and-replace tool.  Given a pair
#    of strings, one to search for and one to replace it with, and
#    a list of files, it will replace all occurrences of the target
#    with the replacement in each of the files.  The original file
#    is renamed "<name>~".
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
        # FIRST, process the command line.
        if {[llength $argv] < 3} {
            ShowUsage
            exit
        }
        
        set target [lindex $argv 0]
        set replacement [lindex $argv 1]
        set files [lrange $argv 2 end]

        # NEXT, Step over the files
        foreach file $files {
            if {[catch {ReplaceString $target $replacement $file} result]} {
                puts "-- Error, $result"
            }
        }
    }

    #-----------------------------------------------------------------------
    # Utility Routines

    # ShowUsage
    #
    # Display command line syntax.

    proc ShowUsage {} {
        puts "Usage: mars_replace target replacement files..."
    }

    proc ReplaceString {target replacement file} {
        # FIRST, read the text from the file
        set f [open $file r]
        set text [read $f]
        close $f

        # NEXT, see whether it contains the string at all.  If not, skip this
        # one.
        if {[string first $target $text] == -1} {
            return
        }

        # TBD: apploader(n), when implemented, should provide a command
        # that returns the actual app name.
        puts "mars_replace: $file"

        # NEXT, backup the file
        set backup "$file~"
        file copy -force $file $backup

        # NEXT, do the replacement.
        set text [string map [list $target $replacement] $text]

        # NEXT, save the new text.
        set f [open $file w]
        puts $f $text
        close $f
    }
}













