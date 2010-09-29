package require snit
package require marsgui
namespace import marsgui::*

paner .pv -orient vertical


proc textpane {w} {
    frame $w -borderwidth 0

    text $w.t -width 40 -height 10 -background white \
        -yscrollcommand [list $w.s set]

    for {set i 1} {$i <= 100} {incr i} {
        $w.t insert end "$w, line $i\n"
    }
    ttk::scrollbar $w.s -command [list $w.t yview]
    pack $w.s -side right -fill y 
    pack $w.t -side right -fill both -expand 1
}

paner .pv.ph -orient horizontal

textpane .pv.t

.pv add .pv.ph -sticky nsew -minsize 60
.pv add .pv.t  -sticky nsew -minsize 60


textpane .pv.ph.t1
textpane .pv.ph.t2

.pv.ph add .pv.ph.t1  -sticky nsew -minsize 60
.pv.ph add .pv.ph.t2  -sticky nsew -minsize 60

grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1
grid .pv -sticky nsew

update idletasks

