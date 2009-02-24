#-----------------------------------------------------------------------
# TITLE:
#    messagebox.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: messagebox
#
#    This is a replacement for tk_messageBox with a slightly different
#    set of options.  In particular, the message box can include a
#    "Do not show this message again" check box; ignoring the message the
#    next time is automatic.
#
#-----------------------------------------------------------------------

namespace eval ::projectgui:: {
    namespace export messagebox
}

#-----------------------------------------------------------------------
# messagebox

snit::type ::projectgui::messagebox {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Create the icons
        namespace eval ${type}::icon { }

        mkicon ${type}::icon::question {
            ...........XXXXXXXXXX...........
            ........XXX,,,,,,,,,,XXX........
            ......XX,,,,,,,,,,,,,,,,XX......
            .....X,,,,,,,,,,,,,,,,,,,,X.....
            ....X,,,,,,,,,,,,,,,,,,,,,,X....
            ...X,,,,,,,,,@@@@@@,,,,,,,,,X...
            ..X,,,,,,,,,@,,,@@@@,,,,,,,,,X..
            .X,,,,,,,,,@@,,,,@@@@,,,,,,,,,X.
            .X,,,,,,,,,@@@,,,@@@@,,,,,,,,,X.
            X,,,,,,,,,,@@@,,,@@@@,,,,,,,,,,X
            X,,,,,,,,,,,@,,,@@@@,,,,,,,,,,,X
            X,,,,,,,,,,,,,,@@@@,,,,,,,,,,,,X
            X,,,,,,,,,,,,,@@@,,,,,,,,,,,,,,X
            X,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,X
            X,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,X
            X,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,X
            .X,,,,,,,,,,,,@@,,,,,,,,,,,,,,X.
            .X,,,,,,,,,,,@@@@,,,,,,,,,,,,,X.
            ..X,,,,,,,,,,@@@@,,,,,,,,,,,,X..
            ...X,,,,,,,,,,@@,,,,,,,,,,,,X...
            ....X,,,,,,,,,,,,,,,,,,,,,,X....
            .....XX,,,,,,,,,,,,,,,,,,,X.....
            .......XXX,,,,,,,,,,,,,XXX......
            ..........XX,,,,,,,XXXX.........
            ............XX,,,,X.............
            ..............X,,,X.............
            ..............X,,,X.............
            ...............X,,X.............
            ................X,X.............
            .................XX.............
            ................................
            ................................
        } {
            X black
            @ blue
            , white
            . trans
        }

        mkicon ${type}::icon::info {
            ...........XXXXXXXXXX...........
            ........XXX,,,,,,,,,,XXX........
            ......XX,,,,,,,,,,,,,,,,XX......
            .....X,,,,,,,,@@@@,,,,,,,,X.....
            ....X,,,,,,,,@@@@@@,,,,,,,,X....
            ...X,,,,,,,,,@@@@@@,,,,,,,,,X...
            ..X,,,,,,,,,,,@@@@,,,,,,,,,,,X..
            .X,,,,,,,,,,,,,,,,,,,,,,,,,,,,X.
            .X,,,,,,,,,,,,,,,,,,,,,,,,,,,,X.
            X,,,,,,,,,,,@@@@@@@,,,,,,,,,,,,X
            X,,,,,,,,,,,,@@@@@@,,,,,,,,,,,,X
            X,,,,,,,,,,,,,@@@@@,,,,,,,,,,,,X
            X,,,,,,,,,,,,,@@@@@,,,,,,,,,,,,X
            X,,,,,,,,,,,,,@@@@@,,,,,,,,,,,,X
            X,,,,,,,,,,,,,@@@@@,,,,,,,,,,,,X
            X,,,,,,,,,,,,,@@@@@,,,,,,,,,,,,X
            .X,,,,,,,,,,,,@@@@@,,,,,,,,,,,X.
            .X,,,,,,,,,,,@@@@@@@,,,,,,,,,,X.
            ..X,,,,,,,,,@@@@@@@@@,,,,,,,,X..
            ...X,,,,,,,,,,,,,,,,,,,,,,,,X...
            ....X,,,,,,,,,,,,,,,,,,,,,,X....
            .....XX,,,,,,,,,,,,,,,,,,,X.....
            .......XXX,,,,,,,,,,,,,XXX......
            ..........XX,,,,,,,XXXX.........
            ............XX,,,,X.............
            ..............X,,,X.............
            ..............X,,,X.............
            ...............X,,X.............
            ................X,X.............
            .................XX.............
            ................................
            ................................
        } {
            X black
            @ blue
            , white
            . trans
        }

        mkicon ${type}::icon::warning {
            ..............XXXX..............
            .............X,,,,X.............
            ............X,,,,,,X............
            ............X,,,,,,X............
            ...........X,,,,,,,,X...........
            ...........X,,,,,,,,X...........
            ..........X,,,,,,,,,,X..........
            ..........X,,,,,,,,,,X..........
            .........X,,,,,,,,,,,,X.........
            .........X,,,,@@@@,,,,X.........
            ........X,,,,@@@@@@,,,,X........
            ........X,,,,@@@@@@,,,,X........
            .......X,,,,,@@@@@@,,,,,X.......
            .......X,,,,,@@@@@@,,,,,X.......
            ......X,,,,,,@@@@@@,,,,,,X......
            ......X,,,,,,,@@@@,,,,,,,X......
            .....X,,,,,,,,@@@@,,,,,,,,X.....
            .....X,,,,,,,,@@@@,,,,,,,,X.....
            ....X,,,,,,,,,,@@,,,,,,,,,,X....
            ....X,,,,,,,,,,@@,,,,,,,,,,X....
            ...X,,,,,,,,,,,@@,,,,,,,,,,,X...
            ...X,,,,,,,,,,,,,,,,,,,,,,,,X...
            ..X,,,,,,,,,,,,@@,,,,,,,,,,,,X..
            ..X,,,,,,,,,,,@@@@,,,,,,,,,,,X..
            .X,,,,,,,,,,,,@@@@,,,,,,,,,,,,X.
            .X,,,,,,,,,,,,,@@,,,,,,,,,,,,,X.
            X,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,X
            X,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,X
            X,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,X
            .X,,,,,,,,,,,,,,,,,,,,,,,,,,,,X.
            ..XXXXXXXXXXXXXXXXXXXXXXXXXXXX..
            ................................
        } {
            X black
            @ black
            , yellow
            . trans
        }

        mkicon ${type}::icon::error {
            ............XXXXXXX.............
            .........XXX,,,,,,,XXX..........
            .......XX,,,,,,,,,,,,,XX........
            ......XX,,,,,,,,,,,,,,,XX.......
            .....X,,,,,,,,,,,,,,,,,,,X......
            ....X,,,,,,,,,,,,,,,,,,,,,X.....
            ...X,,,,,,,,,,,,,,,,,,,,,,,X....
            ..XX,,,,,@,,,,,,,,,,,@,,,,,XX...
            ..X,,,,,@@@,,,,,,,,,@@@,,,,,X...
            .X,,,,,@@@@@,,,,,,,@@@@@,,,,,X..
            .X,,,,,,@@@@@,,,,,@@@@@,,,,,,X..
            .X,,,,,,,@@@@@,,,@@@@@,,,,,,,X..
            X,,,,,,,,,@@@@@,@@@@@,,,,,,,,,X.
            X,,,,,,,,,,@@@@@@@@@,,,,,,,,,,X.
            X,,,,,,,,,,,@@@@@@@,,,,,,,,,,,X.
            X,,,,,,,,,,,,@@@@@,,,,,,,,,,,,X.
            X,,,,,,,,,,,@@@@@@@,,,,,,,,,,,X.
            X,,,,,,,,,,@@@@@@@@@,,,,,,,,,,X.
            X,,,,,,,,,@@@@@,@@@@@,,,,,,,,,X.
            .X,,,,,,,@@@@@,,,@@@@@,,,,,,,X..
            .X,,,,,,@@@@@,,,,,@@@@@,,,,,,X..
            .X,,,,,@@@@@,,,,,,,@@@@@,,,,,X..
            ..X,,,,,@@@,,,,,,,,,@@@,,,,,X...
            ..XX,,,,,@,,,,,,,,,,,@,,,,,XX...
            ...X,,,,,,,,,,,,,,,,,,,,,,,X....
            ....X,,,,,,,,,,,,,,,,,,,,,X.....
            .....X,,,,,,,,,,,,,,,,,,,X......
            ......XX,,,,,,,,,,,,,,,XX.......
            .......XX,,,,,,,,,,,,,XX........
            .........XXX,,,,,,,XXX..........
            ............XXXXXXX.............
            ................................
        } {
            X black
            @ white
            , red
            . trans
        }
    }

    #-------------------------------------------------------------------
    # Lookup Tables

    # iconnames: list of valid icons

    typevariable iconnames {error info question warning}

    #-------------------------------------------------------------------
    # Type Variables

    # dialog -- Name of the dialog widget

    typevariable dialog .messagebox

    # opts -- Array of option settings.  See popup for values

    typevariable opts -array {}

    # ignore -- Array of ignore flags by ignore tag.

    typevariable ignore -array {}

    # choice -- The user's choice
    typevariable choice {}


    #-------------------------------------------------------------------
    # Public methods

    # popup option value....
    #
    # -buttons dict          Dictionary {symbol labeltext ...} of buttons
    # -default symbol        Symbolic name of the default button
    # -icon image            error, info, question, warning
    # -ignoretag tag         Tag for ignoring this dialog
    # -ignoredefault symbol  Button "pressed" if dialog is ignored.
    # -message string        Message to display.  Will be wrapped.
    # -parent window         The message box appears over the parent window
    # -title string          Title of the message box
    #
    # Pops up the message box.  The -buttons will appear at the bottom,
    # left to right, packed to the right.  The specified button will be
    # the -default; or the first button is -default is not given.  The
    # -icon will be displayed; defaults to "info".  The -message will be 
    # wrapped into the message space.  The dialog will be application modal,
    # and centered over the specified -parent window.  It will have the
    # specified -title string.
    #
    # The command will wait until the user presses a button, and will
    # return the symbol for the button.
    #
    # If -ignoretag is specified, there will be a "Do not show this again"
    # checkbox just above the buttons.  If checked, this state will be
    # saved; if the dialog is requested again, it will simply return
    # the symbolic name of the -ignoredefault button.

    typemethod popup {args} {
        # FIRST, get the option values
        $type ParseOptions $args

        # NEXT, ignore it if they've so indicated
        if {[info exists ignore($opts(-ignoretag))] &&
            $ignore($opts(-ignoretag))
        } {
            return $opts(-ignoredefault)
        }

        # NEXT, create the dialog if it doesn't already exist.
        if {![winfo exists $dialog]} {
            # FIRST, create it
            toplevel $dialog           \
                -borderwidth 4         \
                -highlightthickness 0

            # NEXT, withdraw it; we don't want to see it yet
            wm withdraw $dialog

            # NEXT, the user can't resize it
            wm resizable $dialog 0 0

            # NEXT, it can't be closed
            wm protocol $dialog WM_DELETE_WINDOW {
                # Do nothing
            }

            # NEXT, it must be on top
            wm attributes $dialog -topmost 1

            # NEXT, create and grid the standard widgets
            
            # Row 1: Icon and message
            ttk::frame $dialog.top

            ttk::label $dialog.top.icon \
                -image  ${type}::icon::info \
                -anchor nw

            ttk::label $dialog.top.message \
                -textvariable [mytypevar opts(-message)] \
                -wraplength   3i                         \
                -anchor       nw                         \
                -justify      left

            grid $dialog.top.icon \
                -row 0 -column 0 -padx 8 -pady 4 -sticky nw 
            grid $dialog.top.message \
                -row 0 -column 1 -padx 8 -pady 4 -sticky new

            # Row 2: Ignore checkbox
            ttk::checkbutton $dialog.ignore                   \
                -text   "Do not show this message again"
            
            # Row 3: button box
            ttk::frame $dialog.button

            pack $dialog.top    -side top    -fill x
            pack $dialog.button -side bottom -fill x
        }

        # NEXT, configure the dialog according to the options
        
        # Set the title
        wm title $dialog $opts(-title)

        # Set the icon
        $dialog.top.icon configure \
            -image ${type}::icon::$opts(-icon)

        # Set the ignore tag
        if {$opts(-ignoretag) ne ""} {
            set ignore($opts(-ignoretag)) 0

            $dialog.ignore configure \
                -variable [mytypevar ignore($opts(-ignoretag))]

            pack $dialog.ignore \
                -after $dialog.top \
                -side  top         \
                -fill  x           \
                -padx  8           \
                -pady  4
        } else {
            $dialog.ignore configure \
                -variable ""

            pack forget $dialog.ignore
        }

        # Delete any old buttons
        foreach btn [winfo children $dialog.button] {
            destroy $btn
        }

        # Create the buttons
        foreach symbol [lreverse [dict keys $opts(-buttons)]] {
            set text [dict get $opts(-buttons) $symbol]

            set button($symbol) \
                [ttk::button $dialog.button.$symbol                 \
                     -text    $text                                 \
                     -width   [expr {max(8,[string length $text])}] \
                     -command [mytypemethod Choose $symbol]]

            pack $dialog.button.$symbol -side right -padx 4
        }

        # Make it transient over the -parent
        wm transient $dialog $opts(-parent)

        # NEXT, raise the button and set the focus
        wm deiconify $dialog
        wm attributes $dialog -topmost
        raise $dialog
        focus $button($opts(-default))

        # NEXT, do the grab, and wait until they return.
        set choice {}

        grab set $dialog
        vwait [mytypevar choice]
        grab release $dialog
        wm withdraw $dialog

        return $choice
    }

    # ParseOptions arglist
    #
    # arglist     List of popup args
    #
    # Parses the options into the opts array

    typemethod ParseOptions {arglist} {
        # FIRST, set the option defaults
        array set opts {
            -buttons       {ok OK}
            -ignoredefault {}
            -default       {}
            -icon          info
            -ignoretag     {}
            -message       {}
            -parent        {}
            -title         {}
        }

        # NEXT, get the option values
        while {[llength $arglist] > 0} {
            set opt [lshift arglist]

            switch -exact -- $opt {
                -buttons       -
                -default       -
                -icon          -
                -ignoretag     -
                -ignoredefault -
                -message       -
                -parent        -
                -title         {
                    set opts($opt) [lshift arglist]
                }
                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # NEXT, validate -buttons
        if {[llength $opts(-buttons)] == 0 ||
            [llength $opts(-buttons)] % 2 != 0
        } {
            error "-buttons: not a dictionary"
        }

        # NEXT, validate -default
        if {$opts(-default) eq ""} {
            set opts(-default) [lindex $opts(-buttons) 0]
        } else {
            if {$opts(-default) ni [dict keys $opts(-buttons)]} {
                error "-default: unknown button: \"$opts(-default)\""
            }
        }

        # NEXT, validate -ignoredefault
        if {$opts(-ignoredefault) eq ""} {
            set opts(-ignoredefault) $opts(-default)
        } else {
            if {$opts(-ignoredefault) ni [dict keys $opts(-buttons)]} {
                error \
                    "-ignoredefault: unknown button: \"$opts(-ignoredefault)\""
            }
        }

        # NEXT, validate -icon
        if {$opts(-icon) ni $iconnames} {
            error "-icon: should be one of [join $iconnames {, }]"
        }

        # NEXT, validate -parent
        if {$opts(-parent) ne ""} {
            snit::window validate $opts(-parent)
        }
    }

    # Choose symbol
    #
    # symbol    A symbolic name from -buttons
    #
    # Sets the button as their choice

    typemethod Choose {symbol} {
        set choice $symbol
    }

    # reset ?tag?
    #
    # tag     An ignore tag
    #
    # Resets the specified ignore flag, or all ignore flags.

    typemethod reset {{tag ""}} {
        if {$tag ne ""} {
            set ignore($tag) 0
        } else {
            array unset ignore
        }
    }
}


