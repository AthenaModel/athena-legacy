#-----------------------------------------------------------------------
# TITLE:
#    nbhoodbrowser.tcl
#
# AUTHORS:
#    Dave Hanks,
#    Will Duquette
#
# DESCRIPTION:
#    nbhoodbrowser(sim) package: Neighborhood browser.
#
#    This widget displays a formatted list of neighborhood records.
#    Entries in the list are managed by the tablebrowser(n).  
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

#-----------------------------------------------------------------------
# Widget Definition

snit::widget nbhoodbrowser {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Create the button icons
        namespace eval ${type}::icon { }


        mkicon ${type}::icon::lower {
            ......................
            ......................
            ......................
            ......................
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ....XX....XX....XX....
            .....XX...XX...XX.....
            ......XX..XX..XX......
            .......XX.XX.XX.......
            ........XXXXXX........
            .........XXXX.........
            ..........XX..........
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }

        mkicon ${type}::icon::raise {
            ......................
            ......................
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ..........XX..........
            .........XXXX.........
            ........XXXXXX........
            .......XX.XX.XX.......
            ......XX..XX..XX......
            .....XX...XX...XX.....
            ....XX....XX....XX....
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ......................
            ......................
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }
    }

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    # Methods delegated to the tablebrowser
    delegate method * to tb

    #-------------------------------------------------------------------
    # Components

    component tb          ;# tablebrowser(n) used to browse nbhoods
    component bar         ;# Tool bar
    component editbtn     ;# The "Edit Neighborhood" button
    component raisebtn    ;# The "Bring to Front" button
    component lowerbtn    ;# The "Send to Back" button
    component deletebtn   ;# The "Delete Neighborhood" button

    #--------------------------------------------------------------------
    # Instance Variables

    # TBD

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options.
        $self configurelist $args

        # NEXT, create the table browser
        install tb using tablebrowser $win.tb   \
            -db          ::rdb                  \
            -table       "gui_nbhoods"          \
            -keycol      "id"                   \
            -keycolnum   0                      \
            -width       100                    \
            -displaycmd  [mymethod DisplayData]

        # NEXT, create the toolbar
        install bar using frame $tb.toolbar \
            -relief flat

        install editbtn using button $bar.edit   \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Neighborhood"

        install raisebtn using button $bar.raise  \
            -image      ${type}::icon::raise      \
            -relief     flat                      \
            -overrelief raised                    \
            -state      disabled                  \
            -command    [mymethod RaiseSelected]

        DynamicHelp::add $raisebtn -text "Bring Neighborhood to Front"

        install lowerbtn using button $bar.lower  \
            -image      ${type}::icon::lower      \
            -relief     flat                      \
            -overrelief raised                    \
            -state      disabled                  \
            -command    [mymethod LowerSelected]

        DynamicHelp::add $lowerbtn -text "Send Neighborhood to Back"

        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22        \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected Neighborhood"
        
        pack $editbtn   -side left
        pack $raisebtn  -side left
        pack $lowerbtn  -side left
        pack $deletebtn -side right

        # NEXT, hand the toolbar to the browser.
        $tb toolbar $tb.toolbar

        # NEXT, create the columns and labels.
        $tb insertcolumn end 0 {ID}
        $tb insertcolumn end 0 {Neighborhood}
        $tb insertcolumn end 0 {Urbanization}
        $tb insertcolumn end 0 {StkOrd}
        $tb columnconfigure end -sortmode integer
        $tb insertcolumn end 0 {ObscuredBy}
        $tb insertcolumn end 0 {RefPoint}
        $tb insertcolumn end 0 {Polygon}

        # NEXT, the last column fills extra space
        $tb columnconfigure end -stretchable yes

        # NEXT, pack the tablebrowser and let it expand
        pack $tb -expand yes -fill both

        # NEXT, prepare to get tablelist events
        bind $tb <<TablebrowserSelect>> [mymethod SelectionChanged]

        # NEXT, prepare to update on data change
        notifier bind ::sim      <Reconfigure> $self [mymethod Reconfigure]
        notifier bind ::nbhood   <Entity>      $self $self

        # NEXT, reload on creation
        $self reload
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    # select ids
    #
    # ids    A list of neighborhood ids
    #
    # Programmatically selects the neighborhoods in the browser.

    method select {ids} {
        # FIRST, select them in the table browser.
        $tb select $ids

        # NEXT, handle the new selection (tablebrowser only reports
        # user changes, not programmatic changes).
        $self SelectionChanged
    }

    # create id
    #
    # id    The ID of the created neighborhood
    #
    # A new neighborhood has been created.  We need to update any 
    # neighborhoods obscured by it.  For now, just reload the whole
    # shebang.
    
    method create {id} {
        $tb reload
    }
    
    #-------------------------------------------------------------------
    # Private Methods

    # Reconfigure
    #
    # Called when the simulation is reconfigured.  Updates the 
    # tablebrowser, etc.

    method Reconfigure {} {
        # FIRST, update the table browser
        $tb reload

        # NEXT, handle selection changes
        $self SelectionChanged
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected neighborhood.

    method EditSelected {} {
        set ids [$tb curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter NBHOOD:UPDATE n $id
        } else {
            order enter NBHOOD:UPDATE:MULTI ids $ids
        }
    }

    # RaiseSelected
    #
    # Called when the user wants to raise the selected neighborhood.

    method RaiseSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$tb curselection] 0]

        # NEXT, bring it to the front.
        order send gui NBHOOD:RAISE [list n $id]
    }

    # LowerSelected
    #
    # Called when the user wants to lower the selected neighborhood.

    method LowerSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$tb curselection] 0]

        # NEXT, bring it to the front.
        order send gui NBHOOD:LOWER [list n $id]
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected neighborhood.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$tb curselection] 0]

        # NEXT, Send the order.
        order send gui NBHOOD:DELETE n $id
    }

    # delete n
    #
    # n     Deleted neighborhood.
    #
    # When a neighborhood is deleted, we need to update the toolbar
    # state, as it's likely that there is no longer a selection.

    method delete {n} {
        # FIRST, update the tablebrowser
        $tb delete $n

        # NEXT, update the state
        $self SelectionChanged
    }

    # stack
    #
    # Reloads all data items when the neighborhood stacking order
    # changes.

    method stack {} {
        $self reload
    }

    # DisplayData dict
    # 
    # dict   the data dictionary that contains the nbhood information
    #
    # This method converts the nbhood data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            $tb setdata $n [list \
                                $n                             \
                                $longname                      \
                                $urbanization                  \
                                [format "%3d" $stacking_order] \
                                $obscured_by                   \
                                $refpoint                      \
                                $polygon                       ]
                                
        }
    }

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, get the number of selected nbhoods
        set num [llength [$tb curselection]]

        # NEXT, update the toolbar buttons
        if {$num > 0} {
            $editbtn    configure -state normal
        } else {
            $editbtn    configure -state disabled
        }

        if {$num == 1} {
            $raisebtn   configure -state normal
            $lowerbtn   configure -state normal
            $deletebtn  configure -state normal
        } else {
            $raisebtn   configure -state disabled
            $lowerbtn   configure -state disabled
            $deletebtn  configure -state disabled
        }

        # NEXT, notify the app of the selection.
        if {$num == 1} {
            set n [lindex [$tb curselection] 0]

            notifier send ::app <ObjectSelect> \
                [list nbhood $n]
        }
    }
}

