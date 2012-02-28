#-----------------------------------------------------------------------
# TITLE:
#    macro.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_helptool(n): ehtml(5) macro definitions
#
#    This module contains the ehtml(5) macro definitions needs by the
#    help compiler.
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# ehtml(5) extensions

namespace eval ::macro:: {
    namespace eval ::macro::user {}

    variable docInfo   ;# Array of information about the document as a
                        # whole.
    variable pageInfo  ;# Array of information about the current page.

    namespace export \
        childlinks   \
        cref         \
        enumdoc      \
        pageinfo     \
        parmlist     \
        parm         \
        /parm        \
        /parmlist    \
        title        \
        topiclist    \
        topic        \
        /topic       \
        /topiclist   \
        version
}

# childlinks ?name?
#
# name - A page name
#
# Returns a <ul>...</ul> list of links to the children of the
# named page.  Defaults to the current page.

proc macro::childlinks {{parent ""}} {
    variable pageInfo

    # FIRST, get the parent name.
    if {$parent eq ""} {
        set parent $pageInfo(name)
    }

    # NEXT, get the children
    set out "<ul>\n"

    hdb eval {SELECT name,title FROM helpdb_pages WHERE parent=$parent} {
        append out "<li> <a href=\"$name\">$title</a>\n"
    }

    append out "</ul>\n"

    return $out
}

# cref uri ?text?
#
# uri     - A page URI, name?#anchor?
# text    - The link text.  Defaults to the page title.
#
# Cross-reference link to the named page.

proc macro::cref {uri {text ""}} {
    lassign [split $uri "#"] name anchor

    require {$name ne ""} "uri has no page name: \"$uri\""

    if {[hdb page exists $name]} {
        if {$text eq ""} {
            set text [hdb page title $name]
        }
    } else {
        if {$text eq ""} {
            set text $name
        }

        set text "TBD: $text"

        puts "On \"[pageinfo name]\", broken link to: \"$name\""
    }

    return "<a href=\"$uri\">$text</a>"
}

# enumdoc enum
#
# enum   - An enum(n) type.
#
# The built-in enum(n) "html" method produces bad results for this use.
# This is an alternate that looks nicer.

template macro::enumdoc {enum} {
    set names [{*}$enum names]
} {
    |<--
    <table cellspacing=0>
    <tr><th align="left">Symbol&nbsp;</th><th align="left">Meaning</th></tr>
    [tforeach name $names {
        |<--
        <tr>
        <td><tt>$name</tt>&nbsp;</td>
        <td>[{*}$enum longname $name]</td>
        </tr>
    }]
    </table>
}

# pageinfo field
#
# field   - name|title|parent
#
# Returns information about the page currently being expanded.

proc macro::pageinfo {field} {
    variable pageInfo

    return $pageInfo($field)
}

# parmlist
#
# Begins a list of order parameters

template macro::parmlist {} {
    |<--
    <table border width="100%" cellspacing="0" cellpadding="4"> 
    <tr>
    <th align="left">Field</th> 
    <th align="left">Description</th>
    </tr>
}

# parm parm field
#
# parm     - The order parameter name
# field    - The field label
#
# Begins a parameter description.

template macro::parm {parm field} {
    |<--
    <tr valign="baseline">
    <td><b>$field</b><br>(<tt>$parm</tt>)</td>
    <td>
}

# /parm
#
# Ends a parameter description
template macro::/parm {} {
    </td>
    </tr>
}

# /parmlist
#
# Ends a list of order parameters
template macro::/parmlist {} {
    |<--
    </table>
}

# topiclist ?h1 ?h2?
#
# h1    - Header for column 1; defaults to Topic
# h2    - Header for column 2; defaults to Description
#
# Begins a table of topics and descriptions

template macro::topiclist {{h1 Topic} {h2 Description}} {
    |<--
    <table border width="100%" cellspacing="0" cellpadding="4"> 
    <tr>
    <th align="left">$h1</th> 
    <th align="left">$h2</th>
    </tr>
}

# topic topic
#
# topic    - The topic label
#
# Begins a topic description.

template macro::topic {topic} {
    |<--
    <tr valign="baseline">
    <td><b>$topic</b></td>
    <td>
}

# /topic
#
# Ends a topic description
template macro::/topic {} {
    </td>
    </tr>
}

# /topiclist
#
# Ends a list of topics
template macro::/topiclist {} {
    |<--
    </table>
}


# version
#
# Returns the -version.

proc macro::version {} {
    variable docInfo
    
    return $docInfo(version)
}
