#-----------------------------------------------------------------------
# TITLE:
#    mapviewer.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mapviewer(sim): athena_sim(1) Map viewer widget
#
#    The mapviewer uses a mapcanvas(n) widget to display a map, and
#    neighborhood polygons and icons upon that map.  Its purpose is 
#    to wrap up all of the application-specific details of interacting
#    with the map.
#
# OUTLINE:
#    This is a large and complex file; the following outline may prove
#    useful.
#
#      I. General Behavior
#         A. Button Icon Definitions
#         B. Widget Options
#         C. Widget Components
#         D. Instance Variables
#         E. Constructor
#         F. Event Handlers: Tool Buttons
#         G. Event Handlers: Order Entry 
#         H. Public Methods
#     II. Neighborhood Display and Behavior
#         A. Instance Variables
#         B. Neighborhood Display
#         C. Context Menu
#         D. Event Handlers: mapcanvas(n)
#         E. Event Handlers: notifier(n)
#         F. Public Methods
#    III. Icon Display and Behavior
#         A. Instance Variables
#         B. Helper Routines
#         C. Event Handlers: mapcanvas(n)
#     IV. Unit Display and Behavior
#         A. Unit Display
#         B. Context Menu
#         C. Event Handlers: notifier(n)
#         D. Public Methods
#     V.  Envsit Display and Behavior
#         A. Envsit Display
#         B. Context Menu
#         C. Event Handlers: notifier(n)
#         D. Public Methods
#
#-----------------------------------------------------------------------

