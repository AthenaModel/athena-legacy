#-----------------------------------------------------------------------
# TITLE:
#   test_wmsclient.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Test program for wmsclient(n). 
#
#   There is a WMS server at 
#
#       http://demo.cubewerx.com/demo/cubeserv/simple
#
#-----------------------------------------------------------------------
lappend auto_path ~/athena/mars/lib ~/athena/lib

package require marsutil
package require marsgui
package require projectlib

namespace import marsutil::* marsgui::* projectlib::*

proc main {argv} {
    # FIRST, create wmsclient
    wmsclient wms -servercmd DumpData

    # NEXT, create GUI

    # address entry
    commandentry .address \
        -clearbtn 1 \
        -returncmd GotAddress

    ttk::separator .sep1 

    # debug text pane
    text .debug \
        -width 80 \
        -height 40 \
        -yscrollcommand [list .yscroll set]

    scrollbar .yscroll \
        -command [list .debug yview]

    # grid components

    grid .address -row 0 -column 0 -columnspan 2 -sticky ew
    grid .sep1    -row 1 -column 0 -columnspan 2 -sticky ew
    grid .debug   -row 2 -column 0 -sticky nsew
    grid .yscroll -row 2 -column 1 -sticky ns

    grid rowconfigure    . 2 -weight 1
    grid columnconfigure . 0 -weight 1

    if {[llength $argv] > 0} {
        .address set [lindex $argv 0]
        .address execute
    }
}


# GotAddress addr 
#
# addr - The address they entered
#
# Called when the user enters an address.

proc GotAddress {addr} {
    DebugClear
    wms server connect $addr
}

proc DumpData {} {
    DebugValue "Server:" [wms server url]
    DebugValue "URL:"    [wms agent url]
    DebugPuts "\n"

    if {[wms server state] ne "OK"} {
        DebugPuts "Connection Error:\n"
        DebugPuts "WMS [wms server state]: [wms server status]\n"
        DebugPuts "=> [wms server error]\n"
        return
    }

    DebugPuts "WMS [wms server state]: [wms server status]\n\n"

    DebugDict "httpinfo -----:" [wms agent httpinfo]

    DebugDict "Headers ----:" [wms agent meta]


    DebugPuts "Data-----:\n"
    DebugPuts [wms agent data]

}


proc DebugClear {} {
    .debug delete 1.0 end
}

proc DebugPuts {text} {
    .debug insert end $text
}

proc DebugValue {label value} {
    DebugPuts [format "%-20s <%s>\n" $label $value]
}

proc DebugDict {label dict} {
    DebugPuts "$label\n"
    foreach {label value} $dict {
        DebugValue $label $value
    }
    DebugPuts  "------------------\n\n"
}

main $argv
