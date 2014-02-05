#-----------------------------------------------------------------------
# TITLE:
#    econngbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    econngbrowser(sim) package: Nbhood Group economics
#    browser.
#
#    This widget displays a formatted list of demog_g records,
#    focussing on the labor statistics. It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor econngbrowser {
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
        { g           "Civ\nGroup"                                       }
        { longname    "Long\nName"                                      }
        { n           "\nNbhood"                                         }
        { population  "\nPop."           -sortmode integer -foreground %D }
        { subsistence "\nSubsist."       -sortmode integer -foreground %D }
        { consumers   "\nConsumers"      -sortmode integer -foreground %D }
        { labor_force "Labor\nForce"     -sortmode integer -foreground %D }
        { unemployed  "\nUnemployed"     -sortmode integer -foreground %D }
        { ur          "Unemp.\nRate%"    -sortmode real    -foreground %D }
        { aloc        "Actual\nLOC"      -sortmode real    -foreground %D }
        { eloc        "Expected\nLOC"    -sortmode real    -foreground %D }
        { rloc        "Required\nLOC"    -sortmode real    -foreground %D }
        { povpct      "\nPoverty%"       -sortmode real    -foreground %D }
    }

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_econ_g                  \
            -uid          id                          \
            -titlecolumns 1                           \
            -reloadon {
                ::sim <DbSyncB>
                ::demog <Update>
                ::rdb <nbhoods>
                ::rdb <groups>
                ::rdb <civgroups>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}


