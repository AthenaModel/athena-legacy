#-----------------------------------------------------------------------
# TITLE:
#    orggroupbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    orggroupbrowser(sim) package: Organization Group browser.
#
#    This widget displays a formatted list of organization group records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor orggroupbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component editbtn     ;# The "Edit" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -table        "gui_orggroups"             \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using button $bar.add       \
            -image      ::projectgui::icon::plus22 \
            -relief     flat                       \
            -overrelief raised                     \
            -state      normal                     \
            -command    [mymethod AddEntity]

        DynamicHelp::add $addbtn -text "Add Organization Group"

        cond::orderIsValid control $addbtn \
            order GROUP:ORGANIZATION:CREATE


        install editbtn using button $bar.edit       \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                         \
            -overrelief raised                       \
            -state      disabled                     \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Group"

        cond::orderIsValidMulti control $editbtn \
            order   GROUP:ORGANIZATION:UPDATE    \
            browser $win


        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22    \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected Group"
        
        cond::orderIsValidSingle control $deletebtn \
            order   GROUP:ORGANIZATION:DELETE       \
            browser $win


        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right


        # NEXT, create the columns and labels.
        $hull insertcolumn end 0 {ID}
        $hull insertcolumn end 0 {Long Name}
        $hull insertcolumn end 0 {Color}
        $hull insertcolumn end 0 {Unit Shape}        
        $hull insertcolumn end 0 {Org Type}
        $hull insertcolumn end 0 {Demeanor}
        $hull insertcolumn end 0 {RollupWeight}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {EffectsFactor}
        $hull columnconfigure end -sortmode real

        # NEXT, update individual entities when they change.
        notifier bind ::orggroup <Entity>      $self $self
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

    # DisplayData dict
    # 
    # dict   the data dictionary that contains the entity information
    #
    # This method converts the entity data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            $hull setdata $g \
                [list $g $longname $color $shape $orgtype \
                     $demeanor $rollup_weight $effects_factor]
            $hull setcellbackground $g 2 $color
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidSingle update $deletebtn
        cond::orderIsValidMulti  update $editbtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull curselection]] == 1} {
            set g [lindex [$hull curselection] 0]

            notifier send ::app <ObjectSelect> \
                [list group $g]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity.

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter GROUP:ORGANIZATION:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter GROUP:ORGANIZATION:UPDATE g $id
        } else {
            order enter GROUP:ORGANIZATION:UPDATE:MULTI ids $ids
        }
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, Send the order
        order send gui GROUP:ORGANIZATION:DELETE g $id
    }
}