snit::widget mapviewer {
    #===================================================================
    # General Behavior

    #-------------------------------------------------------------------
    # Button Icon Definitions

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


        mkicon ${type}::icon::newunit {
            ......................
            ......................
            ......................
            ......................
            .XXXXXXXXXXXXXXXXXXX..
            .X.................X..
            .X.................X..
            .X.................X..
            .X.....X....X......X..
            .X.....X....X......X..
            .X.....X....X......X..
            .X.....X....X......X..
            .X.....X....X......X..
            .X.....X....X......X..
            .X......XXXX.......X..
            .X.................X..
            .X.................X..
            .X.................X..
            .XXXXXXXXXXXXXXXXXXX..
            ......................
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }


        mkicon ${type}::icon::envpoly {
            ......................
            .....XX...............
            .....X.XX.............
            .....X...XX...........
            .....X.....XX.........
            ....X........XX.......
            ....X..........XX.....
            ....X...........X.....
            ....X..XXXXXXX..X.....
            ...X...X........X.....
            ...X...X........X.....
            ...X...XXXXX....X.....
            ...X...X........X.....
            ....X..X........X.....
            ....X..XXXXXXX..X.....
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
    # Widget Options

    # All options are delegated to the mapcanvas(n).
    delegate option * to hull
    
    #-------------------------------------------------------------------
    # Widget Components

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
        cond::orderIsValid control \
            [button $win.vbar.nbhood                          \
                 -relief  flat                                \
                 -image   ${type}::icon::nbpoly               \
                 -command [list order enter NBHOOD:CREATE]]   \
            order NBHOOD:CREATE

        DynamicHelp::add $win.vbar.nbhood \
            -text [order title NBHOOD:CREATE]

        pack $win.vbar.nbhood -side top -fill x -padx 2

        cond::orderIsValid control \
            [button $win.vbar.newunit                         \
                 -relief  flat                                \
                 -image   ${type}::icon::newunit              \
                 -command [list order enter UNIT:CREATE]]     \
            order UNIT:CREATE

        DynamicHelp::add $win.vbar.newunit \
            -text [order title UNIT:CREATE]

        cond::orderIsValid control \
            [button $win.vbar.newenvsit                                     \
                 -relief  flat                                              \
                 -image   ${type}::icon::envpoly                            \
                 -command [list order enter SITUATION:ENVIRONMENTAL:CREATE]] \
            order SITUATION:ENVIRONMENTAL:CREATE

        DynamicHelp::add $win.vbar.newenvsit \
            -text [order title SITUATION:ENVIRONMENTAL:CREATE]

        pack $win.vbar.nbhood    -side top -fill x -padx 2
        pack $win.vbar.newunit   -side top -fill x -padx 2
        pack $win.vbar.newenvsit -side top -fill x -padx 2

        # Pack all of these components
        pack $win.hbar  -side top  -fill x
        pack $win.sep   -side top  -fill x
        pack $win.vbar  -side left -fill y 
        pack $win.mapsw            -fill both -expand yes

        # NEXT, Create the context menus
        $self CreateNbhoodContextMenu
        $self CreateUnitContextMenu
        $self CreateEnvsitContextMenu

        # NEXT, process the arguments
        $self configurelist $args

        # NEXT, Subscribe to mapcanvas(n) events.
        bind $canvas <<Icon-1>>       [mymethod Icon-1 %d]
        bind $canvas <<Icon-3>>       [mymethod Icon-3 %d %X %Y]
        bind $canvas <<IconMoved>>    [mymethod IconMoved %d]
        bind $canvas <<Nbhood-1>>     [mymethod Nbhood-1 %d]
        bind $canvas <<Nbhood-3>>     [mymethod Nbhood-3 %d %X %Y %x %y]
        bind $canvas <<Point-1>>      [mymethod Point-1 %d]
        bind $canvas <<PolyComplete>> [mymethod PolyComplete %d]

        # NEXT, Subscribe to application notifier(n) events.
        notifier bind ::sim      <Reconfigure> $self [mymethod refresh]
        notifier bind ::map      <MapChanged>  $self [mymethod refresh]
        notifier bind ::order    <OrderEntry>  $self [mymethod OrderEntry]
        notifier bind ::nbhood   <Entity>      $self [mymethod EntityNbhood]
        notifier bind ::unit     <Entity>      $self [mymethod EntityUnit]
        notifier bind ::envsit   <Entity>      $self [mymethod EntityEnvsit]
        notifier bind ::frcgroup <Entity>      $self [mymethod EntityGroup]
        notifier bind ::orggroup <Entity>      $self [mymethod EntityGroup]

        # NEXT, draw everything for the current map, whatever it is.
        $self refresh
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

    #-------------------------------------------------------------------
    # Event Handlers: Tool Buttons

    # ZoomBoxSet
    #
    # Sets the map zoom to the specified amount.

    method ZoomBoxSet {} {
        scan $view(zoom) "%d" factor
        $canvas zoom $factor
    }

    # ButtonFillPoly
    #
    # Fills/unfills the neighborhood polygons

    method ButtonFillPoly {} {
        $self NbhoodFill
    }

    # ButtonExtend
    #
    # Sets the scrollregion to the full 1000x1000 area

    method ButtonExtend {} {
        $canvas region $view(region)
    }

    #-------------------------------------------------------------------
    # Event Handlers: Order Entry

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
    # Public Methods: General

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
        $self IconDeleteAll

        # NEXT, clear all remembered state, and redraw everything
        $self NbhoodDrawAll
        $self UnitDrawAll
        $self EnvsitDrawAll

        # NEXT, set zoom and region
        set view(zoom)   "[$canvas zoom]%"
        set view(region) [$canvas region]
    }


    #===================================================================
    # Neighborhood Display and Behavior
    #
    # The mapcanvas(n) has a basic ability to display neighborhoods. 
    # This section of mapviewer(n) provides the glue between the 
    # mapcanvas(n) and the remainder of the application.

    #-------------------------------------------------------------------
    # Neighborhood Instance Variables

    # nbhoods array:  maps between neighborhood names and canvas IDs.
    #
    #     $id is canvas nbhood ID
    #     $n  is "n" column from nbhoods table.
    #
    # n-$id      n, given ID
    # id-$n      id, given n
    # trans      Transient $n, used in event bindings
    # transref   Transient mapref, used in event bindings

    variable nbhoods -array { }


    #-------------------------------------------------------------------
    # Neighborhood Display

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

        # NEXT, fill it if necessary.
        if {$view(fillpoly)} {
            $canvas nbhood configure $id -fill white
        }

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

    #-------------------------------------------------------------------
    # Neighborhood Context Menu

    # CreateNbhoodContextMenu
    #
    # Creates the context menu

    method CreateNbhoodContextMenu {} {
        set mnu [menu $canvas.nbhoodmenu]

        cond::orderIsValid control \
            [menuitem $mnu command "Create Unit"           \
                 -command [mymethod NbhoodCreateUnitHere]] \
            order UNIT:CREATE
        
        cond::orderIsValid control \
            [menuitem $mnu command "Create Environmental Situation" \
                 -command [mymethod NbhoodCreateEnvsitHere]]        \
            order SITUATION:ENVIRONMENTAL:CREATE

        $mnu add separator

        cond::orderIsValid control \
            [menuitem $mnu command "Bring to Front"      \
                 -command [mymethod NbhoodBringToFront]] \
            order NBHOOD:RAISE

        cond::orderIsValid control \
            [menuitem $mnu command "Send to Back"        \
                 -command [mymethod NbhoodSendToBack]]   \
            order NBHOOD:LOWER
    }


    # NbhoodCreateUnitHere
    #
    # Pops up the create unit dialog with this location filled in.

    method NbhoodCreateUnitHere {} {
        order enter UNIT:CREATE location $nbhoods(transref)
    }


    # NbhoodCreateEnvsitHere
    #
    # Pops up the create envsit dialog with this location filled in.

    method NbhoodCreateEnvsitHere {} {
        order enter SITUATION:ENVIRONMENTAL:CREATE location $nbhoods(transref)
    }


    # NbhoodBringToFront
    #
    # Brings the transient neighborhood to the front

    method NbhoodBringToFront {} {
        order send gui NBHOOD:RAISE [list n $nbhoods(trans)]
    }


    # NbhoodSendToBack
    #
    # Sends the transient neighborhood to the back

    method NbhoodSendToBack {} {
        order send gui NBHOOD:LOWER [list n $nbhoods(trans)]
    }

    #-------------------------------------------------------------------
    # Event Handlers: mapcanvas(n)

    # Nbhood-1 id
    #
    # id      A nbhood canvas ID
    #
    # Called when the user clicks on a nbhood.  First, support pucking 
    # of neighborhoods into orders.  Next, translate it to a 
    # neighborhood ID and forward for use by the containing appwin(sim).

    method Nbhood-1 {id} {
        notifier send ::app <ObjectSelect> [list nbhood $nbhoods(n-$id)]

        event generate $win <<Nbhood-1>> -data $nbhoods(n-$id)
    }

    
    # Nbhood-3 id rx ry wx wy
    #
    # id      A nbhood canvas ID
    # rx,ry   Root window coordinates
    #
    # Called when the user right-clicks on a nbhood.  Pops up the
    # neighborhood context menu.

    method Nbhood-3 {id rx ry wx wy} {
        set nbhoods(trans)    $nbhoods(n-$id)
        set nbhoods(transref) [$canvas w2ref $wx $wy]

        tk_popup $canvas.nbhoodmenu $rx $ry
    }


    #-------------------------------------------------------------------
    # Event Handlers: notifier(n)

    # EntityNbhood create n
    #
    # n     The neighborhood ID
    #
    # There's a new neighborhood; display it.

    method {EntityNbhood create} {n} {
        # FIRST, get the nbhood data we care about
        rdb eval {SELECT refpoint, polygon FROM nbhoods WHERE n=$n} {}

        # NEXT, draw it; this will delete any previous neighborhood
        # with the same name.
        $self NbhoodDraw $n $refpoint $polygon

        # NEXT, show refpoints obscured by the change
        $self NbhoodShowObscured
    }


    # EntityNbhood delete n
    #
    # n     The neighborhood ID
    #
    # Delete the neighborhood from the mapcanvas.

    method {EntityNbhood delete} {n} {
        # FIRST, delete it from the canvas
        $canvas nbhood delete $nbhoods(id-$n)

        # NEXT, delete it from the mapviewer's data.
        set id $nbhoods(id-$n)
        unset nbhoods(n-$id)
        unset nbhoods(id-$n)

        # NEXT, show refpoints revealed by the change
        $self NbhoodShowObscured
    }
      

    # EntityNbhood update n
    #
    # n     The neighborhood ID
    #
    # Something changed about neighborhood n.  Update it.

    method {EntityNbhood update} {n} {
        # FIRST, get the nbhood data we care about
        rdb eval {SELECT refpoint, polygon FROM nbhoods WHERE n=$n} {}

        # NEXT, update the refpoint and polygon
        $canvas nbhood point $nbhoods(id-$n)   $refpoint
        $canvas nbhood polygon $nbhoods(id-$n) $polygon

        # NEXT, show refpoints obscured by the change
        $self NbhoodShowObscured
    }


    # EntityNbhood stack
    #
    # The neighborhood stacking order has changed; redraw all
    # neighborhoods

    method {EntityNbhood stack} {} {
        # TBD: This could be optimized to just raise and lower the
        # existing nbhoods; but this is simple and appears to be
        # fast enough.
        $self NbhoodDrawAll
    }


    #-------------------------------------------------------------------
    # Public Methods: Neighborhoods

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



    #===================================================================
    # Icon Display and Behavior
    #
    # Eventually we will have many different kinds of icon: units,
    # situations, sites, etc.  This section covers the general 
    # behavior, including dispatch of mapcanvas(n) events to 
    # other sections.

    #-------------------------------------------------------------------
    # Instance Variables

    # icons array: 
    #
    #   $cid is canvas icon ID
    #   $sid is scenario ID:
    #        For units: "u" column from units table.
    #
    #   sid-$cid      sid, given cid
    #   cid-$sid      cid, given sid
    #   itype-$cid    Icon type, given cid
    #   context       Transient sid, using in context menu bindings
   
    variable icons -array { }

    #-------------------------------------------------------------------
    # Helper Routines

    method IconDeleteAll {} {
        # Deletes all icons, clears metadata
        array unset icons
        $canvas icon delete all
    }

    # IconDelete sid
    #
    # sid     An icon's scenario ID
    #
    # Deletes an icon given its scenario ID

    method IconDelete {sid} {
        # FIRST, delete it from the canvas
        set cid $icons(cid-$sid)
        $canvas icon delete $cid

        # NEXT, delete it from the mapviewer's data.
        unset icons(sid-$cid)
        unset icons(itype-$cid)
        unset icons(cid-$sid)
    }



    #-------------------------------------------------------------------
    # Event Handlers: mapcanvas(n)

    # Icon-1 cid
    #
    # cid      A canvas icon ID
    #
    # Called when the user clicks on an icon.  First, support pucking 
    # of icons into orders.  Next, translate it to a scenario ID
    # and forward as the appropriate kind of entity.

    method Icon-1 {cid} {
        notifier send ::app <ObjectSelect> \
            [list $icons(itype-$cid) $icons(sid-$cid)]

        set sid $icons(sid-$cid)

        switch $icons(itype-$cid) {
            unit      { event generate $win <<Unit-1>>   -data $sid }
            situation { event generate $win <<Envsit-1>> -data $sid }
        } 
    }

    
    # Icon-3 cid rx ry
    #
    # cid     A canvas icon ID
    # rx,ry   Root window coordinates
    #
    # Called when the user right-clicks on an icon.  Pops up the
    # icon context menu.

    method Icon-3 {cid rx ry} {
        switch -exact $icons(itype-$cid) {
            unit {
                set icons(context) $icons(sid-$cid)
                tk_popup $canvas.unitmenu $rx $ry
            }

            situation {
                set icons(context) $icons(sid-$cid)
                tk_popup $canvas.envsitmenu $rx $ry
            }
        }
    }


    # IconMoved cid
    #
    # cid    A canvas icon ID
    #
    # Called when the user drags an icon.  Moves the underlying
    # scenario object to the desired location.

    method IconMoved {cid} {
        switch -exact $icons(itype-$cid) {
            unit {
                if {[order isvalid UNIT:UPDATE]} {
                    order send gui UNIT:UPDATE           \
                        u $icons(sid-$cid)               \
                        location [$canvas icon ref $cid]
                } else {
                    $self UnitDrawSingle $icons(sid-$cid)
                }
            }

            situation {
                if {[catch {
                    order send gui SITUATION:ENVIRONMENTAL:UPDATE \
                        s        $icons(sid-$cid)                 \
                        location [$canvas icon ref $cid]
                }]} {
                    $self EnvsitDrawSingle $icons(sid-$cid)
                }
            }
        }
    }


    #===================================================================
    # Unit Display and Behavior

    #-------------------------------------------------------------------
    # Unit Display

    # UnitDrawAll
    #
    # Clears and redraws all units

    method UnitDrawAll {} {
        rdb eval {
            SELECT * FROM units JOIN groups USING (g)
        } row {
            $self UnitDraw [array get row]
        } 

    }

    # UnitDraw parmdict
    #
    # parmdict   Data about the unit

    method UnitDraw {parmdict} {
        dict with parmdict {
            # FIRST, if there's an existing unit called this,
            # delete it.
            if {[info exists icons(cid-$u)]} {
                $self IconDelete $u
            }

            # NEXT, draw it.
            set cid [$canvas icon create unit \
                         {*}$location         \
                         -foreground $color   \
                         -shape      $shape   \
                         -symbol     $symbol]
            
            # NEXT, save the name by the ID.
            set icons(itype-$cid) unit
            set icons(sid-$cid) $u
            set icons(cid-$u)   $cid
        }
    }

    # UnitDrawSingle u
    #
    # u    The name of the unit.
    #
    # Redraws just unit u.  Use this when only a single unit is
    # to be redrawn.

    method UnitDrawSingle {u} {
        rdb eval {
            SELECT * FROM units JOIN groups USING (g)
            WHERE u=$u
        } row {
            $self UnitDraw [array get row]
        } 
    }


    #-------------------------------------------------------------------
    # Unit Context Menu

    # CreateUnitContextMenu
    #
    # Creates the context menu

    method CreateUnitContextMenu {} {
        set mnu [menu $canvas.unitmenu]

        cond::orderIsValid control \
            [menuitem $mnu command "Update Unit" \
                 -command [mymethod UpdateUnit]] \
            order UNIT:UPDATE
    }

    # UpdateUnit
    #
    # Pops up the "Update Unit" dialog for this unit

    method UpdateUnit {} {
        order enter UNIT:UPDATE u $icons(context)
    }

    #-------------------------------------------------------------------
    # Event Handlers: notifier(n)

    # EntityUnit create u
    #
    # u     The unit ID
    #
    # There's a new unit; display it.

    method {EntityUnit create} {u} {
        $self EntityUnit update $u
    }


    # EntityUnit delete u
    #
    # u     The unit ID
    #
    # Delete the unit from the mapcanvas.

    method {EntityUnit delete} {u} {
        $self IconDelete $u
    }
      
    # EntityUnit update n
    #
    # n     The unit ID
    #
    # Something changed about unit n.  Update it.

    method {EntityUnit update} {u} {
        $self UnitDrawSingle $u
    }


    # EntityGroup create g
    #
    # g    The group ID
    #
    # A FRC or ORG group was created.  No-op.

    method {EntityGroup create} {g} { }


    # Group delete g
    #
    # g    The group ID
    #
    # A FRC or ORG group was deleted.  No-op.

    method {EntityGroup delete} {g} { }


    # EntityGroup update g
    #
    # g    The group ID
    #
    # A FRC or ORG group was updated.  This might have changed
    # the group's shape or symbol.  Redraw all units belonging to
    # the group.
    #
    # TBD: For now, redraw all units.

    method {EntityGroup update} {g} {
        $self UnitDrawAll 
    }

    #===================================================================
    # Envsit Display and Behavior

    #-------------------------------------------------------------------
    # Envsit Display

    # EnvsitDrawAll
    #
    # Clears and redraws all envsits

    method EnvsitDrawAll {} {
        rdb eval {
            SELECT * FROM envsits_live
        } row {
            $self EnvsitDraw [array get row]
        } 

    }

    # EnvsitDraw parmdict
    #
    # parmdict   Data about the envsit

    method EnvsitDraw {parmdict} {
        dict with parmdict {
            # FIRST, if there's an existing envsit called this,
            # delete it.
            if {[info exists icons(cid-$s)]} {
                $self IconDelete $s
            }

            # NEXT, draw it.
            set cid [$canvas icon create situation \
                         {*}$location              \
                         -text $stype]

            if {$state eq "INITIAL"} {
                $canvas icon configure $cid -background white
            } else {
                $canvas icon configure $cid -background yellow
            }
            
            # NEXT, save the name by the ID.
            set icons(itype-$cid) situation
            set icons(sid-$cid) $s
            set icons(cid-$s)   $cid
        }
    }

    # EnvsitDrawSingle s
    #
    # s    The ID of the envsit.
    #
    # Redraws just envsit s.  Use this when only a single envsit is
    # to be redrawn.

    method EnvsitDrawSingle {s} {
        rdb eval {
            SELECT * FROM envsits_live
            WHERE s=$s
        } row {
            $self EnvsitDraw [array get row]
        } 
    }


    #-------------------------------------------------------------------
    # Envsit Context Menu

    # CreateEnvsitContextMenu
    #
    # Creates the context menu

    method CreateEnvsitContextMenu {} {
        set mnu [menu $canvas.envsitmenu]

        cond::orderIsValid control \
            [menuitem $mnu command "Update Situation" \
                 -command [mymethod UpdateEnvsit]] \
            order SITUATION:ENVIRONMENTAL:UPDATE
    }

    # UpdateEnvsit
    #
    # Pops up the "Update Environmental Situation" dialog for this unit

    method UpdateEnvsit {} {
        order enter SITUATION:ENVIRONMENTAL:UPDATE s $icons(context)
    }

    #-------------------------------------------------------------------
    # Event Handlers: notifier(n)

    # EntityEnvsit create s
    #
    # s     The envsit ID
    #
    # There's a new envsit; display it.

    method {EntityEnvsit create} {s} {
        $self EntityEnvsit update $s
    }


    # EntityEnvsit delete s
    #
    # s     The envsit ID
    #
    # Delete the envsit from the mapcanvas.

    method {EntityEnvsit delete} {s} {
        $self IconDelete $s
    }
      
    # EntityEnvsit update s
    #
    # s     The envsit ID
    #
    # Something changed about envsit s.  Update it.

    method {EntityEnvsit update} {s} {
        $self EnvsitDrawSingle $s
    }
}

