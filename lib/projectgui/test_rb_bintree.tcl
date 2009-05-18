#-----------------------------------------------------------------------
# TITLE:
#    test_rb_bintree.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Test program for the rb_bintree widget
#
#-----------------------------------------------------------------------

package require Tk
package require marsutil
package require projectlib
package require marsgui
package require projectgui

namespace import marsutil::* projectlib::* marsgui::* projectgui::*

proc GotBin {} {
    puts "Got bin: <[.bintree get]>"
}

sqldocument db -clock ::marsutil::simclock
db open :memory:
db clear

reporter configure -db ::db -clock ::marsutil::simclock

reporter bin define all "All" "" {
    SELECT * FROM reports
}

reporter bin define requested "Requested" "" {
    SELECT * FROM reports WHERE requested=1
}

reporter bin define hotlist "Hot List" "" {
    SELECT * FROM reports WHERE hotlist=1
}

reporter bin define inputs "Inputs" "" {
    SELECT * FROM reports WHERE rtype='INPUT'
}

reporter bin define GARBAGE "GARBAGE" inputs {
    SELECT * FROM reports WHERE rtype='INPUT' AND subtype='GARBAGE'
}

reporter bin define SEWAGE "SEWAGE" inputs {
    SELECT * FROM reports WHERE rtype='INPUT' AND subtype='SEWAGE'
}

debugger new


pack [::projectgui::rb_bintree .bintree] -fill both -expand yes

bind .bintree <<Selection>> GotBin

.bintree refresh
.bintree set GARBAGE

