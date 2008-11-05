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

    }

    #-------------------------------------------------------------------
    # Options

    delegate option -map to canvas

    delegate option *    to hull
    
    #-------------------------------------------------------------------
    # Components

    component canvas           ;# The mapcanvas(n)

    #-------------------------------------------------------------------
    # Instance Variables

    # Info array; used for most scalars
    #
    #    mode           The current mapcanvas(n) mode
    #    ref            The current map reference

    variable info -array {
        mode ""
        ref  ""
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
            -background   white                          \
            -modevariable [myvar info(mode)]             \
            -refvariable  [myvar info(ref)]
        
        $win.mapsw setwidget $canvas

        # Horizontal tool bar
        frame $win.hbar \
            -relief flat

        label $win.hbar.ref \
            -textvariable [myvar info(ref)] \
            -width 8

        pack $win.hbar.ref -side right

        # Separator
        frame $win.sep -height 2 -relief sunken -borderwidth 2

        # Vertical tool bar
        frame $win.vbar -relief flat

        $self AddModeTool point left_ptr
        $self AddModeTool poly  draw_poly
        $self AddModeTool pan   fleur

        # Pack all of these components
        pack $win.hbar  -side top  -fill x
        pack $win.sep   -side top  -fill x
        pack $win.vbar  -side left -fill y 
        pack $win.mapsw            -fill both -expand yes

        # NEXT, replace $canvas in the bindtags with $win, so 
        # that it will respond to bindings on the window.
        set bindtags [bindtags $canvas]
        set ndx [lsearch -exact $bindtags $canvas]
        bindtags $canvas [lreplace $bindtags $ndx $ndx $win]

        # NEXT, process the arguments
        $self configurelist $args

        # NEXT, clear the map.
        $canvas clear
    }

    # AddModeTool mode icon
    #
    # mode       The mapcanvas(n) mode name
    # icon       The icon to display on the button

    method AddModeTool {mode icon} {
        radiobutton $win.vbar.$mode                \
            -indicatoron no                        \
            -offrelie    flat                      \
            -variable    [myvar info(mode)]        \
            -image       ${type}::icon::$icon      \
            -value       $mode                     \
            -command     [list $canvas mode $mode]

        pack $win.vbar.$mode -side top -fill x -padx 2
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to canvas



    #-------------------------------------------------------------------
    # Private Methods

    # ThePrompt
    #
    # Returns the CLI prompt.

    method ThePrompt {} {
        return "[simclock asZulu]>"
    }
}





