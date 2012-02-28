#-----------------------------------------------------------------------
# FILE: cmsheet.tcl
#   
#   cellmodel(n) worksheet widget, based on TkTable
#
# PACKAGE:
#   marsgui(n) -- Mars GUI Infrastructure Package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

namespace eval ::marsgui:: {
    namespace export cmsheet
}

#-----------------------------------------------------------------------
# Widget: cmsheet
#
# The cmsheet widget is a Tktable mapped to a cellmodel(n) model.
# The client maps particular cellmodel(n) cells to rows, columns,
# and regions in the Tktable; thereafter, edits in editable
# cmsheet cells will cause the cell model to recompute and display
# the updated information.  In addition, the Tktable text editing 
# capability has been replaced with new code using a ttk::entry 
# widget.
#
#-----------------------------------------------------------------------

snit::widget ::marsgui::cmsheet {
    #-------------------------------------------------------------------
    # Group: Components

    # Component: cm
    #
    # The cellmodel(n) holding the model that backs the GUI.

    component cm

    # Component: tab
    #
    # The tktable displaying the cellmodel.

    component tab

    # Component: entry
    #
    # The ttk::entry used for editing cells in the Tktable.
    component entry

    #-------------------------------------------------------------------
    # Group: Options
    #
    # By default, options are delegated to the hull frame

    delegate option * to hull

    delegate option -height    to tab
    delegate option -maxheight to tab
    delegate option -maxwidth  to tab
    delegate option -width     to tab

    delegate option -entryfont to entry as -font

    # Option: -cols
    #
    # The number of columns in the sheet.

    delegate option -cols to tab

    # Option: -colorigin
    #
    # Base index for columns.

    delegate option -colorigin to tab

    # Option: -font
    #
    # Base font

    delegate option -font to tab

    # Option: -rows
    #
    # The number of rows in the sheet.

    delegate option -rows to tab

    # Option: -roworigin
    #
    # Base index for rows.

    delegate option -roworigin to tab

    # Option: -titlecols
    #
    # Number of non-scrolling title columns.

    delegate option -titlecols to tab

    # Option: -titlerows
    #
    # Number of non-scrolling title rows.

    delegate option -titlerows to tab

    # Option: -xscrollcommand
    #
    # X scroll command.

    delegate option -xscrollcommand to tab

    # Option: -yscrollcommand
    #
    # Y scroll command.

    delegate option -yscrollcommand to tab

    # Option: -cellmodel
    #
    # Creation-time only.  Sets the cellmodel to map to this
    # cmsheet.

    option -cellmodel \
        -readonly yes

    # Option: -solvecmd
    #
    # Command to call to recompute the cellmodel.  By default,
    # solves the entire cellmodel.

    option -solvecmd \
        -default ""

    # Option: -refreshcmd
    #
    # Command to call after the data is refreshed, e.g., to
    # color cells or change text.

    option -refreshcmd \
        -default ""

    # Option: -validatecmd 
    #
    # Command to call to validate an edited cell value.  The command
    # should be a prefix to which will be added the r,c index of the
    # edited cell and the value to validate.  The command should
    # return the value to give to the cellmodel if the value is valid, 
    # throw INVALID if the value is invalid.  This allows the -validatecmd
    # to translate the input in some way.
    #
    # By default, cmsheet(n) expects all inputs to be valid 
    # real numbers.

    option -validatecmd \
        -default ""

    # Option: -formatcmd
    #
    # Specifies the default command for formatting cell values.
    # The command should take one command, the value to format, and
    # return the formatted value.  This command can be overridden
    # by the -formatcmd option on the <mapcell> command and its peers.

    option -formatcmd \
        -default ""

    # Option: -state
    #
    # The widget may be editable (normal) or readonly (disabled)
    option -state \
        -default normal \
        -type {snit::enum -values {normal disabled}}


    #-------------------------------------------------------------------
    # Group: Instance Variables

    # Variable: info
    #
    # Array of scalars
    #
    #   mapped          - List of mapped cellmodel variables
    #   cellBeingEdited - r,c of the cell being edited.
    #   editValue       - value in the entry widget while the
    #                     cell is being edited.
    
    variable info -array {
        mapped          {}
        cellBeingEdited {}
        editValue       {}
    }

    # Variable: cell2rc
    #
    # Mapping from cell names to table indices

    variable cell2rc -array {}

    # Variable: rc2cell
    #
    # Mapping from r,c indices to cell names.
    
    variable rc2cell -array {}

    # Variable: maptags
    #
    # Array of map tags by cell name.

    variable maptags -array {}

    # Variable: formatcmd
    #
    # Array of -formatcmd values, by cell name
    
    variable formatcmd -array {}

    # Variable: data
    #
    # Array storing the data for the Tktable.

    variable data -array {}

    #-------------------------------------------------------------------
    # Group: Constructor

    # Constructor: constructor
    #
    # Creates a new instance given the creation 
    # <Options>.

    constructor {args} {
        # FIRST, create the widgets
        install tab using table $win.tab                      \
            -state              disabled                      \
            -font               TkTextFont                    \
            -maxheight          [winfo screenheight $win]     \
            -maxwidth           [winfo screenwidth  $win]     \
            -titlecols          1                             \
            -titlerows          1                             \
            -roworigin          -1                            \
            -colorigin          -1                            \
            -anchor             e                             \
            -background         $::marsgui::defaultBackground \
            -foreground         black                         \
            -highlightthickness 0                             \
            -multiline          0                             \
            -resizeborders      col                           \
            -bordercursor       sb_h_double_arrow             \
            -ipadx              2                             \
            -relief             ridge                         \
            -sparsearray        0                             \
            -variable           [myvar data]

        install entry using ttk::entry $win.tab.entry \
            -justify      right                       \
            -textvariable [myvar info(editValue)]

        # NEXT, configure the creation options
        $self configurelist $args

        # NEXT, set table tags.
        $tab tag configure title \
            -background $::marsgui::defaultBackground \
            -foreground black

        $tab tag configure empty \
            -borderwidth 0

        # NEXT, get the cell model options
        set cm $options(-cellmodel)

        # NEXT, pack the table
        pack $tab -fill both -expand yes

        # NEXT, event bindings
        bind $tab    <Key-Tab>     [mymethod TabToNext]
        bind $tab    <Key-Return>  [mymethod BeginEditing]
        bind $tab    <Button-1>    [mymethod BeginEditing @%x,%y]
        bind $entry  <Key-Escape>  [mymethod DoneEditing 0]
        bind $entry  <Key-Return>  [mymethod DoneEditing 1]
        bind $entry  <Key-Tab>     [mymethod DoneEditing 1 <Key-Tab>]
        bind $entry  <Key-Up>      [mymethod DoneEditing 1 <Key-Up>]
        bind $entry  <Key-Down>    [mymethod DoneEditing 1 <Key-Down>]
    }

    #-------------------------------------------------------------------
    # Group: Event Handlers

    # Method: TabToNext
    #
    # Tabs to the next editable cell

    method TabToNext {} {
        # FIRST, if the widget is disabled, return.
        if {$options(-state) eq "disabled"} {
            return
        }
        
        # NEXT, get the current cell; if none, return.
        set start [$tab curselection]
        
        if {$start eq ""} {
            return
        }

        # NEXT, find the next cell, working left-to-right and top
        # to bottom.
        set nr [$tab cget -rows]
        set nc [$tab cget -cols]

        lassign [split $start ,] r c
        set rc ""

        while {$rc ne $start} {
            if {$c < $nc - 1} {
                incr c
            } elseif {$r < $nr - 1} {
                incr r
                set c 0
            } else {
                set r 0
                set c 0
            }

            set rc $r,$c

            if {[info exists maptags($rc)] &&
                [$tab tag cget $maptags($rc) -state] ne "disabled"
            } {
                $tab selection clear all
                $tab selection set $rc
                $tab activate $rc
                
                # Break, so that we don't tab to another widget.
                return -code break
            }
        }

        return
    }

    # Method: BeginEditing 
    #
    # This is called when a user wishes to edit a cell.  It pops up
    # the cell entry with the cell's content.
    #
    # Syntax:
    #   BeginEditing _?index?_
    #
    #   index - If given, the index of the cell to edit.  Otherwise,
    #           the currently selected cell is edited.

    method BeginEditing {{index ""}} {
        # FIRST, if the widget or the cell is disabled, return.
        if {$options(-state) eq "disabled"} {
            return
        }
        
        if {$index ne ""} {
            set rc [$tab index $index]
        } else {
            set rc [$tab curselection]
        }

        if {![info exists maptags($rc)] ||
            [$tab tag cget $maptags($rc) -state] eq "disabled"
        } {
            return
        }

        $tab selection clear all
        $tab selection set $rc
        $tab activate $rc

        # NEXT, begin editing.
        set bbox [$tab bbox $rc]

        set info(editValue) $data($rc)
        set info(cellBeingEdited) $rc

        place $entry \
            -bordermode outside          \
            -x          [lindex $bbox 0] \
            -y          [lindex $bbox 1] \
            -width      [lindex $bbox 2] \
            -height     [lindex $bbox 3]

        $entry icursor end
        $entry selection range 0 end

        # Focus on the entry, wait for the focus take effect, and then
        # grab on the entry so that they have to ESC or RETURN before
        # doing anything else.
        focus $entry
        update idletasks
        grab set $entry

        return -code break
    }

    # Method: DoneEditing
    #
    #
    # Handles the end of the editing transaction.  The value is validated
    # and saved (or not), and the entry is hidden.  The event that ended
    # the transaction can be passed back to the Tktable.
    #
    # Syntax:
    #   DoneEditing _keeper ?nextEvent?_
    #
    #   keeper    - 1 if the new value should be saved, and 0 otherwise.
    #   nextEvent - Event to pass along to Tktable

    method DoneEditing {keeper {nextEvent ""}} {
        if {$keeper} {
            set valid 1

            if {$options(-validatecmd) ne ""} {
                if {[catch {
                    {*}$options(-validatecmd) \
                        $info(cellBeingEdited) $info(editValue)
                } result eopts]} {
                    if {[dict get $eopts -errorcode] ne "INVALID"} {
                        return {*}$eopts $result
                    }

                    set valid 0
                } else {
                    set valid 1
                }
            } else {
                if {![string is double -strict $info(editValue)]} {
                    set valid 0
                }

                set result $info(editValue)
            }
            
            if {!$valid} {
                # Not valid; ring bell, and return.  We stay in the
                # entry widget.
                bell
                return -code break
            }

            # Save the value into the cellmodel
            set cellname $rc2cell($info(cellBeingEdited))
            $cm set [list $cellname $result]

            # Display it
            set data($info(cellBeingEdited)) [$self Format $cellname]

            # Recompute
            $self Recompute
        }

        grab release $entry
        place forget $entry

        focus $tab
        $tab activate $info(cellBeingEdited)
        $tab selection set active

        if {$nextEvent ne ""} {
            event generate $tab $nextEvent
            after idle [list catch [list event generate $tab <Key-Return>]]
        }

        return -code break
    }


    # Method: Recompute
    #
    # Recomputes the cell model, and refreshes the displayed data.
    # If the user has specified a -solvecmd, that's used instead of 
    # calling the cellmodel's solve routine.

    method Recompute {} {
        if {$options(-solvecmd) ne ""} {
            uplevel \#0 $options(-solvecmd)
        } else {
            $cm solve
        }

        $self refresh
    }

    #-------------------------------------------------------------------
    # Mapping Routines

    # Method: textcell
    #
    # Puts boilerplate text into the specified cell with the specified
    # tag and tag options.
    #
    # Syntax:
    #   textcell _rc text ?tag ?options...??_
    #
    #   rc      -  A row,column index
    #   text    -  Text to put there.
    #   tag     -  Tag name
    #   options -  Tag options.
    
    method textcell {rc text {tag ""} args} {
        # FIRST, it's an error if the cell is mapped.
        require {![info exists rc2cell($rc)]} \
            "Cell is mapped: \"$rc\""

        # NEXT, save the text.
        set data($rc) $text

        # NEXT, if the tag needs to be configured, do so.
        if {$tag ne ""} {
            if {[llength $args] > 0} {
                $tab tag configure $tag {*}$args
            }
            
            # NEXT, tag the table cell
            $tab tag cell $tag $rc
        }
    }

    # Method: textrow
    #
    # Puts boilerplate text into the specified cells with the specified
    # tag and tag options.  Each string from the _textlist_ goes into
    # consecutive cells along the row from rc.
    #
    # Syntax:
    #   textrow _rc textlist ?tag ?options...??_
    #
    #   rc       -  A row,column index
    #   textlist -  List of text strings
    #   tag      -  Tag name
    #   options  -  Tag options.
    
    method textrow {rc textlist {tag ""} args} {
        lassign [split $rc ,] r c

        foreach text $textlist {
            $self textcell $r,$c $text $tag {*}$args

            incr c
        }
    }

    # Method: textrow
    #
    # Puts boilerplate text into the specified cells with the specified
    # tag and tag options.  Each string from the _textlist_ goes into
    # consecutive cells along the column from rc.
    #
    # Syntax:
    #   textcol _rc textlist ?tag ?options...??_
    #
    #   rc       -  A row,column index
    #   textlist -  List of text strings
    #   tag      -  Tag name
    #   options  -  Tag options.
    
    method textcol {rc textlist {tag ""} args} {
        lassign [split $rc ,] r c

        foreach text $textlist {
            $self textcell $r,$c $text $tag {*}$args

            incr r
        }
    }

    # Method: mapcell
    #
    # Maps a cellmodel cell to a Tktable cell, and assigns the tag.
    # If options are given, the tag is configured.  If the tag is "%cell",
    # the cell is tagged with its own name.  Any previously mapped
    # cellmodel cell is unmapped.
    #
    # Syntax:
    #   mapcell _rc cellname tag ?options...?_
    #
    #   rc       - A row,column index
    #   cellname - cellmodel cell name
    #   tag      - Tag name or "%cell"
    #   options  - Tag options
    #
    # Options:
    #   The options are the standard Tktable tag options, along with
    #   the following:
    #
    #   -formatcmd cmd - Format command prefix

    method mapcell {rc cellname tag args} {
        # FIRST, map the cell, cleaning up any previous cell
        if {[info exists rc2cell($rc)]} {
            set oldcell $rc2cell($rc)
            unset -nocomplain cell2rc($oldcell)
            ldelete info(mapped) $oldcell
        }

        set rc2cell($rc) $cellname
        set cell2rc($cellname) $rc
        lappend info(mapped) $cellname

        # NEXT, configure the tag.  If it is %cell, define a unique
        # tag for this cell.
        if {$tag eq "%cell"} {
            set tag $cellname
        }

        # Configure the tag if there are options.
        set opts(-formatcmd) [from args -formatcmd ""]

        # NEXT, if the cell is a formula, make it disabled;
        # otherwise, make it white.

        if {[$cm cellinfo ctype $cellname] eq "constant"} {
            if {![$tab tag exists $tag]} {
                $tab tag configure $tag -background white
            }
        } else {
            $tab tag configure $tag -state disabled
        }

        $tab tag configure $tag {*}$args

        # Tag the cell
        set formatcmd($cellname) $opts(-formatcmd)
        set maptags($rc) $tag
        $tab tag cell $tag $rc

        # NEXT, grab its value
        set data($rc) [$self Format $cellname]
    }

    # Method: map
    #
    # Maps a set of cellmodel cells to a rectangle of Tktable cells, and 
    # assigns the tag. If options are given, the tag is configured.  
    # If the tag is "%cell", the cells are tagged with their own names.
    #
    # The _indx_ and _jndx_ name indices in the cell model; the 
    # individual index values are substituted into the pattern to get
    # the cell names.  
    #
    # Syntax:
    #   map _rc indx jndx pattern tag ?options...?_
    #
    #   rc       - A row,column index
    #   indx     - cellmodel index name for row indices
    #   jndx     - cellmodel index name for column indices
    #   pattern  - A pattern producing the set of cell names, with
    #              "%" substitutions for the indices.
    #   tag      - Tag name or "%cell"
    #   options  - Tag options
    #
    # Example:
    #   If the index names are "i" and "j", then the following call
    #   will map CELL.i.j for each of the i's and j's.  The i's will
    #   vary down the columns and the j's will vary across the rows.
    #
    #   > map 0,0 i j CELL.%i.%j mytag ...

    method map {rc indx jndx pattern tag args} {
        # FIRST, map the cells
        lassign [split $rc ,] r0 c0

        set r $r0
        foreach i [$cm index $indx] {
            set c $c0

            foreach j [$cm index $jndx] {
                set cellname \
                    [string map [list %$indx $i %$jndx $j] $pattern]

                $self mapcell $r,$c $cellname $tag {*}$args
                
                incr c
            }

            incr r
        }
    }

    # Method: maprow
    #
    # Maps a set of cellmodel cells onto a row of Tktable cells, and 
    # assigns the tag. If options are given, the tag is configured.  
    # If the tag is "%cell", the cells are tagged with their own names.
    #
    # The _jndx_ names an index in the cell model; the 
    # individual index values are substituted into the pattern to get
    # the cell names.  
    #
    # Syntax:
    #   maprow _rc jndx pattern tag ?options...?_
    #
    #   rc       - A row,column index
    #   jndx     - cellmodel index name for column indices
    #   pattern  - A pattern producing the set of cell names, with
    #              "%" substitutions for the _jndx_.
    #   tag      - Tag name or "%cell"
    #   options  - Tag options
    #
    # Example:
    #   If the index name is "j", then the following call
    #   will map CELL.j for each of the j's.  The j's will vary 
    #   across the row from _rc_.
    #
    #   > map 0,0 j CELL..%j mytag ...

    method maprow {rc jndx pattern tag args} {
        # FIRST, map the cells
        lassign [split $rc ,] r0 c0

        set c $c0
        foreach j [$cm index $jndx] {
            set cellname \
                    [string map [list %$jndx $j] $pattern]

            $self mapcell $r0,$c $cellname $tag {*}$args
            incr c
        }
    }

    # Method: mapcol
    #
    # Maps a set of cellmodel cells onto a column of Tktable cells, and 
    # assigns the tag. If options are given, the tag is configured.  
    # If the tag is "%cell", the cells are tagged with their own names.
    #
    # The _indx_ names an index in the cell model; the 
    # individual index values are substituted into the pattern to get
    # the cell names.  
    #
    # Syntax:
    #   mapcol _rc indx pattern tag ?options...?_
    #
    #   rc       - A row,column index
    #   indx     - cellmodel index name for row indices
    #   pattern  - A pattern producing the set of cell names, with
    #              "%" substitutions for the _indx_.
    #   tag      - Tag name or "%cell"
    #   options  - Tag options
    #
    # Example:
    #   If the index name is "i", then the following call
    #   will map CELL.i for each of the i's.  The i's will vary 
    #   down the column _rc_.
    #
    #   > map 0,0 i CELL..%i mytag ...

    method mapcol {rc indx pattern tag args} {
        # FIRST, map the cells
        lassign [split $rc ,] r0 c0

        set r $r0
        foreach i [$cm index $indx] {
            set cellname \
                    [string map [list %$indx $i] $pattern]

            $self mapcell $r,$c0 $cellname $tag {*}$args
            incr r
        }
    }

    # Method: empty
    #
    # Declares that the named range of cells is "empty" and unused.
    #
    # Syntax:
    #   empty _rc0 rc1_
    #
    #   rc0 - r,c index of upper left corner of range
    #   rc1 - r,c index of lower right corner of range.

    method empty {rc0 rc1} {
        lassign [split [$tab index $rc0] ,] r0 c0
        lassign [split [$tab index $rc1] ,] r1 c1
        
        for {set r $r0} {$r <= $r1} {incr r} {
            for {set c $c0} {$c <= $c1} {incr c} {
                $tab tag cell empty $r,$c
            }
        }
    }

    #-------------------------------------------------------------------
    # Group: Other Public Methods
    #
    # The *see*, *tag*, *width*, *window*, *xview*, and *yview* 
    # methods are delegated to the underlying Tktable.

    delegate method tag    to tab
    delegate method width  to tab
    delegate method window to tab
    delegate method xview  to tab
    delegate method yview  to tab

    # Method: index
    #
    # Returns the r,c index corresponding to the index specification,
    # which can be any Tktable index, or a mapped cell name.
    #
    # Syntax:
    #   index _index_
    #
    #   index - A Tktable index, or a cell name.
    
    method index {index} {
        if {[info exists cell2rc($index)]} {
            return $cell2rc($index)
        } else {
            return [$tab index $index]
        }
    }

    # Method: see
    #
    # Scrolls the table so that the named cell or index is visible.
    #
    # Syntax:
    #   see _index_
    #
    #   index - A Tktable index, or a cell name.
   
    method see {index} {
        $tab see [$self index $index]
    }

    # Method: cell
    #
    # Given a valid Tktable index, returns the corresponding cellmodel(n)
    # cell name, or "" if none.
    #
    # Syntax:
    #   cell _index_
    #
    #   index - A valid Tktable index string.

    method cell {index} {
        set rc [$tab index $index]

        if {[info exists rc2cell($rc)]} {
            return $rc2cell($rc)
        } else {
            return ""
        }
    }

    # Method: refresh
    #
    # Updates the table with the current cell values, calling
    # the -refreshcmd so the client can additional details or colors.

    method refresh {} {
        # FIRST, set the cell values
        foreach cell $info(mapped) {
            set rc $cell2rc($cell)

            set data($rc) [$self Format $cell]
        }

        if {$options(-refreshcmd) ne ""} {
            uplevel \#0 $options(-refreshcmd)
        }
    }

    #-------------------------------------------------------------------
    # Utility Methods

    # Method: Format
    #
    # Given a cell name, returns the formatted value of the cell.
    #
    # Syntax:
    #   Format _cellname_
    
    method Format {cellname} {
        if {$formatcmd($cellname) ne ""} {
            return [{*}$formatcmd($cellname) [$cm value $cellname]]
        } elseif {$options(-formatcmd) ne ""} {
            return [{*}$options(-formatcmd) [$cm value $cellname]]
        } else {
            return [$cm value $cellname]
        }
    }
}
