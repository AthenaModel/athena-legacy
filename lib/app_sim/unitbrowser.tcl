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
#    It is a wrapper around sqlbrowser(n).
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
        } { . trans  X black } d { X gray }


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
        } { . trans  X black } d { X gray }


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
        } { . trans  X black } d { X gray }


        mkicon ${type}::icon::attrition {
            ......................
            ......................
            .......X........XXX...
            ......X.XXXX....XXX...
            ......X.XXXXXXXXXXX...
            .....X.XXXXXXXXXXXX...
            .....X.XXXXXXXXXXXX...
            .....X.XXXXXXXXXXXX...
            .....X.XXXXXXXXXXXX...
            ......X.XXXXX...XXX...
            ......X.XXX.....XXX...
            .......X.X......XXX...
            ........X.......XXX...
            ................XXX...
            ................XXX...
            ................XXX...
            ................XXX...
            ................XXX...
            ................XXX...
            ................XXX...
            ................XXX...
            ......................
            ......................
        } { . trans  X black } d { X gray }
    }

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Lookup Tables

    # Layout
    #
    # %D is replaced with the color for derived columns.

    typevariable layout {
        { u           "ID"                                         }
        { gtype       "GType"                                      } 
        { g           "Group"                                      }
        { origin      "Origin"                                     }
        { location    "Location"                                   }
        { n           "Nbhood"                      -foreground %D }
        { personnel   "Personnel" -sortmode integer                }
        { a           "Activity"                                   }
        { a_effective "Effective"                   -foreground %D }
    }

    #-------------------------------------------------------------------
    # Components

    component addbtn      ;# The "Add" button
    component movebtn     ;# The "Move" button
    component actbtn      ;# The "Activity" button
    component perbtn      ;# The "Personnel" button
    component attbtn      ;# The "Attrition" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using sqlbrowser                  \
            -db           ::rdb                       \
            -view         gui_units                   \
            -uid          id                          \
            -titlecolumns 1                           \
            -selectioncmd [mymethod SelectionChanged] \
            -reloadon {
                ::sim <Reconfigure>
                ::sim <Tick>
            } -layout [string map [list %D $::app::derivedfg] $layout]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        # Add Button
        install addbtn using mkaddbutton $bar.add \
            "Add Unit"                            \
            -state    normal                      \
            -command [mymethod AddEntity]

        cond::orderIsValid control $addbtn \
            order UNIT:CREATE


        # Activity Button
        install actbtn using mktoolbutton $bar.act \
            ${type}::icon::activity                \
            "Set Activity for Selected Unit"       \
            -state   disabled                      \
            -command [mymethod SetActivitySelected]

        cond::orderIsValidSingle control $actbtn     \
            order   UNIT:ACTIVITY                    \
            browser $win


        # Personnel Button
        install perbtn using mktoolbutton $bar.per   \
            ${type}::icon::personnel                 \
            "Set Personnel for Selected Unit"        \
            -state    disabled                       \
            -command [mymethod SetPersonnelSelected]

        cond::orderIsValidSingle control $perbtn    \
            order   UNIT:PERSONNEL                  \
            browser $win


        # Attrition Button
        install attbtn using mktoolbutton $bar.att \
            ${type}::icon::attrition               \
            "Attrit Selected Unit"                 \
            -state   disabled                      \
            -command [mymethod AttritSelected]

        cond::orderIsValidSingle control $attbtn    \
            order   ATTRIT:UNIT                     \
            browser $win


        # Move Button
        install movebtn using mktoolbutton $bar.move \
            ${type}::icon::crosshair                 \
            "Move Selected Unit"                     \
            -state   disabled                        \
            -command [mymethod MoveSelected]

        cond::orderIsValidSingle control $movebtn    \
            order   UNIT:MOVE                        \
            browser $win


        # Delete Button
        install deletebtn using mkdeletebutton $bar.delete \
            "Delete Selected Unit"                         \
            -state   disabled                              \
            -command [mymethod DeleteSelected]

        cond::orderIsValidSingle control $deletebtn \
            order   UNIT:DELETE                     \
            browser $win

        
        pack $addbtn    -side left
        pack $actbtn    -side left
        pack $perbtn    -side left
        pack $attbtn    -side left
        pack $movebtn   -side left
        pack $deletebtn -side right

        # NEXT, update individual entities when they change.
        notifier bind ::unit <Entity> $self [mymethod uid]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    #-------------------------------------------------------------------
    # Private Methods

    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidSingle update \
            [list $movebtn $actbtn $perbtn $attbtn $deletebtn]

        # NEXT, notify the app of the selection.
        if {[llength [$hull uid curselection]] == 1} {
            set u [lindex [$hull uid curselection] 0]

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
        set id [lindex [$hull uid curselection] 0]

        order enter UNIT:MOVE u $id
    }


    # SetActivitySelected
    #
    # Called when the user wants to set the unit's activity

    method SetActivitySelected {} {
        set id [lindex [$hull uid curselection] 0]

        order enter UNIT:ACTIVITY u $id
    }


    # SetPersonnelSelected
    #
    # Called when the user wants to set the unit's personnel

    method SetPersonnelSelected {} {
        set id [lindex [$hull uid curselection] 0]

        order enter UNIT:PERSONNEL u $id
    }


    # AttritSelected
    #
    # Called when the user wants to attrit the unit's personnel

    method AttritSelected {} {
        set id [lindex [$hull uid curselection] 0]

        order enter ATTRIT:UNIT u $id
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull uid curselection] 0]

        # NEXT, Send the delete order.
        order send gui UNIT:DELETE u $id
    }
}

