#-----------------------------------------------------------------------
# TITLE:
#    mapref.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    minlib(n) module: a generic projection(i) type.
#
#    Routines for conversion between canvas coordinates and map references.
#    A map is an image file used as a map background.  Maps may be zoomed.
#
#    There are three kinds of coordinate in use:
#
#    * Canvas coordinates: cx,cy coordinates extending to the right and
#      and down from the origin.  The full area of the canvas can be
#      much larger than the visible area.  Canvas coordinates are floating
#      point pixels.  The canvas coordinates for a map location are
#      unique for any given zoom factor, but vary from one zoom factor
#      to another.
#
#    * Map units: mx,my coordinates extending to the right and down from
#      the upper-left corner of the map image.  Map units are
#      independent of zoom factor.  Map units are determined as
#      follows:
#
#          map units = canvas units / (map factor * (zoom factor/100.0))
#
#      The zoom factor is a number, nominally 100, which indicates the
#      zoom level, i.e., 100%, 200%, 50%, etc.
#
#      The map factor is computed as follows:
#
#          map factor = max(map width, map height)/999.0
#
#      In other words, the long dimension of the map image, in pixels, 
#      is divided into 999 units.  The map factor can be computed
#      once, for the 100% (default) zoom, and combined with the zoom
#      factor as shown above, or recomputed for each zoom.  This code
#      does the former.  Map units are integer units.
#
#    * Map references (map refs): A map ref is a six-digit
#      alphanumeric string that is equivalent to an x,y pair in map
#      units.
#
#      * Each coordinate is a number between 000 and 999.  The first
#        digit is turned into a character, A,B,C,D,E,F,G,H,J,K.  Thus,
#        0,0 is A00A00 and 123,456 is B23E56.
#
# TBD:
#
#    * It might be desirable to make map units range from 0 to 9999,
#      if we frequently use larger maps.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::minlib:: {
    namespace export mapref zoomfactor
}

#-----------------------------------------------------------------------
# mapref type

snit::integer ::minlib::zoomfactor -min 1 -max 300

snit::type ::minlib::mapref {
    #-------------------------------------------------------------------
    # Options

    # Width and height of map, in pixels
    option -width  \
        -type {snit::integer -min 1}  \
        -configuremethod ConfigureDim \
        -default 1000

    option -height \
        -type {snit::integer -min 1}  \
        -configuremethod ConfigureDim \
        -default 1000

    method ConfigureDim {opt val} {
        set options($opt) $val

        set mapFactor [expr {
            max($options(-width),$options(-height))/999.0
        }]
    }

    #-------------------------------------------------------------------
    # Instance Variables

    # map factor: map_unit = factor*canvas_unit
    variable mapFactor

    # zoomFactor: 100%, etc.
    variable zoomFactor 100

    #-------------------------------------------------------------------
    # Constructor

    # None needed

    #-------------------------------------------------------------------
    # Methods

    # zoom ?factor?
    #
    # factor    The zoom factor as an integer percentage, e.g., 100
    #
    # Zooms the map to the desired zoom factor.  The default zoom factor
    # is 100.  Returns the zoom factor.

    method zoom {{factor ""}} {
        # FIRST, if no new zoom, just return the old one.
        if {$factor eq ""} {
            return $zoomFactor
        }

        # NEXT, validate the zoom factor. 
        zoomfactor validate $factor

        set zoomFactor $factor
    }

    # box
    #
    # Returns the bounding box of the map in map units

    method box {} {
        list 0 0 {*}[$self c2m $options(-width) $options(-height)]
    }

    # dim
    #
    # Returns the dimensions of the map in map units

    method dim {} {
        $self c2m $options(-width) $options(-height)
    }

    # c2m cx cy
    #
    # cx,cy    Position in canvas units
    #
    # Returns the position in map units

    method c2m {cx cy} {
        set fac [expr {$mapFactor * ($zoomFactor/100.0)}]

        list [expr {round($cx / $fac)}] [expr {round($cy / $fac)}]
    }

    # m2c mx my
    #
    # mx,my    Position in map units
    #
    # Returns the position in canvas units

    method m2c {mx my} {
        set fac [expr {$mapFactor * ($zoomFactor/100.0)}]

        list [expr {$mx * $fac}] [expr {$my * $fac}]
    }

    # c2ref cx cy
    #
    # cx,cy    Position in canvas units
    #
    # Returns the position as a map reference

    method c2ref {cx cy} {
        set fac [expr {$mapFactor * ($zoomFactor/100.0)}]

        return [GetRef $fac $cx][GetRef $fac $cy]
    }

    # ref2c ref
    #
    # ref   A map reference
    #
    # Returns a {cx cy} pair in canvas units

    method ref2c {ref} {
        set fac [expr {$mapFactor * ($zoomFactor/100.0)}]

        list \
            [GetCan $fac [string range $ref 0 2]] \
            [GetCan $fac [string range $ref 3 5]]
    }

    # m2ref mx my
    #
    # mx,my    Position in map units
    #
    # Returns the position as a mapref

    method m2ref {mx my} {
        return [GetRef 1.0 $mx][GetRef 1.0 $my]
    }

    # ref2m ref
    #
    # ref   A map reference
    #
    # Returns an {mx my} pair in map units

    method ref2m {ref} {
        list \
            [expr {round([GetCan 1.0 [string range $ref 0 2]])}] \
            [expr {round([GetCan 1.0 [string range $ref 3 5]])}]
    }

    #-------------------------------------------------------------------
    # Utility Procs

    # GetRef factor cu
    #
    # factor    The map factor
    # cu        A coordinate value in canvas units
    #
    # Returns the mapref coordinate, e.g., "A35".
    # Pass factor=1.0 to convert map units into a ref

    proc GetRef {factor cu} {
        set mu [expr {round($cu/$factor)}]

        set tail [expr {$mu % 100}]
        set head [expr {$mu / 100}]
        set char [lindex {A B C D E F G H J K L} $head]

        return "$char[format %02d $tail]"
    }

    # GetCan factor ref
    #
    # factor    The map factor
    # ref       A map ref coordinate value, e.g., "A35".
    #
    # Returns the coordinate in canvas units.
    # Pass factor=1.0 to convert into map units.

    proc GetCan {factor ref} {
        set char [string toupper [string index $ref 0]]
        scan [string range $ref 1 end] %d tail
        set head [lsearch -exact {A B C D E F G H J K L} $char]
        
        set cu [expr {$factor*(100.0*$head + $tail)}]
        
        return $cu
    }
}

