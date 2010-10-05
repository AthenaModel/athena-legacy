#-----------------------------------------------------------------------
# TITLE:
#    nbgroupbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    nbgroupbrowser(sim) package: Nbhood Group browser.
#
#    This widget displays a formatted list of nbhood group records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor nbgroupbrowser {
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
        { n              "Nbhood"                                         }
        { g              "CivGroup"                                       }
        { local_name     "Local Name"                                     }
        { basepop        "BasePop"       -sortmode integer                }
        { population     "CurrPop"       -sortmode integer -foreground %D }
        { sap            "SA%"           -sortmode integer                }
        { mood0          "Mood at T0"    -sortmode real                   }
        { mood           "Mood Now"      -sortmode real    -foreground %D }
        { demeanor       "Demeanor"                                       }
        { rollup_weight  "RollupWeight"  -sortmode real                   }
        { effects_factor "EffectsFactor" -sortmode real                   }
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
            -view         gui_nbgroups                \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
                ::demog <Update>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using mkaddbutton $bar.add \
            "Add Nbhood Group"                    \
            -state   normal                       \
            -command [mymethod AddEntity]

        cond::orderIsValid control $addbtn \
            order GROUP:NBHOOD:CREATE


        install editbtn using mkeditbutton $bar.edit \
            "Edit Selected Group"                    \
            -state   disabled                        \
            -command [mymethod EditSelected]

        cond::orderIsValidMulti control $editbtn \
            order   GROUP:NBHOOD:UPDATE:POSTPREP \
            browser $win


        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected Group"                        \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::orderIsValidSingle control $deletebtn \
            order   GROUP:NBHOOD:DELETE             \
            browser $win

        
        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right

        # NEXT, Respond to simulation updates
        notifier bind ::nbgroup <Entity> $self [mymethod uid]
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
        cond::orderIsValidSingle update $deletebtn
        cond::orderIsValidMulti  update $editbtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull uid curselection]] == 1} {
            set id [lindex [$hull uid curselection] 0]
            lassign $id n g

            notifier send ::app <ObjectSelect> \
                [list ng $id nbhood $n group $g]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity.

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter GROUP:NBHOOD:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull uid curselection]

        if {[llength $ids] == 1} {
            if {[order state] eq "PREP"} {
                order enter GROUP:NBHOOD:UPDATE          id [lindex $ids 0]
            } else {
                order enter GROUP:NBHOOD:UPDATE:POSTPREP id [lindex $ids 0]
            }
        } else {
            if {[order state] eq "PREP"} {
                order enter GROUP:NBHOOD:UPDATE:MULTI ids $ids
            } else {
                order enter GROUP:NBHOOD:UPDATE:POSTPREP:MULTI ids $ids
            }
        }
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set ids [$hull uid curselection]

        # NEXT, Pop up the dialog, and select this entity
        order send gui GROUP:NBHOOD:DELETE id [lindex $ids 0]
    }
}


