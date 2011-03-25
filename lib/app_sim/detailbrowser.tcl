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

snit::widgetadaptor detailbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull


    #-------------------------------------------------------------------
    # Components

    component tree    ;# The linktree(n)
    component lazy    ;# The lazyupdater(n)

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using mybrowser \
            -home         my://app/ \
            -messagecmd   {app puts}

        # NEXT, create the sidebar.
        set sidebar [$hull sidebar]

        # Entity Tree
        install tree using linktree $sidebar.tree \
            -url       my://app/entitytype        \
            -width     150                        \
            -height    400                        \
            -changecmd [mymethod ShowLink]

        pack $tree -fill both -expand yes

        $hull configure \
            -reloadcmd [mymethod RefreshLinks]

        # NEXT, create the lazy updater
        install lazy using lazyupdater ${selfns}::lazy \
            -window   $win \
            -command  [list $hull reload]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, bind to events that are likely to cause reloads.
        notifier bind ::sim <DbSyncB> $win [mymethod reload]
        notifier bind ::sim <Tick>    $win [mymethod reload]

        # NEXT, schedule the first reload
        $self reload
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
            $hull show $url
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

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


