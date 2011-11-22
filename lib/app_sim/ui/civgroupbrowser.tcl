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
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor civgroupbrowser {
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
        { g          "ID"                                             }
        { longname   "Long Name"                                      }
        { n          "Nbhood"                                         }
        { color      "Color"                                          }
        { shape      "Unit Shape"                                     }
        { demeanor   "Demeanor"                                       }
        { basepop    "BasePop"       -sortmode integer                }
        { sap        "SA%"           -sortmode integer                }
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
            -view         gui_civgroups               \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -displaycmd   [mymethod DisplayData]      \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
                ::demog <Update>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add "Add Civilian Group" \
            -command [mymethod AddEntity]

        cond::available control $addbtn \
            order CIVGROUP:CREATE


        install editbtn using mkeditbutton $bar.edit "Edit Selected Group" \
            -state   disabled                                              \
            -command [mymethod EditSelected]

        cond::availableMulti control $editbtn   \
            order   CIVGROUP:UPDATE:POSTPREP \
            browser $win


        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected Group"                        \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::availableSingle control $deletebtn \
            order   CIVGROUP:DELETE           \
            browser $win

        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right

        # NEXT, update individual entities when they change.
       notifier bind ::rdb <groups>    $self [mymethod uid]
       notifier bind ::rdb <civgroups> $self [mymethod uid]
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

    # DisplayData rindex values
    # 
    # rindex    The row index
    # values    The values in the row's cells
    #
    # Sets the cell background color for the color cells.

    method DisplayData {rindex values} {
        $hull cellconfigure $rindex,3 -background [lindex $values 3]
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::availableSingle update $deletebtn
        cond::availableMulti  update $editbtn
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity.

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter CIVGROUP:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entity(s).

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            if {[order state] eq "PREP"} {
                order enter CIVGROUP:UPDATE g $id
            } else {
                order enter CIVGROUP:UPDATE:POSTPREP g $id
            }
        } else {
            if {[order state] eq "PREP"} {
                order enter CIVGROUP:UPDATE:MULTI ids $ids
            } else {
                order enter CIVGROUP:UPDATE:MULTI:POSTPREP ids $ids
            }
        }
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the dialog, and select this entity
        order send gui CIVGROUP:DELETE g $id
    }
}




