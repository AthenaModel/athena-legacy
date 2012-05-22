#-----------------------------------------------------------------------
# TITLE:
#    satbrowser_sim.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    satbrowser(sim) package: Satisfaction browser, Simulation Mode.
#
#    This widget displays a formatted list of URAM satisfaction curve 
#    records.  It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor satbrowser_sim {
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
        { g        "Group"                                        }
        { c        "Concern"                                      }
        { n        "Nbhood"                                       }
        { sat      "Current"        -sortmode real -foreground %D }
        { base     "Baseline"       -sortmode real -foreground %D }
        { nat      "Natural"                       -foreground %D }
        { sat0     "Current at T0"  -sortmode real -foreground %D }
        { base0    "Baseline at T0" -sortmode real                }
        { nat0     "Natural at T0"                 -foreground %D }
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
            -view         gui_uram_sat                \
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
            "Magic Adjust Satisfaction Baseline"            \
            -state   disabled                               \
            -command [mymethod AdjustSelected]

        cond::availableSingle control $adjustbtn \
            order   MAD:SAT:ADJUST               \
            browser $win

        install inputbtn using mktoolbutton $bar.input \
            ::marsgui::icon::pencili22              \
            "Magic Satisfaction Input"                 \
            -state   disabled                          \
            -command [mymethod InputForSelected]

        cond::availableSingle control $inputbtn \
            order   MAD:SAT:INPUT               \
            browser $win

        pack $adjustbtn -side left
        pack $inputbtn  -side left

        # NEXT, update individual entities when they change.
        notifier bind ::mad <Sat>  $self [mymethod uid]
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

        order enter MAD:SAT:ADJUST id $id
    }

    # InputForSelected
    #
    # Called when the user wants to create an attitude input for
    # the selected entity.

    method InputForSelected {} {
        set id [lindex [$hull uid curselection] 0]
        lassign $id g c

        order enter MAD:SAT:INPUT g $g c $c
    }
}






