#-----------------------------------------------------------------------
# TITLE:
#    envsitbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    envsitbrowser(sim) package: Environmental Situation browser.
#
#    This widget displays a formatted list of envsits.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor envsitbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component editbtn     ;# The "Edit" button
    component resolvebtn  ;# The "Resolve" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   yes                         \
            -table        "gui_envsits"               \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 1                           \
            -displaycmd   [mymethod DisplayData]

        # FIRST, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using button $bar.add   \
            -image      ::projectgui::icon::plus22 \
            -relief     flat                   \
            -overrelief raised                 \
            -state      normal                 \
            -command    [mymethod AddEntity]

        DynamicHelp::add $addbtn -text "Add Situation"

        cond::orderIsValid control $addbtn \
            order SITUATION:ENVIRONMENTAL:CREATE

        pack $addbtn    -side left

        # NEXT, create the columns and labels.
        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Change}
        $hull insertcolumn end 0 {State}
        $hull insertcolumn end 0 {Type}
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {Coverage}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {Began At}
        $hull insertcolumn end 0 {Changed At}
        $hull insertcolumn end 0 {Caused By}
        $hull insertcolumn end 0 {Affects}
        $hull insertcolumn end 0 {Resolved By}
        $hull insertcolumn end 0 {Driver}
        $hull columnconfigure end -sortmode integer

        # NEXT, sort on column 0 by default
        $hull sortbycolumn 0 -increasing

        # NEXT, update individual entities when they change.
        notifier bind ::envsit <Entity> $self $self
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
            lappend fields $id $change $state $stype $n $coverage
            lappend fields $ts $tc $g $flist $resolver $driver

            $hull setdata $id $fields
        }
    }

    # AddEntity
    #
    # Called when the user wants to add a new entity

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter SITUATION:ENVIRONMENTAL:CREATE
    }
}

