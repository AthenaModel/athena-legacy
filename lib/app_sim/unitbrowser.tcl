#-----------------------------------------------------------------------
# TITLE:
#    unitbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    unitbrowser(sim) package: Unit browser.
#
#    This widget displays a formatted list of unit records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor unitbrowser {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Create the button icons
        namespace eval ${type}::icon { }


        mkicon ${type}::icon::crosshair {
            ......................
            ......................
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ......................
            ......................
            ..XXXXXX..XX..XXXXXX..
            ..XXXXXX..XX..XXXXXX..
            ......................
            ......................
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }


        mkicon ${type}::icon::activity {
            ......................
            ......................
            ......................
            .........XXXX.........
            .........XXXX.........
            ........XXXXXX........
            ........XXXXXX........
            .......XXX..XXX.......
            .......XXX..XXX.......
            ......XXX....XXX......
            ......XXX....XXX......
            .....XXX......XXX.....
            .....XXX......XXX.....
            ....XXXXXXXXXXXXXX....
            ....XXXXXXXXXXXXXX....
            ...XXX..........XXX...
            ...XXX..........XXX...
            ..XXX............XXX..
            ..XXX............XXX..
            ......................
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }


        mkicon ${type}::icon::personnel {
            ......................
            ......................
            .........XXXX.........
            ........XXXXXX........
            ........XXXXXX........
            ........XXXXXX........
            .........XXXX.........
            .....XXXXXXXXXXXX.....
            ....XXXXXXXXXXXXXX....
            ....XX.XXXXXXXX.XX....
            ....XX.XXXXXXXX.XX....
            ....XX.XXXXXXXX.XX....
            ....XX.XXXXXXXX.XX....
            .......XXXXXXXX.......
            .......XXX..XXX.......
            .......XXX..XXX.......
            .......XXX..XXX.......
            .......XXX..XXX.......
            .......XXX..XXX.......
            ......................
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }

    }

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component movebtn     ;# The "Move" button
    component actbtn      ;# The "Activity" button
    component perbtn      ;# The "Personnel" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   yes                         \
            -table        "gui_units"                 \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 1                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        # Add Button
        install addbtn using button $bar.add   \
            -image      ::projectgui::icon::plus22 \
            -relief     flat                   \
            -overrelief raised                 \
            -state      normal                 \
            -command    [mymethod AddEntity]

        DynamicHelp::add $addbtn -text "Add Unit"

        cond::orderIsValid control $addbtn \
            order UNIT:CREATE


        # Activity Button
        install actbtn using button $bar.act         \
            -image      ${type}::icon::activity      \
            -relief     flat                         \
            -overrelief raised                       \
            -state      disabled                     \
            -command    [mymethod SetActivitySelected]

        DynamicHelp::add $actbtn -text "Set Activity for Selected Unit"

        cond::orderIsValidSingle control $actbtn     \
            order   UNIT:ACTIVITY                    \
            browser $win



        # Personnel Button
        install perbtn using button $bar.per         \
            -image      ${type}::icon::personnel     \
            -relief     flat                         \
            -overrelief raised                       \
            -state      disabled                     \
            -command    [mymethod SetPersonnelSelected]

        DynamicHelp::add $perbtn -text "Set Personnel for Selected Unit"

        cond::orderIsValidSingle control $perbtn    \
            order   UNIT:PERSONNEL                  \
            browser $win


        # Move Button
        install movebtn using button $bar.move       \
            -image      ${type}::icon::crosshair     \
            -relief     flat                         \
            -overrelief raised                       \
            -state      disabled                     \
            -command    [mymethod MoveSelected]

        DynamicHelp::add $movebtn -text "Move Selected Unit"

        cond::orderIsValidSingle control $movebtn    \
            order   UNIT:MOVE                        \
            browser $win


        # Delete Button
        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22    \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected Unit"

        cond::orderIsValidSingle control $deletebtn \
            order   UNIT:DELETE                     \
            browser $win

        
        pack $addbtn    -side left
        pack $actbtn    -side left
        pack $perbtn    -side left
        pack $movebtn   -side left
        pack $deletebtn -side right


        # NEXT, create the columns and labels.
        $hull insertcolumn end 0 {ID}
        $hull insertcolumn end 0 {GType}
        $hull insertcolumn end 0 {Group}
        $hull insertcolumn end 0 {Origin}
        $hull insertcolumn end 0 {Location}
        $hull insertcolumn end 0 {Nbhood}
        $hull insertcolumn end 0 {Personnel}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Activity}
        $hull insertcolumn end 0 {Effective}

        # NEXT, update individual entities when they change.
        notifier bind ::unit <Entity> $self $self
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
            $hull setdata $u \
                [list $u $gtype $g $origin $location $n $personnel $a \
                     $a_effective]
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidSingle update \
            [list $movebtn $actbtn $perbtn $deletebtn]

        # NEXT, notify the app of the selection.
        if {[llength [$hull curselection]] == 1} {
            set u [lindex [$hull curselection] 0]

            notifier send ::app <ObjectSelect> [list unit $u]
        }
    }


    # AddEntity
    #
    # Called when the user wants to add a new entity

    method AddEntity {} {
        # FIRST, Pop up the dialog
        order enter UNIT:CREATE
    }


    # MoveSelected
    #
    # Called when the user wants to move the selected unit

    method MoveSelected {} {
        set id [lindex [$hull curselection] 0]

        order enter UNIT:MOVE u $id
    }


    # SetActivitySelected
    #
    # Called when the user wants to set the unit's activity

    method SetActivitySelected {} {
        set id [lindex [$hull curselection] 0]

        order enter UNIT:ACTIVITY u $id
    }


    # SetPersonnelSelected
    #
    # Called when the user wants to set the unit's personnel

    method SetPersonnelSelected {} {
        set id [lindex [$hull curselection] 0]

        order enter UNIT:PERSONNEL u $id
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, Send the delete order.
        order send gui UNIT:DELETE u $id
    }
}

