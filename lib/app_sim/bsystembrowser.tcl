#-----------------------------------------------------------------------
# TITLE:
#    bsystembrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    bsystembrowser(sim) package: Belief System Browser
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget bsystembrowser {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        enum erelevance {
            0 No
            1 Yes
        }
    }

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull


    #-------------------------------------------------------------------
    # Components

    component reloader       ;# timeout(n) that reloads content

    component tlist          ;# Topic list
    component taddbtn        ;# Add Topic button
    component teditbtn       ;# Edit Topic button
    component tdeletebtn     ;# Delete Topic button

    component etree          ;# Entity list
    component blist          ;# Belief list
    component alist          ;# Affinity list

    #-------------------------------------------------------------------
    # Instance Variables

    # info array
    #
    #   entity          - Name of currently displayed entity, or ""
    #   reloadRequests  - Number of reload requests since the last reload.
    
    variable info -array {
        entity         ""
        reloadRequests 0
    }

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the timeout controlling reload requests.
        install reloader using timeout ${selfns}::reloader \
            -command    [mymethod ReloadContent]           \
            -interval   1                                  \
            -repetition no

        # NEXT, create the GUI components
        ttk::panedwindow $win.vpaner \
            -orient vertical
        
        pack $win.vpaner -fill both -expand yes

        ttk::panedwindow $win.vpaner.hpaner \
            -orient horizontal

        $self TListCreate $win.vpaner.tlist
        $self ETreeCreate $win.vpaner.hpaner.etree
        $self BListCreate $win.vpaner.hpaner.blist
        $self AListCreate $win.vpaner.hpaner.alist

        $win.vpaner        add $win.vpaner.tlist
        $win.vpaner        add $win.vpaner.hpaner       -weight 1
        $win.vpaner.hpaner add $win.vpaner.hpaner.etree 
        $win.vpaner.hpaner add $win.vpaner.hpaner.blist -weight 1
        $win.vpaner.hpaner add $win.vpaner.hpaner.alist -weight 1

        # NEXT, bind to notifier events
        notifier bind ::sim <DbSyncB>   $win [mymethod ReloadOnEvent]
        notifier bind ::sim <State>     $win [mymethod ReloadOnEvent]
        notifier bind ::rdb <actors>    $win [mymethod ReloadOnEvent]
        notifier bind ::rdb <civgroups> $win [mymethod ReloadOnEvent]

        # Reload the content from the current view when the window
        # is mapped.
        bind $win <Map> [mymethod MapWindow]

        # NEXT, schedule the first reload
        $self reload
    }

    destructor {
        notifier forget $self
    }

    # MapWindow
    #
    # Reload the browser when the window is mapped, if there have
    # been any reload requests.
    
    method MapWindow {} {
        # If a reload has been requested, but the reloader is no
        # longer scheduled (i.e., the reload was requested while
        # the window was unmapped) then reload it now.
        if {$info(reloadRequests) > 0 &&
            ![$reloader isScheduled]
        } {
            $self ReloadContent
        }
    }

    # ReloadOnEvent
    #
    # Reloads the widget when various notifier events are received.
    # The "args" parameter is so that any event can be handled.
    
    method ReloadOnEvent {args} {
        $self reload
    }
    
    # ReloadContent
    #
    # Reloads the current data.  Has no effect if the window is
    # not mapped.
    
    method ReloadContent {} {
        # FIRST, we don't do anything until we're mapped.
        if {![winfo ismapped $win]} {
            return
        }
        
        # NEXT, clear the reload request counter.
        set info(reloadRequests) 0

        # NEXT, Reload each of the components
        $tlist reload
        $etree refresh
        $blist reload
        $alist reload
    }

    #-------------------------------------------------------------------
    # Topic List pane

    # TListCreate pane
    #
    # pane - The name of the topic list's pane widget
    #
    # Creates the "TList" component, which lists all of the 
    # topic definitions.

    method TListCreate {pane} {
        # FIRST, create the component
        install tlist using sqlbrowser $pane                   \
            -height           8                                \
            -width            30                               \
            -db               ::rdb                            \
            -view             mam_topic                        \
            -uid              tid                              \
            -filterbox        off                              \
            -selectioncmd     [mymethod TListSelectionChanged] \
            -displaycmd       [mymethod TListWindows]          \
            -editstartcommand [mymethod TListTitleEditStart]   \
            -editendcommand   [mymethod TListTitleEditEnd]     \
            -layout     {
                { tid       "Topic"                               }
                { relevance "Relevant?" -formatcommand {format ""}} 
                { title     "Title"     -stretchable yes          }
            }

        # NEXT, add the toolbar.
        set bar [$tlist toolbar]

        ttk::label $bar.title \
            -text "Topics"

        install taddbtn using mktoolbutton $bar.add \
            ::projectgui::icon::plust22             \
            "Add a new topic"                       \
            -command [mymethod TListAddTopic]

        cond::available control $taddbtn \
            order BSYSTEM:TOPIC:CREATE

        install teditbtn using mkeditbutton $bar.edit \
            "Edit Topic"                              \
            -state   disabled                         \
            -command [mymethod TListEditTopic]

        cond::availableSingle control $teditbtn \
            order   BSYSTEM:TOPIC:UPDATE        \
            browser $tlist

        install tdeletebtn using mkdeletebutton $bar.delete \
            "Delete Topic"                                  \
            -state   disabled                               \
            -command [mymethod TListDeleteTopic]

        cond::availableSingle control $tdeletebtn \
            order   BSYSTEM:TOPIC:DELETE          \
            browser $tlist

        pack $bar.title  -side left
        pack $taddbtn    -side left
        pack $teditbtn   -side left
        pack $tdeletebtn -side right

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <mam_topic> $self [list $tlist uid]
    }

    # TListSelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection.

    method TListSelectionChanged {} {
        cond::availableSingle update [list $teditbtn $tdeletebtn]
    }


    # TListAddTopic
    #
    # Pops up the order to add a new topic.

    method TListAddTopic {} {
        order enter BSYSTEM:TOPIC:CREATE
    }

    # TListEditTopic
    #
    # Called when the user wants to edit the selected topic.

    method TListEditTopic {} {
        # FIRST, there should be only one selected.
        set id [lindex [$tlist uid curselection] 0]

        # NEXT, Delete the entity
        order enter BSYSTEM:TOPIC:UPDATE tid $id
    }


    # TListDeleteTopic
    #
    # Called when the user wants to delete the selected topic.

    method TListDeleteTopic {} {
        # FIRST, there should be only one selected.
        set id [lindex [$tlist uid curselection] 0]

        # NEXT, Delete the entity
        order send gui BSYSTEM:TOPIC:DELETE tid $id
    }


    # TListWindows r data
    #
    # r      - The row number
    # data   - A list of data values
    #
    # This is a -displaycmd, called when a row is put in the database.
    # It specifies the window creation command for cells that need one.

    method TListWindows {r data} {
        set rc $r,[$tlist cname2cindex relevance]

        $tlist cellconfigure $rc \
            -window [mymethod TListCreateEditor]

        set cwin [$tlist windowpath $rc]

        if {[sim state] ne "PREP"} {
            $cwin configure -state disabled
        }

        $cwin set [$tlist cellcget $rc -text] -silent
    }

    # TListCreateEditor tbl r c w
    #
    # tbl   The tablelist
    # r     The row being edited
    # c     The column being edited
    # w     The window to be created
    #
    # Creates the relevance pulldown.

    method TListCreateEditor {tbl r c w} {
        # Create the field widget, and give it its initial value.
        ::marsgui::enumfield $w \
            -enumtype    ::bsystembrowser::erelevance    \
            -displaylong yes                             \
            -width       5                               \
            -font        [$tbl cget -font]               \
            -changecmd   [mymethod TListTopicChanged $r]
    }


    # TListTopicChanged r newValue
    #
    # r         The row being edited
    # newValue  The new value
    #
    # Used with embedded windows.  Saves the edited value, and updates 
    # the GUI.

    method TListTopicChanged {r newValue} {
        # FIRST, get the tid for this row
        set tid [$tlist rindex2uid $r]

        # NEXT, save the new value, updating everything but 
        # this component.

        order send gui BSYSTEM:TOPIC:UPDATE tid $tid relevance $newValue

        $alist reload
    }

    # TListTitleEditStart tbl r c text
    #
    # tbl   The tablelist
    # r     The row being edited
    # c     The column being edited
    # text  The new text
    #
    # Loads the relevance into the enumfield.

    method TListTitleEditStart {tbl r c text} {
        return $text
    }


    # TListTitleEditEnd tbl r c text
    #
    # tbl   The tablelist
    # r     The row being edited
    # c     The column being edited
    # text  The new text
    #
    # Saves the edited value.

    method TListTitleEditEnd {w r c text} {
        # FIRST, get the tid for this row
        set tid [$tlist rindex2uid $r]

        if {[$tlist cindex2cname $c] eq "title"} {
            order send gui BSYSTEM:TOPIC:UPDATE tid $tid title $text
        }

        return $text
    }


    #-------------------------------------------------------------------
    # Entity List Pane

    # EtreeCreate pane
    #
    # pane - The name of the entity list's pane widget
    #
    # Creates the "etree" component, which lists all of the
    # available entities (actors and civgroups).

    method ETreeCreate {pane} {
        frame $pane

        ttk::label $pane.title \
            -text "Entities"

        install etree using linktree $pane.tree     \
            -url       my://app/entitytype/bsystem  \
            -width     1.5i                         \
            -height    200                          \
            -changecmd [mymethod ETreeSelect]

        grid $pane.title -row 0 -column 0 -sticky w    -pady {3 2}
        grid $pane.tree  -row 1 -column 0 -sticky nsew

        grid rowconfigure    $pane 1 -weight 1
        grid columnconfigure $pane 0 -weight 1
    }

    # ETreeSelect url
    #
    # url - The URL of the selected entity or entity type
    #
    # Called when an entity is selected in the elist.

    method ETreeSelect {url} {
        # TBD: Technically, this is tacky; we shouldn't be extracting
        # the entity ID from the URL string in this way, but instead 
        # should use the URL to request what we really want.  But,
        # this is at the border between "my://" and rdb-land.

        set eid [file tail $url]
        $blist configure -where "eid='$eid'"
        $alist configure -where "f='$eid' AND g != '$eid'"
    }


    #-------------------------------------------------------------------
    # Belief List Pane

    # BListCreate pane
    #
    # pane - The name of the belief list's pane widget
    #
    # Creates the "BList" component, which lists all of the
    # beliefs of the currently selected entity.

    method BListCreate {pane} {
        # FIRST, create the component
        install blist using sqlbrowser $pane       \
            -height      5                         \
            -width       40                        \
            -db          ::rdb                     \
            -view        gui_mam_belief            \
            -uid         id                        \
            -filterbox   off                       \
            -displaycmd  [mymethod BListWindows]   \
            -where       {0}                       \
            -layout      {
                { tid "Topic" }
                { position "Position" 
                    -formatcommand {format ""} }
                { tolerance "Tolerance" 
                    -stretchable yes 
                    -formatcommand {format ""} }
            }

        set bar [$blist toolbar]

        ttk::label $bar.title \
            -text "Beliefs"

        pack $bar.title -side left


        # NEXT, update individual entities when they change.
        notifier bind ::rdb <mam_belief> $self [list $blist uid]
    }

    # BlistWindows r data
    #
    # r      - The row number
    # data   - A list of data values
    #
    # This is a -displaycmd, called when a row is put in the database.
    # It specifies the window creation command for cells that need one.

    method BListWindows {r data} {
        foreach column {position tolerance} {
            # FIRST, get the cell ID
            set rc $r,[$blist cname2cindex $column]

            # NEXT, configure the window command for the cell.
            $blist cellconfigure $rc \
                -window [mymethod BListCreateEditor]

            # NEXT, set the window's state and value
            set cwin [$blist windowpath $rc]

            if {[sim state] ne "PREP"} {
                $cwin configure -state disabled
            }

            $cwin set [$blist cellcget $rc -text] -silent
        }
    }

    # BListCreateEditor tbl r c w
    #
    # tbl   The tablelist
    # r     The row being edited
    # c     The column being edited
    # w     The window to be created
    #
    # Creates the position and tolerance pulldowns.

    method BListCreateEditor {tbl r c w} {
        set cname [$blist cindex2cname $c]

        if {$cname eq "position"} {
            set wintype ::qposition
            set width 20
        } else {
            set wintype ::qtolerance
            set width 15
        }

        ::marsgui::enumfield $w   \
            -enumtype    $wintype                             \
            -displaylong yes                                  \
            -width       $width                               \
            -font        [$tbl cget -font]                    \
            -changecmd   [mymethod BListChanged $r $cname]
    }


    # BListChanged r cname newValue
    #
    # r         The row being edited
    # cname     The column name
    # newValue  The new value
    #
    # Saves the edited value, and updates the GUI.

    method BListChanged {r cname newValue} {
        # FIRST, get the eid and tid for this row
        set id [$blist rindex2uid $r]

        # NEXT, save the new value
        order send gui BSYSTEM:BELIEF:UPDATE id $id $cname $newValue
        
        $alist reload
    }


    #-------------------------------------------------------------------
    # Affinity List Pane

    # AListCreate pane
    #
    # pane - The name of the affinity list's pane widget
    #
    # Creates the "AList" component, which lists all of the
    # affinities of the currently selected entity.

    method AListCreate {pane} {
        install alist using sqlbrowser $pane     \
            -height      5                       \
            -width       30                      \
            -db          ::rdb                   \
            -view        gui_mam_acompare        \
            -uid         id                      \
            -filterbox   off                     \
            -displaycmd  [mymethod AListDisplay] \
            -where       0                       \
            -layout      {
                {f   "Entity A"                 }
                {g   "Entity B"                 }
                {afg "A for B"                  }
                {agf "B for A"  -stretchable yes}
            }

        set bar [$alist toolbar]

        ttk::label $bar.title \
            -text "Affinities"

        pack $bar.title -side left
    }

    # AListDisplay r data
    #
    # r      - The row number
    # data   - A list of data values
    #
    # This is a -displaycmd, called when a row is added to the AList.
    # It assigns icons to the entities.

    method AListDisplay {r data} {
        lassign $data eid1 eid2

        $self AListSetIcon $r,0 $eid1
        $self AListSetIcon $r,1 $eid2
    }

    # AListSetIcon cellindex eid
    #
    # cellindex - A cellindex in the AList
    # eid       - The entity ID shown in the cell
    #
    # Sets the cell's icon according to its contents

    method AListSetIcon {cellindex eid} {
        if {$eid in [actor names]} {
            set icon ::projectgui::icon::actor12
        } else {
            set icon ::projectgui::icon::civgroup12
        }

        $alist cellconfigure $cellindex -image $icon
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # reload
    #
    # Schedules a reload of the content.  Note that the reload will
    # be ignored if the window isn't mapped.
    
    method reload {} {
        incr info(reloadRequests)
        $reloader schedule -nocomplain
    }
}


