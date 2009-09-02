#-----------------------------------------------------------------------
# TITLE:
#    test_reportbrowser.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Test program for the reportviewer widget
#
#-----------------------------------------------------------------------

package require Tk
package require marsutil
package require projectlib
package require marsgui
package require projectgui

namespace import marsutil::* projectlib::* marsgui::* projectgui::*

set text [tsubst {
    |<--
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec
    quis orci ac justo pretium rhoncus. Fusce vel faucibus
    ligula. Nunc varius semper sapien, auctor tempus risus
    faucibus sed. Vestibulum ante ipsum primis in faucibus orci
    luctus et ultrices posuere cubilia Curae; Sed lectus justo,
    tincidunt ut lacinia in, vestibulum sit amet justo. Ut diam
    augue, pulvinar ut faucibus quis, cursus sit amet
    magna. 

    Suspendisse commodo risus in mauris fermentum eget
    fermentum est congue. Nulla fermentum vulputate dolor, quis
    mollis diam rhoncus sit amet. Suspendisse lacinia pulvinar
    dapibus. Cum sociis natoque penatibus et magnis dis parturient
    montes, nascetur ridiculus mus. Etiam in libero
    nulla. Suspendisse vulputate, tellus non ultricies bibendum,
    tellus sapien consectetur enim, quis dictum nisi dolor
    ullamcorper lectus. Nunc bibendum dui vel elit aliquam sed
    ornare ante posuere. Vivamus sit amet eros sem, vitae
    vulputate purus. Aenean vulputate felis dolor.
}]

array set subtypes {
    BADFOOD "Contaminated Food Supply"
    GARBAGE "Garbage in the Streets"
    SEWAGE  "Sewage Spill"
}

proc Tick {} {
    variable text
    variable subtypes

    simclock tick

    set subtype [pickfrom [array names subtypes]]

    reporter save                        \
        -type        INPUT               \
        -subtype     $subtype            \
        -title       $subtypes($subtype) \
        -requested   [pickfrom {0 0 0 1}]    \
        -text $text

    .rb configure -recentlimit \
        [expr {[simclock now] - 10}]
    .rb update
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

reporter bin define BADFOOD "BADFOOD" inputs {
    SELECT * FROM reports WHERE rtype='INPUT' AND subtype='BADFOOD'
}

reporter bin define GARBAGE "GARBAGE" inputs {
    SELECT * FROM reports WHERE rtype='INPUT' AND subtype='GARBAGE'
}

reporter bin define SEWAGE "SEWAGE" inputs {
    SELECT * FROM reports WHERE rtype='INPUT' AND subtype='SEWAGE'
}


timeout ticker -command Tick -interval 2500 -repetition yes
ticker schedule

debugger new

pack [reportbrowser .rb -db ::db] -fill both -expand yes

.rb refresh

