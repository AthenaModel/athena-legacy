#!/bin/sh
# -*-tcl-*-
# The next line restarts using tclsh \
exec tclsh8.5 "$0" "$@"

#-----------------------------------------------------------------------
# TITLE:
#    test_lazyupdater.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Test script for lazyupdater(n)
#
#-----------------------------------------------------------------------

package require Tk
package require marsutil
package require marsgui

namespace import marsutil::* marsgui::*


#-----------------------------------------------------------------------
# Main-line Code

set counter 0

proc HideShow {} {
    if {[winfo ismapped .lab]} {
        pack forget .lab
    } else {
        pack .lab -fill both -expand yes
    } 
}

proc Update {} {
    puts "Update [incr ::counter]"
}

proc main {argv} {
    # FIRST, pop up a debugger
    debugger new

    ttk::button .btn \
        -text "Hide/Show" \
        -command HideShow

    label .lab \
        -textvariable ::counter   \
        -font        {Courier 32} \
        -width       40           \
        -height      10

    pack .btn -fill x


    lazyupdater lu   \
        -delay 1000  \
        -window .lab \
        -command Update

    bind .lab <Configure> {lu update}
}



#-----------------------------------------------------------------------
# Invoke application

main $argv




