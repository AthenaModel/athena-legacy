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
        log detail odlg "init"

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

        # NEXT, create field types.
        form register coop ::formlib::rangefield \
            -type        ::qcooperation          \
            -showsymbols yes

        form register frac ::formlib::rangefield \
            -type        ::rfraction

        form register pct  ::formlib::rangefield \
            -type        ::ipercent

        form register rel ::formlib::rangefield \
            -type        ::qrel                 \
            -resolution  0.1

        form register sat ::formlib::rangefield \
            -type        ::qsat                 \
            -showsymbols yes

        # NEXT, note that we're initialized
        set info(initialized) 1
        
        log detail odlg "init complete"
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
        # NOTE: If at some point we need special dialogs for some
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
    # Components

    component form       ;# The form(n) widget
    component whenFld    ;# textfield, time to schedule
    component schedBtn   ;# Schedule button



    #-------------------------------------------------------------------
    # Instance Variables

    # my array -- scalars and field data
    #
    # parms             Names of all parms.
    # table             Name of associated RDB table/view, or ""
    # valid             1 if current values are valid, and 0 otherwise.

    variable my -array {
        parms {}
        table ""
        valid 0
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

        # NEXT, create the title bar
        ttk::frame $win.tbar \
            -borderwidth 0   \
            -relief      flat

        # NEXT, create the title widget
        ttk::label $win.tbar.title                        \
            -font          OrderTitleFont                 \
            -text          [order title $options(-order)] \
            -padding       4

        # NEXT, create the help button
        ttk::button $win.tbar.help              \
            -style   Toolbutton                 \
            -image   ::projectgui::icon::help22 \
            -state   normal                     \
            -command [mymethod Help]

        DynamicHelp::add $win.tbar.help -text "Get help!"

        pack $win.tbar.title -side left
        pack $win.tbar.help  -side right

        # NEXT, create the form to hold the fields
        install form using form $win.form       \
            -borderwidth 1                        \
            -relief      raised                   \
            -padding     2                        \
            -currentcmd  [mymethod CurrentField]  \
            -changecmd   [mymethod FormChange] 
        
        grid columnconfigure $form 1 -weight 1

        # NEXT, create the fields
        $self CreateFields
        $form layout [order cget $options(-order) -layout]

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

        ttk::button $win.buttons.clear        \
            -text    "Clear"                  \
            -width   6                        \
            -command [mymethod Clear]

        install schedBtn using ttk::button $win.buttons.schedule \
            -text    "Schedule"                                  \
            -width   8                                           \
            -command [mymethod Schedule]

        install whenFld using textfield $win.buttons.when \
            -width     13                                 \
            -changecmd [mymethod CheckWhen]

        ttk::button $win.buttons.send         \
            -text    "Send"                   \
            -width   6                        \
            -command [mymethod Send]

        ttk::button $win.buttons.sendclose    \
            -text    "Send & Close"           \
            -width   12                       \
            -command [mymethod SendClose]

        # Can't do this above, as it sets the state of the
        # send and sendclose buttons.
        if {[order cget $options(-order) -schedulestates] ne ""} {
            if {[order state] eq "PREP"} {
                # Orders must be scheduled in advance; but in the
                # PREP state, time 0 hasn't yet occurred.
                $whenFld set "T0"
            } else {
                $whenFld set "NOW+1"
            }
        }
        
        pack $win.buttons.clear     -side left  -padx {2 15}
        pack $win.buttons.sendclose -side right -padx 2
        pack $win.buttons.send      -side right -padx 2
        pack $win.buttons.when      -side right -padx 2
        pack $win.buttons.schedule  -side right -padx 2


        # NEXT, pack components
        pack $win.tbar    -side top -fill x
        pack $win.form    -side top -fill x -padx 4 -pady 4
        pack $win.message -side top -fill x -padx 4
        pack $win.buttons -side top -fill x -pady 4

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
        notifier bind ::app   <ObjectSelect> $win [mymethod ObjectSelect]
        notifier bind ::sim   <Tick>         $win [mymethod RefreshDialog]
        notifier bind ::order <State>        $win [mymethod RefreshDialog]
        notifier bind ::order <Accepted>     $win [mymethod RefreshDialog]
        notifier bind ::cif   <Update>       $win [mymethod RefreshDialog]

        # NEXT, wait for visibility.
        update idletasks
    }

    destructor {
        notifier forget $win
    }

    # CreateFields
    #
    # Creates the data entry fields

    method CreateFields {} {
        # FIRST, save some variables
        set order     $options(-order)
        set my(parms) [order parms $order]
        set my(valid) 0

        # NEXT, Create the fields
        foreach parm $my(parms) {
            # FIRST, get the parameter dictionary
            set pdict [order parm $order $parm]

            # NEXT, create the field
            set ftype [dict get $pdict -fieldtype]

            set opts [dict create]

            switch -exact -- $ftype {
                coop {
                    dict set opts -resetvalue [dict get $pdict -defval]
                }

                enum {
                    set enumtype [dict get $pdict -type]
        
                    if {$enumtype ne ""} {
                        dict set opts -enumtype $enumtype
                    }

                    dict set opts -displaylong \
                        [dict get $pdict -displaylong]
                    
                }

                key {
                    dict set opts -db       ::rdb
                    dict set opts -table    [dict get $pdict -table]
                    dict set opts -keys     [dict get $pdict -key]
                    dict set opts -labels   [dict get $pdict -labels]
                    dict set opts -dispcols [dict get $pdict -dispcols]
                    dict set opts -widths   [dict get $pdict -widths]
                }

                newkey {
                    dict set opts -db       ::rdb
                    dict set opts -table    [dict get $pdict -table]
                    dict set opts -universe [dict get $pdict -universe]
                    dict set opts -keys     [dict get $pdict -key]
                    dict set opts -widths   [dict get $pdict -widths]
                    dict set opts -labels   [dict get $pdict -labels]
                }

                pct {
                    dict set opts -resetvalue [dict get $pdict -defval]
                }

                multi {
                    dict set opts -table    [dict get $pdict -table]
                    dict set opts -key      [dict get $pdict -key]
                }

            }

            $form field create $parm [dict get $pdict -label] $ftype {*}$opts
        }
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
        # FIRST, make the window visible
        raise $win

        # NEXT, fill in the data
        $self Clear

        if {[dict size $parmdict] > 0} {
            $form set $parmdict

            # NEXT, focus on the first editable field
            $self SetFocus
        }
    }

    # SetFocus
    #
    # Sets the focus to the first editable field.

    method SetFocus {} {
        # TBD: Set the focus to the first editable, non-disabled
        # field.
    }

    #-------------------------------------------------------------------
    # Event Handlers: Form Change

    # FormChange fields
    #
    # fields   A list of one or more field names
    #
    # The data in the form has changed.  Validate the order, and set
    # the button state.

    method FormChange {fields} {
        # FIRST, refresh the contents of the form given the changed
        # fields.
        $self RefreshFields $fields

        # NEXT, validate the order.
        $self CheckValidity

        # NEXT, set the button state
        $self SetButtonState
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
        # we're done.
        set current [$form field current]

        if {$current eq ""} {
            return
        }

        # NEXT, get the tags for the current field.  If there are none,
        # we're done.

        set tags [order parm $options(-order) $current -tags]

        if {[llength $tags] == 0} {
            return
        }

        # NEXT, get the new value, if any.  If none, we're done.
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

        # NEXT, save the value
        $form set $current $newValue
    }

    #-------------------------------------------------------------------
    # Event Handlers: Dialog Refresh

    # RefreshDialog ?args...?
    #
    # args      Ignored optional arguments.
    #
    # At times, it's necessary to refresh the entire dialog:
    # at initialization, on clear, etc.
    #
    # Any arguments are ignored; this allows a refresh to be
    # triggered by any notifier(n) event.

    method RefreshDialog {args} {
        $self RefreshFields $my(parms)
    }

    # RefreshFields fields
    #
    # fields   A list of the fields to refresh.  Generally, all fields
    #          downstream of a changed field.
    # 
    # Refreshes the named fields.
    
    method RefreshFields {fields} {
        # FIRST, call the order's -refreshcmd, if any.
        set cmd [order cget $options(-order) -refreshcmd]
        
        if {$cmd ne ""} {
            {*}$cmd $self $fields [$form get]
        }

        # NEXT, since fields might have changed, check the validity
        # and set the button state.
        $self CheckValidity
        $self SetButtonState
    }


    #-------------------------------------------------------------------
    # Order Validation

    # CheckValidity
    #
    # Checks the current parameters; on error, reveals the error.

    method CheckValidity {} {
        # FIRST, clear the error messages.
        array unset ferrors
        $form invalid {}

        # NEXT, check the order, and handle any errors
        if {[catch {
            order check $options(-order) [$form get]
        } result opts]} {
            # FIRST, if it's unexpected let the app handle it.
            if {[dict get $opts -errorcode] ne "REJECT"} {
                return {*}$opts $result
            }

            # NEXT, save the error text
            array set ferrors $result

            # NEXT, mark the bad parms.
            dict unset result *

            $form invalid [dict keys $result]

            # NEXT, show the current error message
            set current [$form field current]

            if {$current ne "" && [info exists ferrors($current)]} {
                set label [order parm $options(-order) $current -label]
                $self Message "$label: $ferrors($current)"
            } elseif {[dict exists $result *]} {
                $self Message "Error in order: [dict get $result *]"
            } else {
                $self Message \
                 "Error in order; click in marked fields for error messages."
            }

            set my(valid) 0
        } else {
            set my(valid) 1
            $self Message ""
        }
    }


    #-------------------------------------------------------------------
    # Event Handlers: Buttons

    # Clear
    #
    # Clears all parameter values

    method Clear {} {
        # FIRST, clear the parameter values.  Skip "multi" fields.
        set dict [dict create]

        foreach parm $my(parms) {
            if {[$form field ftype $parm] ne "multi"} {
                dict set dict $parm \
                    [order parm $options(-order) $parm -defval]
            }
        }

        $form set $dict


        # NEXT, refresh all of the fields.
        # TBD: Is this necessary?
        $self RefreshDialog

        # NEXT, set the focus to first editable field
        $self SetFocus

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
        $form invalid {}

        # NEXT, send the order, and handle any errors
        if {[catch {
            order send gui $options(-order) [$form get]
        } result opts]} {
            # FIRST, if it's unexpected let the app handle it.
            if {[dict get $opts -errorcode] ne "REJECT"} {
                return {*}$opts $result
            }

            # NEXT, save the error text
            array set ferrors $result

            # NEXT, mark the bad parms.
            dict unset result *

            $form invalid [dict keys $result]

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

    # CheckWhen timespec
    #
    # Sets the state of the Schedule button based on the
    # validity of the "when" field.

    method CheckWhen {timespec} {
        $self SetButtonState
    }

    # Schedule
    #
    # Schedules the current order

    method Schedule {} {
        # FIRST, Is the order valid?
        if {!$my(valid)} {
            set answer [messagebox popup \
                            -title         "Are you sure?"                    \
                            -icon          warning                            \
                            -buttons       {ok "Schedule it" cancel "Cancel"} \
                            -default       cancel                             \
                            -ignoretag     ORDER:SCHEDULE                     \
                            -ignoredefault ok                                 \
                            -parent        [app topwin]                       \
                            -message       [normalize {
                                This order is invalid at the present
                                time.  Are you sure you wish to schedule
                                it to execute in the future?
                            }]]

            if {$answer eq "cancel"} {
                return
            }
        }

        # NEXT, schedule it.
        order send gui ORDER:SCHEDULE \
            timespec [$whenFld get]   \
            name     $options(-order) \
            parmdict [$form get]

        $self Message "Order Scheduled"
    }


    #-------------------------------------------------------------------
    # Event Handlers: Other

    # CurrentField parm
    #
    # parm    The parameter name
    #
    # Updates the display when the user is on a particular field.

    method CurrentField {parm} {
        # FIRST, if there's an error message, display it.
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

    # SetButtonState
    #
    # Enables/disables the send and schedule buttons based on 
    # whether there are unsaved changes, and whether the data is valid,
    # and so forth.

    method SetButtonState {} {
        # FIRST, the order can be sent if it is valid in this state,
        # there is unsaved data, and the field values are valid.
        if {[order cansend $options(-order)] &&
            $my(valid)
        } {
            $win.buttons.send      configure -state normal
            $win.buttons.sendclose configure -state normal
        } else {
            $win.buttons.send      configure -state disabled
            $win.buttons.sendclose configure -state disabled
        }

        # NEXT, the order can be scheduled if it can be scheduled
        # in this state, and the "when" is valid, and either the
        # field values are valid or escaped with -schedwheninvalid
        set valid 1

        foreach p [array names ferrors] {
            if {![order parm $options(-order) $p -schedwheninvalid]} {
                set valid 0
            }
        }

        if {$valid && [order canschedule $options(-order)]} {
            $whenFld configure -state normal

            set timespec [$whenFld get]

            # If we're in the PREP state then a time of now (0) is 
            # valid; otherwise, we need it list now+1.
            if {![catch {simclock future validate $timespec} t]  &&
                ([order state] eq "PREP" || $t > [simclock now])
            } {
                $schedBtn configure -state normal
            } else {
                $schedBtn configure -state disabled
            }
        } else {
            $schedBtn configure -state disabled
            $whenFld  configure -state disabled
        }
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

    delegate method field    to form
    delegate method get      to form
    delegate method disabled to form
    delegate method set      to form

    # loadForKey key ?fields?
    #
    # key     Name of a key field.
    # fields  Fields whose values should be loaded given the key field.
    #         If "*", all fields are loaded.  Defaults to "*".
    #
    # Reads the named fields from the key's -table given the key's
    # current value.

    method loadForKey {key {fields *}} {
        # FIRST, get the table name.
        set table  [$form field cget $key -table]
        set keyval [$form field get $key]

        # NEXT, get the list of fields
        if {$fields eq "*"} {
            set fields [$form field names]
        }

        # NEXT, retrieve the record.
        rdb eval "
            SELECT [join $fields ,] FROM $table
            WHERE $key=\$keyval
        " row {
            unset row(*)

            $form set [array get row]
        }
    }

    # loadForMulti multi ?fields?
    #
    # multi     Name of a multi field.
    # fields  Fields whose values should be loaded given the multi field's
    #         value.  If "*", all fields are loaded.  Defaults to "*".
    #
    # Reads the named fields from the multi's -table given the multi's
    # current list of values.  Builds a dictionary of values common
    # to all records, and clears the others.

    method loadForMulti {multi {fields *}} {
        # FIRST, get the table name, the key column name, and
        # the list of key values.
        set table   [$form field cget $multi -table]
        set keycol  [$form field cget $multi -key]
        set keyvals [$form field get $multi]

        # NEXT, if the list of key values is empty, clear the values;
        # we're done.
        if {[llength $keyvals] == 0} {
            # TBD: Should clear the set of values, probably.
            return
        }
        
        # NEXT, get the list of fields
        if {$fields eq "*"} {
            set fields [$form field names]
            ldelete fields $multi
        }

        # NEXT, retrieve the first entity's data.
        set key [lshift keyvals]

        set query "
            SELECT [join $fields ,] FROM $table WHERE $keycol=\$key
        "

        rdb eval $query prev {}
        unset prev(*)

        # NEXT, retrieve the remaining entities, looking for
        # mismatches
        foreach key $keyvals {
            rdb eval $query current {}

            foreach field $fields {
                if {$prev($field) ne $current($field)} {
                    set prev($field) ""
                }
            }
        }


        # NEXT, save the values.
        $form set [array get prev]
    }

    #-------------------------------------------------------------------
    # Refresh Callbacks

    # refreshForKey key fields  dlg changedFields fdict
    #
    # key        Name of a key field
    # fields     Fields to be loaded for the key field.
    # dlg, etc.  -refreshcmd arguments
    #
    # A -refreshcmd that simply loads field values when a key 
    # field's value changes.  The user defines the -refreshcmd
    # like this:
    #
    #   -refreshcmd {orderdialog refreshForKey g *}

    typemethod refreshForKey {key fields dlg changedFields fdict} {
        if {$key in $changedFields} {
            $dlg loadForKey $key $fields
        }
    }

    # refreshForMulti multi fields  dlg changedFields fdict
    #
    # multi      Name of a multi field
    # fields     Fields to be loaded for the multi field.
    # dlg, etc.  -refreshcmd arguments
    #
    # A -refreshcmd that simply loads field values when a multi 
    # field's value changes.  The user defines the -refreshcmd
    # like this:
    #
    #   -refreshcmd {orderdialog refreshForMulti ids *}

    typemethod refreshForMulti {multi fields dlg changedFields fdict} {
        if {$multi in $changedFields} {
            $dlg loadForMulti $multi $fields
        }
    }

}
