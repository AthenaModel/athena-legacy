#-----------------------------------------------------------------------
# TITLE:
#    nbhoodbrowser.tcl
#
# AUTHORS:
#    Dave Hanks,
#    Will Duquette
#
# DESCRIPTION:
#    nbhoodbrowser(sim) package: Neighborhood browser.
#
#    This widget displays a formatted list of neighborhood records.
#    Entries in the list are managed by the tablebrowser(n).  
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

#-----------------------------------------------------------------------
# Widget Definition

snit::widget nbhoodbrowser {

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    # Options delegated to the tablebrowser
    delegate method * to tb

    #-------------------------------------------------------------------
    # Components

    component tb    ;# tablebrowser(n) used to browse nbhoods

    #--------------------------------------------------------------------
    # Instance Variables

    # TBD

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options.
        $self configurelist $args

        # NEXT, create the table browser
        install tb using tablebrowser $win.tb   \
            -db          ::rdb                  \
            -table       "nbhoods"              \
            -keycol      "n"                    \
            -keycolnum   0                      \
            -width       100                    \
            -displaycmd  [mymethod DisplayData]

        # NEXT, create the columns and labels.
        $tb insertcolumn end 0 {ID}
        $tb insertcolumn end 0 {Neighborhood}
        $tb insertcolumn end 0 {Urbanization}
        $tb insertcolumn end 0 {StkOrd}
        $tb columnconfigure end -sortmode integer
        $tb insertcolumn end 0 {Obscured}
        $tb insertcolumn end 0 {RefPoint}
        $tb insertcolumn end 0 {Polygon}

        # NEXT, the last column fills extra space
        $tb columnconfigure end -stretchable yes

        # NEXT, set the default sort column and direction
        $tb sortbycolumn 0 -increasing

        # NEXT, pack the tablebrowser and let it expand
        pack $win.tb -expand yes -fill both

        # NEXT, prepare to update on data change
        notifier bind ::scenario <Reconfigure> $self [mymethod Refresh]

        notifier bind ::nbhood <NbhoodCreated> $self [mymethod create]
        notifier bind ::nbhood <NbhoodChanged> $self [mymethod update]
        notifier bind ::nbhood <NbhoodDeleted> $self [mymethod delete]
        notifier bind ::nbhood <NbhoodLowered> $self [mymethod Refresh]
        notifier bind ::nbhood <NbhoodRaised>  $self [mymethod Refresh]

        # NEXT, reload on creation
        $self reload
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Private Methods

    # Refresh args
    #
    # args    Dummy args; ignored
    #
    # Reloads all data items.  Just calls "reload"; but can be used for
    # events that include arguments.

    method Refresh {args} {
        $self reload
    }

    

    # DisplayData dict
    # 
    # dict   the data dictionary that contains the nbhood information
    #
    # This method converts the nbhood data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            $tb setdata $n [list \
                                $n                             \
                                $longname                      \
                                $urbanization                  \
                                [format "%3d" $stacking_order] \
                                $obscured                      \
                                [map m2ref {*}$refpoint]       \
                                [map m2ref {*}$polygon]        ]
                                
        }
    }

}

