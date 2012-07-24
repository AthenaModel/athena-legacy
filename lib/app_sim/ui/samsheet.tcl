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

    # Type Variable: units
    #
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

    # Type Variable: color
    #
    # Look-up table for colors of various kinds.
    #
    #  e - Color for editable cells
    #  r - Color for readonly cells

    typevariable color -array {
        e "#CCFF99"
        r "#BABABA"
    }

    #-------------------------------------------------------------------
    # Options
    #
    # Unknown options delegated to the hull

    delegate option * to hull
 
    # The economic model's SAM cellmodel(n).

    component sam

    # The cmsheet(n) widgets used to display the SAM data.

    component matrix
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

        htmlframe $win.h

        # NEXT, Create the GUI components
        $self CreateMatrix        $win.h.matrix
        $self CreateScalarInputs  $win.h.inputs
        $self CreateScalarOutputs $win.h.outputs

        # NEXT layout the components
        $win.h layout {
            Double click a cell to edit. Press "Enter" to save, 
            press "Esc" to cancel editing.<p>
            <table>
             <tr>
                <td colspan=2>
                  <b style="font-size:12px">SAM Inputs</b><p>
                  <input name="matrix">
                </td>
              </tr>
              <tr>
                <td valign="top">
                  <b style="font-size:12px">Other Inputs</b><p>
                  <input name="inputs">
                </td>
                <td valign="top">
                  <b style="font-size:12px">SAM Outputs</b><p>
                  <input name="outputs">
                </td>
              </tr>
            </table>
        }

        # NEXT pack the html frame
        pack $win.h -expand 1 -fill both

        # NEXT, prepare for updates.
        notifier bind ::sim  <DbSyncB>     $self [mymethod refresh]
        notifier bind ::sim  <Tick>        $self [mymethod refresh]
        notifier bind ::econ <Shape>       $self [mymethod refresh]
        notifier bind ::econ <CellUpdate>  $self [mymethod CellUpdate]
    }

    # Constructor: Destructor
    #
    # Forget the notifier bindings.
    
    destructor {
        notifier forget $self
    }

    # CreateMatrix w
    #
    # w - The frame widget
    #
    # Creates the "matrix" component, which displays the 
    # SAM matrix inputs and computed values

    method CreateMatrix {w} {
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
        let cpunits {$ncols - 4}
        let cdunits {$ncols - 2}

        # NEXT, create the cmsheet(n).
        install matrix using cmsheet $w       \
            -cellmodel   $sam                \
            -state       normal              \
            -rows        $nrows              \
            -cols        $ncols              \
            -roworigin   -1                  \
            -colorigin   -1                  \
            -titlerows   1                   \
            -titlecols   1                   \
            -validatecmd [mymethod ValidateMoney] \
            -changecmd   [mymethod CellChanged]   \
            -formatcmd   ::marsutil::moneyfmt


        # NEXT, add titles and empty area
        set titlecol [concat "BX.i.j" $sectors {"Base Rev"} \
                      {"Base Price"} {""} {"Base Demand"}]

        $matrix textrow -1,-1 $titlecol        
        $matrix textcol 0,-1  [concat $sectors {"Base Exp"}]

        $matrix width -1 8

        $matrix textcol 0,$cpunits {
            "$/goodsBKT"
            "$/tonne"
            "$/work-year"
            ""
            ""
            ""
            ""
        } units -anchor w -relief flat

        $matrix textcol 0,$cdunits {
            "goodsBKTs"
            "tonnes"
            "work-years"
            ""
            ""
            ""
            ""
        } units -anchor w -relief flat

        $matrix empty $ractors,$cbp $nrows,$ncols
        $matrix empty $rbe,$cbr $rbe,$cbr
        $matrix width $cpunits 15
        $matrix width $cdunits 15
        $matrix width $cbd     13


        # NEXT, Set up the cells
        $matrix map    0,0    i j BX.%i.%j e -background $color(e)
        $matrix maprow $cbr,0 j   BEXP.%j  r -background $color(r)
        $matrix mapcol 0,$cbr i   BREV.%i  r -background $color(r)
        $matrix mapcol 0,$cbp il  BP.%il   e -background $color(e)
        $matrix mapcol 0,$cbd il  BQD.%il  r -background $color(r)

        $matrix tag configure e -state normal
    }

    # CreateScalarInputs   w
    #
    # w   - the name of the window to use as the cmsheet
    #
    # This method creates the cmsheet for some scalar inputs
    # used by the SAM

    method CreateScalarInputs {w} {
        # FIRST, create the cmsheet(n), which is readonly
        install inputs using cmsheet $w    \
            -roworigin 0                   \
            -colorigin 0                   \
            -cellmodel $sam                \
            -state     normal              \
            -rows      4                   \
            -cols      3                   \
            -titlerows 0                   \
            -titlecols 1                   \
            -validatecmd [mymethod ValidateMoney] \
            -changecmd   [mymethod CellChanged]   \
            -formatcmd ::marsutil::moneyfmt

        # NEXT, add titles 
        $inputs textcol 0,0 {
            "Remittances and Aid"
            "Black mkt Net Rev."
            "Black mkt Feedstock Price"
            "Feedstock per Unit Product"
        }

        $inputs textcol 0,2 {
            "$/year"
            "$/year"
            "$/year"
            ""
        } units -anchor w -relief flat

        # NEXT, add data
        $inputs mapcell 0,1 BRFN           e -background $color(e)
        $inputs mapcell 1,1 BNR.black      e -background $color(e)
        $inputs mapcell 2,1 PF.world.black e -background $color(e)
        $inputs mapcell 3,1 AF.world.black e -background $color(e)

        $inputs width 0 25

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
        install outputs using cmsheet $w \
            -roworigin 0                 \
            -colorigin 0                 \
            -cellmodel $sam              \
            -state     disabled          \
            -rows      2                 \
            -cols      3                 \
            -titlerows 0                 \
            -titlecols 1                 \
            -formatcmd ::marsutil::moneyfmt

        $outputs textcol 0,0 {
            "Foreign Aid to Actors"
            "Foreign Aid to Region"
        }

        $outputs textcol 0,2 {
            "$/year"
            "$/year"
        } units -anchor w -relief flat

        $outputs mapcell 0,1 FAA  r -background $color(r)
        $outputs mapcell 1,1 FAR  r -background $color(r)

        $outputs width 0 20
    }


    #-------------------------------------------------------------------
    # Event handlers

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

    #-------------------------------------------------------------------
    # Public Methods

    # refresh
    #
    # Refreshes all components in the widget.
    
    method refresh {} {
        $matrix refresh
        $inputs   refresh
        $outputs  refresh
    }
}


