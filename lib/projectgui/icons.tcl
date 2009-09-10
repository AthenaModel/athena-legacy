#-----------------------------------------------------------------------
# TITLE:
#    icons.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: standard icons
#
#    This module defines a set of standard icons for use in buttons,
#    etc.  All icons are defined in the ::projectgui::icon namespace; none
#    are exported.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Icon definitions

namespace eval ::projectgui::icon:: {
    namespace import ::marsgui::mkicon

    image create photo ::projectgui::icon::peabody32 \
        -file [file join $::projectgui::library MrPeabody.gif]

    mkicon ::projectgui::icon::pencil22 {
        ......................
        ......................
        ...............XXX....
        ..............XeeeX...
        .............XeeeeeX..
        ............X,XeeeeX..
        ...........X,,,XeeeX..
        ..........X,,,X,XeX...
        .........X,,,X,,,X....
        ........X,,,X,,,X.....
        .......X,,,X,,,X......
        ......X,,,X,,,X.......
        .....X,,,X,,,X........
        ....XwX,X,,,X.........
        ....XwwX,,,X..........
        ...XwwwwX,X...........
        ...XwwwwwX............
        ...XXwwXX.............
        ..XXXXX...............
        ..XX..................
        ......................
        ......................
    } {
        .  trans
        X  #000000
        e  #E77F7F
        ,  #EFB311
        w  #BDA565
    }

    mkicon ::projectgui::icon::pencil022 {
        ......................
        ......................
        ...............XXX....
        ..............XeeeX...
        .............XeeeeeX..
        ............X,XeeeeX..
        ...........X,,,XeeeX..
        ..........X,,,X,XeX...
        .........X,,,X,,,X....
        ........X,,,X,,,X.....
        .......X,,,X,,,X......
        ......X,,,X,,,X.......
        .....X,,,X,,,X........
        ....XwX,X,,,X..XXXX...
        ....XwwX,,,X..X....X..
        ...XwwwwX,X...X...XX..
        ...XwwwwwX....X..X.X..
        ...XXwwXX.....X.X..X..
        ..XXXXX.......XX...X..
        ..XX...........XXXX...
        ......................
        ......................
    } {
        .  trans
        X  #000000
        e  #E77F7F
        ,  #EFB311
        w  #BDA565
    }

    mkicon ::projectgui::icon::pencils22 {
        ......................
        ......................
        ...............XXX....
        ..............XeeeX...
        .............XeeeeeX..
        ............X,XeeeeX..
        ...........X,,,XeeeX..
        ..........X,,,X,XeX...
        .........X,,,X,,,X....
        ........X,,,X,,,X.....
        .......X,,,X,,,X......
        ......X,,,X,,,X.......
        .....X,,,X,,,X........
        ....XwX,X,,,X..XXXX...
        ....XwwX,,,X..X....X..
        ...XwwwwX,X...X.......
        ...XwwwwwX.....XXXX...
        ...XXwwXX..........X..
        ..XXXXX.......X....X..
        ..XX...........XXXX...
        ......................
        ......................
    } {
        .  trans
        X  #000000
        e  #E77F7F
        ,  #EFB311
        w  #BDA565
    }

    mkicon ::projectgui::icon::pencila22 {
        ......................
        ......................
        ...............XXX....
        ..............XeeeX...
        .............XeeeeeX..
        ............X,XeeeeX..
        ...........X,,,XeeeX..
        ..........X,,,X,XeX...
        .........X,,,X,,,X....
        ........X,,,X,,,X.....
        .......X,,,X,,,X......
        ......X,,,X,,,X.......
        .....X,,,X,,,X........
        ....XwX,X,,,X..XXXX...
        ....XwwX,,,X..X....X..
        ...XwwwwX,X...X....X..
        ...XwwwwwX....XXXXXX..
        ...XXwwXX.....X....X..
        ..XXXXX.......X....X..
        ..XX..........X....X..
        ......................
        ......................
    } {
        .  trans
        X  #000000
        e  #E77F7F
        ,  #EFB311
        w  #BDA565
    }

    mkicon ::projectgui::icon::plus22 {
        ......................
        ......................
        ......................
        .........XXXX.........
        .........XXXX.........
        .........XXXX.........
        .........XXXX.........
        .........XXXX.........
        .........XXXX.........
        ...XXXXXXXXXXXXXXXX...
        ...XXXXXXXXXXXXXXXX...
        ...XXXXXXXXXXXXXXXX...
        ...XXXXXXXXXXXXXXXX...
        .........XXXX.........
        .........XXXX.........
        .........XXXX.........
        .........XXXX.........
        .........XXXX.........
        .........XXXX.........
        ......................
        ......................
        ......................
    } {
        .  trans
        X  #000000
    }


    mkicon ::projectgui::icon::help22 {
        ......................
        ......................
        ........XXXXXX........
        ......XXXXXXXXXX......
        .....XXXXXXXXXXXX.....
        ....XXXXX....XXXXX....
        ....XXXX......XXXX....
        .....XX.......XXXX....
        .............XXXX.....
        ............XXXX......
        ...........XXXX.......
        ..........XXXX........
        .........XXXX.........
        .........XXXX.........
        ..........XX..........
        ......................
        ..........XX..........
        .........XXXX.........
        .........XXXX.........
        ..........XX..........
        ......................
        ......................
    } {
        .  trans
        X  #000000
    }

