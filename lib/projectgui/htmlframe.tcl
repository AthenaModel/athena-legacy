#-----------------------------------------------------------------------
# TITLE:
#    htmlframe.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: geometry manager widget using HTML/CSS
#    to control layout of widgets.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export htmlframe
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor ::projectgui::htmlframe {
    #-------------------------------------------------------------------
    # Type constructor

    typeconstructor {
        namespace import ::marsutil::* ::marsgui::*
    }

    #-------------------------------------------------------------------
    # Options

    # Delegate all options to the hull frame
    delegate option * to hull

    #-------------------------------------------------------------------
    # Instance Variables

    # TBD

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the hull.
        installhull using htmlviewer3 \
            -shrink yes

        # NEXT, add a node handler for <input> tags.
        $hull handler node input [mymethod InputCmd]

        # NEXT, get the options
        $self configurelist $args
    }

    # InputCmd node
    # 
    # node    - htmlviewer3 node handle
    #
    # An <input> element was found in the input.  This callback replaces the
    # element with the child widget having the same name as the element,
    # should the child exist.

    method InputCmd {node} {
        # FIRST, get the attributes of the object.
        set name [$node attribute -default "" name]

        if {$name ne ""} {
            set iwin $win.$name

            if {[winfo exists $iwin]} {
                $node replace $iwin
            }
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method *      to hull
    delegate method layout to hull as set


    # set id attribute value
    #
    # id         - An element id, set using the "id" or "name" attribute
    # attribute  - An attribute name
    # value      - A new attribute value
    #
    # Sets the attribute value for the first element with the given ID
    # or NAME.  Looks for ID first.

    method set {id attribute value} {
        set node [lindex [$hull search "#$id"] 0]

        if {$node eq ""} {
            set node [lindex [$hull search "\[name=\"$id\"\]"] 0]
        }

        require {$node ne ""} "unknown element id: \"$id\""

        $node attribute $attribute $value
        return
    }
    
    # get id attribute
    #
    # id         - An element id, set using the "id" or "name" attribute
    # attribute  - An attribute name
    #
    # Gets the value of the named attribute for the first element with 
    # the given ID or NAME.  Looks for ID first.

    method get {id attribute} {
        set node [lindex [$hull search "#$id"] 0]

        if {$node eq ""} {
            set node [lindex [$hull search "\[name=\"$id\"\]"] 0]
        }

        require {$node ne ""} "unknown element id: \"$id\""

        return [$node attribute $attribute]
    }
}

