#------------------------------------------------------------------------
# TITLE:
#    helpbrowserwin.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    helpbrowser(sim): athena_sim(1) Help Browser
#
#    The helpbrowser is a window wrapping the helpbrowser(n) widget.
#    It loads docs/help/athena.helpdb.
#
#-----------------------------------------------------------------------

snit::widget helpbrowserwin {
    # This is a toplevel window
    hulltype toplevel

    #-------------------------------------------------------------------
    # Type Components

    typecomponent thebrowser   ;# The browser window

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # We'll create the browser the first time we need it.
        set thebrowser {}
    }

    #-------------------------------------------------------------------
    # Public Type Methods

    # showhelp ?page?
    #
    # page     A help page name; defaults to "home".
    #
    # Shows the helpbrowser, and shows the requested page.  The
    # browser window is created if necessary.

    typemethod showhelp {{page home}} {
        if {$thebrowser eq ""} {
            set thebrowser [helpbrowserwin .help]
        }

        $thebrowser showhelp $page
    }

    #-------------------------------------------------------------------
    # Widget Options

    # All options are delegated to the hull.
    delegate option * to hull
    
    #-------------------------------------------------------------------
    # Widget Components

    component hdb              ;# The helpdb(n)
    component browser          ;# The helpbrowser(n)

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options, if any
        $self configurelist $args

        # NEXT, create the helpdb(n)
        install hdb using helpdb ${selfns}::hdb
        $hdb open [appdir join docs help athena.helpdb]

        # NEXT, create the browser
        install browser using helpbrowser $win.hb \
            -helpdb      $hdb                     \
            -notfoundcmd [mymethod PageNotFound]

        pack $browser -fill both -expand yes

        # NEXT, set the title
        wm title $win "Athena [version]: Help Browser"

        # NEXT, on close, just pop it down.
        wm protocol $win WM_DELETE_WINDOW [mymethod hide]
    }

    # PageNotFound page
    #
    # page     The name of an unknown page
    #
    # Creates a "Page Not Found" pseudo-page body.

    method PageNotFound {page} {
        return [tsubst {
            |<--
            <img src="athena" align="right">
            The page you requested, "<tt>$page</tt>", could not be
            found in this help file.  Please report the error to the Athena
            development team at the following address: 
            <b><tt>William.H.Duquette@jpl.nasa.gov</tt></b>.
        }]
    }


    

    #-------------------------------------------------------------------
    # Public Methods

    # hide
    #
    # Withdraws the help browser window

    method hide {} {
        wm withdraw $win
    }

    # show
    #
    # Restores and raises the help browser window

    method show {} {
        wm deiconify $win
        raise $win
    }

    # showhelp ?page?
    #
    # page     A help page name; defaults to "home".
    #
    # Shows the helpbrowser, and shows the requested page.

    method showhelp {{page home}} {
        $browser showpage $page
        $self show
    }
}



