#-----------------------------------------------------------------------
# TITLE:
#    winbrowser.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    winbrowser(n) is an experimental widget for browsing the window
#    tree.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Exported Commands

namespace eval ::marsgui:: {
    namespace export winbrowser
}

#-----------------------------------------------------------------------
# winbrowser

snit::widget ::marsgui::winbrowser {
    #-------------------------------------------------------------------
    # Typeconstructor

    typeconstructor {
        namespace import ::marsutil::* ::marsutil::* ::marsgui::*
    }

    #-------------------------------------------------------------------
    # Components

    component tree       ;# The tree of window data
    component tnb        ;# Tabbed notebook for window data

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Instance Variables

    variable pages    ;# Array of text pages for data display

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the widgets
        ::marsgui::paner $win.paner \
            -orient     horizontal \
            -showhandle 1

        ScrolledWindow $win.paner.treesw  \
            -borderwidth 0                \
            -auto        horizontal
        $win.paner add $win.paner.treesw -sticky nsew -minsize 60

        install tree using Tree $win.paner.treesw.tree \
            -background     white                      \
            -width          40                         \
            -borderwidth    0                          \
            -deltay         16                         \
            -takefocus      1                          \
            -selectcommand  [mymethod SelectWindow]

        $win.paner.treesw setwidget $tree

        install tnb using ttk::notebook $win.paner.tnb \
            -padding   2 \
            -takefocus 1
        $win.paner add $tnb -sticky nsew -minsize 60

        $self AddPage winfo
        $self AddPage options
        $self AddPage bindings

        grid rowconfigure    $win 0 -weight 1
        grid columnconfigure $win 0 -weight 1

        grid $win.paner -row 0 -column 0 -sticky nsew

        # NEXT, get the options
        $self configurelist $args

        # NEXT, populate the list
        $self Populate

        # NEXT, activate the first item.
        $tree selection set .
    }

    # AddPage name label
    #
    # name      The page name
    #
    # Adds a page to the tabbed notebook

    method AddPage {name} {
        set sw $tnb.${name}sw

        ScrolledWindow $sw \
            -borderwidth 0          \
            -auto        horizontal

        $tnb add $sw \
            -sticky  nsew     \
            -padding 2        \
            -text    $name

        set pages($name) [rotext $sw.text \
                              -width              50       \
                              -height             15       \
                              -font               codefont \
                              -highlightthickness 1]

        $sw setwidget $pages($name)
    }


    #-------------------------------------------------------------------
    # Methods

    # refresh
    #
    # Refreshes the content of the display

    method refresh {} {
        # FIRST, get the current item
        set node [lindex [$tree selection get] 0]

        # NEXT, repopulate
        $tree delete [$tree nodes root]
        $self Populate

        # NEXT, see the current item or "."
        if {$node eq ""} {
            set node .
        }

        $tree selection set $node
        $tree see $node
    }

    # Populate
    #
    # Populate the listbox with the windows

    method Populate {} {
        $tree insert end root . \
            -text .             \
            -fill black         \
            -font codefont      \
            -padx 0

        foreach w [winfo children .] {
            if {[string match "*#*" $w]} {
                continue
            }

            $self AddWin root $w
        }
    }

    # AddWin pnode w
    #
    # pnode   Parent node
    # w       A window
    #
    # Adds a window and its children

    method AddWin {pnode w} {
        $tree insert end $pnode $w \
            -text $w             \
            -fill black          \
            -font codefont       \
            -padx 0

        set kids [winfo children $w]

        foreach c [winfo children $w] {
            if {[string match "*#*" $c]} {
                continue
            }
            $self AddWin $w $c
        }
    }

    # SelectWindow w nodes
    #
    # w        The Tree widget
    # nodes    The selected items; should only be one.
    #
    # Puts the winfo into the rotext.

    method SelectWindow {w nodes} {
        if {[llength $nodes] == 0} {
            return
        }

        set node [lindex $nodes 0]

        $self GetWinfo    $node
        $self GetOptions  $node
        $self GetBindings $node
    }

    # GetWinfo w
    #
    # w    A window
    #
    # Gets the winfo for the window, and displays it on the winfo
    # page.

    method GetWinfo {w} {
        set fmt "%-10s %s\n"
        set result ""

        append result [format $fmt "widget:" $w]

        if {[catch {set wtype [$w info type]}]} {
            set wtype "n/a"
        }

        append result [format $fmt "snit type:" $wtype]

        foreach attr {
            class
            toplevel
            geometry
            width
            height
            reqwidth
            reqheight
            ismapped
            depth
            manager
            rootx
            rooty
            x
            y
        } {
            append result [format $fmt "$attr:" [winfo $attr $w]]
        }

        $self Display winfo $result
    }

    # GetOptions w
    #
    # w    A window
    #
    # Gets the option data for the window, and displays it on
    # the options page.

    method GetOptions {w} {
        set fmt "%24s: %s\n"
        set result ""

        if {[catch {set records [$w configure]}]} {
            set records [list]
        }

        foreach record $records {
            set opt [lindex $record 0]

            append result [format $fmt "$opt" [$w cget $opt]]
        }

        $self Display options $result
    }

    # GetBindings w
    #
    # w    A window
    #
    # Gets the bindings for the window, and displays them in the
    # bindings window.

    method GetBindings {w} {
        set out ""

        append out "Bind Tags:\n"

        foreach tag [bindtags $w] {
            append out "    Tag: $tag\n"
        }

        append out "\n"

        foreach tag [bindtags $w] {
            append out "Tag: $tag\n\n"

            foreach event [bind $tag] {
                set binding [reindent [bind $tag $event] "    "]
                append out "  Event: $event\n"
                append out "$binding\n\n"
            }
        }

        $self Display bindings $out
    }

    # reindent text ?indent?
    #
    # text      A block of text
    # indent    A new indent for each line; defaults to ""
    #
    # Removes leading and trailing blank lines, and any
    # whitespace margin at the beginning of each line, and
    # then indents each line according to "indent".

    proc reindent {text {indent ""}} {
        set text [outdent $text]
        
        set lines [split $text "\n"]

        set out [join [split $text "\n"] "\n$indent"]

        return "${indent}$out"
    }

    # Display text
    #
    # page 
    # text       A text string
    #
    # Displays the text string in the rotext widget

    method Display {page text} {
        $pages($page) del 1.0 end
        $pages($page) ins 1.0 $text
        $pages($page) see 1.0
    }
}







