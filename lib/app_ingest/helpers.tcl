#-----------------------------------------------------------------------
# TITLE:
#    helpers.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_ingest(1): Helper commands
# 
#-----------------------------------------------------------------------

# coalesce ?value...?
#
# value...  - Any number of values.
#
# Returns the first value that isn't the empty string.

proc coalesce {args} {
    foreach value $args {
        if {$value ne ""} {
            return $value
        }
    }

    return ""
}

# enscript template ?token value...?
#
# template    - A Tcl code template
# token       - A [string map] replacement token
# value       - The value to replace the token with
#
# Substitutes the tokens for values in the template, and returns the
# template.  In addition, enscript:
#
# * Replaces \\ with \
# * Outdents the code to the left margin.

proc enscript {template args} {
    lappend args "\\\\" \\
    return [string map $args [outdent $template]]
}
