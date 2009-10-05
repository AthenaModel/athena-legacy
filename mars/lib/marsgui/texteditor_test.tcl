#!/bin/sh
# -*-tcl-*-
# The next line restarts using tclsh \
exec tclsh8.4 "$0" "$@"

package require Tk 8.4
package require marsgui

wm title . "Test"

label .lab \
    -font {Helvetica 40} \
    -text "texteditor test"

pack .lab

if {[llength $argv] == 0} {
    ::marsgui::texteditor .%AUTO% -title "Test Editor"
} else {
    set win [::marsgui::texteditor .%AUTO% -title "Test Editor"]

    $win open [lindex $argv 0]
}





