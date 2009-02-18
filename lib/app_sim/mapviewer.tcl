#-----------------------------------------------------------------------
# TITLE:
#    mapviewer.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Map viewer widget
#
#    The mapviewer is a mapcanvas with addition tools and components.
#
#-----------------------------------------------------------------------

snit::widget mapviewer {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Create the button icons
        namespace eval ${type}::icon { }

        mkicon ${type}::icon::left_ptr {
            ......................
            ......................
            .....X................
            .....XX...............
            .....XXX..............
            .....XXXX.............
            .....XXXXX............
            .....XXXXXX...........
            .....XXXXXXX..........
            .....XXXXXXXX.........
            .....XXXXXXXXX........
            .....XXXXXXXXXX.......
            .....XXXXXXXXXXX......
            .....XXXXXXX..........
            .....XXX.XXXX.........
            .....XX..XXXX.........
            .....X....XXXX........
            ..........XXXX........
            ...........XXXX.......
            ...........XXXX.......
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }

        mkicon ${type}::icon::fleur {
            ...........X..........
            ..........XXX.........
            .........XXXXX........
            ........XXXXXXX.......
            .......XXXXXXXXX......
            ...........X..........
            .....X.....X.....X....
            ....XX.....X.....XX...
            ...XXX.....X.....XXX..
            ..XXXX.....X.....XXXX.
            .XXXXXXXXXXXXXXXXXXXXX
            ..XXXX.....X.....XXXX.
            ...XXX.....X.....XXX..
            ....XX.....X.....XX...
            .....X.....X.....X....
            ...........X..........
            .......XXXXXXXXX......
            ........XXXXXXX.......
            .........XXXXX........
            ..........XXX.........
            ...........X..........
            ......................
        } {
            .  trans
            X  #000000
        }

        mkicon ${type}::icon::crosshair {
            ......................
            ......................
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ......................
            ......................
            ..XXXXXX..XX..XXXXXX..
            ..XXXXXX..XX..XXXXXX..
            ......................
            ......................
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }

        mkicon ${type}::icon::draw_poly {
            ......................
            ......................
            .....XX...............
            .....X.XX.............
            .....X...XX...........
            .....X.....XX.........
            ....X........XX.......
            ....X..........XX.....
            ....X...........X.....
            ....X...........X.....
            ...X............X.....
            ...X............X.....
            ...X............X.....
            ...X............X.....
            ....X...........X.....
            ....X...........X.....
            ....X...........X.....
            ....X.........XXX.....
            .....X.....XXX........
            .....X..XXX...........
            .....XXX..............
            ......................
        } {
            .  trans
            X  #000000
        }

        mkicon ${type}::icon::fill_poly {
            ......................
            ......................
            .....XX...............
            .....XaXX.............
            .....XaaaXX...........
            .....XaaaaaXX.........
            ....XaaaaaaaaXX.......
            ....XaaaaaaaaaaXX.....
            ....XaaaaaaaaaaaX.....
            ....XaaaaaaaaaaaX.....
            ...XaaaaaaaaaaaaX.....
            ...XaaaaaaaaaaaaX.....
            ...XaaaaaaaaaaaaX.....
            ...XaaaaaaaaaaaaX.....
            ....XaaaaaaaaaaaX.....
            ....XaaaaaaaaaaaX.....
            ....XaaaaaaaaaaaX.....
            ....XaaaaaaaaaXXX.....
            .....XaaaaaXXX........
            .....XaaXXX...........
            .....XXX..............
            ......................
        } {
            .  trans
            X  #000000
            a  #FFFFFF
        }


        mkicon ${type}::icon::nbpoly {
            ......................
            .....XX...............
            .....X.XX.............
            .....X...XX...........
            .....X.....XX.........
            ....X........XX.......
            ....X..........XX.....
            ....X...........X.....
            ....X..X.....X..X.....
            ...X...XX....X..X.....
            ...X...X.X...X..X.....
            ...X...X..X..X..X.....
            ...X...X...X.X..X.....
            ....X..X....XX..X.....
            ....X..X.....X..X.....
            ....X...........X.....
            ....X.........XXX.....
            .....X.....XXX........
            .....X..XXX...........
            .....XXX..............
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }


        mkicon ${type}::icon::extend {
            ......................
            .,,,,,,x-------------.
            .,,,xxx--------------.
            .,,x-----------^-----.
            .,,x----------^-^----.
            .,,,xx-------^-------.
            .,,,,,xx----^-^--^---.
            .,,,,,,,x-------^-^--.
            .,,,,,,x-----^-------.
            .,,,,,x-----^-^------.
            .,,,,x---------------.
            .,,,x-----------,,---.
            .,,,,xxx-------,,,,--.
            .,,,,,,x--------,,---.
            .,,,,xx--------------.
            .aaaaaaaaaaaaaaaaaaaa.
            .aaaaaaaaaaaaaaaaaaaa.
            .aaaaaaaaaaaaaaaaaaaa.
            .aaaaaaaaaaaaaaaaaaaa.
            .aaaaaaaaaaaaaaaaaaaa.
            .aaaaaaaaaaaaaaaaaaaa.
            ......................
        } {
            .  trans
            X  #000000
            a  #FFFFFF
            x  #000000
            ,  #00CCCC
            ^  #660000
            -  #FFCC33
        }
    }


    #-------------------------------------------------------------------
    # Options

    delegate option *    to hull
    
    #-------------------------------------------------------------------
    # Components

    component canvas           ;# The mapcanvas(n)

    #-------------------------------------------------------------------
    # Instance Variables

    # Info array; used for most scalars
    #
    #    mode           The current mapcanvas(n) mode
    #    ordertags      List of parameter type tags, if an order is
    #                   being entered and the current field has tags.
    #    ref            The current map reference

    variable info -array {
        mode      ""
        ordertags {}
        ref       ""
    }

    # View array; used for values that control the view
    #
    #    fillpoly       1 if polygons should be filled, and 0 otherwise.
    #    region         normal | extended
    #    zoom           Current zoom factor show in the zoombox

    variable view -array {
        fillpoly 0
        region   normal
        zoom     "100%"
    }

    # nbhoods array: 
    #
    #     $id is canvas nbhood ID
    #     $n  is "n" column from nbhoods table.
    #
    # n-$id      n, given ID
    # id-$n      id, given n
    # trans      Transient $n, used in event bindings

    variable nbhoods -array { }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Configure the hull's appearance.
        
        $hull configure    \
            -borderwidth 0 \
            -relief flat

        # NEXT, create the components.

        # ScrolledWindow to contain the canvas
        ScrolledWindow $win.mapsw \
            -borderwidth 0        \
            -relief      flat     \
            -auto        none

        # Map canvas
        install canvas using mapcanvas $win.mapsw.canvas \
            -background     white                        \
            -modevariable   [myvar info(mode)]           \
            -refvariable    [myvar info(ref)]

        $win.mapsw setwidget $canvas

        # Horizontal tool bar
        frame $win.hbar \
            -relief flat

        ComboBox $win.hbar.zoombox \
            -textvariable [myvar view(zoom)]                           \
            -font          codefont                                    \
            -editable      0                                           \
            -width         4                                           \
            -justify       right                                       \
            -values        {25% 50% 75% 100% 125% 150% 200% 250% 300%} \
            -takefocus     no                                          \
            -modifycmd     [mymethod ZoomBoxSet]

        DynamicHelp::add $win.hbar.zoombox \
            -text "Select zoom factor for the map display"

        label $win.hbar.ref \
            -textvariable [myvar info(ref)] \
            -width 8

        checkbutton $win.hbar.fillpoly              \
            -indicatoron no                         \
            -offrelief   flat                       \
            -variable    [myvar view(fillpoly)]     \
            -image       ${type}::icon::fill_poly   \
            -command     [mymethod ButtonFillPoly]

        DynamicHelp::add $win.hbar.fillpoly \
            -text "Display neighborhood polygons with an opaque fill"

        checkbutton $win.hbar.extend                \
            -indicatoron no                         \
            -offrelief   flat                       \
            -onvalue     extended                   \
            -offvalue    normal                     \
            -variable    [myvar view(region)]       \
            -image       ${type}::icon::extend      \
            -command     [mymethod ButtonExtend]

        DynamicHelp::add $win.hbar.extend \
            -text "Enable the extended scroll region"

        pack $win.hbar.zoombox  -side right
        pack $win.hbar.fillpoly -side right
        pack $win.hbar.extend   -side right
        pack $win.hbar.ref      -side right

        # Separator
        frame $win.sep -height 2 -relief sunken -borderwidth 2

        # Vertical tool bar
        frame $win.vbar -relief flat

        $self AddModeTool browse left_ptr   "Browse tool"
        $self AddModeTool pan    fleur      "Pan tool"
        $self AddModeTool point  crosshair  "Point tool"
        $self AddModeTool poly   draw_poly  "Draw Polygon tool"

        # TBD: Really need separator
        button $win.vbar.nbhood                          \
            -relief  flat                                \
            -image   ${type}::icon::nbpoly               \
            -command [list order enter NBHOOD:CREATE]
        DynamicHelp::add $win.vbar.nbhood -text "Create Neighborhood"

        pack $win.vbar.nbhood -side top -fill x -padx 2

        # Pack all of these components
        pack $win.hbar  -side top  -fill x
        pack $win.sep   -side top  -fill x
        pack $win.vbar  -side left -fill y 
        pack $win.mapsw            -fill both -expand yes

        # NEXT, process the arguments
        $self configurelist $args

        # NEXT, draw everything for the current map, whatever it is.
        $self refresh

        # NEXT, Forward virtual events from the canvas to the application.
        $self ForwardVirtual <<Icon-1>>

        # NEXT, Translate events for the application
        bind $canvas <<Nbhood-1>>     [mymethod Nbhood-1 %d]

        # NEXT, Support order processing.  This will set the viewer mode
        # to support the currently edited order field.
        notifier bind ::order <OrderEntry> $self [mymethod OrderEntry]

        bind $canvas <<Point-1>>      [mymethod Point-1 %d]
        bind $canvas <<PolyComplete>> [mymethod PolyComplete %d]

        # NEXT, Support model updates
        notifier bind ::scenario <Reconfigure>   $self [mymethod refresh]
        notifier bind ::map      <MapChanged>    $self [mymethod refresh]
        notifier bind ::nbhood   <Entity>        $self [mymethod Nbhood]

        # NEXT, create popup menus
        set mnu [menu $canvas.nbhoodmenu]

        $mnu add command \
            -label   "Bring to Front" \
            -command [mymethod BringToFront]

        $mnu add command \
            -label   "Send to Back" \
            -command [mymethod SendToBack]

        bind $canvas <<Nbhood-3>> [mymethod Nbhood-3 %d %X %Y]
    }

    destructor {
        notifier forget $self
    }

    # AddModeTool mode icon tooltip
    #
    # mode       The mapcanvas(n) mode name
    # icon       The icon to display on the button
    # tooltip    Dynamic help string

    method AddModeTool {mode icon tooltip} {
        radiobutton $win.vbar.$mode                \
            -indicatoron no                        \
            -offrelief   flat                      \
            -variable    [myvar info(mode)]        \
            -image       ${type}::icon::$icon      \
            -value       $mode                     \
            -command     [list $canvas mode $mode]

        pack $win.vbar.$mode -side top -fill x -padx 2

        DynamicHelp::add $win.vbar.$mode -text $tooltip
    }

    # ForwardVirtual event
    #
    # virtualEvent    A virtual event name
    #
    # Forwards virtual events from the $canvas to $win

    method ForwardVirtual {event} {
        bind $canvas $event \
            [list event generate $win $event -x %x -y %y -data %d]
    }

    #===================================================================
    # Event Handlers

    #-------------------------------------------------------------------
    # Neighborhood Events

    # Nbhood-1 id
    #
    # id      A nbhood canvas ID
    #
    # Called when the user clicks on a nbhood.  First, support pucking 
    # of neighborhoods into orders.  Next, translate it to a 
    # neighborhood ID and forward.

    method Nbhood-1 {id} {
        notifier send ::app <ObjectSelect> [list nbhood $nbhoods(n-$id)]

        event generate $win <<Nbhood-1>> -data $nbhoods(n-$id)
    }
    
    # Nbhood-3 id rx ry
    #
    # id      A nbhood canvas ID
    # rx,ry   Root window coordinates
    #
    # Called when the user right-clicks on a nbhood.  Pops up the
    # neighborhood context menu.

    method Nbhood-3 {id rx ry} {
        set nbhoods(trans) $nbhoods(n-$id)

        tk_popup $canvas.nbhoodmenu $rx $ry
    }

    # BringToFront
    #
    # Brings the transient neighborhood to the front

    method BringToFront {} {
        order send gui NBHOOD:RAISE [list n $nbhoods(trans)]
    }

    # SendToBack
    #
    # Sends the transient neighborhood to the back

    method SendToBack {} {
        order send gui NBHOOD:LOWER [list n $nbhoods(trans)]
    }

    #-------------------------------------------------------------------
    # Order Handling

    # OrderEntry tags
    #
    # tags   The tags for the current order field.
    #
    # Detects when we are in order entry mode and when we are not.
    #
    # On leaving order entry mode the transient graphics are deleted.
    #
    # In addition, in order entry mode this sets the viewer to the 
    # appropriate mode for the parameter type. 
    #
    # TBD: In the long run, certain modes shouldn't be allowed in order
    # entry mode.  But unfortunately, pan mode can't be one of them.

    method OrderEntry {tags} {
        # FIRST, handle entering and leaving order entry mode
        if {$tags eq "" && $info(ordertags) ne ""} {
            $canvas delete transient
        }

        set info(ordertags) $tags

        # NEXT, set the mode according to the first tag
        switch -exact -- [lindex $info(ordertags) 0] {
            point   { $self mode point  }
            polygon { $self mode poly   }
            default { $self mode browse }
        }
    }

    # Point-1 ref
    #
    # ref     A map reference string
    #
    # The user has pucked a point in point mode.  If there's an active 
    # order dialog, and the current field type is appropriate, set the 
    # field's value to this point.  Otherwise, propagate the event.

    method Point-1 {ref} {
        if {"point" in $info(ordertags)} {
            # FIRST, plot a point; mark existing points as old.
            $canvas itemconfigure {transient&&point} -fill blue

            lassign [$canvas ref2c $ref] cx cy
                
            $canvas create oval [boxaround 3.0 $cx $cy] \
                -outline blue                           \
                -fill    cyan                           \
                -tags    [list transient point]

            # NEXT, notify the app that a point has been selected.
            notifier send ::app <ObjectSelect> [list point $ref]
        } else {
            event generate $win <<Point-1>> -data $ref
        }
    }

    # PolyComplete poly
    #
    # poly     A list of map references defining a polygon
    #
    # The user has drawn a polygon on the map.  If there's an active 
    # order dialog, and the current field type is appropriate, set the 
    # field's value to the polygon coordinates.  Otherwise, propagate 
    # the event.

    method PolyComplete {poly} {
        if {"polygon" in $info(ordertags)} {
            # FIRST, delete existing polygons, and plot the new one.
            $canvas itemconfigure {transient&&polygon} -outline blue

            $canvas create polygon [$canvas ref2c {*}$poly] \
                -outline cyan                               \
                -fill    ""                                 \
                -tags    [list transient polygon]

            # NEXT, notify the app that a polygon has been selected.
            notifier send ::app <ObjectSelect> [list polygon $poly]
        } else {
            event generate $win <<PolyComplete>> -data $poly
        }
    }

    #-------------------------------------------------------------------
    # Entity Updates

    # Nbhood create n
    #
    # n     The neighborhood ID
    #
    # There's a new neighborhood; display it.

    method {Nbhood create} {n} {
        # FIRST, get the nbhood data we care about
        rdb eval {SELECT refpoint, polygon FROM nbhoods WHERE n=$n} {}

        # NEXT, draw it; this will delete any previous neighborhood
        # with the same name.
        $self NbhoodDraw $n $refpoint $polygon

        # NEXT, show refpoints obscured by the change
        $self NbhoodShowObscured
    }

    # Nbhood delete n
    #
    # n     The neighborhood ID
    #
    # Delete the neighborhood from the mapcanvas.

    method {Nbhood delete} {n} {
        # FIRST, delete it from the canvas
        $canvas nbhood delete $nbhoods(id-$n)

        # NEXT, delete it from the mapviewer's data.
        set id $nbhoods(id-$n)
        unset nbhoods(n-$id)
        unset nbhoods(id-$n)

        # NEXT, show refpoints revealed by the change
        $self NbhoodShowObscured
    }
      
    # Nbhood update n
    #
    # n     The neighborhood ID
    #
    # Something changed about neighborhood n.  Update it.

    method {Nbhood update} {n} {
        # FIRST, get the nbhood data we care about
        rdb eval {SELECT refpoint, polygon FROM nbhoods WHERE n=$n} {}

        # NEXT, update the refpoint and polygon
        $canvas nbhood point $nbhoods(id-$n)   $refpoint
        $canvas nbhood polygon $nbhoods(id-$n) $polygon

        # NEXT, show refpoints obscured by the change
        $self NbhoodShowObscured
    }

    # Nbhood stack
    #
    # The neighborhood stacking order has changed; redraw all
    # neighborhoods

    method {Nbhood stack} {} {
        # TBD: This could be optimized to just raise and lower the
        # existing nbhoods; but this is simple and appears to be
        # fast enough.
        $self NbhoodDrawAll
    }

    #-------------------------------------------------------------------
    # FillPoly
    

    # ButtonFillPoly
    #
    # Fills/unfills the neighborhood polygons

    method ButtonFillPoly {} {
        $self NbhoodFill
    }

    #-------------------------------------------------------------------
    # Extend

    # ButtonExtend
    #
    # Sets the scrollregion to the full 1000x1000 area

    method ButtonExtend {} {
        $canvas region $view(region)
    }



    #-------------------------------------------------------------------
    # Zoom Box
    
    # ZoomBoxSet
    #
    # Sets the map zoom to the specified amount.

    method ZoomBoxSet {} {
        scan $view(zoom) "%d" factor
        $canvas zoom $factor
    }

    #===================================================================
    # Public Methods

    delegate method * to canvas

    # refresh
    #
    # Clears the map; and redraws the scenario features

    method refresh {} {
        # FIRST, get the current map and projection
        $canvas configure -map        [map image]
        $canvas configure -projection [map projection]

        # NEXT, clear the canvas
        $canvas clear

        # NEXT, clear all remembered state, and redraw everything
        $self NbhoodDrawAll

        # NEXT, create icons
        # TBD: Ultimately, this will query the RDB; for now, 
        # just make some icons.

        # Get the bounding box, so we can position things
        # randomly within it.
        lassign [map box] x1 y1 x2 y2

        foreach icontype [mapcanvas icon types] {
            for {set i 0} {$i < 20} {incr i} {
                set mx [expr {$x1 + rand()*($x2 - $x1)}]
                set my [expr {$y1 + rand()*($y2 - $y1)}]
                
                $canvas icon create $icontype $mx $my
            }
        }

        set info(zoom)   "[$canvas zoom]%"
        set info(region) [$canvas region]
    }

    # NbhoodDrawAll
    #
    # Clears and redraws all neighborhoods

    method NbhoodDrawAll {} {
        array unset nbhoods

        # NEXT, add neighborhoods
        rdb eval {
            SELECT n, refpoint, polygon 
            FROM nbhoods
            ORDER BY stacking_order
        } {
            $self NbhoodDraw $n $refpoint $polygon
        }

        # NEXT, reveal obscured refpoints
        $self NbhoodShowObscured

        # NEXT, fill them, or not.
        $self NbhoodFill
    }

    # NbhoodDraw n refpoint polygon
    #
    # n          The neighborhood ID
    # refpoint   The neighborhood's reference point
    # polygon    The neighborhood's polygon

    method NbhoodDraw {n refpoint polygon} {
        # FIRST, if there's an existing neighborhood called this,
        # delete it.
        if {[info exists nbhoods(id-$n)]} {
            $canvas nbhood delete $nbhoods(id-$n)
            unset nbhoods(id-$n)
        }

        # NEXT, draw it.
        set id [$canvas nbhood create $refpoint $polygon]

        # NEXT, save the name by the ID.
        set nbhoods(n-$id) $n
        set nbhoods(id-$n) $id
    }

    # NbhoodFill
    #
    # Fills the neighborhood polygons according to the current
    # FillPoly setting

    method NbhoodFill {} {
        if {$view(fillpoly)} {
            set fill white
        } else {
            set fill ""
        }

        foreach id [$canvas nbhood ids] {
            $canvas nbhood configure $id -fill $fill
        }
    }

    # NbhoodShowObscured
    #
    # Shows the obscured status of each neighborhood by lighting
    # up the refpoint.

    method NbhoodShowObscured {} {
        rdb eval {
            SELECT n,obscured_by FROM nbhoods
        } {
            if {$obscured_by ne ""} {
                $canvas nbhood configure $nbhoods(id-$n) -pointcolor red
            } else {
                $canvas nbhood configure $nbhoods(id-$n) -pointcolor black
            }
        }
    }
    

    # nbhood configure n option value...
    #
    # n    A neighborhood name
    #
    # Configures the neighborhood polygon in the mapcanvas given
    # the neighborhood name, rather than the canvas ID

    method {nbhood configure} {n args} {
        $canvas nbhood configure $nbhoods(id-$n) {*}$args
    }

    # nbhood cget n option
    #
    # n       A neighborhood name
    # option  An option name
    #
    # Retrieves the option's value for the neighborhood given 
    # the neighborhood name, rather than the canvas ID

    method {nbhood cget} {n option} {
        $canvas nbhood cget $nbhoods(id-$n) $option
    }

}








