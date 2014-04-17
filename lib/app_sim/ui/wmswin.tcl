#-----------------------------------------------------------------------
# TITLE:
#    wmswin.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    WMS toplevel window
#
# This window is responsible for allowing the user to pick and choose
# map layers and bounding boxes from a web map service (WMS) server.
# Currently, there is only one map service that we regularly use:
#
#      http://demo.cubewerx.com/demo/cubeserv/simple
#
# If a different WMS is known its base url can by typed into the window
# and an attempt to connect to it made.  The assumption is that a connected
# WMS is compliant with the Open GIS standard for web map services.
#
# Once the server is connected and the WMS client has successfully 
# retrieved the WMS capabilities info, a default map is drawn using
# the first layer from the list of layers available and the largest 
# lat/long bounding box that the service allows.
#
# After the default map is drawn, the user can then change layers and
# select different bounding boxes to customize the look and location of
# the map.  The application keeps a stack of maps selected so the user
# can easily switch back to previously selected maps rather than 
# go back to the default map and start over.
#
# Once the user is content with the look and feel of the map it can
# be exported to the Athena application and used to draw neighborhoods
# on.  If neighborhoods already exist in Athena a check is made to
# see if they would be compatible with the map selected and, if need be,
# the user is warned if there is an incompatiblity (such as neighborhood
# boundaries outside the boundaries of the selected map.)
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# wmswin

