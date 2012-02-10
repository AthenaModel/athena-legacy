#-----------------------------------------------------------------------
# TITLE:
#    strategybrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    strategybrowser(sim) package: Agent/Goal/Tactic browser/editor
#
# TBD:
# 
#    * Perhaps Tree striping should be done lazily.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget strategybrowser {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Create icons
        mkicon ::icon::addgoal {
            ......................
            ......................
            ......................
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            .........XXXX.........
            .........XXXX...XXXX..
            .........XXXX..X......
            .........XXXX..X..XX..
            .........XXXX..X...X..
            .........XXXX...XXXX..
            ......................
            ......................
            ......................
        } { . trans  X black } d { X gray }

        mkicon ::icon::addtactic {
            ......................
            ......................
            ......................
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            .........XXXX.........
            .........XXXX..XXXXX..
            .........XXXX....X....
            .........XXXX....X....
            .........XXXX....X....
            .........XXXX....X....
            ......................
            ......................
            ......................
        } { . trans  X black } d { X gray }

        mkicon ::icon::addcondition {
            ......................
            ......................
            ......................
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            .........XXXX.........
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            .........XXXX.........
            .........XXXX...XXXX..
            .........XXXX..X......
            .........XXXX..X......
            .........XXXX..X......
            .........XXXX...XXXX..
            ......................
            ......................
            ......................
        } { . trans  X black } d { X gray }

        mkicon ::icon::onoff {
            .......................
            .......................
            ..........XXX..........
            .......X..XXX..X.......
            .....XXX..XXX..XXX.....
            ....XXX...XXX...XXX....
            ....XX....XXX....XX....
            ...XX.....XXX.....XX...
            ...XX.....XXX.....XX...
            ..XX......XXX......XX..
            ..XX...............XX..
            ..XX...............XX..
            ..XX...............XX..
            ..XX...............XX..
            ...XX.............XX...
            ...XX.............XX...
            ....XX...........XXX...
            ....XXX.........XXX....
            .....XXXX.....XXXX.....
            .......XXXXXXXXX.......
            .........XXXXX.........
            .......................
        } { . trans  X black } d { X gray }

        mkicon ::icon::dash {
            ......................
            ......................
            ......................
            ......................
            ......................
            ......................
            ......................
            ......................
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ...XXXXXXXXXXXXXXXX...
            ......................
            ......................
            ......................
            ......................
            ......................
            ......................
            ......................
            ......................
        } { . trans  X black } d { X gray }
    }

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull


    #-------------------------------------------------------------------
    # Components

    component reloader       ;# timeout(n) that reloads content

    # AList: Agent List
    component alist          ;# Agent sqlbrowser(n)

    # GTree: Goal/Condition Tree
    component gtree          ;# Goal treectrl
    component gt_bar         ;# GTree toolbar
    component gt_gaddbtn     ;# Add Goal button
    component gt_caddbtn     ;# Add Condition button
    component gt_editbtn     ;# The "Edit" button
    component gt_togglebtn   ;# The Goal state toggle button
    component gt_checkbtn    ;# The Sanity Check button
    component gt_deletebtn   ;# The Delete button

    # TTree: Tactic/Condition Tree
    component ttree          ;# Tactics/Conditions treectrl.
    component tt_bar         ;# Tactics/Conditions toolbar
    component tt_taddbtn     ;# Add Tactic button
    component tt_caddbtn     ;# Add Condition button
    component tt_editbtn     ;# The "Edit" button
    component tt_topbtn      ;# The "Top Priority" button
    component tt_raisebtn    ;# The "Raise Priority" button
    component tt_lowerbtn    ;# The "Lower Priority" button
    component tt_bottombtn   ;# The "Bottom Priority" button
    component tt_togglebtn   ;# The tactic state toggle button
    component tt_deletebtn   ;# The Delete button

    #-------------------------------------------------------------------
    # Instance Variables

    # info array
    #
    #   agent           - Name of currently displayed agent, or ""
    #   reloadRequests  - Number of reload requests since the last reload.
    
    variable info -array {
        agent          ""
        reloadRequests 0
    }

    # gt_g2i: array of GTree goal item IDs by goal_id
    variable gt_g2item -array {}

    # gt_c2item: array of GTree condition item IDs by condition_id
    variable gt_c2item -array {}

    # tt_t2item: array of TTree tactic item IDs by tactic_id
    variable tt_t2item -array {}

    # tt_c2item: array TTree condition item IDs by condition_id
    variable tt_c2item -array {}

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the timeout controlling reload requests.
        install reloader using timeout ${selfns}::reloader \
            -command    [mymethod ReloadContent]           \
            -interval   1                                  \
            -repetition no

        # NEXT, create the GUI components
        ttk::panedwindow $win.hpaner \
            -orient horizontal

        pack $win.hpaner -fill both -expand yes

        ttk::panedwindow $win.hpaner.vpaner \
            -orient vertical

        pack $win.hpaner.vpaner -fill both -expand yes

        $self AListCreate $win.hpaner.alist
        $self GTreeCreate $win.hpaner.vpaner.goals
        $self TTreeCreate $win.hpaner.vpaner.tactics

        $win.hpaner        add $win.hpaner.alist 
        $win.hpaner        add $win.hpaner.vpaner         -weight 1
        $win.hpaner.vpaner add $win.hpaner.vpaner.goals   -weight 1
        $win.hpaner.vpaner add $win.hpaner.vpaner.tactics -weight 2

        # NEXT, configure the command-line options
        $self configurelist $args

        # NEXT, Behavior

        # Reload the content when the window is mapped.
        bind $win <Map> [mymethod MapWindow]

        # Reload the content on various notifier events.
        notifier bind ::sim      <DbSyncB> $self [mymethod ReloadOnEvent]
        notifier bind ::sim      <Tick>    $self [mymethod ReloadOnEvent]
        notifier bind ::strategy <Check>   $self [mymethod ReloadOnEvent]

        # Reload individual entities when they
        # are updated or deleted.

        notifier bind ::rdb <actors>     $self [mymethod MonActor]
        notifier bind ::rdb <goals>      $self [mymethod MonGoals]
        notifier bind ::rdb <tactics>    $self [mymethod MonTactics]
        notifier bind ::rdb <conditions> $self [mymethod MonConditions]

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
    # Reloads the current -view.  Has no effect if the window is
    # not mapped.
    
    method ReloadContent {} {
        # FIRST, we don't do anything until we're mapped.
        if {![winfo ismapped $win]} {
            return
        }

        # NEXT, clear the reload request counter.
        set info(reloadRequests) 0

        # NEXT, Reload each of the components
        $alist reload
        $self GTreeReload
        $self TTreeReload
    }

    # MonActor update|delete a
    #
    # a - The actor ID
    #
    # An actor has been updated or deleted.  Refresh the browser
    # accordingly.

    method MonActor {op a} {
        # FIRST, Update the AList.
        $alist uid $op $a

        # NEXT, if the actor was updated and it's the currently
        # selected agent, refresh the entire browser; a number
        # of things might have changed.
        if {$op eq "update" && $a == $info(agent)} {
            $self reload
        }
    }

    # MonGoals update goal_id
    #
    # goal_id   - A goal ID
    #
    # Displays/adds the goal to the goals tree.

    method {MonGoals update} {goal_id} {
        # FIRST, we need to get the data about this goal.
        # If it isn't for the currently displayed agent, we
        # can ignore it.
        array set gdata [goal get $goal_id]

        if {$gdata(owner) ne $info(agent)} {
            return
        }

        # NEXT, Display the goal item
        $self GTreeGoalDraw gdata
        $self TreeStripe $gtree
    }

    # MonGoals delete goal_id
    #
    # goal_id   - A goal ID
    #
    # Deletes the goal from the goals tree.

    method {MonGoals delete} {goal_id} {
        # FIRST, is this goal displayed?
        if {![info exists gt_g2item($goal_id)]} {
            return
        }

        # NEXT, delete the item from the tree.
        $gtree item delete $gt_g2item($goal_id)
        unset gt_g2item($goal_id)
        $self TreeStripe $gtree
    }

    # MonTactics update tactic_id
    #
    # tactic_id   - A tactic ID
    #
    # Displays/adds the tactic to the tactics tree.

    method {MonTactics update} {tactic_id} {
        # FIRST, we need to get the data about this tactic.
        # If it isn't for the currently displayed agent, we
        # can ignore it.
        array set tdata [tactic get $tactic_id]

        if {$tdata(owner) ne $info(agent)} {
            return
        }

        # NEXT, Display the tactic item
        $self TTreeTacticDraw tdata
        $self TreeStripe $ttree
    }

    # MonTactics delete tactic_id
    #
    # tactic_id   - A tactic ID
    #
    # Deletes the tactic from the tactics tree.

    method {MonTactics delete} {tactic_id} {
        # FIRST, is this tactic displayed?
        if {![info exists tt_t2item($tactic_id)]} {
            return
        }

        # NEXT, delete the item from the tree.
        $ttree item delete $tt_t2item($tactic_id)
        unset tt_t2item($tactic_id)
        $self TreeStripe $ttree
    }

    # MonConditions update condition_id
    #
    # condition_id   - A condition ID
    #
    # Displays/adds the condition to the goals or conditions tree.

    method {MonConditions update} {condition_id} {
        # FIRST, we need to get the data about this condition.
        # If it isn't currently displayed, we can ignore it.
        array set cdata [condition get $condition_id]

        if {[info exists gt_g2item($cdata(cc_id))]} {
            $self GTreeConditionDraw cdata
            $self TreeStripe $gtree
        } elseif {[info exists tt_t2item($cdata(cc_id))]} {
            $self TTreeConditionDraw cdata
            $self TreeStripe $ttree
        }
    }

    # MonConditions delete condition_id
    #
    # condition_id   - A condition ID
    #
    # Deletes the condition from the goals or tactics tree, if it
    # is currently displayed.  NOTE: Conditions are deleted with their
    # goal or tactic; in that case, the item might already be gone
    # from the tree.  So check.

    method {MonConditions delete} {condition_id} {
        # FIRST, is this condition displayed?
        if {[info exists gt_c2item($condition_id)]} {
            # FIRST, delete the item from the tree.
            if {[$gtree item id $gt_c2item($condition_id)] ne ""} {
                $gtree item delete $gt_c2item($condition_id)
            }

            unset gt_c2item($condition_id)
            $self TreeStripe $gtree
        } elseif {[info exists tt_c2item($condition_id)]} {
            # FIRST, delete the item from the tree.
            if {[$ttree item id $tt_c2item($condition_id)] ne ""} {
                $ttree item delete $tt_c2item($condition_id)
            }

            unset tt_c2item($condition_id)
            $self TreeStripe $ttree
        }
    }




    #-------------------------------------------------------------------
    # Agent List Pane

    # AListCreate pane
    #
    # pane - The name of the agent list's pane widget
    #
    # Creates the "alist" component, which lists all of the
    # available agents.

    method AListCreate {pane} {
        # FIRST, create the list widget
        install alist using sqlbrowser $pane          \
            -height       10                          \
            -width        10                          \
            -relief       flat                        \
            -borderwidth  1                           \
            -stripeheight 0                           \
            -db           ::rdb                       \
            -view         agents                      \
            -uid          agent_id                    \
            -filterbox    off                         \
            -selectmode   browse                      \
            -selectioncmd [mymethod AListAgentSelect] \
            -layout {
                {agent_id "Agent" -stretchable yes} 
            } 

        # NEXT, Detect agent updates
        notifier bind ::rdb <actors> $self [list $alist uid]
    }

    # AListAgentSelect
    #
    # Called when an agent is selected in the alist.  Updates the
    # rest of the browser to display that agent's data.

    method AListAgentSelect {} {
        # FIRST, update the rest of the browser
        set agent [lindex [$alist uid curselection] 0]

        if {$agent ne $info(agent)} {
            set info(agent) $agent

            $self GTreeReload
            $self TTreeReload
        }

        # NEXT, update state controllers
        ::cond::simPP_predicate update \
            [list $tt_taddbtn $gt_gaddbtn]
    }


    #-------------------------------------------------------------------
    # GTree: Goals/Conditions Tree Pane

    # GTreeCreate pane
    # 
    # pane - The name of the pane widget
    #
    # Creates the GTree pane, where goals and conditions are
    # edited.

    method GTreeCreate {pane} {
        # FIRST, create the pane
        ttk::frame $pane

        # NEXT, create the toolbar
        install gt_bar using ttk::frame $pane.gt_bar

        ttk::label $gt_bar.title \
            -text "Goals:"

        install gt_gaddbtn using mktoolbutton $gt_bar.gt_gaddbtn    \
            ::icon::addgoal                                         \
            "Add Goal"                                              \
            -state   normal                                         \
            -command [mymethod GTreeGoalAdd]

        cond::simPP_predicate control $gt_gaddbtn                   \
            browser   $win                                          \
            predicate {gtree canAddGoal}

        install gt_caddbtn using mktoolbutton $gt_bar.gt_caddbtn    \
            ::icon::addcondition                                    \
            "Add Condition"                                         \
            -state   normal                                         \
            -command [mymethod GTreeConditionAdd]

        cond::simPP_predicate control $gt_caddbtn                   \
            browser   $win                                          \
            predicate {gtree single}

        install gt_editbtn using mkeditbutton $gt_bar.edit          \
            "Edit Goal or Condition"                                \
            -state   disabled                                       \
            -command [mymethod GTreeEdit]

        cond::simPP_predicate control $gt_editbtn                   \
            browser $win                                            \
            predicate {gtree single}

        install gt_togglebtn using mktoolbutton $gt_bar.toggle      \
            ::icon::onoff                                           \
            "Toggle Goal State"                                     \
            -state   disabled                                       \
            -command [mymethod GTreeGoalState]

        cond::simPP_predicate control $gt_togglebtn                 \
            browser $win                                            \
            predicate {gtree validgoal}

        install gt_checkbtn using ttk::button $gt_bar.check         \
            -style   Toolbutton                                     \
            -text    "Check"                                        \
            -command [mymethod GTreeSanityCheck]

        install gt_deletebtn using mkdeletebutton $gt_bar.delete    \
            "Delete Goal or Condition"                              \
            -state   disabled                                       \
            -command [mymethod GTreeDelete]

        cond::simPP_predicate control $gt_deletebtn                 \
            browser $win                                            \
            predicate {gtree canDelete}
            

        pack $gt_bar.title  -side left
        pack $gt_gaddbtn    -side left
        pack $gt_caddbtn    -side left
        pack $gt_editbtn    -side left
        pack $gt_togglebtn  -side left
        pack $gt_checkbtn   -side left

        pack $gt_deletebtn  -side right

        ttk::separator $pane.sep1 \
            -orient horizontal

        # NEXT, create the goals tree widget
        install gtree using $self TreeCreate $pane.gtree \
            -height         100                          \
            -yscrollcommand [list $pane.yscroll set]

        ttk::scrollbar $pane.yscroll                 \
            -orient         vertical                 \
            -command        [list $gtree yview]

        # Standard tree column options:
        set colopts [list \
                         -background     $::marsgui::defaultBackground \
                         -borderwidth    1                             \
                         -button         off                           \
                         -font           TkDefaultFont                 \
                         -resize         no]

        # Tree column 0: narrative
        $gtree column create {*}$colopts               \
            -text        "Goal/Condition"            \
            -itemstyle   wrapStyle                     \
            -expand      yes                           \
            -squeeze     yes                           \
            -weight      1

        $gtree configure -treecolumn first

        # Tree column 1: goal_id/condition_id
        $gtree column create {*}$colopts  \
            -text        "Id"             \
            -itemstyle   numStyle         \
            -tags        id

        # Tree column 2: condition_type
        $gtree column create {*}$colopts  \
            -text        "Type"           \
            -itemstyle   textStyle        \
            -tags        type

        # NEXT, grid them all in place
        grid $gt_bar       -row 0 -column 0 -sticky ew -columnspan 2
        grid $pane.sep1    -row 1 -column 0 -sticky ew -columnspan 2
        grid $gtree        -row 2 -column 0 -sticky nsew
        grid $pane.yscroll -row 2 -column 1 -sticky ns

        grid rowconfigure    $pane 2 -weight 1
        grid columnconfigure $pane 0 -weight 1
 
        # NEXT, prepare to handle selection changes.
        $gtree notify bind $gtree <Selection> [mymethod GTreeSelection]
    }

    # GTreeReload
    #
    # Loads data from the goals and conditions tables into gtree.

    method GTreeReload {} {
        # FIRST, save the selection (at most one thing should be selected).
        set id [lindex [$gtree select get] 0]

        if {$id eq ""} {
            set selKind ""
            set selId   ""
        } else {
            set selId [$gtree item text $id {tag id}]

            if {"goal" in [$gtree item tag names $id]} {
                set selKind goal
            } else {
                set selKind condition
            }
        }

        # NEXT, get a list of the collapsed goals
        set collapsed [list]

        foreach id [$gtree item children root] {
            if {![$gtree item state get $id open]} {
                lappend collapsed [$gtree item text $id {tag id}]
            }
        }


        # NEXT, empty the gtree
        $gtree item delete all
        array unset gt_g2item
        array unset gt_c2item

        # NEXT, if no agent we're done.
        if {$info(agent) eq ""} {
            return
        }

        # NEXT, insert the goals
        rdb eval {
            SELECT *
            FROM goals
            WHERE owner=$info(agent)
            ORDER BY goal_id
        } row {
            unset -nocomplain row(*)
            $self GTreeGoalDraw row
        }

        # NEXT, insert the conditions
        rdb eval {
            SELECT C.*,
                   G.owner
            FROM conditions AS C
            JOIN goals AS G ON (cc_id = goal_id)
            WHERE G.owner=$info(agent)
            ORDER BY condition_id;
        } row {
            unset -nocomplain row(*)
            $self GTreeConditionDraw row
        }

        # NEXT, set striping
        $self TreeStripe $gtree

        # NEXT, open the same goals as before
        foreach goal_id $collapsed {
            if {[info exists gt_g2item($goal_id)]} {
                $gtree item collapse $gt_g2item($goal_id)
            }
        }

        # NEXT, if there was a selection before, select it again
        if {$selKind eq "goal"} {
            if {[info exists gt_g2item($selId)]} {
                $gtree selection add $gt_g2item($selId)
            }
        } elseif {$selKind eq "condition"} {
            if {[info exists gt_c2item($selId)]} {
                $gtree selection add $gt_c2item($selId)
            }
        }
    }

    # GTreeSelection
    #
    # Called when the gtree's selection has changed.

    method GTreeSelection {} {
        ::cond::simPP_predicate update \
            [list $gt_caddbtn $gt_editbtn $gt_deletebtn $gt_togglebtn]
    }

    # GTreeEdit
    #
    # Called when the GTree's edit button is pressed.
    # Edits the selected entity.

    method GTreeEdit {} {
        # FIRST, there should be only one selected.
        set id [lindex [$gtree selection get] 0]

        # NEXT, it has an ID; if it's a condition it has a type
        set oid   [$gtree item text $id {tag id}]
        set otype [$gtree item text $id {tag type}]

        # NEXT, it's a goal or a condition.
        if {"goal" in [$gtree item tag names $id]} {
            order enter GOAL:UPDATE goal_id $oid
        } else {
            order enter CONDITION:$otype:UPDATE condition_id $oid
        }
    }

    # GTreeGoalAdd
    #
    # Allows the user to create a new goal.
    
    method GTreeGoalAdd {} {
        order enter GOAL:CREATE owner $info(agent)
    }

    # GTreeGoalState
    #
    # Toggles the goal's state from normal to disabled and back
    # again.

    method GTreeGoalState {} {
        # FIRST, there should be only one selected.
        set id [lindex [$gtree selection get] 0]

        # NEXT, get its goal ID
        set goal_id [$gtree item text $id {tag id}]

        # NEXT, Get its state
        set state [goal get $goal_id state]

        if {$state eq "normal"} {
            order send gui GOAL:STATE goal_id $goal_id state disabled
        } elseif {$state eq "disabled"} {
            order send gui GOAL:STATE goal_id $goal_id state normal
        } else {
            # Do nothing (this should never happen anyway)
        }
    }

    # GTreeSanityCheck
    #
    # Allows the user to create a new goal.
    
    method GTreeSanityCheck {} {
        if {![strategy sanity check]} {
            app show my://app/sanity/strategy
        }
    }

    # GTreeDelete
    #
    # Called when the GTree's delete button is pressed.
    # Deletes the selected entity.

    method GTreeDelete {} {
        # FIRST, there should be only one selected.
        set id [lindex [$gtree selection get] 0]

        # NEXT, it's a goal or a condition.
        if {"goal" in [$gtree item tag names $id]} {
            order send gui GOAL:DELETE \
                goal_id [$gtree item text $id {tag id}]
        } else {
            order send gui CONDITION:DELETE \
                condition_id [$gtree item text $id {tag id}]
        }
    }

    # GTreeGoalDraw gdataVar
    #
    # gdataVar - Name of an array containing goal attributes
    #
    # Adds/updates a goal item in the gtree.

    method GTreeGoalDraw {gdataVar} {
        upvar $gdataVar gdata

        # FIRST, get the goal item ID; if there is none,
        # create one.
        if {![info exists gt_g2item($gdata(goal_id))]} {
            set id [$gtree item create \
                        -parent root   \
                        -button auto   \
                        -tags   goal]

            $gtree item expand $id

            set gt_g2item($gdata(goal_id)) $id
        } else {
            set id $gt_g2item($gdata(goal_id))
        }

        # NEXT, set the text.
        $gtree item text $id               \
            0           $gdata(narrative)  \
            {tag id}    $gdata(goal_id)    \
            {tag type}  ""

        # NEXT, set the state flags
        $self TreeItemState $gtree $id $gdata(state)
        $self TreeItemFlag  $gtree $id $gdata(flag)

        # NEXT, sort goals by goal ID.
        $gtree item sort root -column {tag id} -integer
    }

    # GTreeConditionAdd
    #
    # Allows the user to pick a condition from a pulldown, and
    # then pops up the related CONDITION:*:CREATE dialog.
    
    method GTreeConditionAdd {} {
        # FIRST, get a list of order names and titles
        set odict [dict create]

        foreach name [condition type names -goal] {
            set order "CONDITION:$name:CREATE"

            # Get title, and remove the "Create Condition: " prefix
            set title [order title $order]
            set ndx [string first ":" $title]
            set title [string range $title $ndx+2 end]
            dict set odict $title $order
        }

        set list [lsort [dict keys $odict]]

        # NEXT, get the goal_id
        set id    [lindex [$gtree selection get] 0]
        set oid   [$gtree item text $id {tag id}]

        if {"goal" in [$gtree item tag names $id]} {
            set cc_id $oid
            $gtree item expand $id
        } else {
            set cc_id [condition get $oid cc_id]
        }

        # NEXT, let them pick one
        set title [messagebox pick \
                       -parent    [app topwin]         \
                       -initvalue [lindex $list 0]     \
                       -title     "Select a condition" \
                       -values    $list                \
                       -message   [normalize "
                           Select a condition to create for
                           agent $info(agent)'s goal $cc_id.
                       "]]

        if {$title ne ""} {
            order enter [dict get $odict $title ] cc_id $cc_id
        }
    }

    # GTreeConditionDraw cdataVar
    #
    # cdataVar - Name of an array containing condition attributes
    #
    # Adds/updates a condition item in the gtree.

    method GTreeConditionDraw {cdataVar} {
        upvar $cdataVar cdata

        # FIRST, get the parent item ID
        set parent $gt_g2item($cdata(cc_id))

        # NEXT, get the condition item ID; if there is none,
        # create one.
        if {![info exists gt_c2item($cdata(condition_id))]} {
            set id [$gtree item create     \
                        -parent $parent    \
                        -tags   condition]

            set gt_c2item($cdata(condition_id)) $id
        } else {
            set id $gt_c2item($cdata(condition_id))
        }

        # NEXT, set the text
        $gtree item text $id                       \
            0               $cdata(narrative)      \
            {tag id}        $cdata(condition_id)   \
            {tag type}      $cdata(condition_type)

        # NEXT, set the state flags
        $self TreeItemState $gtree $id $cdata(state)
        $self TreeItemFlag  $gtree $id $cdata(flag)

        # NEXT, sort conditions by condition.
        $gtree item sort $parent -column {tag id} -integer
    }


    #-------------------------------------------------------------------
    # TTree: Tactics/Conditions Tree Pane

    # TTreeCreate pane
    # 
    # pane - The name of the pane widget
    #
    # Creates the tactics pane, where tactics and conditions are
    # edited.

    method TTreeCreate {pane} {
        # FIRST, create the pane
        ttk::frame $pane

        # NEXT, create the toolbar
        install tt_bar using ttk::frame $pane.tt_bar

        # Temporary add button, just for looks
        ttk::label $tt_bar.title \
            -text "Tactics:"

        install tt_taddbtn using mktoolbutton $tt_bar.tt_taddbtn \
            ::icon::addtactic                                    \
            "Add Tactic"                                         \
            -state   normal                                      \
            -command [mymethod TTreeTacticAdd]

        cond::simPP_predicate control $tt_taddbtn                \
            browser   $win                                       \
            predicate {alist single}

        install tt_caddbtn using mktoolbutton $tt_bar.tt_caddbtn \
            ::icon::addcondition                                 \
            "Add Condition"                                      \
            -state   normal                                      \
            -command [mymethod TTreeConditionAdd]

        cond::simPP_predicate control $tt_caddbtn                \
            browser   $win                                       \
            predicate {ttree single}

        install tt_editbtn using mkeditbutton $tt_bar.edit       \
            "Edit Tactic or Condition"                           \
            -state   disabled                                    \
            -command [mymethod TTreeEdit]

        cond::simPP_predicate control $tt_editbtn                \
            browser $win                                         \
            predicate {ttree single}

        install tt_topbtn using mktoolbutton $tt_bar.top         \
            ::marsgui::icon::totop                            \
            "Top Priority"                                       \
            -state   disabled                                    \
            -command [mymethod TTreeTacticPriority top]

        cond::simPP_predicate control $tt_topbtn                 \
            browser $win                                         \
            predicate {ttree tactic}

        install tt_raisebtn using mktoolbutton $tt_bar.raise     \
            ::marsgui::icon::raise                            \
            "Raise Priority"                                     \
            -state   disabled                                    \
            -command [mymethod TTreeTacticPriority raise]

        cond::simPP_predicate control $tt_raisebtn               \
            browser $win                                         \
            predicate {ttree tactic}

        install tt_lowerbtn using mktoolbutton $tt_bar.lower     \
            ::marsgui::icon::lower                            \
            "Lower Priority"                                     \
            -state   disabled                                    \
            -command [mymethod TTreeTacticPriority lower]

        cond::simPP_predicate control $tt_lowerbtn               \
            browser $win                                         \
            predicate {ttree tactic}

        install tt_bottombtn using mktoolbutton $tt_bar.bottom   \
            ::marsgui::icon::tobottom                         \
            "Bottom Priority"                                    \
            -state   disabled                                    \
            -command [mymethod TTreeTacticPriority bottom]

        cond::simPP_predicate control $tt_bottombtn              \
            browser $win                                         \
            predicate {ttree tactic}

        install tt_togglebtn using mktoolbutton $tt_bar.toggle   \
            ::icon::onoff                                        \
            "Toggle Tactic State"                                \
            -state   disabled                                    \
            -command [mymethod TTreeTacticState]

        cond::simPP_predicate control $tt_togglebtn              \
            browser $win                                         \
            predicate {ttree validtactic}

        install tt_deletebtn using mkdeletebutton $tt_bar.delete \
            "Delete Tactic or Condition"                         \
            -state   disabled                                    \
            -command [mymethod TTreeDelete]

        cond::simPP_predicate control $tt_deletebtn              \
            browser $win                                         \
            predicate {ttree single}
            
        pack $tt_bar.title -side left
        pack $tt_taddbtn    -side left
        pack $tt_caddbtn    -side left
        pack $tt_editbtn    -side left
        pack $tt_topbtn     -side left
        pack $tt_raisebtn   -side left
        pack $tt_lowerbtn   -side left
        pack $tt_bottombtn  -side left
        pack $tt_togglebtn  -side left

        pack $tt_deletebtn  -side right

        ttk::separator $pane.sep1 \
            -orient horizontal

        # NEXT, create the tactics tree widget
        install ttree using $self TreeCreate $pane.ttree \
            -height         200                          \
            -yscrollcommand [list $pane.yscroll set]

        ttk::scrollbar $pane.yscroll                 \
            -orient         vertical                 \
            -command        [list $ttree yview]

        # Standard tree column options:
        set colopts [list \
                         -background     $::marsgui::defaultBackground \
                         -borderwidth    1                             \
                         -button         off                           \
                         -font           TkDefaultFont                 \
                         -resize         no]

        # Tree column 0: narrative
        $ttree column create {*}$colopts               \
            -text        "Tactic/Condition"            \
            -itemstyle   wrapStyle                     \
            -expand      yes                           \
            -squeeze     yes                           \
            -weight      1

        $ttree configure -treecolumn first

        # Tree column 1: Exec time stamp
        $ttree column create {*}$colopts  \
            -text        "Last Exec"      \
            -itemstyle   textStyle        \
            -tags        exec_ts

        # Tree column 2: Once?
        $ttree column create {*}$colopts  \
            -text        "Once?"          \
            -itemstyle   textStyle        \
            -tags        once

        # Tree column 3: $
        $ttree column create {*}$colopts  \
            -text        "Est. $"         \
            -itemstyle   numStyle         \
            -tags        dollars

        # Tree column 4: tactic_id/condition_id
        $ttree column create {*}$colopts  \
            -text        "Id"             \
            -itemstyle   numStyle         \
            -tags        id

        # Tree column 5: tactic_type/condition_type
        $ttree column create {*}$colopts  \
            -text        "Type"           \
            -itemstyle   textStyle        \
            -tags        type

        # Tree column 6: priority
        $ttree column create {*}$colopts  \
            -text        "Priority"       \
            -itemstyle   textStyle        \
            -tags        priority         \
            -visible     no

        # NEXT, grid them all in place
        grid $tt_bar         -row 0 -column 0 -sticky ew -columnspan 2
        grid $pane.sep1    -row 1 -column 0 -sticky ew -columnspan 2
        grid $ttree        -row 2 -column 0 -sticky nsew
        grid $pane.yscroll -row 2 -column 1 -sticky ns

        grid rowconfigure    $pane 2 -weight 1
        grid columnconfigure $pane 0 -weight 1
 
        # NEXT, prepare to handle selection changes.
        $ttree notify bind $ttree <Selection> [mymethod TTreeSelection]
    }

    # TTreeReload
    #
    # Loads data from the tactics and conditions tables into ttree.

    method TTreeReload {} {
        # FIRST, save the selection (at most one thing should be selected.
        set id [lindex [$ttree select get] 0]

        if {$id eq ""} {
            set selKind ""
            set selId   ""
        } else {
            set selId [$ttree item text $id {tag id}]

            if {"tactic" in [$ttree item tag names $id]} {
                set selKind tactic
            } else {
                set selKind condition
            }
        }

        # NEXT, get a list of the expanded tactics
        set collapsed [list]

        foreach id [$ttree item children root] {
            if {![$ttree item state get $id open]} {
                lappend collapsed [$ttree item text $id {tag id}]
            }
        }


        # NEXT, empty the ttree
        $ttree item delete all
        array unset tt_t2item
        array unset tt_c2item

        # NEXT, if no agent we're done.
        if {$info(agent) eq ""} {
            return
        }

        # NEXT, insert the tactics
        rdb eval {
            SELECT *
            FROM tactics
            WHERE owner=$info(agent)
            ORDER BY priority
        } row {
            unset -nocomplain row(*)
            $self TTreeTacticDraw row
        }

        # NEXT, insert the conditions
        rdb eval {
            SELECT C.*,
                   T.owner
            FROM conditions AS C
            JOIN tactics AS T ON (cc_id = tactic_id)
            WHERE T.owner=$info(agent)
            ORDER BY condition_id;
        } row {
            unset -nocomplain row(*)
            $self TTreeConditionDraw row
        }

        # NEXT, set striping
        $self TreeStripe $ttree

        # NEXT, open the same tactics as before
        foreach tactic_id $collapsed {
            if {[info exists tt_t2item($tactic_id)]} {
                $ttree item collapse $tt_t2item($tactic_id)
            }
        }

        # NEXT, if there was a selection before, select it again
        if {$selKind eq "tactic"} {
            if {[info exists tt_t2item($selId)]} {
                $ttree selection add $tt_t2item($selId)
            }
        } elseif {$selKind eq "condition"} {
            if {[info exists tt_c2item($selId)]} {
                $ttree selection add $tt_c2item($selId)
            }
        }
    }

    # TTreeSelection
    #
    # Called when the ttree's selection has changed.

    method TTreeSelection {} {
        ::cond::simPP_predicate update \
            [list $tt_caddbtn $tt_editbtn $tt_deletebtn $tt_togglebtn \
                 $tt_topbtn $tt_raisebtn $tt_lowerbtn $tt_bottombtn]
    }

    # TTreeEdit
    #
    # Called when the TTree's delete button is pressed.
    # Deletes the selected entity.

    method TTreeEdit {} {
        # FIRST, there should be only one selected.
        set id [lindex [$ttree selection get] 0]

        # NEXT, it has a type and an ID
        set otype [$ttree item text $id {tag type}]
        set oid   [$ttree item text $id {tag id}]

        # NEXT, it's a tactic or a condition.
        if {"tactic" in [$ttree item tag names $id]} {
            order enter TACTIC:$otype:UPDATE \
                tactic_id $oid
        } else {
            order enter CONDITION:$otype:UPDATE \
                condition_id $oid
        }
    }

    # TTreeTacticAdd
    #
    # Allows the user to pick a tactic from a pulldown, and
    # then pops up the related TACTIC:*:CREATE dialog.
    
    method TTreeTacticAdd {} {
        # FIRST, get a list of tactic types for the current agent
        set ttypes [lsort [tactic type names_by_agent $info(agent)]]

        # NEXT, get a list of order names and titles
        set odict [dict create]

        foreach ttype $ttypes {
            set order "TACTIC:$ttype:CREATE"
            set title [string map {"Create Tactic: " ""} [order title $order]]
            dict set odict "$ttype: $title" $order
        }

        set titles [dict keys $odict]

        # NEXT, let them pick one
        set title [messagebox pick \
                       -parent    [app topwin]        \
                       -initvalue [lindex $titles 0]  \
                       -title     "Select a tactic"   \
                       -values    $titles             \
                       -message   [normalize "
                           Select a tactic to create for 
                           agent $info(agent).
                       "]]

        if {$title ne ""} {
            order enter [dict get $odict $title ] owner $info(agent)
        }
    }


    # TTreeTacticPriority prio
    #
    # prio    A token indicating the new priority.
    #
    # Sets the selected tactic's priority.

    method TTreeTacticPriority {prio} {
        # FIRST, there should be only one selected.
        set id [lindex [$ttree selection get] 0]

        # NEXT, get its tactic ID
        set tactic_id [$ttree item text $id {tag id}]

        # NEXT, Set its priority.
        order send gui TACTIC:PRIORITY tactic_id $tactic_id priority $prio
    }


    # TTreeTacticState
    #
    # Toggles the tactic's state from normal to disabled and back
    # again.

    method TTreeTacticState {} {
        # FIRST, there should be only one selected.
        set id [lindex [$ttree selection get] 0]

        # NEXT, get its tactic ID
        set tactic_id [$ttree item text $id {tag id}]

        # NEXT, Get its state
        set state [tactic get $tactic_id state]

        if {$state eq "normal"} {
            order send gui TACTIC:STATE tactic_id $tactic_id state disabled
        } elseif {$state eq "disabled"} {
            order send gui TACTIC:STATE tactic_id $tactic_id state normal
        } else {
            # Do nothing (this should never happen anyway)
        }
    }


    # TTreeDelete
    #
    # Called when the TTree's delete button is pressed.
    # Deletes the selected entity.

    method TTreeDelete {} {
        # FIRST, there should be only one selected.
        set id [lindex [$ttree selection get] 0]

        # NEXT, it's a tactic or a condition.
        if {"tactic" in [$ttree item tag names $id]} {
            order send gui TACTIC:DELETE \
                tactic_id [$ttree item text $id {tag id}]
        } else {
            order send gui CONDITION:DELETE \
                condition_id [$ttree item text $id {tag id}]
        }
    }

    # TTreeTacticDraw tdataVar
    #
    # tdataVar - Name of an array containing tactic attributes
    #
    # Adds/updates a tactic item in the ttree.

    method TTreeTacticDraw {tdataVar} {
        upvar $tdataVar tdata

        # FIRST, get the tactic item ID; if there is none,
        # create one.
        if {![info exists tt_t2item($tdata(tactic_id))]} {
            set id [$ttree item create \
                        -parent root   \
                        -button auto   \
                        -tags   tactic]

            $ttree item expand $id

            set tt_t2item($tdata(tactic_id)) $id
        } else {
            set id $tt_t2item($tdata(tactic_id))
        }

        # NEXT, get the execution timestamp
        if {$tdata(exec_ts) ne ""} {
            set timestamp [simclock toZulu $tdata(exec_ts)]
        } else {
            set timestamp ""
        }

        # NEXT, set the text.
        set tdict [array get tdata]

        if {$tdata(once)} {
            set once YES
        } else {
            set once NO
        }

        $ttree item text $id                             \
            0               $tdata(narrative)            \
            {tag exec_ts}   $timestamp                   \
            {tag once}      $once                        \
            {tag dollars}   [tactic call dollars $tdict] \
            {tag id}        $tdata(tactic_id)            \
            {tag type}      $tdata(tactic_type)          \
            {tag priority}  $tdata(priority)

        # NEXT, set the state flags
        $self TreeItemState $ttree $id $tdata(state)

        if {$tdata(exec_flag)} {
            $ttree item state set $id check
        } else {
            $ttree item state set $id !check
        }

        # NEXT, sort tactics by priority.
        $ttree item sort root -column {tag priority} -integer
    }

    # TTreeConditionAdd
    #
    # Allows the user to pick a condition from a pulldown, and
    # then pops up the related CONDITION:*:CREATE dialog.
    
    method TTreeConditionAdd {} {
        # FIRST, get a list of order names and titles
        set odict [dict create]

        foreach name [condition type names -tactic] {
            set order "CONDITION:$name:CREATE"

            if {![string match "CONDITION:*:CREATE" $order]} {
                continue
            }

            # Get title, and remove the "Create Condition: " prefix
            set title [order title $order]
            set ndx [string first ":" $title]
            set title [string range $title $ndx+2 end]
            dict set odict $title $order
        }

        set list [lsort [dict keys $odict]]

        # NEXT, get the tactic_id.  Make sure it's expanded.
        set id    [lindex [$ttree selection get] 0]
        set otype [$ttree item text $id {tag type}]
        set oid   [$ttree item text $id {tag id}]

        if {"tactic" in [$ttree item tag names $id]} {
            set cc_id $oid
            $ttree item expand $id
        } else {
            set cc_id [condition get $oid cc_id]
        }

        # NEXT, let them pick one
        set title [messagebox pick \
                       -parent    [app topwin]      \
                       -initvalue [lindex $list 0]  \
                       -title     "Select a condition" \
                       -values    $list             \
                       -message   [normalize "
                           Select a condition to create for
                           agent $info(agent)'s tactic $cc_id.
                       "]]

        if {$title ne ""} {
            order enter [dict get $odict $title ] cc_id $cc_id
        }
    }

    # TTreeConditionDraw cdataVar
    #
    # cdataVar - Name of an array containing condition attributes
    #
    # Adds/updates a condition item in the ttree.

    method TTreeConditionDraw {cdataVar} {
        upvar $cdataVar cdata

        # FIRST, get the parent item ID
        set parent $tt_t2item($cdata(cc_id))

        # NEXT, get the condition item ID; if there is none,
        # create one.
        if {![info exists tt_c2item($cdata(condition_id))]} {
            set id [$ttree item create     \
                        -parent $parent    \
                        -tags   condition]

            set tt_c2item($cdata(condition_id)) $id
        } else {
            set id $tt_c2item($cdata(condition_id))
        }

        # NEXT, set the text
        $ttree item text $id                       \
            0               $cdata(narrative)      \
            {tag once}      ""                     \
            {tag dollars}   ""                     \
            {tag id}        $cdata(condition_id)   \
            {tag type}      $cdata(condition_type)

        # NEXT, set the state flags
        $self TreeItemState $ttree $id $cdata(state)
        $self TreeItemFlag  $ttree $id $cdata(flag)

        # NEXT, sort conditions by condition.
        $ttree item sort $parent -column {tag id} -integer
    }

    #-------------------------------------------------------------------
    # Tree Routines
    #
    # This section contains code shared by the Goals and Tactics Trees.

    # TreeCreate tree ?options...?
    #
    # tree    - The name of the treectrl to create
    # options - treectrl options and their values
    #
    # Creates and returns a new treectrl with standard options, states,
    # elements, and styles.

    method TreeCreate {tree args} {
        # NEXT, create the tree widget
        treectrl $tree                 \
            -width          400        \
            -height         100        \
            -borderwidth    0          \
            -relief         flat       \
            -background     white      \
            -linestyle      dot        \
            -usetheme       1          \
            -showheader     1          \
            -showroot       0          \
            -showrootlines  0          \
            -indent         14         \
            {*}$args

        # NEXT, create the states, elements, and styles.

        # Define Item states
        $tree state define stripe     ;# Item is striped
        $tree state define disabled   ;# Item is disabled by user
        $tree state define invalid    ;# Item is invalid.
        $tree state define check      ;# Item gets a checkmark
        $tree state define true       ;# Item is known to be true
        $tree state define false      ;# Item is known to be false

        # Fonts
        set overstrike [dict merge [font actual codefont] {-overstrike 1}]

        set fontList [list \
                          $overstrike disabled \
                          codefont    {}]

        # Text fill
        set fillList [list \
                          "#999999" disabled \
                          red        invalid  \
                          black      {}]

        # Elements
        $tree element create itemText text  \
            -font    $fontList              \
            -fill    $fillList

        $tree element create wrapText text  \
            -font    $fontList              \
            -fill    $fillList              \
            -wrap    word

        $tree element create numText text   \
            -font    $fontList              \
            -fill    $fillList              \
            -justify right

        $tree element create thumbIcon image \
            -image {
                ::marsgui::icon::check22        check
                ::marsgui::icon::smthumbupgreen true
                ::marsgui::icon::smthumbdownred false
                ::icon::dash                    {}
            }

        $tree element create elemRect rect               \
            -fill {gray {selected} "#CCFFBB" {stripe}}

        # wrapStyle: wrapped text over a fill rectangle.

        $tree style create wrapStyle
        $tree style elements wrapStyle {elemRect thumbIcon wrapText}
        $tree style layout wrapStyle thumbIcon
        $tree style layout wrapStyle wrapText  \
            -squeeze x                         \
            -iexpand nse                       \
            -ipadx   4
        $tree style layout wrapStyle elemRect \
            -union   {thumbIcon wrapText}

        # textStyle: text over a fill rectangle.
        $tree style create textStyle
        $tree style elements textStyle {elemRect itemText}
        $tree style layout textStyle itemText \
            -iexpand nse                      \
            -ipadx   4
        $tree style layout textStyle elemRect \
            -union   {itemText}

        # numStyle: numeric text over a fill rectangle.
        $tree style create numStyle
        $tree style elements numStyle {elemRect numText}
        $tree style layout numStyle numText \
            -iexpand nsw                    \
            -ipadx   4
        $tree style layout numStyle elemRect \
            -union {numText}

        # NEXT, return the new widget
        return $tree
    }

    # TreeItemState tree id state
    #
    # tree     - The goal or tactics tree
    # id       - The item ID
    # state    - normal|disabled|invalid
    #
    # Sets the tree state flags for a tree item to match the 
    # state of the application entity.

    method TreeItemState {tree id state} {
        if {$state eq "normal"} {
            $tree item state set $id !disabled
            $tree item state set $id !invalid
        } elseif {$state eq "disabled"} {
            $tree item state set $id disabled
            $tree item state set $id !invalid
        } else {
            # invalid
            $tree item state set $id !disabled
            $tree item state set $id invalid
        }
    }

    # TreeItemFlag tree id flag
    #
    # tree     - The goal or tactics tree
    # id       - The item ID
    # flag     - 1 or 0 or ""
    #
    # Sets the tree state flags for a tree item to match the 
    # the application entity true/false/unknown flag

    method TreeItemFlag {tree id flag} {
        if {$flag == 1} {
            $tree item state set $id true
            $tree item state set $id !false
        } elseif {$flag == 0} {
            $tree item state set $id false
            $tree item state set $id !true
        } else {
            $tree item state set $id !false
            $tree item state set $id !true
        }
    }


    # TreeStripe tree
    #
    # Stripes the even-numbered top-level items, and colors their
    # children the same way.

    method TreeStripe {tree} {
        set count 0
        
        foreach id [$tree item children root] {
            set last  [$tree item lastchild $id]

            if {$last eq ""} {
                set last $id
            }

            if {$count % 2 == 1} {
                $tree item state set $id $last stripe
            } else {
                $tree item state set $id $last !stripe
            }

            incr count
        }
    }




    #-------------------------------------------------------------------
    # State Controller Predicates
    #
    # These methods are used in statecontroller -conditions to control
    # the state of toolbar buttons and such-like.

    # alist single
    #
    # Returns 1 if a single item is selected in the AList, and 0 
    # otherwise.
    
    method {alist single} {} {
        expr {[llength [$alist curselection]] == 1}
    }
    
    # gtree single
    #
    # Returns 1 if a single item is selected in the GTree, and 0 
    # otherwise.
    
    method {gtree single} {} {
        expr {[llength [$gtree selection get]] == 1}
    }

    # gtree validgoal
    #
    # Returns 1 if a valid (not invalid) goal is selected in the
    # GTree, and 0 otherwise.
    
    method {gtree validgoal} {} {
        if {[llength [$gtree selection get]] != 1} {
            return 0
        }

        set id [lindex [$gtree selection get] 0]
        
        if {"goal" in [$gtree item tag names $id] &&
            ![$gtree item state get $id invalid]
        } {
            return 1
        } else {
            return 0
        }
    }

    # gtree canAddGoal
    #
    # Returns 1 if a goal can be added, i.e., if an agent is selected
    # in the AList, and the GOAL:CREATE order is available, and 0 otherwise.
    
    method {gtree canAddGoal} {} {
        expr {[$self alist single] && [order available GOAL:CREATE]}
    }

    # gtree canDelete
    #
    # Returns 1 if the currently selected entity in the goal browser
    # can be deleted, and 0 otherwise.  To delete, one entity must be
    # selected; and if it is a goal, the GOAL:DELETE order must be
    # available.
    
    method {gtree canDelete} {} {
        if {![$self gtree single]} {
            return 0
        }

        set id [lindex [$gtree selection get] 0]
        
        if {"goal" in [$gtree item tag names $id]} {
            return [order available GOAL:DELETE]
        } {
            # It's a condition
            return 1
        }

        expr {[$self alist single] && [order available GOAL:CREATE]}
    }

    # ttree single
    #
    # Returns 1 if a single item is selected in the TTree, and 0 
    # otherwise.
    
    method {ttree single} {} {
        expr {[llength [$ttree selection get]] == 1}
    }

    # ttree tactic
    #
    # Returns 1 if a tactic is selected in the TTree, and 0 
    # otherwise.
    
    method {ttree tactic} {} {
        if {[llength [$ttree selection get]] != 1} {
            return 0
        }

        set id [lindex [$ttree selection get] 0]
        
        return [expr {"tactic" in [$ttree item tag names $id]}]
    }

    # ttree validtactic
    #
    # Returns 1 if a valid (not invalid) tactic is selected in the
    # TTree, and 0 otherwise.
    
    method {ttree validtactic} {} {
        if {[llength [$ttree selection get]] != 1} {
            return 0
        }

        set id [lindex [$ttree selection get] 0]
        
        if {"tactic" in [$ttree item tag names $id] &&
            ![$ttree item state get $id invalid]
        } {
            return 1
        } else {
            return 0
        }
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



