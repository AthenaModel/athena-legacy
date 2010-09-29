#-----------------------------------------------------------------------
# TITLE:
#    marsicons.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsgui(n) package: standard icons
#
#    This module defines a set of standard icons for use in buttons,
#    etc.  All icons are defined in the ::marsgui::icon namespace; none
#    are exported.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Icon definitions

namespace eval ::marsgui::icon:: {
    namespace import ::marsgui::mkicon
    
    mkicon ::marsgui::icon::clear {
        ...XXXXX...
        ..XXXXXXX..
        .XX.XXX.XX.
        XX...X...XX
        XXX.....XXX
        XXXX...XXXX
        XXX.....XXX
        XX...X...XX
        .XX.XXX.XX.
        ..XXXXXXX..
        ...XXXXX...
        ...........
    } { . trans X black} d { X gray }
    
    mkicon ::marsgui::icon::clock {
        ....XXXXX....
        ..XX.....XX..
        .X....X....X.
        .X....X....X.
        X.....X.....X
        X.....X.....X
        X.....XXX...X
        X...........X
        X...........X
        .X.........X.
        .X.........X.
        ..XX.....XX..
        ..XXXXXXXXX..
        .XXXXXXXXXXX.
    } { . trans X black} d { X gray}
    
    mkicon ::marsgui::icon::filter {
        ........XXXXX...
        .......X.X.X.X..
        ......X.X.X.X.X.
        .....X.X.X.X.X.X
        .....XX.X.X.X.XX
        .....X.X.X.X.X.X
        .....XX.X.X.X.XX
        .....X.X.X.X.X.X
        ......X.X.X.X.X.
        .....XXX.X.X.X..
        ....XXX.XXXXX...
        ...XXX..........
        ..XXX....XXXXXXX
        .XXX......XXXXX.
        XXX........XXX..
        XX..........X...
    } {
        . trans
        X black
    }

    mkicon ::marsgui::icon::search {
        ........XXXXX...
        .......X.....X..
        ......X..XXX..X.
        .....X..X...X..X
        .....X.........X
        .....X.........X
        .....X.........X
        .....X.........X
        ......X.......X.
        .....XXX.....X..
        ....XXX.XXXXX...
        ...XXX..........
        ..XXX....XXXXXXX
        .XXX......XXXXX.
        XXX........XXX..
        XX..........X...
    } {
        . trans
        X black
    }
    
    mkicon ::marsgui::icon::autoscroll_on {
        ..XXXXXXXXXX..
        ..X........X..
        ..X.XX.XXX.X..
        ..X........X..
        ..X.XX.XXX.X..
        ..X........X..
        ..X.XX.XXX.X..
        ..X........X..
        XXXXXXXXXXXXXX
        X.X........X.X
        X.X.XX.XXX.X.X
        X.XXXXXXXXXX.X
        X............X
        XXXXXXXXXXXXXX
    } { . trans X black } d { X gray }

    mkicon ::marsgui::icon::autoscroll_off {
        ..XXXXXXXXXX..
        ..X........X..
        XXXXXXXXXXXXXX
        X.X........X.X
        X.X.XX.XXX.X.X
        X.X........X.X
        X.X.XX.XXX.X.X
        XXXXXXXXXXXXXX
        ..X........X..
        ..X.XX.XXX.X..
        ..X........X..
        ..XXXXXXXXXX..
        ..............
        ..............
    } { . trans X black } d { X gray }
    
    mkicon ::marsgui::icon::locked {
        ..............
        ...XXXXXXXX...
        ..XXXXXXXXXX..
        ..XX......XX..
        ..XX......XX..
        ..XX......XX..
        ..XX......XX..
        XXXXXXXXXXXXXX
        X............X
        X.XXXXXXXXXX.X
        X............X
        X.XXXXXXXXXX.X
        X............X
        X.XXXXXXXXXX.X
        X............X
        XXXXXXXXXXXXXX
    } { . trans X black } d { X gray }

    mkicon ::marsgui::icon::unlocked {
        ...XXXXXXXX...
        ..XXXXXXXXXX..
        ..XX......XX..
        ..XX......XX..
        ..XX..........
        ..XX..........
        ..XX..........
        XXXXXXXXXXXXXX
        X............X
        X.XXXXXXXXXX.X
        X............X
        X.XXXXXXXXXX.X
        X............X
        X.XXXXXXXXXX.X
        X............X
        XXXXXXXXXXXXXX
    } { . trans X black } d { X gray }
}


