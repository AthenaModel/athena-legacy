#-----------------------------------------------------------------------
# FILE: plotviewer.tcl
#
#   Athena Plot Viewer
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

#-----------------------------------------------------------------------
# Widget: plotviewer
#
# The plotviewer(n) widget implements the Athena "Plots" tab.  It
# consists of a toolbar and a pwinman(n) that contains plots.
#
# TBD:
#    GUI creation of plots
#    command-line creation of plots
#    GUI editing of plots (change variables, title)
#
#-----------------------------------------------------------------------

snit::widget plotviewer {
    #-------------------------------------------------------------------
    # Group: Components

    # Component: bar
    #
    # The toolbar

    component bar

    # Component: bnbhood
    #
    # New neighborhood chart button.

    component bnbhood

    # Component: btime
    #
    # New time plot button.

    component btime

    # Component: bhelp
    #
    # Help browser button

    component bhelp

    # Component: man
    #
    # pwinman(n) pseudo-window manager

    component man

    #-------------------------------------------------------------------
    # Group: Options
    # 
    # Unknown options are delegated to the hull

    delegate option * to hull

    #-------------------------------------------------------------------
    # Group: Instance Variables

    # Variable: pwinCounter
    #
    # Supplies window numbers.
    
    variable pwinCounter 0

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the components.
        
        # Toolbar
        install bar using ttk::frame $win.bar

        # New Neighborhood Chart
        install bnbhood using ttk::button $bar.nbhood \
            -style   Toolbutton                         \
            -image   ::projectgui::icon::nbpoly         \
            -command [mymethod NewNbhoodPlot]

        DynamicHelp::add $bnbhood -text "New Neighborhood Bar Chart"
  
        # New Neighborhood Chart
        install btime using ttk::button $bar.time \
            -style   Toolbutton                      \
            -image   ::marsgui::icon::clock          \
            -command [mymethod NewTimePlot]

        DynamicHelp::add $btime -text "New Time Series Plot"

        # Help
        install bhelp using ttk::button $bar.help \
            -style   Toolbutton                     \
            -image   ::projectgui::icon::help22     \
            -command [list helpbrowserwin showhelp vars]

        DynamicHelp::add $bhelp -text "Help on Display Variables"

        pack $bnbhood  -side left
        pack $btime    -side left
        pack $bhelp    -side right

        # Separator
        ttk::separator $win.sep1

        # Window manager
        install man using pwinman $win.man

        grid $bar      -row 0 -column 0 -sticky ew
        grid $win.sep1 -row 1 -column 0 -sticky ew
        grid $man      -row 2 -column 0 -sticky nsew
        
        grid rowconfigure    $win 2 -weight 1
        grid columnconfigure $win 0 -weight 1
    }

    #-------------------------------------------------------------------
    # Event Handlers

    # Method: NewNbhoodPlot
    #
    # The user wants to create a new nbhood plot.

    method NewNbhoodPlot {} {
        set pwin [$man insert 0]
        set f    [$pwin frame]

        set num [incr pwinCounter]
        $pwin configure -title $num

        nbchart $f.chart \
            -title    "Nbhood Chart #$num"        \
            -yscrollcommand [list $f.yscroll set]

        ttk::scrollbar $f.yscroll \
            -command [list $f.chart yview]

        pack $f.yscroll -side right -fill y
        pack $f.chart  -fill both -expand yes
    }

    # Method: NewTimePlot
    #
    # The user wants to create a new time plot.

    method NewTimePlot {} {
        set pwin [$man insert 0]
        set f    [$pwin frame]

        set num [incr pwinCounter]
        $pwin configure -title $num

        timechart $f.chart \
            -title    "Time Plot #$num"

        pack $f.chart  -fill both -expand yes
    }



    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}


