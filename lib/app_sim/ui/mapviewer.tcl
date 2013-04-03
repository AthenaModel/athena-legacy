#------------------------------------------------------------------------
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
#     V.  Ensit Display and Behavior
#         A. Ensit Display
#         B. Context Menu
#         C. Event Handlers: notifier(n)
#         D. Public Methods
#    VI.  Group Entity Handlers
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
            X..........
            XX.........
            XXX........
            XXXX.......
            XXXXX......
            XXXXXX.....
            XXXXXXX....
            XXXXXXXX...
            XXXXXXXXX..
            XXXXXXXXXX.
            XXXXXXXXXXX
            XXXXXXX....
            XXX.XXXX...
            XX..XXXX...
            X....XXXX..
            .....XXXX..
            ......XXXX.
            ......XXXX.
        } { . trans  X black } d { X gray }

        mkicon ${type}::icon::fleur {
            ..........X..........
            .........XXX.........
            ........XXXXX........
            .......XXXXXXX.......
            ......XXXXXXXXX......
            ..........X..........
            ....X.....X.....X....
            ...XX.....X.....XX...
            ..XXX.....X.....XXX..
            .XXXX.....X.....XXXX.
            XXXXXXXXXXXXXXXXXXXXX
            .XXXX.....X.....XXXX.
            ..XXX.....X.....XXX..
            ...XX.....X.....XX...
            ....X.....X.....X....
            ..........X..........
            ......XXXXXXXXX......
            .......XXXXXXX.......
            ........XXXXX........
            .........XXX.........
            ..........X..........
        } { . trans  X black } d { X gray }

        mkicon ${type}::icon::crosshair {
            ........XX........
            ........XX........
            ........XX........
            ........XX........
            ........XX........
            ........XX........
            ..................
            ..................
            XXXXXX..XX..XXXXXX
            XXXXXX..XX..XXXXXX
            ..................
            ..................
            ........XX........
            ........XX........
            ........XX........
            ........XX........
            ........XX........
            ........XX........
        } { . trans  X black } d { X gray }

        mkicon ${type}::icon::draw_poly {
            ..XX..........
            ..X.XX........
            ..X...XX......
            ..X.....XX....
            .X........XX..
            .X..........XX
            .X...........X
            .X...........X
            X............X
            X............X
            X............X
            X............X
            .X...........X
            .X...........X
            .X...........X
            .X.........XXX
            ..X.....XXX...
            ..X..XXX......
            ..XXX.........
        } { . trans  X black } d { X gray }

        mkicon ${type}::icon::fill_poly {

            ..XX..........
            ..XaXX........
            ..XaaaXX......
            ..XaaaaaXX....
            .XaaaaaaaaXX..
            .XaaaaaaaaaaXX
            .XaaaaaaaaaaaX
            .XaaaaaaaaaaaX
            XaaaaaaaaaaaaX
            XaaaaaaaaaaaaX
            XaaaaaaaaaaaaX
            XaaaaaaaaaaaaX
            .XaaaaaaaaaaaX
            .XaaaaaaaaaaaX
            .XaaaaaaaaaaaX
            .XaaaaaaaaaXXX
            ..XaaaaaXXX...
            ..XaaXXX......
            ..XXX.........
        } {
            .  trans
            X  #000000
            a  #FFFFFF
        }


        mkicon ${type}::icon::nbpoly {
            ..XX..........
            ..X.XX........
            ..X...XX......
            ..X.....XX....
            .X........XX..
            .X..........XX
            .X...........X
            .X..X.....X..X
            X...XX....X..X
            X...X.X...X..X
            X...X..X..X..X
            X...X...X.X..X
            .X..X....XX..X
            .X..X.....X..X
            .X...........X
            .X.........XXX
            ..X.....XXX...
            ..X..XXX......
            ..XXX.........
        } { . trans  X black } d { X gray }

        mkicon ${type}::icon::newunit {
            XXXXXXXXXXXXXXXXXXX
            X.................X
            X.................X
            X.................X
            X.....X....X......X
            X.....X....X......X
            X.....X....X......X
            X.....X....X......X
            X.....X....X......X
            X.....X....X......X
            X......XXXX.......X
            X.................X
            X.................X
            X.................X
            XXXXXXXXXXXXXXXXXXX
        } { . trans  X black } d { X gray }


        mkicon ${type}::icon::envpoly {
            ..XX..........
            ..X.XX........
            ..X...XX......
            ..X.....XX....
            .X........XX..
            .X..........XX
            .X...........X
            .X..XXXXXXX..X
            X...X........X
            X...X........X
            X...XXXXX....X
            X...X........X
            .X..X........X
            .X..XXXXXXX..X
            .X...........X
            .X.........XXX
            ..X.....XXX...
            ..X..XXX......
            ..XXX.........
        } { . trans  X black } d { X gray }

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
    # Look-up tables

    # Default fill specs

    typevariable defaultFills {
        none
        nbmood
        pcf
    }

    #-------------------------------------------------------------------
    # Type Variables

    # Shared pick list info.
    #
    # recentFills    Recently selected fill tags
    # filltags       Current set of filltags for fillbox pulldown

    typevariable picklist -array {
        recentFills {}
        filltags    {}
    }

    #-------------------------------------------------------------------
    # Widget Options

    # All options are delegated to the mapcanvas(n).
    delegate option * to hull
    
    #-------------------------------------------------------------------
    # Widget Components

    component canvas           ;# The mapcanvas(n)
    component fillbox          ;# ComboBox of nbhood fill criteria

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
    #    filltag        Current fill tag (neighborhood variable)

    variable view -array {
        fillpoly     0
        filltag     none
        recentFills {}
        filltags    {}
        region      normal
        zoom        "100%"
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Configure the hull's appearance.
        $hull configure    \
            -borderwidth 0 \
            -relief flat

        # NEXT, create the components.

        # Frame to contain the canvas
        ttk::frame $win.mapsw

        # Map canvas
        install canvas using mapcanvas $win.mapsw.canvas  \
            -background     white                         \
            -modevariable   [myvar info(mode)]            \
            -refvariable    [myvar info(ref)]             \
            -xscrollcommand [list $win.mapsw.xscroll set] \
            -yscrollcommand [list $win.mapsw.yscroll set]

        ttk::scrollbar $win.mapsw.xscroll \
            -orient  horizontal           \
            -command [list $canvas xview]

        ttk::scrollbar $win.mapsw.yscroll \
            -command [list $canvas yview]

        grid columnconfigure $win.mapsw 0 -weight 1
        grid rowconfigure    $win.mapsw 0 -weight 1
        
        grid $win.mapsw.canvas  -row 0 -column 0 -sticky nsew
        grid $win.mapsw.yscroll -row 0 -column 1 -sticky ns
        grid $win.mapsw.xscroll -row 1 -column 0 -sticky ew

        # Horizontal tool bar
        ttk::frame $win.hbar

        # MapRef
        ttk::label $win.hbar.ref \
            -textvariable [myvar info(ref)] \
            -width        8

        # Extended scroll region toggle
        ttk::checkbutton $win.hbar.extend           \
            -style       Toolbutton                 \
            -onvalue     extended                   \
            -offvalue    normal                     \
            -variable    [myvar view(region)]       \
            -image       ${type}::icon::extend      \
            -command     [mymethod ButtonExtend]

        DynamicHelp::add $win.hbar.extend \
            -text "Enable the extended scroll region"

        # Nbhood fill toggle
        ttk::checkbutton $win.hbar.fillpoly         \
            -style       Toolbutton                 \
            -variable    [myvar view(fillpoly)]     \
            -image       ${type}::icon::fill_poly   \
            -command     [mymethod NbhoodFill]

        DynamicHelp::add $win.hbar.fillpoly \
            -text "Display neighborhood polygons with an opaque fill"

        # Nbhood fill criteria
        install fillbox using menubox $win.hbar.fillbox \
            -textvariable [myvar view(filltag)]         \
            -font          codefont                     \
            -width         16                           \
            -values        $defaultFills                \
            -postcommand   [mymethod FillBoxPost]       \
            -command       [mymethod NbhoodFill]

        DynamicHelp::add $win.hbar.fillbox \
            -text "Select the neighborhood fill criteria"

        # Zoom Box
        set factors [list]
        foreach factor [$canvas zoomfactors] {
            lappend factors "$factor%"
        }

        menubox $win.hbar.zoombox               \
            -textvariable [myvar view(zoom)]    \
            -font         codefont              \
            -width        4                     \
            -justify      right                 \
            -values       $factors              \
            -command      [mymethod ZoomBoxSet]

        DynamicHelp::add $win.hbar.zoombox \
            -text "Select zoom factor for the map display"

        pack $win.hbar.zoombox  -side right -padx {5 0}
        pack $win.hbar.fillbox  -side right
        pack $win.hbar.fillpoly -side right -padx 3
        pack $win.hbar.extend   -side right
        pack $win.hbar.ref      -side right

        # Separators
        ttk::separator $win.sep1
        ttk::separator $win.sep2 \
            -orient vertical

        # Vertical tool bar
        ttk::frame $win.vbar

        $self AddModeTool browse left_ptr   "Browse tool"
        $self AddModeTool pan    fleur      "Pan tool"
        $self AddModeTool point  crosshair  "Point tool"
        $self AddModeTool poly   draw_poly  "Draw Polygon tool"

        # Separator
        ttk::separator $win.vbar.sep

        cond::available control \
            [ttk::button $win.vbar.nbhood                       \
                 -style   Toolbutton                            \
                 -image   [list ${type}::icon::nbpoly           \
                               disabled ${type}::icon::nbpolyd] \
                 -command [list order enter NBHOOD:CREATE]]     \
            order NBHOOD:CREATE

        DynamicHelp::add $win.vbar.nbhood \
            -text [order title NBHOOD:CREATE]

        cond::available control \
            [ttk::button $win.vbar.newensit                                  \
                 -style   Toolbutton                                         \
                 -image   [list ${type}::icon::envpoly                       \
                               disabled ${type}::icon::envpolyd]             \
                 -command [list order enter ENSIT:CREATE]] \
            order ENSIT:CREATE

        DynamicHelp::add $win.vbar.newensit \
            -text [order title ENSIT:CREATE]

        pack $win.vbar.sep       -side top -fill x -pady 2
        pack $win.vbar.nbhood    -side top -fill x -padx 2
        pack $win.vbar.newensit  -side top -fill x -padx 2

        # Pack all of these components
        pack $win.hbar  -side top  -fill x
        pack $win.sep1  -side top  -fill x
        pack $win.vbar  -side left -fill y
        pack $win.sep2  -side left -fill y
        pack $win.mapsw            -fill both -expand yes

        # NEXT, Create the context menus
        $self CreateNbhoodContextMenu
        $self CreateEnsitContextMenu

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
        notifier bind ::sim      <DbSyncB>     $self [mymethod dbsync]
        notifier bind ::sim      <Tick>        $self [mymethod dbsync]
        notifier bind ::map      <MapChanged>  $self [mymethod dbsync]
        notifier bind ::order    <OrderEntry>  $self [mymethod OrderEntry]
        notifier bind ::rdb      <nbhoods>     $self [mymethod EntityNbhood]
        notifier bind ::nbhood   <Stack>       $self [mymethod NbhoodStack]
        notifier bind ::rdb      <units>       $self [mymethod EntityUnit]
        notifier bind ::rdb      <ensits>      $self [mymethod EntityEnsit]
        notifier bind ::rdb      <groups>      $self [mymethod EntityGroup]
        notifier bind ::rdb      <econ_n>      $self [mymethod EntityEcon]

        # NEXT, draw everything for the current map, whatever it is.
        $self dbsync
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
        ttk::radiobutton $win.vbar.$mode           \
            -style       Toolbutton                \
            -variable    [myvar info(mode)]        \
            -image       ${type}::icon::$icon      \
            -value       $mode                     \
            -command     [list $canvas mode $mode]

        pack $win.vbar.$mode -side top -fill x -padx {2 3} -pady 3

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

    # ButtonExtend
    #
    # Sets the scrollregion to the full 1000x1000 area

    method ButtonExtend {} {
        $canvas region $view(region)
    }

    # FillBoxPost
    #
    # Sets the values for the fillbox on post.

    method FillBoxPost {} {
        $fillbox configure -values $picklist(filltags)
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
            nbpoint { $self mode point  }
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
        if {"point" in $info(ordertags) || "nbpoint" in $info(ordertags)} {
            # FIRST, if nbpoint we must be in a neighborhood.
            if {"nbpoint" in $info(ordertags)} {
                set n [nbhood find {*}[$canvas ref2m $ref]]

                if {$n eq ""} {
                    return
                } else {
                    set data [list nbpoint $ref]
                }
            } else {
                set data [list point $ref]
            }
            
            # NEXT, Delete previous point
            $canvas delete {transient&&point}

            # NEXT, plot the new point
            lassign [$canvas ref2c $ref] cx cy
                
            $canvas create oval [boxaround 3.0 $cx $cy] \
                -outline blue                           \
                -fill    cyan                           \
                -tags    [list transient point]

            # NEXT, notify the app that a point has been selected.
            notifier send ::app <Puck> $data
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
            notifier send ::app <Puck> [list polygon $poly]
        } else {
            event generate $win <<PolyComplete>> -data $poly
        }
    }

    #-------------------------------------------------------------------
    # Public Methods: General

    delegate method * to canvas

    # dbsync
    #
    # Clears the map; and redraws the scenario features

    method dbsync {} {
        # FIRST, get the current map and projection
        $canvas configure -map        [map image]
        $canvas configure -projection [map projection]

        # NEXT, clear the canvas
        $canvas clear
        $self IconDeleteAll

        # NEXT, clear all remembered state, and redraw everything
        $self NbhoodDrawAll
        $self UnitDrawAll
        $self EnsitDrawAll

        # NEXT, set zoom and region
        set view(zoom)   "[$canvas zoom]%"
        set view(region) [$canvas region]

        # NEXT, update the set of fill tags
        $self NbhoodUpdateFillTags
    }

    # Method: nbfill
    #
    # Directs the mapviewer to use the specified 
    # neighborhood variable to determine the fill color for each 
    # neighborhood, and enables filling.  Rejects the variable
    # if it:
    #
    #   - Is clearly invalid, or
    #   - Has no associated gradient (required for filling), or
    #   - Has no associated data in the RDB.
    #
    # If the variable is accepted, it is added to the nbfill picklist,
    # possible displacing older picks.

    method nbfill {varname} {
        # FIRST, validate the varname and put it in canonical form.
        set varname [view n validate $varname]

        # NEXT, get the view dict.
        array set vdict [view n get $varname]

        # NEXT, does it have a gradient?
        set gradient [dict get $vdict(meta) $varname gradient]

        if {$gradient eq ""} {
            return -code error -errorcode INVALID \
      "can't use variable as fill: no associated color gradient: \"$varname\""
        }

        if {![rdb exists "SELECT * FROM $vdict(view)"]} {
            return -code error -errorcode INVALID \
                "variable has no associated data in the database: \"$varname\""
        }

        # NEXT, ask the mapviewer to enable filling, and fill!
        set view(fillpoly) [expr {$varname ne "none"}]
        set view(filltag)  $varname

        $self NbhoodFill

        # NEXT, if the variable name is not on the global picklist, add it,
        # and prune old picks.
        if {$varname ni $picklist(recentFills)} {
            set picklist(recentFills) \
                [lrange [linsert $picklist(recentFills) 0 $varname] 0 9]

            $self NbhoodUpdateFillTags
        }

        return
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

    # NbhoodRedrawAll
    #
    # Clears and redraws all neighborhoods

    method NbhoodRedrawAll {} {
        foreach id [$canvas nbhood ids] {
            $canvas nbhood delete $id
        }

        $self NbhoodDrawAll
    }

    # NbhoodDrawAll
    #
    # Draws all neighborhoods

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
            unset nbhoods(n-$nbhoods(id-$n))
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
        # FIRST, get the fill type, and retrieve nbhood moods if need be.
        if {!$view(fillpoly)} {
            set fill ""
        } else {
            set fill data

            array set vdict [view n get $view(filltag)]

            array set data [rdb eval "SELECT n, x0 FROM $vdict(view)"]

            set gradient [dict get $vdict(meta) $view(filltag) gradient]
        }
        
        # NEXT, fill the nbhoods
        foreach id [$canvas nbhood ids] {
            set n $nbhoods(n-$id)

            if {$fill eq "data"} {
                if {[info exists data($n)] && $data($n) ne ""} {
                    set color [$gradient color $data($n)]
                } else {
                    set color ""
                }
            } else {
                set color ""
            }

            $canvas nbhood configure $id -fill $color
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

    # NbhoodUpdateFillTags
    #
    # Updates the list of nbhood fill tags on the toolbar

    method NbhoodUpdateFillTags {} {
        set standards $defaultFills

        foreach g [frcgroup names] {
            lappend standards "nbcoop.$g"
        }

        set tags $picklist(recentFills)

        foreach tag $standards {
            if {$tag ni $picklist(recentFills)} {
                lappend tags $tag
            }
        }

        if {$view(filltag) ni $tags} {
            set view(filltag) none

            if {$view(fillpoly)} {
                $self NbhoodFill
            }
        }

        set picklist(filltags) $tags
    }

    #-------------------------------------------------------------------
    # Neighborhood Context Menu

    # CreateNbhoodContextMenu
    #
    # Creates the context menu

    method CreateNbhoodContextMenu {} {
        set mnu [menu $canvas.nbhoodmenu]

        cond::available control \
            [menuitem $mnu command "Create Environmental Situation" \
                 -command [mymethod NbhoodCreateEnsitHere]]         \
            order ENSIT:CREATE

        $mnu add separator

        cond::available control \
            [menuitem $mnu command "Attrit Civilians in Neighborhood" \
                 -command [mymethod NbhoodAttrit]]                    \
            order ATTRIT:NBHOOD

        cond::available control \
            [menuitem $mnu command "Bring Neighborhood to Front" \
                 -command [mymethod NbhoodBringToFront]]         \
            order NBHOOD:RAISE

        cond::available control \
            [menuitem $mnu command "Send Neighborhood to Back" \
                 -command [mymethod NbhoodSendToBack]]         \
            order NBHOOD:LOWER
    }


    # NbhoodCreateEnsitHere
    #
    # Pops up the create ensit dialog with this location filled in.

    method NbhoodCreateEnsitHere {} {
        order enter ENSIT:CREATE location $nbhoods(transref)
    }


    # NbhoodAttrit
    #
    # Attrits all civilians in the neighborhood

    method NbhoodAttrit {} {
        order enter ATTRIT:NBHOOD n $nbhoods(trans)
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
        notifier send ::app <Puck> [list nbhood $nbhoods(n-$id)]

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

    # EntityNbhood delete n
    #
    # n     The neighborhood ID
    #
    # Delete the neighborhood from the mapcanvas.

    # EntityNbhood update n
    #
    # n     The neighborhood ID
    #
    # Something changed about neighborhood n.  Update it.

    method {EntityNbhood update} {n} {
        # FIRST, get the nbhood data we care about
        rdb eval {SELECT refpoint, polygon FROM nbhoods WHERE n=$n} {}

        # NEXT, if this is a new neighborhood, just draw it;
        # otherwise, update the refpoint and polygon
        if {![info exists nbhoods(id-$n)]} {
            $self NbhoodDraw $n $refpoint $polygon
        } else {
            $canvas nbhood point $nbhoods(id-$n)   $refpoint
            $canvas nbhood polygon $nbhoods(id-$n) $polygon
        }

        # NEXT, show refpoints obscured by the change
        $self NbhoodShowObscured
    }

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
      

    # NbhoodStack
    #
    # The neighborhood stacking order has changed; redraw all
    # neighborhoods

    method NbhoodStack {} {
        $self NbhoodRedrawAll
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

        # NEXT, clear the context; the icon might not be there
        # any more
        set icons(context) ""
    }

    # IconExists sid
    #
    # Returns 1 if there's an icon with the given sid, and 0 otherwise.

    method IconExists {sid} {
        return [info exists icons(cid-$sid)]
    }



    #-------------------------------------------------------------------
    # Event Handlers: mapcanvas(n)

    # canupdate
    #
    # returns 1 if you can update the icon, and 0 otherwise.

    method canupdate {} {
        if {![info exists icons(context)] ||
            $icons(context) eq ""} {
            return 0
        }

        set sid $icons(context)

        # If the icon once exist but has been deleted, forget
        # it and return 0.
        if {![info exists icons(cid-$sid)]} {
            set icons(context) ""
            return 0
        }

        set cid $icons(cid-$sid)
        set itype $icons(itype-$cid)

        if {$itype eq "situation"} {
            return [expr {$sid in [ensit initial names]}]
        } else {
            return 1
        }
    }



    # Icon-1 cid
    #
    # cid      A canvas icon ID
    #
    # Called when the user clicks on an icon.  First, support pucking 
    # of icons into orders.  Next, translate it to a scenario ID
    # and forward as the appropriate kind of entity.

    method Icon-1 {cid} {
        notifier send ::app <Puck> \
            [list $icons(itype-$cid) $icons(sid-$cid)]

        set sid $icons(sid-$cid)

        switch $icons(itype-$cid) {
            unit      { event generate $win <<Unit-1>>   -data $sid }
            situation { event generate $win <<Ensit-1>> -data $sid }
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
        # FIRST, save the context.
        set icons(context) $icons(sid-$cid)

        # NEXT, Update any menu items that depend on this condition
        cond::availableCanUpdate update

        # NEXT, popup the menu
        switch -exact $icons(itype-$cid) {
            situation {
                tk_popup $canvas.ensitmenu $rx $ry
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
                if {[catch {
                    order send gui UNIT:MOVE             \
                        u        $icons(sid-$cid)        \
                        location [$canvas icon ref $cid]
                }]} {
                    $self UnitDrawSingle $icons(sid-$cid)
                }
            }

            situation {
                if {[catch {
                    order send gui ENSIT:MOVE \
                        s        $icons(sid-$cid)                 \
                        location [$canvas icon ref $cid]
                }]} {
                    $self EnsitDrawSingle $icons(sid-$cid)
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
            WHERE active
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

            # NEXT, we only draw active units.
            if {!$active} {
                return
            }

            # NEXT, color it.
            if {$personnel > 0} {
                set bg black
            } else {
                set bg gray
            }

            # NEXT, draw it.
            set cid [$canvas icon create unit \
                         {*}$location         \
                         -foreground $color   \
                         -background $bg      \
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

    # AttritUnit
    #
    # Pops up the relevant order dialog for this unit

    method AttritUnit {} {
        order enter ATTRIT:UNIT u $icons(context)
    }

    #-------------------------------------------------------------------
    # Event Handlers: notifier(n)

    # EntityUnit update n
    #
    # n     The unit ID
    #
    # Something changed about unit n.  Update it.

    method {EntityUnit update} {u} {
        $self UnitDrawSingle $u
    }


    # EntityUnit delete u
    #
    # u     The unit ID
    #
    # Delete the unit from the mapcanvas.

    method {EntityUnit delete} {u} {
        # There's an icon only if the unit is currently active.
        if {[$self IconExists $u]} {
            $self IconDelete $u
        }
    }
      
    #===================================================================
    # Ensit Display and Behavior

    #-------------------------------------------------------------------
    # Ensit Display

    # EnsitDrawAll
    #
    # Clears and redraws all ensits

    method EnsitDrawAll {} {
        rdb eval {
            SELECT * FROM ensits
        } row {
            $self EnsitDraw [array get row]
        } 

    }

    # EnsitDraw parmdict
    #
    # parmdict   Data about the ensit

    method EnsitDraw {parmdict} {
        dict with parmdict {
            # FIRST, if there's an existing ensit called this,
            # delete it.
            if {[info exists icons(cid-$s)]} {
                $self IconDelete $s
            }

            # NEXT, draw it.
            set cid [$canvas icon create situation \
                         {*}$location              \
                         -text $stype]

            if {$state eq "INITIAL"} {
                $canvas icon configure $cid -foreground red
                $canvas icon configure $cid -background white
            } elseif {$state eq "RESOLVED"} {
                $canvas icon configure $cid -foreground "#009900"
                $canvas icon configure $cid -background white
            } else {
                $canvas icon configure $cid -foreground red
                $canvas icon configure $cid -background yellow
            }
            
            # NEXT, save the name by the ID.
            set icons(itype-$cid) situation
            set icons(sid-$cid) $s
            set icons(cid-$s)   $cid
        }
    }

    # EnsitDrawSingle s
    #
    # s    The ID of the ensit.
    #
    # Redraws just ensit s.  Use this when only a single ensit is
    # to be redrawn.
    # 
    # Note that s might be any situation; make sure that non-ensits
    # are ignored.

    method EnsitDrawSingle {s} {
        # FIRST, draw it, if it's current.
        rdb eval {
            SELECT * FROM ensits
            WHERE s=$s
        } row {
            $self EnsitDraw [array get row]
            return
        } 

        # NEXT, the ensit is no longer current; delete the icon.
        if {[info exists icons(cid-$s)]} {
            $self IconDelete $s
        }
    }


    #-------------------------------------------------------------------
    # Ensit Context Menu

    # CreateEnsitContextMenu
    #
    # Creates the context menu

    method CreateEnsitContextMenu {} {
        set mnu [menu $canvas.ensitmenu]

        cond::availableCanUpdate control \
            [menuitem $mnu command "Update Situation" \
                 -command [mymethod UpdateEnsit]] \
            order ENSIT:UPDATE browser $win
    }

    # UpdateEnsit
    #
    # Pops up the "Update Environmental Situation" dialog for this unit

    method UpdateEnsit {} {
        order enter ENSIT:UPDATE s $icons(context)
    }

    #-------------------------------------------------------------------
    # Event Handlers: notifier(n)

    # EntityEnsit update s
    #
    # s     The ensit ID
    #
    # Something changed about ensit s.  Update it.
    #
    # Note that s might be any situation; make sure that non-ensits
    # are ignored.

    method {EntityEnsit update} {s} {
        $self EnsitDrawSingle $s
    }

    # EntityEnsit delete s
    #
    # s     The ensit ID
    #
    # Delete the ensit from the mapcanvas.
    #
    # Note that s might be any situation; make sure that non-ensits
    # are ignored.

    method {EntityEnsit delete} {s} {
        # FIRST, Delete the icon only if it actually exists.
        if {[info exists icons(cid-$s)]} {
            $self IconDelete $s
        }
    }
      
    #===================================================================
    # Group Entity Event Handlers

    # EntityGroup op g
    #
    # op    The operation
    # g     The group ID
    #
    # A group was created/updated/deleted.
    #
    # * Update the list of nbhood fill tags.
    # * If the group was updated, redraw units; their shapes or
    #   colors might have changed.
    #
    # TBD: It appears that these things can change in PREP only,
    # when it doesn't matter.

    method EntityGroup {op g} { 
        $self NbhoodUpdateFillTags

        if {$op eq "update"} {
            $self UnitDrawAll
        }
    }

    #===================================================================
    # Economics Entity Event Handlers

    # EntityEcon op n
    #
    # op   The operation
    # n    The nbhood ID
    #
    # If nbhood data was changed for the economic model, update the
    # nbhood colors.

    method EntityEcon {op g} {
        $self NbhoodFill
    }
}



