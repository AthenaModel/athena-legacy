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

    delegate option -refvariable  to canvas
    delegate option -map          to canvas

    delegate option *             to hull
    
    #-------------------------------------------------------------------
    # Components

    component canvas           ;# The mapcanvas(n)

    #-------------------------------------------------------------------
    # Instance Variables

    # Info array; used for most scalars
    #
    #    mode           The current mapcanvas(n) mode

    variable info -array {
        mode ""
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
            -modevariable [myvar info(mode)]
        
        $win.mapsw setwidget $canvas

        # Vertical tool bar
        frame $win.vbar

        $self AddModeTool point left_ptr
        $self AddModeTool poly  draw_poly
        $self AddModeTool pan   fleur

        # Pack all of these components
        pack $win.vbar  -side left   -fill y 
        pack $win.mapsw              -fill both -expand yes

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

        pack $win.vbar.$mode -side top -fill x
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





