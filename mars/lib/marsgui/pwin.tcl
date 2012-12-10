#-----------------------------------------------------------------------
# FILE: pwin.tcl
#   
#   Pseudo-window Widget
#
# PACKAGE:
#   marsgui(n) -- Mars GUI Infrastructure Package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

namespace eval ::marsgui:: {
    namespace export pwin
}

#-----------------------------------------------------------------------
# Widget: pwin
#
# A pseudo-window is a fancy window frame for widgets in a pwinman(n)
# widget.
#
#-----------------------------------------------------------------------

snit::widget ::marsgui::pwin {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        namespace import ::marsutil::*

        #---------------------------------------------------------------
        # Icons

        namespace eval ${type}::icon:: {}

        mkicon ${type}::icon::close {
            XX....XX
            XXX..XXX
            .XXXXXX.
            ..XXXX..
            ..XXXX..
            .XXXXXX.
            XXX..XXX
            XX....XX
        } { . trans  X black } d { X gray }

        mkicon ${type}::icon::down {
            ..........
            XXXXXXXXXX
            .XXXXXXXX.
            ..XXXXXX..
            ...XXXX...
            ....XX....
            ..........
            ..........
        } { . trans  X black } d { X gray }

        mkicon ${type}::icon::up {
            .........
            ..........
            ....XX....
            ...XXXX...
            ..XXXXXX..
            .XXXXXXXX.
            XXXXXXXXXX
            .........
        } { . trans  X black } d { X gray }

    }

    #-------------------------------------------------------------------
    # Group: Components

    # Component: bar
    #
    # The toolbar

    component bar

    # Component: title
    #
    # The title label

    component title

    # Component: up
    #
    # The up button

    component up

    # Component: down
    #
    # The down button

    component down

    # Component: close
    #
    # The close button

    component close

    # Component: inner
    #
    # The inner frame, in which the user can put widgets.

    component inner

    #-------------------------------------------------------------------
    # Group: Options
    #
    # Delegate all options to the hull

    delegate option * to hull

    delegate option -title     to title as -text
    delegate option -titlefont to title as -font

    # Option: -command
    #
    # A command to be called when a toolbar button is pressed.
    # The command is called with one additional argument, 
    # *up*, *down*, or *close*.

    option -command

    # Option: -upstate
    #
    # Sets the -state of the up button.

    delegate option -upstate to up as -state

    # Option: -downstate
    #
    # States the -state of the down button.

    delegate option -downstate to down as -state

    # Option: -closestate
    #
    # Sets the -state of the close button.

    delegate option -closestate to close as -state

    #-------------------------------------------------------------------
    # Group: Constructor

    # Constructor: constructor
    #
    # The constructor creates the frame.

    constructor {args} {
        # FIRST, configure standard options
        $hull configure         \
            -borderwidth 1      \
            -relief      raised 

        # NEXT, create the toolbar.
        install bar using ttk::frame $win.bar

        install title using ttk::label $bar.title

        $self MakeButton up
        $self MakeButton down
        $self MakeButton close

        pack $bar.title -side left -padx 2
        pack $bar.close -side right -padx {2 0}
        pack $bar.down  -side right
        pack $bar.up    -side right

        # NEXT, create the inner frame

        install inner using ttk::frame $win.inner \
            -borderwidth 1                        \
            -relief      sunken

        pack $bar   -side top -fill x -padx 3
        pack $inner -fill both -expand yes -padx 3 -pady {0 3}

        # NEXT, apply the user's options
        $self configurelist $args
    }

    # Method: MakeButton
    #
    # Creates a toolbutton in the toolbar with the specified flavor
    #
    # Syntax:
    #   MakeButton _flavor_
    #
    #   flavor - *up*, *down*, *close*

    method MakeButton {flavor} {
        install $flavor using ttk::button $bar.$flavor \
            -style   Toolbutton                   \
            -image   [list ${type}::icon::$flavor \
                          disabled ${type}::icon::${flavor}d] \
            -command [mymethod CallCommand $flavor]
    }

    #-------------------------------------------------------------------
    # Group: Event Handlers

    # Method: CallCommand
    #
    # Calls the -command callback.
    #
    # Syntax:
    #   CallCommand _flavor_
    #
    #   flavor - *up*, *down*, *close*

    method CallCommand {flavor} {
        callwith $options(-command) $flavor
    }



    #-------------------------------------------------------------------
    # Group: Public Methods

    # Method: frame
    #
    # Returns the name of the inner frame, in which the client can
    # manage their own widgets.

    method frame {} {
        return $inner
    }



}