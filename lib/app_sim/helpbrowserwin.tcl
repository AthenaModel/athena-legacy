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

    typecomponent hdb          ;# The helpdb
    typecomponent thebrowser   ;# The browser window

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # We'll create the components the first time we need them.
        set hdb        {}
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
        $type MakeHDB

        if {$thebrowser eq ""} {
            set thebrowser [helpbrowserwin .help]
        }

        $thebrowser showhelp $page
    }

    # exists page
    #
    # page    A help page name
    #
    # Returns 1 if the page exists, and 0 otherwise.

    typemethod exists {page} {
        $type MakeHDB

        return [$hdb page exists $page]
    }

    typemethod MakeHDB {} {
        if {$hdb eq ""} {
            set hdb [helpdb ::hdb]
            $hdb open [appdir join docs help athena.helpdb]
        }
    }


    #-------------------------------------------------------------------
    # Widget Options

    # All options are delegated to the hull.
    delegate option * to hull
    
    #-------------------------------------------------------------------
    # Widget Components

    component browser          ;# The helpbrowser(n)

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options, if any
        $self configurelist $args

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



