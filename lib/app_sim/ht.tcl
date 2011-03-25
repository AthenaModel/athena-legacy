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
    # Adds the text strings to the buffer, separated by spaces.

    proc put {args} {
        append stack($sp) [join $args " "]

        return
    }

    # putln text...
    #
    # text - One or more text strings
    #
    # Adds the text strings to the buffer, separated by spaces,
    # and *preceded* by a newline.

    proc putln {args} {
        append stack($sp) \n [join $args " "]

        return
    }

    # get
    #
    # Get the text in the main buffer.

    proc get {} {
        return $stack($sp)
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
    # If "else" is given, the buffer is automatically put into
    # the level below, unless it's empty; if it's empty, the
    # body is executed.

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
        putln <title>$title</title>
        putln </head>

        if {$body ne ""} {
            uplevel 1 $body
            /page
        }
    }

    # /page
    #
    # Adds the standard footer boilerplate

    proc /page {} {
        putln <hr>
        putln "<font size=2><i>"

        if {[sim state] eq "PREP"} {
            put "Scenario is unlocked."
        } else {
            put [format "Simulation time: Day %04d, %s." \
                      [simclock now] [simclock asZulu]]
        }

        put [format " -- Wall Clock: %s" [clock format [clock seconds]]]

        put "</i></font>"
        putln "</body></html>"
    }

    # h1 title
    #
    # title  - A title string
    #
    # Returns an HTML H1 title.

    proc h1 {title} {
        putln <h1>$title</h1>
    }

    # h2 title
    #
    # title  - A title string
    #
    # Returns an HTML H2 title.

    proc h2 {title} {
        putln <h2>$title</h2>
    }

    # h3 title
    #
    # title  - A title string
    #
    # Returns an HTML H3 title.

    proc h3 {title} {
        putln <h3>$title</h2>
    }

    # tinyb text
    #
    # text - A text string
    #
    # Sets the text in tiny bold.

    proc tinyb {text} {
        put "<font size=2><b>$text</b></font>"
    }

    # tinyi text
    #
    # text - A text string
    #
    # Sets the text in tiny italics.

    proc tinyi {text} {
        put "<font size=2><i>$text</i></font>"
    }

    # ul ?body?
    #
    # body    - A body script
    #
    # Begins an unordered list. If the body is given, it is executed and 
    # the </ul> is added automatically.
   
    proc ul {{body ""}} {
        putln <ul>

        if {$body ne ""} {
            uplevel 1 $body
            /ul
        }
    }

    # li
    #
    # body    - A body script
    #
    # Begins a list item.  If the body is given, it is executed and 
    # the </li> is added automatically.
    
    proc li {{body ""}} {
        putln <li>

        if {$body ne ""} {
            uplevel 1 $body
            put </li>
        }

    }

    # /ul
    #
    # Ends an unordered list
    
    proc /ul {} {
        putln </ul>
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

    # linklist ?options...? links
    #
    # links  - A list of links and labels
    #
    # Options:
    #   -delim   - Delimiter; defaults to ", "
    #   -default - String to put if list is empty; defaults to ""
    #
    # Formats and returns a list of HTML links.

    proc linklist {args} {
        # FIRST, get the options
        set links [lindex $args end]
        set args  [lrange $args 0 end-1]

        array set opts {
            -delim   ", "
            -default ""
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -delim   -
                -default {
                    set opts($opt) [lshift args]
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # NEXT, build the list of links.
        set list [list]
        foreach {url label} $links {
            lappend list "<a href=\"$url\">$label</a>"
        }

        set result [join $list $opts(-delim)]

        if {$result ne ""} {
            put $result
        } else {
            put $opts(-default)
        }
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
        putln "<table border=1 cellpadding=2 cellspacing=0>"
        putln "<tr align=left>"

        foreach header $headers {
            put "<th align=left>$header</th>"
        }
        put </tr>

        if {$body ne ""} {
            uplevel 1 $body
            /table
        }
    }

    # tr ?body?
    #
    # body    - A body script
    #
    # Begins a standard table row.  If the body is included,
    # it is executed, and the </tr> is included automatically.
    
    proc tr {{body ""}} {
        putln "<tr valign=top>"

        if {$body ne ""} {
            if {$body ne ""} {
                uplevel 1 $body
                /tr
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
        putln <td>
        if {$body ne ""} {
            uplevel 1 $body
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
        putln <td align=right>
        if {$body ne ""} {
            uplevel 1 $body
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

    # image name
    #
    # name - A Tk image name
    #
    # Adds an in-line <img>.

    proc image {name} {
        put "<img src=\"/image/$name\">"
    }
}

