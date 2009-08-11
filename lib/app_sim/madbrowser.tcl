#-----------------------------------------------------------------------
# TITLE:
#    madbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    madbrowser(sim) package: Magic Attitude Driver browser.
#
#    This widget displays a formatted list of MADs.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor madbrowser {
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
            -tickreload   yes                         \
            -table        "gui_mads"                  \
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

        DynamicHelp::add $addbtn -text "Add Driver"

        cond::orderIsValid control $addbtn \
            order MAD:CREATE

        install editbtn using button $bar.edit   \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Driver"

        cond::orderIsValidCanUpdate control $editbtn   \
            order   MAD:UPDATE \
            browser $win

        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22    \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected Driver"

        cond::orderIsValidCanDelete control $deletebtn \
            order   MAD:DELETE  \
            browser $win


        pack $addbtn     -side left
        pack $editbtn    -side left
        pack $deletebtn  -side right

        # NEXT, create the columns and labels.
        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Description}
        $hull insertcolumn end 0 {Driver}
        $hull columnconfigure end                  \
            -sortmode   integer                    \
            -foreground $::browser_base::derivedfg 
        $hull insertcolumn end 0 {Inputs}
        $hull columnconfigure end                  \
            -sortmode   integer                    \
            -foreground $::browser_base::derivedfg

        # NEXT, sort on column 0 by default
        $hull sortbycolumn 0 -decreasing

        # NEXT, update individual entities when they change.
        notifier bind ::mad <Entity> $self $self
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

            if {$id in [mad initial names]} {
                return 1
            }
        }

        return 0
    }


    # canupdate
    #
    # Returns 1 if the current selection is updateable.
    
    method canupdate {} {
        if {[llength [$self curselection]] == 1} {
            set id [lindex [$self curselection] 0]

            if {$id in [mad initial names]} {
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
            $hull setdata $id [list $id $oneliner $driver $inputs]
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidCanUpdate  update $editbtn
        cond::orderIsValidCanDelete  update $deletebtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull curselection]] == 1} {
            set s [lindex [$hull curselection] 0]

            notifier send ::app <ObjectSelect> [list mad $s]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter MAD:CREATE
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected entity

    method EditSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, Pop up the order dialog.
        order enter MAD:UPDATE id $id
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, Send the delete order.
        order send gui MAD:DELETE id $id
    }

}


