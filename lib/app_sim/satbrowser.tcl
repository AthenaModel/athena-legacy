#-----------------------------------------------------------------------
# TITLE:
#    satbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    satbrowser(sim) package: Nbhood Group browser.
#
#    This widget displays a formatted list of nbhood group records.
#    Entries in the list are managed by the tablebrowser(n).  
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

#-----------------------------------------------------------------------
# Widget Definition

snit::widget satbrowser {
    #-------------------------------------------------------------------
    # Type Constructor

    # Not yet needed

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    # Methods delegated to the tablebrowser
    delegate method * to tb

    #-------------------------------------------------------------------
    # Components

    component tb          ;# tablebrowser(n) used to browse groups
    component bar         ;# Tool bar
    component editbtn     ;# The "Edit Group" button

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
            -table       "gui_sat_ngc"          \
            -keycol      "ngc"                  \
            -keycolnum   0                      \
            -width       100                    \
            -displaycmd  [mymethod DisplayData]

        # NEXT, create the toolbar
        install bar using frame $tb.toolbar \
            -relief flat

        install editbtn using button $bar.edit   \
            -image      ::athgui::icon::pencil22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Curve"

       
        pack $editbtn   -side left

        # NEXT, hand the toolbar to the browser.
        $tb toolbar $tb.toolbar

        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $g", but
        # we don't want to display it.

        $tb insertcolumn end 0 {ID}
        $tb columnconfigure end -hide yes
        $tb insertcolumn end 0 {Nbhood}
        $tb insertcolumn end 0 {Group}
        $tb insertcolumn end 0 {Concern}
        $tb insertcolumn end 0 {Sat at T0}
        $tb columnconfigure end -sortmode real
        $tb insertcolumn end 0 {Trend}
        $tb columnconfigure end -sortmode real
        $tb insertcolumn end 0 {Saliency}
        $tb columnconfigure end -sortmode real

        # NEXT, sort on column 1 by default
        $tb sortbycolumn 1 -increasing

        # NEXT, pack the tablebrowser and let it expand
        pack $tb -expand yes -fill both

        # NEXT, prepare to get tablelist events
        bind $tb <<TablebrowserSelect>> [mymethod UpdateToolbarState]

        # NEXT, prepare to update on data change
        notifier bind ::scenario <Reconfigure> $self [mymethod Reconfigure]
        notifier bind ::sat      <Entity>      $self $self

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
    # Selects the neighborhoods in the browser.

    method select {ids} {
        $tb select $ids
        $self UpdateToolbarState
    }

    # create n g c
    #
    # n, g    The nbhood, group, and concern of a new sat curve.
    #
    # A new satisfaction curve has been created.  
    # For now, just reload the whole shebang
    
    method create {n g c} {
        $tb reload
    }

    # update n g c
    #
    # n, g, c    The nbhood, group, and concern of the updated curve
    #
    # The curve has been updated.

    method update {n g c} {
        $tb update [list $n $g $c]
    }

    # delete n g c
    #
    # n     Nbhood of deleted curve
    # g     group of deleted curve
    # c     Concern of deleted curve
    #
    # When a curve is deleted, we need to update the toolbar
    # state, as there might no longer be a selection.

    method delete {n g c} {
        # FIRST, update the tablebrowser
        $tb delete [list $n $g $c]

        # NEXT, update the state
        $self UpdateToolbarState
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
    # Called when the user wants to edit the selected group(s)

    method EditSelected {} {
        set ids [$tb curselection]

        if {[llength $ids] == 1} {
            lassign [lindex $ids 0] n g c

            ordergui enter SAT:UPDATE
            ordergui parm set n $n
            ordergui parm set g $g
            ordergui parm set c $c
        } else {
            ordergui enter SAT:UPDATE:MULTI
            ordergui parm set ids $ids
        }
    }

    # DisplayData dict
    # 
    # dict   the data dictionary that contains the group information
    #
    # This method converts the group data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            set id [list $n $g $c]

            $tb setdata $id \
                [list $id $n $g $c $sat0 $trend0 $saliency]
        }
    }

    # UpdateToolbarState
    #
    # Enables/disables toolbar controls based on the displayed data.

    method UpdateToolbarState {} {
        # FIRST, get the number of selected groups
        set num [llength [$tb curselection]]

        # NEXT, update the toolbar buttons
        if {$num > 0} {
            $editbtn    configure -state normal
        } else {
            $editbtn    configure -state disabled
        }
    }
}


