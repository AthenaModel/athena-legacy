#-----------------------------------------------------------------------
# TITLE:
#    messagebox.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsgui(n) package: messagebox
#
#    This is a replacement for tk_messageBox with a slightly different
#    set of options.  In particular, the message box can include a
#    "Do not show this message again" check box; ignoring the message the
#    next time is automatic.
#
#    In addition, it provides a dialog for requesting a string value
#    from the user.
#
# TBD:
#    The caller should be able to specify arbitrary Tk images is
#    the value of -icon.
#
#-----------------------------------------------------------------------

namespace eval ::marsgui:: {
    namespace export messagebox
}

#-----------------------------------------------------------------------
# messagebox

snit::type ::marsgui::messagebox {
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

    # getsdlg -- Name of the gets dialog widget

    typevariable getsdlg .messageboxgets

    # opts -- Array of option settings.  See popup for values

    typevariable opts -array {}

    # ignore -- Array of ignore flags by ignore tag.

    typevariable ignore -array {}

    # choice -- The user's choice
    typevariable choice {}

    # errorText -- Error message, for "gets".
    typevariable errorText {}


    #-------------------------------------------------------------------
    # Public methods

    # popup option value....
    #
    # -buttons dict          Dictionary {symbol labeltext ...} of buttons
    # -default symbol        Symbolic name of the default button
    # -icon image            error, info, question, warning, peabody
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
        $type ParsePopupOptions $args

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
        if {$opts(-icon) eq "peabody"} {
            set icon ::marsgui::icon::peabody32
        } else {
            set icon ${type}::icon::$opts(-icon)
        }

        $dialog.top.icon configure -image $icon

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

    # ParsePopupOptions arglist
    #
    # arglist     List of popup args
    #
    # Parses the options into the opts array

    typemethod ParsePopupOptions {arglist} {
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
            set opt [::marsutil::lshift arglist]

            switch -exact -- $opt {
                -buttons       -
                -default       -
                -icon          -
                -ignoretag     -
                -ignoredefault -
                -message       -
                -parent        -
                -title         {
                    set opts($opt) [::marsutil::lshift arglist]
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
        if {$opts(-icon) ni $iconnames && $opts(-icon) ne "peabody"} {
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

    #-------------------------------------------------------------------
    # gets

    # gets option value....
    #
    # -oktext text           Text for the OK button.
    # -icon image            error, info, question, warning, peabody
    # -message string        Message to display.  Will be wrapped.
    # -parent window         The message box appears over the parent window
    # -title string          Title of the message box
    # -initvalue string      Initial value for the entry field
    # -validatecmd cmd       Validation command
    #
    # Pops up the "get string" message box.  The buttons will appear at 
    # the bottom, left to right, packed to the right.  The OK button will
    # have the specified text; it defaults to "OK".  The
    # -icon will be displayed; defaults to "question".  The -message will be 
    # wrapped into the message space; the entry widget will be below
    # the -message. The dialog will be application modal,
    # and centered over the specified -parent window.  It will have the
    # specified -title string.  If -initvalue is non-empty, its value
    # will be placed in the entry widget, and selected.
    #
    # The command will wait until the user presses a button.  On 
    # "cancel", it will return "".  On OK, it will call the -validatecmd
    # on the trimmed string.  If the -validatecmd throws INVALID, the
    # error message will appear in red below the entry widget.  Otherwise,
    # the command will return the entered string.

    typemethod gets {args} {
        # FIRST, get the option values
        $type ParseGetsOptions $args

        # NEXT, create the dialog if it doesn't already exist.
        if {![winfo exists $getsdlg]} {
            # FIRST, create it
            toplevel $getsdlg         \
                -borderwidth        4 \
                -highlightthickness 0

            # NEXT, withdraw it; we don't want to see it yet
            wm withdraw $getsdlg

            # NEXT, the user can't resize it
            wm resizable $getsdlg 0 0

            # NEXT, it can't be closed
            wm protocol $getsdlg WM_DELETE_WINDOW {
                # Do nothing
            }

            # NEXT, it must be on top
            wm attributes $getsdlg -topmost 1

            # NEXT, create and grid the standard widgets
            
            # Row 1: Icon and message
            ttk::frame $getsdlg.top

            ttk::label $getsdlg.top.icon \
                -image  ${type}::icon::question \
                -anchor nw

            ttk::label $getsdlg.top.message \
                -textvariable [mytypevar opts(-message)] \
                -wraplength   3i                         \
                -anchor       nw                         \
                -justify      left

            # Row 2: Entry Widget
            ttk::entry $getsdlg.top.entry

            bind $getsdlg.top.entry <Return> [mytypemethod GetsOK]

            # Row 3: Error label
            label $getsdlg.top.error \
                -textvariable [mytypevar errorText] \
                -wraplength   3i                    \
                -anchor       nw                    \
                -justify      left                  \
                -foreground   "#BB0000"
            
            grid $getsdlg.top.icon \
                -row 0 -column 0 -padx 8 -pady 4 -sticky nw 

            grid $getsdlg.top.message \
                -row 0 -column 1 -padx 8 -pady 4 -sticky new
            
            grid $getsdlg.top.entry \
                -row 1 -column 1 -padx 8 -pady 4 -stick ew

            grid $getsdlg.top.error \
                -row 2 -column 1 -padx 8 -pady 4 -sticky new

            # Button box
            ttk::frame $getsdlg.button

            # Create the buttons
            ttk::button $getsdlg.button.cancel     \
                -text    "Cancel"                  \
                -command [mytypemethod GetsCancel]

            ttk::button $getsdlg.button.ok     \
                -text    $opts(-oktext)        \
                -command [mytypemethod GetsOK]
            
            pack $getsdlg.button.ok     -side right -padx 4
            pack $getsdlg.button.cancel -side right -padx 4


            # Pack the top-level components.
            pack $getsdlg.top    -side top    -fill x
            pack $getsdlg.button -side bottom -fill x
        }

        # NEXT, configure the dialog according to the options
        
        # Set the title
        wm title $getsdlg $opts(-title)

        # Set the icon
        if {$opts(-icon) eq "peabody"} {
            set icon ::marsgui::icon::peabody32
        } else {
            set icon ${type}::icon::$opts(-icon)
        }

        $getsdlg.top.icon configure -image $icon

        # Make it transient over the -parent
        wm transient $getsdlg $opts(-parent)

        # NEXT, clear the error message and the entered text, and
        # apply the initvalue.
        set errorText ""
        $getsdlg.top.entry delete 0 end
        $getsdlg.top.entry insert 0 $opts(-initvalue)
        $getsdlg.top.entry selection range 0 end

        # NEXT, raise the dialog and set the focus
        wm deiconify $getsdlg
        wm attributes $getsdlg -topmost
        raise $getsdlg
        focus $getsdlg.top.entry

        # NEXT, do the grab, and wait until they return.
        set choice {}

        grab set $getsdlg
        vwait [mytypevar choice]
        grab release $getsdlg
        wm withdraw $getsdlg

        return $choice
    }

    # ParseGetsOptions arglist
    #
    # arglist     List of popup args
    #
    # Parses the options into the opts array

    typemethod ParseGetsOptions {arglist} {
        # FIRST, set the option defaults
        array set opts {
            -oktext        "OK"
            -icon          question
            -message       {}
            -parent        {}
            -title         {}
            -initvalue     {}
            -validatecmd   {}
        }

        # NEXT, get the option values
        while {[llength $arglist] > 0} {
            set opt [::marsutil::lshift arglist]

            switch -exact -- $opt {
                -oktext        -
                -icon          -
                -message       -
                -parent        -
                -title         -
                -initvalue     -
                -validatecmd   {
                    set opts($opt) [::marsutil::lshift arglist]
                }
                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # NEXT, validate -icon
        if {$opts(-icon) ni $iconnames && $opts(-icon) ne "peabody"} {
            error "-icon: should be one of [join $iconnames {, }]"
        }

        # NEXT, validate -parent
        if {$opts(-parent) ne ""} {
            snit::window validate $opts(-parent)
        }
    }

    # GetsCancel
    #
    # Returns the empty string.

    typemethod GetsCancel {} {
        set choice ""
    }

    # GetsOK
    #
    # Validates the string, and returns it.
    
    typemethod GetsOK {} {
        set string [string trim [$getsdlg.top.entry get]]

        if {$opts(-validatecmd) ne ""} {
            if {[catch {{*}$opts(-validatecmd) $string} result eopts]} {
                set ecode [dict get $eopts -errorcode]

                if {$ecode ne "INVALID"} {
                    return {*}$eopts $result
                }

                set errorText $result
                return
            }

            # Allow the validation command to canonicalize the
            # string.
            set string $result
        }

        # Save the string for next time.
        set choice $string
    }

}


