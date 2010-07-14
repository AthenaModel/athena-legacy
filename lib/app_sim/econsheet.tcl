#-----------------------------------------------------------------------
# FILE: econsheet.tcl
#
#   Economics Spreadsheet view
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
# Widget: econsheet
#
# This module is responsible for displaying the current state of 
# the economy.
#
# TBD: Consider doing lazy update.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget econsheet {
    #-------------------------------------------------------------------
    # Group: Lookup Tables
    #
    # These variables contain constant data used in building and
    # operating the GUI.

    # Type Variable: units
    #
    # This variable serves two purposes: its keys are the sector names,
    # and its values are the units for each sector.
    #
    # NOTE: If we have more meta-data, we will need something more
    # complicated.

    typevariable units {
        goods GBasket/yr
        pop   workyear/yr
        else  Ebasket/yr
    }

    # Type Variable: color
    #
    # Look-up table for colors of various kinds.
    #
    #  q - Color for quantities of things
    #  x - Color for money amounts

    typevariable color -array {
        q "#FFCC33"
        x "#CCFF99"
    }

    #-------------------------------------------------------------------
    # Group: Options
    #
    # Unknown options delegated to the hull

    delegate option * to hull
 
    #-------------------------------------------------------------------
    # Group: Components

    # Component: cge
    #
    # The economic model's CGE cellmodel(n).

    component cge

    # Component: sheet
    #
    # The cmsheet(n) used to display the CGE.
    component sheet

    #-------------------------------------------------------------------
    # Group: Instance Variables

    # Variable: info
    #
    # Array of scalars.
    #
    # mapState - X or Q, indicating which variable set is displayed.
    
    variable info -array {
        mapState X
    }

    #--------------------------------------------------------------------
    # Group: Constructor

    # Constructor: Constructor
    #
    # Create the widget and map the CGE.

    constructor {args} {
        # FIRST, Get the CGE.
        set cge [econ cge]

        # NEXT, get some important values
        set sectors [$cge index i]
        set ns      [llength $sectors]
        let nrows   {2*$ns + 3}
        let ncols   {$ns + 5}
        
        # Main area
        set rexp    $ns
        set crev    $ns
        let cp      {$ns + 1}
        let cq      {$ns + 2}
        let cunits  {$ns + 3}

        # Shortages/Overages area
        let rblank  {$ns + 1}
        let rsubt   {$ns + 2}
        let rgoods  {$ns + 3}
        let rpop    {$ns + 4}
        let clatent 0
        let cidle   1

        # NEXT, create the cmsheet(n), which is readonly.
        install sheet using cmsheet $win.sheet \
            -cellmodel   $cge                  \
            -state       disabled              \
            -rows        $nrows                \
            -cols        $ncols                \
            -roworigin   -1                    \
            -colorigin   -1                    \
            -titlerows   1                     \
            -titlecols   1                     \
            -formatcmd   ::marsutil::moneyfmt

        pack $sheet -fill both -expand yes

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the switch buttons
        ttk::frame $sheet.f
        ttk::radiobutton $sheet.f.x           \
            -text      "$"                    \
            -takefocus 0                      \
            -command   [mymethod MapMatrix]   \
            -value     X                      \
            -variable  [myvar info(mapState)]

        ttk::radiobutton $sheet.f.q           \
            -text      "Qty"                  \
            -takefocus 0                      \
            -command   [mymethod MapMatrix]   \
            -value     Q                      \
            -variable  [myvar info(mapState)]

        pack $sheet.f.q -side right
        pack $sheet.f.x -side right

        $sheet window configure -1,-1 \
            -sticky e                 \
            -relief flat              \
            -window $sheet.f


        # NEXT, add titles and empty area
        $sheet textrow -1,0 [concat $sectors {Revenue Price Quantity}]
        $sheet textcol 0,-1 [concat $sectors {Expense}]

        $sheet textcell -1,$cunits "Units" units \
            -relief flat                         \
            -anchor w
        $sheet textcol 0,$cunits [dict values $units] units

        $sheet width -1 8
        $sheet width $cunits 10

        $sheet empty $rexp,$crev $rexp,$cunits


        # NEXT, Set up the cells
        $sheet maprow $rexp,0 j Out::EXP.%j %cell \
            -background $color(x)
        $sheet mapcol 0,$crev i Out::REV.%i %cell \
            -background $color(x)
        $sheet mapcol 0,$cp   i Out::P.%i   p     \
            -background $color(x)
        $sheet mapcol 0,$cq   i Out::QS.%i  q     \
            -background $color(q)

        $self MapMatrix

        # NEXT, Overages/Shortages
        $sheet empty $rblank,-1 $rblank,$cunits
        $sheet empty $rsubt,2   $rpop,$cunits

        $sheet textrow $rsubt,0 {LatentDmd IdleCap} title

        $sheet textcol $rgoods,-1 [$cge index imost]

        $sheet mapcol $rgoods,$clatent imost Out::LATENTDEMAND.%imost q
        $sheet mapcol $rgoods,$cidle   imost Out::IDLECAP.%imost  q

        # NEXT, prepare for updates.
        notifier bind ::sim <DbSyncB> $self [mymethod refresh]
        notifier bind ::sim <Tick>    $self [mymethod refresh]
    }

    # Constructor: Destructor
    #
    # Forget the notifier bindings.
    
    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Event handlers

    # Method: MapMatrix
    #
    # Based on the map state, displays the X.i.js or the
    # QD.i.j's.

    method MapMatrix {} {
        if {$info(mapState) eq "X"} {
            $sheet map 0,0 i j Out::X.%i.%j x \
                -background $color(x)
        } else {
            $sheet map 0,0 i j Out::QD.%i.%j qij \
                -background $color(q)
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method refresh to sheet
}


