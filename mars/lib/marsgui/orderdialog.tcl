#-----------------------------------------------------------------------
# FILE: orderdialog.tcl
#
#   Mars Order Dialog Manager
#
# PACKAGE:
#   marsgui(n): Mars GUI Infrastructure Package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#    Will Duquette
#
#-------------------------------------------------------------------

namespace eval ::marsgui:: {
    namespace export orderdialog
}

#-----------------------------------------------------------------------
# Widget: orderdialog
#
# The orderdialog(n) widget creates order dialogs for orders defined
# using order(n).  In addition, this module is responsible for 
# creating and managing orderdialog(n) widgets on demand.
#
# This module sends the <OrderEntry> event to indicate what kind of
# parameter is currently being entered.  Because orderdialog(n) is a
# GUI submodule of order(n), it will use the same notifier(n) subject
# as order(n).
#
#-----------------------------------------------------------------------

snit::widget ::marsgui::orderdialog {
    typeconstructor {
        namespace import ::marsutil::*
    }

    #===================================================================
    # Dialog Management
    #
    # This section contains code that manages the collection of dialogs.
    # The actual dialog code appears below.

    #-------------------------------------------------------------------
    # Type Components

    typecomponent rdb    ;# The order(n) -rdb.



    #-------------------------------------------------------------------
    # Type Variables

    # Scalars, etc.
    #
    # initialized      - 1 if initialized, 0 otherwise.
    # appname          - Application name, for use in dialog titles
    # helpcmd          - Help command, for order help
    # parent           - Parent window for dialogs, or command for 
    #                    determining what the parent window is.
    # refreshon        - List of notifier(n) subjects and events that
    #                    trigger a dialog refresh.
    # ftrans           - field option translator commands, by field type.
    # wincounter       - Counter for creating widget names.
    # win-$order       - The dialog's widget name.  We reuse the same name
    #                  - over and over.
    # position-$order  - The dialog's saved geometry (i.e., screen position)

    typevariable info -array {
        initialized   0
        appname       "<set -appname>"
        helpcmd       ""
        parent        ""
        refreshon     {}
        ftrans        {}
        wincounter    0
    }

    #-------------------------------------------------------------------
    # Initialization

    # init ?options?
    #
    # Initializes the order GUI.

    typemethod init {args} {
        # FIRST, we can only initialize once.
        if {$info(initialized)} {
            return
        }

        # NEXT, order(n) must have been initialized.
        require {[order initialized]} "order(n) has not been initialized"

        # NEXT, get the option values
        if {[llength $args] > 0} {
            $type configure {*}$args
        }

        require {$info(parent) ne ""} "-parent is unset"

        # NEXT, create the necessary fonts.
        # TBD: This probably shouldn't go here, but it needs to go 
        # somewhere.
        font create OrderTitleFont {*}[font actual TkDefaultFont] \
            -weight bold                                          \
            -size   -16

        # NEXT, create the initial order dialog names
        foreach order [order names] {
            $type InitOrderData $order
        }

        # NEXT, get the rdb
        set rdb [order cget -rdb]

        # NEXT, register the default field types that need it.
        $type fieldopts enum \
            -enumtype    %?  \
            -displaylong %?

        $type fieldopts key \
            -db       [order cget -rdb] \
            -table    %!                \
            -keys     %!                \
            -labels   %?                \
            -dispcols %?                \
            -widths   %?
    
        $type fieldopts multi \
            -table    %!      \
            -key      %!

        $type fieldopts newkey \
            -db       [order cget -rdb] \
            -table    %!                \
            -universe %!                \
            -keys     %!                \
            -labels   %?                \
            -widths   %?

        # NEXT, note that we're initialized
        set info(initialized) 1
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

    # cget ?option?
    #
    # option  - An option name
    #
    # If option is given, returns the option value.  Otherwise,
    # returns a dictionary of the module configuration options and
    # their values.

    typemethod cget {{option ""}} {
        # FIRST, query an option.
        if {$option ne ""} {
            switch -exact -- $option {
                -appname   { return $info(appname)               }
                -helpcmd   { return $info(helpcmd)               }
                -parent    { return $info(parent)                }
                -refreshon { return $info(refreshon)             }
                default    { error "Unknown option: \"$option\"" }
            }
        } else {
            return [dict create \
                        -appname   $info(appname)    \
                        -helpcmd   $info(helpcmd)    \
                        -parent    $info(parent)     \
                        -refreshon $info(refreshon)]
        }
    }

    # configure ?option value...?
    #
    # option  - An option name
    # value   - An option value
    #
    # Sets the values of one or more module options.

    typemethod configure {args} {
        while {[llength $args] > 0} {
            set option [lshift args]

            if {[llength $args] == 0} {
                error "Option $option: no value given"
            }

            switch -exact -- $option {
                -appname   { set info(appname)   [lshift args]   }
                -helpcmd   { set info(helpcmd)   [lshift args]   }
                -parent    { set info(parent)    [lshift args]   }
                -refreshon { set info(refreshon) [lshift args]   }
                default    { error "Unknown option: \"$option\"" }
            }
        }

        return
    }

    #-------------------------------------------------------------------
    # Field Options
    #
    # An order dialog is based around a form(n) entry form.  Many
    # form(n) field types (e.g., "text") can be used without any
    # additional configuration.  Others, like "key", require many
    # additional options.  The developer has two choices:
    #
    # 1. Define specific form(n) field types for all of the 
    #    required configurations, and use those field types in
    #    the order metadata.
    #
    # 2. Use configurable field types, and require the programmer
    #    to include the relevant configuration options in the
    #    the order metadata.
    # 
    # In case #1, orderdialog(n) doesn't need any additional 
    # information; unconfigurable form(n) field types can be used
    # freely.
    #
    # In case #2, orderdialog(n) needs to know how to configure
    # fields of the given type.  The fieldopts command is used to
    # provide this information.


    # fieldopts fieldType option valspec ?option valspec...?
    #
    # fieldType - A field type registered with form(n)
    # option    - An option taken by that field type
    # valspec   - A string specifying the value the option should
    #             have.
    #
    # If the valspec begins with "%", then it specifies a translation
    # to be done by orderdialog(n); otherwise, it is simply an option
    # value.  The available translations are as follows, where 
    # "<parmOption>" is the name of an option passed to "parm" in the
    # order metadata:
    #
    #    %!<parmOption>
    #        The value is the value of the named order parameter option, 
    #        which is required to be present.
    #
    #    %?<parmOption>
    #        The value is the value of the named order parameter option,
    #        *if* it is present; otherwise, this option is omitted.
    #
    # Often the <parmOption> will have the same name as the field 
    # option; in this case, the <parmOption> can be omitted.

    typemethod fieldopts {fieldType args} {
        dict set info(ftrans) $fieldType $args
    }
    
    #-------------------------------------------------------------------
    # Order Entry

    # enter name ?parmdict?
    # enter name ?parm value...?
    #
    # name       - The name of the order
    # parmdict   - A (partial) dictionary of initial parameter values
    # parm,value - A (partial) dictionary of initial parm values specified
    #              as individual arguments.
    #
    # Begins entry of the specified order:
    #
    # * If the order is not active, the dialog is created with the
    #   initial parmdict, and popped up.
    #
    # * If the order is active, it is given the initial parmdict, and
    #   then receives focus and raised to the top.

    typemethod enter {name args} {
        require {$info(initialized)}    "$type is uninitialized."
        require {[order exists $name]} "Undefined order: \"$name\""

        # FIRST, get the initial parmdict.
        if {[llength $args] > 1} {
            set parmdict $args
        } else {
            set parmdict [lindex $args 0]
        }

        # NEXT, if this is a new order, initialize its data.
        if {![info exists info(win-$name)]} {
            $type InitOrderData $name
        }

        # NEXT, if it doesn't exist, create it.
        #
        # NOTE: If at some point we need special dialogs for some
        # orders, we can add a query to order metadata here.

        if {![$type isactive $name]} {
            # FIRST, Create the dialog for the specified order
            orderdialog $info(win-$name) \
                -order $name
        }

        # NEXT, give the parms and the focus
        $info(win-$name) EnterDialog $parmdict
    }

    # puck tagdict
    #
    # tagdict - A dictionary of tags and values
    #
    # Specifies a dictionary of tags and values that indicate an
    # object or objects selected by the application.  The first
    # tagged value whose tag matches a tag on the current field
    # of the topmost order dialog (if any) will be inserted into
    # that field.

    typemethod puck {tagdict} {
        # FIRST, is there an active dialog?
        set dlg [$type TopDialog]

        if {$dlg eq ""} {
            return
        }

        $dlg ObjectSelect $tagdict
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

    #-------------------------------------------------------------------
    # Helper Typemethods

    # Notify event args...
    #
    # event     - A notifier(n) event
    # args...   - The event arguments
    #
    # Sends the notifier event from the same subject as the
    # the order(n) module.

    typemethod Notify {event args} {
        notifier send [order cget -subject] $event {*}$args
    }

    # Parent
    #
    # Returns the parent window for the order dialogs.
    
    typemethod Parent {} {
        if {[string match ".*" $info(parent)]} {
            return $info(parent)
        } else {
            return [callwith $info(parent)]
        }
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
    # context           Names of all context parms
    # noncontext        Names of all non-context parms
    # table             Name of associated RDB table/view, or ""
    # valid             1 if current values are valid, and 0 otherwise.

    variable my -array {
        parms      {}
        context    {}
        noncontext {}
        table      ""
        valid      0
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
        wm title $win "$info(appname): Send Order"
        
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
        ttk::button $win.tbar.help               \
            -style   Toolbutton                  \
            -image   ::marsgui::icon::question22 \
            -state   normal                      \
            -command [mymethod Help]

        DynamicHelp::add $win.tbar.help -text "Get help!"

        pack $win.tbar.title -side left

        if {$info(helpcmd) ne ""} {
            pack $win.tbar.help  -side right
        }

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
        $form layout [order options $options(-order) -layout]

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

        pack $win.buttons.clear     -side left  -padx {2 15}
        pack $win.buttons.sendclose -side right -padx 2
        pack $win.buttons.send      -side right -padx 2

        # Can't do this above, as it sets the state of the
        # send and sendclose buttons.
        if {[order options $options(-order) -schedulestates] ne ""} {
            pack $win.buttons.when      -side right -padx 2
            pack $win.buttons.schedule  -side right -padx 2

            $whenFld set "NOW+1"
        }

        # NEXT, pack components
        pack $win.tbar    -side top -fill x
        pack $win.form    -side top -fill x -padx 4 -pady 4
        pack $win.message -side top -fill x -padx 4
        pack $win.buttons -side top -fill x -pady 4

        # NEXT, make the window visible, and transient over the
        # current top window.
        osgui mktoolwindow  $win [$type Parent]
        wm attributes $win -topmost 1
        wm deiconify  $win
        raise $win

        # NEXT, if there's saved position, give the dialog the
        # position.
        if {$info(position-$options(-order)) ne ""} {
            wm geometry \
                $info(win-$options(-order)) \
                $info(position-$options(-order))
        }

        # NEXT, refresh the dialog on events from order(n).
        notifier bind \
            [order cget -subject] <State>    $win [mymethod RefreshDialog]
        notifier bind \
            [order cget -subject] <Accepted> $win [mymethod RefreshDialog]

        # NEXT, prepare to refresh the dialog on particular events from
        # the application.
        foreach {subject event} $info(refreshon) {
            notifier bind $subject $event $win [mymethod RefreshDialog]
        }

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
        set order          $options(-order)
        set my(parms)      [order parms $order]
        set my(context)    [list]
        set my(noncontext) [list]
        set my(valid)      0

        # NEXT, Create the fields
        foreach parm $my(parms) {
            # FIRST, get the parameter dictionary
            set pdict [order parm $order $parm]

            # NEXT, create the field
            set ftype [dict get $pdict -fieldtype]

            set opts [$self TranslateFieldOptions $ftype $pdict]

            $form field create $parm [dict get $pdict -label] $ftype {*}$opts

            # NEXT, save whether it's a context or non-context parm; and
            # if it's context, disable it so that the user can't edit it.
            if {[dict get $pdict -context]} {
                lappend my(context) $parm
            } else {
                lappend my(noncontext) $parm
            }
        }
    }


    # TranslateFieldOptions ftype pdict
    #
    # ftype   - A field type
    # pdict   - An order parameter option dictionary

    method TranslateFieldOptions {ftype pdict} {
        # FIRST, if no translation is needed, don't do any.
        if {![dict exists $info(ftrans) $ftype]} {
            return {}
        }

        # NEXT, translate the valspecs
        set opts [list]

        foreach {opt valspec} [dict get $info(ftrans) $ftype] {
            # FIRST, just copy normal values.
            if {[string index $valspec 0] ne "%"} {
                lappend opts $opt $valspec
                continue
            }

            # NEXT, get the translation code and the parm option name
            set code [string range $valspec 0 1]

            if {[string length $valspec] eq 2} {
                set popt $opt
            } else {
                set popt [string range $valspec 2 end]
            }

            # NEXT, translate given the code.
            if {$code eq "%!"} {
                if {![dict exists $pdict $popt]} {
                    error \
               "missing parameter option for field type \"$ftype\": \"$popt\""
                }

                lappend opts $opt [dict get $pdict $popt]
            } elseif {$code eq "%?"} {
                if {[dict exists $pdict $popt]} {
                    lappend opts $opt [dict get $pdict $popt]
                }
            } else {
                error \
          "Unexpected translation code for field type \"$ftype\", option $opt"
            }
        }

        return $opts
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

        # NEXT, verify that all context parameters are included.
        set missing [list]
        foreach cparm $my(context) {
            if {![dict exists $parmdict $cparm]} {
                lappend missing $cparm
            }
        }

        if {[llength $missing] > 0} {
            set msg "Cannot enter $options(-order) dialog, context parm(s) missing: [join $missing {, }]"
            $self Close
            return -code error $msg
        }

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

    method ObjectSelect {tagdict} {
        # FIRST, Get the current field.  If there is none,
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

    # TopDialog
    #
    # Returns the name of the topmost order dialog

    typemethod TopDialog {} {
        foreach w [lreverse [wm stackorder .]] {
            if {[winfo class $w] eq "Orderdialog"} {
                return $w
            }
        }

        return ""
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
        # Mark -context fields
        if {[llength $my(context)] > 0} {
            $form context $my(context)
        }

        # Refresh all fields
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
        set cmd [order options $options(-order) -refreshcmd]
        
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
                set label \
                    [order parm $options(-order) $current -label]
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

        foreach parm $my(noncontext) {
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
        $type Notify <OrderEntry> {}
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
        $type Notify <OrderEntry> {}

        # NEXT, destroy the dialog
        destroy $win
    }

    # Help
    #
    # Brings up the on-line help for the application
    
    method Help {} {
        callwith $info(helpcmd) $options(-order)
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
        $type Notify <OrderEntry> {}

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
                            -parent        [$type Parent]                     \
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

        $type Notify <OrderEntry> $tags
    }

    # SetButtonState
    #
    # Enables/disables the send and schedule buttons based on 
    # whether there are unsaved changes, and whether the data is valid,
    # and so forth.

    method SetButtonState {} {
        # FIRST, the order can be sent if the field values are
        # valid, and if either we aren't checking order states or
        # the order is valid in this state.
        if {$my(valid) &&
            (![order interface cget gui -checkstate] ||
             [order cansend $options(-order)])
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

            # Next, the schedule button is valid if the order can
            # really be scheduled, and not otherwise.
            if {[catch {
                order check ORDER:SCHEDULE    \
                    timespec $timespec        \
                    name     $options(-order) \
                    parmdict {}
            }]} {
                $schedBtn configure -state disabled
            } else {
                $schedBtn configure -state normal
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
        $rdb eval "
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

        $rdb eval $query prev {}
        unset prev(*)

        # NEXT, retrieve the remaining entities, looking for
        # mismatches
        foreach key $keyvals {
            $rdb eval $query current {}

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


