#-----------------------------------------------------------------------
# TITLE:
#    mapicons.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This module defines a generic unit icon for use with
#    mapcanvas(n).  It adheres to the mapicon(i) interface.
#
#-----------------------------------------------------------------------


snit::type ::mapicon::unit {
    #-------------------------------------------------------------------
    # Type Methods

    typemethod typename {} {
        return "unit"
    }

    #-------------------------------------------------------------------
    # Components

    component can         ;# The mapcanvas

    #-------------------------------------------------------------------
    # Instance variables

    variable drawn 0      ;# 1 if the icon has ever been drawn, 0 o.w.
    variable me           ;# The icon name in the mapcanvas: the 
                           # tail of the command name.
    variable tags {}      ;# Tags for all components of the icon

    #-------------------------------------------------------------------
    # Options

    # -shape shape
    #
    # Determines the shape of the icon: FRIEND is rectangular,
    # NEUTRAL is square, ENEMY is diamond.

    option -shape \
        -default         NEUTRAL                  \
        -type            ::projectlib::eunitshape \
        -configuremethod ConfigureShape

    method ConfigureShape {opt val} {
        if {$drawn} {
            # Need to get origin before the new shape is set.
            set origin [$self origin]
        }

        set options($opt) [eunitshape name $val]

        if {$drawn} {
            # Redraw the icon
            $self draw {*}$origin
        }
    }


    # -symbol list
    #
    # Determines the symbols displayed in the shape.
    
    option -symbol \
        -default         infantry                                         \
        -type            {snit::listtype -type ::projectlib::eunitsymbol} \
        -configuremethod ConfigureSymbols

    method ConfigureSymbols {opt val} {
        foreach sym $val {
            lappend newval [eunitsymbol name $sym] 
        }

        set options($opt) $newval

        if {$drawn} {
            # Redraw the icon
            $self draw {*}[$self origin]
        }
    }

    # -foreground color

    option -foreground                        \
        -default         white                \
        -configuremethod ConfigureForeground

    method ConfigureForeground {opt val} {
        set options($opt) $val

        if {$drawn} {
            $can itemconfigure $me&&unitshape   -outline $val
            $can itemconfigure $me&&unitsymbol -fill    $val
        }
    }

    # -background color

    option -background                        \
        -default         black                \
        -configuremethod ConfigureBackground

    method ConfigureBackground {opt val} {
        set options($opt) $val

        if {$drawn} {
            $can itemconfigure $me&&unitshape -fill $val
        }
    }

    # -tags taglist
    #
    # Additional tags the icon should receive.

    option -tags \
        -configuremethod ConfigureTags

    method ConfigureTags {opt val} {
        set options($opt) $val

        set tags [list $me [$type typename] icon {*}$val]
    }


    #-------------------------------------------------------------------
    # Constructor

    constructor {mapcanvas cx cy args} {
        # FIRST, save the canvas and the name
        set can $mapcanvas
        set me [namespace tail $self]

        # NEXT, configure the options.  Force configuration of the tags.
        $self configure -tags {} {*}$args

        # NEXT, draw the unit.
        $self draw $cx $cy
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
        # FIRST, we've now drawn the icon at least once.
        set drawn 1

        # NEXT, delete the icon from its current location
        $can delete $me

        # NEXT, draw the shape
        set coords [$self DrawShape $options(-shape) $cx $cy]

        # NEXT, draw the symbol(s)
        foreach sym $options(-symbol) {
            $self DrawSymbol $sym $coords
        }
    }

    
    #-------------------------------------------------------------------
    # Private Methods

    # DrawShape FRIEND cx cy
    #
    # Draws the background shape for FRIENDs.  This is a rectangle
    # that's 1.5*L wide by L high, per Table VII of MIL-STD-2525B.
    # Here, L is 20 pixels.

    method {DrawShape FRIEND} {cx cy} {
        set x1 $cx
        set x2 [expr {$cx + 30}]
        set y1 [expr {$cy - 20}]
        set y2 $cy

        set coords [list $x1 $y1 $x2 $y2]

        $can create rectangle $coords       \
            -width   2                      \
            -outline $options(-foreground)  \
            -fill    $options(-background)  \
            -tags    [concat $tags unitshape]

        return $coords
    }
    

    # DrawShape NEUTRAL cx cy
    #
    # Draws the background shape for NEUTRALs.  This is a square
    # that's 1.1*L wide by 1.1*L high, per Table VII of MIL-STD-2525B.
    # Here, L is 20 pixels.

    method {DrawShape NEUTRAL} {cx cy} {
        set x1 $cx
        set x2 [expr {$cx + 22}]
        set y1 [expr {$cy - 22}]
        set y2 $cy

        set coords [list $x1 $y1 $x2 $y2]

        $can create rectangle $coords       \
            -width   2                      \
            -outline $options(-foreground)  \
            -fill    $options(-background)  \
            -tags    [concat $tags unitshape]

        return $coords
    }


    # DrawShape ENEMY cx cy
    #
    # Draws the background shape for ENEMY's.  This is a diamond
    # that's 1.44*L wide by 1.44*L high, per Table VII of MIL-STD-2525B.
    # Here, L is 20 pixels, 1.44*L is 28.8.  We'll call it 29.  The 
    # reference point is the left-hand point of the diamond.

    method {DrawShape ENEMY} {cx cy} {
        set x1 $cx
        set x2 [expr {$cx + 22}]
        set y1 [expr {$cy - 22}]
        set y2 $cy

        set coords [list $cx $cy                             \
                        [expr {$cx + 15}] [expr {$cy - 15}]  \
                        [expr {$cx + 30}] $cy                \
                        [expr {$cx + 15}] [expr {$cy + 15}]]

        $can create polygon $coords         \
            -width   2                      \
            -outline $options(-foreground)  \
            -fill    $options(-background)  \
            -tags    [concat $tags unitshape]

        return $coords
    }


    # DrawSymbol infantry coords ?dash?
    #
    # coords    Coordinates of the icon shape
    # stipple   Stipple bitmap
    #
    # Draws the infantry symbol.

    method {DrawSymbol infantry} {coords} {
        if {$options(-shape) eq "ENEMY"} {
            lassign $coords cx cy

            set x1 [expr {$cx + 5}]
            set y1 [expr {$cy - 5}]
            set x2 [expr {$cx + 25}]
            set y2 [expr {$cy + 5}]
        } else {
            lassign $coords x1 y1 x2 y2
        }

        $self SymLine $x1 $y1 $x2 $y2
        $self SymLine $x1 $y2 $x2 $y1
    }

    # DrawSymbol criminal coords
    #
    # coords    Coordinates of the icon shape
    #
    # Draws the criminal symbol: an angry face

    method {DrawSymbol criminal} {coords} {
        # FIRST, get the center point.
        lassign [$self Center $coords] cx cy

        # NEXT, draw left eyebrow
        $self SymLine \
            [expr {$cx - 4}] [expr {$cy - 4}]  \
            [expr {$cx - 1}] [expr {$cy - 1}]

        # NEXT, draw left eye
        $self SymLine \
            [expr {$cx - 4}] [expr {$cy - 1}] \
            [expr {$cx - 3}] [expr {$cy - 0}]

        # NEXT, draw right eyebrow. The pixel choices are odd
        # to work around weird canvas behavior
        $self SymLine \
            [expr {$cx + 5}] [expr {$cy - 5}]  \
            [expr {$cx + 2}] [expr {$cy - 2}]

        # NEXT, draw right eye
        $self SymLine \
            [expr {$cx + 5}] [expr {$cy + 0}] \
            [expr {$cx + 4}] [expr {$cy - 1}]

        # NEXT, draw mouth
        $self SymLine \
            [expr {$cx - 6}] [expr {$cy + 4}]  \
            [expr {$cx + 7}] [expr {$cy + 4}]
    }

    # DrawSymbol police coords
    #
    # coords    Coordinates of the icon shape
    #
    # Draws the police symbol

    method {DrawSymbol police} {coords} {
        # FIRST, get the center point.
        lassign [$self Center $coords] cx cy

        # NEXT, draw shield
        $self SymLine \
            [expr {$cx - 5}] [expr {$cy - 6}]  \
            [expr {$cx - 2}] [expr {$cy - 3}]  \
            $cx              [expr {$cy - 6}]  \
            [expr {$cx + 2}] [expr {$cy - 3}]  \
            [expr {$cx + 5}] [expr {$cy - 6}]  \
            [expr {$cx + 5}] [expr {$cy + 3}]  \
            $cx              [expr {$cy + 5}]  \
            [expr {$cx - 5}] [expr {$cy + 3}]  \
            [expr {$cx - 5}] [expr {$cy - 5}]

    }

    # DrawSymbol medical coords
    #
    # coords    Coordinates of the icon shape
    #
    # Draws the medical symbol: a small cross.

    method {DrawSymbol medical} {coords} {
        # FIRST, get the center point.
        lassign [$self Center $coords] cx cy

        # NEXT, draw cross
        $self SymLine \
            [expr {$cx - 4}] [expr {$cy - 5}]  \
            [expr {$cx - 4}] [expr {$cy + 0}]

        $self SymLine \
            [expr {$cx - 6}] [expr {$cy - 3}] \
            [expr {$cx - 1}] [expr {$cy - 3}]
    }


    # DrawSymbol support coords
    #
    # coords    Coordinates of the icon shape
    #
    # Draws the support symbol: a banana?

    method {DrawSymbol support} {coords} {
        # FIRST, get the center point.
        lassign [$self Center $coords] cx cy

        # NEXT, draw banana
        $self SymLine \
            [expr {$cx + 5}] [expr {$cy - 8}] \
            [expr {$cx + 2}] [expr {$cy - 4}] \
            [expr {$cx + 5}] [expr {$cy + 0}]

    }


    # DrawSymbol engineer coords
    #
    # coords    Coordinates of the icon shape
    #
    # Draws the medical symbol: a small cross.

    method {DrawSymbol engineer} {coords} {
        # FIRST, get the center point.
        lassign [$self Center $coords] cx cy

        # NEXT, draw body of E
        $self SymLine \
            [expr {$cx - 5}] [expr {$cy + 5}] \
            [expr {$cx - 5}] [expr {$cy + 1}] \
            [expr {$cx + 5}] [expr {$cy + 1}] \
            [expr {$cx + 5}] [expr {$cy + 5}]

        # NEXT, draw center line
        $self SymLine \
            $cx              [expr {$cy + 1}] \
            $cx              [expr {$cy + 5}]
    }


    # SymLine x1 y1 x2 y2...
    #
    # Draws a unit symbol line

    method SymLine {args} {
        $can create line $args                 \
            -width   1                         \
            -fill    $options(-foreground)     \
            -tags    [concat $tags unitsymbol]
    }

    # Center coords
    #
    # coords    shape coordinates
    #
    # Returns the icon's center point

    method Center {coords} {
        if {$options(-shape) eq "ENEMY"} {
            lassign $coords cx cy
            set cx [expr {$cx + 15}]
        } else {
            lassign $coords x1 y1 x2 y2
            
            set cx [expr {($x1 + $x2)/2}]
            set cy [expr {($y1 + $y2)/2}]
        }

        return [list $cx $cy]
    }


    #-------------------------------------------------------------------
    # Public Meetings

    # origin
    #
    # Returns the current origin of the icon: the lower left point
    # for FRIEND and NEUTRAL, and the leftmost point for ENEMY.

    method origin {} {
        set coords [$can coords $me&&unitshape]

        if {$options(-shape) eq "ENEMY"} {
            return [lrange $coords 0 1]
        } else {
            return [list [lindex $coords 0] [lindex $coords 3]]
        }
    }
}

::projectgui::mapcanvas icon register ::mapicon::unit
