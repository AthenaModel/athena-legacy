#-----------------------------------------------------------------------
# TITLE:
#    mapsimple.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    marsutil(n) module: a simple projection(i) type.
#
#    Routines for conversion between canvas coordinates and map references.
#    A map is an image file used as a map background.
#
#    There are three kinds of coordinate in use:
#
#    * Canvas coordinates: cx,cy coordinates extending to the right and
#      and down from the origin.  The full area of the canvas can be
#      much larger than the visible area.  Canvas coordinates are floating
#      point pixels.  The canvas coordinates for a map location are
#      unique for any given zoom factor, but vary from one zoom factor
#      to another.  Conversions to and from canvas coordinates take
#      the zoom factor into account.
#
#    * Map units: lat,lon coordinates extending to the right and down from
#      the upper-left corner of the map image.  Map units are
#      independent of zoom factor.  Map units are determined as
#      follows:
#
#          lat = canvas units / (delta map x * (zoom factor/100.0))
#          lon = canvas units / (delta map y * (zoom factor/100.0))
#
#      The zoom factor is a number, nominally 100, which indicates the
#      zoom level, i.e., 100%, 200%, 50%, etc.
#
#      Delta map x and delta map y are computed from the width and height
#      of the map image and the width in latitude and height in longitude.
#
#      Thus,
#          delta map x = (image width / (max lat - min lat))
#          delta map y = (image height / (max lon - min lon))
#
#      The basic assumption is that it is a nicely square patch of earth, which
#      is *very* simple, hence the name of the projection. This projection
#      should only be used if the map image conforms to this assumption.
#
#    * Map locations (map locs) : computed as above
#    * Map references (map refs): computed from the lat/long pair 
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsutil:: {
    namespace export mapsimple
}

#-----------------------------------------------------------------------
# mapref type

snit::type ::marsutil::mapsimple {
    #-------------------------------------------------------------------
    # Options

    # Width and height of map, in pixels
    option -width  \
        -type {snit::integer -min 1}  \
        -default 1000

    option -height \
        -type {snit::integer -min 1}  \
        -default 1000

    # Min/max latitude and longitude defaults
    option -minlon -type snit::double -default 0.0
    option -maxlon -type snit::double -default 3.0
    option -minlat -type snit::double -default 3.0
    option -maxlat -type snit::double -default 0.0

    #-------------------------------------------------------------------
    # Instance Variables

    # mwid, mht
    #
    # Dimensions in map coordinates
    
    variable mwid 1000
    variable mht  1000
    variable dmx  0.1
    variable dmy  0.1
    
    #-------------------------------------------------------------------
    # Constructor

    # None needed

    #-------------------------------------------------------------------
    # Methods

    method init {} {
        # FIRST, compute deltas given the map image size and the map
        # corner coordinates of the map image
        set dmx [expr {($options(-maxlon)-$options(-minlon))/$options(-width)}]
        set dmy [expr {($options(-maxlat)-$options(-minlat))/$options(-height)}]
    }

    # box
    #
    # Returns the bounding box of the map in map units

    method box {} {
        list 0 0 $mwid $mht
    }

    # dim
    #
    # Returns the dimensions of the map in map units

    method dim {} {
        list $mwid $mht
    }

    # c2m zoom cx cy
    #
    # zoom     Zoom factor
    # cx,cy    Position in canvas units
    #
    # Returns the position in map units
    # Note: Canvas units increase downward, map units (lat) decrease
    # downward, hence the use of max lat and a minus sign

    method c2m {zoom cx cy} {
        set fac [expr {$zoom/100.0}]
        list [expr {$options(-maxlat)-$cy/$fac*$dmy}] \
             [expr {$options(-minlon)+$cx/$fac*$dmx}]
    }

    # m2c zoom mx my....
    #
    # zoom       Zoom factor
    # lat,lon    One or points in map units
    #
    # Returns the points in canvas units
    # Note: canvas units increase downward, map units (lat) decrease
    # downward, hence the use of max lat 

    method m2c {zoom args} {
        set out [list]
        set fac [expr {$zoom/100.0}]
        foreach {lat lon} $args {
            # FIRST, compute normalized lat and long referenced to the
            # upper left corner of the map image
            set nmy [expr {$options(-maxlat) - $lat}]
            set nmx [expr {$lon - $options(-minlon)}]
            lappend out [expr {round($nmx*$fac/$dmx)}] \
                        [expr {round($nmy*$fac/$dmy)}]
        }

        return $out
    }

    # c2ref zoom cx cy
    #
    # zoom     Zoom factor
    # cx,cy    Position in canvas units
    #
    # Returns the position as a map reference
    # Note: canvas units increase downward, map unit (lat) decrease
    # downward, hence the use of max lat

    method c2ref {zoom cx cy} {
        set fac [expr {$zoom/100.0}]
        set lon [expr {$options(-minlon)+$cx/$fac*$dmx}] 
        set lat [expr {$options(-maxlat)-$cy/$fac*$dmy}]
        return [latlong tomgrs [list $lat $lon]]
    }

    # ref2c zoom ref...
    #
    # zoom     Zoom factor
    # ref      A map reference
    #
    # Returns a list {cx cy} in canvas units
    # Note: canvas units increase downward, map unit (lat) decrease
    # downward, hence the use of max lat

    method ref2c {zoom args} {
        set fac [expr {$zoom/100.0}]

        foreach ref $args {
            lassign [latlong frommgrs $ref] lat lon
            set cy [expr {round(($options(-maxlat)-$lat)*$fac/$dmy)}]
            set cx [expr {round(($lon-$options(-minlon))*$fac/$dmx)}]
            lappend result $cx $cy
        }

        return $result
    }

    # m2ref mx my....
    #
    # lat,lon    Position in map units
    #
    # Returns the position(s) as mapref strings

    method m2ref {args} {
        set result [list]

        foreach {lat lon} $args {
            lappend result [latlong tomgrs [list $lat $lon]]
        }
        
        return $result
    }

    # ref2m ref...
    #
    # ref   A map reference string
    #
    # Returns a list {lat lon...} 

    method ref2m {args} {
        set result ""

        foreach ref $args {
            lappend result [latlong frommgrs $ref] 
        }

        return $result
    }

    # ref validate ref....
    #
    # ref   A map reference
    #
    # Validates the map reference for form and content.

    method {ref validate} {args} {
        set prefix ""

        foreach ref $args {
            if {[catch {latlong frommgrs $ref} result]} {
                error "invalid MGRS coordinate: \"$ref\""
            }
        }

        return $args
    }
}

