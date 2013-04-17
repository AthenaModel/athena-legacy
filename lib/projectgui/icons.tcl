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

    mkicon ::projectgui::icon::locked22 {
        ......................
        ......XXXXXXXXXX......
        .....XXXXXXXXXXXX.....
        .....XX........XX.....
        .....XX........XX.....
        .....XX........XX.....
        .....XX........XX.....
        ...XXXXXXXXXXXXXXXX...
        ...X..............X...
        ...X...XXXXXXX....X...
        ...X...XXXXXXXX...X...
        ...X...XX....XX...X...
        ...X...XX....XX...X...
        ...X...XX....XX...X...
        ...X...XXXXXXXX...X...
        ...X...XXXXXXX....X...
        ...X...XX.........X...
        ...X...XX.........X...
        ...X...XX.........X...
        ...X..............X...
        ...XXXXXXXXXXXXXXXX...
        ......................
    } { . trans X black } d { X gray }

    mkicon ::projectgui::icon::unlocked22 {
        ......................
        ......XXXXXXXXXX......
        .....XXXXXXXXXXXX.....
        .....XX........XX.....
        .....XX........XX.....
        .....XX...............
        .....XX...............
        ...XXXXXXXXXXXXXXXX...
        ...X..............X...
        ...X...XXXXXXX....X...
        ...X...XXXXXXXX...X...
        ...X...XX....XX...X...
        ...X...XX....XX...X...
        ...X...XX....XX...X...
        ...X...XXXXXXXX...X...
        ...X...XXXXXXX....X...
        ...X...XX.........X...
        ...X...XX.........X...
        ...X...XX.........X...
        ...X..............X...
        ...XXXXXXXXXXXXXXXX...
        ......................
    } { . trans X black } d { X gray }



    mkicon ::projectgui::icon::nbpoly {
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



    mkicon ::projectgui::icon::actor12 {
        ...XX..
        ..XXXX.
        ..XXXX.
        ...XX..
        .XXXXXX
        .X.XX.X
        .X.XX.X
        ...XX..
        ..XXXX.
        ..X..X.
        ..X..X.
        ..X..X.
    } { . trans X black }

    mkicon ::projectgui::icon::hook12 {
        .........X
        .........X
        ......X..X
        ..xxx.XX.X
        .xxxxxX..X
        .xxxxx.XX.
        .xxxxx....
        ..xxx.....
        xxxxxxx...
        xxxxxxxx..
    } { . trans X black x #999999 }

    mkicon ::projectgui::icon::message12 {
        ........
        ..XXXXXX
        .X.X...X
        XXXX...X
        X......X
        X.xxxx.X
        X......X
        X.xxx..X
        X......X
        X.xxxx.X
        X......X
        XXXXXXXX
    } { . trans X black x #666666 } 

    mkicon ::projectgui::icon::dollar12 {
       ....X....
       ..XXXXX..
       .XX.X.XX.
       .XX.X..X.
       ..X.X....
       ...XX....
       ....XX...
       ....X.X..
       .X..X.XX.
       .XX.X.XX.
       ..XXXXX..
       ....X....
    } { . trans X #216C2A } 

    mkicon ::projectgui::icon::heart12 {
       .........
       .........
       .........
       .XXX.XXX.
       XXXXXXXXX
       XXXXXXXXX
       .XXXXXXX.
       ..XXXXX..
       ...XXX...
       ....X....
       .........
       .........
    } { . trans X red } 


    mkicon ::projectgui::icon::blackheart12 {
       .........
       .........
       .........
       .XXX.XXX.
       XXXXXXXXX
       XXXXXXXXX
       .XXXXXXX.
       ..XXXXX..
       ...XXX...
       ....X....
       .........
       .........
    } { . trans X black } 

    mkicon ::projectgui::icon::blueheart12 {
       .........
       .........
       .........
       .XXX.XXX.
       XXXXXXXXX
       XXXXXXXXX
       .XXXXXXX.
       ..XXXXX..
       ...XXX...
       ....X....
       .........
       .........
    } { . trans X blue } 



    mkicon ::projectgui::icon::cap12 {
        .X.xx.X.
        X.xxxx.X
        X.xxxx.X
        .X.xx.X.
        ...xx...
        ...xx...
        ...xx...
        ...xx...
        ...xx...
        ...xx...
        ...xx...
        ...xx...
    } { . trans X black x "#666666"}

    mkicon ::projectgui::icon::nbhood12 {
        .......
        ...X...
        ..XXX..
        .XX,XX.
        XX,,,XX
        X,,,,,X
        .X,,,,X
        .X,,,,X
        X,,,,,X
        XX,,,,X
        ..XX,,X
        ....XX.
    } { . trans , "#00AA00" X black }

    mkicon ::projectgui::icon::group12 {
        ...X...
        ..XXX..
        ...X...
        .X...X.
        XXX.XXX
        .X...X.
        ...X...
        ..XXX..
        ...X...
        .X...X.
        XXX.XXX
        .X...X.
    } { . trans X black }

    mkicon ::projectgui::icon::frcgroup12 {
        ...X...
        ..XXX..
        ...X...
        .X...X.
        XXX.XXX
        .X...X.
        ...X...
        ..XXX..
        ...X...
        .X...X.
        XXX.XXX
        .X...X.
    } { . trans X "#CC0000" }

    mkicon ::projectgui::icon::civgroup12 {
        ...X...
        ..XXX..
        ...X...
        .X...X.
        XXX.XXX
        .X...X.
        ...X...
        ..XXX..
        ...X...
        .X...X.
        XXX.XXX
        .X...X.
    } { . trans X "#00AA00" }

    mkicon ::projectgui::icon::orggroup12 {
        ...X...
        ..XXX..
        ...X...
        .X...X.
        XXX.XXX
        .X...X.
        ...X...
        ..XXX..
        ...X...
        .X...X.
        XXX.XXX
        .X...X.
    } { . trans X "#0000FF" }

    mkicon ::projectgui::icon::eye12 {
        ............
        ............
        ..X..X..X...
        X..XXXXX..X.
        .XX.....XX..
        XX..XXX..XX.
        X..XXXXX..X.
        XX..XXX..XX.
        .XX.....XX..
        ...XXXXX....
        ............
        ............
    } { . trans X black , "#0AAEBD" }

    mkicon ::projectgui::icon::gpoly {
        ..XX..........
        ..X.XX........
        ..X...XX......
        ..X.....XX....
        .X........XX..
        .X..........XX
        .X..XXXXX....X
        .X.X.....X...X
        X..X.........X
        X..X.........X
        X..X..XXXX...X
        X..X.....X...X
        .X.X.....X...X
        .X..XXXXX....X
        .X...........X
        .X.........XXX
        ..X.....XXX...
        ..X..XXX......
        ..XXX.........
    } { . trans  X black } d { X gray }
}


