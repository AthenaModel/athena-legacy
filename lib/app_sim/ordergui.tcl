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
        text ::textentry
        enum ::enumentry
    }

    #-------------------------------------------------------------------
    # Dialog Definition data


    # Array of meta dicts by order name.
    typevariable meta -array {}


    #-------------------------------------------------------------------
    # Type Variables

    # info array: scalar variables
    #
    #  active      1 if dialog is visible, 0 otherwise
    #  current     Current parameter
    #  message     message to be displayed on the dialog
    #  order       If active, name of the order to send
    #  title       If active, the order's title

    typevariable info -array {
        active      0
        current     ""
        initialized 0
        order       ""
        title       ""
    }

    #-------------------------------------------------------------------
    # Transient Data used while active

    # etypes array: Entry widget types by parameter type
    typevariable etypes -array { }

    # values array: entered data by parm name.
    typevariable values -array { }

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
        wm title $dialog "Send Order"

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

        ttk::button $dialog.buttons.send       \
            -text    "Send"                    \
            -width   8                         \
            -command [mytypemethod ButtonSend]

        ttk::button $dialog.buttons.cancel   \
            -text    "Cancel"                \
            -width   8                       \
            -command [mytypemethod cancel]

        pack $dialog.buttons.cancel -side right -padx 2
        pack $dialog.buttons.send   -side right -padx 2


        # NEXT, pack components
        pack $dialog.title   -side top -fill x
        pack $dialog.parmf   -side top -fill x -padx 4 -pady 4
        pack $dialog.buttons -side top -fill x

        # NEXT, note that we're initialized
        set info(initialized) 1
    }

    #-------------------------------------------------------------------
    # Public Type Methods

    # define name metadata
    
    # name        The name of the order
    # metadata    A dictionary of meta-data about the order.
    #
    # Defines meta-data for the order that defines the order's dialog.

    typemethod define {name metadata} {
        # NEXT, save the metadata
        set meta($name) $metadata
    }

    # meta order key ?key...?
    #
    # order     The name of an order
    # key...    Keys into the meta dictionary
    #
    # Returns the result of "dict get" on the meta dictionary

    typemethod meta {order args} {
        return [dict get $meta($order) {*}$args]
    }
    
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
        return [$type meta $info(order) parms $parm ptype]
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

        # NEXT, get the parm type
        set values($parm) $value
    }


    # enter parent order
    #
    # parent   The parent window
    # order    The name of an order
    #
    # Sets up the dialog for entry of the specified order, and pops
    # up the window.

    typemethod enter {parent order} {
        require {$info(initialized)} "Order dialog is uninitialized"
        require {!$info(active)}     "Order dialog is already active"

        # FIRST, get the order's title
        set info(order) $order
        set info(title) [$type meta $order title]
        array unset values
        array unset icon
        array unset perrors
        
        # NEXT, add the parameter fields
        set row -1
        
        dict for {parm pdict} [$type meta $order parms] {
            # FIRST, get the current row
            incr row

            # NEXT, no value is specified initially
            set values($parm) ""

            # NEXT, get the parameter type.
            set ptype [dict get $pdict ptype]

            # NEXT, get the entry type and args.  If no entry type
            # is know for this parameter type, we treat it as a standard
            # text entry.
            if {[info exists etypes($ptype)]} {
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
            $ewidget($etype) $parmf.entry$row {*}$eoptions \
                -textvariable [mytypevar values($parm)]

            bind $parmf.entry$row <FocusIn> \
                [mytypemethod ParmIn $parm $ptype]
            bind $parmf.entry$row <FocusOut> \
                [mytypemethod ParmOut $parm]

            # Status Icon
            ttk::label $parmf.icon$row \
                -image ${type}::blank10x10

            set icon($parm) $parmf.icon$row

            grid $parmf.label$row -row $row -column 0 -sticky w 
            grid $parmf.entry$row -row $row -column 1 -sticky ew -padx 2
            grid $parmf.icon$row  -row $row -column 2 -sticky nsew
        }

        # NEXT, raise the window and set the focus
        wm transient $dialog $parent
        wm deiconify $dialog
        raise $dialog
        focus $parmf.entry0


        # NEXT, wait for visibility
        update idletasks

        # NEXT, we're active!
        set info(active) 1
    }

    # cancel
    #
    # Cancels an order dialog that's in progress, and pops it down.

    typemethod cancel {} {
        if {$info(active)} {
            # FIRST, pop down the dialog
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

    #-------------------------------------------------------------------
    # Event handlers

    # ButtonSend
    #
    # Sends the order; on error, reveals the error.

    typemethod ButtonSend {} {
        # FIRST, send the order, and handle any errors
        if {[catch {
            order send "" client $info(order) [array get values]
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

            return
        }

        # NEXT, the order was accepted; we're done here.
        $type cancel
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
            set label [$type meta $info(order) parms $parm label]
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
    # etype    An entry type: text | enum
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

