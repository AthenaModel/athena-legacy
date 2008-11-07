#-----------------------------------------------------------------------
# TITLE:
#    mapicons.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This module defines some preliminary icon types for use with
#    mapcanvas.
#
# mapicon(i) Interface:
#
#    mapicon <name> <mapcanvas> <cx> <cy> <options....>
#
#       Each mapicon is created as an instance command called <name>.
#       It is drawn on some <mapcanvas>.   It is drawn at some pair of 
#       canvas coordinates <cx> <cy>; mapicons are not aware of map 
#       coordinates.  It can take a variety of options, determined by
#       the icon type.
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# infantry
#
# An infantry icon: a rectangle with diagonal lines.


snit::type ::mapicon::infantry {

    #-------------------------------------------------------------------
    # Type Methods

    typemethod typename {} {
        return "infantry"
    }

    #-------------------------------------------------------------------
    # Components

    component can         ;# The mapcanvas

    #-------------------------------------------------------------------
    # Instance variables

    variable me           ;# The icon name in the mapcanvas: the 
                           # tail of the command name.

    #-------------------------------------------------------------------
    # Options

    # -foreground color

    option -foreground                        \
        -default         black                \
        -configuremethod ConfigureForeground

    method ConfigureForeground {opt val} {
        set options($opt) $val

        $can itemconfigure $me.rect  -outline $val
        $can itemconfigure $me.lines -fill    $val
    }

    # -background color

    option -background                        \
        -default         gray                 \
        -configuremethod ConfigureBackground

    method ConfigureBackground {opt val} {
        set options($opt) $val
        $can itemconfigure $me.rect -fill $val
    }

    # -tags taglist
    #
    # Additional tags the icon should receive.

    option -tags


    #-------------------------------------------------------------------
    # Constructor

    constructor {mapcanvas cx cy args} {
        # FIRST, save the canvas and the name
        set can $mapcanvas
        set me [namespace tail $self]

        # NEXT, draw the unit.
        $self draw $cx $cy

        # NEXT, configure the options
        $self configurelist $args
    }

    destructor {
        catch {$can delete $me}
    }

    #-------------------------------------------------------------------
    # Public Methods

    # draw cx cy
    #
    # cx,cy      A location in canvas coordinates
    #
    # Draws the icon at the specified location using the current
    # option settings

    method draw {cx cy} {
        # FIRST, delete the icon from its current location
        $can delete $me

        # NEXT, draw the icon.
        set x1 $cx
        set x2 [expr {$cx + 30}]
        set y1 [expr {$cy - 20}]
        set y2 $cy

        # There are two sets of items: the underlying rectangle
        # and the crossed lines.

        # $self.rect
        $can create rectangle $x1 $y1 $x2 $y2            \
            -outline $options(-foreground)               \
            -fill    $options(-background)               \
            -tags    [list $me $me.rect [$type typename] icon {*}$options(-tags)]
        
        # $self.lines
        $can create line $x1 $y1 $x2 $y2                 \
            -fill $options(-foreground)                  \
            -tags [list $me $me.lines [$type typename] icon {*}$options(-tags)]

        $can create line $x1 $y2 $x2 $y1                 \
            -fill $options(-foreground)                  \
            -tags [list $me $me.lines [$type typename] icon {*}$options(-tags)]
    }
}

::mingui::mapcanvas icon register ::mapicon::infantry


#-----------------------------------------------------------------------
# Bomb

