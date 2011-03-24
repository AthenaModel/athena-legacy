#-----------------------------------------------------------------------
# TITLE:
#    ht.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n): HTML tools.
#
#    The commands in this module aid in the generation of HTML text
#    by the appserver.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# ht singleton

snit::type ht {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Variables

    # Stack pointer
    typevariable sp 0

    # stack: buffer stack
    #
    # $num - Buffer 
    
    typevariable stack -array {
        0  {}
    }

    #-------------------------------------------------------------------
    # Commands for building up HTML in the buffer

    # put text...
    #
    # text - One or more text strings
    #
    # Adds the text strings to the buffer, separated by spaces, 
    # plus a newline on the end.

    proc put {args} {
        append stack($sp) [join $args " "] \n

        return
    }

    # add text...
    #
    # text - One or more text strings
    #
    # Adds the text strings to the buffer, separated by spaces.

    proc add {args} {
        append stack($sp) [join $args " "]

        return
    }

    # get
    #
    # Get the text in the main buffer.

    proc get {} {
        return $stack(0)
    }

    # clear
    #
    # Clears the buffer for new stuff.

    proc clear {} {
        array unset stack
        set sp 0
        set stack($sp) ""
    }

    # push
    #
    # Pushes a new buffer on the stack.

    proc push {} {
        incr sp
        set stack($sp) ""
    }

    # pop
    #
    # Pops a buffer off of the stack, and returns its contents.

    proc pop {} {
        if {$sp <= 0} {
            error "stack underflow"
        }

        set result $stack($sp)
        incr sp -1

        return $result
    }

    #-------------------------------------------------------------------
    # HTML Commands

    # page title
    #
    # title  - Title of HTML page
    # body   - A body script
    #
    # Adds the standard header boilerplate; also clears the buffer
    # stack.  If the body is given, it is executed and the /page
    # footer is added automatically.

    proc page {title {body ""}} {
        clear

        put <html><head>
        put <title>$title</title>
        put </head>

        if {$body ne ""} {
            uplevel 1 $body
            /page
        }
    }

    # /page
    #
    # Adds the standard footer boilerplate

    proc /page {} {
        put <hr>
        add "<font size=2><i>"

        if {[sim state] eq "PREP"} {
            add "Scenario is unlocked."
        } else {
            add [format "Simulation time: Day %04d, %s." \
                      [simclock now] [simclock asZulu]]
        }

        add [format " -- Wall Clock: %s" [clock format [clock seconds]]]

        put "</i></font>"
        put "</body></html>"
    }

    # h1 title
    #
    # title  - A title string
    #
    # Returns an HTML H1 title.

    proc h1 {title} {
        put <h1>$title</h1>
    }

    # h2 title
    #
    # title  - A title string
    #
    # Returns an HTML H2 title.

    proc h2 {title} {
        put <h2>$title</h2>
    }

    # h3 title
    #
    # title  - A title string
    #
    # Returns an HTML H3 title.

    proc h3 {title} {
        put <h3>$title</h2>
    }

    # ul ?body?
    #
    # body    - A body script
    #
    # Begins an unordered list. If the body is given, it is executed and 
    # the </ul> is added automatically.
   
    proc ul {{body ""}} {
        put <ul>

        if {$body ne ""} {
            put [uplevel 1 $body]
            put </ul>
        }
    }

    # li
    #
    # body    - A body script
    #
    # Begins a list item.  If the body is given, it is executed and 
    # the </li> is added automatically.
    
    proc li {{body ""}} {
        put <li>

        if {$body ne ""} {
            put [uplevel 1 $body]
            put </li>
        }

    }

    # /ul
    #
    # Ends an unordered list
    
    proc /ul {} {
        put </ul>
    }

    # para
    #
    # Adds a paragraph mark.
    
    proc para {} {
        put <p>
    }

    # link url label
    #
    # url    - A resource URL
    # label  - A text label
    #
    # Formats and returns an HTML link.

    proc link {url label} {
        put "<a href=\"$url\">$label</a>"
    }

    # table headers ?body?
    #
    # headers - A list of column headers
    # body    - A body script
    #
    # Begins a standard table with the specified column headers.
    # If the body is given, it is executed and the </table> is
    # added automatically.

    proc table {headers {body ""}} {
        put "<table border=1 cellpadding=2 cellspacing=0>"
        put "<tr align=left>"

        foreach header $headers {
            put "<th align=left>$header</th>"
        }
        put </tr>

        if {$body ne ""} {
            put [uplevel 1 $body]
            put </table>
        }
    }

    # tr ?body?
    #
    # body    - A body script
    #
    # Begins a standard table row.  If the body is included,
    # it is executed, and the </tr> is included automatically.
    
    proc tr {{body ""}} {
        put "<tr valign=top>"

        if {$body ne ""} {
            if {$body ne ""} {
                put [uplevel 1 $body]
                put </tr>
            }
        }
    }

    # td ?body?
    #
    # body    - A body script
    #
    # Formats a standard table item; if the body is included,
    # it is executed, and the </td> is included automatically.
    
    proc td {{body ""}} {
        put <td>
        if {$body ne ""} {
            put [uplevel 1 $body]
            put </td>
        }
    }

    # td-right ?body?
    #
    # body    - A body script
    #
    # Formats a right-justified table item; if the body is included,
    # it is executed, and the </td> is included automatically.
    
    proc td-right {{body ""}} {
        put <td align=right>
        if {$body ne ""} {
            put [uplevel 1 $body]
            put </td>
        }
    }

    # /td
    #
    # ends a standard table item
    
    proc /td {} {
        put </td>
    }

    # /tr
    #
    # ends a standard table row
    
    proc /tr {} {
        put </tr>
    }

    # /table
    #
    # Ends a standard table with the specified column headers

    proc /table {} {
        put </table>
    }
}

