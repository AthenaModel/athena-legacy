#-----------------------------------------------------------------------
# TITLE:
#    defroebrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    defroebrowser(sim) package: Defending ROE browser.
#
#    This widget displays a formatted list of gui_defroe_view records.
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor defroebrowser {
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
        {n        "Nbhood"     }
        {g        "Group"      }
        {roe      "ROE"        }
        {override "OV" -hide 1 }
    }

    #-------------------------------------------------------------------
    # Components

    # None

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_defroe_view             \
            -uid          id                          \
            -titlecolumns 2                           \
            -displaycmd   [mymethod DisplayData]      \
            -reloadon {
                ::rdb <nbhoods>
                ::rdb <frcgroups>
                ::sim <DbSyncB>
                ::sim <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <defroe_ng> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # When defroe_ng records are deleted, treat it like an update.
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
        set override [lindex $values 3]

        if {$override} {
            $hull rowconfigure $rindex -foreground "#BB0000"
        } else {
            $hull rowconfigure $rindex -foreground $::app::derivedfg
        }
    }
}











