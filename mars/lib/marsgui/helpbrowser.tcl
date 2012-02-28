#-----------------------------------------------------------------------
# TITLE:
#    helpbrowser.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsgui(n): Tkhtml 2.0-based Help Browser.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export helpbrowser
}

#-------------------------------------------------------------------
# helpbrowser(n)

snit::widget ::marsgui::helpbrowser {
    #-------------------------------------------------------------------
    # Type constructor

    typeconstructor {
        namespace import ::marsutil::* ::marsgui::*
    }

    #-------------------------------------------------------------------
    # Components

    component hdb       ;# The helpdb(n).
    
    component bar       ;# The tool bar
    component tree      ;# The helptree(n)
    component hv        ;# The htmlviewer(n)
    component backbtn   ;# Back one page button
    component fwdbtn    ;# Forward one page button
    component titlelab  ;# Title label
    component searchbox ;# Search Box

    #-------------------------------------------------------------------
    # Options

    # Delegate all options to the hull frame
    delegate option * to hull

    # -helpdb    The helpdb to browse
    option -helpdb -readonly yes

    # -notfoundcmd:  A command that returns the body of a "Page Not Found"
    # pseudo-page when the user requests a page that doesn't exist.
    # The command should take one argument, the name of the requested
    # page.
    option -notfoundcmd

    #-------------------------------------------------------------------
    # Instance Variables

    # Browser Info
    #
    # current       The name of the current page
    # title         The title of the current page
    # history       The history stack: a list of page refs
    # future        The future stack: a list of page refs

    variable info -array {
        current ""
        title   ""
        history {}
        future  {}
    }

    # Viewed: array of counts by page name.

    variable viewed -array { }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, extract the -helpdb.
        set hdb [from args -helpdb]

        if {$hdb eq ""} {
            error "no -helpdb specified"
        }

        # NEXT, create the widgets

        # Toolbar
        install bar using ttk::frame $win.bar

        install backbtn using ttk::button $bar.back         \
            -style   Toolbutton                             \
            -image   [list                                  \
                                   ::marsgui::icon::back    \
                          disabled ::marsgui::icon::backd]  \
            -command [mymethod back]

        DynamicHelp::add $backbtn -text "Go back one page"


        install fwdbtn using ttk::button $bar.forward         \
            -style   Toolbutton                               \
            -image   [list                                    \
                                   ::marsgui::icon::forward   \
                          disabled ::marsgui::icon::forwardd] \
            -command [mymethod forward]

        pack $backbtn  -side right -padx 1 -pady 1

        DynamicHelp::add $fwdbtn -text "Go forward one page"

        install titlelab using ttk::label $bar.title \
            -textvariable [myvar info(title)]

        ttk::label $bar.searchlab \
            -text "Search:"

        install searchbox using commandentry $bar.searchbox \
            -relief     sunken                              \
            -clearbtn   yes                                 \
            -changecmd  [mymethod DoSearch]


        pack $backbtn       -side left  -padx 1 -pady 1
        pack $fwdbtn        -side left  -padx 1 -pady 1
        pack $titlelab      -side left  -padx 1 -pady 1
        pack $searchbox     -side right -padx 3 -pady 1
        pack $bar.searchlab -side right -padx 0 -pady 1

        # Separator
        ttk::separator $win.sep -orient horizontal

        # Paner
        ttk::panedwindow $win.paner -orient horizontal

        # Help Tree

        install tree using ::marsgui::helptree $win.paner.tree \
            -helpdb $hdb
        $win.paner add $win.paner.tree -weight 0

        # HTML Viewer
        ttk::frame $win.paner.frm
        $win.paner add $win.paner.frm -weight 1
        
        install hv using htmlviewer $win.paner.frm.hv          \
            -takefocus        1                                \
            -hyperlinkcommand [mymethod HyperlinkCmd]          \
            -isvisitedcommand [mymethod IsVisitedCmd]          \
            -imagecommand     [mymethod ImageCmd]              \
            -yscrollcommand   [list $win.paner.frm.scroll set]

        ttk::scrollbar $win.paner.frm.scroll \
            -command [list $hv yview]

        pack $win.paner.frm.scroll -side right -fill y
        pack $win.paner.frm.hv                 -fill both -expand yes

        grid rowconfigure    $win 2 -weight 1
        grid columnconfigure $win 0 -weight 1

        grid $win.bar   -row 0 -column 0 -sticky ew
        grid $win.sep   -row 1 -column 0 -sticky ew -pady 1
        grid $win.paner -row 2 -column 0 -sticky nsew

        # NEXT, get the options
        $self configurelist $args

        # NEXT, populate the tree
        $tree refresh

        # NEXT, Event bindings
        bind $tree <<Selection>> [mymethod ShowTreePage]

        # NEXT, show the first page
        $self showpage [lindex [$hdb page children ""] 0]
    }

    # HyperlinkCmd uri
    #
    # uri     A URI of the form "<pageName>#<anchor>"
    #
    # Displays the URI in the help viewer.  Note that either the
    # <pageName> or the <anchor> can be empty, but not both.

    method HyperlinkCmd {uri} {
        # FIRST, get the page name and the anchor within the topic
        set uri [lindex $uri 0]

        lassign [split $uri "#"] name anchor

        # NEXT, show it.
        $self showpage $name $anchor
    }

    # IsVisitedCmd uri
    #
    # uri     A URI of the form "<pageName>#<anchor>"
    #
    # Returns 1 if the Not clear what this should do.

    method IsVisitedCmd {uri} {
        # FIRST, get the page name and the anchor within the topic
        set uri [lindex $uri 0]

        if {[string index $uri 0] eq "#"} {
            set uri "$info(current)$uri"
        }

        if {[info exists viewed($uri)]} {
            return 1
        } else {
            return 0
        }
    }

    # ImageCmd src width height dict dummy
    #
    # src     The image source
    # width   The requested width (ignored)
    # height  The requested height (ignored)
    # dict    All <img> parms (ignored)
    # dummy   Not sure what this is.
    #
    # Returns the Tk image relating to the src.

    method ImageCmd {src width height dict dummy} {
        $hdb eval {
            SELECT data FROM helpdb_images WHERE name=$src
        } {
            return [image create photo -format png -data $data]
        }

        return ""
    }
    

    # ShowTreePage
    #
    # Displays a page when the user clicks on it in the help tree.

    method ShowTreePage {} {
        $self showpage [$tree get]
    }

    # DoSearch target
    #
    # target   Content of the search box
    #
    # Displays the search
    
    method DoSearch {target} {
        $self showpage Search
    }

    #-------------------------------------------------------------------
    # Public Methods

    # showpage page ?anchor?
    #
    # page      A page name, or ""
    # anchor    An anchor name, or ""
    #
    # Shows the specified page/anchor in htmlviewer.  If both page and
    # anchor are "", nothing happens.  If page is not "", the page
    # is loaded; if anchor is not "", the htmlviewer is scrolled to
    # display the related text.

    method showpage {page {anchor ""}} {
        # FIRST, if page and anchor are both "" there's nothing to
        # do.
        if {$page eq "" && $anchor eq ""} {
            return
        }

        # NEXT, push the current page ref onto the history stack
        $self Push history

        # NEXT, set the new current page, if it's changed.
        if {$page ne ""} {
            set info(current) $page
        }

        # NEXT, clear the future stack
        set info(future) [list]

        # NEXT, display the current page, if it's changed.
        if {$page ne ""} {
            $self ShowPageRef $page 0.0
        }

        # NEXT, scroll to the anchor, if any.  At the same time,
        # remember that we've been here.
        if {$anchor ne ""} {
            $hv yview $anchor
            
            set uri "$info(current)#$anchor"
            incr viewed($uri)
        } else {
            incr viewed($info(current))
        }

        # NEXT, update the button state.
        $self UpdateButtonState
    }

    # ShowPageRef page ?frac?
    #
    # page      A page name
    # frac      A scroll fraction, 0.0 to 1.0; defaults to 0.
    #
    # Loads the named page into the htmlviewer, and scrolls to the
    # specified fraction.  If the page is not known, a pseudo-page
    # is created.

    method ShowPageRef {page {frac 0.0}} {
        # FIRST, get the page data.
        if {$page eq "Search"} {
            set info(title) Search
            set text [$hdb search [$searchbox get]]
        } else {
            lassign [$hdb page title+text $page] info(title) text
        }

        # NEXT, if not found get a pseudo page
        if {$info(title) eq ""} {
            set info(title) "Page Not Found"
            set text [$self PageNotFound $page]
        }

        # NEXT, format the page, and show it.
        $hv set $text

        # NEXT, make it visible in the help tree
        $tree set $page

        # NEXT, update idle tasks; otherwise scrolling to anchors,
        # etc., won't work.
        update idletasks

        # NEXT, scroll to the fraction.
        $hv yview moveto $frac
    }

    # PageNotFound page
    #
    # page     The name of an unknown page
    #
    # Creates a "Page Not Found" pseudo-page body.

    method PageNotFound {page} {
        if {$options(-notfoundcmd) ne ""} {
            return [{*}$options(-notfoundcmd) $page]
        } else {
            return [tsubst {
                |<--
                The page you requested, "<tt>$page</tt>", could not be
                found in this help file.  Please report the error to 
                the development team..
            }]
        }
    }


    # back
    #
    # Go back one page

    method back {} {
        # FIRST, pop the top page ref from the history stack.  If none,
        # there's nothing to do.
        lassign [$self Pop history] page frac

        if {$page eq ""} {
            return
        }

        # NEXT, push the current page onto the future stack.
        $self Push future

        # NEXT, make the new page current
        set info(current) $page

        # NEXT, display the page.
        $self ShowPageRef $page $frac

        # NEXT, Update the button state
        $self UpdateButtonState
    }


    # forward
    #
    # Go forward one page

    method forward {} {
        # FIRST, pop the top page ref from the future stack.  If none,
        # there's nothing to do.
        lassign [$self Pop future] page frac

        if {$page eq ""} {
            return
        }

        # NEXT, push the current page onto the history stack.
        $self Push history

        # NEXT, make the new page current
        set info(current) $page

        # NEXT, display the page.
        $self ShowPageRef $page $frac

        # NEXT, Update the button state
        $self UpdateButtonState
    }


    # UpdateButtonState
    #
    # Enables/disables the toolbar buttons based on the state of the 
    # browser.

    method UpdateButtonState {} {
        if {[llength $info(history)] > 0} {
            $backbtn configure -state normal
        } else {
            $backbtn configure -state disabled
        }

        if {[llength $info(future)] > 0} {
            $fwdbtn configure -state normal
        } else {
            $fwdbtn configure -state disabled
        }
    }

    # Push stack
    #
    # Pushes the current page and fraction onto the named
    # stack (presuming that they are different from what's
    # already there.

    method Push {stack} {
        # FIRST, If there's no current page to push, don't push it.
        if {$info(current) eq ""} {
            return
        }

        # NEXT, get the current page ref.
        set ref [list $info(current) [lindex [$hv yview] 0]]

        # NEXT, if it's the same as the top of the stack, we're done.
        # Otherwise, push it on the stack.
        if {$ref ne [lindex $info($stack) end]} {
            lappend info($stack) $ref
        }

        return
    }

    # Pop stack
    #
    # Pops the top entry off of the named stack, and returns it.
    # If the stack is entry, returns "".

    method Pop {stack} {
        set ref [lindex $info($stack) end]
        set info($stack) [lrange $info($stack) 0 end-1]
        return $ref
    }
}
