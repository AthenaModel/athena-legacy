#!/bin/sh
# -*-tcl-*-
# The next line restarts using tclsh \
exec tclsh8.5 "$0" "$@"

#-----------------------------------------------------------------------
# TITLE:
#    test_pwinman.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Test script for pwinman(n), pwin(n)
#
#-----------------------------------------------------------------------

package require Tk
package require marsutil
package require marsgui

namespace import marsutil::* marsgui::*


#-----------------------------------------------------------------------
# Main-line Code

set pwinCount 0


proc echo {args} {
    puts $args
}

proc CreatePwin {w} {
    set f [$w frame]

    label $f.label \
        -text "Pwin #[incr ::pwinCount]" \
        -width 40 \
        -height 8 \
        -background white \
        -foreground black

    pack $f.label -fill both -expand yes

    $w configure -title "$::pwinCount"
}

proc main {argv} {
    # FIRST, pop up a debugger
    debugger new

    ttk::button .new \
        -text     "New Pwin"  \
        -command  {CreatePwin [.man insert 0]}

    pwinman .man \
        -width 600 \
        -height 600

    pack .new -side top -fill x
    pack .man -fill both -expand yes
}



#-----------------------------------------------------------------------
# Invoke application

main $argv




