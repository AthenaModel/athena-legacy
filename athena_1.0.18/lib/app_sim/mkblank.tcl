package require pixane
package require marsutil
namespace import marsutil::*

set a [pixane create]

pixane resize $a 1000 1000
pixane color $a white
pixane fill $a
pixane color $a #CCCCCC

for {set x 40} {$x <= 960} {incr x 40} {
    for {set y 40} {$y <= 960} {incr y 40} {
        lassign [boxaround 2 $x $y] x1 y1 x2 y2

        pixane line $a $x1 $y $x2 $y
        pixane line $a $x $y1 $x $y2
    }
}

pixane save $a -file blank.png -format PNG
