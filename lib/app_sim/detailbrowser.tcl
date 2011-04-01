#-----------------------------------------------------------------------
# TITLE:
#    detailbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    detailbrowser(sim) package: Detail browser.
#
#    This widget displays a web-like browser for examining
#    model entities in detail.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget detailbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to browser


    #-------------------------------------------------------------------
    # Components

    component browser ;# The mybrowser(n)
    component tree    ;# The linktree(n)
    component lazy    ;# The lazyupdater(n)

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        install browser using mybrowser $win.browser \
            -home         my://app/                  \
            -hyperlinkcmd [mymethod WinLinkCmd]      \
            -messagecmd   {app puts}

        # NEXT, create the sidebar.
        set sidebar [$browser sidebar]

        # Entity Tree
        install tree using linktree $sidebar.tree \
            -url       my://app/entitytype        \
            -width     150                        \
            -height    400                        \
            -changecmd [mymethod ShowLink]

        pack $tree -fill both -expand yes

        $browser configure \
            -reloadcmd [mymethod RefreshLinks]

        # NEXT, create the lazy updater
        install lazy using lazyupdater ${selfns}::lazy \
            -window   $win \
            -command  [list $browser reload]

        pack $browser -fill both -expand yes

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, bind to events that are likely to cause reloads.
        notifier bind ::sim <DbSyncB> $win [mymethod reload]
        notifier bind ::sim <Tick>    $win [mymethod reload]
        notifier bind ::rdb <Monitor> $win [mymethod reload]

        # NEXT, schedule the first reload
        $self reload
    }

    destructor {
        notifier forget $win
    }

    # WinLinkCmd url
    #
    # url - A URL with a scheme other than "my:".
    #
    # Checks the URL scheme; if it's known, passes it to 
    # "app show".  Otherwise, lets mybrowser handle it.

    method WinLinkCmd {url} {
        # FIRST, get its scheme
        if {[catch {
            array set parts [uri::split $url]
        } result]} {
            return 0
        }

        if {$parts(scheme) ne "win"} {
            return 0
        }

        app show $url
        return 1
    }

    # RefreshLinks
    #
    # Called on browser reload; refreshes the links tree
    
    method RefreshLinks {} {
        $tree refresh
    }

    # ShowLink url
    #
    # Shows whatever is selected in the tree, if it's different than
    # what we already have.

    method ShowLink {url} {
        if {$url ne ""} {
            $browser show $url
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to browser

    # reload
    #
    # Causes the widget to reload itself.  In particular,
    #
    # * This call triggers the lazy updater.
    # * The lazy updater will ask the mybrowser to reload itself after
    #   1 millisecond, or when the window is next mapped.
    # * The mybrowser will reload the currently displayed resource and
    #   ask the tree to refresh itself via its -reloadcmd.

    method reload {} {
        $lazy update
    }
}


