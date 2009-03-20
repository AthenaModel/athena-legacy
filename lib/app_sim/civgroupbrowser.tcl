#-----------------------------------------------------------------------
# TITLE:
#    civgroupbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    civgroupbrowser(sim) package: Civilian Group browser.
#
#    This widget displays a formatted list of civilian group records.
#    Entries in the list are managed by the tablebrowser(n).  
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

#-----------------------------------------------------------------------
# Widget Definition

snit::widget civgroupbrowser {
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
    component addbtn      ;# The "Add Civ Group" button
    component editbtn     ;# The "Edit Civ Group" button
    component deletebtn   ;# The "Delete Civ Group" button

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
            -table       "gui_civgroups"        \
            -keycol      "id"                   \
            -keycolnum   0                      \
            -width       100                    \
            -displaycmd  [mymethod DisplayData]

        # NEXT, create the toolbar
        install bar using frame $tb.toolbar \
            -relief flat

        install addbtn using button $bar.add   \
            -image      ::projectgui::icon::plus22 \
            -relief     flat                   \
            -overrelief raised                 \
            -state      normal                 \
            -command    [mymethod AddGroup]

        DynamicHelp::add $addbtn -text "Add Civilian Group"

        install editbtn using button $bar.edit   \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Group"

        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22        \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected Group"
        
        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right

        # NEXT, hand the toolbar to the browser.
        $tb toolbar $tb.toolbar

        # NEXT, create the columns and labels.
        $tb insertcolumn end 0 {ID}
        $tb insertcolumn end 0 {Long Name}
        $tb insertcolumn end 0 {Color}
        $tb insertcolumn end 0 {Unit Shape}

        # NEXT, pack the tablebrowser and let it expand
        pack $tb -expand yes -fill both

        # NEXT, prepare to get tablelist events
        bind $tb <<TablebrowserSelect>> [mymethod SelectionChanged]

        # NEXT, prepare to update on data change
        notifier bind ::sim      <Reconfigure> $self [mymethod Reconfigure]
        notifier bind ::civgroup <Entity>      $self $self

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
    # id    The ID of the created group
    #
    # A new group has been created.  We need to put it in its place.
    # For now, just reload the whole shebang
    
    method create {id} {
        $tb reload
    }
    
    #-------------------------------------------------------------------
    # Private Methods

    # DisplayData dict
    # 
    # dict   the data dictionary that contains the group information
    #
    # This method converts the group data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            $tb setdata $g \
                [list $g $longname $color $shape]
            $tb setcellbackground $g 2 $color
        }
    }

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

    # AddGroup
    #
    # Called when the user wants to add a new group.

    method AddGroup {} {
        # FIRST, Pop up the dialog
        order enter GROUP:CIVILIAN:CREATE
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected group(s).

    method EditSelected {} {
        set ids [$tb curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter GROUP:CIVILIAN:UPDATE g $id
        } else {
            order enter GROUP:CIVILIAN:UPDATE:MULTI ids $ids
        }
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected group.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$tb curselection] 0]

        # NEXT, Pop up the dialog, and select this group
        order send gui GROUP:CIVILIAN:DELETE g $id
    }

    # delete n
    #
    # n     Deleted group.
    #
    # When a group is deleted, we need to update the toolbar
    # state, as it's likely that there is no longer a selection.

    method delete {n} {
        # FIRST, update the tablebrowser
        $tb delete $n

        # NEXT, update the state
        $self SelectionChanged
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

        if {$num == 1} {
            $deletebtn  configure -state normal
        } else {
            $deletebtn  configure -state disabled
        }

        # NEXT, notify the app of the selection.
        if {$num == 1} {
            set g [lindex [$tb curselection] 0]

            notifier send ::app <ObjectSelect> \
                [list group $g]
        }
    }
}

