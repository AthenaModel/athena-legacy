#-----------------------------------------------------------------------
# TITLE:
#    nbcoopbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    nbcoopbrowser(sim) package: Nbhood Cooperation browser.
#
#    This widget displays a formatted list of gram_frc_ng records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor nbcoopbrowser {
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
            -table        "gui_coop_ng"               \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 3                           \
            -displaycmd   [mymethod DisplayData]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $g", but
        # we don't want to display it.

        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -hide yes
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {With Group}
        $hull insertcolumn end 0 {Coop at T0}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {Coop Now}
        $hull columnconfigure end -sortmode real

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
            $hull setdata $id \
                [list $id $n $g $coop0 $coop]
        }
    }
}

