#-----------------------------------------------------------------------
# TITLE:
#    coopbrowser_sim.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    coopbrowser(sim) package: Cooperation browser, Simulation Mode.
#
#    This widget displays a formatted list of uram_coop records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor coopbrowser_sim {
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
        { f        "Of Group"                   }
        { g        "With Group"                 }
        { coop     "Current"        -sortmode real -foreground %D }
        { base     "Baseline"       -sortmode real -foreground %D }
        { nat      "Natural"                       -foreground %D }
        { coop0    "Current at T0"  -sortmode real -foreground %D }
        { base0    "Baseline at T0" -sortmode real                }
        { nat0     "Natural at T0"                 -foreground %D }
    }

    #-------------------------------------------------------------------
    # Components

    component inputbtn      ;# The "Input" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_uram_coop               \
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

        install inputbtn using mktoolbutton $bar.input \
            ::marsgui::icon::pencil22                  \
            "Magic Cooperation Input"                  \
            -state   disabled                          \
            -command [mymethod InputForSelected]

        cond::availableSingle control $inputbtn \
            order   MAD:COOP:INPUT              \
            browser $win

        pack $inputbtn  -side left

        # NEXT, update individual entities when they change.
        notifier bind ::mad <Coop>  $self [mymethod uid]
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
        cond::availableSingle update [list $inputbtn]
    }

    # InputForSelected
    #
    # Called when the user wants to create an attitude input for
    # the selected entity.

    method InputForSelected {} {
        set id [lindex [$hull uid curselection] 0]
        lassign $id f g

        order enter MAD:COOP:INPUT f $f g $g
    }
}




