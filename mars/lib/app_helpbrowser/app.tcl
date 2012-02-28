#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mars_helpbrowser(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_helpbrowser
#        app init $argv
#
#    This program is a browser for the .helpdb help documents 
#    produced by mars_helptool(1).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Variables

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv         Command line arguments
    #
    # This the main program.

    typemethod init {argv} {
        # FIRST get the arguments, if any.
        if {[llength $argv] == 0 || [llength $argv] > 2} {
            app usage
            exit 1
        }

        lassign $argv filename page

        if {![file exists $filename]} {
            puts "No such help file: $filename"
            exit 1
        }

        # NEXT, open the help file, and pop up the help browser.
        helpdb hdb
        hdb open $filename

        helpbrowser .hb \
            -helpdb ${type}::hdb

        pack .hb -fill both -expand yes

        if {$page ne ""} {
            if {![hdb page exists $page]} {
                puts "No such page: $page"
                exit 1
            }

            .hb showpage $page
        }

        # NEXT, allow for debugging
        bind . <Control-F12> [list debugger new]
    }

    # usage
    # 
    # Displays the application usage.

    typemethod usage {} {
        puts "mars helpbrowser file.helpdb \[page\]"
    }
}
