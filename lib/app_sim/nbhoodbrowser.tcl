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
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor nbhoodbrowser {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Create the button icons
        namespace eval ${type}::icon { }


        mkicon ${type}::icon::lower {
            ......................
            ......................
            ......................
            ......................
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ....XX....XX....XX....
            .....XX...XX...XX.....
            ......XX..XX..XX......
            .......XX.XX.XX.......
            ........XXXXXX........
            .........XXXX.........
            ..........XX..........
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ......................
            ......................
        } {
            .  trans
            X  #000000
        }

        mkicon ${type}::icon::raise {
            ......................
            ......................
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ..........XX..........
            .........XXXX.........
            ........XXXXXX........
            .......XX.XX.XX.......
            ......XX..XX..XX......
            .....XX...XX...XX.....
            ....XX....XX....XX....
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ..........XX..........
            ......................
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

    component editbtn     ;# The "Edit" button
    component raisebtn    ;# The "Bring to Front" button
    component lowerbtn    ;# The "Send to Back" button
    component deletebtn   ;# The "Delete" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -tickreload   yes                         \
            -table        "gui_nbhoods"               \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 1                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using button $bar.edit   \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Neighborhood"

        # Assumes that *:UPDATE and *:UPDATE:MULTI always have the
        # the same validity.
        cond::orderIsValidMulti control $editbtn \
            order   NBHOOD:UPDATE                \
            browser $win


        install raisebtn using button $bar.raise  \
            -image      ${type}::icon::raise      \
            -relief     flat                      \
            -overrelief raised                    \
            -state      disabled                  \
            -command    [mymethod RaiseSelected]

        DynamicHelp::add $raisebtn -text "Bring Neighborhood to Front"

        cond::orderIsValidSingle control $raisebtn \
            order   NBHOOD:RAISE                   \
            browser $win


        install lowerbtn using button $bar.lower  \
            -image      ${type}::icon::lower      \
            -relief     flat                      \
            -overrelief raised                    \
            -state      disabled                  \
            -command    [mymethod LowerSelected]

        DynamicHelp::add $lowerbtn -text "Send Neighborhood to Back"

        cond::orderIsValidSingle control $lowerbtn \
            order   NBHOOD:LOWER                   \
            browser $win


        install deletebtn using button $bar.delete \
            -image      ::projectgui::icon::x22        \
            -relief     flat                       \
            -overrelief raised                     \
            -state      disabled                   \
            -command    [mymethod DeleteSelected]

        DynamicHelp::add $deletebtn -text "Delete Selected Neighborhood"

        cond::orderIsValidSingle control $deletebtn \
            order   NBHOOD:DELETE                   \
            browser $win

        pack $editbtn   -side left
        pack $raisebtn  -side left
        pack $lowerbtn  -side left
        pack $deletebtn -side right

        # NEXT, create the columns and labels.
        $hull insertcolumn end 0 {ID}
        $hull insertcolumn end 0 {Neighborhood}
        $hull insertcolumn end 0 {Urbanization}
        $hull insertcolumn end 0 {Population}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {Mood at T0}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {Mood Now}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {VtyGain}
        $hull columnconfigure end -sortmode real
        $hull insertcolumn end 0 {Vty}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {StkOrd}
        $hull columnconfigure end -sortmode integer
        $hull insertcolumn end 0 {ObscuredBy}
        $hull insertcolumn end 0 {RefPoint}
        $hull insertcolumn end 0 {Polygon}

        # NEXT, the last column fills extra space
        $hull columnconfigure end -stretchable yes

        # NEXT, update individual entities when they change.
        notifier bind ::nbhood <Entity> $self $self
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # stack
    #
    # Reloads all data items when the neighborhood stacking order
    # changes in response to "<Entity> stack"

    method stack {} {
        $self reload
    }

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
            $hull setdata $n [list \
                                $n                             \
                                $longname                      \
                                $urbanization                  \
                                $population                    \
                                $mood0                         \
                                $mood                          \
                                $vtygain                       \
                                $volatility                    \
                                [format "%3d" $stacking_order] \
                                $obscured_by                   \
                                $refpoint                      \
                                $polygon                       ]
                                
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidSingle update [list $deletebtn $lowerbtn $raisebtn]
        cond::orderIsValidMulti  update $editbtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull curselection]] == 1} {
            set n [lindex [$hull curselection] 0]

            notifier send ::app <ObjectSelect> \
                [list nbhood $n]
        }
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entity

    method EditSelected {} {
        set ids [$hull curselection]

        if {[llength $ids] == 1} {
            set id [lindex $ids 0]

            order enter NBHOOD:UPDATE n $id
        } else {
            order enter NBHOOD:UPDATE:MULTI ids $ids
        }
    }


    # RaiseSelected
    #
    # Called when the user wants to raise the selected neighborhood.

    method RaiseSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, bring it to the front.
        order send gui NBHOOD:RAISE [list n $id]
    }


    # LowerSelected
    #
    # Called when the user wants to lower the selected neighborhood.

    method LowerSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, bring it to the front.
        order send gui NBHOOD:LOWER [list n $id]
    }


    # DeleteSelected
    #
    # Called when the user wants to delete the selected entity.

    method DeleteSelected {} {
        # FIRST, there should be only one selected.
        set id [lindex [$hull curselection] 0]

        # NEXT, Send the order.
        order send gui NBHOOD:DELETE n $id
    }
}

