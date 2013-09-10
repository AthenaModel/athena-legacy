package require snit
package require Tk
source gradient.tcl


proc test {} {
    set grad [::marsutil::gradient %AUTO%  \
                  -mincolor \#FFCC99  \
                  -maxcolor \#663300  \
                  -minlevel 0         \
                  -maxlevel 4]
    
        
    for {set i 0} {$i <= 4} {incr i} {
        set color [$grad color $i]
        puts $color
        
        label .lab$i -width 10 -height 1 -background [$grad color $i]
        pack .lab$i -side bottom
    }            
}

test


