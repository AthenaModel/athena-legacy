#-----------------------------------------------------------------------
# TITLE:
#    satbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    satbrowser(sim) package: Satisfaction browser.
#
#    This widget displays a formatted list of satisfaction curve records.
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

        DynamicHelp::add $editbtn -text "Edit Selected Curve"

        cond::orderIsValidMulti control $editbtn \
            order   SATISFACTION:UPDATE          \
            browser $win

       
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
        bind $tb <<TablebrowserSelect>> [mymethod SelectionChanged]

        # NEXT, prepare to update on data change
        notifier bind ::sim   <Reconfigure> $self [mymethod Reconfigure]
        notifier bind ::sat   <Entity>      $self $self

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
    # id      The {n g c} of a new sat curve.
    #
    # A new satisfaction curve has been created.  
    # For now, just reload the whole shebang
    
    method create {id} {
        $tb reload
    }

    # update id
    #
    # id        The {n g c} of the updated curve
    #
    # The curve has been updated.

    method update {id} {
        $tb update $id
    }

    # delete id
    #
    # id        The {n g c} of the updated curve
    #
    # When a curve is deleted, there might no longer be a selection.

    method delete {id} {
        # FIRST, update the tablebrowser
        $tb delete $id

        # NEXT, handle selection changes.
        $self SelectionChanged
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
    # Called when the user wants to edit the selected group(s)

    method EditSelected {} {
        set ids [$tb curselection]

        if {[llength $ids] == 1} {
            lassign [lindex $ids 0] n g c

            order enter SATISFACTION:UPDATE n $n g $g c $c
        } else {
            order enter SATISFACTION:UPDATE:MULTI ids $ids
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

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidMulti update $editbtn

        # NEXT, if there's exactly one item selected, notify the
        # the app.
        if {[llength [$tb curselection]] == 1} {
            set id [lindex [$tb curselection] 0]
            lassign $id n g c

            notifier send ::app <ObjectSelect> \
                [list ngc $id  nbhood $n group $g concern $c]
        }
    }
}




