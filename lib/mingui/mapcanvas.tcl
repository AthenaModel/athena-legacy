#-----------------------------------------------------------------------
# TITLE:
#    mapcanvas.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mingui(n) package: Map Canvas widget
#
#    This is a canvas widget designed to display a map with
#    features upon it, including neighborhood polygons and asset icons.
#
# DISPLAYED OBJECTS:
#    mapcanvas(n) displays the following kinds of objects:
#
#    The Map
#        The map is an image file; the canvas' scroll region is precisely
#        the extent of the map.  The map can be viewed at several
#        zoom levels; however, all zoom levels derive from the original
#        image file.
#
#    Neighborhoods
#        Neighborhoods are represented as polygons.  By default, 
#        nbhood polygons have no fill, allowing the map to show through;
#        however, fill colors can be used as desired to convey nbhood
#        status and other relationships.
#
#    Icons
#        Icons are things positioned on the map, usually within 
#        neighborhoods: military units, infrastructure, etc.
#
# COORDINATE SYSTEMS:
#    mapcanvas(n) works with and translates between the following 
#    coordinate systems.
#
#    Window Coordinates
#        (x,y) with origin at the top-left of the canvas widget's
#        viewport.  Mouse-clicks come in with these coordinates via
#        the %x,%y event-handler substitutions.
#
#        In code, the symbols wx and wy are used for window coordinates.
#
#    Canvas Coordinates
#        (x,y) with origin at the top-left of the map, and extending
#        to the right and down.  Canvas coordinates are pixel coordinates.
#
#        In code, the symbols cx and cy are used for canvas coordinates.
#
#    Map Coodinates
#        (x,y), referring to unique positions on the map.  Conversion
#        between map coordinates and canvas coordinates is handled by
#        a coordinate-conversion object given to the mapcanvas when it
#        is created.
#
#        In code, the symbols mx and my are used for map coordinates.
#
#    Map Reference Strings
#        A map reference string, or "mapref" is a short string that
#        equivalent to some (x,y) in map coordinates (e.g., MGRS
#        strings are equivalent to lat/lon.  Conversion between
#        maprefs and canvas coordinates is also handled by the 
#        coordinate-conversion object.
#
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::mingui:: {
    namespace export mapcanvas mapimage
}

#-------------------------------------------------------------------
# Data Types

snit::type ::mingui::mapimage {
    typemethod validate {img} {
        if {$img eq ""} {
            return
        }

        # NEXT, make sure it's an image
        if {[catch {
            image width $img
        } result]} {
            error "not an image"
        }
    }
}


