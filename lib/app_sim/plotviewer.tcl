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

    # Component: newbtn
    #
    # New plot button.

    component newbtn

    # Component: helpbtn
    #
    # Help browser button

    component helpbtn

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

        # New Plot Button
        install newbtn using mkaddbutton $bar.new \
            "New Plot"                            \
            -state   normal                       \
            -command [mymethod NewPlot]
  
        install helpbtn using ttk::button $bar.help \
            -style   Toolbutton                     \
            -image   ::projectgui::icon::help22     \
            -command [list helpbrowserwin showhelp vars]

        DynamicHelp::add $helpbtn -text "Help on Display Variables"

        pack $newbtn  -side left
        pack $helpbtn -side right

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

    # Method: NewPlot
    #
    # The user wants to create a new plot.  Query the user for the
    # requisite variable name(s).

    method NewPlot {} {
        set pwin [$man insert 0]
        set f    [$pwin frame]

        set num [incr pwinCounter]
        $pwin configure -title $num

        nbchart $f.chart \
            -title    "Chart #$num"                             \
            -yscrollcommand [list $f.yscroll set]

        ttk::scrollbar $f.yscroll \
            -command [list $f.chart yview]

        pack $f.yscroll -side right -fill y
        pack $f.chart  -fill both -expand yes
    }



    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}


