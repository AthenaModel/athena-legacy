#-----------------------------------------------------------------------
# TITLE:
#    attroenfbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    attroenfbrowser(sim) package: Attacking ROE (Non-Uniformed) browser.
#
#    This widget displays a formatted list of gui_attroenf_ng records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor attroenfbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Lookup Tables

    # Layout
    #
    # %D is replaced with the color for derived columns.

    typevariable layout {
        {n         "Nbhood"                     }
        {f         "Attacker"                   }
        {g         "Attacked"                   }
        {roe       "ROE"                        }
        {cooplimit "Coop. Limit" -sortmode real }
        {rate      "Attacks/Day" -sortmode real }
    }

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component editbtn     ;# The "Edit" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_attroenf_nfg            \
            -uid          id                          \
            -titlecolumns 3                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        # Add Button
        install addbtn using mkaddbutton $bar.add "Add ROE" \
            -command [mymethod AddEntity]

        cond::orderIsValid control $addbtn \
            order ATTROE:NF:CREATE

        pack $addbtn   -side left

        # Edit Button
        install editbtn using mkeditbutton $bar.edit "Edit Selected ROE" \
            -state   disabled                                            \
            -command [mymethod EditSelected]

        cond::orderIsValidMulti control $editbtn \
            order   ATTROE:NF:UPDATE  \
            browser $win
       
        pack $editbtn   -side left

        # Delete Button
        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected ROE"                          \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::orderIsValidSingle control $deletebtn \
            order   ATTROE:DELETE               \
            browser $win

        pack $deletebtn   -side right

        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $f $g", but
        # we don't want to display it.

        # NEXT, update individual entities when they change.
        notifier bind ::attroe <Entity> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

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
        if {[llength [$hull uid curselection]] == 1} {
            set id [lindex [$hull uid curselection] 0]
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
        order enter ATTROE:NF:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            order enter ATTROE:NF:UPDATE id [lindex $ids 0]
        } else {
            order enter ATTROE:NF:UPDATE:MULTI ids $ids
        }
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, There should be only one selected.
        order send gui ATTROE:DELETE \
            id [lindex [$hull uid curselection] 0]
    }

}