snit::type ::mapicon::bomb {
    #-------------------------------------------------------------------
    # Type constructor

    typeconstructor {
        mkicon ${type}::icon {
            .......................
            .............XXX.......
            ...........XXX.........
            ...........X...........
            ..........XXX..........
            ..........XXX..........
            ..........XXX..........
            ........XXXXXXX........
            .......XXXXXXXXX.......
            ......XXXXXXXXXXX......
            ......XXXXXXXXXXX......
            ......XXXXXXXXXXX......
            ......XXXXXXXXXXX......
            .......XXXXXXXXX.......
            ........XXXXXXX........
            ..........XXX..........
            .......................
            .......................
            .......................
            .......................
        } {
            .  trans
            X  #000000
        }
    }

    #-------------------------------------------------------------------
    # Type Methods

    typemethod typename {} {
        return "bomb"
    }

    #-------------------------------------------------------------------
    # Components

    component can         ;# The mapcanvas

    #-------------------------------------------------------------------
    # Instance variables

    variable me           ;# The icon name in the mapcanvas: the 
                           # tail of the command name.

    #-------------------------------------------------------------------
    # Options

    # -tags taglist
    #
    # Additional tags the icon should receive.

    option -tags

    #-------------------------------------------------------------------
    # Constructor

    constructor {mapcanvas cx cy args} {
        # FIRST, save the canvas and the name
        set can $mapcanvas
        set me [namespace tail $self]

        # NEXT, draw the icon.
        $self draw $cx $cy

        # NEXT, configure the options
        $self configurelist $args
    }

    destructor {
        catch {$can delete $me}
    }


    #-------------------------------------------------------------------
    # Public Methods

    # draw cx cy
    #
    # cx,cy      A location in canvas coordinates
    #
    # Draws the icon at the specified location using the current
    # option settings

    method draw {cx cy} {
        # FIRST, delete the icon from its current location
        $can delete $me

        # NEXT, draw the icon.
        $can create image $cx $cy               \
            -image  ${type}::icon               \
            -anchor sw                          \
            -tags   [list $me [$type typename] icon {*}$options(-tags)]
    }

}

::mingui::mapcanvas icon register ::mapicon::bomb


#-----------------------------------------------------------------------
# Power Plant

snit::type ::mapicon::powerplant {
    #-------------------------------------------------------------------
    # Type constructor

    typeconstructor {
        mkicon ${type}::icon {
            
            ..XX...XX.......
            ..XX...XX.......
            ..XX...XX.......
            ..XX...XX.......
            ..XX...XX.......
            ..XX...XX.......
            XXXXXXXXXXXXXXXX
            XXXXXXXXXXXXXXXX
            XXXXXXXXXXXXXXXX
            XXXXXXXXXXXXXXXX
            XXXXXXXXXXXXXXXX
            XXXXXXXXXXXXXXXX
        } {
            .  trans
            X  #000000
        }
    }

    #-------------------------------------------------------------------
    # Type Methods

    typemethod typename {} {
        return "powerplant"
    }

    #-------------------------------------------------------------------
    # Components

    component can         ;# The mapcanvas

    #-------------------------------------------------------------------
    # Instance variables

    variable me           ;# The icon name in the mapcanvas: the 
                           # tail of the command name.

    #-------------------------------------------------------------------
    # Options

    # -tags taglist
    #
    # Additional tags the icon should receive.

    option -tags

    #-------------------------------------------------------------------
    # Constructor

    constructor {mapcanvas cx cy args} {
        # FIRST, save the canvas and the name
        set can $mapcanvas
        set me [namespace tail $self]

        # NEXT, draw the icon.
        $self draw $cx $cy

        # NEXT, configure the options
        $self configurelist $args
    }

    destructor {
        catch {$can delete $me}
    }

    #-------------------------------------------------------------------
    # Public Methods

    # draw cx cy
    #
    # cx,cy      A location in canvas coordinates
    #
    # Draws the icon at the specified location using the current
    # option settings

    method draw {cx cy} {
        # FIRST, delete the icon from its current location
        $can delete $me

        # NEXT, draw the icon.
        $can create image $cx $cy               \
            -image  ${type}::icon               \
            -anchor sw                          \
            -tags   [list $me [$type typename] icon {*}$options(-tags)]
    }
}

::mingui::mapcanvas icon register ::mapicon::powerplant
