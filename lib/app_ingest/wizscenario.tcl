#-----------------------------------------------------------------------
# TITLE:
#    wizscenario.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    wizscenario(n): A wizard manager page for choosing an
#    athena scenario.
#
# TBD: 
#   We'll need to verify that the scenario has neighborhoods and
#   actors.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# wizscenario widget


snit::widget wizscenario {
    #-------------------------------------------------------------------
    # Layout

    # The HTML layout for this widget.
    typevariable layout {
        <h1>Choose Scenario</h1>
        
        This tool retrieves TIGR intel messages for a given area of
        interest and time period, and helps the user ingest them into
        an Athena scenario.<p>

        The scenario determines the area of interest, its breakdown
        into "neighborhoods", the civilian residents, and the 
        significant political, military, and economic actors.  Thus,
        the first step is to choose an Athena scenario for the 
        area of interest.<p>

        The selected Athena scenario:<br>
        <input name="dbfile"> <input name="bbrowse"><p>

        <input name="errmsg"><p>
    }
    
    #-------------------------------------------------------------------
    # Components

    component hframe     ;# htmlframe(n) widget to contain the content.
    component bbrowse    ;# "browse" button
    
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Variables

    # Info array: wizard data
    #
    # dbfile              - The selected scenario db file.
    # errmsg              - Error message for bad scenario.

    variable info -array {
        dbfile {}
        errmsg {}
    }

    #-------------------------------------------------------------------
    # Constructor
    #

    constructor {args} {
        # FIRST, set the default size of this page.
        $hull configure \
            -height 300 \
            -width  400

        pack propagate $win off

        # NEXT, create the HTML frame.
        install hframe using htmlframe $win.hframe

        pack $hframe -fill both -expand yes

        # NEXT, create the other widgets.
        label $hframe.dbfile                   \
            -borderwidth  1                    \
            -relief       sunken               \
            -width        60                   \
            -anchor       w                    \
            -textvariable [myvar info(dbfile)]

        ttk::button $hframe.bbrowse                 \
            -text      "Browse"                     \
            -takefocus 0                            \
            -command   [mymethod BrowseForScenario]

        label $hframe.errmsg \
            -width        60                   \
            -anchor       nw                   \
            -justify      left                 \
            -wraplength   400                  \
            -foreground   #C7001B              \
            -textvariable [myvar info(errmsg)]

        # NEXT, lay it out.
        $hframe layout $layout
    }

    #-------------------------------------------------------------------
    # Event handlers

    # BrowseForScenario
    #
    # Called when the user presses the Browse button.  Pops up a 
    # File/Open dialog for scenario files, and hands the result to
    # the ingester.

    method BrowseForScenario {} {
        # FIRST, query for the scenario file name.
        set filename [tk_getOpenFile                      \
                          -parent $win                    \
                          -title "Open Scenario"          \
                          -filetypes {
                              {{Athena Scenario} {.adb}}
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, we have a file name.  Let's try to ingest it.
        try {
            ingester openScenario $filename
            set info(dbfile) [ingester dbfile]
            set info(errmsg) ""
        } trap {} message {
            set info(errmsg) "Error opening $filename:\n$message"
        }
    }


    #-------------------------------------------------------------------
    # Wizard Page Interface

    # enter
    #
    # This command is called when wizman selects this page for
    # display.  It should do any necessary set up (i.e., pull
    # data from the data model).

    method enter {} {
        set info(dbfile) [ingester dbfile]
    }


    # finished
    #
    # This command is called to determine whether or not the user has
    # completed all necessary tasks on this page.  It returns 1
    # if we can go on to the next page, and 0 otherwise.

    method finished {} {
        # The user can go on when he has successfully chosen a
        # scenario file to work with.
        return [ingester gotScenario]
    }


    # leave
    #
    # This command is called when the user presses the wizman's
    # "Next" button to go on to the next page.  It should trigger
    # any processing that needs to be done as the result of the
    # choices made on this page, before the next page is entered.

    method leave {} {
        # Nothing to do
        return
    }
}