#-----------------------------------------------------------------------
# TITLE:
#    helptree.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Help Browser Page Tree
#
#    This is a scrolled tree control that displays help pages.
#    It is a subcomponent of helpbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::projectgui::helptree {
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -helpdb    The helpdb(n) to browse
    option -helpdb -readonly yes


    #-------------------------------------------------------------------
    # Components

    component hdb       ;# The helpdb(n) to browse.
    component tree      ;# The treectrl(n) widget

    #-------------------------------------------------------------------
    # Instance Variables

    # Info array
    # 
    #   item-$name      Tree item IDs by page name
    #   name-$item      Page names by tree item ID
    #   setCount        Incremented on entry to "$win set"; decremented 
    #                   on exit.  Prevents "$win set" from sending the
    #                   <<Selection>> event.
    variable info -array {
        setCount 0
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, save the options
        $self configurelist $args

        set hdb $options(-helpdb)

        # NEXT, create the tree
        install tree using treectrl $win.tree       \
            -width          2i                      \
            -borderwidth    0                       \
            -relief         flat                    \
            -usetheme       1                       \
            -showroot       0                       \
            -showheader     0                       \
            -selectmode     single                  \
            -itemwidthequal 1                       \
            -indent         14                      \
            -yscrollcommand [list $win.yscroll set]

        $tree column create
        $tree configure -treecolumn first
        $tree element create elemText text
        $tree element create elemRect rect -fill {gray {selected}}
        $tree style create style1
        $tree style elements style1 {elemRect elemText}
        $tree style layout style1 elemText -iexpand e
        $tree style layout style1 elemRect -union {elemText}
        $tree configure -default style1
        $tree item style set root tree style1

        # NEXT, create the scrollbar
        scrollbar $win.yscroll          \
            -orient  vertical           \
            -command [list $tree yview]

        # NEXT, grid them in
        grid $tree        -row 0 -column 0 -sticky nsew
        grid $win.yscroll -row 0 -column 1 -sticky ns

        grid columnconfigure $win 0 -weight 1
        grid rowconfigure    $win 0 -weight 1

        # NEXT, get selection events
        $tree notify bind $tree <Selection> \
            [mymethod Selection]
    }

    # Selection
    #
    # Sends a <<Selection>> event, when needed.
    
    method Selection {} {
        if {$info(setCount) == 0} {
            event generate $win <<Selection>>
        }
    }


    #-------------------------------------------------------------------
    # Public methods
    
    # refresh
    #
    # Reloads the list of pages from the hdb

    method refresh {} {
        # FIRST, clear all content from the tree
        $tree item delete 0 end
        array unset info

        # NEXT, Get the top-level names
        set names [$hdb children ""]

        # NEXT, loop over the names
        while {[llength $names] > 0} {
            set name [lshift names]

            # FIRST, Get the page's title, and its parent, or "root" if none
            $hdb eval {
                SELECT title,parent FROM helpdb_pages WHERE name=$name
            } {}

            if {$parent eq ""} {
                set pitem root
            } else {
                set pitem $info(item-$parent)
            }

            # NEXT, get the pages's children.
            set kids [$hdb children $name]

            if {[llength $kids] > 0} {
                lappend names {*}$kids
                set button yes
            } else {
                set button no
            }

            # NEXT, add the page
            set info(item-$name)   \
                [$tree item create     \
                     -parent $pitem    \
                     -button $button]

            if {$button} {
                $tree item collapse $info(item-$name)
            }

            $tree item element configure $info(item-$name) tree elemText \
                -text $title

            # NEXT, link the item to the page.
            set info(name-$info(item-$name)) $name
        }
    }


    # set
    #
    # Sets the displayed name; does not send <<Selection>>

    method set {name} {
        require {[info exists info(item-$name)]} \
            "unknown name: \"$name\""

        # FIRST, expand the item and its parents.
        set parent [$hdb parent $name]

        while {$parent ne ""} {
            $tree item expand $info(item-$parent)
            set parent [$hdb parent $parent]
        }

        # NEXT, make sure the item is visible
        $tree item expand $info(item-$name)

        $tree see $info(item-$name)

        # NEXT, select it.  The setCount prevents this from
        # triggering a <<Selection>> event.
        try {
            incr info(setCount)
            $tree selection clear 0 end
            $tree selection add $info(item-$name)
        } finally {
            incr info(setCount) -1
        }
        
        # TBD: Needed?
        update idletasks
    }

    
    # get
    #
    # Returns the displayed name

    method get {} {
        set item [lindex [$tree selection get] 0]

        if {$item ne ""} {
            return $info(name-$item)
        } else {
            return ""
        }
    }
}
