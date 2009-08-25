#-----------------------------------------------------------------------
# TITLE:
#    satbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    satbrowser(sim) package: Satisfaction browser.
#
#    This widget displays a formatted list of satisfaction curve records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor satbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    component editbtn     ;# The "Edit" button
    component setbtn      ;# The "Set" button
    component adjbtn      ;# The "Adjust" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   yes                         \
            -table        "gui_sat_ngc"               \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 4                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using button $bar.edit   \
            -image      ::projectgui::icon::pencil022 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Initial Curve"

        cond::orderIsValidMulti control $editbtn \
            order   SAT:UPDATE          \
            browser $win

       
        install setbtn using button $bar.set   \
            -image      ::projectgui::icon::pencils22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod SetSelected]

        DynamicHelp::add $setbtn -text "Magic Set Satisfaction Level"

        cond::orderIsValidSingle control $setbtn \
            order   MAD:SAT:SET                  \
            browser $win
       

        install adjbtn using button $bar.adj   \
            -image      ::projectgui::icon::pencila22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod AdjustSelected]

        DynamicHelp::add $adjbtn -text "Magic Adjust Satisfaction Level"

        cond::orderIsValidSingle control $adjbtn \
            order   MAD:SAT:ADJUST               \
            browser $win
       
        pack $editbtn   -side left
        pack $setbtn    -side left
        pack $adjbtn    -side left

        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $g", but
        # we don't want to display it.

        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -hide yes
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {Group}
        $hull insertcolumn end 0 {Concern}
        $hull insertcolumn end 0 {Sat at T0}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {Sat Now}
        $hull columnconfigure end \
            -sortmode   real      \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {Trend}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {Saliency}
        $hull columnconfigure end -sortmode real

        # NEXT, sort on column 1 by default
        $hull sortbycolumn 1 -increasing

        # NEXT, update individual entities when they change.
        notifier bind ::sat <Entity> $self $self
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
    # dict   the data dictionary that contains the group information
    #
    # This method converts the group data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            set id [list $n $g $c]

            $hull setdata $id \
                [list $id $n $g $c $sat0 $sat $trend0 $saliency]
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidMulti update $editbtn
        cond::orderIsValidSingle update [list $setbtn $adjbtn]

        # NEXT, if there's exactly one item selected, notify the
        # the app.
        if {[llength [$hull curselection]] == 1} {
            set id [lindex [$hull curselection] 0]
            lassign $id n g c

            notifier send ::app <ObjectSelect> \
                [list ngc $id  nbhood $n group $g concern $c]
        }
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities

    method EditSelected {} {
        set ids [$hull curselection]

        if {[llength $ids] == 1} {
            lassign [lindex $ids 0] n g c

            order enter SAT:UPDATE n $n g $g c $c
        } else {
            order enter SAT:UPDATE:MULTI ids $ids
        }
    }


    # SetSelected
    #
    # Called when the user wants to set the selected level

    method SetSelected {} {
        set ids [$hull curselection]

        lassign [lindex $ids 0] n g c

        order enter MAD:SAT:SET n $n g $g c $c
    }

    # AdjustSelected
    #
    # Called when the user wants to adjust the selected level

    method AdjustSelected {} {
        set ids [$hull curselection]

        lassign [lindex $ids 0] n g c

        order enter MAD:SAT:ADJUST n $n g $g c $c
    }
}





