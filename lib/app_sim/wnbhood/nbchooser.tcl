#-----------------------------------------------------------------------
# TITLE:
#    nbchooser.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    nbchooser(n): A widget for selecting neighborhoods
# from a hierarchical tree.
#
# This widget has two main areas: a tablelist(n) for displaying the 
# hierarchy of neighborhoods and a mapcanvas(n) for displaying the
# neighborhood boundaries.  As the user clicks to choose which 
# polygons should be included as part of a scenario the polygon display
# changes accordingly indicating the currently selected set of polygons
# and greying out the set of deselected polygons.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Exported Commands

namespace eval ::wnbhood:: {
    namespace export nbchooser
}

#-----------------------------------------------------------------------
# nbchooser widget

snit::widget ::wnbhood::nbchooser {
    #-------------------------------------------------------------------
    # Components

    component paner   ;# Paned window containing mapcanvas and tablelist
    component nblist  ;# tablelist of neighborhoods
    component map     ;# mapcanvas(n) to display neighborhood polygons
    component geo     ;# geoset(n) that contains the polygons
    component colors  ;# gradient(n) of colors to use for polygons
    component popup   ;# popup menu for selecting/deselecting all children

    #-------------------------------------------------------------------
    # Options

    # -treespec dict
    #
    # Nested dictionary containing heirarchical set of nbhoods

    option -treespec \
        -readonly yes

    # -projection proj
    #
    # The map projection to use when displaying nbhood polygons

    option -projection

    # -map map
    #
    # A map image to display behind any neighborhoods

    option -map

    #-------------------------------------------------------------------
    # Variables
    
    # info array
    #
    # active    - the current selection in nblist
    # locvar    - variable that contains map locations to display
    #
    # neighborhood relationships
    #
    # key-$n      - the tablelist key for neighborhood n
    # nb-$key     - the neighborhood name for the tablelist key
    # pkey-$n     - the tablelist parent key for neighborhood n
    # children-$n - list of the children of neighborhood n and of "root"
    # depth-$key  - depth in the hierarchy of neighborhood with tablelist key
    #
    # neighborhood display
    #
    # refpt-$n    - computed reference point for neighborhood n
    # color-$n    - the display color of neighborhood n
    # selected-$n - flag indicating whether n is selected for output
    # btnidx-$key - the index of the checkbutton in nblist expressed as
    #               "$row,$col" for the tablelist key

    variable info -array {
        active  0
    }
    
    # Transient array to keep track of a right clicked parent nbhood
    variable trans -array {
        active_parent ""
    }

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options
        $self configurelist $args

        assert {$options(-projection) ne ""}

        # NEXT, configure colors for polygons
        set colors [::marsutil::gradient %AUTO% \
            -mincolor #29663D -minlevel 0 \
            -midcolor #5CE68A -midlevel 3 \
            -maxcolor #85FFAD -maxlevel 7]

        # NEXT, create geoset(n) to hold polygons
        set geo [::marsutil::geoset %AUTO%]

        # NEXT, create content
        ttk::panedwindow $win.paner -orient horizontal
        ttk::frame $win.paner.f
        ttk::frame $win.paner.m

        $self MakeNbhoodList $win.paner.f
        $self MakeMapCanvas  $win.paner.m

        ttk::label $win.loc -textvariable [myvar info(locvar)] \
            -justify right -anchor e -width 60

        # NEXT, configure and layout content in the window
        grid columnconfigure $win.paner.f 0 -weight 1
        grid rowconfigure    $win.paner.f 0 -weight 1

        $win.paner add $win.paner.f
        $win.paner add $win.paner.m

        grid columnconfigure $win 0 -weight 1
        grid rowconfigure    $win 1 -weight 1

        grid $win.loc   -row 0 -column 1 -sticky w
        grid $win.paner -row 1 -column 0 -columnspan 2 -sticky nsew

        # NEXT, mouse behavior
        bind [$nblist bodytag] <Button-1> [mymethod ActivateNbhood %W %x %y]
        bind [$nblist bodytag] <Button-3> [mymethod ParentPopup %W %x %y %X %Y]
        bind $map <<Nbhood-1>> [mymethod NbhoodClicked %d]
        bind $map <<Nbhood-3>> [mymethod ToggleNbhood %d]

        # NEXT, create the popup menu for selecting/deselecting children
        # of a neighborhood
        set popup [menu .p]
        $popup add command \
            -label "Select All Children" \
            -command [mymethod ChildrenState 1]

        $popup add command \
            -label "Deselect All Children" \
            -command [mymethod ChildrenState 0]
    }

    destructor {
        destroy .p
    }

    # MakeMapCanvas w
    #
    # w  - a pathname to the window that contains the mapcanvas(n)
    #
    # This method creates a mapcanvas(n) with vertical and horizontal
    # scroll bars.

    method MakeMapCanvas {w} {
        install map using mapcanvas $w.map        \
            -locvariable    [myvar info(locvar)]  \
            -background     white                 \
            -yscrollcommand [list $w.yscroll set] \
            -xscrollcommand [list $w.xscroll set] 

        # Configure projection and, optionally, map image
        $map configure -projection $options(-projection)

        if {$options(-map) ne ""} {
            $map configure -map $options(-map)
        }
        
        ttk::scrollbar $w.yscroll \
            -orient  vertical     \
            -command [list $w.map yview]

        ttk::scrollbar $w.xscroll \
            -orient  horizontal   \
            -command [list $w.map xview]

        grid columnconfigure $w 0 -weight 1 
        grid rowconfigure    $w 0 -weight 1

        grid $w.map     -row 0 -column 0 -sticky nsew
        grid $w.yscroll -row 0 -column 1 -sticky ns   -pady {1 0}
        grid $w.xscroll -row 1 -column 0 -sticky ew   -padx {1 0}

        $map refresh
    }

    # MakeNbhoodList w
    #
    # w   - a window containing the tablelist 
    #
    # This method creates and embeds the tablelist in the supplied
    # window.

    method MakeNbhoodList {w} {
        install nblist using tablelist::tablelist $w.browser   \
            -columns          {20 Nbhoods left 10 Use? center} \
            -width            35                               \
            -background       white                            \
            -foreground       black                            \
            -selectmode       browse                           \
            -selecttype       row                              \
            -selectbackground white                            \
            -selectforeground black                            \
            -yscrollcommand   [list $w.yscroll set]            \
            -treecolumn       0

        ttk::scrollbar $w.yscroll \
            -orient  vertical     \
            -command [list $w.browser yview]

        $w.browser columnconfigure 0             -stretchable yes
        $w.browser columnconfigure 1 -editable 0 -stretchable no

        grid $w.browser -row 0 -column 0 -sticky nsew
        grid $w.yscroll -row 0 -column 1 -sticky ns   -pady {1 0}

    }

    # InsertToggle w row col btn
    #
    # w    - The tablelist widget
    # row  - a row in the tablelist
    # col  - a column in the tablelist
    # btn  - a path for a new checkbutton widget
    #
    # This method adds a checkbutton widget to the tablelist at
    # the row,col position provided.  The info array is updated
    # so that we have the button index by key for manipulation of
    # that cell in the tablelist widget.

    method InsertToggle {w row col btn} {
        # FIRST get the key
        set key [$w getfullkeys $row]

        set exists $info(exists-$info(nb-$key))

        # NEXT, create the checkbutton linked to a variable
        # in the info array and store it's index
        checkbutton $btn                            \
            -variable   [myvar info(selected-$key)] \
            -background white                       \
            -command    [mymethod UpdateMap]        

        # NEXT, if the neighborhood already exists in the scenario
        # then show it disabled
        if {$exists} {
            $btn configure -state disabled -background #CCCCCC
        }

        # NEXT, references to the cell that contains the button
        set info(btnidx-$key) "$row,$col"
    }

    #--------------------------------------------------------------------
    # Event Handlers
    #

    # ParentPopup w x y X Y
    #
    # w   - the tablelist widget
    # x   - the window x coord
    # y   - the window y coord
    # X   - the absolute X coord
    # Y   - the absolute Y coord
    #
    # This handler pops up a menu that allows the user to activate or
    # deactivate all the children neighborhoods of a parent

    method ParentPopup {w x y X Y} {
        # FIRST, translate mouse location to tablelist entry
        foreach {tbl x y} [tablelist::convEventFields $w $x $y] {}
        set key [$tbl getfullkeys [$tbl containing $y]]

        # NEXT, make sure that the location is on a neighborhood and that
        # the neighborhood has children
        if {[info exists info(nb-$key)]} {
            if {[llength $info(children-$info(nb-$key))]} {
                set trans(active_parent) $info(nb-$key)
                # Popup on absolute coords
                tk_popup $popup $X $Y
            }
        } 
    }

    # ChildrenState  state
    #
    # state   - display state of the child neighborhoods of a parent
    #
    # This method selects/deselects all the child neighborhoods of a parent
    # for inclusion or exclusion in a scenario.

    method ChildrenState {state} {
        # FIRST, go through all the children of the parent setting their
        # selected state
        foreach n $info(children-$trans(active_parent)) {
            set info(selected-$info(key-$n)) $state
        }

        # NEXT, using the parents key, collapse or expand the tree
        set key $info(key-$trans(active_parent))
        
        if {$state} {
            $nblist expand $key -partly

            # NEXT, if all children are selected, deselect parent, but
            # only if it doesn't already exist
            if {!$info(exists-$info(nb-$key))} {
                let info(selected-$key) 0
            }
        } else {
            $nblist collapse $key -partly
        }

        # NEXT, redraw the map
        $self UpdateMap
    }

    # ActivateNbhood  w x y
    #
    # w   - a window
    # x,y - mouse click location
    #
    # This method converts the event arguments to a key in the tablelist's
    # list of neighborhoods. A flag is set for that neighborhood to indicate
    # that it is the active one and the map updated.

    method ActivateNbhood {w x y} {
        foreach {tbl x y} [tablelist::convEventFields $w $x $y] {}
    
        set key [$tbl getfullkeys [$tbl containing $y]]
        if {$key ne ""} {
            set info(active) $info(id-$key)
        } 
    
        $self UpdateMap
    }

    # NbhoodClicked id 
    #
    # id    - The mapcanvas(n) ID of a neighborhood polygon
    #
    # This callback happens when the user clicks in a neighborhood polygon
    # so the row containing that neighborhood in the tablelist can be 
    # activated and seen.

    method NbhoodClicked {id} {
        $nblist activate $info(key-$id)
        $nblist see $info(key-$id)
        set info(active) $id
        $self UpdateMap
    }

    # ToggleNbhood id
    #
    # id   - The mapcanvas(n) ID of a neighborhood polygon
    #
    # This callback toggles the selected state of a neighborhood
    # and redraws the map.

    method ToggleNbhood {id} {
        set key $info(key-$id)

        # FIRST, if the neighborhood already exists in the scenario
        # then its a no-op
        if {$info(exists-$info(nb-$key))} {
            return
        }

        # NEXT, toggle the selection and update
        set info(selected-$key) [expr {!$info(selected-$key)}]

        $self UpdateMap
    }

    #----------------------------------------------------------------
    # Private methods

    # CreateTree
    #
    # This method creates the tablelist hierarchy based on the supplied
    # tree specification and sets the color of each neighborhood.  Finally
    # the map is drawn.  For now, only three levels of hierarchy are
    # handled.

    method CreateTree {} {
        # FIRST, get the treespec from the options
        set tree $options(-treespec)

        # NEXT, the assumption, for now, is that there is a maximum of
        # three levels of political boundary: TopN -> MidN -> BotN.
        # Of course, this will not do in the long run, a more flexible way
        # of defining and extracting polygon heirarchy must be determined.
        set info(children-root) [list]
        foreach {topn plist} $tree {
            set nkey [$nblist insertchild root end $topn]
            set info(key-$topn)         $nkey
            set info(pkey-$topn)        root
            set info(nb-$nkey)          $topn
            lappend info(children-root) $topn
            set info(children-$topn) [list]
            set info(selected-$nkey) 1
            # Collapse all top level entries

            $nblist collapse $nkey -fully
            foreach {midn dlist} $plist {
                set pkey [$nblist insertchild $nkey end $midn]
                set info(key-$midn)          $pkey
                set info(pkey-$midn)         $nkey
                set info(nb-$pkey)           $midn
                lappend info(children-$topn) $midn
                set info(children-$midn) [list]
                set info(selected-$pkey) 0
                foreach botn $dlist {
                    set dkey [$nblist insertchild $pkey end $botn]
                    set info(key-$botn)          $dkey
                    set info(pkey-$botn)         $pkey
                    set info(nb-$dkey)           $botn
                    lappend info(children-$midn) $botn
                    set info(selected-$dkey) 0
                }
            }
        }
    
        # NEXT, add a toggle to each row in the second column and 
        # determine the maximum depth of the tree along with the
        # depth of each row, which will determine color
        set maxdepth 0
        foreach key [$nblist getfullkeys 0 end] {
            set row [$nblist index $key]
            $nblist cellconfigure $row,1 -window [mymethod InsertToggle]
            set info(depth-$key) [$nblist depth $key]
            set maxdepth [expr {max($maxdepth, $info(depth-$key))}]
        }

        # NEXT, determine color. A maximum depth of 8 is supported.
        if {$maxdepth > 8} {
            error "Too many levels in the hierarchy."
        }

        # NEXT, based on max depth determine the delta between colors
        # in the gradient.
        set delta [expr {round(8.0/$maxdepth)}]
        
        # NEXT, set color and draw the map
        foreach key [$nblist getfullkeys 0 end] {
            set nb $info(nb-$key)

            # If the nbhood exists already, grey it out
            if {$info(exists-$nb)} {
                set info(color-$info(nb-$key)) #CCCCCC
                continue
            } 
            set idx [expr {($info(depth-$key)-1) * $delta}]
            set info(color-$nb) [$colors color $idx]
        }

        $self UpdateMap
    }

    # UpdateMap
    #
    # This method draws the maps given the current state of neighborhood
    # selections made.  If the map does not have a neighborhood with 
    # the given tablelist key, it is created. 

    method UpdateMap {} {
        # FIRST, get nbhoods from the tree
        set nbhoods [$nblist getcolumns 0]
    
        # NEXT, go through and draw them based on nbhood selection state
        foreach n $nbhoods {
            # NEXT, extract the nbhood key from the info array
            set key $info(key-$n)
    
            # NEXT, if nbhood has not been created, create it
            if {![info exists info(id-$key)]} {
                set poly [$geo coords $n]
                set id [$map nbhood create $info(ref-$n) $poly]
                set info(id-$key) $id
                set info(key-$id) $key
            }
    
            # NEXT, assign default attributes to nbhood
            $map nbhood configure $info(id-$key) \
                -fill       $info(color-$n) \
                -polycolor  black           \
                -pointcolor black           \
                -linewidth  1
    
            $nblist cellconfigure $info(btnidx-$key) \
                -bg $info(color-$n) -selectbackground $info(color-$n)
    
            # NEXT, if this is the active nbhood, draw a thicker line
            if {$info(active) eq $info(id-$key)} {
                $map nbhood configure $info(id-$key) -linewidth 3
            }
    
            # NEXT, configure the look of deselected neighborhoods
            if {!$info(selected-$key) && !$info(exists-$n)} {
    
                # The nbhood is not selected, determine if any parent is
                # selected and adopt that color
                set nb $n
                set color ""
    
                # Traverse up the tree looking for a selected parent until
                # we get to a neighborhood whose parent is "root", which is
                # a top level neighborhood
                while {$info(pkey-$nb) ne "root"} {
                    set pkey $info(pkey-$nb)
                    if {$info(selected-$pkey)} {
                        # This nbhood is selected; adopt the color
                        set color $info(color-$info(nb-$pkey))
                        break
                    } else {
                        # It is not selected; get it's parent
                        set nb $info(nb-$pkey)
                    }
                }
    
                # Configure the look of the deselected nbhood
                $map nbhood configure $info(id-$key) \
                    -fill $color -polycolor #808080 -pointcolor #CCCCCC
    
                 # Configure background of the checkbutton to be the same
                 # as the deselected nbhood
                 $nblist cellconfigure $info(btnidx-$key) \
                    -bg $color -selectbackground $color
            }
        }
    
        # NEXT, get the stacking of neighborhoods right based on the
        # hierarchy of the tree and whether a polygon is selected or not.
        set tree [linsert $nbhoods 0 root]
    
        foreach n $tree {
            # NEXT, if no children, nothing to do
            if {![info exists info(children-$n)] || 
                [llength $info(children-$n)] == 0} {
                continue
            }
    
            # NEXT, separate selected polygons from unselected ones
            set selected [list]
            set unselected [list]
    
            foreach child $info(children-$n) {
                set key $info(key-$child)
    
                if {$info(selected-$key) || $info(exists-$child)} {
                    lappend selected $child
                } else {
                    lappend unselected $child
                }
            }
    
            # NEXT, raise unselected ones first, we want the selected
            # ones to appear on top
            foreach uchild $unselected {
                set key $info(key-$uchild)
                set id $info(id-$key)
                $map raise $id
            }
    
            # NEXT, finally raise the selected ones
            foreach schild $selected {
                set key $info(key-$schild)
                set id $info(id-$key)
                $map raise $id
            }
        }
    }

    #---------------------------------------------------------------------
    # Public methods

    # clear
    #
    # Clears the geoset(n) and tablelist(n) of all content
    # unsets the info array

    method clear {} {
        $geo clear
        $nblist delete 0 end
        array unset info
        set info(active) ""
    }

    # setpoly polydict
    #
    # Sets the dictionary of polygons for display.  The dictionary
    # contains name/polygon pairs.

    method setpolys {polydict} {
        # FIRST, clear everything out
        $self clear

        # NEXT, go through the dictionary checking for polygons that
        # already exist in the scenario
        dict for {name poly} $polydict {
            $geo create polygon $name $poly nbhood
            set info(ref-$name) [$self GetRefPt $name]
            set info(exists-$name) \
                [rdb exists {SELECT n FROM nbhoods WHERE polygon=$poly}]
        }
        
        $self CreateTree
    }

    # getpolys 
    #
    # This method returns the currently selected set of polygons
    # and their reference points as a dictionary.  The dictionary
    # is a name/list pair where the list is, in order, the reference
    # point followed by the coordinates of the polygon:
    #
    #     name  -> [list refpt polygon]

    method getpolys {} {
        # FIRST, get ready to send neighborhood dictionary
        set ndict [dict create]

        # NEXT, go through the entire tree and pull out neighborhoods
        # that have been selected
        set nbhoods [$nblist getcolumns 0]
        foreach n $nbhoods {
            set refpt ""
            set poly  ""

            set key $info(key-$n)

            # NEXT, if it's not selected or already exists, it is not
            # included
            if {!$info(selected-$key) || $info(exists-$n)} {
                continue
            }

            # NEXT, if all it's children are selected, the assumption is
            # that it's completely covered and not included
            if {[$self AllChildrenSelected $n]} {
                continue
            }

            # NEXT, set polygon. 
            set poly [$map nbhood polygon $info(id-$key)]

            # NEXT, determine ref point. If there's no children then
            # use it's own refpoint. If there are children find the first
            # one that is not selected.
            if {[llength $info(children-$n)] == 0} {
                set refpt [$map nbhood point $info(id-$key)]
            } else {
                foreach child $info(children-$n) {
                    set ckey $info(key-$child)
                    if {$info(selected-$ckey) || $info(exists-$child)} {
                        continue
                    }

                    set childpt [$map nbhood point $info(id-$ckey)]

                    # Get random ref point inside child
                    set refpt [$self RandPt $child]

                    # Now, in the unlikely event it's not unique keep trying
                    while {$refpt eq $childpt} {
                        set refpt [$self RandPt $child]
                    }
                }
            }

            dict set ndict $n [list $refpt $poly]
        }

        return $ndict
    }

    #--------------------------------------------------------------------
    # Helper Methods

    # GetRefPt  n
    #
    # n   - A neighborhood polygon in the geoset(n)
    #
    # This method computes a reference point for a neighborhood
    # polygon.  It's possible that one is not found if, for example,
    # a national polygon is completely covered by provincial polygons.
    # Upon output, that is treated as a special case.

    method GetRefPt {n} {
        foreach {x1 y1 x2 y2} [$geo bbox $n] {}
    
        # FIRST, try right in the center of the bounding box
        set x [expr {double($x2 - $x1) / 2.0 + $x1}]
        set y [expr {double($y2 - $y1) / 2.0 + $y1}]
    
        set pt [list $x $y]
    
        if {[$geo find $pt] eq $n} {
            return $pt
        }
    
        # NEXT, traverse a diagonal across the bounding box
        for {set i 0} {$i < 100} {incr i} {
            set x [expr {($x2 - $x1)*((double($i)+1.0)/100.0) + $x1}]
            set y [expr {($y2 - $y1)*((double($i)+1.0)/100.0) + $y1}]
    
            # Is it in the neighborhood (taking stacking order
            # into account)?
            set pt [list $x $y]
    
            if {[$geo find $pt] eq $n} {
                return $pt
            }
        }
    }

    # RandPt  n
    #
    # n   - A neighborhood polygon in the geoset(n)
    #
    # This method tries to find a random point inside the neighborhood
    # supplied. If it fails, it returns the empty string, which must
    # be dealt with by the caller.

    method RandPt {n} {
        # FIRST, get the neighborhood polygon's bounding box
        foreach {x1 y1 x2 y2} [$geo bbox $n] {}

        # NEXT, no more than 100 tries
        for {set i 0} {$i < 100} {incr i} {
            # Get a random lat/lon
            let x {($x2 - $x1)*rand() + $x1}
            let y {($y2 - $y1)*rand() + $y1}

            # Is it in the neighborhood (taking stacking order
            # into account)?
            set pt [list $x $y]

            if {[$geo find $pt] eq $n} {
                return $pt
            }
        }

        return ""
    }

    # AllChildrenSelected  n
    #
    # n   - the name of a neighborhood in the hierarchy
    #
    # This method checks if the supplied neighborhood has all of it's 
    # children selected for output or already exists in the scenario
    # and returns an appropriate flag.

    method AllChildrenSelected {n} {
        set flag 1

        # FIRST, no children means not all selected, by convention
        if {[llength $info(children-$n)] == 0} {
            return 0
        }

        # NEXT, go through the list of children and see if they are
        # all selected without giving consideration to those that may 
        # already exist.
        foreach child $info(children-$n) {
            if {$info(exists-$child)} {
                continue
            }

            set key $info(key-$child)
            let flag {$flag * $info(selected-$key)}
        }

        return $flag
    }
}

