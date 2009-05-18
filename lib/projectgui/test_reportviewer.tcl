#-----------------------------------------------------------------------
# TITLE:
#    test_reportviewer.tcl
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

sqldocument db -clock ::marsutil::simclock
db open :memory:
db clear

reporter configure -db ::db -clock ::marsutil::simclock

reporter save \
    -type INPUT      \
    -subtype GARBAGE \
    -title "Garbage in the Streets" \
    -text [tsubst {
        |<--

        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec
        quis orci ac justo pretium rhoncus. Fusce vel faucibus
        ligula. Nunc varius semper sapien, auctor tempus risus
        faucibus sed. Vestibulum ante ipsum primis in faucibus orci
        luctus et ultrices posuere cubilia Curae; Sed lectus justo,
        tincidunt ut lacinia in, vestibulum sit amet justo. Ut diam
        augue, pulvinar ut faucibus quis, cursus sit amet
        magna. Suspendisse commodo risus in mauris fermentum eget
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

pack [reportviewer .viewer -db ::db] -fill both -expand yes

.viewer display 1

debugger new
