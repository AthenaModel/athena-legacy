#-----------------------------------------------------------------------
# TITLE:
#    orderdialog.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Order GUI Manager.  This module is responsible for creating and
#    managing orderdialog(sim) widgets.
#
#    This module sends the <OrderEntry> event to indicate what kind
#    of parameter is currently being entered.  Because this is a submodule
#    of ::order, ::order is the subject.
#
#-----------------------------------------------------------------------

snit::widget orderdialog {
    #===================================================================
    # Type Constructor: Type Icons

    typeconstructor {
        mkicon ${type}::error_x {
            XX......XX
            XXX....XXX
            .XXX..XXX.
            ..XXXXXX..
            ...XXXX...
            ...XXXX...
            ..XXXXXX..
            .XXX..XXX.
            XXX....XXX
            XX......XX
        } {
            X red
            . trans
        }

        mkicon ${type}::left_arrow {
            ....XX....
            ...XXX....
            ..XXX.....
            .XXX......
            XXXXXXXXXX
            XXXXXXXXXX
            .XXX......
            ..XXX.....
            ...XXX....
            ....XX....
        } {
            X black
            . trans
        }

        mkicon ${type}::blank10x10 {
            ..........
            ..........
            ..........
            ..........
            ..........
            ..........
            ..........
            ..........
            ..........
            ..........
        } {
            X black
            . trans
        }
    }



    #===================================================================
    # Dialog Management
    #
    # This section contains code that manages the collection of dialogs.
    # The actual dialog code appears below.

    #-------------------------------------------------------------------
    # Type Variables

    # Scalars, etc.
    #
    # initialized      1 if initialized, 0 otherwise.
    # wincounter       Counter for creating widget names.
    # win-$order       The dialog's widget name.  We reuse the same name
    #                  over and over.
    # position-$order  The dialog's saved geometry (i.e., screen position)

    typevariable info -array {
        initialized   0
        wincounter    0
    }

    #-------------------------------------------------------------------
    # Initialization

    # init
    #
    # Initializes the order GUI.

    typemethod init {} {
        # FIRST, create the necessary fonts.
        # TBD: This probably shouldn't go here, but it needs to go 
        # somewhere.
        font create OrderTitleFont {*}[font actual TkDefaultFont] \
            -weight bold                                          \
            -size   -16

        # NEXT, create the initial order dialog names
        foreach order [order names] {
            $type InitOrderData $order
        }

        # NEXT, note that we're initialized
        set info(initialized) 1
        
        log detail orderdlg "Initialized"
    }

    # InitOrderData order
    #
    # order     Name of an order
    #
    # Initializes the window name, etc.

    typemethod InitOrderData {order} {
        set info(win-$order)      .order[format %04d [incr info(wincounter)]]
        set info(position-$order) {}
    }

    
    #-------------------------------------------------------------------
    # Order Entry

    # enter order ?parmdict?
    # enter order ?parm value...?
    #
    # order       The name of the order
    # parmdict    A (partial) dictionary of initial parameter values
    # parm,value  A (partial) dictionary of initial parm values specified
    #             as individual arguments.
    #
    # Begins entry of the specified order:
    #
    # * If the order is not active, the dialog is created with the
    #   initial parmdict, and popped up.
    #
    # * If the order is active, it is given the initial parmdict, and
    #   then receives focus and raised to the top.

    typemethod enter {order args} {
        require {$info(initialized)}    "$type is uninitialized."
        require {[order exists $order]} "Undefined order: \"$order\""

        # FIRST, get the initial parmdict.
        if {[llength $args] > 1} {
            set parmdict $args
        } else {
            set parmdict [lindex $args 0]
        }

        # NEXT, if this is a new order, initialize its data.
        if {![info exists info(win-$order)]} {
            $type InitOrderData $order
        }

        # NEXT, if it doesn't exist, create it.
        #
        # MOTE: If at some point we need special dialogs for some
        # orders, we can add a query to order metadata here.

        if {![$type isactive $order]} {
            # FIRST, Create the dialog for the specified order
            orderdialog $info(win-$order) \
                -order $order
        }

        # NEXT, give the parms and the focus
        $info(win-$order) EnterDialog $parmdict

    }


    #-------------------------------------------------------------------
    # Queries

    # isactive order
    #
    # order    Name of an order
    #
    # Returns true if the order's dialog is active, and false otherwise.

    typemethod isactive {order} {
        return [winfo exists $info(win-$order)]
    }

    # topwin
    #
    # Returns the name of the topmost order dialog

    typemethod topwin {} {
        foreach w [lreverse [wm stackorder .]] {
            if {[winfo class $w] eq "Orderdialog"} {
                return $w
            }
        }

        return ""
    }


    #===================================================================
    # Dialog Widget
    #
    # Each order has a widget of this type.

    hulltype toplevel

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -order order
    #
    # The name of the order for this dialog.

    option -order     \
        -readonly yes

    #-------------------------------------------------------------------
    # Instance Variables

    # my array -- scalars and field data
    #
    # parms             Names of all parms.
    # multi             Name of "multi" parm, or ""
    # keys              Names of "key" parms, or {}
    # nonkeys           Names of non-key parms, or {}
    # table             Name of associated RDB table/view, or ""
    # current           Name of current parameter, or ""
    # saved             Dictionary of "saved" field values
    # field-$parm       Name of field widget
    # icon-$parm        Name of status icon widget

    variable my -array {
        parms    {}
        multi    ""
        keys     {}
        nonkeys  {}
        table    ""
        current  ""
        saved    {}
    }

    # ferrors -- Array of field errors by parm name
    
    variable ferrors -array { }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options
        $self configurelist $args

        # NEXT, withdraw the hull; we will deiconify at the end of the
        # constructor.
        wm withdraw $win
        
        # NEXT, set up the window manager details

        # Title
        wm title $win "Athena [version]: Send Order"
        
        # User can't resize it
        wm resizable $win 0 0

        # Control closing the window
        wm protocol $win WM_DELETE_WINDOW [mymethod Close]

        # NEXT, create the title widget
        ttk::label $win.title                             \
            -font          OrderTitleFont                 \
            -text          [order title $options(-order)] \
            -anchor        center                         \
            -padding       4

        # NEXT, create the frame to hold the fields
        ttk::frame $win.fields  \
            -borderwidth 1      \
            -relief      raised \
            -padding     2
        
        grid columnconfigure $win.fields 1 -weight 1

        # NEXT, create the fields
        $self CreateParameterFields

        # NEXT, create the message display
        rotext $win.message                                \
            -takefocus          0                          \
            -font               TkDefaultFont              \
            -width              40                         \
            -height             3                          \
            -wrap               word                       \
            -relief             flat                       \
            -background         [$win cget -background]    \
            -highlightthickness 0

        # NEXT, create the frame to hold the buttons
        ttk::frame $win.buttons \
            -borderwidth 0      \
            -relief      flat

        ttk::button $win.buttons.help         \
            -text    "Help"                   \
            -width   6                        \
            -command [mymethod Help]

        label $win.buttons.spacer             \
            -text "   "

        ttk::button $win.buttons.close        \
            -text    "Close"                  \
            -width   6                        \
            -command [mymethod Close]

        ttk::button $win.buttons.clear        \
            -text    "Clear"                  \
            -width   6                        \
            -command [mymethod Clear]

        ttk::button $win.buttons.send         \
            -text    "Send"                   \
            -width   6                        \
            -command [mymethod Send]

        ttk::button $win.buttons.sendclose    \
            -text    "Send and Close"         \
            -width   14                       \
            -command [mymethod SendClose]


        pack $win.buttons.help      -side left  -padx 2
        pack $win.buttons.spacer    -side left

        pack $win.buttons.sendclose -side right -padx 2
        pack $win.buttons.send      -side right -padx 2
        pack $win.buttons.clear     -side right -padx 2
        pack $win.buttons.close     -side right -padx 2


        # NEXT, pack components
        pack $win.title   -side top -fill x
        pack $win.fields  -side top -fill x -padx 4 -pady 4
        pack $win.message -side top -fill x
        pack $win.buttons -side top -fill x

        # NEXT, make the window visible, and transient over the
        # current top window.
        wm transient $win .main 
        wm attributes $win -topmost 1
        wm deiconify $win
        raise $win

        # NEXT, if there's saved position, give the dialog the
        # position.
        if {$info(position-$options(-order)) ne ""} {
            wm geometry \
                $info(win-$options(-order)) \
                $info(position-$options(-order))
        }
        
        # NEXT, prepare to receive selected objects from the application.
        notifier bind ::app <ObjectSelect> $win [mymethod ObjectSelect]

        # NEXT, save the current (empty) values, so that EnterDialog
        # won't complain about them.
        $self MarkSaved

        # NEXT, wait for visibility.
        update idletasks
    }

    destructor {
        notifier forget $win
    }

    # CreateParameterFields
    #
    # Creates the data entry fields

    method CreateParameterFields {} {
        # FIRST, save some variables
        set order     $options(-order)
        set my(parms) [order parms $order]
        set my(table) [order cget $order -table]

        # NEXT, Create the fields
        set row    -1
        set keyrow -1

        foreach parm $my(parms) {
            # FIRST, get the parameter dictionary
            set pdict [order parm $order $parm]

            # NEXT, get the field type
            set ftype [dict get $pdict -fieldtype]

            # NEXT, get the current grid row, and see if we need to 
            # insert a separator before the non-key fields
            incr row

            if {$ftype eq "key"} {
                set keyrow [expr {$row + 1}]
            } elseif {$row == $keyrow} {
                # Add the separator and move on
                ttk::label $win.fields.label$row -text " "
                grid $win.fields.label$row -column 0

                incr row
            }

            # NEXT, create the label widget.
            ttk::label $win.fields.label$row \
                -text   "[dict get $pdict -label]:"

            # NEXT, create the field widget
            set my(field-$parm) $win.fields.f$row

            $self CreateField $ftype $parm

            # NEXT, Detect when the field widget receives focus.
            bind $my(field-$parm) <FocusIn>  [mymethod FieldIn $parm]

            # NEXT, Create the status icon
            set my(icon-$parm) $win.fields.icon$row

            ttk::label $my(icon-$parm) \
                -image ${type}::blank10x10
            
            # NEXT, Grid the fields
            grid $win.fields.label$row -row $row -column 0 -sticky w
            grid $win.fields.f$row     -row $row -column 1 -sticky ew \
                -padx 2 -pady 4
            grid $win.fields.icon$row  -row $row -column 2 -sticky nsew
        }
    }

    # CreateField color parm
    #
    # parm    The parameter name
    #
    # Creates the field widget

    method {CreateField color} {parm} {
        # FIRST, remember that this is not a key
        lappend my(nonkeys) $parm

        # NEXT, create the field widget
        textfield $my(field-$parm) \
            -changecmd [mymethod NonKeyChange $parm] \
            -editcmd   [mymethod colorpicker]
    }


    # CreateField enum parm
    #
    # parm    The parameter name
    #
    # Creates the field widget

    method {CreateField enum} {parm} {
        # FIRST, remember that this is not a key
        lappend my(nonkeys) $parm

        # NEXT, do have an enumtype?
        set opts [dict create]

        set enumtype [order parm $options(-order) $parm -type]
        
        if {$enumtype ne ""} {
            dict set opts -enumtype $enumtype
        }

        # NEXT, create the field widget
        enumfield $my(field-$parm) {*}$opts \
            -changecmd [mymethod NonKeyChange $parm]
    }


    # CreateField zulu parm
    #
    # parm    The parameter name
    #
    # Creates the field widget

    method {CreateField zulu} {parm} {
        # FIRST, remember that this is not a key
        lappend my(nonkeys) $parm

        # NEXT, create the field widget
        zulufield $my(field-$parm) \
            -changecmd [mymethod NonKeyChange $parm]
    }


    # CreateField key parm
    #
    # parm    The parameter name
    #
    # Creates the field widget

    method {CreateField key} {parm} {
        assert {$my(table) ne ""}
        
        # FIRST, remember that this is a key
        lappend my(keys) $parm

        # NEXT, create the field widget
        enumfield $my(field-$parm) \
            -changecmd [mymethod KeyChange $parm]
    }


    # CreateField multi parm
    #
    # parm    The parameter name
    #
    # Creates the field widget

    method {CreateField multi} {parm} {
        # FIRST, remember that this is a multi.
        set my(multi) $parm

        # NEXT, create the field.  We'll fill in the 
        # value on focus.
        multifield $my(field-$parm) \
            -changecmd [mymethod MultiChange $parm]
    }


    # CreateField text parm
    #
    # parm    The parameter name
    #
    # Creates the field widget

    method {CreateField text} {parm} {
        # FIRST, remember that this is not a key
        lappend my(nonkeys) $parm

        # NEXT, create the field widget
        textfield $my(field-$parm) \
            -changecmd [mymethod NonKeyChange $parm]
    }

    #-------------------------------------------------------------------
    # Event Handlers: Entering the Dialog

    # EnterDialog parmdict
    #
    # parmdict     A dictionary of initial parameter values.
    #
    # Gives the window the focus, and populates it with the initial data.
    # This is used by "orderdialog enter".

    method EnterDialog {parmdict} {
        # FIRST, throw an error if this is a "multi" order and the
        # "multi" parm is not included.
        if {$my(multi) ne "" && 
            (![dict exists $parmdict $my(multi)] ||
             [llength [dict get $parmdict $my(multi)]] == 0)
        } {
            error "Required parm $my(multi) not specified."
        }

        # NEXT, make the window visible
        raise $win

        # NEXT, re-entering the dialog will clear any unsaved
        # changes.  Ask if this is what they want.
        if {[$self Unsaved] && ![$self DiscardUnsaved]} {
            return
        }

        # NEXT, fill in the data
        $self Clear

        if {[dict size $parmdict] > 0} {
            $self set $parmdict

            # NEXT, focus on the first editable field
            $self SetFocus
        }
    }

    # SetFocus
    #
    # Sets the focus to the first editable field.

    method SetFocus {} {
        foreach parm $my(parms) {
            if {$parm ne $my(multi) &&
                [$my(field-$parm) cget -state] ne "disabled"
            } {
                focus $my(field-$parm)
                break
            }
        }
    }


    #-------------------------------------------------------------------
    # Event Handlers: Object Selection

    # ObjectSelect tagdict
    #
    # tagdict   A dictionary of tags and values
    #
    # A dictionary of tags and values that indicates the object or 
    # objects that were selected.  The first one that matches the current
    # field, if any, will be inserted into it.
    #
    # This is only allowed to happen if this dialog is currently the
    # active order dialog.

    method ObjectSelect {tagdict} {
        # FIRST, Is this the active dialog?
        if {[$type topwin] ne $win} {
            return
        }

        # NEXT, get the current field.  If there is none,
        # just leave.

        if {$my(current) eq ""} {
            return
        }

        # NEXT, are there unsaved parameters?
        set unsaved [$self Unsaved] 


        # NEXT, if the current field is a key field, and the order itself
        # has an overall tag, and there's a matching tag in the tagdict,
        # update the keys using it if possible.  If not, proceed.

        if {!$unsaved && $my(current) in $my(keys)} {
            foreach otag [order cget $options(-order) -tags] {
                # FIRST, is this tag present?
                if {![dict exists $tagdict $otag]} {
                    continue
                }
                
                # NEXT, It is.  Does it have the right number of tokens?
                # If not, skip it.
                set id [dict get $tagdict $otag]

                if {[llength $my(keys)] ne [llength $id]} {
                    continue
                }

                # NEXT, If we load it, we're done.
                if {[rdb exists "SELECT id FROM $my(table) WHERE id=\$id"]} {
                    foreach parm $my(keys) value $id {
                        $self set $parm $value
                    }

                    return
                }
            }
        }


        # NEXT, get the tags for the current field.  If there are none,
        # just leave.

        set tags [order parm $options(-order) $my(current) -tags]

        if {[llength $tags] == 0} {
            return
        }

        # NEXT, get the new value, if any
        set newValue ""

        foreach {tag value} $tagdict {
            if {$tag in $tags} {
                set newValue $value
                break
            }
        }

        if {$newValue eq ""} {
            return
        }

        # NEXT, if this is a key or multi field, and dialog data is
        # unsaved, we can only save this value if the user requests it.

        set ftype [order parm $options(-order) $my(current) -fieldtype]

        if {$ftype in {key multi} 
            && $unsaved
            && ![$self DiscardUnsaved $my(current)]
        } {
            return
        }

        # NEXT, save the value
        $self set $my(current) $newValue
    }


    #-------------------------------------------------------------------
    # Event Handlers: Multi Management
    #
    # When the multi field's value is set, the downstream fields need
    # to be populated.

    # MultiChange parm ?value?
    #
    # parm     The parm that changed, e.g., my(multi)
    # value    Its new value (ignored)
    #
    # When the "multi" field's value changes, refresh the other
    # fields.

    method MultiChange {parm {value ""}} {
        # FIRST, get the IDs
        set ids [$my(field-$my(multi)) get]

        # NEXT, if there are no IDs, clear the data; we're done.
        if {[llength $ids] == 0} {
            $self Clear
            return
        }

        # NEXT, refresh all fields with -refreshcmds.
        $self NonKeyChange ""

        # NEXT, retrieve the first entity's data
        set id [lshift ids]

        rdb eval "
            SELECT * FROM $my(table) WHERE id=\$id
        " prev {}

        # NEXT, retrieve the remaining entities, looking for
        # mismatches
        foreach id $ids {
            rdb eval "
                SELECT * FROM $my(table) WHERE id=\$id
            " current {}

            foreach parm [array names current] {
                if {$prev($parm) ne $current($parm)} {
                    set prev($parm) ""
                }
            }
        }

        unset prev(*)

        # NEXT, update the values
        foreach parm $my(nonkeys) {
            $my(field-$parm) set $prev($parm)
        }

        # NEXT, everything has been refreshed; there are no unsaved
        # values.
        $self MarkSaved
    }




    #-------------------------------------------------------------------
    # Event Handlers: Key Management
    #
    # When a key field's value is set, downstream keys and non-key
    # fields are updated.  These routines manage this process.


    # RefreshKey key
    #
    # key    Name of a key parameter
    # 
    # Retrieves the list of valid values for this key, given the
    # values of the previous keys.

    method RefreshKey {key} {
        # FIRST, get the current values of the fields.
        array set values [$self get]

        # NEXT, build the query
        set keytests [list]

        foreach parm $my(keys) {
            if {$parm eq $key} {
                break
            }

            # Add it to the set of tests.
            lappend keytests "$parm=\$values($parm)"
        }

        set keytests [join $keytests " AND "]

        if {$keytests ne ""} {
            set where "WHERE $keytests"
        } else {
            set where ""
        }

        # NEXT, get the list of values
        set list [rdb eval "
            SELECT DISTINCT $key 
            FROM $my(table) 
            $where
            ORDER BY $key
        "]

        # NEXT, blank the entry if the current value isn't in the list.
        if {$values($key) ni $list} {
            $my(field-$key) set ""
        }

        # NEXT, update the pulldown list
        $my(field-$key) configure -values $list

        # NEXT, the value might or might not have changed; but
        # treat it like a key change.  The will cause the subsequent
        # parms to get updated properly.
        $self KeyChange $key
    }


    # KeyChange parm ?value?
    #
    # parm   Name of a key parameter
    # value  The new value, which is ignored.
    #
    # Called when the user has selected a new value for this key.
    #
    # If this is the last of the keys, we must refresh and enable
    # the other fields.  Otherwise, we must refresh the next key.

    method KeyChange {parm {value ""}} {
        set last [expr {[llength $my(keys)] - 1}]
        set ndx  [lsearch -exact $my(keys) $parm]

        if {$ndx == $last} {
            # FIRST, if there are non-key fields, refresh them, and 
            # mark the dialog saved; we've just loaded the non-key
            # fields from the database, and so there are no unsaved fields.
            # Otherwise, check for unsaved fields.
            if {[llength $my(nonkeys)] > 0} {
                $self RefreshNonKeyFields
                $self MarkSaved
            } else {
                $self CheckForUnsavedValues
            }
        } else {
            $self RefreshKey [lindex $my(keys) $ndx+1]
        }
    }


    # RefreshNonKeyFields
    #
    # Fills in the non-key parameters with data from the database

    method RefreshNonKeyFields {} {
        # FIRST, get the current values of the fields.
        array set values [$self get]

        # NEXT, build the key queries
        foreach parm $my(keys) {
            lappend keytests "$parm=\$values($parm)"
        }

        set keytests [join $keytests " AND "]

        set query "SELECT * FROM $my(table) WHERE $keytests"

        # NEXT, get the data from the table
        rdb eval $query row {
            # FIRST, enable all key fields
            $self SetNonKeyFieldState normal

            # NEXT, refresh all fields with -refreshcmds.
            $self NonKeyChange ""

            # NEXT, update the values.
            foreach parm $my(nonkeys) {
                $my(field-$parm) set $row($parm)
            }

            return
        }

        # NEXT, there was no entity to recover.
        $self SetNonKeyFieldState disabled
    }


    # SetNonKeyFieldState state
    #
    # state         normal | disabled
    #
    # Sets the -state of all non-key fields.

    method SetNonKeyFieldState {state} {
        foreach parm $my(nonkeys) {
            $my(field-$parm) configure -state $state

            if {$state eq "disabled"} {
                $my(field-$parm) set ""
            }
        }
    }


    #-------------------------------------------------------------------
    # Event Handlers: Non-Key Management

    # NonKeyChange parm ?value?
    #
    # parm      The name of a non-key parm, or ""
    # value     The new value (ignored)
    #
    # The value of the parameter has changed; refresh all downstream
    # fields with -refreshcmd's.  If parm is "", refresh all
    # non-key fields.

    method NonKeyChange {parm {value ""}} {
        # FIRST, is this one parameter or a general refresh?
        if {$parm ne ""} {
            # FIRST, set the send button state
            $self CheckForUnsavedValues

            # NEXT, if it doesn't have -refresh set, skip it.
            if {![order parm $options(-order) $parm -refresh]} {
                return
            }
        }

        # NEXT, get the list of downstream fields
        set ndx        [lsearch $my(nonkeys) $parm]
        set downstream [lrange $my(nonkeys) $ndx+1 end]
        
        # NEXT, refresh all downstream fields that have a -refreshcmd.
        foreach p $downstream {
            set cmd [order parm $options(-order) $p -refreshcmd]
            if {$cmd ne ""} {
                {*}$cmd $my(field-$p) [$self get]
            }
        }
    }


    #-------------------------------------------------------------------
    # Event Handlers: Buttons

    # Clear
    #
    # Clears all parameter values

    method Clear {} {
        # FIRST, clear the parameter values.  Skip "multi" fields.
        foreach parm [concat $my(keys) $my(nonkeys)] {
            $my(field-$parm) set \
                [order parm $options(-order) $parm -defval]
        }

        # NEXT, if there are key fields, disable non-key fields.
        if {[llength $my(keys)] != 0} {
            $self RefreshKey [lindex $my(keys) 0]
        } else {
            $self NonKeyChange ""
        }

        # NEXT, set the focus to first editable field
        $self SetFocus

        # NEXT, save the current field values, so that we can check
        # whether there are unsaved changes.
        $self MarkSaved

        # NEXT, notify the app that the dialog has been cleared; this
        # will allow it to clear up any entry artifacts.
        notifier send ::order <OrderEntry> {}
    }

    # Close
    #
    # Closes the dialog

    method Close {} {
        # FIRST, save the dialog's position
        set geo [wm geometry $win]
        set ndx [string first "+" $geo]
        set info(position-$options(-order)) [string range $geo $ndx end]

        # NEXT, notify the app that no order entry is being done.
        notifier send ::order <OrderEntry> {}

        # NEXT, destroy the dialog
        destroy $win
    }

    # Help
    #
    # Brings up the on-line help for the application
    
    method Help {} {
        app help $options(-order)
    }

    # Send
    #
    # Sends the order; on error, reveals the error.

    method Send {} {
        # FIRST, clear the error text from the previous order.
        array unset ferrors

        # NEXT, send the order, and handle any errors
        if {[catch {
            order send gui $options(-order) [$self get]
        } result opts]} {
            # FIRST, if it's unexpected let the app handle it.
            if {[dict get $opts -errorcode] ne "REJECT"} {
                return {*}$opts $result
            }

            # NEXT, mark the bad parms.
            foreach {parm msg} $result {
                if {$parm ne "*"} {
                    $my(icon-$parm) configure -image ${type}::error_x
                }
            }

            # NEXT, save the error text
            array set ferrors $result

            # NEXT, if it's not shown, show the message box
            if {[dict exists $result *]} {
                $self Message "Error in order: [dict get $result *]"
            } else {
                $self Message \
                 "Error in order; click in marked fields for error messages."
            }

            return 0
        }

        # NEXT, either output the result, or just say that the order
        # was accepted.
        if {$result ne ""} {
            $self Message $result
        } else {
            $self Message "The order was accepted."
        }

        # NEXT, save the current values, so that we can check whether
        # there are changes.
        $self MarkSaved

        # NEXT, notify the app that no order entry is being done; this
        # will allow it to clear up any entry artifacts.
        notifier send ::order <OrderEntry> {}

        # NEXT, the order was accepted; we're done here.
        return 1
    }

    # SendClose
    #
    # Sends the order and closes the dialog on success.

    method SendClose {} {
        if {[$self Send]} {
            $self Close
        }
    }


    #-------------------------------------------------------------------
    # Event Handlers: Other

    # FieldIn parm
    #
    # parm    The parameter name
    #
    # Updates the display when the user is on a particular field.

    method FieldIn {parm} {
        # FIRST, clear the previous parm's icon
        if {$my(current) ne ""} {
            $my(icon-$my(current)) configure -image ${type}::blank10x10
        }

        # NEXT, set the status icon
        set my(current) $parm

        $my(icon-$parm) configure -image ${type}::left_arrow

        # NEXT, if there's an error message, display it.
        if {[info exists ferrors($parm)]} {
            set label [order parm $options(-order) $parm -label]
            $self Message "$label: $ferrors($parm)"
        } else {
            $self Message ""
        }

        # NEXT, tell the app what kind of parameter this is.
        set tags [order parm $options(-order) $parm -tags]

        if {[llength $tags] == 0} {
            set tags null
        }

        notifier send ::order <OrderEntry> $tags
    }

    #-------------------------------------------------------------------
    # Saved/Unsaved Values
    #
    # There are certain points where we know there are no unsaved
    # user changes:
    #
    # * When Clear is called.
    # * When Send is successful.
    # * When the content has been refreshed due to a key or multi field
    #   change.
    #
    # When there are no unsaved changes, the Send and SendClose buttons
    # should be disabled.

    # MarkSaved
    #
    # Saves the current field values, and disables the Send buttons.

    method MarkSaved {} {
        # FIRST, if the order is always unsaved, ignore this.
        if {[order cget $options(-order) -alwaysunsaved]} {
            return 1
        }

        # NEXT, save the current values, so we check whether 
        # there's anything unsaved.
        set my(saved) [$self get]

        # NEXT, disable the buttons
        $win.buttons.send      configure -state disabled
        $win.buttons.sendclose configure -state disabled
    }


    # CheckForUnsavedValues
    #
    # Enables/disables the send buttons based on whether there are
    # unsaved changes.

    method CheckForUnsavedValues {} {
        if {[$self Unsaved]} {
            $win.buttons.send      configure -state normal
            $win.buttons.sendclose configure -state normal
        } else {
            $win.buttons.send      configure -state disabled
            $win.buttons.sendclose configure -state disabled
        }
    }

    # Unsaved
    #
    # Returns 1 if there are unsaved field values, and 0 otherwise.

    method Unsaved {} {
        expr {[order cget $options(-order) -alwaysunsaved]  ||
              [$self get] ne $my(saved)}
    }

    # DiscardUnsaved ?parm?
    #
    # parm   Name of a key or multi partm
    #
    # Asks the user if they want to discard unsaved changes.  Returns
    # 1 if so and 0 otherwise.
    #

    method DiscardUnsaved {{parm ""}} {
        # FIRST, if the order is always unsaved, ignore this.
        if {[order cget $options(-order) -alwaysunsaved]} {
            return 1
        }

        # NEXT, If the dialog has no nonkey fields, it returns 1 immediately.
        if {[llength $my(nonkeys)] == 0} {
            return 1
        }

        if {$parm ne ""} {
            set label [order parm $options(-order) $my(current) -label]
            
            set message "You have selected a new $label, but the"
        } else {
            set message "The"
        }
        
        append message " dialog contains unsaved changes.  Discard them?"

        set answer [messagebox popup \
                        -icon          warning                    \
                        -message       [normalize $message]       \
                        -parent        $win                       \
                        -title         "Unsaved Changes"          \
                        -default       ok                         \
                        -buttons       {
                            ok     "Discard" 
                            cancel "Go Back"
                        }]

        return [expr {$answer eq "ok"}]
    }

    #-------------------------------------------------------------------
    # Utility Methods


    # Message text
    #
    # Opens the message widget, and displays the text.

    method Message {text} {
        # FIRST, normalize the whitespace
        set text [string trim $text]
        set text [regsub {\s+} $text " "]

        # NEXT, display the text.
        $win.message del 1.0 end
        $win.message ins 1.0 $text
        $win.message see 1.0
    }


    #-------------------------------------------------------------------
    # Public methods

    # get
    #
    # Returns a parmdict of the current values

    method get {} {
        foreach parm $my(parms) {
            dict set parmdict $parm [$my(field-$parm) get]
        }

        return $parmdict
    }

    # set parmdict
    # set parm value ?parm value...?
    #
    # Fills in the specified fields

    method set {args} {
        # FIRST, get the parmdict
        if {[llength $args] > 1} {
            set parmdict $args
        } else {
            set parmdict [lindex $args 0]
        }

        # NEXT, set the values, from upstream to downstream.
        foreach parm [concat $my(multi) $my(keys) $my(nonkeys)] {
            if {[dict exists $parmdict $parm]} {
                # FIRST, set the field value
                $my(field-$parm) set [dict get $parmdict $parm]
            }
        }
    }

    #-------------------------------------------------------------------
    # Edit Commands

    # colorpicker color
    #
    # color       A hex color value, or ""
    #
    # Pops up a color picker dialog, displaying the specified color,
    # and allows the user to choose a new color.  Returns the new
    # color, or ""

    method colorpicker {color} {
        if {$color ne ""} {
            set opts [list -color $color]
        } else {
            set opts ""
        }

        set out [SelectColor::dialog $win.colorpicker \
                     -type   dialog                   \
                     -parent $win                     \
                     {*}$opts]

        return $out
    }
}
