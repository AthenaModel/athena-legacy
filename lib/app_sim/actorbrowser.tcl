#-----------------------------------------------------------------------
# TITLE:
#    actorbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    actorbrowser(sim) package: Actor browser.
#
#    This widget displays a formatted list of actor records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor actorbrowser {
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
        { a          "ID"                                             }
        { longname   "Long Name"                                      }
        { income     "Income, $/Week"                                 }
        { cash       "Cash on Hand, $"                                }
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
            -view         gui_actors                  \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add "Add Actor" \
            -command [mymethod AddEntity]

        cond::orderIsValid control $addbtn \
            order ACTOR:CREATE


        install editbtn using mkeditbutton $bar.edit "Edit Actor" \
            -state   disabled                                     \
            -command [mymethod EditSelected]

        cond::orderIsValidSingle control $editbtn   \
            order   ACTOR:UPDATE                    \
            browser $win


        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Actor"                                 \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::orderIsValidSingle control $deletebtn \
            order   ACTOR:DELETE           \
            browser $win

        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right

        # NEXT, update individual entities when they change.
       notifier bind ::rdb <actors> $self [mymethod uid]
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
        cond::orderIsValidSingle update [list $editbtn $deletebtn]
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity.

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter ACTOR:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entity(s).

    method EditSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the dialog, and select this entity
        order enter ACTOR:UPDATE a $id
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the dialog, and select this entity
        order send gui ACTOR:DELETE a $id
    }
}



