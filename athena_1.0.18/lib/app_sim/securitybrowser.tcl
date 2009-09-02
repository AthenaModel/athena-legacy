#-----------------------------------------------------------------------
# TITLE:
#    securitybrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    securitybrowser(sim) package: Group Security browser.
#
#    This widget displays a formatted list of force_ng records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor securitybrowser {
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
            -table        "gui_security"              \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 3                           \
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
        $hull insertcolumn end 0 {Security}
        $hull columnconfigure end \
            -sortmode   integer   \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {%Force}
        $hull columnconfigure end \
            -sortmode   integer   \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {%Enemy}
        $hull columnconfigure end \
            -sortmode   integer   \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {Volatility}
        $hull columnconfigure end \
            -sortmode   integer   \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {VtyGain}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {NomVty}
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

            lappend fields $id $n $g
            lappend fields \
                [format "%3d, %s" $security [qsecurity longname $security]]
            lappend fields $pct_force $pct_enemy $volatility
            lappend fields $volatility_gain $nominal_volatility

            $hull setdata $id $fields
        }
    }
}

