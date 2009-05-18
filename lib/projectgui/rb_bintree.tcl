#-----------------------------------------------------------------------
# TITLE:
#    rb_bintree.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Report Browser Bin Tree
#
#    This is a scrolled tree control that displays the reporter(n) bins.
#    It is a subcomponent of reportbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::projectgui::rb_bintree {
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    component tree      ;# The treectrl(n) widget

    #-------------------------------------------------------------------
    # Instance Variables

    # Info array
    # 
    #   item-$bin      Tree item IDs by bin ID
    #   bin-$item      Bin IDs by tree item ID
    variable info -array {}

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, save the options
        $self configurelist $args

        # NEXT, create the tree
        install tree using treectrl $win.tree       \
            -width          140                     \
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
            [list event generate $win <<Selection>>]
    }



    #-------------------------------------------------------------------
    # Public methods
    
    # refresh
    #
    # Reloads the list of bins from reporter(n).

    method refresh {} {
        # FIRST, clear all content from the tree
        $tree item delete 0 end
        array unset info

        # NEXT, Get the top-level bins
        set bins [reporter bin children ""]

        # NEXT, loop over the bins
        while {[llength $bins] > 0} {
            set bin [lshift bins]

            # FIRST, Get the bin's parent bin, or "root" if none
            set parent [reporter bin parent $bin]

            if {$parent eq ""} {
                set pitem root
            } else {
                set pitem $info(item-$parent)
            }

            # NEXT, get the bin's children, and add them to bins.
            set kids [reporter bin children $bin]

            if {[llength $kids] > 0} {
                lappend bins {*}$kids
                set button yes
            } else {
                set button no
            }

            # NEXT, add the bin
            set info(item-$bin)       \
                [$tree item create    \
                     -parent $pitem   \
                     -button $button]

            if {$button} {
                $tree item collapse $info(item-$bin)
            }

            $tree item element configure $info(item-$bin) tree elemText \
                -text [reporter bin title $bin]

            # NEXT, link the item to the bin.
            set info(bin-$info(item-$bin)) $bin
        }
    }


    # set
    #
    # Sets the displayed bin; does not send <<BinSelected>>

    method set {bin} {
        require {[info exists info(item-$bin)]} \
            "unknown bin: \"$bin\""

        # FIRST, make sure the item is visible
        set parent [reporter bin parent $bin]

        while {$parent ne ""} {
            $tree item expand $info(item-$parent)
            set parent [reporter bin parent $parent]
        }

        $tree see $info(item-$bin)

        # NEXT, select it
        $tree selection clear 0 end
        $tree selection add $info(item-$bin)
        
        # TBD: Needed?
        update idletasks
    }

    
    # get
    #
    # Returns the displayed bin

    method get {} {
        set item [lindex [$tree selection get] 0]

        if {$item ne ""} {
            return $info(bin-$item)
        } else {
            return ""
        }
    }
}