#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor ::mingui::mapcanvas {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # FIRST, Define the standard Mapcanvas bindings

        # Track when the pointer enters and leaves the window.
        bind Mapcanvas <Enter>  {%W MapEnter}
        bind Mapcanvas <Leave>  {%W MapLeave}

        # Support -refvariable
        bind Mapcanvas <Motion> {%W MaprefSet %x %y}

        # NEXT, Define the bindtags for the interaction modes

        # Mode: point
        # No bindtags yet

        # Mode: poly

        bind Mapcanvas.poly <ButtonPress-1>        {%W PolyPoint %x %y}
        bind Mapcanvas.poly <Motion>               {%W PolyMove  %x %y}
        bind Mapcanvas.poly <Double-ButtonPress-1> {%W PolyComplete}
        bind Mapcanvas.poly <Escape>               {%W PolyFinish}

        # Mode: pan

        bind Mapcanvas.pan <ButtonPress-1> {%W scan mark %x %y}
        bind Mapcanvas.pan <B1-Motion>     {%W scan dragto %x %y 1}
    }

    #-------------------------------------------------------------------
    # Lookup Tables

    # Mode data, by mode name
    #
    #    cursor    Name of the Tk cursor for this mode
    #    cleanup   Name of a method to call when a different mode is
    #              selected.
    #    bindings  A list, {tag event binding ...}, of bindings on 
    #              canvas tags which should be used when this mode is
    #              in effect.

    typevariable modes -array {
        point {
            cursor   left_ptr
            cleanup  {}
            bindings {
                icon  <ButtonPress-1>    {%W Icon-1 %x %y}
                icon  <Control-Button-1> {%W IconMark %x %y}
                icon  <B1-Motion>        {%W IconDrag %x %y}
                icon  <B1-ButtonRelease> {%W IconRelease %x %y}
            }
        }

        poly {
            cursor   crosshair
            cleanup  PolyCleanUp
            bindings {}
        }

        pan {
            cursor   fleur
            cleanup  {}
            bindings {}
        }
    }

    #-------------------------------------------------------------------
    # Type variables

    # Array of icon type data
    #
    # names        List of icon type names
    # icon-$name   Type command

    typevariable icontypes -array {
        names ""
    }

    #-------------------------------------------------------------------
    # Typemethods: Icon Management

    # icon register iconType
    #
    # iconType     A mapicon(i) type command
    #
    # Registers the iconType with the mapcanvas

    typemethod {icon register} {iconType} {
        set name [$iconType typename]

        if {$name ni $icontypes(names)} {
            lappend icontypes(names) $name
        }

        set icontypes(type-$name) $iconType
    }

    # icon types
    #
    # Returns a list of the icon type names

    typemethod {icon types} {} {
        return $icontypes(names)
    }

    #-------------------------------------------------------------------
    # Components

    component proj       ;# The projection(i) component

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -map
    #
    # Tk photo image of the map
    
    option -map -type ::mingui::mapimage

    # -projection
    #
    # A projection(i) object.  If not specified, a mapref(n) will be
    # used.

    option -projection

    # -refvariable
    #
    # A variable name.  It is set to the map reference string of the
    # location under the mouse pointer.

    option -refvariable -default ""

    # -modevariable
    #
    # A variable name.  It is set to the current interaction mode, or
    # "" if none.

    option -modevariable -default ""

    # -snapradius
    #
    # Radius, in pixels, for snapping to points.

    option -snapradius \
        -type    {snit::integer -min 0} \
        -default 5

    # -snapmode
    #
    # Whether snapping is on or not.
    
    option -snapmode \
        -type    snit::boolean \
        -default yes

    #-------------------------------------------------------------------
    # Instance Variables

    # info array
    #
    #   mode         Current interaction mode
    #   modeTags     List of canvas tags associated with the current
    #                mode's bindings.
    #   iconCounter  Used to name icons
    #   gotPointer   1 if mouse pointer over widget, 0 otherwise.

    variable info -array {
        mode        ""
        modeTags    {}
        iconCounter 0
        gotPointer  0
    }

    # icons array
    #
    # ids               List of icon ids
    # ids-$icontype     List of icon ids by type
    # icon-$id          Dictionary of icon data for icon $id
    #      id           Icon id
    #      icontype     Icon type
    #      cmd          Icon command
    #      mxy          Icon location as map coordinate pair

    variable icons -array {
        ids {}
    }

    # trans: Data array used during multi-event user interactions

    variable trans -array {}

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the canvas
        installhull using canvas  \
            -highlightthickness 0 \
            -borderwidth        0

        # NEXT, replace Canvas in the bindtags with Mapcanvas
        set tags [bindtags $win]
        set ndx [lsearch -exact $tags Canvas]
        bindtags $win [lreplace $tags $ndx $ndx Mapcanvas]

        # NEXT, save the options
        $self configurelist $args

        # NEXT, create the namespace for icon commands
        namespace eval ${selfns}::icons {}


        # NEXT, display the initial map image; this also sets
        # the initial interaction mode.
        $self clear
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # clear
    #
    # Clears all content from the mapcanvas and reinitializes it to
    # display -map using -projection. If -projection
    # is not defined, a mapref(n) instance will be used.

    method clear {} {
        # FIRST, delete everything.
        $hull delete all

        foreach id $icons(ids) {
            rename [dict get $icons(icon-$id) cmd] ""
        }

        array unset icons
        set icons(ids) [list]

        # NEXT, if there's no map, handle it.
        if {$options(-map) eq ""} {
            set proj [myproc UndefinedMap]
            return
        }

        # NEXT, create the map item
        $hull create image 0 0     \
            -anchor nw             \
            -image  $options(-map) \
            -tags   map

        # NEXT, set the scroll region to the whole map.
        $hull configure -scrollregion [$hull bbox map]
        
        # NEXT, if a projection is specified, remember it; otherwise,
        # create one.

        if {[llength [info command ${selfns}::proj]] != 0} {
            ${selfns}::proj destroy
        }

        if {$options(-projection) ne ""} {
            set proj $options(-projection)
        } else {
            if {[llength [info command ${selfns}::proj]] == 0} {
                mapref ${selfns}::proj \
                    -width  [image width  $options(-map)] \
                    -height [image height $options(-map)]
            }

            set proj ${selfns}::proj
        }

        # NEXT, set the mode back to point mode
        $self mode point

        return
    }

    #-------------------------------------------------------------------
    # Interaction Modes
    #
    # Mapcanvas defines a number of interaction modes.  Modes are defined
    # by a combination of bindtags and canvas tag bindings.  First,
    # each mode is associated with a Tk bindtag called Mapcanvas.<mode>.
    # Second, each mode has a list {tag event binding ...} in the
    # modes array.
    #
    # The currently defined modes are as follows:
    #
    #    point      Default behavior: you can point at things.
    #    poly       You can draw polygons.
    #    pan        Pan mode: pan the map.

    # mode ?mode?
    #
    # mode    A Mapcanvas interaction mode
    #
    # If mode is given, sets the interaction mode.  Returns the current
    # interaction mode.
   
    method mode {{mode ""}} {
        # FIRST, if no new mode is given, return the current mode.
        if {$mode eq ""} {
            return $info(mode)
        }

        # NEXT, call the old mode's cleanup method, if any.
        if {[info exists modes($info(mode))]} {
            set method [dict get $modes($info(mode)) cleanup]
            
            if {$method ne ""} {
                $self $method
            }
        }

        # NEXT, save the mode
        set info(mode) $mode

        # NEXT, clear the old mode's canvas tag bindings.
        foreach tag $info(modeTags) {
            foreach event [$hull bind $tag] {
                $hull bind $tag $event {}
            }
        }

        set info(modeTags) [list]

        # NEXT, Set up the new mode's cursor and tag bindings, if there
        # are any.
        if {[info exists modes($mode)]} {
            $hull configure -cursor [dict get $modes($mode) cursor]
        } else {
            $hull configure -cursor left_ptr
        }

        # NEXT, add the new mode's canvas tag bindings
        if {[info exists modes($mode)]} {
            foreach {tag event binding} [dict get $modes($mode) bindings] {
                if {$tag ni $info(modeTags)} {
                    lappend info(modeTags) $tag
                }

                $hull bind $tag $event $binding
            }
        }

        # NEXT, Find the old mode's bindtag
        set tags [bindtags $win]

        set ndx [lsearch -glob $tags "Mapcanvas.*"]

        if {$ndx > -1} {
            set tags [lreplace $tags $ndx $ndx Mapcanvas.$mode]
        } else {
            set ndx [lsearch -exact $tags "Mapcanvas"]

            set tags [linsert $tags $ndx+1 Mapcanvas.$mode]
        }
        
        # Install the new mode's bindtag
        bindtags $win $tags

        # NEXT, set the mode variable (if any)
        if {$options(-modevariable) ne ""} {
            uplevel 1 [list set $options(-modevariable) $info(mode)]
        }

        # NEXT, return the mode
        return $info(mode)
    }

    #-------------------------------------------------------------------
    # Binding Handlers

    # MapEnter
    #
    # Remembers that the pointer is over the window.

    method MapEnter {} {
        set info(gotPointer) 1
    }

    # MapClear
    #
    # Rembers that the pointer is not over the window.

    method MapLeave {} {
        set info(gotPointer) 0
    }


    # MaprefSet wx wy
    #
    # wx,wy    Position in window units
    #
    # Sets the -refvariable, if any

    method MaprefSet {wx wy} {
        if {$info(gotPointer) && $options(-refvariable) ne ""} {
            set ref [$self w2ref $wx $wy]
            uplevel \#0 [list set $options(-refvariable) $ref]
        }
    }


    # Icon-1 wx wy
    #
    # wx    x window coordinate
    # wy    y window coordinate
    #
    # Generates the <<Icon-1>> virtual event for the selected icon.

    method Icon-1 {wx wy} {
        set id [lindex [$win gettags current] 0]

        $win raise $id

        event generate $win <<Icon-1>> \
            -x    $wx                  \
            -y    $wy                  \
            -data $id
    }


    # IconMark wx wy
    #
    # wx    x window coordinate
    # wy    y window coordinate
    # 
    # Begins the process of dragging an icon on Control-Click.

    method IconMark {wx wy} {
        # FIRST, convert the window coordinates to canvas coordinates.
        lassign [$win w2c $wx $wy] cx cy

        # NEXT, get the ID of the selected icon
        set trans(dragging) 1
        set trans(id)       [lindex [$win gettags current] 0]
        set trans(startx)   $cx
        set trans(starty)   $cy
        set trans(cx)       $cx
        set trans(cy)       $cy
        set trans(moved)    0

        # NEXT, raise the icon, so it when moved it will be over
        # the others.
        $win raise $trans(id)
    }

    # IconDrag wx wy
    #
    # wx    x window coordinate
    # wy    y window coordinate
    # 
    # Continues the process of dragging an icon

    method IconDrag {wx wy} {
        if {![info exists trans(dragging)]} {
            return
        }

        # FIRST, convert the window coordinates to canvas coordinates.
        lassign [$win w2c $wx $wy] cx cy

        # NEXT, compute the delta from the last drag position,
        # and move the icon by that much.
        set dx [expr {$cx - $trans(cx)}]
        set dy [expr {$cy - $trans(cy)}]

        $win move $trans(id) $dx $dy

        # NEXT, remember where it is on the canvas, and that it has
        # been moved.
        set trans(cx) $cx
        set trans(cy) $cy
        set trans(moved) 1
    }

    # IconRelease
    #
    # Finishes the process of dragging an icon.

    method IconRelease {wx wy} {
        if {![info exists trans(dragging)]} {
            return
        }

        # FIRST, if it's been moved, update its mxy, and notify the
        # user.

        if {$trans(moved)} {
            # FIRST, is the current location within the visible bounds
            # of the window?  If so move it!

            if {$info(gotPointer)} {

                # FIRST, Get the delta relative to the point we started
                # dragging.
                set dx [expr {$trans(cx) - $trans(startx)}]
                set dy [expr {$trans(cy) - $trans(starty)}]

                # NEXT, get the icon's original mxy
                lassign [dict get $icons(icon-$trans(id)) mxy] mx1 my1

                # NEXT, get the icon's original cxy
                lassign [$win m2c $mx1 $my1] cx1 cy1

                # NEXT, get the icon's new cxy
                set cx2 [expr {$cx1 + $dx}]
                set cy2 [expr {$cy1 + $dy}]

                # NEXT, get the icon's new mxy, and save it.
                dict set icons(icon-$trans(id)) \
                    mxy [$win c2m $cx2 $cy2]

                # NEXT, notify the user
                event generate $win <<IconMoved>> \
                    -x    $wx                     \
                    -y    $wy                     \
                    -data $trans(id)
            } else {

                # Whoops!  Put the icon back where it was.
                set dx [expr {$trans(startx) - $trans(cx)}]
                set dy [expr {$trans(starty) - $trans(cy)}]

                $win move $trans(id) $dx $dy
            }
        }

        # NEXT, clear the trans array
        array unset trans
    }

    # PolyPoint
    #
    # wx,wy    Window coordinates of a mouse-click
    #
    # Begins/extends a polygon in poly mode.

    method PolyPoint {wx wy} {
        # FIRST, get the current position in canvas coordinates.
        # TBD: Should probably snap to map units!
        lassign [$self PolySnap {*}[$self w2c $wx $wy]] cx cy

        # NEXT, are we already drawing a polygon?  If so, save the
        # current line.
        if {[info exists trans(poly)]} {
            # FIRST, if the new point is close to the first point, and
            # we have enough points, end the line.
            if {[$self CanSnap $cx $cy $trans(startx) $trans(starty)] &&
                [llength $trans(coords)] >= 6
            } {
                $self PolyComplete
                return
            }

            # NEXT, if this point is already on the polygon, ignore it
            foreach {x y} $trans(coords) {
                if {$x == $cx && $y == $cy} {
                    return
                }
            }

            # NEXT, If this edge intersects an earlier edge, return.
            set n [clength $trans(coords)]

            set q1 [lrange $trans(coords) end-1 end]
            set q2 [list $cx $cy]

            for {set i 0} {$i < $n - 2} {incr i} {
                set edge [cedge $trans(coords) $i]
                set p1 [lrange $edge 0 1]
                set p2 [lrange $edge 2 3]

                if {[intersect $p1 $p2 $q1 $q2]} {
                    return
                }
            }

            # NEXT, save the point
            lappend trans(coords) $cx $cy
            
            $hull create line $trans(cx) $trans(cy) $cx $cy \
                -fill red -tags partial
        } else {
            set trans(poly) 1
            set trans(coords) [list $cx $cy]
            set trans(startx) $cx
            set trans(starty) $cy
        }

        # NEXT, Create the rubber line
        set trans(cx) $cx
        set trans(cy) $cy

        $hull delete rubberline

        $hull create line $cx $cy $cx $cy \
            -fill red -tags rubberline

        # NEXT, focus on the window, so that Escape will cancel.
        focus $win
    }

    # PolyComplete
    #
    # Called when a polygon has been completed.  Notifies the
    # application.

    method PolyComplete {} {
        # FIRST, are we already drawing a polygon?  If not, or if the
        # polygon hasn't enough points, ignore this event.
        if {![info exists trans(poly)] ||
            [llength $trans(coords)] < 6
        } {
            return
        }

        # NEXT, notify the application
        event generate $win <<PolyComplete>> \
            -data $trans(coords)
        
        # NEXT, we're done.
        $self PolyFinish
    }

    # PolyMove wx wy
    #
    # Does rubber-banding as we're drawing a polygon.

    method PolyMove {wx wy} {
        # FIRST, if we're not drawing a polygon, we're done.
        if {![info exists trans(poly)]} {
            return
        }

        # NEXT, snap the current point.
        lassign [$self PolySnap {*}[$win w2c $wx $wy]] cx cy

        # NEXT, Updated the rubber line
        set coords [$hull coords rubberline]
        set coords [lreplace $coords 2 end $cx $cy]
        $hull coords rubberline {*}$coords
    }

    # PolyFinish
    #
    # Called when we're finished with the current polygon, whether
    # because it's complete or it's been cancelled.

    method PolyFinish {} {
        # FIRST, clean up the transient data.
        $self PolyCleanUp

        # NEXT, go back to point mode.
        $self mode point
    }

    # PolyCleanUp
    #
    # Cleans up the transient data and canvas artifacts associated with
    # drawing polygons.

    method PolyCleanUp {} {
        array unset trans
        $hull delete rubberline
        $hull delete partial
    }

    # PolySnap cx cy
    #
    # cx,cy   A point in canvas coordinates
    #
    # Given a point cx,cy, tries to snap to a point within a radius.
    # If the first point in the polygon is within range, and snapping
    # to it would yield a valid polygon, snaps to that.  Otherwise,
    # uses SnapToPoint.

    method PolySnap {cx cy} {
        # TBD: Should validate the polygon

        # FIRST, snap to the first point in the polygon, if that 
        # makes sense.  We can do this even if -snapmode is off.
        if {[info exists trans(poly)] &&
            [$self CanSnap $cx $cy $trans(startx) $trans(starty)] &&
            [llength $trans(coords)] >= 6
        } {
            return [list $trans(startx) $trans(starty)]
        }

        # NEXT, Use a normal snap, otherwise.
        if {$options(-snapmode)} {
            return [$self SnapToPoint $cx $cy]
        } else {
            return [list $cx $cy]
        }
    }
   
    #-------------------------------------------------------------------
    # Coordinate Conversion methods

    # Methods delegated to projection
    delegate method mapdim to proj as dim
    delegate method mapbox to proj as box
    delegate method m2ref  to proj
    delegate method ref2m  to proj
    delegate method c2m    to proj
    delegate method m2c    to proj
    delegate method c2ref  to proj
    delegate method ref2c  to proj

    # w2c wx wy
    #
    # wx,wy    Position in window units
    #
    # Returns the position in canvas units

    method w2c {wx wy} {
        list [$hull canvasx $wx] [$hull canvasy $wy]
    }

    # w2m wx wy
    #
    # wx,wy    Position in window units
    #
    # Returns the position in map units

    method w2m {wx wy} {
        $proj c2m [$hull canvasx $wx] [$hull canvasy $wy]
    }

    # w2ref wx wy
    #
    # wx,wy    Position in window units
    #
    # Returns the position as a map reference

    method w2ref {wx wy} {
        $proj c2ref [$hull canvasx $wx] [$hull canvasy $wy]
    }

    #-------------------------------------------------------------------
    # Icon Management

    # icon create icontype mappoint options...
    #
    # icontype    Name of a registered icon type
    # mappoint    Location in map coordinates/map ref
    # options...  Depends on icon type
    #
    # Creates an icon at the specified location, with the specified
    # options.  The option types are icontype-specific.
    #
    # The mappoint can be specified as a mapref or as "mx my"; the
    # latter can be passed as one or two arguments.
    #
    # Returns the new icon's ID, which will be the first tag on the icon.

    method {icon create} {icontype args} {
        # FIRST, check args
        if {[llength $args] < 1} {
            WrongNumArgs "icon create icontype mappoint options..."
        }

        if {![info exists icontypes(type-$icontype)]} {
            error "Unknown icon type: \"$icontype\""
        }

        # NEXT, get the map coordinates.
        lassign [$self GetMapPoint args] mx my

        # NEXT, Convert the map coords to canvas coords, and create
        # the icon, given the options.
        
        lassign [$self m2c $mx $my] cx cy

        set id "$icontype[incr info(iconCounter)]"
        set cmd  ${selfns}::icons::$id

        # Allow option errors to propagate to the user
        $icontypes(type-$icontype) $cmd $self $cx $cy {*}$args

        # NEXT, mark it as an icon
        $hull addtag icon withtag $id

        # NEXT, save the icon's name and current data.
        lappend icons(ids)           $id
        lappend icons(id-$icontype)  $id

        set icons(icon-$id) [dict create                  \
                                 id       $id             \
                                 icontype $icontype       \
                                 cmd      $cmd            \
                                 mxy      [list $mx $my]]

        # NEXT, return the icon ID
        return $id
    }

    # icon ref id
    #
    # id   An icon id
    #
    # Returns the location of the icon as a map reference

    method {icon ref} {id} {
        $self m2ref {*}[dict get $icons(icon-$id) mxy]
    }

    # icon moveto id mappoint
    #
    # id          An icon id
    # mappoint    A location in map units or mapref, as for icon create

    method {icon moveto} {id args} {
        # FIRST, validate the arguments
        if {[llength $args] < 1} {
            WrongNumArgs "icon moveto id mappoint"
        }

        lassign [$self GetMapPoint args] mx2 my2

        if {[llength $args] > 0} {
            WrongNumArgs "icon moveto id mappoint"
        }

        # NEXT, move the icon to the new location.  We need to compute
        # the delta.
        lassign [dict get $icons(icon-$id) mxy] mx1 my1

        lassign [$win m2c $mx1 $my1] cx1 cy1
        lassign [$win m2c $mx2 $my2] cx2 cy2

        set dx [expr {$cx2 - $cx1}]
        set dy [expr {$cy2 - $cy1}]

        $win move $id $dx $dy

        dict set icons(icon-$id) mxy [list $mx2 $my2]

        return
    }

    # GetMapPoint argvar
    #
    # argvar    Argument list variable
    #
    # Reads one map point from the specified list.  A map point can
    # be specified as a mapref, or as a coordinate pair in map units
    # passed as one or two arguments.

    method GetMapPoint {argvar} {
        upvar $argvar args

        set first [lshift args]

        if {[llength $first] == 1} {
            # If it's a double, get the next arg; otherwise, it's a ref.
            if {[string is double -strict $first]} {
                set mx $first
                set my [lshift args]
            } else {
                lassign [$self ref2m $first] mx my
            }
        } elseif {[llength $first] == 2} {
            # It's an mx my pair
            lassign $first mx my
        } else {
            error "invalid mappoint: \"$first\""
        }

        return [list $mx $my]
    }

    #-------------------------------------------------------------------
    # Utility Methods

    # CanSnap x1 y1 x2 y2
    #
    # x1,y1     A point
    # x2,y2     Another point
    #
    # Returns 1 if distance between the two points is within the snap
    # radius.

    method CanSnap {x1 y1 x2 y2} {
        expr {[Distance $x1 $y1 $x2 $y2] <= $options(-snapradius)}
    }

    # SnapToPoint cx cy
    #
    # cx,cy   A point in canvas coordinates
    #
    # Given a point cx,cy, tries to snap to a point within a radius.
    # Candidate points are points in the "coords" list of items 
    # tagged with "snaps".

    method SnapToPoint {cx cy} {
        set mindist [expr {2*$options(-snapradius)}]
        set minitem ""
        set nearest [list]

        set bbox [BoxAround $options(-snapradius) $cx $cy]

        foreach item [$hull find overlapping {*}$bbox] {
            set tags [$hull gettags $item]

            if {"snaps" ni $tags} {
                continue
            }
            
            foreach {sx sy} [$hull coords $item] {
                set dist [Distance $cx $cy $sx $sy]

                if {$dist < $mindist} {
                    set nearest [list $sx $sy]
                    set mindist $dist
                    set minitem [lindex $tags 0]
                }
            }
        }

        if {[llength $nearest] == 2} {
            return $nearest
        } else {
            return [list $cx $cy]
        }
    }

    #-------------------------------------------------------------------
    # Utility Procs

    # Distance x1 y1 x2 y2
    #
    # x1,y1    A point
    # x2,y2    Another point
    #
    # Computes the distance between the two points.

    proc Distance {x1 y1 x2 y2} {
        expr {sqrt(($x1-$x2)**2 + ($y1-$y2)**2)}
    }

    # BoxAround radius x y
    #
    # radius    a distance
    # x,y       a point
    #
    # Returns a bounding box {x1 y1 x2 y2} of the given radius around
    # the given point.
    proc BoxAround {radius x y} {
        set x1 [expr {$x - $radius}]
        set y1 [expr {$y - $radius}]
        set x2 [expr {$x + $radius}]
        set y2 [expr {$y + $radius}]

        list $x1 $y1 $x2 $y2
    }

    # WrongNumArgs methodsig
    #
    # methodsig    The method name and arg spec
    #
    # Outputs a WrongNumArgs method
    
    proc WrongNumArgs {methodsig} {
        return -code error "wrong \# args: should be \"$self $methodsig\""
    }

    # UndefinedMap
    #
    # Throws an error if called.

    proc UndefinedMap {args} {
        error "-map is undefined or \"clear\" has not been called"
    }
    
    # InBox x1 y1 x2 y2 x y
    #
    # x1,y1,x2,y2    Bounds of bounding box
    # x,y            A point
    #
    # Returns 1 if x,y is in the box
    
    proc InBox {x1 y1 x2 y2 x y} {
        expr {$x1 <= $x && $x2 >= $x && $y1 <= $y && $y2 >= $y}
    }
}
