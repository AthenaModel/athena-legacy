#-----------------------------------------------------------------------
# FILE: samsheet.tcl
#
#   Economics SAM Spreadsheet view (new for 6x6)
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
# This module is responsible for displaying the initial state of 
# the economy via a Social Accounting Matrix (SAM)
#
# TBD: Consider doing lazy update.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget samsheet {
    #-------------------------------------------------------------------
    # Group: Lookup Tables
    #
    # These variables contain constant data used in building and
    # operating the GUI.

    # This variable serves two purposes: its keys are the sector names,
    # and its values are the units for each sector.
    #
    # NOTE: If we have more meta-data, we will need something more
    # complicated.

    typevariable units {
        goods GBasket/yr
        black tonne/yr
        pop   workyear/yr
    }

    # Look-up table for colors of various kinds.
    #
    #  e - Color for editable cells
    #  r - Color for readonly cells
    #  d - Color for editable cells when they are disabled
    #  a - Color for "A" shape parameters (Leontief production function)
    #  f - Color for "f" shape parameters (Cobb-Douglas parameter)
    #  t - Color for "t" shape parameters (tax-like rates)

    typevariable color -array {
        e "#CCFF99"
        r "#BABABA"
        d "#E3E3E3"
        a "#C16610"
        f "#8BAE56"
        t "#40ABB0"
    }

    # The html layout of the cmsheet(n) objects on this tab

    typevariable layout {
        <table>
          <tr>
            <td colspan="3">
              <b style="font-size:12px">SAM Inputs</b><p>
              <input name="mmatrix">
            </td>
          </tr>
          <tr>
            <td colspan="2">
              <b style="font-size:12px">Other Inputs</b><p>
              <input name="inputs">
            </td>
            <td>
              <b style="font-size:12px">SAM Outputs</b><p>
              <input name="outputs">
            </td>
          </tr>
          <tr>
            <td valign="top">
              <b style="font-size:12px">Shape Parameters</b><p>
              <input name="smatrix">
            </td>
            <td valign="center">
              <p class="leglbl" style="background-color:#C16610">A.i.j</p>
              <p class="leglbl" style="background-color:#8BAE56">f.i.j</p>
              <p class="leglbl" style="background-color:#40ABB0">t.i.j</p>
            </td>
            <td valign="center">
              <p class="legtxt">- Leontief coefficients</p>
              <p class="legtxt">- Cobb-Douglas coefficients</p>
              <p class="legtxt">- tax-like rates</p>
            </td>
          </tr>
        </table>
    }

    # CSS for the legend in the layout

    typevariable css {
        p.leglbl {margin: 0px 0px 1px 0px; width: 30px}
        p.legtxt {margin: 0px 0px 1px 0px}
    }

    #-------------------------------------------------------------------
    # Options
    #
    # Unknown options delegated to the hull

    delegate option * to hull
 
    # The economic model's SAM cellmodel(n).

    component sam

    # The cmsheet(n) widgets used to display the SAM data.

    component mmatrix
    component smatrix
    component inputs
    component outputs

    #--------------------------------------------------------------------
    # Constructor
    #
    # Create the widget and map the CGE.

    constructor {args} {
        # FIRST, get the options.
        $self configurelist $args

        # NEXT, get a copy of the sam and solve it
        set sam [econ sam 1]
        $sam solve

        htmlframe $win.h \
            -yscrollcommand [list $win.yscroll set]

        $win.h configure -styles $css

        # NEXT, Create the GUI components
        $self CreateMoneyMatrix   $win.h.mmatrix
        $self CreateShapeMatrix   $win.h.smatrix
        $self CreateScalarInputs  $win.h.inputs
        $self CreateScalarOutputs $win.h.outputs

        ttk::scrollbar $win.yscroll \
            -command [list $win.h yview]

        # NEXT grid the html frame and scrollbar
        # Note that the widgets in the html frame are layed out once
        # sim state is determined. See the SimState typemethod below
        grid $win.h       -row 0 -column 0 -sticky nsew
        grid $win.yscroll -row 0 -column 1 -sticky ns

        grid rowconfigure    $win 0 -weight 1
        grid columnconfigure $win 0 -weight 1

        # NEXT, prepare for updates.
        notifier bind ::sim  <DbSyncB>     $self [mymethod SyncSheet]
        notifier bind ::sim  <Tick>        $self [mymethod refresh]
        notifier bind ::sim  <State>       $self [mymethod SimState]
        notifier bind ::econ <CellUpdate>  $self [mymethod CellUpdate]
        notifier bind ::econ <SyncSheet>   $self [mymethod SyncSheet]
    }

    # Constructor: Destructor
    #
    # Forget the notifier bindings.
    
    destructor {
        notifier forget $self
    }

    # CreateShapeMatrix w
    #
    # w - The frame widget
    #
    # Creates the matrix component for displaying the shape parameters
    # of the economy as specified in the SAM.

    method CreateShapeMatrix {w} {
        set sectors [$sam index i]
        set ns [llength $sectors]
        let nrows {$ns + 1}
        let ncols {$ns + 1}


        install smatrix using cmsheet $w    \
            -cellmodel $sam                 \
            -state     disabled             \
            -rows      $nrows               \
            -cols      $ncols               \
            -roworigin -1                   \
            -colorigin -1                   \
            -titlerows 1                    \
            -titlecols 1                    \
            -formatcmd {format "%.4f"}

        set titlecol [concat "i,j" $sectors] 
        $smatrix textrow -1,-1 $titlecol
        $smatrix textcol 0,-1  $sectors
        $smatrix textcol 0,5 {
            "n/a"
            "n/a"
            "n/a"
            "n/a"
            "n/a"
            "n/a"
        } 

        $smatrix mapcol 0,0 il  f.%il.goods   f -background $color(f)
        $smatrix mapcol 3,0 inp t.%inp.goods  t -background $color(t)

        $smatrix mapcol 0,1 il  A.%il.black   a -background $color(a)
        $smatrix mapcol 3,1 inp t.%inp.black  t -background $color(t)

        $smatrix mapcol 0,2 il  f.%il.pop     f -background $color(f)
        $smatrix mapcol 3,2 inp t.%inp.pop    t -background $color(t)

        $smatrix mapcol 0,3 i   f.%i.actors   f -background $color(f)

        $smatrix mapcol 0,4 i   f.%i.region   f -background $color(f)
    }

    # CreateMoneyMatrix w
    #
    # w - The frame widget
    #
    # Creates the "matrix" component for displaying monetary flows in 
    # the SAM.

    method CreateMoneyMatrix {w} {
        # FIRST, get some important values
        set sectors [$sam index i]
        set ns      [llength $sectors]
        let nrows   {$ns + 2}
        let ncols   {$ns + 6}
        
        # Main area
        let ractors {$ns - 3}
        let rworld  {$ns - 1}
        let rbe     {$ns + 1}
        set rexp    $ns
        set cbr     $ns
        let cbp     {$ns + 1}
        let cbd     {$ns + 3}
        let cactors {$ns - 3}
        let cpunits {$ncols - 4}
        let cdunits {$ncols - 2}

        # NEXT, create the cmsheet(n).
        install mmatrix using cmsheet $w              \
            -cellmodel     $sam                       \
            -state         normal                     \
            -rows          $nrows                     \
            -cols          $ncols                     \
            -roworigin     -1                         \
            -colorigin     -1                         \
            -titlerows     1                          \
            -titlecols     1                          \
            -browsecommand [mymethod BrowseCmd $w %C] \
            -validatecmd   [mymethod ValidateMoney]   \
            -changecmd     [mymethod CellChanged]     \
            -formatcmd     ::marsutil::moneyfmt


        # NEXT, add titles and empty area
        set titlecol [concat "BX.i.j" $sectors {"Base Rev"} \
                      {"Base Price"} {""} {"Base Demand"}]

        $mmatrix textrow -1,-1 $titlecol        
        $mmatrix textcol 0,-1  [concat $sectors {"Base Exp"}]

        $mmatrix width -1 8

        $mmatrix textcol 0,$cpunits {
            "$/goodsBKT"
            "$/tonne"
            "$/work-year"
            ""
            ""
            ""
            ""
        } units -anchor w -relief flat

        $mmatrix textcol 0,$cdunits {
            "goodsBKTs"
            "tonnes"
            "work-years"
            ""
            ""
            ""
            ""
        } units -anchor w -relief flat

        $mmatrix empty $ractors,$cbp $nrows,$ncols
        $mmatrix empty $rbe,$cbr $rbe,$cbr
        $mmatrix width $cpunits 15
        $mmatrix width $cdunits 15
        $mmatrix width $cbd     13


        # NEXT, Set up the cells
        $mmatrix map    0,0    i j BX.%i.%j e -background $color(e)
        $mmatrix maprow $cbr,0 j   BEXP.%j  r -background $color(r)
        $mmatrix mapcol 0,$cbr i   BREV.%i  r -background $color(r)
        $mmatrix mapcol 0,$cbp il  BP.%il   e -background $color(e)
        $mmatrix mapcol 0,$cbd il  BQD.%il  r -background $color(r)

        $mmatrix tag configure e -state normal
        
        # NEXT, disable the actor sector row and column, these are 
        # computed from the actor definitions and strategies
        $mmatrix maprow $ractors,0 j BX.actors.%j a -background $color(d)
        $mmatrix mapcol 0,$cactors i BX.%i.actors a -background $color(d)

        $mmatrix tag configure a -state disabled
    }

    # CreateScalarInputs   w
    #
    # w   - the name of the window to use as the cmsheet
    #
    # This method creates the cmsheet for some scalar inputs
    # used by the SAM

    method CreateScalarInputs {w} {
        # FIRST, create the cmsheet(n), which is readonly
        install inputs using cmsheet $w               \
            -roworigin     0                          \
            -colorigin     0                          \
            -cellmodel     $sam                       \
            -state         normal                     \
            -rows          5                          \
            -cols          3                          \
            -titlerows     0                          \
            -titlecols     1                          \
            -browsecommand [mymethod BrowseCmd $w %C] \
            -validatecmd   [mymethod ValidateMoney]   \
            -changecmd     [mymethod CellChanged]     \
            -formatcmd     ::marsutil::moneyfmt

        # NEXT, add titles 
        $inputs textcol 0,0 {
            "Remittances"
            "Black mkt Feedstock Price"
            "Feedstock per Unit Product"
            "Max Feedstock Avail."
            "Base Consumers"
        }

        $inputs textcol 0,2 {
            "$/year"
            "$/year"
            ""
            "tonnes/year"
            ""
        } units -anchor w -relief flat

        # NEXT, add data
        $inputs mapcell 0,1 BRFN           e -background $color(e)
        $inputs mapcell 1,1 PF.world.black e -background $color(e)
        $inputs mapcell 2,1 AF.world.black e -background $color(e)
        $inputs mapcell 3,1 MF.world.black e -background $color(e)
        $inputs mapcell 4,1 BaseConsumers  e -background $color(e)

        $inputs width 0 25
        $inputs width 2 15

        $inputs tag configure e -state normal
    }

    # CreateScalarOutputs   w
    #
    # w  - the name of the window to use as the cmsheet
    #
    # This method creates the cmsheet for some scalar outputs
    # generated by the SAM

    method CreateScalarOutputs {w} {
        # FIRST, create the cmsheet(n)
        install outputs using cmsheet $w              \
            -roworigin     0                          \
            -colorigin     0                          \
            -cellmodel     $sam                       \
            -state         disabled                   \
            -rows          7                          \
            -cols          3                          \
            -titlerows     0                          \
            -titlecols     1                          \
            -browsecommand [mymethod BrowseCmd $w %C] \
            -formatcmd     ::marsutil::moneyfmt

        $outputs textcol 0,0 {
            "Foreign Aid to Actors"
            "Foreign Aid to Region"
            "Per cap. Demand for Goods"
            "Exports of Goods"
            "Exports from Black Market"
            "Exported jobs "
            "Black Market Net Revenue"
        }

        $outputs textcol 0,2 {
            "$/year"
            "$/year"
            "goodsBKT/year"
            "goodsBKT/year"
            "tonnes/year"
            "work-years/year"
            "$/year"
        } units -anchor w -relief flat

        $outputs mapcell 0,1 FAA           r -background $color(r)
        $outputs mapcell 1,1 FAR           r -background $color(r)
        $outputs mapcell 2,1 A.goods.pop   r -background $color(r)
        $outputs mapcell 3,1 EXPORTS.goods r -background $color(r)
        $outputs mapcell 4,1 EXPORTS.black r -background $color(r)
        $outputs mapcell 5,1 EXPORTS.pop   r -background $color(r)
        $outputs mapcell 6,1 BNR.black     r -background $color(r)

        $outputs width 0 25
        $outputs width 2 15
    }


    #-------------------------------------------------------------------
    # Event handlers

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
            set val [$sam value $cell]
            if {[string is double $val]} {
                app puts [commafmt $val -places 2]
            } 
        }
    }

    # ValidateMoney cell new
    #
    #  cell - The cell that has a new value
    #  val  - The new value
    #
    # This method validates an entry that has been edited and if its
    # valid returns the new value. If it's invalid, the money command
    # throws an error and the cell remains in edit mode until fixed.

    method ValidateMoney {cell val} {
        set value [money validate $val]
        return $value
    }
    
    # CellChanged cell new
    #
    #  cell - The name of the cell in the underlying cellmodel(n)
    #  new  - The new value to assume
    #
    # This method is called when the user has successfully edited a 
    # cell with a valid monetary value. The new value is converted 
    # to a number before being sent to the order processor.
    #
    # TBD: Need to deal with conversion between money format and number
    #      better, there could be a loss of precision.

    method CellChanged {cell new} {
        # FIRST convert the monetary value
        set new [::marsutil::moneyscan $new]

        # NEXT, send the order to the econ model
        order send gui ECON:SAM:UPDATE id $cell val $new
    }

    # CellUpdate index value
    #
    #  index - the cell index as a cellmodel(n) value (ie. BX.actors.actors)
    #  value - the new value represented as a number (not a moneyfmt)
    #
    # This event handler is called when the econ model sends a notifier
    # that a cell model value has changed. This typically is called as
    # part of undo/redo
    #
    # TBD: Need to deal with conversion between money format and number
    #      better, there could be a loss of precision.

    method CellUpdate {index value} {
        # FIRST, set the cell, solve the updated SAM and refresh the
        # sheet
        $sam set [list $index $value]

        $sam solve

        $self refresh
    }

    # SimState
    #
    # Responds to notifier events from the simulation that the state
    # of the simulation has changed. If the sim is in PREP then the
    # SAM is editable, otherwise it is not.

    method SimState {} {
        # FIRST, get the state
        if {[sim state] eq "PREP"} {

            # NEXT, we are in PREP set the SAM and inputs to normal 
            # and display the layout with help text.
            $mmatrix configure -state normal
            $inputs configure -state normal
            $mmatrix tag configure e -background $color(e)
            $inputs tag configure e -background $color(e)

            $win.h layout "
                Double click a cell to edit. Press \"Enter\" to save, 
                press \"Esc\" to cancel editing.<p>
                Actual actors revenue and expenses will be determined from
                the actor definitions and their strategies once the scenario
                is locked.<p>
                $layout
            "
        } else {

            # NEXT, we are not in PREP, disable the SAM and inputs and
            # remove the help text.
            $mmatrix configure -state disabled
            $inputs configure -state disabled
            $mmatrix tag configure e -background $color(d)
            $inputs tag configure e -background $color(d)

            $win.h layout "
                <br>
                $layout
            "
        }
    }
            
    # SyncSheet
    #
    # This is called when a <DbSyncB> notifier is received. The SAM
    # data is copied from the econ module and the SAM solved before
    # the cmsheet(n) objects are refreshed.

    method SyncSheet {} {
        $sam set [[econ sam] get]
        $sam solve
        $self refresh
    }

    #-------------------------------------------------------------------
    # Public Methods

    # refresh
    #
    # Refreshes all components in the widget.
    
    method refresh {} {
        $mmatrix  refresh
        $smatrix  refresh
        $inputs   refresh
        $outputs  refresh
    }
}


