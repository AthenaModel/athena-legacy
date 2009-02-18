#-----------------------------------------------------------------------
# TITLE:
#    nbgroupbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    nbgroupbrowser(sim) package: Nbhood Group browser.
#
#    This widget displays a formatted list of nbhood group records.
#    Entries in the list are managed by the tablebrowser(n).  
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

#-----------------------------------------------------------------------
# Widget Definition

snit::widget nbgroupbrowser {
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
    component addbtn      ;# The "Add Group" button
    component editbtn     ;# The "Edit Group" button
    component deletebtn   ;# The "Delete Group" button

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
            -table       "gui_nbgroups"         \
            -keycol      "id"                   \
            -keycolnum   0                      \
            -width       100                    \
            -displaycmd  [mymethod DisplayData]

        # NEXT, create the toolbar
        install bar using frame $tb.toolbar \
            -relief flat

        install addbtn using button $bar.add   \
            -image      ::athgui::icon::plus22 \
            -relief     flat                   \
            -overrelief raised                 \
            -state      normal                 \
            -command    [mymethod AddGroup]

        DynamicHelp::add $addbtn -text "Add Nbhood Group"

        install editbtn using button $bar.edit   \
            -image      ::athgui::icon::pencil22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Group"

        install deletebtn using button $bar.delete \
            -image      ::athgui::icon::x22        \
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

        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $g", but
        # we don't want to display it.

        $tb insertcolumn end 0 {ID}
        $tb columnconfigure end -hide yes
        $tb insertcolumn end 0 {Nbhood}
        $tb insertcolumn end 0 {CivGroup}
        $tb insertcolumn end 0 {Local Name}
        $tb insertcolumn end 0 {Demeanor}
        $tb insertcolumn end 0 {RollupWeight}
        $tb columnconfigure end -sortmode real
        $tb insertcolumn end 0 {EffectsFactor}
        $tb columnconfigure end -sortmode real

        # NEXT, sort on column 1 by default
        $tb sortbycolumn 1 -increasing

        # NEXT, pack the tablebrowser and let it expand
        pack $tb -expand yes -fill both

        # NEXT, prepare to get tablelist events
        bind $tb <<TablebrowserSelect>> [mymethod UpdateToolbarState]

        # NEXT, prepare to update on data change
        notifier bind ::scenario <Reconfigure> $self [mymethod Reconfigure]
        notifier bind ::nbgroup <Entity>       $self $self

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

    # create id
    #
    # id    The {n g} of the created nbhood group
    #
    # A new group has been created.  We need to put it in its place.
    # For now, just reload the whole shebang
    
    method create {id} {
        $tb reload
    }

    # update id
    #
    # id     The {n g} of the updated nbhood group
    #
    # The group has been updated.

    method update {id} {
        $tb update $id
    }

    # delete id
    #
    # id     The {n g} of the delete nbhood group
    #
    # When a group is deleted, we need to update the toolbar
    # state, as it's likely that there is no longer a selection.

    method delete {id} {
        # FIRST, update the tablebrowser
        $tb delete $id

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

    # AddGroup
    #
    # Called when the user wants to add a new group.

    method AddGroup {} {
        # FIRST, Pop up the dialog
        order enter GROUP:NBHOOD:CREATE
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected group.

    method EditSelected {} {
        set ids [$tb curselection]

        if {[llength $ids] == 1} {
            lassign [lindex $ids 0] n g

            order enter GROUP:NBHOOD:UPDATE
            ordergui parm set n $n
            ordergui parm set g $g
        } else {
            order enter GROUP:NBHOOD:UPDATE:MULTI
            ordergui parm set ids $ids
        }
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected group.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        lassign [lindex [$tb curselection] 0] n g

        # NEXT, Pop up the dialog, and select this group
        order enter GROUP:NBHOOD:DELETE
        ordergui parm set n $n 
        ordergui parm set g $g
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
            set id [list $n $g]

            $tb setdata $id \
                [list $id $n $g $local_name $demeanor \
                     $rollup_weight $effects_factor]
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

        if {$num == 1} {
            $deletebtn  configure -state normal
        } else {
            $deletebtn  configure -state disabled
        }
    }
}



