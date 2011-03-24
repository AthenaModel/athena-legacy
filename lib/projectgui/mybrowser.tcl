#-----------------------------------------------------------------------
# TITLE:
#    mybrowser.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: URI-driven Browser
#
#    This is a web-browser-like widget that browses resources found
#    via  URI server.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export mybrowser
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::projectgui::mybrowser {
    #-------------------------------------------------------------------
    # Type constructor

    typeconstructor {
        namespace import ::marsutil::* ::marsgui::*
    }

    #-------------------------------------------------------------------
    # Components

    component agent     ;# The myagent(n)
    component bar       ;# The tool bar
    component sidebar   ;# The sidebar ttk::frame(n)
    component hv        ;# The htmlviewer(n)
    component backbtn   ;# Back one page button
    component fwdbtn    ;# Forward one page button
    component homebtn   ;# Home button
    component reloadbtn ;# Reload button
    component address   ;# Address bar

    #-------------------------------------------------------------------
    # Options

    # Delegate all options to the hull frame
    delegate option * to hull

    delegate option -defaultserver to agent

    # -home
    #
    # The home URL

    option -home \
        -configuremethod ConfigureHome

    method ConfigureHome {opt val} {
        set options($opt) $val

        if {$val ne ""} {
            $homebtn configure -state normal
        } else {
            $homebtn configure -state disabled
        }
    }

    # -messagecmd
    #
    # A command to pass messages to, to put on the app's message line.

    option -messagecmd

    # -reloadcmd
    #
    # A command to call when the widget is reloaded.

    option -reloadcmd


    #-------------------------------------------------------------------
    # Instance Variables

    # Browser Info
    #
    # address     - The URI In the address bar, which might or might not
    #             - be the current page.
    # uri         - The URI of the current page, including any anchor
    # page        - The page name from the current URI
    # anchor      - The anchor from the current URI
    # history     - The history stack: a list of page refs
    # future      - The future stack: a list of page refs
    # mouseover   - Last mouse-over string

    variable info -array {
        address   ""
        uri       ""
        page      ""
        anchor    ""
        history   {}
        future    {}
        mouseover ""
    }

    # Viewed: array of counts by page name.

    variable viewed -array { }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the widgets

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

        DynamicHelp::add $fwdbtn -text "Go forward one page"

        install homebtn using ttk::button $bar.home             \
            -style   Toolbutton                                 \
            -state   disabled                                   \
            -image   [list                                      \
                                   ::projectgui::icon::home22   \
                          disabled ::projectgui::icon::home22d] \
            -command [mymethod home]

        DynamicHelp::add $homebtn -text "Display home page"

        install reloadbtn using ttk::button $bar.reload      \
            -style   Toolbutton                              \
            -image   [list                                   \
                                   ::marsgui::icon::reload   \
                          disabled ::marsgui::icon::reloadd] \
            -command [mymethod reload]

        DynamicHelp::add $reloadbtn -text "Reload current page"


        install address using ttk::entry $bar.address \
            -textvariable [myvar info(address)]

        bind $address <Return> [mymethod ShowAddress]


        pack $backbtn   -side left                      -padx 1 -pady 1
        pack $fwdbtn    -side left                      -padx 1 -pady 1
        pack $homebtn   -side left                      -padx 1 -pady 1
        pack $reloadbtn -side left                      -padx 1 -pady 1
        pack $address   -side left -fill x -expand yes  -padx 1 -pady {1 3}

        # Separator
        ttk::separator $win.sep -orient horizontal

        # Paner
        ttk::panedwindow $win.paner -orient horizontal

        # Sidebar Frame: We'll create this later, when we need it.
        set sidebar ""

        # HTML Viewer
        ttk::frame $win.paner.frm
        $win.paner add $win.paner.frm -weight 1
        
        install hv using htmlviewer $win.paner.frm.hv              \
            -takefocus           1                                 \
            -hyperlinkcommand    [mymethod HyperlinkCmd]           \
            -isvisitedcommand    [mymethod IsVisitedCmd]           \
            -imagecommand        [mymethod ImageCmd]               \
            -xscrollcommand      [list $win.paner.frm.xscroll set] \
            -yscrollcommand      [list $win.paner.frm.yscroll set]

        ttk::scrollbar $win.paner.frm.xscroll \
            -orient  horizontal               \
            -command [list $hv xview]

        ttk::scrollbar $win.paner.frm.yscroll \
            -command [list $hv yview]

        grid $win.paner.frm.hv      -row 0 -column 0 -sticky nsew
        grid $win.paner.frm.yscroll -row 0 -column 1 -sticky ns
        grid $win.paner.frm.xscroll -row 1 -column 0 -sticky ew

        grid rowconfigure    $win.paner.frm 0 -weight 1
        grid columnconfigure $win.paner.frm 0 -weight 1

        grid $win.bar   -row 0 -column 0 -sticky ew
        grid $win.sep   -row 1 -column 0 -sticky ew -pady 1
        grid $win.paner -row 2 -column 0 -sticky nsew

        grid rowconfigure    $win 2 -weight 1
        grid columnconfigure $win 0 -weight 1

        # NEXT, browser events
        bind HtmlClip <Motion> [mymethod MouseOver %x %y]

        # NEXT, create the agent.
        install agent using myagent ${selfns}::agent \
            -contenttypes {text/html text/plain tk/image}

        # NEXT, get the options
        $self configurelist $args

        # NEXT, reload the browser and show the home page
        $self reload
        $self home
    }

    # MouseOver x y
    #
    # x,y - %x,%y coordinates of <Motion> event
    #
    # Called as the mouse moves; calls -messagecmd with the URI.

    method MouseOver {x y} {
        set url [lindex [$hv href $x $y] 0]

        if {$url eq $info(mouseover)} {
            return
        }

        set info(mouseover) $url

        if {$url ne ""} {
            callwith $options(-messagecmd) "Link: $url"
        }
    }

    #
    # uri     A URI of the form "<resource>#<anchor>"
    #
    # Displays the URI in the html viewer.  Note that either the
    # <resource> or the <anchor> can be empty, but not both.

    method HyperlinkCmd {uri} {
        $self show [lindex $uri 0]
    }

    # IsVisitedCmd uri
    #
    # uri     A URI of the form "<page>#<anchor>"
    #
    # Returns 1 if the URI has been visited.

    method IsVisitedCmd {uri} {
        # FIRST, get the page name and the anchor within the topic
        set uri [lindex $uri 0]

        if {[string index $uri 0] eq "#"} {
            set uri "$info(page)$uri"
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
        if {[catch {$agent get $src} cdict]              ||
            [dict get $cdict contentType] ne "tk/image"
        } {
            return ::marsgui::icon::question22
        }

        return [dict get $cdict content]
    }

   
    # ShowAddress
    #
    # Shows the page entered manually in the address bar.

    method ShowAddress {} {
        $self show $info(address)
    }
    
    #-------------------------------------------------------------------
    # Public Methods

    # sidebar
    #
    # If the sidebar pane has not been created, creates it and
    # manages it in the paner.  Returns the sidebar pane's widget.

    method sidebar {} {
        if {$sidebar eq ""} {
            install sidebar using ttk::frame $win.paner.sidebar

            $win.paner forget $win.paner.frm
            $win.paner add $win.paner.sidebar
            $win.paner add $win.paner.frm -weight 1
        }

        return $sidebar
    }

    # home
    #
    # Go to the home page

    method home {} {
        $self show $options(-home)
    }

    # show uri
    #
    # uri  - A resource URI, possibly with an anchor
    #
    # Shows the specified URI in htmlviewer.  If both resource and
    # anchor are "", nothing happens.  If resource is not "", the resource
    # is loaded; if anchor is not "", the htmlviewer is scrolled to
    # display the related text.

    method show {uri} {
        # FIRST, parse the URI and its components
        lassign [split $uri "#"] page anchor

        # NEXT, if page and anchor are both "", then just clear the
        # html viewer; there's nothing else to do.
        if {$page eq "" && $anchor eq ""} {
            $hv set ""
            return
        }

        # NEXT, push the current page ref onto the history stack
        $self Push history

        # NEXT, save the information about the new current page.
        if {$page ne "" && $page ne $info(page)} {
            set info(page) $page
            set gotNewPage 1
        } else {
            set page $info(page)
            set gotNewPage 0
        }

        if {$anchor eq ""} {
            $self SaveUri $page
        } else {
            $self SaveUri "$page#$anchor"
        }

        # NEXT, clear the future stack
        set info(future) [list]

        # NEXT, display the current page, if it's changed.
        if {$gotNewPage} {
            $self ShowPageRef $page
        }

        # NEXT, scroll to the anchor, if any.
        if {$anchor ne ""} {
            $hv yview $anchor
        }            

        # NEXT, remember that we've been here.
        incr viewed($info(uri))

        # NEXT, update the button state.
        $self UpdateButtonState
    }

    # ShowPageRef page ?frac?
    #
    # page      A page URI
    # frac      A scroll fraction, 0.0 to 1.0; defaults to 0.
    #
    # Loads the named page into the htmlviewer, and scrolls to the
    # specified fraction.  If the page is not known, a pseudo-page
    # is created.

    method ShowPageRef {page {frac 0.0}} {
        # FIRST, get the page data.
        if {[catch {
            set result [$agent get $page]
        } result opts]} {
            set ecode [dict get $opts -errorcode]

            if {$ecode ne "NOTFOUND"} {
                return {*}$opts $result
            }

            set result [dict create \
                            url         $page                              \
                            content     [$self PageNotFound $page $result] \
                            contentType text/html]
        }

        dict with result {
            # FIRST, handle special content.
            switch -exact -- $contentType {
                text/plain {
                    set content \
                  "<pre>[string map {& &amp; < &lt; > &gt;} $content]</pre>"
                }

                tk/image {
                    set content "<img src=\"$url\">"
                }
            }

            # NEXT, show the page.
            $hv configure -base $url
            $hv set $content
        }

        # NEXT, update idle tasks; otherwise scrolling to anchors,
        # etc., won't work.
        update idletasks
        
        # NEXT, scroll to the fraction.
        $hv yview moveto $frac
    }

    # PageNotFound uri
    #
    # uri     The name of an unknown resource
    #
    # Creates a "Not Found" pseudo-page body.

    method PageNotFound {uri result} {
        return [tsubst {
            |<--
            <h1>Not Found</h1>

            The data you requested could not be found:<p>
            $result
        }]
    }

    # reload
    #
    # Reloads the current page

    method reload {} {
        $self ShowPageRef $info(page) [lindex [$hv yview] 0]
        callwith $options(-reloadcmd)
    }


    # back
    #
    # Go back one page

    method back {} {
        # FIRST, pop the top page ref from the history stack.  If none,
        # there's nothing to do.
        lassign [$self Pop history] uri frac

        if {$uri eq ""} {
            return
        }

        # NEXT, push the current page onto the future stack.
        $self Push future

        # NEXT, make the new page current
        $self SaveUri $uri

        # NEXT, display the page.
        $self ShowPageRef $info(page) $frac

        # NEXT, Update the button state
        $self UpdateButtonState
    }


    # forward
    #
    # Go forward one page

    method forward {} {
        # FIRST, pop the top page ref from the future stack.  If none,
        # there's nothing to do.
        lassign [$self Pop future] uri frac

        if {$uri eq ""} {
            return
        }

        # NEXT, push the current page onto the history stack.
        $self Push history

        # NEXT, make the new page current
        $self SaveUri $uri

        # NEXT, display the page.
        $self ShowPageRef $info(page) $frac

        # NEXT, Update the button state
        $self UpdateButtonState
    }

    # SaveUri uri
    #
    # uri   - The current URI
    #
    # Saves the current URI and its components.

    method SaveUri {uri} {
        lassign [split $uri "#"] page anchor
        set info(uri)     $uri
        set info(address) $uri
        set info(page)    $page
        set info(anchor)  $anchor
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
    # Pushes the current URI and fraction onto the named
    # stack (presuming that they are different from what's
    # already there.

    method Push {stack} {
        # FIRST, If there's no current URI to push, don't push it.
        if {$info(uri) eq ""} {
            return
        }

        # NEXT, get the current page ref.
        set ref [list $info(uri) [lindex [$hv yview] 0]]

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


