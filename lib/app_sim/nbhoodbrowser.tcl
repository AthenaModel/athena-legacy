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

        mkicon ${type}::icon::edit {
            ......................
            ......................
            ...............XXX....
            ..............X...X...
            .............X.....X..
            ............X.X....X..
            ...........X...X...X..
            ..........X...X.X.X...
            .........X...X...X....
            ........X...X...X.....
            .......X...X...X......
            ......X...X...X.......
            .....X...X...X........
            ....X.X.X...X.........
            ....X..X...X..........
            ...X....X.X...........
            ...X.....X............
            ...XX..XX.............
            ..XXXXX...............
            ..XX..................
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

    # Options delegated to the tablebrowser
    delegate method * to tb

    #-------------------------------------------------------------------
    # Components

    component tb          ;# tablebrowser(n) used to browse nbhoods
    component bar         ;# Tool bar
    component editbtn     ;# The "Edit Neighborhood" button

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
            -table       "nbhoods"              \
            -keycol      "n"                    \
            -keycolnum   0                      \
            -width       100                    \
            -displaycmd  [mymethod DisplayData]

        # NEXT, create the toolbar
        install bar using frame $tb.toolbar \
            -relief flat

        install editbtn using button $bar.edit  \
            -image      ${type}::icon::edit     \
            -relief     flat                    \
            -overrelief raised                  \
            -state      disabled                \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Neighborhood"
        
        pack $editbtn -side left

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

        # NEXT, set the default sort column and direction
        $tb sortbycolumn 0 -increasing

        # NEXT, pack the tablebrowser and let it expand
        pack $tb -expand yes -fill both

        # NEXT, prepare to get tablelist events
        bind $tb <<TablebrowserSelect>> [mymethod UpdateToolbarState]

        # NEXT, prepare to update on data change
        notifier bind ::scenario <Reconfigure> $self [mymethod Reconfigure]
        notifier bind ::nbhood   <Entity>      $self $self

        # NEXT, reload on creation
        $self reload
    }

    destructor {
        notifier forget $self
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

        # NEXT, update the tools
        $self UpdateToolbarState
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected neighborhood.

    method EditSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$tb curselection] 0]

        # NEXT, Pop up the dialog, and select this nbhood
        ordergui enter NBHOOD:UPDATE
        ordergui parm set n $id
        
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
        $self UpdateToolbarState
    }

    # raise n
    #
    # n     Raised neighborhood.  Ignore
    #
    # Reloads all data items when a neighborhood is raised, since the
    # stacking order changes for all of them.

    method raise {n} {
        $self reload
    }

    # lower n
    #
    # n     Lowered neighborhood.  Ignore
    #
    # Reloads all data items when a neighborhood is lowered, since the
    # stacking order changes for all of them.

    method lower {n} {
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
                                [map m2ref {*}$refpoint]       \
                                [map m2ref {*}$polygon]        ]
                                
        }
    }

    # UpdateToolbarState
    #
    # Enables/disables toolbar controls based on the displayed data.

    method UpdateToolbarState {} {
        # FIRST, get the number of selected nbhoods
        set num [llength [$tb curselection]]

        # NEXT, update the toolbar buttons
        if {$num == 1} {
            $editbtn configure -state normal
        } else {
            $editbtn configure -state disabled
        }
    }
}

