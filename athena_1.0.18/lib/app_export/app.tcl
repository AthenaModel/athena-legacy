#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_export(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_export
#        app init $argv
#
#    This program exports Athena scenario files in XML format.
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

        # NEXT, open the table
        scenariodb db
        
        if {[catch {db open $scenario} result]} {
            puts $result
            exit 1
        }

        if {[catch {db export} output]} {
            puts "Error exporting $scenario:\n\n"
            puts $::errorInfo
            exit
        }

        if {$xmlfile eq ""} {
            puts $output
            exit
        }

        if {[catch {
            set f [open $xmlfile w]
            puts $f $output
            close $f
        } result]} {
            puts "Error writing to $xmlfile: \n$result"
        }
    }

    #-----------------------------------------------------------------------
    # Utility Routines

    # ShowUsage
    #
    # Display command line syntax.

    proc ShowUsage {} {
        puts {Usage: athena export scenario [xmlfile]

Given a scenario file, exports the scenario as an XML file.  By default,
the XML output is written to the standard output; if an XML file name
is given, the output is written to that file.  See athena_export(1) 
for more information.}
    }

}







