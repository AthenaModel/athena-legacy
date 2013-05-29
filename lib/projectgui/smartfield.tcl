#-----------------------------------------------------------------------
# TITLE:
#    smartfield.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Smart type data entry field
#
#    A smartfield is a data entry field that displays the narrative for
#    a smart type value, and has an Edit button popping up a dynabox for
#    the smart type.
#
#    In addition to the widget, this file also defines the "smart"
#    dynaform_field(i) type.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export smartfield
}

#-------------------------------------------------------------------
# smartfield

snit::widget ::projectgui::smartfield {
    #-------------------------------------------------------------------
    # Components

    component nlabel   ;# ttk::label; displays narrative text
    component editbtn  ;# Edit button

    #-------------------------------------------------------------------
    # Options

    delegate option -background  to hull
    delegate option -borderwidth to hull
    delegate option *               to nlabel

    # -typename smart_type
    #
    # Name of the smart type being edited.

    option -typename

    # -state state
    #
    # state must be "normal" or "disabled".

    option -state                     \
        -default         "normal"     \
        -configuremethod ConfigState

    method ConfigState {opt val} {
        set options($opt) $val
        
        if {$val eq "normal"} {
            $editbtn configure -state normal
        } elseif {$val eq "disabled"} {
            $editbtn configure -state disabled
        } else {
            error "Invalid -state: \"$val\""
        }
    }

    # -changecmd command
    # 
    # Specifies a command to call whenever the field's content changes
    # for any reason.  The new value is appended to the command as a 
    # single argument.

    option -changecmd \
        -default ""

    #-------------------------------------------------------------------
    # Instance Variables

    # info array
    #
    # value  - The current value of the widget

    variable info -array {
        value ""
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, configure the hull
        $hull configure                \
            -borderwidth        0      \
            -relief             flat   \
            -highlightthickness 0

        # NEXT, create a frame to be a border around the label.
        ttk::frame $win.nframe \
            -borderwidth        1      \
            -relief             sunken

        # NEXT, create the label to display the narrative.
        # TBD: Put it into a frame, to give it a border.
        install nlabel using ::ttk::label $win.nframe.nlabel \
            -takefocus  yes \
            -width      -30 \
            -wraplength 300

        pack $nlabel -fill both -expand yes

        # NEXT, create the edit button
        install editbtn using button $win.edit \
            -state     normal                         \
            -font      tinyfont                       \
            -text      "Edit"                         \
            -takefocus 0                              \
            -command   [mymethod Edit]

        pack $editbtn    -side right -fill y -padx {2 0}
        pack $win.nframe -fill both

        # NEXT, configure the arguments
        $self configure -state normal {*}$args
    }

    #-------------------------------------------------------------------
    # Private Methods

    # Edit
    #
    # Called when the Edit button is pressed

    method Edit {} {
        # FIRST, give focus to this field
        focus $win

        # NEXT, get the dynaform name.
        set form [{*}$options(-typename) dynaform]

        # NEXT, call the dynabox given the current data value
        set value [dynabox popup             \
            -formtype    $form               \
            -initvalue   $info(value)        \
            -parent      $win                \
            -title       "Edit Field Value"  \
            -validatecmd [mymethod Validate]]

        # NEXT, if the value is not "", set it.
        if {$value ne ""} {
            $self set $value
        }
    }

    # Validate value
    #
    # value   - The value of the dynaform
    #
    # Validates the value; when valid, returns a preview.

    method Validate {value} {
        # FIRST, validate it; the validate command will throw INVALID
        # on error.
        {*}$options(-typename) validate $value

        # NEXT, return the preview
        return [$self Preview $value]
    }

    # Preview value
    #
    # value  - The form value
    #
    # Returns a preview string of the narrative text.

    method Preview {value} {
        return "Rule: [{*}$options(-typename) narrative $value -brief]"
    }

    #-------------------------------------------------------------------
    # Public Methods

    # get
    #
    # Retrieves the widget's value.

    method get {} {
        return $info(value)
    }

    # set value
    #
    # value  - A new value
    #
    # Sets the widget's value to the new value.

    method set {value} {
        # FIRST, if it's not a change do nothing.
        if {$value eq $info(value)} {
            return
        }

        # NEXT, save the value
        set info(value) $value

        # NEXT, save the narrative
        $nlabel configure -text [$self Preview $value]

        callwith $options(-changecmd) $value
    }
}

#-----------------------------------------------------------------------
# smart field type
#
# This is a dynaform field type to use with smart types.

::marsutil::dynaform fieldtype define smart {
    typemethod attributes {} {
        return {
            typename wraplength width
        }
    }

    typemethod validate {idict} {
        dict with idict {}
        require {$typename ne ""} \
            "No smart type name command given"
    }

    typemethod create {w idict} {
        set context [dict get $idict context]

        set wid [dict get $idict width]

        # This widget works better if the width is negative, setting a
        # minimum size.  Then it can widen to the wraplength.
        if {$wid ne "" && $wid > 0} {
            dict set idict width [expr {-$wid}]
        }

        smartfield $w \
            -state [expr {$context ? "disabled" : "normal"}] \
            {*}[asoptions $idict typename wraplength width]
    }
}

