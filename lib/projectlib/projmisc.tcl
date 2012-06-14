#-----------------------------------------------------------------------
# TITLE:
#    projmisc.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: Miscellaneous helper commands.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectlib:: {
    namespace export     \
        dict2urlquery    \
        urlquery2dict
}

# dict2urlquery dict
#
# dict   - A parameter dictionary
#
# Given a dictionary of parameter names and values, creates
# a URL query string, e.g., from
#
#    a 1 b 2
#
# creates 
#
#    a=1+b=2
#
# Neither names nor values may contain "=" or "+"; however, this
# is not checked.  If a value is the empty string, the "=" is omitted.

proc ::projectlib::dict2urlquery {dict} {
    set list ""

    dict for {parm value} $dict {
        if {$value ne ""} {
            lappend list "$parm=$value"
        } else {
            lappend list $parm
        }
    }

    return [join $list "+"]
}

# urlquery2dict query
#
# query  - A URL query string, e.g., a=1+b=2
#
# Converts the query string into a parameter dictionary.  It is assumed
# that the names and parameters do not contain = or +.  If a name has
# no corresponding =, the name goes in the dictionary with an empty
# value.  If a name has multiple ='s, the second and subsequent are
# ignored.

proc ::projectlib::urlquery2dict {query} {
    # FIRST, split the query on "+"
    set items [split $query "+"]

    # NEXT, handle each one individually.
    set qdict [dict create]

    foreach item $items {
        lassign [split $item "="] parm value

        dict set qdict $parm $value
    }

    return $qdict
}
