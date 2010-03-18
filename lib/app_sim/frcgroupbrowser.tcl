#-----------------------------------------------------------------------
# TITLE:
#    frcgroupbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    frcgroupbrowser(sim) package: Force Group browser.
#
#    This widget displays a formatted list of force group records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor frcgroupbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Look-up Tables

    # Layout
    #
    # %D is replaced with the color for derived columns.

    typevariable layout {
        { g         "ID"         }
        { longname  "Long Name"  }
        { color     "Color"      }
        { shape     "Unit Shape" }
        { forcetype "Force Type" }
        { demeanor  "Demeanor"   }
        { uniformed "Uniformed?" }
        { local     "Local?"     }
        { coalition "Coalition?" }
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
            -view         gui_frcgroups               \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -displaycmd   [mymethod DisplayData]      \
            -reloadon {
                ::sim <DbSyncB>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add \
            "Add Force Group"                     \
            -state   normal                       \
            -command [mymethod AddEntity]

        cond::orderIsValid control $addbtn \
            order GROUP:FORCE:CREATE


        install editbtn using mkeditbutton $bar.edit \
            "Edit Selected Group"                    \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::orderIsValidMulti control $editbtn \
            order   GROUP:FORCE:UPDATE           \
            browser $win


        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected Group"                        \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::orderIsValidSingle control $deletebtn \
            order   GROUP:FORCE:DELETE              \
            browser $win

       
        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right

        # NEXT, update individual entities when they change.
        notifier bind ::frcgroup <Entity> $self [mymethod uid]
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
    # rindex    The row index of an updated row
    # values    The values in the row's cells.
    #
    # Colors the "color" cell.

    method DisplayData {rindex values} {
        $hull cellconfigure $rindex,2 -background [lindex $values 2]
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
        if {[llength [$hull uid curselection]] == 1} {
            set g [lindex [$hull uid curselection] 0]

            notifier send ::app <ObjectSelect> \
                [list group $g]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity.

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter GROUP:FORCE:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter GROUP:FORCE:UPDATE g $id
        } else {
            order enter GROUP:FORCE:UPDATE:MULTI ids $ids
        }
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the dialog, and select this entity
        order send gui GROUP:FORCE:DELETE g $id
    }
}


