#-----------------------------------------------------------------------
# TITLE:
#    nbgroupbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    nbgroupbrowser(sim) package: Nbhood Group browser.
#
#    This widget displays a formatted list of nbhood group records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor nbgroupbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component editbtn     ;# The "Edit" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   yes                         \
            -table        "gui_nbgroups"              \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 3                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # FIRST, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install addbtn using button $bar.add       \
            -image      ::projectgui::icon::plus22 \
            -relief     flat                       \
            -overrelief raised                     \
            -state      normal                     \
            -command    [mymethod AddEntity]

        DynamicHelp::add $addbtn -text "Add Nbhood Group"

        cond::orderIsValid control $addbtn \
            order GROUP:NBHOOD:CREATE


        install editbtn using button $bar.edit       \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                         \
            -overrelief raised                       \
            -state      disabled                     \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Group"

        cond::orderIsValidMulti control $editbtn \
            order   GROUP:NBHOOD:UPDATE          \
            browser $win


        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22    \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected Group"

        cond::orderIsValidSingle control $deletebtn \
            order   GROUP:NBHOOD:DELETE             \
            browser $win

        
        pack $addbtn    -side left
        pack $editbtn   -side left
        pack $deletebtn -side right


        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $g", but
        # we don't want to display it.

        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -hide yes
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {CivGroup}
        $hull insertcolumn end 0 {Local Name}
        $hull insertcolumn end 0 {BasePop}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Mood at T0}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {Mood Now}
        $hull columnconfigure end \
            -sortmode   real      \
            -foreground $::browser_base::derivedfg
        $hull insertcolumn end 0 {Demeanor}
        $hull insertcolumn end 0 {RollupWeight}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {EffectsFactor}
        $hull columnconfigure end -sortmode real

        # NEXT, sort on column 1 by default
        $hull sortbycolumn 1 -increasing

        # NEXT, update individual entities when they change.
        notifier bind ::nbgroup <Entity> $self $self
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
                [list $id $n $g $local_name $basepop $mood0 $mood \
                     $demeanor $rollup_weight $effects_factor]
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidSingle update $deletebtn
        cond::orderIsValidMulti  update $editbtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull curselection]] == 1} {
            set id [lindex [$hull curselection] 0]
            lassign $id n g

            notifier send ::app <ObjectSelect> \
                [list ng $id nbhood $n group $g]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity.

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter GROUP:NBHOOD:CREATE
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities.

    method EditSelected {} {
        set ids [$hull curselection]

        if {[llength $ids] == 1} {
            lassign [lindex $ids 0] n g

            order enter GROUP:NBHOOD:UPDATE n $n g $g
        } else {
            order enter GROUP:NBHOOD:UPDATE:MULTI ids $ids
        }
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        lassign [lindex [$hull curselection] 0] n g

        # NEXT, Pop up the dialog, and select this entity
        order send gui GROUP:NBHOOD:DELETE n $n g $g
    }
}

