#-----------------------------------------------------------------------
# TITLE:
#    attritbrowser.tcl
#
# AUTHORS:
#    Dave Hanks
#
# DESCRIPTION:
#    attritbrowser(sim) package: Magic Attrition browser.
#
#    This widget displays a formatted list of magic attrition requests. 
#    It is a wrapper around sqlbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor attritbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    # Layout
    #

    typevariable layout {
        { id         "ID"                  -sortmode integer }
        { narrative  "Description"                           }
        { casualties "Casualties"          -sortmode integer }
        { g1         "Responsible Group 1"                   }
        { g2         "Responsible Group 2"                   }
    }

    #-------------------------------------------------------------------
    # Components

    component nbhoodbtn ;# The "Attrit Nbhood" button
    component groupbtn  ;# The "Attrit Group" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_magic_attrit            \
            -uid          id                          \
            -titlecolumns 1                           \
            -layout       $layout                     \
            -reloadon {
                ::sim <DbSyncB>
                ::sim <Tick>
            }

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install nbhoodbtn using mktoolbutton $bar.nbhood \
            ::marsgui::icon::poly                        \
            "Attrit Nbhood"                              \
            -state   normal                              \
            -command [mymethod AttritNbhood]

        cond::available control $nbhoodbtn \
            order ATTRIT:NBHOOD

        install groupbtn using mktoolbutton $bar.group   \
            ::marsgui::icon::gpoly                       \
            "Attrit Group"                               \
            -state   normal                              \
            -command [mymethod AttritGroup]

        cond::available control $groupbtn \
            order ATTRIT:GROUP

        pack $nbhoodbtn -side left
        pack $groupbtn  -side left

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <magic_attrit> $self [mymethod uid]
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

    # AttritNbhood
    #
    # Called when the user wants to magically attrit a neighborhood

    method AttritNbhood {} {
        # FIRST, Pop up the dialog
        order enter ATTRIT:NBHOOD
    }

    # AttritGroup
    #
    # Called when the user wants to magically attrit a group

    method AttritGroup {} {
        # FIRST, Pop up the dialog
        order enter ATTRIT:GROUP
    }
}


