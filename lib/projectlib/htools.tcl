#-----------------------------------------------------------------------
# TITLE:
#    htools.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectlib(n): HTML generation tools
#
#    The htools type provides a number of HTML-related utility commands.
#    In addition, instances of the htools type are buffers for the 
#    generation of HTML.
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export htools
}

#-----------------------------------------------------------------------
# htools type

snit::type ::projectlib::htools {
    #-------------------------------------------------------------------
    # Type Variables

    # Transient values used by query
    typevariable qopts       ;# Query options
    typevariable qnames      ;# List of column names
    typevariable qrow        ;# Row of queried data.


    #-------------------------------------------------------------------
    # Type Methods

    # escape text
    #
    # text - Plain text to be included in an HTML page
    #
    # Escapes the &, <, and > characters so that the included text
    # doesn't screw up the formatting.

    typemethod escape {text} {
        return [string map {& &amp; < &lt; > &gt;} $text]
    }

    #-------------------------------------------------------------------
    # Options

    # -headercmd
    #
    # A command that returns content for the page header.

    option -headercmd

    # -footercmd
    #
    # A command that returns content for the page footer.

    option -footercmd

    # -rdb
    #
    # An SQLite database handle; used by "query".

    option -rdb

    #-------------------------------------------------------------------
    # Instance Variables

    # Stack pointer
    variable sp 0

    # stack: buffer stack
    #
    # $num - Buffer 
    
    variable stack -array {
        0  {}
    }


    #-------------------------------------------------------------------
    # Constructor 

    constructor {args} {
        $self configurelist $args
    }


    #-------------------------------------------------------------------
    # Commands for building up HTML in the buffer

    # put text...
    #
    # text - One or more text strings
    #
    # Adds the text strings to the buffer, separated by spaces.

    method put {args} {
        append stack($sp) [join $args " "]

        return
    }

    # putln text...
    #
    # text - One or more text strings
    #
    # Adds the text strings to the buffer, separated by spaces,
    # and *preceded* by a newline.

    method putln {args} {
        append stack($sp) \n [join $args " "]

        return
    }

    # get
    #
    # Get the text in the main buffer.

    method get {} {
        return $stack($sp)
    }

    # clear
    #
    # Clears the buffer for new stuff.

    method clear {} {
        array unset stack
        set sp 0
        set stack($sp) ""
    }

    # push
    #
    # Pushes a new buffer on the stack.

    method push {} {
        incr sp
        set stack($sp) ""
    }

    # pop
    #
    # Pops a buffer off of the stack, and returns its contents.
    # If "else" is given, the buffer is automatically put into
    # the level below, unless it's empty; if it's empty, the
    # body is executed.

    method pop {} {
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

    method putif {expr then {else ""}} {
        if {[uplevel 1 [list expr $expr]]} {
            $self put $then
        } else {
            $self put $else
        }
    }

    # query sql ?options...?
    #
    # sql           An SQL query.
    # options       Formatting options
    #
    # -align  codes   - List of column alignments, left, right, center
    # -labels list    - List of column labels
    # -default text   - Text to return if there's no data found.
    #                   Defaults to "No data found.<p>"
    # -escape flag    - If yes, all data returned by the RDB is escaped.
    #                   Defaults to no.
    #
    # Executes the query and accumulates the results as HTML.

    method query {sql args} {
        require {$options(-rdb) ne ""} "No -rdb has been specified."

        # FIRST, get options.
        array set qopts {
            -labels   {}
            -default  "No data found.<p>"
            -align    {}
            -escape   no
        }
        array set qopts $args

        # FIRST, begin the table
        $self push

        # NEXT, if we have labels, use them.
        if {[llength $qopts(-labels)] > 0} {
            $self table $qopts(-labels)
        }

        # NEXT, get the data.  Execute the query as an uplevel,
        # so that we can use variables.
        set qnames {}

        uplevel 1 [list $options(-rdb) eval $sql ::projectlib::htools::qrow \
                       [list $self QueryRow]]

        $self /table

        set table [$self pop]

        if {[llength $qnames] == 0} {
            $self putln $qopts(-default)
        } else {
            $self putln $table
        }
    }

    # QueryRow 
    #
    # Builds up the table results

    method QueryRow {} {
        if {[llength $qnames] == 0} {
            set qnames $qrow(*)
            unset qrow(*)

            if {$qopts(-escape)} {
                set qnames [$type escape $qnames]
            }

            if {[$self get] eq ""} {
                $self table $qnames
            }
        }

        $self tr {
            foreach name $qnames align $qopts(-align) {
                if {$qopts(-escape)} {
                    set qrow($name) [$type escape $qrow($name)]
                }

                $self td $align {
                    $self put $qrow($name)
                }
            }
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

    method page {title {body ""}} {
        $self clear

        $self put <html><head>
        $self putln <title>$title</title>
        $self putln </head>

        callwith $options(-headercmd) $title

        if {$body ne ""} {
            uplevel 1 $body
            $self /page
        }
    }

    # /page
    #
    # Adds the standard footer boilerplate

    method /page {} {
        callwith $options(-footercmd)

        $self putln "</body></html>"
    }

    # title title ?over? ?under?
    #
    # title  The title text proper
    # over   Tiny text to appear over the title, or ""
    # under  Normal text to appear under the title, or ""
    #
    # Formats the title in the standard way.

    method title {title {over ""} {under ""}} {
        if {$over eq "" && $under eq ""} {
            $self h1 $title
            return
        }

        $self putln ""

        if {$over ne ""} {
            $self tiny $over
            $self br
        }

        $self putln "<font size=7><b>$title</b></font>"

        if {$under ne ""} {
            $self br
            $self putln $under
        }

        $self para
    }


    # h1 title ?anchor?
    #
    # title  - A title string
    # anchor - An anchor for internal hyperlinks
    #
    # Returns an HTML H1 title.

    method h1 {title {anchor ""}} {
        $self HTitle 1 $title $anchor
    }

    # h2 title ?anchor?
    #
    # title  - A title string
    # anchor - An anchor for internal hyperlinks
    #
    # Returns an HTML H2 title.

    method h2 {title {anchor ""}} {
        $self HTitle 2 $title $anchor
    }

    # h3 title ?anchor?
    #
    # title  - A title string
    # anchor - An anchor for internal hyperlinks
    #
    # Returns an HTML H3 title.

    method h3 {title {anchor ""}} {
        $self HTitle 3 $title $anchor
    }

    # HTitle num title anchor
    #
    # num    - The header level
    # title  - The title text
    # anchor - Anchor, for internal hyperlinks

    method HTitle {num title anchor} {
        if {$anchor eq ""} {
            $self putln <h$num>$title</h$num>
        } else {
            $self putln "<h$num><a name=\"$anchor\">$title</a></h$num>"
        }
    }

    # linkbar linkdict
    # 
    # linkdict   - A dictionary of URLs and labels
    #
    # Displays the links in a horizontal bar.

    method linkbar {linkdict} {
        $self putln <hr>
        set count 0

        foreach {link label} $linkdict {
            if {$count > 0} {
               $self put " | "
            }

            $self link $link $label

            incr count
        }

        $self putln <hr>
        $self para
    }

    # tiny text
    #
    # text - A text string
    #
    # Sets the text in tiny font.

    method tiny {text} {
        $self put "<font size=2>$text</font>"
    }

    # tinyb text
    #
    # text - A text string
    #
    # Sets the text in tiny bold.

    method tinyb {text} {
        $self put "<font size=2><b>$text</b></font>"
    }

    # tinyi text
    #
    # text - A text string
    #
    # Puts the text in tiny italics.

    method tinyi {text} {
        $self put "<font size=2><i>$text</i></font>"
    }

    # ul ?body?
    #
    # body    - A body script
    #
    # Begins an unordered list. If the body is given, it is executed and 
    # the </ul> is added automatically.
   
    method ul {{body ""}} {
        $self putln <ul>

        if {$body ne ""} {
            uplevel 1 $body
            $self /ul
        }
    }

    # li
    #
    # body    - A body script
    #
    # Begins a list item.  If the body is given, it is executed and 
    # the </li> is added automatically.
    
    method li {{body ""}} {
        $self putln <li>

        if {$body ne ""} {
            uplevel 1 $body
            $self put </li>
        }
    }

    # li-text text
    #
    # text    - A text string
    #
    # Puts the text as a list item.    

    method li-text {text} {
        $self putln <li>$text</li>
    }

    # /ul
    #
    # Ends an unordered list
    
    method /ul {} {
        $self putln </ul>
    }

    # pre ?text?
    #
    # text    - A text string
    #
    # Begins a <pre> block.  If the text is given, it is
    # escaped for HTML and the </pre> is added automatically.
   
    method pre {{text ""}} {
        $self putln <pre>
        if {$text ne ""} {
            $self putln [string map {& &amp; < &lt; > &gt;} $text]
            $self /pre
        }
    }

    # /pre
    #
    # Ends a <pre> block
    
    method /pre {} {
        $self putln </pre>
    }


    # para
    #
    # Adds a paragraph mark.
    
    method para {} {
        $self put <p>
    }

    # br
    #
    # Adds a line break
    
    method br {} {
        $self put <br>
    }

    # link url label
    #
    # url    - A resource URL
    # label  - A text label
    #
    # Formats and returns an HTML link.

    method link {url label} {
        $self put "<a href=\"$url\">$label</a>"
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

    method linklist {args} {
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
            $self put $result
        } else {
            $self put $opts(-default)
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

    method table {headers {body ""}} {
        $self putln "<table border=1 cellpadding=2 cellspacing=0>"
        $self putln "<tr align=left>"

        foreach header $headers {
            $self put "<th align=left>$header</th>"
        }
        $self put </tr>

        if {$body ne ""} {
            uplevel 1 $body
            $self /table
        }
    }

    # tr ?body?
    #
    # body    - A body script
    #
    # Begins a standard table row.  If the body is included,
    # it is executed, and the </tr> is included automatically.
    
    method tr {{body ""}} {
        $self putln "<tr valign=top>"

        if {$body ne ""} {
            if {$body ne ""} {
                uplevel 1 $body
                $self /tr
            }
        }
    }

    # td ?align? ?body?
    #
    # align   - left | center | right; defaults to "left".
    # body    - A body script
    #
    # Formats a standard table item; if the body is included,
    # it is executed, and the </td> is included automatically.
    
    method td {{align left} {body ""}} {
        $self putln "<td align=\"$align\">"
        if {$body ne ""} {
            uplevel 1 $body
            $self put </td>
        }
    }

    # /td
    #
    # ends a standard table item
    
    method /td {} {
        $self put </td>
    }

    # /tr
    #
    # ends a standard table row
    
    method /tr {} {
        $self put </tr>
    }

    # /table
    #
    # Ends a standard table with the specified column headers

    method /table {} {
        $self put </table>
    }

    # image name ?align?
    #
    # name  - A Tk image name
    # align - Alignment
    #
    # Adds an in-line <img>.

    method image {name {align ""}} {
        $self put "<img src=\"/image/$name\" align=\"$align\">"
    }
}


