#-----------------------------------------------------------------------
# TITLE:
#   cappenbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    cappenbrowser(sim) package: CAP group penetration browser
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor cappenbrowser {
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
        {k        "Of CAP"                                      }
        {owner    "With Owner"                                  }
        {g        "Into Group"                                  }
        {n        "In Nbhood"                                   }
        {capcov   "Grp Cov"       -sortmode real -foreground %D }
        {pen      "= Grp Pen"     -sortmode real                }
        {nbcov    "* Nbhood Cov"  -sortmode real                }
        {capacity "* Capacity"    -sortmode real                }
        {orphan   "ORPHAN"       -hide 1                        }
    }

    #-------------------------------------------------------------------
    # Components

    component editbtn     ;# The "Edit" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_capcov_nonzero          \
            -uid          id                          \
            -titlecolumns 4                           \
            -selectioncmd [mymethod SelectionChanged] \
            -displaycmd   [mymethod DisplayData]      \
            -reloadon {
                ::rdb <caps>
                ::sim <DbSyncB>
            } -views {
                gui_capcov         "All"
                gui_capcov_nonzero "Non-Zero"
                gui_capcov_orphans "Orphans"
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using mkeditbutton $bar.edit \
            "Set CAP Neighborhood Coverage"          \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::availableMulti control $editbtn \
            order   CAP:PEN:SET              \
            browser $win

        pack $editbtn   -side left

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <cap_kg> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # When cap_kn records are deleted, treat it like an update.
    delegate method {uid *}      to hull using {%c uid %m}
    delegate method {uid delete} to hull using {%c uid update}


    #-------------------------------------------------------------------
    # Private Methods

    # DisplayData rindex values
    # 
    # rindex    The row index
    # values    The values in the row's cells
    #
    # Sets the cell foreground color for the color cells.

    method DisplayData {rindex values} {
        set orphan [lindex $values end-1]

        if {$orphan} {
            $hull rowconfigure $rindex \
                -foreground black      \
                -background yellow
        }
    }

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::availableMulti update $editbtn
    }

    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            order enter CAP:PEN:SET id [lindex $ids 0]
        } else {
            order enter CAP:PEN:SET:MULTI ids $ids
        }
    }
}


