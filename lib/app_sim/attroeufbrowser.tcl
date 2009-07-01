#-----------------------------------------------------------------------
# TITLE:
#    attroeufbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    attroeufbrowser(sim) package: Attacking ROE (Uniformed) browser.
#
#    This widget displays a formatted list of gui_attroeuf_ng records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor attroeufbrowser {
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
            -table        "gui_attroeuf_nfg"          \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 4                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        # Add Button
        install addbtn using button $bar.add       \
            -image      ::projectgui::icon::plus22 \
            -relief     flat                       \
            -overrelief raised                     \
            -state      normal                     \
            -command    [mymethod AddEntity]

        DynamicHelp::add $addbtn -text "Add ROE"

        cond::orderIsValid control $addbtn \
            order ROE:ATTACK:UNIFORMED:CREATE

        pack $addbtn   -side left

        # Edit Button
        install editbtn using button $bar.edit       \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                         \
            -overrelief raised                       \
            -state      disabled                     \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected ROE"

        cond::orderIsValidMulti control $editbtn \
            order   ROE:ATTACK:UNIFORMED:UPDATE  \
            browser $win
       
        pack $editbtn   -side left

        # Delete Button
        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22    \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected ROE"

        cond::orderIsValidSingle control $deletebtn \
            order   ROE:ATTACK:DELETE               \
            browser $win

        pack $deletebtn   -side right

        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $f $g", but
        # we don't want to display it.

        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -hide yes
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {Attacker}
        $hull insertcolumn end 0 {Attacked}
        $hull insertcolumn end 0 {ROE}
        $hull insertcolumn end 0 {Coop. Limit}
        $hull columnconfigure end -sortmode real        

        # NEXT, sort on column 1 by default
        $hull sortbycolumn 1 -increasing

        # NEXT, update individual entities when they change.
        notifier bind ::attroe <Entity> $self $self
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
            $hull setdata $id \
                [list $id $n $f $g $roe $cooplimit]
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidMulti  update $editbtn
        cond::orderIsValidSingle update $deletebtn


        # NEXT, if there's exactly one item selected, notify the
        # the app.
        if {[llength [$hull curselection]] == 1} {
            set id [lindex [$hull curselection] 0]
            lassign $id n f g

            notifier send ::app <ObjectSelect> \
                [list nfg $id  nbhood $n group $f]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity.

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter ROE:ATTACK:UNIFORMED:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull curselection]

        if {[llength $ids] == 1} {
            lassign [lindex $ids 0] n f g

            order enter ROE:ATTACK:UNIFORMED:UPDATE n $n f $f g $g
        } else {
            order enter ROE:ATTACK:UNIFORMED:UPDATE:MULTI ids $ids
        }
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        lassign [lindex [$hull curselection] 0] n f g

        # NEXT, Pop up the dialog, and select this entity
        order send gui ROE:ATTACK:DELETE n $n f $f g $g
    }

}









