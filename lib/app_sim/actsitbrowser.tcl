#-----------------------------------------------------------------------
# TITLE:
#    actsitbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    actsitbrowser(sim) package: Activity Situation browser.
#
#    This widget displays a formatted list of actsits.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor actsitbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    # None

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   yes                         \
            -table        "gui_actsits_current"       \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 1                           \
            -displaycmd   [mymethod DisplayData]      \
            -views        {
                "All"      gui_actsits
                "Current"  gui_actsits_current
                "Ended"    gui_actsits_ended
            }

        # FIRST, get the options.
        $self configurelist $args

        # NEXT, create the columns and labels.

        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Change}
        $hull columnconfigure end \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {State}
        $hull columnconfigure end \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {Type}
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {Group}
        $hull insertcolumn end 0 {Activity}
        $hull insertcolumn end 0 {Coverage}
        $hull columnconfigure end \
            -sortmode   real      \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {Began At}
        $hull columnconfigure end \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {Changed At}
        $hull columnconfigure end \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {Driver}
        $hull columnconfigure end \
            -sortmode   integer   \
            -foreground $::browser_base::derivedfg

        # NEXT, sort on column 0 by default
        $hull sortbycolumn 0 -increasing
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

    # DisplayData dict
    # 
    # dict   the data dictionary that contains the entity information
    #
    # This method converts the entity data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            lappend fields $id $change $state $stype $n $g $a
            lappend fields $coverage $ts $tc $driver

            $hull setdata $id $fields
        }
    }
}

