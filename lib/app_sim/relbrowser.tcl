#-----------------------------------------------------------------------
# TITLE:
#    relbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    relbrowser(sim) package: Relationship browser.
#
#    This widget displays a formatted list of rel_fg records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor relbrowser {
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
        {f     "Of Group F"                  }
        {g     "With Group G"                }
        {ftype "F Type"                      }
        {gtype "G Type"                      }
        {rel   "Relationship" -sortmode real }
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
            -view         gui_rel_fg                  \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using mkeditbutton $bar.edit \
            "Edit Selected Relationship"             \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::orderIsValidCanUpdate control $editbtn \
            order   REL:UPDATE          \
            browser $win
       
        pack $editbtn   -side left

        # NEXT, update individual entities when they change.
        notifier bind ::rel <Entity> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull


    # canupdate
    #
    # Returns 1 if the current selection can be "updated" and 0 otherwise.
    #
    # The current selection can be updated if it is a single or multiple
    # selection and none of the selected entries has f=g.

    method canupdate {} {
        # FIRST, there must be something selected
        if {[llength [$self uid curselection]] > 0} {
            foreach id [$self uid curselection] {
                lassign $id f g

                if {$f eq $g} {
                    return 0
                }
            }
            return 1
        } else {
            return 0
        }
    }

    #-------------------------------------------------------------------
    # Private Methods

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidCanUpdate update $editbtn
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            order enter REL:UPDATE id [lindex $ids 0]
        } else {
            order enter REL:UPDATE:MULTI ids $ids
        }
    }
}