    mkicon ::projectgui::icon::x22 {
        ......................
        ......................
        ......................
        ...XXX..........XXX...
        ...XXXX........XXXX...
        ...XXXXX......XXXXX...
        ....XXXXX....XXXXX....
        .....XXXXX..XXXXX.....
        ......XXXXXXXXXX......
        .......XXXXXXXX.......
        ........XXXXXX........
        ........XXXXXX........
        .......XXXXXXXX.......
        ......XXXXXXXXXX......
        .....XXXXX..XXXXX.....
        ....XXXXX....XXXXX....
        ...XXXXX......XXXXX...
        ...XXXX........XXXX...
        ...XXX..........XXX...
        ......................
        ......................
        ......................
    } {
        .  trans
        X  #FF0000
    }

    mkicon ::projectgui::icon::check22 {
        ......................
        ......................
        ......................
        ......................
        .................XX...
        ...X...........XXX....
        ...XX........XXXX.....
        ....XX.....XXXXX......
        ....XXX..XXXXXX.......
        ....XXXXXXXXXX........
        ....XXXXXXXXX.........
        .....XXXXXXX..........
        .....XXXXXX...........
        .....XXXXX............
        .....XXXX.............
        ......XX..............
        ......X...............
        ......................
        ......................
        ......................
        ......................
        ......................
    } {
        .  trans
        X  #009900
    }

    mkicon ::projectgui::icon::play22 {
        ......................
        ......................
        ......................
        ....XX................
        ....XXXX..............
        ....XXXXXX............
        ....XXXXXXXX..........
        ....XXXXXXXXXX........
        ....XXXXXXXXXXXX......
        ....XXXXXXXXXXXXXX....
        ....XXXXXXXXXXXX......
        ....XXXXXXXXXX........
        ....XXXXXXXX..........
        ....XXXXXX............
        ....XXXX..............
        ....XX................
        ......................
        ......................
        ......................
        ......................
        ......................
        ......................
    } {
        .  trans
        X  #000000
    }


    mkicon ::projectgui::icon::pause22 {
        ......................
        ......................
        ......................
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        .....XXXX....XXXX.....
        ......................
        ......................
        ......................
        ......................
        ......................
        ......................
    } {
        .  trans
        X  #000000
    }


    mkicon ::projectgui::icon::rewind22 {
        ......................
        ......................
        ......................
        ...X............XX....
        ...X..........XXXX....
        ...X........XXXXXX....
        ...X......XXXXXXXX....
        ...X....XXXXXXXXXX....
        ...X..XXXXXXXXXXXX....
        ...XXXXXXXXXXXXXXX....
        ...X..XXXXXXXXXXXX....
        ...X....XXXXXXXXXX....
        ...X......XXXXXXXX....
        ...X........XXXXXX....
        ...X..........XXXX....
        ...X............XX....
        ......................
        ......................
        ......................
        ......................
        ......................
        ......................
    } {
        .  trans
        X  #000000
    }


    mkicon ::projectgui::icon::first16 {
        ................
        .X.....X.....X..
        .X....XX....XX..
        .X...XXX...XXX..
        .X..XXXX..XXXX..
        .X.XXXXX.XXXXX..
        .XXXXXXXXXXXXX..
        .X.XXXXX.XXXXX..
        .X..XXXX..XXXX..
        .X...XXX...XXX..
        .X....XX....XX..
        .X.....X.....X..
        ................
        ................
        ................
        ................
    } {
        .  trans
        X  #000000
    }


    mkicon ::projectgui::icon::prev16 {
        ................
        .......X.....X..
        ......XX....XX..
        .....XXX...XXX..
        ....XXXX..XXXX..
        ...XXXXX.XXXXX..
        ..XXXXXXXXXXXX..
        ...XXXXX.XXXXX..
        ....XXXX..XXXX..
        .....XXX...XXX..
        ......XX....XX..
        .......X.....X..
        ................
        ................
        ................
        ................
    } {
        .  trans
        X  #000000
    }


    mkicon ::projectgui::icon::next16 {
        ................
        .X.....X........
        .XX....XX.......
        .XXX...XXX......
        .XXXX..XXXX.....
        .XXXXX.XXXXX....
        .XXXXXXXXXXXX...
        .XXXXX.XXXXX....
        .XXXX..XXXX.....
        .XXX...XXX......
        .XX....XX.......
        .X.....X........
        ................
        ................
        ................
        ................
    } {
        .  trans
        X  #000000
    }


    mkicon ::projectgui::icon::last16 {
        ................
        .X.....X.....X..
        .XX....XX....X..
        .XXX...XXX...X..
        .XXXX..XXXX..X..
        .XXXXX.XXXXX.X..
        .XXXXXXXXXXXXX..
        .XXXXX.XXXXX.X..
        .XXXX..XXXX..X..
        .XXX...XXX...X..
        .XX....XX....X..
        .X.....X.....X..
        ................
        ................
        ................
        ................
    } {
        .  trans
        X  #000000
    }

}


