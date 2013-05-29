#-----------------------------------------------------------------------
# TITLE:
#    smart_type.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectlib(n): Smart Type Infrastructure
#    
#    A smart type is a data validation type whose values represent different
#    ways of specifying a data value of interest.  For example, there are many
#    ways to specify a list of civilian groups: an explicit list, all groups
#    resident in a particular neighborhood or neighborhoods, all groups who
#    support a particular actor, and so forth.
#
#    The value of a smart type is a value dictionary, or vdict.  It will 
#    always have a field called "mode", whose value indicates the algorithm
#    to use to find the data value or values of interest.  Other fields
#    will vary from smart type to smart type.
#
#    See smart_type(i) for the methods that a smart type object must 
#    implement.
#
#    This module defines a constructor for smart types.  Each smart type
#    has an ensemble command

namespace eval ::projectlib:: {
    namespace export smart_type
}

# smart_type name dynaform body
#
# name      - The name of the smart type, e.g., smart_civgroups
# dynaform  - A dynaform to use for editing values of this smart type.
#             It will have the same name as the type.
# body      - A type-definition body that defines the type's methods.

proc ::projectlib::smart_type {name dynaform body} {
    set prefix {
        pragma -hasinstances no

        typemethod dynaform {} {
            return "$type.form"
        }
    }

    set fullname [uplevel 1 [list snit::type $name "$prefix\n\n$body"]]
    dynaform define "$fullname.form" $dynaform
    return
}