snit::widget wmswin {
    hulltype toplevel

    #-------------------------------------------------------------------
    # Components

    component wms        ;# wmsclient(n)
    component map        ;# mapcanvas(n)
    component centry     ;# commandentry(n)
    component llist      ;# toplevel for displaying available map layers
    component sendbtn    ;# the "Send" button

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Instance variables

    # info array
    #
    # status     - status of the WMS server
    # locvar     - variable used to store map location for display
    # layers     - dict of available map layers
    # clayers    - list of chosen map layers
    # cwidth     - map width in pixels
    # cheight    - map height in pixels
    # mapstack   - list of map/projection pairs already loaded
    # lchanged   - flag indicating whether chosen layers have changed
    # boxchanged - flag indicating whether bounding box has changed

    variable info -array {
        status     "Not Connected"
        locvar     {}
        layers     {}
        clayers    {}
        cwidth     1000
        cheight    650
        mapstack   {}
        lchanged   0
        boxchanged 0
    }

    # boxcoords array
    #
    # Bounding box coordinates in canvas units
   
    variable box -array {
        x0   0
        y0   0
        x1   1000
        y1   650
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, withdraw the hull widget
        wm withdraw $win

        wm title $win "WMS Map Client"

        # NEXT, get options
        $self configurelist $args

        # NEXT, create the wmsclient(n)
        install wms using wmsclient ${selfns}::client \
            -servercmd [mymethod HandleServerResponse]

        # NEXT, exit when window closed
        wm protocol $win WM_DELETE_WINDOW [list wm withdraw $win]

        # NEXT, create GUI componenents
        $self CreateComponents
        $self CreateLayerSelectionWin

        # NEXT, react to simulation state changes
        notifier bind ::sim <State> $win [mymethod StateChange]

        # NEXT, connect to default server
        set baseurl "http://demo.cubewerx.com/demo/cubeserv/simple"
        $win.bar.address set $baseurl
        $self ConnectToAddress $baseurl

        update idletasks 
        wm deiconify $win
        raise $win
    }

    destructor {
        notifier forget $win
    }

    # CreateComponents
    #
    # Creates the meat of the UI
    
    method CreateComponents {} {
        # Row 1: The server location bar
        ttk::frame $win.bar

        # Label, command entry and "Go" button
        ttk::label $win.bar.lbl \
            -text "Server:  "

        commandentry $win.bar.address \
            -clearbtn 1           \
            -returncmd [mymethod ConnectToAddress]

        ttk::button $win.bar.btn \
            -style Toolbutton    \
            -text "Connect"      \
            -command [mymethod ConnectToServer]

        ttk::button $win.bar.help \
            -style Toolbutton     \
            -image ::marsgui::icon::question22 \
            -state normal                      \
            -command [list app help MAP:IMPORT:DATA]

        # Pack the components into the bar
        pack $win.bar.lbl     -side left -padx {0 5}
        pack $win.bar.address -side left -expand yes -fill x -padx {0 5}
        pack $win.bar.btn     -side left
        pack $win.bar.help    -side left

        # Row 2: A separator
        ttk::separator $win.sep1

        # Frame for the map itself
        ttk::frame $win.mapf
    
        # The map top toolbar
        ttk::frame $win.mapf.ttoolbar
    
        ttk::separator $win.mapf.sep1

        # Layer selection tool
        ttk::button $win.mapf.ttoolbar.layers \
            -style Toolbutton       \
            -text "Select Layers"   \
            -state disabled         \
            -command [list $self SelectLayers]
    
        # Get map button
        ttk::button $win.mapf.ttoolbar.getmap \
            -style Toolbutton \
            -text  "Get Map"  \
            -state disabled   \
            -command [list $self GetMap]
    
        # Map location display
        ttk::label $win.mapf.ttoolbar.loc \
            -textvariable [myvar info(maploc)] \
            -justify      right                \
            -anchor       e                    \
            -width        60             
    
        pack $win.mapf.ttoolbar.layers -side left
        pack $win.mapf.ttoolbar.getmap -side left -padx {5 0}
        pack $win.mapf.ttoolbar.loc    -side right

        # map display
        install map using mapcanvas $win.mapf.map \
            -locvariable [myvar info(locvar)]     \
            -width 1000 -height 650
    
        ttk::separator $win.mapf.sep2

        # map bottom toolbar
        ttk::frame $win.mapf.btoolbar

        ttk::label $win.mapf.btoolbar.slbl \
            -text "Server Status: "

        ttk::label $win.mapf.btoolbar.status \
            -textvariable [myvar info(status)] \
            -width        20

        ttk::button $win.mapf.btoolbar.cancel \
            -style Toolbutton  \
            -text "Cancel"     \
            -command [list $self Cancel]

        install sendbtn using ttk::button $win.mapf.btoolbar.send \
                -style Toolbutton \
                -text  "Send"     \
                -state disabled   \
                -command [list $self ExportMap]

        # pack components into the bottom toolbar
        pack $win.mapf.btoolbar.slbl   -side left  -anchor w -padx {0 5}
        pack $win.mapf.btoolbar.status -side left  -anchor w -padx {0 5}
        pack $win.mapf.btoolbar.send   -side right -anchor e -padx {0 5} 
        pack $win.mapf.btoolbar.cancel -side right -anchor e -padx {0 5}

        # bounding box events
        bind $map <ButtonPress-1>   [list $self BboxSet  %x %y]
        bind $map <B1-Motion>       [list $self BboxDraw %x %y]
        bind $map <ButtonRelease-1> [list $self BboxDone %x %y]   
        bind $map <ButtonPress-3>   [list $self HandleRightClick]
    
        # pack components into the map frame
        pack $win.mapf.ttoolbar -side top    -anchor w
        pack $win.mapf.sep1     -side top    -expand yes -fill x
        pack $win.mapf.btoolbar -side bottom -expand yes -fill x
        pack $win.mapf.sep2     -side bottom -expand yes -fill x
        pack $map               -side bottom -expand yes -fill both

        # grid components into the main window
        grid $win.bar   -row 0 -column 0 -sticky ew
        grid $win.sep1  -row 1 -column 0 -sticky ew
        grid $win.mapf  -row 2 -column 0 -sticky nsew
    
        grid rowconfigure    $win 2 -weight 1
        grid columnconfigure $win 0 -weight 1
    }

    # CreateLayerSelectionWin
    #
    # This method creates and populates the layer selection window
    # with the map layers available in the WMS.

    method CreateLayerSelectionWin {} {
        # FIRST, create the window 
        install llist as toplevel .p 
        wm title $llist "Choose Layers"
        wm protocol $llist WM_DELETE_WINDOW [list wm withdraw $llist]
    
        listfield $llist.layers                 \
            -changecmd [mymethod LayersChanged] \
            -height    10                       \
            -itemdict  $info(layers)            \
            -showkeys  0                        \
            -width     40 
    
        $llist.layers set $info(clayers)
    
        ttk::button $llist.btn \
            -text "Ok"         \
            -command [list $self LayersSelected]
    
        pack $llist.layers -side top    -expand no
        pack $llist.btn    -side bottom -expand no -anchor e

        wm withdraw $llist
    }
    
    #------------------------------------------------------------------------
    # Event Handlers

    # ConnectToAddress  addr
    #
    # addr   - base url for a WMS
    #
    # An attempt is made to connect to a WMS given by addr.

    method ConnectToAddress {addr} {
        # FIRST, initialize map information
        set info(layers)     [dict create]
        set info(clayers)    [list]
        set info(cwidth)     1000
        set info(cheight)    650
        set info(mapstack)   [list]
        set info(lchanged)   0
        set info(boxchanged) 0
        set info(status)     "CONNECTING"
        
        # NEXT, clear out layers and map
        $llist.layers configure -itemdict $info(layers)
        $llist.layers set $info(clayers)

        $map clear
        $map configure -map {} -projection {}
        $map refresh

        # NEXT, disable buttons
        $sendbtn configure -state disabled
        $win.mapf.ttoolbar.getmap configure -state disabled
        $win.mapf.ttoolbar.layers configure -state disabled

        # NEXT, attempt to connect
        $wms server connect $addr
    }

    # ConnectToServer
    #
    # The "Connect" button was pressed, get the URL from the address bar
    # and attemp to connect to the server.

    method ConnectToServer {} {
        # FIRST, get the URL from the address bar
        set baseurl [$win.bar.address get]

        # NEXT, try to connect
        $self ConnectToAddress $baseurl
    }

    # StateChange
    #
    # The simulation has changed state, update GUI compoenents

    method StateChange {} {
        if {[sim state] eq "PREP"} {
            $sendbtn configure -state normal
        } else {
            $sendbtn configure -state disabled
        }
    }

    # BboxSet x y
    #
    # x   - an x location in canvas coords
    # y   - a y location in canvas coords
    #
    # The user has pressed the mouse on the canvas. Start drawing a
    # bounding box.

    method BboxSet  {x y} {
        $self BboxClear
    
        set box(x0) $x
        set box(y0) $y
        $map create rectangle $box(x0) $box(y0) $box(x0) $box(y0) \
            -outline red -tags Bbox
    }
    
    # BboxDraw  x y
    # 
    # x   - an x location in canvas coords
    # y   - a y location in canvas coords
    #
    # The user is dragging the mouse on the canvas. Update the bounding
    # box.

    method BboxDraw {x y} {
        # dragging down and to the right is what's allowed
        if {$x < $box(x0)} {
            set x $box(x0)
        } 
    
        if {$y < $box(y0)} {
            set y $box(y0)
        }
    
        # draw the box
        $map coords Bbox $box(x0) $box(y0) $x $y
    }
    
    # BboxDone x y
    #
    # x  - an x location in canvas coords
    # y  - a y location in canvas coords
    #
    # The user has released the mouse. Stop drawing the box and set the
    # lower right coords and changed flag.

    method BboxDone {x y} {
        set box(x1) $x
        set box(y1) $y
    
        set info(boxchanged) 1
    }

    # BboxClear
    #
    # Deletes the bounding box from the map and resets the origin

    method BboxClear {} {
        if {[llength [$map find withtag Bbox]] > 0} {
            $map delete Bbox
            set info(x0) 0
            set info(y0) 0
        }
    }

    # Cancel
    #
    # Clicking the Cancel button makes the window go away

    method Cancel {} {
        wm withdraw $win
    }

    # HandleRightClick
    #
    # This method removes any bounding box that may be drawn on the screen
    # and goes back one in the stack of maps that have already been loaded.
    # TBD: provide a way to traverse the stack back and forth.

    method HandleRightClick {} {
        # FIRST, if there's a bounding box clear it
        $self BboxClear
    
        # NEXT, no map stack, nothing to do
        if {[llength $info(mapstack)] == 0} {
            return
        }
    
        # NEXT, go to previous map/projection in stack
        # to
        if {[llength $info(mapstack)] > 2} {
            # Pop image and projection off mapstack
            set info(mapstack) [lrange $info(mapstack) 0 end-2]
        }
    
        # NEXT, set image and projection
        set img [lindex $info(mapstack) end-1]
        set proj [lindex $info(mapstack) end]
    
        # NEXT, configure map with new data and refresh
        $map clear
        $map configure -map $img -projection $proj
        $map refresh

        # NEXT, set box changed flag
        set info(boxchanged) 1
    }

    # ExportMap
    # 
    # This callback extracts the map image data and projection meta-data
    # for export to Athena.  The MAP:IMPORT:DATA order is called to set 
    # the map in the application.

    method ExportMap {} {
        # FIRST, extract map image data in JPEG format
        set img [$map cget -map]
        set imgdata [$img data -format jpeg]
        set parms(data) $imgdata

        # NEXT, extract map projection meta-data
        set parms(proj) [dict create]
        set proj [$map cget -projection]
        dict set parms(proj) ptype RECT
        dict set parms(proj) minlon [$proj cget -minlon]
        dict set parms(proj) maxlon [$proj cget -maxlon]
        dict set parms(proj) minlat [$proj cget -minlat]
        dict set parms(proj) maxlat [$proj cget -maxlat]
        dict set parms(proj) width  [$proj cget -width]
        dict set parms(proj) height [$proj cget -height]

        if {![map compatible $parms(proj)]} {
            set answer [messagebox popup \
                           -title "Are you sure?"              \
                           -icon  warning                      \
                           -buttons {cancel "Cancel" ok "Yes"} \
                           -default cancel                     \
                           -parent $win                        \
                           -message [normalize {
                               Using this map will result in neighborhoods
                               needing to be redrawn. Are you sure you want
                               to use this map?
                           }]]

            if {$answer eq "cancel"} {
                return
            }
        }

        # NEXT, send the order
        order send gui MAP:IMPORT:DATA [array get parms]
    }

    # HandleServerResponse ?rtype?
    #
    # rtype - response type; if present, one of WMSCAP or WMSMAP
    #
    # handles responses from the connected server
    
    method HandleServerResponse {{rtype {}}} {
        # FIRST, status information
        set info(status) [$wms server state]

        # NEXT, disable the Ok button, it will be enabled if all is well
        $sendbtn configure -state disabled

        log detail wmswin "WMS [$wms server state]: [$wms server status]"
        if {[$wms server state] ne "OK"} {
            log detail wmswin "Connection Error: [$wms server error]"

            messagebox popup             \
               -title   "Server Error"   \
               -icon    error            \
               -buttons {ok "Ok"}        \
               -default ok               \
               -parent $win              \
               -message [normalize {
                   An error occurred trying to connect, see the log for
                   details.
                }]

            return
        }
    
        # NEXT, if the response is from a GetCapabilities request
        if {$rtype eq "WMSCAP"} {
            # FIRST, extract capabilities from the server
            set caps [$wms server wmscap]
    
            log detail wmswin "WMS Version: [dict get $caps Version]"
    
            if {[$wms server state] eq "OK"} {
                # NEXT, extract layers from WMS capabilities
                set lns [dict get $caps Layer Name]
                set lts [dict get $caps Layer Title]
                set info(layers) [dict create]
                foreach ln $lns lt $lts {
                    dict set info(layers) $ln $lt
                }
                set info(clayers) [lindex $lns 0]
    
                $llist.layers configure -itemdict $info(layers)
                $llist.layers set $info(clayers)

                # NEXT, display default map
                $self GetDefaultMap
            }
        } elseif {$rtype eq "WMSMAP"} {
            # NEXT, response is from a GetMap request
            if {[$wms server state] eq "OK"} {
                $map clear
                $map configure -map [$wms map image]
                lassign [$wms map bbox] minlat minlon maxlat maxlon
                set proj [::marsutil::maprect %AUTO% \
                                          -minlon $minlon -minlat $minlat \
                                          -maxlon $maxlon -maxlat $maxlat \
                                          -width [$wms map width] \
                                          -height [$wms map height]]
                $map configure -projection $proj
                $map refresh
    
                # Push retrieved image and projection onto the map stack
                lappend info(mapstack) [$wms map image] $proj
                set info(boxchanged) 0
                set info(lchanged) 0

                # NEXT, all is good so enable buttons
                $sendbtn configure -state normal
                $win.mapf.ttoolbar.getmap configure -state normal
                $win.mapf.ttoolbar.layers configure -state normal
            } else {
                tk_messageBox -default "ok" \
                          -icon error   \
                          -message "Error in map request, see log." \
                          -parent $win \
                          -title "Error" \
                          -type ok
            }
        } elseif {$rtype eq ""} {
            return
        } else {
            log debug wmswin "Unknown response from WMS Client: $rtype"
        }
    }

    # GetDefaultMap
    #
    # This proc gets the default map once the client has successfully connected
    # to the server.
    
    method GetDefaultMap {} {
        # NEXT set the URL with user parms
        set baseURL [dict get [$wms server wmscap] Request GetMap Xref]
        set qparms [dict create]
        dict set qparms LAYERS [lindex $info(clayers) 0]
        dict set qparms WIDTH  $info(cwidth)
        dict set qparms HEIGHT $info(cheight)
    
        # NEXT, make the request
        $wms server getmap $baseURL $qparms
    }

    # GetMap
    #
    # User has requested a map from the WMS
    
    method GetMap {} {
        # FIRST, gather requested layers
        if {[llength $info(clayers)] == 0} {
            tk_messageBox -default ok \
                          -icon error \
                          -title "Layers not selected" \
                          -message "Select one or more layers" \
                          -type ok
            return
        }
    
        # NEXT, if nothing changed, nothing to do
        if {!$info(lchanged) && !$info(boxchanged)} {
            return
        }
    
        # NEXT set the URL with user parms
        set baseURL [dict get [$wms server wmscap] Request GetMap Xref]
        set qparms [dict create]
        dict set qparms LAYERS [join $info(clayers) ","]
    
        # NEXT, if there's a bounding box, convert it to lat/lon coords 
        # and set the BBOX parm in the request
        if {[llength [$map find withtag Bbox]] > 0} {
            $self ComputeCanvasDim
            lassign [$map bbox Bbox] x1 y1 x2 y2
            lassign [$map c2m $x1 $y1] maxlat minlon
            lassign [$map c2m $x2 $y2] minlat maxlon
        } else {
            lassign [$map c2m 0 0] maxlat minlon
            set info(cwidth) [$map cget -width]
            set info(cheight) [$map cget -height]
            lassign [$map c2m $info(cwidth) $info(cheight)] minlat maxlon
        }

        dict set qparms WIDTH  $info(cwidth)
        dict set qparms HEIGHT $info(cheight)
        dict set qparms BBOX "$minlat,$minlon,$maxlat,$maxlon"
    
        # NEXT, make the request
        $wms server getmap $baseURL $qparms
    }
    
    # ComputeCanvasDim  
    #
    # Given a bounding box drawn on the map, pick some canvas dimensions for
    # the map to be requested so that there is no distortion of the image.

    method ComputeCanvasDim {} {
        # FIRST, extract bounding box coordinates
        lassign [$map bbox Bbox] x1 y1 x2 y2
        let dx {$x2-$x1}
        let dy {$y2-$y1}
        let ratio {$dx/$dy}
    
        # NEXT, figure out dimensions that will nicely fit onto the
        # canvas. An aspect ratio of 1.65 is pleasing for maps so use
        # that as the basis for computing width or height
        if {$dx/$dy > 1.65} {
            # X-dim is larger than 1.65*Y-dim; set width to max
            set info(cwidth) 1000
            let info(cheight) {int($dy * (1000.0/$dx))}
        } else {
            # X-dim is less than or equal to 1.65*Y-dim; set height to max
            set info(cheight) 650
            let info(cwidth) {int($dx * (650.0/$dy))}
        }
    }
    
    # SelectLayers 
    #
    # Given the set of map layers available in the WMS, allow the user
    # to choose which ones to see.
    
    method SelectLayers {} {
        # FIRST, if the window isn't already up, pop it up
        if {[winfo exists $llist]} {
            wm deiconify $llist
            return
        }
    }
    
    # LayersChanged arg
    # 
    # TBD

    method LayersChanged {arg} {
        # No-Op for now
    }
    
    method LayersSelected {} {
        # The user hit the OK button; pop window down
        set lSelected [$llist.layers get]
        if {$info(clayers) ne $lSelected} {
            set info(clayers) $lSelected
            set info(lchanged) 1
        }
        wm withdraw $llist
    }
}

