#-----------------------------------------------------------------------
# TITLE:
#    paner.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsgui(n) paner widget
#
#    This widget manages two widgets, one on top and one on the bottom,
#    or one to the left and one to the right, and allows their relative 
#    sizes to be adjusted by the user.  It also ensures that resizing 
#    the window will not make the second pane disappear.
#
#    The paner(n) widget is a Tk panedwindow(n) widget with some
#    extra behavior to ensure that window resizing is handled properly.
#
#-----------------------------------------------------------------------

namespace eval ::marsgui:: {
    namespace export paner
}

#-----------------------------------------------------------------------
# paner

snit::widgetadaptor ::marsgui::paner {
    #-------------------------------------------------------------------
    # Inheritance

    delegate option * to hull
    delegate method * to hull

    #-------------------------------------------------------------------
    # Constructor 

    constructor {args} {
        # FIRST, install the hull
        # TBD: Put this in global.tcl?
        installhull [panedwindow $win         \
                         -relief       flat   \
                         -borderwidth  0      \
                         -showhandle   0      \
                         -sashpad      0      \
                         -opaqueresize on     \
                         -sashwidth    3      \
                         -sashrelief   sunken]

        # NEXT, handle user's options
        $self configurelist $args

        # NEXT, prepare to handle resizes
        bind $win <Configure> [mymethod Resize]
    }

    #-------------------------------------------------------------------
    # Event Handlers

    # Resize
    # 
    # Called on window <Configure>; makes sure that the last window
    # is visible.

    method Resize {} {
        # FIRST, are we vertical or horizontal?
        if {[$hull cget -orient] eq "vertical"} {
            set vflag 1
        } else {
            set vflag 0
        }

        # NEXT, get the size of the whole panedwindow
        if {$vflag} {
            set size [winfo height $win]
        } else {
            set size [winfo width $win]
        }
        
        # NEXT, get the min size of the second pane
        set minSize [$hull panecget [lindex [$win panes] 1] -minsize]

        # NEXT, get the position of the sash separating the
        # two panes
        set sashPos [lindex [$hull sash coord 0] $vflag]

        # NEXT, if the sash position is such that the second pane
        # can't be seen, do something about it.
        if {$sashPos > $size - $minSize} {
            # set newPos [expr {$size/2}]
            set newPos [expr {$size - $minSize}]

            if {$vflag} {
                $hull sash place 0 0 $newPos
            } else {
                $hull sash place 0 $newPos 0
            }
        }
    }
}



