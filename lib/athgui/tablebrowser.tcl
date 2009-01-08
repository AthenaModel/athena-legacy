#-----------------------------------------------------------------------
# TITLE:
#    tablebrowser.tcl
#
# AUTHORS:
#    Dave Hanks
#    Will Duquette
#
# DESCRIPTION:
#    athgui(n) package: Generic table browser.
#
#    This widget displays a formatted list of data from an SQLite3 
#    database table or view.  Entries in the list can be filtered 
#    and searched. Also, a callback can be supplied for double click events.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::athgui:: {
    namespace export tablebrowser
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::athgui::tablebrowser {

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Add defaults to the option database
        option add *Tablebrowser.borderWidth      1
        option add *Tablebrowser.relief           flat
        option add *Tablebrowser.background       white
        option add *Tablebrowser.Foreground       black
        option add *Tablebrowser.font             codefont
        option add *Tablebrowser.width            80
        option add *Tablebrowser.height           24
        option add *Tablebrowser.hullbackground   $::marsgui::defaultBackground
    }

    #-------------------------------------------------------------------
    # Components

    component tableList   ;# The tablelist widget displaying the data.
    component bar         ;# The bar at the top of the window  
    component toolbar     ;# The toolbar for application-specific widgets.
    component db          ;# sqldatabase(n) component
    component filter      ;# filter(n) component used to filtefilterr entries.

    #-------------------------------------------------------------------
    # Options
    
    # -keycol col
    #
    # The name of the column in the db that contains the unique 
    # identifier for a row
    option -keycol

    # -keycolnum num
    #
    # The number of the column in the tablelist that contains the keycol;
    # zero is the leftmost column
    option -keycolnum

    # -displaycmd cmd
    #
    # Callback made by table browser users to return the data in the 
    # form that the tablelist displays
    option -displaycmd

    # -db db
    #
    # The sqldatabase(n) object
    option -db -readonly yes

    # -table name
    #
    # The name of the table in the db that this browser displays
    option -table

    # Options delegated to the hull
    delegate option -borderwidth    to hull
    delegate option -relief         to hull
    delegate option -hullbackground to hull as -background
    delegate option -width          to tableList

    # Methods delegated to the tablelist
    delegate method columnconfigure to tableList
    delegate method sortbycolumn to tableList

    #-------------------------------------------------------------------
    # Instance Variables

    variable lastSortCol   0   ;# Last column on which a sort was requested

    # Remember sort direction for each column. This array gets filled in as
    # columns are requested
    variable lastSortDir   -array {}         

    # A map between the entries in the key column and the row number
    variable keyMap        -array {}

    # Array used to manage the results of a search. The members of the array
    # are as follows:
    #
    #   target       the search target, i.e. what is being searched for
    #   targetType   the type of search (exact, incremental, regexp, wildcard)
    #   targetRegexp the regular expression of the target
    #   count        the number of rows that have a target match
    #   instance     the row currently highlighted [0,(count-1)]
    #   rownum       the number of the highlighted row in the tablelist
    #   lines        the list of row numbers that have a target match
    variable found -array {
        target       ""
        targetType   ""
        targetRegexp ""
        count        0
        instance     -1
        rownum       -1
        lines        {}
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Create the components
        $hull configure \
            -borderwidth 1 

        # Title Bar
        install bar using frame $win.bar \
                     -relief flat

        # The tablelist widget listing the rows of data.
        install tableList using tablelist::tablelist $win.table \
            -height           24                        \
            -state            normal                    \
            -labelbackground  $::marsgui::defaultBackground \
            -arrowstyle       sunken8x7                 \
            -yscrollcommand   [list $win.yview set]     \
            -xscrollcommand   [list $win.xview set]     \
            -movablecolumns   no                        \
            -background       white                     \
            -exportselection  false                     \
            -selectmode       extended                  \
            -stripebackground #CCFFBB                   \
            -labelborderwidth 1                         \
            -activestyle      none                      \
            -labelcommand     [mymethod SortByColumn]   \
            -font             codefont                  \
            -selectbackground black                     \
            -selectforeground white                   

        # NEXT, configure options
        $self configurelist $args

        # NEXT, fill in the options
        set db      $options(-db)

        # Install the filter controls.
        install filter using ::marsgui::filter $bar.filter  \
            -width     15   \
            -filtercmd [mymethod FilterData] \
        
        # Scrollbars
        scrollbar $win.yview   \
            -orient  vertical  \
            -command [list $tableList yview]

        scrollbar $win.xview   \
            -orient  horizontal  \
            -command [list $tableList xview]


        # NEXT, layout the components.
        pack $filter    -side right -fill y
        
        grid $bar -row 0 -column 0 -columnspan 2 -sticky ew
        grid $tableList -row 1 -column 0 -sticky nsew
        grid $win.yview -row 1 -column 1 -sticky nsew
        grid $win.xview -row 2 -column 0 -sticky nsew

        grid columnconfigure $win 0 -weight 1
        grid rowconfigure    $win 1 -weight 1
    
        # NEXT, force focus when the table list is clicked
        bind [$tableList bodytag] <1> [focus $tableList]

        # NEXT, binding for copying the contents
        bind [$tableList bodytag] <<Copy>> [mymethod TablelistCopy]

        bind $tableList <<TablelistSelect>> \
            [list event generate $win <<TablebrowserSelect>>]
    }
    
    #-------------------------------------------------------------------
    # Public Methods

    # toolbar tbar
    #
    # tbar  the frame widget that contains the toolbar widgets to be displayed
    #
    # This method packs the supplied toolbar frame into the f
    method toolbar {tbar} {
        # FIRST, make sure it doesn't already exist
        assert {[winfo exists $toolbar] == 0}

        # NEXT, set it as the toolbar and pack it
        set toolbar $tbar
        pack $toolbar -in $bar -side left -fill x -expand yes
    }

    # curselection
    #
    # Returns a list of the IDs of the rows that are selected, or
    # the empty string if none.

    method curselection {} {
        set result [list]

        set keydata [$tableList getcolumns $options(-keycolnum)]

        foreach row [$tableList curselection] {
            lappend result [lindex $keydata $row]
        }

        return $result
    }

    # create id
    #
    # id     The id that corresponds to -keycol
    #
    # The update method handles the creation of new rows
    #

    method create {id} {
        # FIRST, update the table browser with the new data
        $self update $id
    }

    
    # update id
    #
    # id   The id that corresponds to -keycol
    #
    # Extract the row with the supplied id from the db. The client tells
    # the table browser how to display the data, then the data is sorted.
    # 

    method update {id} {
        set dict {}

        # FIRST, get the row from the table
        $db eval "
            SELECT * from $options(-table)
            WHERE $options(-keycol) == \$id
        " row {
            unset -nocomplain row(*)
            set dict [array get row]
        } 

        # NEXT, callback to client for display
        callwith $options(-displaycmd) $dict

        # NEXT, sort the rows, the update may have changed the column we
        # are sorting on
        $self SortData 
    }

    # delete
    #
    # id   The id of the row that corresponds to -keycol
    #
    # This method deletes the row from the table that has the column
    # that matches id

    method delete {id} {
        # FIRST, look for a match on id
        if {[info exists keyMap($id)]} {
            $tableList delete $keyMap($id) $keyMap($id)
        }

        # NEXT, clear the array
        array unset keyMap

        # NEXT, rebuild the map between row id and row number
        set keydata [$tableList getcolumns $options(-keycolnum)]
        set rownum 0

        foreach id $keydata {
            set keyMap($id) $rownum
            incr rownum
        }
    }

    # clear
    #
    # Clears the contents of the tablelist widget and resets the
    # row counter
    
    method clear {} {
        # FIRST, clear out the key map
        array unset keyMap

        # NEXT, clear the display.
        $tableList delete 0 end
    }        

    # insertcolumn
    # 
    # index   the location that the insertion should take place
    # width   the width of the column 
    # name    the name to appear at the top of the column
    #
    # Sets the default sort direction for the column and then inserts
    # the column to the right of any existing columns. NB: The last sort
    # dir must be set first here because the column count returned by the
    # tablelist will be the index into the array for the column about to
    # be inserted.
 
    method insertcolumn {index width name} {
        # FIRST, set the default sort direction
        set lastSortDir([$tableList columncount]) "-increasing"

        # NEXT, call the tablelist widget to add the column
        $tableList insertcolumns $index $width $name
    }

    # select ids
    #
    # ids    A list of ids as found in each row's key column
    #
    # Selects the rows with the associated IDs.  Unknown IDs
    # are ignored.

    method select {ids} {
        $tableList selection clear 0 end
        
        set rows [list]

        foreach id $ids {
            if {[info exists keyMap($id)]} {
                lappend rows $keyMap($id)
            }
        }

        $tableList selection set $rows
    }

    # setcolor id color
    #
    # id    The id for the row found in the key column
    # color The foreground color that the row should take
    # 
    # This method translates row id to row number and sets the
    # foreground color of that row to the requested color

    method setcolor {id color} {
        $tableList rowconfigure $keyMap($id) -foreground $color
    }

    # setbackground id color
    #
    # id    The id for the row found in the key column
    # color The background color that the row should take
    # 
    # This method translates row id to row number and sets the
    # background color of that row to the requested color

    method setbackground {id color} {
        $tableList rowconfigure $keyMap($id) -background $color
    }

    # setfont id font
    #
    # id    The id for the row found in the key column    
    # font  The font that the row should take
    #
    # This method translates row id to row number and sets the
    # font of that row to the requested font

    method setfont {id font} {
        $tableList rowconfigure $keyMap($id) -font $font
    }

    # setdata id data
    #
    # Adds a row of data to the tablelist widget and gives it its
    # default appearance. By default it is added to the end of the
    # tablelist. This call is made by clients of the tablebrowser to
    # get thier data into the table.

    method setdata {id data} {
        # NEXT, if the row exists replace the data and return
        if {[info exists keyMap($id)]} {
            $tableList rowconfigure $keyMap($id) -text $data
            return
        }

        # NEXT, insert the data
        $tableList insert end $data

        # NEXT, determine whether it should be filtered
        if {[$filter check $data]} {
            $tableList rowconfigure end -hide false
        } else {
            $tableList rowconfigure end -hide true
        }

        # NEXT, set the default location of this row in the key map
        set keyMap($id) end
    }

    # reload
    #
    # This method clears the table browser and reloads all the data
    # from the table that it is meant to show

    method reload {} {
        # FIRST, save the selection.
        set ids [$self curselection]

        # NEXT, clear the table
        $self clear

        # NEXT, request all rows from the table
        $db eval "
            SELECT * from $options(-table)
        " row {
            unset -nocomplain row(*)
            set dict [array get row]
            callwith $options(-displaycmd) $dict
        }
     
        # NEXT, sort the contents
        $self SortData

        # NEXT, select the same rows
        $self select $ids
    } 

    # getselection
    #
    # This method retrieves and returns the data on the currently selected
    # row. If no row is selected it returns an empty string
 
    method getselection {} {
        # FIRST, set the currently selected row
        set rows [$tableList curselection]

        # NEXT, if the row is valid, get the data and return it
        if {$rows ne ""} {
            if {[llength $rows] == 1} {
                return [$tableList get $rows $rows]
            } else {
                return [$tableList get $rows]
            }
        }

        # NEXT, row is not valid, return empty string
        return ""
    }

    # takefocus
    #
    # This method puts focus on the tablelist widget that actually is
    # displaying the data. This causes keyboard navigation to work.

    method takefocus {} {
        focus $tableList
    }

    #-------------------------------------------------------------------
    # Private Methods

    # TablelistCopy
    #
    # This method takes the currently selected text from the table browser
    # and appends it to the system clipboard after clearing it first.
    #

    method TablelistCopy {} {
        # FIRST, get currently selected rows
        set rows [$tableList curselection]

        # NEXT, if there is a selection clear the clipboard
        if {[llength $rows] > 0} {
            clipboard clear
            # NEXT, append each row with a new line so it gets pasted nicely
            foreach row $rows {
                clipboard append "[$tableList get $row]\n"
            }
        }
    }

    # SortByColumn wdgt col
    #
    # wdgt      the tablelist widget 
    # col       the column inde
    #
    # Sets the last sort direction for the specified column so that when
    # the event list is received it is sorted on the correct column in 
    # the correct direction

    method SortByColumn {wdgt col} {
        # FIRST, set the last column sorted to this one
        set lastSortCol $col
        
        # NEXT, determine what the new direction should be
        if {$lastSortDir($lastSortCol) eq "-none"} {
            # Never been selected, increasing is default 
            set lastSortDir($lastSortCol) "-increasing"

        } elseif {$lastSortDir($lastSortCol) eq "-increasing"} {
            # Switch from increasing to decreasing
            set lastSortDir($lastSortCol) "-decreasing"

        } elseif {$lastSortDir($lastSortCol) eq "-decreasing"} {
            # Switch from decreasing to increasing
            set lastSortDir($lastSortCol) "-increasing"

        }
        
        $self SortData
    }

    # SortData
    #
    # Sorts the contents of the tablelist widget by the last requested
    # sort command
  
    method SortData {} {
        # FIRST, pass the command through to the tablelist widget
        if {$lastSortDir($lastSortCol) ne "-none"} {
            $tableList sortbycolumn $lastSortCol $lastSortDir($lastSortCol)
        }

        array unset keyMap
        # NEXT, rebuild the map between row id and row number
        set keydata [$tableList getcolumns $options(-keycolnum)]
        set rownum 0

        foreach id $keydata {
            set keyMap($id) $rownum
            incr rownum
        }
    }

    # FilterData
    #
    # Filters the data based upon the specified target.
    
    method FilterData {} {
        # FIRST, initialize row and all data
        set rowidx 0
        set datasets [$tableList get 0 end]

        # NEXT, go through each dataset and see if it should be filtered
        foreach data $datasets {
            if {[$filter check $data]} {
                $tableList rowconfigure $rowidx -hide false
            } else {
                $tableList rowconfigure $rowidx -hide true
            }
            incr rowidx
        } 

        # NEXT, clear all selections 
        $tableList selection clear 0 end
    }

    # ResetRows
    #
    # Removes all highlighting from the tablelist and resets the list
    # of found lines

    method ResetRows {} {
        # FIRST, reset the background of all cells
        set rowcount [$tableList size]

        # NEXT, reload to restore colors
        $self reload

        # NEXT, clear the list of rows that had hits
        set found(lines) [list]
    }
}



