#-----------------------------------------------------------------------
# TITLE:
#    vrelbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    vrelbrowser(sim) package: Vertical Relationship browser, Scenario
#    Mode.
#
#    This widget displays a formatted list of gui_vrel_view records.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor vrelbrowser {
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
        {g        "Of Group G"                  }
        {a        "With Actor A"                }
        {gtype    "G Type"                      }
        {base     "Baseline"     -sortmode real }
        {current  "Current"      -sortmode real }
        {nat      "Natural"      -sortmode real }
        {override "OV"           -hide 1        }
    }

    #-------------------------------------------------------------------
    # Components

    component editbtn     ;# The "Edit" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_vrel_view               \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -displaycmd   [mymethod DisplayData]      \
            -reloadon {
                ::rdb <actors>
                ::rdb <civgroups>
                ::rdb <groups>
                ::sim <DbSyncB>
            } -views {
                gui_vrel_view          "All"
                gui_vrel_override_view "Overridden"
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using mkeditbutton $bar.edit   \
            "Override Initial Horizontal Relationship" \
            -state   disabled                          \
            -command [mymethod EditSelected]

        cond::availableCanUpdate control $editbtn \
            order   VREL:OVERRIDE                 \
            browser $win

        install deletebtn using mkdeletebutton $bar.delete \
            "Restore Initial Horizontal Relationship"      \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::availableCanDelete control $deletebtn \
            order   VREL:RESTORE                    \
            browser $win

        pack $editbtn   -side left
        pack $deletebtn -side right

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <vrel_ga> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # When vrel_ga records are deleted, treat it like an update.
    delegate method {uid *}      to hull using {%c uid %m}
    delegate method {uid delete} to hull using {%c uid update}


    # canupdate
    #
    # Returns 1 if the current selection can be "updated" and 0 otherwise.
    #
    # The current selection can be updated if it is a single or multiple
    # selection.

    method canupdate {} {
        # FIRST, there must be something selected
        if {[llength [$self uid curselection]] > 0} {
            return 1
        } else {
            return 0
        }
    }

    # candelete
    #
    # Returns 1 if the current selection can be "deleted" and 0 otherwise.
    #
    # The current selection can be deleted if it is a single
    # selection and it is overridden.

    method candelete {} {
        # FIRST, there must be one thing selected
        if {[llength [$self uid curselection]] != 1} {
            return 0
        }

        # NEXT, is it an override?
        set id [lindex [$self uid curselection] 0]
        lassign $id g a

        set override [rdb onecolumn {
            SELECT override FROM vrel_view WHERE g=$g AND a=$a
        }]

        if {$override ne "" && $override} {
            return 1
        } else {
            return 0
        }
    }

    #-------------------------------------------------------------------
    # Private Methods

    # DisplayData rindex values
    # 
    # rindex    The row index
    # values    The values in the row's cells
    #
    # Sets the cell foreground color for the color cells.

    method DisplayData {rindex values} {
        set override [lindex $values end-1]

        if {$override && [sim state] eq "PREP"} {
            $hull rowconfigure $rindex -foreground "#BB0000"
        } else {
            $hull rowconfigure $rindex -foreground $::app::derivedfg
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::availableCanUpdate update $editbtn
        cond::availableCanDelete update $deletebtn
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            order enter VREL:OVERRIDE id [lindex $ids 0]
        } else {
            order enter VREL:OVERRIDE:MULTI ids $ids
        }
    }

    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Pop up the dialog, and select this entity
        order send gui VREL:RESTORE id $id
    }
}


