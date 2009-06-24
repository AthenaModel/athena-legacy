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
#    This widget displays a formatted list of demog_ng records.
#    It is a variation of browser_base(n).
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
    # Components

    # TBD

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   no                          \
            -table        "gui_nbgroups"              \
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
        $hull insertcolumn end 0 {CivGroup}
        $hull insertcolumn end 0 {Local Name}

        $hull insertcolumn end 0 {BasePop}
        $hull columnconfigure end \
            -sortmode integer

        $hull insertcolumn end 0 {CurrPop}
        $hull columnconfigure end \
            -sortmode integer     \
            -foreground $::browser_base::derivedfg

        $hull insertcolumn end 0 {Implicit}
        $hull columnconfigure end \
            -sortmode integer     \
            -foreground $::browser_base::derivedfg

        $hull insertcolumn end 0 {Explicit}
        $hull columnconfigure end \
            -sortmode integer     \
            -foreground $::browser_base::derivedfg

        $hull insertcolumn end 0 {Displaced}
        $hull columnconfigure end \
            -sortmode integer     \
            -foreground $::browser_base::derivedfg

        $hull insertcolumn end 0 {Attrition}
        $hull columnconfigure end \
            -sortmode integer     \
            -foreground $::browser_base::derivedfg

        # NEXT, sort on column 1 by default
        $hull sortbycolumn 1 -increasing

        # NEXT, Respond to simulation updates
        notifier bind ::demog   <Update> $self [mymethod reload]
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

            $hull setdata $id \
                [list $id $n $g $local_name $basepop $population \
                     $implicit $explicit $displaced $attrition]
        }
    }
}

