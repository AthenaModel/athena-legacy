#-----------------------------------------------------------------------
# TITLE:
#    linktree.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: URL-driven Entity Tree
#
#    This is a scrolled tree control that displays the IDs of
#    different kinds of entity, by entity type; it gets the entities from
#    a "my://" server given an URL.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export linktree
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::projectgui::linktree {
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    delegate option -height        to tree
    delegate option -width         to tree
    delegate option -defaultserver to agent

    # -url    
    #
    # The URL to read entity types from

    option -url -readonly yes

    # -changecmd
    #
    # A callback when the selection changes.

    option -changecmd

    # -errorcmd
    #
    # Called if there's an error with the -url.  Takes one argument,
    # a string.

    option -errorcmd


    #-------------------------------------------------------------------
    # Components

    component agent     ;# The myagent(n).
    component tree      ;# The treectrl(n) widget

    #-------------------------------------------------------------------
    # Instance Variables

    # info Array: Miscellaneous data
    #
    # inRefresh        - 1 if we're doing a refresh, and 0 otherwise.
    # lastItem         - URI of last selected item, or ""
    # etypes           - List of entity type URIs

    variable info -array {
        inRefresh 0
        lastItem  {}
        etypes    {}
    }

    # uri2id Array: Tree item ID by entity uri.
    # id2uri Array: Entity uri by tree item ID

    variable uri2id -array { }
    variable id2uri -array { }

    #-------------------------------------------------------------------
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

        # NEXT, create the agent
        install agent using myagent ${selfns}::agent \
            -contenttypes tcl/linkdict

        # NEXT, save the options
        $self configurelist $args
    }

    # ItemSelected
    #
    # Calls the -changecmd event, when needed.
    
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

        # NEXT, call the -changecmd with the item URL
        set info(lastItem) $thisItem
        callwith $options(-changecmd) $thisItem
    }

    #-------------------------------------------------------------------
    # Public methods

    # refresh
    #
    # Reloads the entities from the server

    method refresh {} {
        set info(inRefresh) 1

        try {
            # FIRST, get the selected entity, if any, and the 
            # open/close status for each entity type.
            set currentSelection [$self get]
            
            foreach etype [dict keys $info(etypes)] {
                if {[info exists uri2id($etype)]} {
                    set open($etype) [$tree item isopen $uri2id($etype)]
                }
            }

            # NEXT, clear all content from the tree
            $tree item delete 0 end
            array unset uri2id
            array unset id2uri

            # NEXT, get the entity types
            if {[catch {
                $agent get $options(-url)
            } result]} {
                callwith $options(-errorcmd) \
                    "Error getting \"$options(-url)\": $result"
                return
            }

            set info(etypes) [dict get $result content]

            # NEXT, add entities
            dict for {t tdict} $info(etypes) {
                set pid    [$self DrawEntityType $t $tdict]

                if {[catch {
                    $agent get $t
                } result]} {
                    callwith $options(-errorcmd) \
                        "Error getting \"$options(-url)\": $result"
                    continue
                }

                dict with result {
                    dict for {uri edict} $content {
                        $self DrawEntity $pid $uri $edict
                    }
                }
            }

            # NEXT, close folders that should be closed
            foreach etype [array names open] {
                if {!$open($etype)} {
                    $tree collapse $uri2id($etype)
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

    # DrawEntityType etype etdict
    #
    # etype  - An entity type URI
    # etdict - Entity type dictionary

    method DrawEntityType {etype etdict} {
        set id [$tree item create \
                    -parent root \
                    -button auto]

        dict with etdict {
            $tree item text $id 0 $label
            $tree item element configure $id 0 elemIcon \
                -image ::projectgui::icon::folder12
        }

        # Resolve the etype, so that we have a complete URL
        set etype [$agent resolve $options(-url) $etype]

        set uri2id($etype) $id
        set id2uri($id)    $etype

        return $id
    }

    # DrawEntity parent uri edict
    #
    # parent - The tree item ID of the parent
    # uri    - The URI of the entity itself
    # edict  - Dictionary of entity data

    method DrawEntity {parent uri edict} {
        set id [$tree item create -parent $parent]

        dict with edict {
            $tree item text $id 0 $label
            $tree item element configure $id 0 elemIcon \
                -image $listIcon
        }

        # Resolve the entity URL, so that we have a complete URL
        set uri [$agent resolve $options(-url) $uri]

        set uri2id($uri) $id
        set id2uri($id)  $uri
    }

    # set
    #
    # Sets the displayed uri; does not send <<Selection>>

    method set {uri} {
        # FIRST, get the URI in fully resolved form.
        set uri [$agent resolve $options(-url) $uri]

        # NEXT, clear selection on unknown uris
        if {![info exists uri2id($uri)]} {
            $tree selection clear
            return
        }

        # NEXT, make sure the item is visible
        set id $uri2id($uri)

        if {[$tree item parent $id] != 0} {
            $tree expand [list $id parent]
        }

        $tree see $id
        
        # NEXT, select the ID
        $tree selection modify $id all
    }

    
    # get
    #
    # Returns the displayed uri

    method get {} {
        set id [lindex [$tree selection get] 0]

        if {[info exists id2uri($id)]} {
            return $id2uri($id)
        } else {
            return ""
        }
    }
}


