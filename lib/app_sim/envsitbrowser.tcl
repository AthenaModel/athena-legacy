#-----------------------------------------------------------------------
# TITLE:
#    envsitbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    envsitbrowser(sim) package: Environmental Situation browser.
#
#    This widget displays a formatted list of envsits.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor envsitbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component editbtn     ;# The "Edit" button
    component resolvebtn  ;# The "Resolve" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   yes                         \
            -table        "gui_envsits"               \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 1                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # FIRST, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using button $bar.add   \
            -image      ::projectgui::icon::plus22 \
            -relief     flat                   \
            -overrelief raised                 \
            -state      normal                 \
            -command    [mymethod AddEntity]

        DynamicHelp::add $addbtn -text "Add Situation"

        cond::orderIsValid control $addbtn \
            order SITUATION:ENVIRONMENTAL:CREATE

        install editbtn using button $bar.edit   \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Situation"

        cond::orderIsValidSingle control $editbtn   \
            order   SITUATION:ENVIRONMENTAL:UPDATE \
            browser $win

        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22    \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected Situation"

        cond::orderIsValidCanDelete control $deletebtn \
            order   SITUATION:ENVIRONMENTAL:DELETE  \
            browser $win


        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right

        # NEXT, create the columns and labels.
        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Change}
        $hull insertcolumn end 0 {State}
        $hull insertcolumn end 0 {Type}
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {Location}
        $hull insertcolumn end 0 {Coverage}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {Began At}
        $hull insertcolumn end 0 {Changed At}
        $hull insertcolumn end 0 {Caused By}
        $hull insertcolumn end 0 {Affects}
        $hull insertcolumn end 0 {Resolved By}
        $hull insertcolumn end 0 {Driver}
        $hull columnconfigure end -sortmode integer

        # NEXT, sort on column 0 by default
        $hull sortbycolumn 0 -increasing

        # NEXT, update individual entities when they change.
        notifier bind ::envsit <Entity> $self $self
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # candelete
    #
    # Returns 1 if the current selection is deletable.
    
    method candelete {} {
        if {[llength [$self curselection]] == 1} {
            set id [lindex [$self curselection] 0]

            if {$id in [envsit initial names]} {
                return 1
            }
        }

        return 0
    }

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
            lappend fields $id $change $state $stype $n $location $coverage
            lappend fields $ts $tc $g $flist $resolver $driver

            $hull setdata $id $fields
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidSingle    update $editbtn
        cond::orderIsValidCanDelete update $deletebtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull curselection]] == 1} {
            set s [lindex [$hull curselection] 0]

            notifier send ::app <ObjectSelect> [list situation $s]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter SITUATION:ENVIRONMENTAL:CREATE
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected entity

    method EditSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, Send the delete order.
        order enter SITUATION:ENVIRONMENTAL:UPDATE s $id
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, Send the delete order.
        order send gui SITUATION:ENVIRONMENTAL:DELETE s $id
    }

}

