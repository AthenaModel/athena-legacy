#-----------------------------------------------------------------------
# FILE: cgesheet.tcl
#
#   Economics CGE Spreadsheet view (new for 6x6)
#   This is an experimental sheet for now
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#    Dave Hanks
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget: cgesheet
#
# This module is responsible for displaying the current state of 
# the economy via a Computable General Equilibrium matrix
#
# TBD: Consider doing lazy update.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget cgesheet {
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
        goods goodsBKT/yr
        black tonnes/yr
        pop   work-years/yr
    }

    # Type Variable: color
    #
    # Look-up table for colors of various kinds.
    #
    #  q - Color for quantities of things
    #  x - Color for money amounts

    #  old x "#CCFF99"

    typevariable color -array {
        q "#FFCC33"
        x "#D4E3FF"
    }

    #-------------------------------------------------------------------
    # Group: Options
    #
    # Unknown options delegated to the hull

    delegate option * to hull
 
    #
    # The economic model's CGE cellmodel(n) .
    component cge

    # A label widget that displays the econ model as disabled, if
    # it is so.
    component sheetlbl

    # The cmsheet(n) widgets used to display values from the CGE.
    component money
    component quant
    component inputs
    component outputs

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

        # NEXT, the frame for the htmlframe and scroll bar
        ttk::frame $win.frm

        # NEXT create the htmlfram and GUI components
        htmlframe $win.frm.h \
            -yscrollcommand [list $win.frm.yscroll set]

        $self CreateMoneyMatrix    $win.frm.h.money
        $self CreateQuantMatrix    $win.frm.h.quant
        $self CreateScalarInputs   $win.frm.h.inputs
        $self CreateScalarOutputs  $win.frm.h.outputs

        ttk::scrollbar $win.frm.yscroll \
            -command [list $win.frm.h yview]

        install sheetlbl using ttk::label $win.frm.h.sheetlbl \
            -text "Current Economy" -font messagefontb

        # NEXT specify the layout in the htmlframe
        $win.frm.h layout {
            <table>
              <tr>
                <td colspan=2>
                  <input name="sheetlbl"><p>
                  <b style="font-size:12px">Dollars</b><br>
                  <input name="money"><p>
                  <br><br>
                  <b style="font-size:12px">Quantities</b><br>
                  <input name="quant"><p>
                </td>
              </tr>
              <tr>
                <td valign="top">
                  <b style="font-size:12px">Current Inputs</b><p>
                  <input name="inputs">
                </td>
                <td valign="top">
                  <b style="font-size:12px">Other Outputs</b><p>
                  <input name="outputs">
                </td>
              </tr>
            </table>
        }

        # NEXT, pack all the widgets into tab
        pack $win.frm.h       -side left  -expand 1 -fill both      
        pack $win.frm.yscroll -side left  -expand 1 -fill y -anchor e
        pack $win.frm                     -expand 1 -fill both

        # NEXT, prepare for updates.
        notifier bind ::sim  <DbSyncB>   $self [mymethod refresh]
        notifier bind ::sim  <Tick>      $self [mymethod refresh]
        notifier bind ::econ <CgeUpdate> $self [mymethod refresh]
    }

    # Constructor: Destructor
    #
    # Forget the notifier bindings.
    
    destructor {
        notifier forget $self
    }

    # CreateMoneyMatrix   w
    #
    #   w - The widget window
    #
    # Creates the CGE money component, which displays the current
    # 6x6 CGE in amounts of money with elaborations.
    
    method CreateMoneyMatrix {w} {
        # FIRST, get some important values
        set sectors [$cge index i]
        set ns      [llength $sectors]
        set rexp    $ns
        let nrows   {$ns + 2}
        let ncols   {$ns + 5}

        # NEXT, create the cmsheet(n), which is readonly.
        install money using cmsheet $w             \
            -cellmodel     $cge                    \
            -state         disabled                \
            -rows          $nrows                  \
            -cols          $ncols                  \
            -roworigin     -1                      \
            -colorigin     -1                      \
            -titlerows     1                       \
            -titlecols     1                       \
            -browsecommand [mymethod BrowseCmd $w %C] \
            -formatcmd     ::marsutil::moneyfmt

        $money textcol 0,-1 [concat $sectors {Expense}]

        $money maprow $rexp,0 j Out::EXP.%j %cell \
            -background $color(x)

        # Main area
        let ractors {$ns - 3}
        let rworld  {$ns - 1}
        set rexp    $ns
        let cactors {$ns - 3}
        let cworld  {$ns - 1}
        set crev    $ns
        let cp      {$ns + 1}
        let cq      {$ns + 2}
        let cunits  {$ns + 3}
        let clatent {$ns + 4}
        let cidle   {$ns + 5}

        # NEXT, add titles and empty area
        $money textrow -1,0 [concat $sectors {
            Revenue Price Quantity ""}]

        $money textcell -1,$cunits "Units" units \
            -relief flat                         \
            -anchor w
        $money textcol 0,$cunits [dict values $units] units

        $money width -1 12
        $money width $cunits 13

        $money empty $rexp,$crev $rexp,$cidle
        $money empty $ractors,$cp $rworld,$cidle

        # NEXT, Set up the cells
        $money mapcol 0,$crev i Out::REV.%i %cell \
            -background $color(x)
        $money mapcol 0,$cp   gbp Out::P.%gbp   p     \
            -background $color(x)
        $money mapcol 0,$cq   gbp Out::QS.%gbp  q     \
            -background $color(q)

        $money textcell -1,-1 "X.i.j" 

        # NEXT, map amounts of money to the cmsheet
        $money map 0,0 i j Out::X.%i.%j x \
            -background $color(x)
    }

    # CreateQuantMatrix   w
    #
    #   w -  the widget window
    #
    # Creates the CGE quantities component, which displays the 
    # current 6x6 CGE in quantities for those sectors that have
    # them.

    method CreateQuantMatrix {w} {
        # FIRST, get some important values
        set csectors [$cge index i]
        set rsectors [$cge index gbp]
        set nc       [llength $csectors]
        set nr       [llength $rsectors]
        set rdem     $nr
        let cactors  {$nc - 3}
        let cidle    {$nc + 3}
        let nrows    {$nr + 2}
        let ncols    {$nc + 5}

        # NEXT, create the cmsheet(n), which is readonly.
        install quant using cmsheet $w             \
            -cellmodel     $cge                    \
            -state         disabled                \
            -rows          $nrows                  \
            -cols          $ncols                  \
            -roworigin     -1                      \
            -colorigin     -1                      \
            -titlerows     1                       \
            -titlecols     1                       \
            -browsecommand [mymethod BrowseCmd $w %C] \
            -formatcmd     ::marsutil::moneyfmt

        $quant textcol 0,-1 [concat $rsectors {Demand}]

        $quant maprow $rdem,0 gbp Out::QD.%gbp %cell \
            -background $color(q)

        # Main area
        set ractors $nr
        let cworld  {$nc - 1}
        set cq      $nc
        let cunits  {$nc + 1}
        let clatent {$nc + 2}

        # NEXT, add titles and empty area
        $quant textrow -1,0 [concat $csectors {
            Quantity "" LatentDmd IdleCap}]

        $quant textcell -1,$cunits "Units" units \
            -relief flat                         \
            -anchor w

        $quant textcol 0,$cunits [dict values $units] units

        $quant width -1 12
        $quant width $cunits 13

        $quant empty $rdem,$cactors $rdem,$cidle

        # NEXT, Set up the cells
        $quant mapcol 0,$cq   gbp Out::QS.%gbp  q     \
            -background $color(q)
        $quant mapcol 0,$clatent gbp Out::LATENTDEMAND.%gbp q
        $quant mapcol 0,$cidle   gbp Out::IDLECAP.%gbp q

        $quant textcell -1,-1 "QD.i.j"

        # NEXT, map quantities to the cmsheet
        $quant map 0,0 gbp j Out::QD.%gbp.%j qij \
            -background $color(q)
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
        # FIRST, create the cmsheet(n), which is readonly.
        install inputs using cmsheet $w               \
            -roworigin     0                          \
            -colorigin     0                          \
            -cellmodel     $cge                       \
            -state         disabled                   \
            -rows          5                          \
            -cols          3                          \
            -titlerows     0                          \
            -titlecols     1                          \
            -browsecommand [mymethod BrowseCmd $w %C] \
            -formatcmd     ::marsutil::moneyfmt

        pack $inputs -fill both -expand 1

        # NEXT, add titles
        $inputs textcol 0,0 {
            "Consumers"
            "Consumer Sec. Factor"
            "Labor Force"
            "Labor Sec. Factor"
            "FAR Graft Factor"
        }

        $inputs textcol 0,2 {
            "People"
            ""
            "People"
            ""
            ""
        } units -anchor w -relief flat
        
        # NEXT, add data
        $inputs mapcell 0,1 In::Consumers q -background $color(q)
        $inputs mapcell 1,1 In::CSF       q
        $inputs mapcell 2,1 In::LF        q
        $inputs mapcell 3,1 In::LSF       q
        $inputs mapcell 4,1 In::graft     q -formatcmd {format "%.3f"}

        # NEXT, expand widths
        $inputs width 0 21
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
        # FIRST, create the cmsheet(n), which is readonly.
        install outputs using cmsheet $w  \
            -roworigin     0                          \
            -colorigin     0                          \
            -cellmodel     $cge                       \
            -state         disabled                   \
            -rows          11                         \
            -cols          3                          \
            -titlerows     0                          \
            -titlecols     1                          \
            -browsecommand [mymethod BrowseCmd $w %C] \
            -formatcmd     ::marsutil::moneyfmt

        # NEXT, add titles
        $outputs textcol 0,0 {
            "GDP"
            "CPI"
            "Deflated GDP"
            "Per Capita Deflated GDP"
            "Per Cap. Demand for goods"
            "Unemployment"
            "Unemp. Rate"
            "Insecure Labor Force"
            "Goods Shortage"
            "Black Mkt Shortage"
            "Labor Shortage"
        }

        $outputs width 0 25

        $outputs textcol 0,2 {
            "$/Year"
            ""
            "$/Year, Deflated"
            "$/Year, Deflated"
            "goodsBKT/year"
            "work-years"
            "%"
            "work-years"
            "goodsBKT/year"
            "tonne/year"
            "work-years"
        } units -anchor w -relief flat

        $outputs width 2 17
        
        # NEXT, add data
        $outputs mapcell  0,1 Out::GDP            x -background $color(x)
        $outputs mapcell  1,1 Out::CPI            q -background $color(q)
        $outputs mapcell  2,1 Out::DGDP           x
        $outputs mapcell  3,1 Out::PerCapDGDP     x 
        $outputs mapcell  4,1 Out::A.goods.pop    q
        $outputs mapcell  5,1 Out::Unemployment   q
        $outputs mapcell  6,1 Out::UR             q
        $outputs mapcell  7,1 Out::LFU            q
        $outputs mapcell  8,1 Out::SHORTAGE.goods q
        $outputs mapcell  9,1 Out::SHORTAGE.black q
        $outputs mapcell 10,1 Out::SHORTAGE.pop   q
    }

    #------------------------------------------------------------------
    # Event Callback Handler

    # BrowseCmd sheet rc
    #
    # sheet  - the cmsheet(n) object that contains the cells
    # rc     - row,col index into the supplied cmsheet
    #
    # This method extracts the cell name from the supplied cmsheet
    # object and then converts it to the cell name and extracts the 
    # raw data and displays it in the app messageline(n) 
    # using a comma formatted number

    method BrowseCmd {sheet rc} {
        # FIRST, extract the cell name, if it does not exist, done.
        if {[$sheet cell $rc] ne ""} {
            set cell [$sheet cell $rc]

            # NEXT, convert and display in the app message line
            set val [$cge value $cell]
            if {[string is double $val]} {
                app puts [commafmt $val -places 2]
            } 
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    # Method: refresh
    #
    # Refreshes all components in the widget.
    
    method refresh {} {
        if {[parmdb get econ.disable]} {
            $sheetlbl configure -text "Current Economy (*DISABLED*)" 
        } else {
            $sheetlbl configure -text "Current Economy" 
        }

        $money   refresh
        $quant   refresh
        $inputs  refresh
        $outputs refresh
    }
}


