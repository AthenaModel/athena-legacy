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
#    It is a wrapper around sqlbrowser(n).
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
            -view         gui_attroeuf_nfg            \
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
            order ROE:ATTACK:UNIFORMED:CREATE

        pack $addbtn   -side left

        # Edit Button
        install editbtn using mkeditbutton $bar.edit "Edit Selected ROE" \
            -state   disabled                                            \
            -command [mymethod EditSelected]

        cond::orderIsValidMulti control $editbtn \
            order   ROE:ATTACK:UNIFORMED:UPDATE  \
            browser $win
       
        pack $editbtn   -side left

        # Delete Button
        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected ROE"                          \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::orderIsValidSingle control $deletebtn \
            order   ROE:ATTACK:DELETE               \
            browser $win

        pack $deletebtn   -side right

        # NEXT, update individual entities when they change.
        notifier bind ::attroe <Entity> $self [mymethod uid]
    }

    destructor {
        notifier forget $self
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
        order enter ROE:ATTACK:UNIFORMED:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            order enter ROE:ATTACK:UNIFORMED:UPDATE id [lindex $ids 0]
        } else {
            order enter ROE:ATTACK:UNIFORMED:UPDATE:MULTI ids $ids
        }
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, There should be only one selected.
        order send gui ROE:ATTACK:DELETE \
            id [lindex [$hull uid curselection] 0]
    }
}










