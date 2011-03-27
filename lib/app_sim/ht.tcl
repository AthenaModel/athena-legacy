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

    # Transient values used by ht::query
    typevariable qnames      ;# List of column names
    typevariable qrow        ;# Row of queried data.
    typevariable qcol        ;# Column name

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

    # putif expr then ?else?
    #
    # expr   - An expression
    # then   - A string
    # else   - A string, defaults to ""
    #
    # If expr, puts then, otherwise puts else.

    proc putif {expr then {else ""}} {
        if {[uplevel 1 [list expr $expr]]} {
            put $then
        } else {
            put $else
        }
    }

    # query sql ?options...?
    #
    # sql           An SQL query.
    # options       Formatting options
    #
    # -labels list    - List of column labels
    # -default text   - Text to return if there's no data found.
    #                   Defaults to "No data found.<p>"
    #
    # Executes the query and accumulates the results as HTML.

    proc query {sql args} {
        # FIRST, get options.
        array set opts {
            -labels   {}
            -default  "No data found.<p>"
        }
        array set opts $args

        # FIRST, begin the table
        push

        # NEXT, if we have labels, use them.
        if {[llength $opts(-labels)] > 0} {
            table $opts(-labels)
        }

        # NEXT, get the data.  Execute the query as an uplevel,
        # so that we can use variables.
        set ::ht::qnames {}

        uplevel 1 [list rdb eval $sql ::ht::qrow {
            # FIRST, get the column names.
            if {[llength $::ht::qnames] == 0} {
                set ::ht::qnames $::ht::qrow(*)
                unset ::ht::qrow(*)

                if {[ht::get] eq ""} {
                    ::ht::table $::ht::qnames
                }
            }

            ::ht::tr {
                foreach ::ht::qname $::ht::qnames {
                    ::ht::td {
                        ::ht::put $::ht::qrow($::ht::qname)
                    }
                }
            }
        }]

        /table

        set table [pop]

        if {[llength $::ht::qnames] == 0} {
            putln $opts(-default)
        } else {
            putln $table
        }
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
        putln <p>
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

    # title title ?over? ?under?
    #
    # title  The title text proper
    # over   Tiny text to appear over the title, or ""
    # under  Normal text to appear under the title, or ""
    #
    # Formats the title in the standard way.

    proc title {title {over ""} {under ""}} {
        if {$over eq "" && $under eq ""} {
            h1 $title
            return
        }

        putln ""

        if {$over ne ""} {
            tiny $over
            br
        }

        putln "<font size=7><b>$title</b></font>"

        if {$under ne ""} {
            br
            putln $under
        }

        para
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

    # tiny text
    #
    # text - A text string
    #
    # Sets the text in tiny font.

    proc tiny {text} {
        put "<font size=2>$text</font>"
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
    # Puts the text in tiny italics.

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

    # li-text text
    #
    # text    - A text string
    #
    # Puts the text as a list item.    

    proc li-text {text} {
        putln <li>$text</li>
    }

    # /ul
    #
    # Ends an unordered list
    
    proc /ul {} {
        putln </ul>
    }

    # pre ?text?
    #
    # text    - A text string
    #
    # Begins a <pre> block.  If the text is given, it is
    # escaped for HTML and the </pre> is added automatically.
   
    proc pre {{text ""}} {
        putln <pre>
        if {$text ne ""} {
            putln [string map {& &amp; < &lt; > &gt;} $text]
            /pre
        }
    }

    # /pre
    #
    # Ends a <pre> block
    
    proc /pre {} {
        putln </pre>
    }


    # para
    #
    # Adds a paragraph mark.
    
    proc para {} {
        put <p>
    }

    # br
    #
    # Adds a line break
    
    proc br {} {
        put <br>
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
    #   -default - String to put if list is empty; defaults to "None."
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

    # image name ?align?
    #
    # name  - A Tk image name
    # align - Alignment
    #
    # Adds an in-line <img>.

    proc image {name {align ""}} {
        put "<img src=\"/image/$name\" align=\"$align\">"
    }
}

