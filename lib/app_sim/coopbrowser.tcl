#-----------------------------------------------------------------------
# TITLE:
#    coopbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    coopbrowser(sim) package: Cooperation browser.
#
#    This widget displays a formatted list of coop_nfg records.
#    Entries in the list are managed by the tablebrowser(n).  
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

#-----------------------------------------------------------------------
# Widget Definition

snit::widget coopbrowser {
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
            -table       "gui_coop_nfg"          \
            -keycol      "id"                   \
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
        $tb insertcolumn end 0 {Of Group}
        $tb insertcolumn end 0 {With Group}
        $tb insertcolumn end 0 {Cooperation}
        $tb columnconfigure end -sortmode real

        # NEXT, sort on column 1 by default
        $tb sortbycolumn 1 -increasing

        # NEXT, pack the tablebrowser and let it expand
        pack $tb -expand yes -fill both

        # NEXT, prepare to get tablelist events
        bind $tb <<TablebrowserSelect>> [mymethod SelectionChanged]

        # NEXT, prepare to update on data change
        notifier bind ::scenario <Reconfigure> $self [mymethod Reconfigure]
        notifier bind ::coop      <Entity>      $self $self

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
    # id      The {n f g} of a new coop curve.
    #
    # A new cooperation curve has been created.  
    # For now, just reload the whole shebang
    
    method create {id} {
        $tb reload
    }

    # update id
    #
    # id        The {n f g} of the updated curve
    #
    # The curve has been updated.

    method update {id} {
        $tb update $id
    }

    # delete id
    #
    # id        The {n f g} of the updated curve
    #
    # When a curve is deleted, we need to update the toolbar
    # state, as there might no longer be a selection.

    method delete {id} {
        # FIRST, update the tablebrowser
        $tb delete $id

        # NEXT, update the state
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
            lassign [lindex $ids 0] n f g

            order enter COOPERATION:UPDATE n $n f $f g $g
        } else {
            order enter COOPERATION:UPDATE:MULTI ids $ids
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
            set id [list $n $f $g]

            $tb setdata $id \
                [list $id $n $f $g $coop0]
        }
    }

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, get the number of selected groups
        set num [llength [$tb curselection]]

        # NEXT, update the toolbar buttons
        if {$num > 0} {
            $editbtn    configure -state normal
        } else {
            $editbtn    configure -state disabled
        }

        # NEXT, notify the app of the selection.
        if {$num == 1} {
            set id [lindex [$tb curselection] 0]
            lassign $id n f g

            notifier send ::app <ObjectSelect> \
                [list nfg $id nbhood $n group $f]
        }
    }
}
