#-----------------------------------------------------------------------
# TITLE:
#    cmdbrowser.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    cmdbrowser(n) is an experimental widget for browsing Tcl commands
#    and Snit objects.
#
# FUTURE:
#    * Should preserve location on Populate, if possible
#    * Might want to use a tktreeview instead of Tree, so that we can 
#      have multiple columns.
#    * It would be nice to be able to edit code on the fly.
#    * Would like better support for Snit types and instances.
#    * Would like searching.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Exported Commands

namespace eval ::marsgui:: {
    namespace export cmdbrowser
}

#-----------------------------------------------------------------------
# cmdbrowser

snit::widget ::marsgui::cmdbrowser {
    #-------------------------------------------------------------------
    # Typeconstructor

    typeconstructor {
        namespace import ::marsutil::* ::marsgui::*
    }

    #-------------------------------------------------------------------
    # Type Variables

    typevariable cmdcolors -array {
        proc    \#000000
        nse     \#0066FF
        sub     \#00CCFF
        alias   \#00CCFF
        bin     \#FF0000
        wproc   \#CC00FF
        wnse    \#CC00FF
        walias  \#CC00FF
        wbin    \#CC00FF
        bwid    \#6600FF
        ns      \#009900
    }



    #-------------------------------------------------------------------
    # Components

    component bar        ;# The toolbar
    component tree       ;# The tree of window data
    component tnb        ;# Tabbed notebook for window data

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Instance Variables

    variable pages    ;# Array of text pages for data display

    # Array of data; the indices are as follows:
    #
    # counter     Counter for node IDs
    # imports     1 if imported commands should be shown, and 0 otherwise.

    variable info -array {
        counter 0
        imports 0
        wid     0
        alias   1
        bin     1
        bwid    0
    }

    # Array of data for each browsed command, indexed by tree node ID.
    variable cmds

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the widgets
        ::marsgui::paner $win.paner \
            -orient     horizontal \
            -showhandle 1

        # Toolbar
        install bar using ttk::frame $win.bar

        ttk::checkbutton $bar.imports       \
            -style    Toolbutton            \
            -text     "Imports"             \
            -variable [myvar info(imports)] \
            -command  [mymethod Populate]

        ttk::checkbutton $bar.wid           \
            -style    Toolbutton            \
            -text     "Widgets"             \
            -variable [myvar info(wid)]     \
            -command  [mymethod Populate]

        ttk::checkbutton $bar.alias         \
            -style    Toolbutton            \
            -text     "Aliases"             \
            -variable [myvar info(alias)]   \
            -command  [mymethod Populate]

        ttk::checkbutton $bar.bin           \
            -style    Toolbutton            \
            -text     "BinCmds"             \
            -variable [myvar info(bin)]     \
            -command  [mymethod Populate]

        ttk::checkbutton $bar.bwid          \
            -style    Toolbutton            \
            -text     "BWid\#"              \
            -variable [myvar info(bwid)]    \
            -command  [mymethod Populate]


        pack $win.bar.imports -side left -padx 1 -pady 1
        pack $win.bar.wid     -side left -padx 1 -pady 1
        pack $win.bar.alias   -side left -padx 1 -pady 1
        pack $win.bar.bin     -side left -padx 1 -pady 1
        pack $win.bar.bwid    -side left -padx 1 -pady 1


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
            -selectcommand  [mymethod SelectNode]      \
            -opencmd        [mymethod OpenNode]

        $win.paner.treesw setwidget $tree

        install tnb using ttk::notebook $win.paner.tnb \
            -padding   2 \
            -takefocus 1
        $win.paner add $tnb -sticky nsew -minsize 60

        $self AddPage code

        grid rowconfigure    $win 1 -weight 1
        grid columnconfigure $win 0 -weight 1

        grid $win.bar   -row 0 -column 0 -sticky ew
        grid $win.paner -row 1 -column 0 -sticky nsew

        # NEXT, get the options
        $self configurelist $args

        # NEXT, populate the tree
        $self Populate

        # NEXT, activate the first item.
        $tree selection set cmd1
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
        set name [dict get $cmds($node) name]

        # NEXT, repopulate
        $self Populate

        # NEXT, see the current item or "cmd1"
        if {$node eq ""                           || 
            ![$tree exists $node]                 ||
            [dict get $cmds($node) name] ne $name
        } {
            set node cmd1
        }

        $tree selection set $node
        $tree see $node
    }

    # Populate
    #
    # Populate the listbox with the windows

    method Populate {} {
        array unset cmds
        set info(counter) 0

        $self GetNsNodes root ::
    }

    # GetNsNodes parent ns
    #
    # parent  A parent node
    # ns      A fully-qualified namespace
    #
    # Gets the tree nodes for the children of ns, and adds them
    # under parent.

    method GetNsNodes {parent ns} {
        $tree delete [$tree nodes $parent]
        
        foreach {name ctype} [cmdinfo list $ns] {
            # Filter out unwanted commands:
            # TBD: Add this to cmdinfo?
            if {$ctype ne "ns"} {
                if {(!$info(imports) && $name ne [namespace origin $name]) ||
                    (!$info(wid)   && $ctype in {wbin walias wproc wnse})  ||
                    (!$info(bwid)  && $ctype eq "bwid")                    ||
                    (!$info(alias) && $ctype in {alias walias})            ||
                    (!$info(bin)   && $ctype in {bin wbin})
                } {
                    continue
                }
            }

            # Display the command in the tree
            set id cmd[incr info(counter)]

            set cmd [dict create id $id name $name ctype $ctype]

            $tree insert end $parent $id  \
                -text "$name    ($ctype)" \
                -fill $cmdcolors($ctype)  \
                -font codefont            \
                -padx 0

            if {$ctype in {"ns" "nse"}} {
                # We'll get the child nodes on request.  
                # Mark it unexpanded, and create a dummy child so that
                # we get the open icon.
                dict set cmd expanded 0

                $tree insert end $id $id-dummy
            }

            set cmds($id) $cmd

        }
    }

    # GetNseNodes parent nse
    #
    # parent  A parent node
    # nse     A fully-qualified namespace ensemble
    #
    # Gets the tree nodes for the subcommands of nse, and adds them
    # under parent.

    method GetNseNodes {parent nse} {
        $tree delete [$tree nodes $parent]
        
        foreach {sub mapping} [cmdinfo submap $nse] {
            set id cmd[incr info(counter)]

            set cmd [dict create           \
                         id     $id        \
                         name   $sub       \
                         ctype  sub        \
                         mapping $mapping]

            $tree insert end $parent $id  \
                -text "$sub    (sub)"     \
                -fill $cmdcolors(sub)     \
                -font codefont            \
                -padx 0

            set cmds($id) $cmd
        }
    }


    # OpenNode node
    #
    # node    The node to open.  
    # 
    # If the node hasn't been expanded, expand it.
    
    method OpenNode {node} {
        if {[dict get $cmds($node) expanded]} {
            return
        }

        dict with cmds($node) {
            set expanded 1

            if {$ctype eq "ns"} {
                $self GetNsNodes $id $name
            } elseif {$ctype eq "nse"} {
                $self GetNseNodes $id $name
            }
        }
    }

    # SelectNode w nodes
    #
    # w        The Tree widget
    # nodes    The selected items; should only be one.
    #
    # Puts the proc info into the rotext.

    method SelectNode {w nodes} {
        # FIRST, get the node
        if {[llength $nodes] == 0} {
            return
        }

        # NEXT, display it.
        $self DisplayNode [lindex $nodes 0]
    }

    # DisplayNode node
    #
    # node    A node in the tree
    #
    # Gets the info for the node, and displays it on the code
    # page.

    method DisplayNode {node} {
        set cmd $cmds($node)
        set name [dict get $cmd name]

        switch -exact -- [dict get $cmd ctype] {
            proc {
                set text [getcode $name]
            }

            nse  -
            wnse {
                set opts [namespace ensemble configure $name]

                set text "namespace ensemble: $name\n\n"
                foreach {opt val} $opts {
                    append text [format "%-12s %s\n" $opt $val]
                }
            }

            sub {
                set text "maps to -> [dict get $cmds($node) mapping]"
            }

            alias  -
            walias {
                set text "alias -> [interp alias {} [dict get $cmd name]]"
            }

            bin  {
                set text "Binary command"
            }

            wbin {
                set text "Tk Widget"
            }

            bwid {
                set text "BWidget special widget"
            }

            ns {
                set text "namespace"
            }
        }

        $self Display code $text
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






