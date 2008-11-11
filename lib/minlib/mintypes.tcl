#-----------------------------------------------------------------------
# TITLE:
#    mintypes.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Minerva Data Types
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::minlib:: {
    namespace export eurbanization polygon
}

#-------------------------------------------------------------------
# Enumerations

::marsutil::enum ::minlib::eurbanization {
    RURAL        "Rural"
    SUBURBAN     "Suburban"
    URBAN        "Urban"
}

#-----------------------------------------------------------------------
# polygon type

snit::type ::minlib::polygon {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate coords...
    #
    # coords      A list {x1 y1 x2 y2 x3 y3 ....} of vertices
    #
    # Validates the polygon.  The polygon is valid if:
    #
    # * It has at least three points
    # * There are no duplicated points
    # * No edge intersects any other edge
    #
    # The coordinates can be passed as a single list, or as
    # individual arguments.

    typemethod validate {args} {
        # FIRST, get the coordinate list if passed as one arg.
        if {[llength $args] == 1} {
            set coords [lindex $args 0]
        } else {
            set coords $args
        }

        # NEXT, check the number of coordinates
        set len [llength $coords]
        require {$len % 2 == 0} \
            "expected even number of coordinates, got $len: \"$coords\""

        let size {$len/2}
        require {$size >= 3} \
            "expected at least 3 point(s), got $size: \"$coords\""

        # NEXT, check for duplicated points
        for {set i 0} {$i < $len} {incr i 2} {
            for {set j 0} {$j < $len} {incr j 2} {
                if {$i == $j} {
                    continue
                }

                lassign [lrange $coords $i $i+1] x1 y1
                lassign [lrange $coords $j $j+1] x2 y2

                require {$x1 != $x2 || $y1 != $y2} \
                    "Point [expr {$i/2}] is identical to point [expr {$j/2}]: \"$coords\""
            }
        }

        # NEXT, check for edge crossings.  Consecutive edges can
        # intersect at their end points.
        set n [clength $coords]
        
        for {set i 0} {$i < $n} {incr i} {
            for {set j [expr {$i + 2}]} {$j <= $i + $n - 2} {incr j} {
                set e1 [cedge $coords $i]
                set e2 [cedge $coords $j]

                set p1 [lrange $e1 0 1]
                set p2 [lrange $e1 2 3]
                set q1 [lrange $e2 0 1]
                set q2 [lrange $e2 2 3]

                require {![intersect $p1 $p2 $q1 $q2]} \
                    "Edges $i and $j intersect: \"$coords\""
            }
        }


        return $coords
    }
}

