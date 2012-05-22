#-----------------------------------------------------------------------
# TITLE:
#    hrelbrowser_sim.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    hrelbrowser(sim) package: Relationship browser.
#
#    This widget displays the simulation's current HREL values.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor hrelbrowser_sim {
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
        {f        "Of Group F"                                   }
        {g        "With Group G"                                 }
        {ftype    "F Type"                                       }
        {gtype    "G Type"                                       }
        {hrel     "Current"        -sortmode real -foreground %D }
        {base     "Baseline"       -sortmode real -foreground %D }
        {nat      "Natural"        -sortmode real -foreground %D }
        {hrel0    "Current at T0"  -sortmode real -foreground %D }
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
            -view         gui_uram_hrel               \
            -uid          id                          \
            -titlecolumns 2                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <Tick>
                ::sim <DbSyncB>
                ::parm <Update>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install adjustbtn using mktoolbutton $bar.adjust    \
            ::marsgui::icon::pencila22                   \
            "Magic Adjust Horizontal Relationship Baseline" \
            -state   disabled                               \
            -command [mymethod AdjustSelected]

        cond::availableSingle control $adjustbtn \
            order   MAD:HREL:ADJUST              \
            browser $win

        install inputbtn using mktoolbutton $bar.input \
            ::marsgui::icon::pencili22              \
            "Magic Horizontal Relationship Input"      \
            -state   disabled                          \
            -command [mymethod InputForSelected]

        cond::availableSingle control $inputbtn \
            order   MAD:HREL:INPUT               \
            browser $win

        pack $adjustbtn -side left
        pack $inputbtn  -side left

        # NEXT, update individual entities when they change.
        notifier bind ::mad <Hrel>  $self [mymethod uid]
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

        order enter MAD:HREL:ADJUST id $id
    }

    # InputForSelected
    #
    # Called when the user wants to create an attitude input for
    # the selected entity.

    method InputForSelected {} {
        set id [lindex [$hull uid curselection] 0]
        lassign $id f g

        order enter MAD:HREL:INPUT f $f g $g
    }
}


