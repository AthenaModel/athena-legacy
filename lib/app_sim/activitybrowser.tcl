#-----------------------------------------------------------------------
# TITLE:
#    activitybrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    activitybrowser(sim) package: Unit Activity browser.
#
#    This widget displays a formatted list of activity_nga records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor activitybrowser {
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
            -table        "gui_activity_nga"          \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 4                           \
            -displaycmd   [mymethod DisplayData]

        # FIRST, get the options.
        $self configurelist $args

        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $g", but
        # we don't want to display it.

        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -hide yes
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {Group}
        $hull insertcolumn end 0 {Activity}
        $hull insertcolumn end 0 {Coverage}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {SecFlag}
        $hull insertcolumn end 0 {NomPers}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {ActPers}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {EffPers}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {SitType}
        $hull insertcolumn end 0 {Driver}
        $hull columnconfigure end -sortmode integer


        # NEXT, sort on column 1 by default
        $hull sortbycolumn 1 -increasing
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
            set id [list $n $g]

            lappend fields $id $n $g $a $coverage $security_flag
            lappend fields $nominal $active $effective
            lappend fields $stype $driver

            $hull setdata $id $fields
        }
    }
}

