#-----------------------------------------------------------------------
# TITLE:
#    entitytree.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Entity Tree
#
#    This is a scrolled tree control that displays the IDs of
#    different kinds of entity, by entity type.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export entitytree
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::projectgui::entitytree {
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    delegate option -height to tree
    delegate option -width  to tree

    # -rdb    
    #
    # The RDB to read entities from

    option -rdb -readonly yes

    # -label
    #
    # Label text for the tree header.

    option -label \
        -configuremethod ConfigLabel

    method ConfigLabel {opt val} {
        set options($opt) $val

        if {$val ne ""} {
            $tree configure -showheader yes
            $tree column configure tree -text $val

        } else {
            $tree configure -showheader no
            $tree column configure tree -text ""
        }
    }

    # -changecmd
    #
    # A callback when the selection changes.

    option -changecmd


    #-------------------------------------------------------------------
    # Components

    component rdb       ;# The sqldocument(n) to browse.
    component tree      ;# The treectrl(n) widget

    #-------------------------------------------------------------------
    # Instance Variables

    # info Array: Miscellaneous data
    #
    # inRefresh        - 1 if we're doing a refresh, and 0 otherwise.
    # lastItem         - Name of last selected item, or ""
    # tables           - List of entity table names
    # key-$table       - Name of key field
    # label-$table     - Human-readable label for the kind of entity
    # icon-$table      - Tk image to display with the label

    variable info -array {
        inRefresh 0
        lastItem  {}
        tables    {}
    }

    # name2id Array: Tree item ID by entity name.
    # id2name Array: Entity name by tree item ID
    #
    # There are special entity names: .actor, .nbhood, .civgroup, 
    # .frcgroup, .orggroup.

    variable name2id -array { }
    variable id2name -array { }

    #-------------------------------app_sim/------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the tree
        install tree using treectrl $win.tree       \
            -width          1.25i                   \
            -borderwidth    1                       \
            -relief         sunken                  \
            -background     white                   \
            -usetheme       1                       \
            -showroot       0                       \
            -showheader     0                       \
            -showbuttons    1                       \
            -selectmode     single                  \
            -itemwidthequal 1                       \
            -indent         14                      \
            -yscrollcommand [list $win.yscroll set]

        $tree element create elemText text \
            -font codefont \
            -fill black
        $tree element create elemIcon image

        $tree element create elemRect rect -fill {gray {selected}}
        $tree style create style1
        $tree style elements style1 {elemRect elemIcon elemText}
        $tree style layout style1 elemText -iexpand nse -padx 4
        $tree style layout style1 elemRect -union {elemIcon elemText}

        $tree column create                            \
            -borderwidth 1                             \
            -expand      yes                           \
            -resize      no                            \
            -background  $::marsgui::defaultBackground \
            -font        TkDefaultFont                 \
            -itemstyle   style1 
        $tree configure -treecolumn 0

        $tree column configure tail \
            -borderwidth 0         \
            -squeeze     yes

        # NEXT, create the scrollbar
        ttk::scrollbar $win.yscroll     \
            -orient  vertical           \
            -command [list $tree yview]

        # NEXT, grid them in
        grid $tree        -row 0 -column 0 -sticky nsew
        grid $win.yscroll -row 0 -column 1 -sticky ns   -pady {1 0}

        grid columnconfigure $win 0 -weight 1
        grid rowconfigure    $win 0 -weight 1

        # NEXT, get selection events
        $tree notify bind $tree <Selection> \
            [mymethod ItemSelected]

        # NEXT, save the options
        $self configurelist $args

        set rdb $options(-rdb)
    }

    # ItemSelected
    #
    # Sends a <<Selection>> event, when needed.
    
    method ItemSelected {} {
        # FIRST, if we're in a refresh call, do nothing.
        if {$info(inRefresh)} {
            return
        }

        # NEXT, get the selected item.
        set thisItem [$self get]

        if {$info(lastItem) eq $thisItem} {
            return
        }

        # NEXT, call the -changecmd with the item name.
        set info(lastItem) $thisItem
        callwith $options(-changecmd) $thisItem
    }

    # RefreshEvent args...
    #
    # args - Ignored
    #
    # Refreshes the content of the widget when the entity lists change.
    
    method RefreshEvent {args} {
        $self refresh
    }


    #-------------------------------------------------------------------
    # Public methods

    # add table key label icon
    #
    # table  - Name of a table containing entity definitions
    # key    - Name of the key field
    # label  - A label string to use for entities of this type
    # icon   - An icon to use for entities of this type
    #
    # Saves the data, and arranges to refresh the content as it
    # changes.

    method add {table key label icon} {
        # FIRST, save the data
        ladd info(tables) $table
        
        set info(key-$table)   $key
        set info(label-$table) $label
        set info(icon-$table)  $icon
    }

    # refresh
    #
    # Reloads the list of pages from the rdb

    method refresh {} {
        set info(inRefresh) 1

        try {
            # FIRST, get the selected entity, if any, and the 
            # open/close status for each entity type.
            set currentSelection [$self get]
            
            foreach table $info(tables) {
                if {[info exists name2id(.$table)]} {
                    set open($table) [$tree item isopen $name2id(.$table)]
                }
            }

            # NEXT, clear all content from the tree
            $tree item delete 0 end
            array unset name2id
            array unset id2name

            # NEXT, add entities
            foreach t $info(tables) {
                set pid [$self DrawEntityType .$t $info(label-$t)]
                
                $rdb eval "
                    SELECT $info(key-$t) AS id
                    FROM $t ORDER BY $info(key-$t)
                " {
                    $self DrawEntity $pid $info(icon-$t) $id
                }
            
            }

            # NEXT, close folders that should be closed
            foreach table [array names open] {
                if {!$open($table)} {
                    $tree collapse $name2id(.$table)
                }
            }

            # NEXT, set the item
            if {$currentSelection ne ""} {
                $self set $currentSelection
            }
        } finally {
            set info(inRefresh) 0
        }

    }

    # DrawEntityType name label
    #
    # name   - A magic token, e.g., .actor
    # label  - The label string for display

    method DrawEntityType {name label} {
        set id [$tree item create \
                    -parent root \
                    -button auto]

        $tree item text $id 0 $label
        $tree item element configure $id 0 elemIcon \
            -image ::marsgui::icon::folder12

        set name2id($name) $id
        set id2name($id)   $name

        return $id
    }

    # DrawEntity parent icon name
    #
    # parent - The tree item ID of the parent
    # icon   - The icon image for display
    # name   - The entity name

    method DrawEntity {parent icon name} {
        set id [$tree item create -parent $parent]

        $tree item text $id 0 $name
        $tree item element configure $id 0 elemIcon \
            -image $icon

        set name2id($name) $id
        set id2name($id)   $name
    }

    # set
    #
    # Sets the displayed name; does not send <<Selection>>

    method set {name} {
        # FIRST, clear selection on unknown names
        if {![info exists name2id($name)]} {
            $tree selection clear
            return
        }

        # NEXT, make sure this is a leaf item.
        set id $name2id($name)

        if {[$tree item parent $id] == 0} {
            $tree selection clear
            return
        }

        # NEXT, make sure the item is visible
        $tree expand [list $id parent]
        $tree see $id
        
        # NEXT, select the ID
        $tree selection modify $id all
    }

    
    # get
    #
    # Returns the displayed name

    method get {} {
        set id [lindex [$tree selection get] 0]

        if {$id ne "" && [$tree item parent $id] != 0} {
            return $id2name($id)
        } else {
            return ""
        }
    }
}
