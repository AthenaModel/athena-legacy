#-----------------------------------------------------------------------
# TITLE:
#    ordergui.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Order Dialog Manager; works with order.tcl's metadata to automatically
#    create order dialogs.
#
#-----------------------------------------------------------------------

snit::type ordergui {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    typecomponent dialog     ;# The dialog widget (a toplevel)
    typecomponent parmf      ;# The parameters frame
    typecomponent message    ;# The message rotext

    #-------------------------------------------------------------------
    # Type Constructor

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

    #-------------------------------------------------------------------
    # Lookup Tables

    # ewidget: Array of entry widget types by etype
    
    typevariable ewidget -array {
        key    ::enumentry
        text   ::textentry
        enum   ::enumentry
        editor ::editorentry
    }

    #-------------------------------------------------------------------
    # Type Variables

    # info array: scalar variables
    #
    #  active      1 if dialog is visible, 0 otherwise
    #  current     Current parameter
    #  geometry    Root window coords of upper-left corner of dialog,
    #              as "+x+y"
    #  message     message to be displayed on the dialog
    #  order       If active, name of the order to send
    #  title       If active, the order's title
    #  table       If not "", the table associated with the order
    #  keys        If not "", the key parameters for the table

    typevariable info -array {
        active      0
        current     ""
        geometry    ""
        initialized 0
        order       ""
        title       ""
        table       ""
        keys        ""
    }

    #-------------------------------------------------------------------
    # Transient Data used while active

    # etypes array: Entry widget types by parameter type
    typevariable etypes -array { }

    # values array: entered data by parm name.
    typevariable values -array { }

    # entries array: entry widgets by parm name.
    typevariable entries -array { }
    
    # icon array: Status icon by parm name.
    typevariable icon -array { }

    # perrors: Parameter errors array by parm name
    typevariable perrors -array { }

    #-------------------------------------------------------------------
    # Initialization

    # init
    #
    # Initializes the module, i.e., creates the dialog

    typemethod init {} {
        # FIRST, create the necessary fonts
        font create OrderTitleFont {*}[font actual TkDefaultFont] \
            -weight bold                                          \
            -size   -16

        # NEXT, set up the standard ptypes
        $type entrytype text text
        
        # NEXT, create the order dialog and its main components.
        toplevel .order           \
            -borderwidth 4        \
            -highlightthickness 0

        set dialog .order

        # NEXT, Withdraw it; we don't want to see it yet.
        wm withdraw $dialog

        # NEXT, set the window title
        wm title $dialog "Athena [version]: Send Order"

        # NEXT, the user can't resize it
        wm resizable $dialog 0 0

        # NEXT, if it's closed, just cancel the order entry
        wm protocol $dialog WM_DELETE_WINDOW [mytypemethod cancel]

        # NEXT, create the title widget
        ttk::label $dialog.title                   \
            -font          OrderTitleFont          \
            -textvariable  [mytypevar info(title)] \
            -anchor        center                  \
            -padding       4

        # NEXT, create the frame to hold the parameters
        ttk::frame $dialog.parmf   \
            -borderwidth 1      \
            -relief      raised \
            -padding     2
        
        set parmf $dialog.parmf

        grid columnconfigure $parmf 1 -weight 1

        # NEXT, create the message text
        rotext $dialog.message                             \
            -takefocus          0                          \
            -font               TkDefaultFont              \
            -width              40                         \
            -height             3                          \
            -wrap               word                       \
            -relief             flat                       \
            -background         [$dialog cget -background] \
            -highlightthickness 0
        set message $dialog.message

        # NEXT, create the frame to hold the buttons
        ttk::frame $dialog.buttons \
            -borderwidth 0         \
            -relief      flat

        ttk::button $dialog.buttons.help               \
            -text    "Help"                            \
            -width   6                                 \
            -command [mytypemethod help]

        label $dialog.buttons.spacer                   \
            -text "   "

        ttk::button $dialog.buttons.cancel             \
            -text    "Close"                           \
            -width   6                                 \
            -command [mytypemethod cancel]

        ttk::button $dialog.buttons.clear              \
            -text    "Clear"                           \
            -width   6                                 \
            -command [mytypemethod clear]

        ttk::button $dialog.buttons.send               \
            -text    "Send"                            \
            -width   6                                 \
            -command [mytypemethod ButtonSend]

        ttk::button $dialog.buttons.sendclose          \
            -text    "Send and Close"                  \
            -width   14                                \
            -command [mytypemethod ButtonSendClose]


        pack $dialog.buttons.help      -side left  -padx 2
        pack $dialog.buttons.spacer    -side left

        pack $dialog.buttons.sendclose -side right -padx 2
        pack $dialog.buttons.send      -side right -padx 2
        pack $dialog.buttons.clear     -side right -padx 2
        pack $dialog.buttons.cancel    -side right -padx 2


        # NEXT, pack components
        pack $dialog.title   -side top -fill x
        pack $dialog.parmf   -side top -fill x -padx 4 -pady 4
        pack $dialog.buttons -side top -fill x

        # NEXT, note that we're initialized
        set info(initialized) 1
    }

    #-------------------------------------------------------------------
    # Public Type Methods

    # isactive
    #
    # Returns 1 if the order dialog is active, and 0 otherwise

    typemethod isactive {} {
        return $info(active)
    }

    # parm type parm
    #
    # parm     A parm name, or "current"
    #
    # Returns the ptype of the named parameter.  "current" is the parm
    # with focus.

    typemethod {parm type} {parm} {
        # FIRST, get the parm name
        if {$parm eq "current"} {
            set parm $info(current)
        }

        # NEXT, get the parm type
        return [order meta $info(order) parms $parm ptype]
    }

    # parm set parm value
    #
    # parm     A parm name, or "current"
    # value    A new value
    #
    # Sets the value of the named parameter.  "current" is the parm
    # with focus.

    typemethod {parm set} {parm value} {
        # FIRST, get the parm name
        if {$parm eq "current"} {
            set parm $info(current)
        }

        # NEXT, set the parm's value
        set values($parm) $value

        # NEXT, if this is a key value, refresh the content.
        if {$parm in $info(keys)} {
            $type KeyChange $parm
        }

        # NEXT, if this is the "ids" parm in a multi-update order, it's
        # handled specially.
        if {$info(multi) && $parm eq "ids"} {
            $type IDsChange
        }
    }

    # enter order
    #
    # order    The name of an order
    #
    # Sets up the dialog for entry of the specified order, and pops
    # up the window.

    typemethod enter {order} {
        require {$info(initialized)}    "Order dialog is uninitialized"
        require {[order exists $order]} "Undefined order: \"$order\""

        # FIRST, Make sure we're not already handling an order
        if {$info(active)} {
            set answer [messagebox popup \
                            -buttons {
                                yes    "Enter this Order" 
                                cancel "Cancel"
                            } -icon    question            \
                            -ignoretag ordergui:active     \
                            -parent    [app topwin]        \
                            -title     "Athena [version]" \
                            -message "The order dialog is already active for another order.  Do you wish to enter this order instead of the previous?"]

            if {$answer eq "cancel"} {
                return
            }

            # NEXT, pop down the old order, so that the dialog can be
            # popped up for the new one.
            #
            # TBD: Should we retain values for same-named parameters?
            $type cancel
        }

        # NEXT, get the order's title
        set info(order) $order
        set info(title) [order meta $order title]
        set info(table) [order meta $order table]
        set info(multi) [order meta $order multi]
        set info(keys)  [list]
        array unset values
        array unset entries
        array unset icon
        array unset perrors
        
        # NEXT, add the parameter fields
        set row -1
        
        dict for {parm pdict} [order meta $order parms] {
            # FIRST, get the current row
            incr row

            # NEXT, set the default value
            set values($parm) [dict get $pdict defval]

            # NEXT, get the parameter type.
            set ptype [dict get $pdict ptype]

            # NEXT, get the entry type and args.  If no entry type
            # is know for this parameter type, we treat it as a standard
            # text entry.  If it's a key, add it to the list of keys.

            if {$ptype eq "ids"} {
                assert {$info(multi)}
                set etype label
            } elseif {$ptype eq "key"} {
                assert {$info(table) ne ""}
                lappend info(keys) $parm

                set etype    enum
                set eoptions {}
            } elseif {[info exists etypes($ptype)]} {
                lassign $etypes($ptype) etype eoptions
            } else {
                set etype    text
                set eoptions {}
            }

            # NEXT, create the widgets

            # Label
            ttk::label $parmf.label$row \
                -text   "[dict get $pdict label]:"

            # Entry
            set entries($parm) $parmf.entry$row

            if {$etype eq "label"} {
                ttk::label $entries($parm)
            } else {
                $ewidget($etype) $entries($parm) {*}$eoptions \
                    -textvariable [mytypevar values($parm)]

                bind $entries($parm) <FocusIn> \
                    [mytypemethod ParmIn $parm $ptype]
                bind $entries($parm) <FocusOut> \
                    [mytypemethod ParmOut $parm]

                if {$ptype eq "key"} {
                    bind $entries($parm) <<ComboboxSelected>> \
                        [mytypemethod KeyChange $parm]
                }
            }

            # Status Icon
            ttk::label $parmf.icon$row \
                -image ${type}::blank10x10
            
            set icon($parm) $parmf.icon$row
            
            grid $parmf.label$row -row $row -column 0 -sticky w
            grid $parmf.entry$row -row $row -column 1 -sticky ew \
                -padx 2 -pady 4
            grid $parmf.icon$row  -row $row -column 2 -sticky nsew
        }

        # NEXT, if there are key fields, disable non-key fields.
        if {[llength $info(keys)] != 0} {
            $type GetKeyValues [lindex $info(keys) 0]
        }

        # NEXT, raise the window and set the focus
        wm transient $dialog [app topwin]
        wm deiconify $dialog
        raise $dialog

        if {$info(geometry) ne ""} {
            wm geometry $dialog $info(geometry)
        }

        focus $parmf.entry0


        # NEXT, wait for visibility
        update idletasks

        # NEXT, we're active!
        set info(active) 1
    }

    # KeyChange key
    #
    # key    Name of a key parameter
    #
    # Called when the user has selected a new value for this key.
    #
    # If this is the last of the keys, we must refresh and enable
    # the other fields.  Otherwise, we must refresh the next key.

    typemethod KeyChange {key} {
        set last [expr {[llength $info(keys)] - 1}]
        set ndx  [lsearch -exact $info(keys) $key]

        if {$ndx == $last} {
            $type RefreshNonKeyFields
        } else {
            $type GetKeyValues [lindex $info(keys) $ndx+1]
        }
    }

    # GetKeyValues key
    #
    # key    Name of a key parameter
    # 
    # Retrieves the list of valid values for this key, given the
    # values of the previous keys.

    typemethod GetKeyValues {key} {
        # FIRST, build the query
        set keytests [list]

        foreach parm $info(keys) {
            if {$parm eq $key} {
                break
            }

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
            FROM $info(table) 
            $where
            ORDER BY $key
        "]

        

        # NEXT, blank the entry if the current value isn't in the list.
        if {$values($key) ni $list} {
            set values($key) ""
        }

        # NEXT, update the pulldown list
        $entries($key) configure -values $list

        # NEXT, the value might or might not have changed; but
        # treat it like a key change.  The will cause the subsequent
        # parms to get updated properly.
        $type KeyChange $key

    }

    # RefreshNonKeyFields
    #
    # Fills in the non-key parameters with data from the database

    typemethod RefreshNonKeyFields {} {
        # FIRST, build the key queries
        foreach parm $info(keys) {
            lappend keytests "$parm=\$values($parm)"
        }

        set keytests [join $keytests " AND "]

        set query "SELECT * FROM $info(table) WHERE $keytests"

        # NEXT, get the data from the table
        rdb eval $query row {
            $type SetNonKeyFields normal

            foreach parm [array names values] {
                if {$parm ni $info(keys)} {
                    set values($parm) $row($parm)
                }
            }

            return
        }

        # NEXT, there was no entity to recover.
        $type SetNonKeyFields disabled
    }

    # SetNonKeyFields state
    #
    # state         normal | disabled
    #
    # Sets the -state of all non-key fields.

    typemethod SetNonKeyFields {state} {
        foreach parm [array names entries] {
            if {$parm ni $info(keys)} {
                $entries($parm) configure -state $state
            }
        }
    }

    # IDsChange
    #
    # When the "ids" parameter for multi-update orders changes, 
    # fill in the rest of the dialog.

    typemethod IDsChange {} {
        # FIRST, get the IDs
        set ids $values(ids)

        # NEXT, set the ids field to show how many there are
        $entries(ids) configure -text "[llength $ids] Selected"

        # NEXT, if there are no IDs, clear the data; we're done.
        if {[llength $ids] == 0} {
            foreach parm [array names values] {
                set values($parm) ""
            }
            return
        }

        # NEXT, retrieve the first entity's data

        set id [lshift ids]

        rdb eval "
            SELECT * FROM $info(table) WHERE id=\$id
        " prev {}

        # NEXT, retrieve the remaining entities, looking for
        # mismatches
        foreach id $ids {
            rdb eval "
                SELECT * FROM $info(table) WHERE id=\$id
            " current {}

            foreach parm [array names current] {
                if {$prev($parm) ne $current($parm)} {
                    set prev($parm) ""
                }
            }
        }

        unset prev(*)

        # NEXT, update the values
        foreach parm [array names values] {
            if {$parm ne "ids"} {
                set values($parm) $prev($parm)
            }
        }
    }


    # clear
    #
    # Clears all parameter values

    typemethod clear {} {
        # FIRST, clear the parameter values
        foreach parm [array names values] {
            # Skip the "ids" parm for multi-update orders
            if {$parm eq "ids" && $info(multi)} {
                continue
            }

            set values($parm) ""
        }

        # NEXT, notify the app that the dialog has been cleared; this
        # will allow it to clear up any entry artifacts.
        notifier send $type <OrderEntry> ""
    }

    # cancel
    #
    # Cancels an order dialog that's in progress, and pops it down.

    typemethod cancel {} {
        if {$info(active)} {
            # FIRST, save the dialog's location
            set geo [wm geometry $dialog]
            set ndx [string first "+" $geo]
            set info(geometry) [string range $geo $ndx end]

            # NEXT, pop down the dialog
            wm withdraw $dialog
            
            # NEXT, delete all of the parameter children
            foreach w [winfo children $parmf] {
                destroy $w
            }

            # NEXT, hide the message widget, if shown
            pack forget $message

            # NEXT, we're no longer active!
            set info(active) 0
            set info(current) ""

            # NEXT, notify the app that no order entry is being done.
            notifier send $type <OrderEntry> ""
        }
    }

    # help
    #
    # Brings up the on-line help for the application
    
    typemethod help {} {
        messagebox popup \
            -buttons {ok OK}                                      \
            -icon    info                                         \
            -parent  [app topwin]                                 \
            -title   "Athena [version]"                          \
            -message "This feature has not yet been implemented."
    }

    #-------------------------------------------------------------------
    # Event handlers

    # ButtonSend
    #
    # Sends the order; on error, reveals the error.

    typemethod ButtonSend {} {
        # FIRST, send the order, and handle any errors
        if {[catch {
            order send "" gui $info(order) [array get values]
        } result opts]} {
            # FIRST, if it's unexpected let the app handle it.
            if {[dict get $opts -errorcode] ne "REJECT"} {
                return {*}$opts $result
            }

            # NEXT, mark the bad parms.
            foreach {parm msg} $result {
                $icon($parm) configure -image ${type}::error_x
            }

            # NEXT, save the error text
            array unset perrors
            array set perrors $result

            # NEXT, if it's not shown, show the message box
            $type Message \
          "Error in order; click in marked entry fields for error messages."

            return 0
        }

        # NEXT, say that it's OK.
        $type Message "The order was accepted."

        # NEXT, notify the app that no order entry is being done; this
        # will allow it to clear up any entry artifacts.
        notifier send $type <OrderEntry> ""

        # NEXT, the order was accepted; we're done here.
        return 1
    }

    # ButtonSendClose
    #
    # Sends the order and closes the dialog on success.

    typemethod ButtonSendClose {} {
        if {[$type ButtonSend]} {
            $type cancel
        }
    }

    # ParmIn parm ptype
    #
    # parm    The parameter name
    # ptype   The parameter data entry type, e.g., text
    #
    # Updates the display when the user is on a particular entry.

    typemethod ParmIn {parm ptype} {
        # FIRST, set the status icon
        set info(current) $parm

        $icon($parm) configure -image ${type}::left_arrow

        # NEXT, if there's an error message, display it.
        if {[info exists perrors($parm)]} {
            set label [order meta $info(order) parms $parm label]
            $type Message "$label: $perrors($parm)"
        } else {
            $type Message ""
        }

        # NEXT, tell the app what kind of parameter this is.
        notifier send $type <OrderEntry> $ptype
    }

    # ParmOut
    #
    # Clears the status icon when the user leaves a particular
    # entry.

    typemethod ParmOut {parm} {
        $icon($parm) configure -image ${type}::blank10x10
    }

    #-------------------------------------------------------------------
    # Entry Type Definition

    # entrytype etype ptype options...
    #
    # etype    An entry type: text | enum | editor
    # ptype    An order parameter type
    # options  Vary by entry type.
    #
    # For all entry types:
    #
    #   -width chars     Width of entry; defaults to 20
    #
    # For enum entry types:
    #
    #   -values list     List of enumerated values
    #   -valuecmd cmd    Command that returns list of enumerated values
    #
    # For editor entry types: -editcmd

    typemethod entrytype {etype ptype args} {
        # TBD: Should do some error checking
        set etypes($ptype) [list $etype $args]
    }

    #-------------------------------------------------------------------
    # Utility Typemethods

    # Message text
    #
    # Opens the message widget, and displays the text.

    typemethod Message {text} {
        # FIRST, normalize the whitespace
        set text [string trim $text]
        set text [regsub {\s+} $text " "]

        # NEXT, pop up the message box the first time text is
        # written to it.
        if {$text ne "" && ![winfo ismapped $message]} {
            pack $message -side top -fill x -after $parmf
        }
        
        # NEXT, display the text.
        $message del 1.0 end
        $message ins 1.0 $text
        $message see 1.0
    }

    #-------------------------------------------------------------------
    # Utility Procs

    # colorpicker color
    #
    # color       A hex color value, or ""
    #
    # Pops up a color picker dialog, displaying the specified color,
    # and allows the user to choose a new color.  Returns the new
    # color, or ""
    proc colorpicker {color} {
        if {$color ne ""} {
            set opts [list -color $color]
        } else {
            set opts ""
        }

        set out [SelectColor::dialog $dialog.colorpicker \
                     -type   dialog                      \
                     -parent $dialog                     \
                     {*}$opts]

        return $out
    }
}

#-----------------------------------------------------------------------
# Entry Types

snit::widgetadaptor enumentry {

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -valuecmd
    #
    # Specifies a command to call to get the values dynamically.

    option -valuecmd

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, install the hull
        installhull using ttk::combobox        \
            -exportselection yes               \
            -state           readonly          \
            -takefocus       1                 \
            -width           20                \
            -postcommand     [mymethod OnPost]

        # NEXT, configure the arguments
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Event Handlers

    # OnPost
    #
    # Called when the dropdown list is posted
    
    method OnPost {} {
        if {$options(-valuecmd) ne ""} {
            $self configure -values [uplevel \#0 $options(-valuecmd)]
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}

snit::widgetadaptor textentry {
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, install the hull
        installhull using ttk::entry    \
            -exportselection yes        \
            -justify         left       \
            -width           20

        # NEXT, configure the arguments
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}

snit::widget editorentry {
    #-------------------------------------------------------------------
    # Components

    component entry    ;# ttk::entry; displays text


    #-------------------------------------------------------------------
    # Options

    delegate option * to entry

    # Command to call when the editor's button is pushed.
    option -editcmd

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, configure the hull
        $hull configure                \
            -borderwidth        0      \
            -highlightthickness 0

        # NEXT, create the entry to display the text.
        install entry using ::ttk::entry $win.entry \
            -exportselection    yes                 \
            -state              readonly            \
            -justify            left                \
            -width              20

        # NEXT, create the button
        ttk::frame $win.bframe  \
            -borderwidth 1      \
            -relief      sunken \

        button $win.bframe.edit \
            -font tinyfont        \
            -text "Edit"          \
            -command [mymethod Edit]

        pack propagate $win.bframe no
        $win.bframe configure                \
            -width  30                       \
            -height [winfo reqheight $entry]

        pack $win.bframe.edit -fill both

        grid $win.entry $win.bframe -sticky nsew
        grid columnconfigure $win 0 -weight 1

        # NEXT, configure the arguments
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Private Methods

    # Edit
    #
    # Called when the Edit button is pressed

    method Edit {} {
        # FIRST, call the editor command given the current data value
        set value [{*}$options(-editcmd) [$entry get]]

        # NEXT, if the value is not "", set it.
        if {$value ne ""} {
            $entry configure -state normal
            $entry delete 0 end
            $entry insert end $value
            $entry configure -state readonly
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to entry

}


#-------------------------------------------------------------------
# Define specific entry types

ordergui entrytype editor color        -editcmd  ::ordergui::colorpicker
ordergui entrytype enum   concern      -values   [econcern names]
ordergui entrytype enum   demeanor     -values   [edemeanor names]
ordergui entrytype enum   forcetype    -values   [eforcetype names]
ordergui entrytype enum   orgtype      -values   [eorgtype names]
ordergui entrytype enum   proximity    -values   [eproximity names]
ordergui entrytype enum   urbanization -values   [eurbanization names]
ordergui entrytype enum   yesno        -values   {Yes No}

ordergui entrytype enum   nbhood       -valuecmd [list nbhood names]
ordergui entrytype enum   civgroup     -valuecmd [list civgroup names]
ordergui entrytype enum   frcgroup     -valuecmd [list frcgroup names]
ordergui entrytype enum   orggroup     -valuecmd [list orggroup names]
ordergui entrytype enum   satgroup     -valuecmd [list sat group names]





