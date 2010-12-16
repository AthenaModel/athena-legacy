#-----------------------------------------------------------------------
# TITLE:
#    demogbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    demogbrowser(sim) package: Nbhood Group Demographics browser.
#
#    This widget displays a formatted list of demog_g records,
#    focussing on the population statistics.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor demogbrowser {
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
        { g           "Group"                                       }
        { n           "Nbhood"                                      }
        { basepop     "BasePop"    -sortmode integer                }
        { population  "CurrPop"    -sortmode integer -foreground %D }
        { displaced   "Displaced"  -sortmode integer -foreground %D }
        { attrition   "Attrition"  -sortmode integer -foreground %D }
    }

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_civgroups               \
            -uid          id                          \
            -titlecolumns 1                           \
            -reloadon {
                ::sim <DbSyncB>
                ::demog <Update>
                ::rdb <nbhoods>
                ::rdb <civgroups>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}


