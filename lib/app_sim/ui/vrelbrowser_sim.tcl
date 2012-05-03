#-----------------------------------------------------------------------
# TITLE:
#    vrelbrowser_sim.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    vrelbrowser(sim) package: Vertical Relationship browser, Simulation
#    Mode.
#
#    This widget displays a formatted list of gui_uram_vrel records.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor vrelbrowser_sim {
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
        {g        "Of Group G"                                   }
        {a        "With Actor A"                                 }
        {gtype    "G Type"                                       }
        {vrel     "Current"        -sortmode real -foreground %D }
        {base     "Baseline"       -sortmode real -foreground %D }
        {nat      "Natural"        -sortmode real -foreground %D }
        {vrel0    "Current at T0"  -sortmode real -foreground %D }
        {base0    "Baseline at T0" -sortmode real                }
        {nat0     "Natural at T0"  -sortmode real -foreground %D }
    }

    #-------------------------------------------------------------------
    # Components

    component adjustbtn     ;# The "Adjust" button
    component inputbtn      ;# The "Input" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_uram_vrel               \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <Tick>
                ::sim <DbSyncB>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install adjustbtn using mktoolbutton $bar.adjust    \
            ::projectgui::icon::pencila22                   \
            "Magic Adjust Vertical Relationship Baseline" \
            -state   disabled                               \
            -command [mymethod AdjustSelected]

        cond::availableSingle control $adjustbtn \
            order   MAD:VREL:ADJUST              \
            browser $win

        install inputbtn using mktoolbutton $bar.input \
            ::projectgui::icon::pencili22              \
            "Magic Vertical Relationship Input"      \
            -state   disabled                          \
            -command [mymethod InputForSelected]

        cond::availableSingle control $inputbtn \
            order   MAD:VREL:INPUT               \
            browser $win

        pack $adjustbtn -side left
        pack $inputbtn  -side left

        # NEXT, update individual entities when they change.
        notifier bind ::mad <Vrel>  $self [mymethod uid]

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
        cond::availableSingle update [list $adjustbtn $inputbtn]
    }

    # AdjustSelected
    #
    # Called when the user wants to adjust the selected entity.

    method AdjustSelected {} {
        set id [lindex [$hull uid curselection] 0]

        order enter MAD:VREL:ADJUST id $id
    }

    # InputForSelected
    #
    # Called when the user wants to create an attitude input for
    # the selected entity.

    method InputForSelected {} {
        set id [lindex [$hull uid curselection] 0]
        lassign $id g a

        order enter MAD:VREL:INPUT g $g a $a
    }
}


