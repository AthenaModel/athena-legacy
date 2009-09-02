#-----------------------------------------------------------------------
# TITLE:
#    htmlviewer.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    HTML Viewer Widget, based on Tkhtml 2.0
#
#    htmlviewer(n) is a Snit wrapper around Tkhtml 2.0.  It adds a
#    few new methods, and also defines some additional bindings from
#    the "tkhtml" page at the Tcler's Wiki.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export htmlviewer
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor ::projectgui::htmlviewer {
    #-------------------------------------------------------------------
    # Type Constructor
    #
    # This type constructor defines a number of standard bindings.
    # They will affect all instances of Tkhtml, not just those
    # using this wrapper.

    typeconstructor {
        #-------------------------------------------------------------------
        # FIRST, the missing bindings from the tkhtml page at the Tcler's
        # Wiki, http://wiki.tcl.tk/2336

        #
        # Change cursor to hand if over hyperlink
        # Copied from hv.tcl
        #

        bind HtmlClip <Motion> {
            set parent [winfo parent %W]
            set url [$parent href %x %y]
            if {[string length $url] > 0} {
                $parent configure -cursor hand2
            } else {
                $parent configure -cursor {}
            }

        }

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

        #
        # Invoke widget hyperlink command on the hyperlink
        #
        bind HtmlClip <1> {
            set parent [winfo parent %W]
            set url [$parent href %x %y]
            if {[string length $url]} {
                eval [$parent cget -hyperlinkcommand] $url
            }
        }
    }

    #-------------------------------------------------------------------
    # Standard Font Sizes

    typevariable pixels -array {
        1    -9
        2    -10
        3    -12
        4    -14
        5    -16
        6    -18
        7    -20
    }

    #-------------------------------------------------------------------
    # Instance Variables

    typevariable fonts -array {
        fixed     "Courier"
    }

    #-------------------------------------------------------------------
    # Inherit html behavior

    delegate option * to hull
    delegate method * to hull

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the hull
        installhull [html $win                  \
                         -background     white  \
                         -foreground     black  \
                         -unvisitedcolor blue   \
                         -borderwidth    0      \
                         -relief         flat   \
                         -tablerelief    flat   \
                         -width          5i     \
                         -height         4i     \
                         -fontcommand    [mymethod FontCommand]]

        $self configurelist $args

        # NEXT, get some fonts
        set families [font families]

        if {"Luxi Mono" in $families} {
            set fonts(fixed) "Luxi Mono"
        }
    }

    # FontCommand size font
    #
    # size    Size, 1 to 7; 4 is standard
    # font    0 to 3 of "bold", "italic", "fixed".
    #
    # Returns the Tcl font to use.  Note that the widget does the
    # right thing for roman text; "fixed" is the problem.

    method FontCommand {size font} {
        # FIRST, we're only doing "fixed".
        if {"fixed"  ni $font} { 
            return ""
        }

        set fontspec [list $fonts(fixed)]

        lappend fontspec $pixels($size)

        # TBD: It appears that these never appear with "fixed".  Oh, well.
        if {"bold"   in $font} { lappend fontspec bold }
        if {"italic" in $font} { lappend fontspec italic }

        return $fontspec
    }

    #-------------------------------------------------------------------
    # Public Methods

    # set html
    # 
    # html     An HTML-formatted text string
    #
    # Displays the HTML text, replacing any previous contents.

    method set {html} {
        $hull clear
        $hull parse $html
    }
}
