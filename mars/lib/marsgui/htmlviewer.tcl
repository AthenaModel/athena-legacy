#-----------------------------------------------------------------------
# TITLE:
#    htmlviewer.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsgui(n): HTML Viewer Widget, based on Tkhtml 2.0
#
#    htmlviewer(n) is a Snit wrapper around Tkhtml 2.0.  It adds a
#    few new methods, and also defines some additional bindings from
#    the "tkhtml" page at the Tcler's Wiki.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export htmlviewer
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor ::marsgui::htmlviewer {
    #-------------------------------------------------------------------
    # Type Constructor
    #
    # This type constructor defines a number of standard bindings.
    # They will affect all instances of Tkhtml, not just those
    # using this wrapper.

    typeconstructor {
        #-------------------------------------------------------------------
        # FIRST, these bindings are based on those from the tkhtml page at 
        # the Tcler's Wiki, http://wiki.tcl.tk/2336, with my changes.

        bind HtmlClip <1>               {[winfo parent %W] Button1 %x %y}
        bind HtmlClip <Control-1>       {[winfo parent %W] NoOp}
        bind HtmlClip <Shift-1>         {[winfo parent %W] NoOp}
        bind HtmlClip <ButtonRelease-1> {[winfo parent %W] Release1}
        bind HtmlClip <Motion>          {[winfo parent %W] MouseMotion %x %y}

        # Key-scrolling bindings
        bind Html <Prior>  {%W yview scroll -1 pages}
        bind Html <Next>   {%W yview scroll  1 pages}
        bind Html <Home>   {%W yview moveto 0.0}
        bind Html <End>    {%W yview moveto 1.0}
        bind Html <Up>     {%W yview scroll -1 units}
        bind Html <Down>   {%W yview scroll  1 units}
        bind Html <Left>   {%W xview scroll -1 units}
        bind Html <Right>  {%W xview scroll  1 units}

        # Copy bindings
        bind Html <<Copy>> {%W CopySelection}

        #
        # Mouse Wheel bindings
        # Cut'n'pasted from Text widget binding
        #

        if {[string equal [tk windowingsystem] "classic"]
            || [string equal [tk windowingsystem] "aqua"]} {
            bind HtmlClip <MouseWheel> {
                %W yview scroll [expr {- (%D)}] units
            }
            bind HtmlClip <Option-MouseWheel> {
                %W yview scroll [expr {-10 * (%D)}] units
            }
            bind HtmlClip <Shift-MouseWheel> {
                %W xview scroll [expr {- (%D)}] units
            }
            bind HtmlClip <Shift-Option-MouseWheel> {
                %W xview scroll [expr {-10 * (%D)}] units
            }
        } else {
            bind HtmlClip <MouseWheel> {
                %W yview scroll [expr {- (%D / 120) * 4}] units
            }
        }

        if {[string equal "x11" [tk windowingsystem]]} {
            # Support for mousewheels on Linux/Unix commonly comes through 
            # mapping the wheel to the extended buttons.  If you have a 
            # mousewheel, find Linux configuration info at:
            #   http://www.inria.fr/koala/colas/mouse-wheel-scroll/
            bind HtmlClip <4> {
                if {!$tk_strictMotif} {
                    %W yview scroll -1 units
                }
            }
            bind HtmlClip <5> {
                if {!$tk_strictMotif} {
                    %W yview scroll 1 units
                }
            }

        }
    }

    #-------------------------------------------------------------------
    # Look-up tables

    # Standard Font Sizes
    typevariable pixels -array {
        1    -9
        2    -10
        3    -12
        4    -14
        5    -18
        6    -20
        7    -22
    }

    # HTML character entity translations.  Tkhtml2 can display 
    # Unicode characters (at least on Linux), but doesn't understand
    # many HTML character entities.  This table contains translations
    # of the one to the other.

    typevariable entities {
        &Delta; "\u0394"
    }

    #-------------------------------------------------------------------
    # Inherit html behavior

    delegate option * to hull
    delegate method * to hull

    #-------------------------------------------------------------------
    # Options

    # -mouseovercommand
    #
    # Called when the mouse goes over something interesting.  The
    # command is passed two arguments: a type and a string.  The
    # valid types are as follows:
    #
    #    href - A link

    option -mouseovercommand

    #-------------------------------------------------------------------
    # Instance Variables

    # Transient Data Array
    #
    # mark - Mark for sweeping out a selection
    # over - What we're over

    variable trans -array {
        mark {}
        over {}
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, load Tkhtml 2.0 if need be
        package require Tkhtml 2.0

        # FIRST, create the hull
        installhull [html $win                        \
                         -highlightthickness 1        \
                         -background         white    \
                         -foreground         black    \
                         -unvisitedcolor     \#1C1CF0 \
                         -visitedcolor       \#561B8B \
                         -borderwidth        0        \
                         -relief             flat     \
                         -tablerelief        flat     \
                         -width              5i       \
                         -height             4i       \
                         -fontcommand        [mymethod FontCommand]]

        $self configurelist $args
    }

    # FontCommand size font
    #
    # size    Size, 1 to 7; 4 is standard
    # font    0 to 3 of "bold", "italic", "fixed".
    #
    # Returns the Tcl font to use.  Note that the widget does the
    # right thing for roman text; "fixed" is the problem.

    method FontCommand {size font} {
        if {"fixed" in $font} {
            set basefont TkFixedFont
            set font ""
        } else {
            set basefont TkTextFont
        }

        set family   [dict get [font actual $basefont] -family]
        set fontspec [list $family $pixels($size) {*}$font]

        return $fontspec
    }

    # CopySelection
    #
    # Copies the selection to the clipboard.

    method CopySelection {} {
        clipboard clear
        clipboard append [selection get]
    }

    # Button1 x y
    #
    # Called when Button 1 is pressed.

    method Button1 {x y} {
        focus $win 

        $hull selection clear

        set url [$hull href $x $y]

        if {$url ne ""} {
            {*}[$hull cget -hyperlinkcommand] $url
        }

        # If this window is still mapped, and the 
        # -hyperlinkcommand didn't make us lose the focus,
        # begin sweeping out a selection.
        if {[winfo ismapped $win] && [focus] eq $win} {
            set trans(mark) $x,$y
        }
    }

    # NoOp
    #
    # Event handler for bindings that should do nothing.  For example,
    # <Control-1> shouldn't trigger the <1> logic.

    method NoOp {} {

    }

    # Release1
    #
    # Called when Button 1 is released.

    method Release1 {} {
        set trans(mark) ""
    }

    # MouseMotion x y
    #
    # x,y   The mouse coordinates
    #
    # Handles mouse overs.

    method MouseMotion {x y} {
        # Sweep out the selection
        if {$trans(mark) ne ""} {
            $hull selection set @$trans(mark) @$x,$y
        }

        # Are we over a URL?
        set url [$hull href $x $y]

        # If it's the same as last time, we're done.
        if {$url eq $trans(over)} {
            return
        }

        set trans(over) $url

        # Set cursor if we're over
        if {$url ne ""} {
            $hull configure -cursor hand2
            callwith $options(-mouseovercommand) href [lindex $url 0]
        } else {
            $hull configure -cursor {}
        }

    }


    #-------------------------------------------------------------------
    # Public Methods


    # set html
    # 
    # html     An HTML-formatted text string
    #
    # Displays the HTML text, replacing any previous contents.
    # Translates certain HTML character entities into Unicode
    # equivalents for display.

    method set {html} {
        $hull clear
        $hull parse [string map $entities $html]
    }
}
