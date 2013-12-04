#-----------------------------------------------------------------------
# TITLE:
#    myhtmlpane.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Individual my:// server page pane
#
#    This widget displays a single my:// page, specified via an option,
#    and hands off all links to the application.  It is not a browser,
#    as such.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export myhtmlpane
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::projectgui::myhtmlpane {
    #-------------------------------------------------------------------
    # Type constructor

    typeconstructor {
        namespace import ::marsutil::* ::marsgui::*
    }

    #-------------------------------------------------------------------
    # Components

    component agent     ;# The myagent(n)
    component hv        ;# The htmlviewer(n)
    component lazy      ;# The lazyupdater(n)
    
    #-------------------------------------------------------------------
    # Options

    # Delegate all options to the hull frame
    delegate option * to hull

    delegate option -width        to hv
    delegate option -height       to hv
    delegate option -shrink       to hv
    delegate option -zoom         to hv
    delegate option -hyperlinkcmd to hv
    delegate option -styles       to hv

    delegate option -defaultserver to agent

    # -messagecmd
    #
    # A command to pass messages to, to put on the app's message line.

    option -messagecmd

    # -reloadon
    #
    # A dictionary of notifier events on which the content should be
    # reloaded.

    option -reloadon \
        -readonly yes

    # -url
    #
    # The URL of the data to display.

    option -url \
        -configuremethod ConfigureURL

    method ConfigureURL {opt val} {
        set options($opt) $val

        $self show $val
    }

    #-------------------------------------------------------------------
    # Instance Variables

    # Browser Info
    #
    # page        - The page name from the current URI
    # anchor      - The anchor from the current URI
    # data        - The data dict for the current page, or "".
    # base        - Base URL, used for resolving links
    # counter     - Counter for creating object widget names.

    variable info -array {
        page      ""
        anchor    ""
        data      "" 
        base      ""
        counter   0
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, set the default hull size
        $hull configure \
            -width  8i  \
            -height 6i

        # NEXT, create the widgets

        install hv using htmlviewer $win.hv             \
            -hovercmd            [mymethod HoverCmd]     \
            -imagecmd            [mymethod ImageCmd]     \
            -xscrollcommand      [list $win.xscroll set] \
            -yscrollcommand      [list $win.yscroll set]

        ttk::scrollbar $win.xscroll \
            -orient  horizontal               \
            -command [list $hv xview]

        ttk::scrollbar $win.yscroll \
            -command [list $hv yview]

        grid $win.hv      -row 0 -column 0 -sticky nsew
        grid $win.yscroll -row 0 -column 1 -sticky ns
        grid $win.xscroll -row 1 -column 0 -sticky ew

        grid rowconfigure    $win 0 -weight 1
        grid columnconfigure $win 0 -weight 1

        grid propagate $win no

        # NEXT, add a node handler for <object> tags.
        $hv handler node object [mymethod ObjectCmd]

        # NEXT, update the htmlviewer's bindtags,
        # so that users can bind mouse events to $win.
        bindtags $hv [list $win {*}[bindtags $hv]]

        # NEXT, create the agent.
        install agent using myagent ${selfns}::agent \
            -contenttypes {text/html text/plain tk/image}

        # NEXT, create the lazy updater
        install lazy using lazyupdater ${selfns}::lazy \
            -window   $win \
            -command  [mymethod ReloadNow]
        
        # NEXT, get the options; this will load the -url, if any.
        $self configurelist $args

        # NEXT, prepare to reload on notifier events
        foreach {subject event} $options(-reloadon) {
            notifier bind $subject $event $self [mymethod ReloadOnEvent]
        }
    }

    destructor {
        notifier forget $self
    }

    # ObjectCmd node
    # 
    # node    - htmlviewer node handle
    #
    # An <object> tag was found in the input.  The data attribute is
    # assumed to name a resource with content-type tk/widget.  The size of
    # the widget can be controlled using width and height attributes with
    # the usual HTML length units, e.g., "100%" for full width.

    method ObjectCmd {node} {
        # FIRST, get the attributes of the object.
        set data [$node attribute -default "" data]

        # NEXT, get the Tk widget command for the object.  This will throw
        # NOTFOUND if the object is not found.

        if {[catch {
            set udict [$agent get $data tk/widget]
            set cmd [dict get $udict content]
        } result]} {
            set cmd [list ttk::label %W -image ::marsgui::icon::question22]
        }


        # NEXT, get a unique widget name
        set owin "$hv.o[incr info(counter)]"

        # NEXT, create the widget
        set cmd [string map [list %W $owin] $cmd]

        namespace eval :: $cmd

        $node replace $owin -deletecmd [list destroy $owin] 
    }

    # HoverCmd otype text
    #
    # otype   - Object type, either "href" or "image"
    # text    - Text describing thing we're over.
    #
    # Called as the mouse moves; calls -messagecmd with the URI.

    method HoverCmd {otype text} {
        if {$otype eq "href"} {
            set text [$agent resolve $info(base) $text]

            callwith $options(-messagecmd) "Link: $text"
        }
    }

    # ImageCmd src
    #
    # src     The image source
    #
    # Returns the Tk image relating to the src.

    method ImageCmd {src} {
        set src [$agent resolve $info(base) $src]

        if {[catch {$agent get $src} cdict]              ||
            [dict get $cdict contentType] ne "tk/image"
        } {
            set img ::marsgui::icon::question22
        } else {
            set img [dict get $cdict content]
        }

        # NEXT, make a copy of the image, since htmlviewer will delete
        # it when it is done with it.
        set copy [image create photo]
        $copy copy $img

        return $copy
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hv

    # reload
    #
    # Causes the widget to reload itself.  In particular,
    #
    # * This call triggers the lazy updater.
    # * The lazy updater will ask the widget to reload itself after
    #   1 millisecond, or when the window is next mapped.

    method reload {} {
        $lazy update
    }

    # ReloadNow
    #
    # Reloads the current page immediately, if there is one; otherwise,
    # clears the display.

    method ReloadNow {} {
        if {$info(page) ne ""} {
            $self ShowPageRef $info(page) [lindex [$hv yview] 0]
        } else {
            $hv set ""
        }
    }

    # ReloadOnEvent dummy...
    #
    # Reloads the content on an arbitrary notifier event.

    method ReloadOnEvent {args} {
        $self reload
    }


    # data 
    #
    # Returns the data for the currently displayed page.

    method data {} {
        return $info(data)
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

        # NEXT, save the information about the new current page.
        if {$page ne "" && $page ne $info(page)} {
            set info(page) $page
        } else {
            set page $info(page)
        }

        if {$anchor eq ""} {
            $self SaveUri $page
        } else {
            $self SaveUri "$page#$anchor"
        }
        # NEXT, display the current page.
        $self ShowPageRef $page

        # NEXT, scroll to the anchor, if any.
        if {$anchor ne ""} {
            $hv setanchor $anchor
        }            
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
            set einfo [dict get $opts -errorinfo]
            set etext $result

            set result [dict create url $page contentType text/html]

            if {$ecode eq "NOTFOUND"} {
                dict set result content [$self PageNotFound $page $etext]
            } else {
                dict set result content [$self PageError $page $einfo]
            }
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
            set info(base) $url
            $hv set $content
        }

        # NEXT, save the content, so that it can be queried.
        set info(data) $result

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
        set result [htools escape $result]
        return [tsubst {
            |<--
            <h1>Not Found</h1>

            The data you requested could not be found:<p>
            $result
        }]
    }

    # PageError uri einfo
    #
    # uri     - The name of an resource
    # einfo   - The error stack trace
    #
    # Creates an "Unexpected Error" pseudo-page body.

    method PageError {uri einfo} {
        set einfo [htools escape $einfo]
        return [tsubst {
            |<--
            <h1>Unexpected Error</h1>
            
            The page at <tt>$uri</tt> returned an unexpected error.
            Please report this to the development team.<p>
            
            <pre>
            $einfo
            </pre>
        }]
    }

    # SaveUri uri
    #
    # uri   - The current URI
    #
    # Saves the current URI and its components.

    method SaveUri {uri} {
        lassign [split $uri "#"] page anchor
        set info(page)    $page
        set info(anchor)  $anchor
    }
}



