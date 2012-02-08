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

    # Component: matrix
    #
    # The cmsheet(n) widgets used to display the CGE.
    component matrix
    component inputs
    component outputs
    component shape

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
        # FIRST, get the options.
        $self configurelist $args

        # NEXT, Get the CGE.
        set cge [econ cge]

        # NEXT, Create the GUI components
        $self CreateOverviewMatrix $win.matrix
        $self CreateScalarInputs   $win.inputs
        $self CreateScalarOutputs  $win.outputs
        $self CreateShapeMatrix    $win.shape

        # NEXT, grid the components.
        grid $win.matrix -row 0 -column 0 -columnspan 2 \
            -sticky nsew -padx 5 -pady 5

        grid $win.inputs -row 1 -column 0 \
            -sticky nsew -padx 5 -pady 5

        grid $win.outputs -row 1 -column 1 \
            -sticky nsew -padx 5 -pady 5

        grid $win.shape -row 2 -column 0 -columnspan 2 \
            -sticky nsew -padx 5 -pady 5

        # NEXT, prepare for updates.
        notifier bind ::sim <DbSyncB> $self [mymethod refresh]
        notifier bind ::sim <Tick>    $self [mymethod refresh]
        notifier bind ::econ <Shape>  $self [mymethod refresh]
    }

    # Constructor: Destructor
    #
    # Forget the notifier bindings.
    
    destructor {
        notifier forget $self
    }

    # Method: CreateOverviewMatrix
    #
    # Creates the "matrix" component, which displays the current
    # 3x3 matrix with elaborations.
    # 
    # Syntax:
    #   CreateOverviewMatrix _w_
    #
    #   w - The frame widget
    

    method CreateOverviewMatrix {w} {
        # FIRST, get some important values
        set sectors [$cge index i]
        set ns      [llength $sectors]
        let nrows   {$ns + 2}
        let ncols   {$ns + 7}
        
        # Main area
        let relse   {$ns - 1}
        set rexp    $ns
        set crev    $ns
        let cp      {$ns + 1}
        let cq      {$ns + 2}
        let cunits  {$ns + 3}
        let clatent {$ns + 4}
        let cidle   {$ns + 5}

        # NEXT, create a titled frame
        ttk::labelframe $w \
            -text    "Current Economy" \
            -padding 5

        # NEXT, create the cmsheet(n), which is readonly.
        install matrix using cmsheet $w.sheet \
            -cellmodel   $cge                  \
            -state       disabled              \
            -rows        $nrows                \
            -cols        $ncols                \
            -roworigin   -1                    \
            -colorigin   -1                    \
            -titlerows   1                     \
            -titlecols   1                     \
            -formatcmd   ::marsutil::moneyfmt

        pack $matrix -fill both -expand 1

        # NEXT, create the switch buttons
        ttk::frame $matrix.f
        ttk::radiobutton $matrix.f.x           \
            -text      "$"                    \
            -takefocus 0                      \
            -command   [mymethod MapMatrix]   \
            -value     X                      \
            -variable  [myvar info(mapState)]

        ttk::radiobutton $matrix.f.q           \
            -text      "Qty"                  \
            -takefocus 0                      \
            -command   [mymethod MapMatrix]   \
            -value     Q                      \
            -variable  [myvar info(mapState)]

        pack $matrix.f.q -side right
        pack $matrix.f.x -side right

        $matrix window configure -1,-1 \
            -sticky e                 \
            -relief flat              \
            -window $matrix.f


        # NEXT, add titles and empty area
        $matrix textrow -1,0 [concat $sectors {
            Revenue Price Quantity "" LatentDmd IdleCap}]
        $matrix textcol 0,-1 [concat $sectors {Expense}]

        $matrix textcell -1,$cunits "Units" units \
            -relief flat                         \
            -anchor w
        $matrix textcol 0,$cunits [dict values $units] units

        $matrix width -1 12
        $matrix width $cunits 11

        $matrix empty $rexp,$crev $rexp,$cidle
        $matrix empty $relse,$clatent $relse,$cidle


        # NEXT, Set up the cells
        $matrix maprow $rexp,0 j Out::EXP.%j %cell \
            -background $color(x)
        $matrix mapcol 0,$crev i Out::REV.%i %cell \
            -background $color(x)
        $matrix mapcol 0,$cp   i Out::P.%i   p     \
            -background $color(x)
        $matrix mapcol 0,$cq   i Out::QS.%i  q     \
            -background $color(q)
        $matrix mapcol 0,$clatent imost Out::LATENTDEMAND.%imost q
        $matrix mapcol 0,$cidle   imost Out::IDLECAP.%imost q

        $self MapMatrix
    }

    # Type Method: CreateScalarInputs
    #
    # Creates the "inputs" component, which displays the current
    # scalar inputs.
    # 
    # Syntax:
    #   CreateScalarInputs _w_
    #
    #   w - The frame widget

    method CreateScalarInputs {w} {
        # FIRST, create a titled frame
        ttk::labelframe $w \
            -text    "Current Inputs" \
            -padding 5

        # NEXT, create the cmsheet(n), which is readonly.
        install inputs using cmsheet $w.sheet  \
            -roworigin   0                     \
            -colorigin   0                     \
            -cellmodel   $cge                  \
            -state       disabled              \
            -rows        3                     \
            -cols        3                     \
            -titlerows   0                     \
            -titlecols   1                     \
            -formatcmd   ::marsutil::moneyfmt

        pack $inputs -fill both -expand 1

        # NEXT, add titles
        $inputs textcol 0,0 {
            "Consumers"
            "Labor Force"
            "LSF"
        }

        $inputs textcol 0,2 {
            "People"
            "People"
            ""
        } units -anchor w -relief flat
        
        # NEXT, add data
        $inputs mapcell 0,1 In::Consumers q -background $color(q)
        $inputs mapcell 1,1 In::WF        q
        $inputs mapcell 2,1 In::LSF       q

        # NEXT, expand widths
        $inputs width 0 12
    }

    # Type Method: CreateScalarOutputs
    #
    # Creates the "outputs" component, which displays the current
    # scalar outputs.
    # 
    # Syntax:
    #   CreateScalarOutputs _w_
    #
    #   w - The frame widget

    method CreateScalarOutputs {w} {
        # FIRST, create a titled frame
        ttk::labelframe $w \
            -text    "Other Outputs" \
            -padding 5

        # NEXT, create the cmsheet(n), which is readonly.
        install outputs using cmsheet $w.sheet  \
            -roworigin   0                     \
            -colorigin   0                     \
            -cellmodel   $cge                  \
            -state       disabled              \
            -rows        5                     \
            -cols        3                     \
            -titlerows   0                     \
            -titlecols   1                     \
            -formatcmd   ::marsutil::moneyfmt

        pack $outputs -fill both -expand 1

        # NEXT, add titles
        $outputs textcol 0,0 {
            "GDP"
            "CPI"
            "Deflated GDP"
            "Unemployment"
            "Unemp. Rate"
        }

        $outputs width 0 14

        $outputs textcol 0,2 {
            "$/Year"
            ""
            "$/Year, Deflated"
            "work-year"
            "%"
        } units -anchor w -relief flat

        $outputs width 2 16
        
        # NEXT, add data
        $outputs mapcell 0,1 Out::GDP          x -background $color(x)
        $outputs mapcell 1,1 Out::CPI          q -background $color(q)
        $outputs mapcell 2,1 Out::DGDP         x
        $outputs mapcell 3,1 Out::Unemployment q
        $outputs mapcell 4,1 Out::UR           q
    }


    # Type Method: CreateShapeMatrix
    #
    # Creates the "shape" component, which displays the current
    # shape inputs
    # 
    # Syntax:
    #   CreateShapeMatrix _w_
    #
    #   w - The frame widget

    method CreateShapeMatrix {w} {
        # FIRST, create a titled frame
        ttk::labelframe $w \
            -text    "Shape Inputs" \
            -padding 5

        # NEXT, get some important values
        set sectors [$cge index i]
        set ns      [llength $sectors]
        let nrows   {$ns + 1}
        let ncols   {$ns + 6}
        
        # Main area
        let cbp      $ns

        # NEXT, create the cmsheet(n), which is readonly.
        install shape using cmsheet $w.sheet \
            -cellmodel   $cge                  \
            -state       disabled              \
            -rows        $nrows                \
            -cols        $ncols                \
            -roworigin   -1                    \
            -colorigin   -1                    \
            -titlerows   1                     \
            -titlecols   1                     \
            -formatcmd   ::marsutil::moneyfmt

        pack $shape -fill both -expand 1


        # NEXT, add titles and empty area
        $shape textrow -1,-1 [concat "f.i.j" $sectors {"Base Price"}]
        $shape textcol 0,-1  $sectors

        $shape width -1 8

        $shape width 4 2
        $shape empty -1,4 2,4

        $shape textcell 0,5 "Consumption" label \
            -relief flat

        $shape width 5 13

        $shape textcell 0,7 "GBasket/Yr/Capita" wlabel \
            -anchor w    \
            -relief flat
        $shape width 7 17

        $shape empty 1,5 2,7

        # NEXT, Set up the cells
        $shape map    0,0    i j f.%i.%j q -background $color(q)
        $shape mapcol 0,$cbp i   BP.%i   x -background $color(x)

        $shape mapcell 0,6 A.goods.pop q
    }

    

    #-------------------------------------------------------------------
    # Event handlers

    # Method: MapMatrix
    #
    # Based on the map state, displays the X.i.js or the
    # QD.i.j's.

    method MapMatrix {} {
        if {$info(mapState) eq "X"} {
            $matrix map 0,0 i j Out::X.%i.%j x \
                -background $color(x)
        } else {
            $matrix map 0,0 i j Out::QD.%i.%j qij \
                -background $color(q)
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    # Method: refresh
    #
    # Refreshes all components in the widget.
    
    method refresh {} {
        if {[parmdb get econ.disable]} {
            $win.matrix configure -text "Current Economy (*DISABLED*)"
        } else {
            $win.matrix configure -text "Current Economy"
        }

        $matrix  refresh
        $inputs  refresh
        $outputs refresh
        $shape refresh
    }
}


