#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_import(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_import
#        app init $argv
#
#    This program imports Athena scenario files from XML.
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
        # FIRST, if there are too few or too many arguments, show usage.
        if {[llength $argv] < 1 ||
            [llength $argv] > 2
        } {
            ShowUsage
            exit 1
        }

        # NEXT, get the args
        set scenario [lindex $argv 0]

        set xmlfile [lindex $argv 1]

        # FIRST, get the XML input
        if {$xmlfile ne ""} {
            if {[catch {set xmltext [readfile $xmlfile]} result]} {
                puts "Error reading XML text from $xmlfile:\n$result"
                exit 1
            }
        } else {
            set xmltext [read stdin]
        }

        # NEXT, open the table
        scenariodb db
        
        if {[catch {db open $scenario} result]} {
            puts $result
            exit 1
        }

        # NEXT, import the XML.
        if {[catch {db import $xmltext -clear -logcmd puts}]} {
            puts "Error importing $scenario:\n\n"
            puts $::errorInfo
            exit
        }

        db close
    }

    #-----------------------------------------------------------------------
    # Utility Routines

    # ShowUsage
    #
    # Display command line syntax.

    proc ShowUsage {} {
        puts {Usage: athena import scenario [xmlfile]

Creates a scenario file from XML input.  By default, the XML text 
is read from standard input; if an XML file name is given, the XML 
text read from the file.  See athena_import(1) for more information.
}
    }

}








