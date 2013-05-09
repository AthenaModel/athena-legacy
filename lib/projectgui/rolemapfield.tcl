#-----------------------------------------------------------------------
# TITLE:
#    rolemapfield.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Role map editing widget
#
#    A rolemapfield is a data entry field that allows the user to
#    selects list of entities for multiple roles.  The field value
#    is a dictionary, <role> -> <list of values>.  This is intended
#    for editing roles for the CURSE tactic, but it is really a 
#    generic dictionary of lists editor, where the collection of 
#    roles and valid lists is dynamically configurable.
#
#    In addition, this module defines a "rolemap" dynaform_field(i) type,
#    so that "rolemap" fields can be used in dynaforms.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export rolemapfield
}

#-------------------------------------------------------------------
# rolemapfield

snit::widget ::projectgui::rolemapfield {
    hulltype ttk::frame

    #-------------------------------------------------------------------
    # Components

    component form       ;# a form(n) containing the listfields and their
                         ;# labels.
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    delegate option -state to form

    # -changecmd cmd
    #
    # cmd is called when the field's value changes; the new value is appended
    # to the field as an argument.

    option -changecmd

    # -rolespec spec
    #
    # This option fully configures the data to be edited.  The spec is a
    # dictionary <rolename> -> <valid list>.  The form will be set to 
    # contain set of labels and listfields, where the <rolename> is the
    # label string, and the listfield is defined for the matching valid list.
    option -rolespec \
        -configuremethod ConfigRoleSpec

    method ConfigRoleSpec {opt val} {
        if {$val ne $options($opt)} {
            set options($opt) $val
        
            $self UpdateDisplay
        }
    }

    # -listheight num
    #
    # Number of rows to display in each listfield.  Changes take effect 
    # when the -rolespec is changed.
    
    option -listheight \
        -default         5

    # -liststripe flag
    #
    # If 1, the lists are striped; otherwise not. Changes take effect 
    # when the -rolespec is changed.

    option -liststripe \
        -default         1


    # -listwidth num
    #
    # Width in characters of each listfield's list boxes.  Changes take effect 
    # when the -rolespec is changed.
    
    option -listwidth \
        -default         10

    #-------------------------------------------------------------------
    # Instance Variables

    # TBD

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the components.  There's really only a form,
        # that we'll populate when -rolespec changes.
        install form using form $win.form \
            -changecmd [mymethod FormChangeCmd]

        pack $form -side top -fill both -expand yes
        
        # NEXT, configure options
        $self configurelist $args
    }        

    #-------------------------------------------------------------------
    # Private Methods

    # FormChangeCmd field
    #
    # field   A field in the form, i.e., a role name.
    #
    # Called when the form's content changes.  This routine 
    # sets the invalid flag, and calls the client's change command

    method FormChangeCmd {field} {
        set fields [list]

        foreach {role value} [$form get] {
            if {[llength $value] == 0} {
                lappend fields $role
            }
        }

        $form invalid $fields

        callwith $options(-changecmd) [$form get]
    }

    # UpdateDisplay
    #
    # This method is called when a new -rolespec 
    # value is given.  It clears any included values, and resets the
    # display.

    method UpdateDisplay {} {
        # FIRST, delete any existing content.
        $form clear

        # NEXT, add listfields for each role
        foreach {role values} $options(-rolespec) {
            # FIRST, create the item dict
            set itemdict [dict create]
            foreach value $values {
                dict set itemdict $value $value
            }

            # NEXT, create the listfield
            $form field create $role $role list \
                -showkeys no                    \
                -height   $options(-listheight) \
                -stripe   $options(-liststripe) \
                -width    $options(-listwidth)  \
                -itemdict $itemdict
        }

        # NEXT, layout the widget.
        $form layout

        # NEXT, all roles are initially invalid (no items are selected)
        $form invalid [dict keys $options(-rolespec)]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method get to form
    delegate method set to form
}

#-----------------------------------------------------------------------
# rolemap field type

::marsutil::dynaform fieldtype define rolemap {
    typemethod attributes {} {
        return {
            rolespeccmd 
            listheight
            liststripe
            listwidth
        }
    }

    typemethod validate {idict} {
        dict with idict {}
        require {$rolespeccmd ne ""} \
            "No role specification command given"
    }

    typemethod create {w idict} {
        set context [dict get $idict context]

        rolemapfield $w \
            -state [expr {$context ? "disabled" : "normal"}] \
            {*}[asoptions $idict listheight liststripe listwidth]
    }

    typemethod reconfigure {w idict vdict} {
        # If the field has a -rolespeccmd, call it and apply the
        # results (note that rolemapfield will properly do nothing
        # if the resulting spec hasn't changed.)
        dict with idict {}

        if {$rolespeccmd ne ""} {
            $w configure -rolespec [formcall $vdict $rolespeccmd] 
        }
    }

    typemethod ready {w idict} {
        return [expr {[llength [$w cget -rolespec]] > 0}]
    }
}


