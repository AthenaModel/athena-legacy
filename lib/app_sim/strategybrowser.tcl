#-----------------------------------------------------------------------
# TITLE:
#    strategybrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    strategybrowser(sim) package: Actor/Goal/Tactic browser/editor
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget strategybrowser {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Create icons
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

    component reloader ;# timeout(n) that reloads content

    component alist       ;# Actor sqlbrowser(n)
    component tbar        ;# Tactics/Conditions toolbar
    component taddbtn     ;# Add Tactic button
    component caddbtn     ;# Add Condition button
    component editbtn     ;# The "Edit" button
    component topbtn      ;# The "Top Priority" button
    component raisebtn    ;# The "Raise Priority" button
    component lowerbtn    ;# The "Lower Priority" button
    component bottombtn   ;# The "Bottom Priority" button
    component togglebtn   ;# The tactic state toggle button
    component deletebtn   ;# The Delete button
    
    component ttree    ;# Tactics/Conditions treectrl.

    #-------------------------------------------------------------------
    # Instance Variables

    # info array
    #
    #   actor           - Name of currently displayed actor, or ""
    #   reloadRequests  - Number of reload requests since the last reload.
    
    variable info -array {
        actor          ""
        reloadRequests 0
    }

    # tactic2item: array of $ttree tactic item IDs by tactic_id
    variable tactic2item -array {}

    # condition2item: array $ttree condition item IDs by condition_id
    variable condition2item -array {}
    

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the timeout controlling reload requests.
        install reloader using timeout ${selfns}::reloader \
            -command    [mymethod ReloadContent]           \
            -interval   1                                  \
            -repetition no

        # NEXT, create the GUI components
        ttk::panedwindow $win.atpaner \
            -orient horizontal

        pack $win.atpaner -fill both -expand yes

        $self CreateActorList   $win.atpaner.alist
        $self CreateTacticsPane $win.atpaner.tactics

        $win.atpaner add $win.atpaner.alist 
        $win.atpaner add $win.atpaner.tactics -weight 1

        # NEXT, configure the command-line options
        $self configurelist $args

        # NEXT, Behavior

        # Reload the content on various notifier events.
        notifier bind ::sim <DbSyncB> $self [mymethod ReloadOnEvent]
        notifier bind ::sim <Tick>    $self [mymethod ReloadOnEvent]
        notifier bind ::rdb <actors>  $self [mymethod ActorUpdate]


        # Reload the content when the window is mapped.
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
    
    # ActorUpdate update|delete a
    #
    # a - The actor ID
    #
    # An actor has been updated or deleted.  Refresh the browser
    # accordingly.

    method ActorUpdate {op a} {
        # FIRST, Update the AList.
        $alist uid $op $a

        # NEXT, if the actor was updated and it's the currently
        # selected actor, refresh the entire browser; a number
        # of things might have changed.
        if {$op eq "update" && $a == $info(actor)} {
            $self reload
        }
    }


    #-------------------------------------------------------------------
    # Actor List Pane

    # CreateActorList pane
    #
    # pane - The name of the actor list's pane widget
    #
    # Creates the "alist" component, which lists all of the
    # available actors.

    method CreateActorList {pane} {
        # FIRST, create the list widget
        # TBD: Should set -stripeheight 0

        install alist using sqlbrowser $pane     \
            -height       10                     \
            -width        10                     \
            -relief       flat                   \
            -borderwidth  1                      \
            -stripeheight 0                      \
            -db           ::rdb                  \
            -view         actors                 \
            -uid          a                      \
            -filterbox    off                    \
            -selectmode   browse                 \
            -selectioncmd [mymethod ActorSelect] \
            -layout {
                {a "Actor" -stretchable yes} 
            } 

        # NEXT, update individual entities when they change.
        notifier bind ::rdb <actors> $self [list $alist uid]
    }

    # ActorSelect
    #
    # Called when an actor is selected in the alist.  Updates the
    # rest of the browser to display that actor's data.

    method ActorSelect {} {

        # FIRST, update the rest of the browser
        set actor [lindex [$alist uid curselection] 0]

        if {$actor ne $info(actor)} {
            set info(actor) $actor

            $self reload
        }

        # NEXT, update state controllers
        ::cond::simPP_predicate update \
            [list $taddbtn]
    }

    #-------------------------------------------------------------------
    # Tactics Pane

    # CreateTacticsPane pane
    # 
    # pane - The name of the pane widget
    #
    # Creates the tactics pane, where tactics and conditions are
    # edited.

    method CreateTacticsPane {pane} {
        # FIRST, create the pane
        ttk::frame $pane

        # NEXT, create the toolbar
        install tbar using ttk::frame $pane.tbar

        # Temporary add button, just for looks
        ttk::label $tbar.title \
            -text "Tactics:"

        install taddbtn using mktoolbutton $tbar.taddbtn    \
            ::icon::addtactic                               \
            "Add Tactic"                                    \
            -state   normal                                 \
            -command [mymethod TacticAdd]

        cond::simPP_predicate control $taddbtn              \
            browser   $win                                  \
            predicate {alist single}

        install caddbtn using mktoolbutton $tbar.caddbtn    \
            ::icon::addcondition                            \
            "Add Condition"                                 \
            -state   normal                                 \
            -command [mymethod ConditionAdd]

        cond::simPP_predicate control $caddbtn              \
            browser   $win                                  \
            predicate {ttree single}

        install editbtn using mkeditbutton $tbar.edit       \
            "Edit Tactic or Condition"                      \
            -state   disabled                               \
            -command [mymethod TTreeEdit]

        cond::simPP_predicate control $editbtn              \
            browser $win                                    \
            predicate {ttree single}

        install topbtn using mktoolbutton $tbar.top         \
            ::projectgui::icon::totop                       \
            "Top Priority"                                  \
            -state   disabled                               \
            -command [mymethod TacticPriority top]

        cond::simPP_predicate control $topbtn               \
            browser $win                                    \
            predicate {ttree tactic}

        install raisebtn using mktoolbutton $tbar.raise     \
            ::projectgui::icon::raise                       \
            "Raise Priority"                                \
            -state   disabled                               \
            -command [mymethod TacticPriority raise]

        cond::simPP_predicate control $raisebtn             \
            browser $win                                    \
            predicate {ttree tactic}

        install lowerbtn using mktoolbutton $tbar.lower     \
            ::projectgui::icon::lower                       \
            "Lower Priority"                                \
            -state   disabled                               \
            -command [mymethod TacticPriority lower]

        cond::simPP_predicate control $lowerbtn             \
            browser $win                                    \
            predicate {ttree tactic}

        install bottombtn using mktoolbutton $tbar.bottom   \
            ::projectgui::icon::tobottom                    \
            "Bottom Priority"                               \
            -state   disabled                               \
            -command [mymethod TacticPriority bottom]

        cond::simPP_predicate control $bottombtn            \
            browser $win                                    \
            predicate {ttree tactic}

        install togglebtn using mktoolbutton $tbar.toggle   \
            ::icon::onoff                                   \
            "Toggle Tactic State"                           \
            -state   disabled                               \
            -command [mymethod TacticState]

        cond::simPP_predicate control $togglebtn            \
            browser $win                                    \
            predicate {ttree validtactic}

        install deletebtn using mkdeletebutton $tbar.delete \
            "Delete Tactic or Condition"                    \
            -state   disabled                               \
            -command [mymethod TTreeDelete]

        cond::simPP_predicate control $deletebtn            \
            browser $win                                    \
            predicate {ttree single}
            

        pack $tbar.title -side left
        pack $taddbtn    -side left
        pack $caddbtn    -side left
        pack $editbtn    -side left
        pack $topbtn     -side left
        pack $raisebtn   -side left
        pack $lowerbtn   -side left
        pack $bottombtn  -side left
        pack $togglebtn  -side left

        pack $deletebtn  -side right

        ttk::separator $pane.sep1 \
            -orient horizontal

        # NEXT, create the tactics tree widget
        install ttree using treectrl $pane.ttree     \
            -width          400                      \
            -height         200                      \
            -borderwidth    0                        \
            -relief         flat                     \
            -background     white                    \
            -linestyle      dot                      \
            -usetheme       1                        \
            -showheader     1                        \
            -showroot       0                        \
            -showrootlines  0                        \
            -indent         14                       \
            -yscrollcommand [list $pane.tscroll set]

        ttk::scrollbar $pane.tscroll                 \
            -orient         vertical                 \
            -command        [list $ttree yview]

        # NEXT, configure the tactics tree widget

        # Fonts
        set overstrike [dict merge [font actual codefont] {-overstrike 1}]

        # Define Item states
        $ttree state define stripe     ;# Item is striped
        $ttree state define overstrike ;# Item text has overstrike.
        $ttree state define error      ;# Item is invalid.
        $ttree state define check      ;# Tactic was executed next time
        $ttree state define true       ;# Condition is known to be true
        $ttree state define false      ;# Condition is known to be false

        # Elements
        $ttree element create itemText text               \
            -font [list $overstrike overstrike codefont {}] \
            -fill [list red error black {}] 

        $ttree element create wrapText text               \
            -font [list $overstrike overstrike codefont {}] \
            -fill [list red error black {}]             \
            -wrap word

        $ttree element create numText text                     \
            -font    [list $overstrike overstrike codefont {}] \
            -fill    [list red error black {}]                 \
            -justify right

        $ttree element create thumbIcon image \
            -image {
                ::marsgui::icon::check22        check
                ::marsgui::icon::smthumbupgreen true
                ::marsgui::icon::smthumbdownred false
                ::icon::dash                    {}
            }

        $ttree element create elemRect rect               \
            -fill {gray {selected} "#CCFFBB" {stripe}}

        # wrapStyle: wrapped text over a fill rectangle.

        $ttree style create wrapStyle
        $ttree style elements wrapStyle {elemRect thumbIcon wrapText}
        $ttree style layout wrapStyle thumbIcon
        $ttree style layout wrapStyle wrapText \
            -squeeze x                         \
            -iexpand nse                        \
            -ipadx   4
        $ttree style layout wrapStyle elemRect \
            -union   {thumbIcon wrapText}

        # textStyle: text over a fill rectangle.
        $ttree style create textStyle
        $ttree style elements textStyle {elemRect itemText}
        $ttree style layout textStyle itemText \
            -iexpand nse                        \
            -ipadx   4
        $ttree style layout textStyle elemRect \
            -union   {itemText}

        # numStyle: numeric text over a fill rectangle.
        $ttree style create numStyle
        $ttree style elements numStyle {elemRect numText}
        $ttree style layout numStyle numText \
            -iexpand nsw                        \
            -ipadx   4
        $ttree style layout numStyle elemRect \
            -union {numText}

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

        # Tree column 2: $
        $ttree column create {*}$colopts  \
            -text        "$"              \
            -itemstyle   numStyle         \
            -tags        dollars

        # Tree column 3: Personnel
        $ttree column create {*}$colopts  \
            -text        "Pers."          \
            -itemstyle   numStyle         \
            -tags        personnel

        # Tree column 4: tactic_id
        $ttree column create {*}$colopts  \
            -text        "Id"             \
            -itemstyle   numStyle         \
            -tags        id

        # Tree column 5: tactic_type
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
        grid $tbar         -row 0 -column 0 -sticky ew -columnspan 2
        grid $pane.sep1    -row 1 -column 0 -sticky ew -columnspan 2
        grid $ttree        -row 2 -column 0 -sticky nsew
        grid $pane.tscroll -row 2 -column 1 -sticky ns

        grid rowconfigure    $pane 2 -weight 1
        grid columnconfigure $pane 0 -weight 1
 
        # NEXT, update individual tactics and conditions when they change.
        notifier bind ::rdb <tactics>    $self [mymethod MonTactics]
        notifier bind ::rdb <conditions> $self [mymethod MonConditions]

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
        set expanded [list]

        foreach id [$ttree item children root] {
            if {[$ttree item state get $id open]} {
                lappend expanded [$ttree item text $id {tag id}]
            }
        }


        # NEXT, empty the ttree
        $ttree item delete all
        array unset tactic2item
        array unset condition2item

        # NEXT, if no actor we're done.
        if {$info(actor) eq ""} {
            return
        }

        # NEXT, insert the tactics
        rdb eval {
            SELECT *
            FROM tactics
            WHERE owner=$info(actor)
            ORDER BY priority
        } row {
            unset -nocomplain row(*)
            $self TacticDraw row
        }

        # NEXT, insert the conditions
        rdb eval {
            SELECT C.*,
                   T.owner
            FROM conditions AS C
            JOIN tactics AS T USING (tactic_id)
            WHERE owner=$info(actor)
            ORDER BY condition_id;
        } row {
            unset -nocomplain row(*)
            $self ConditionDraw row
        }

        # NEXT, set striping
        $self TTreeStripe

        # NEXT, open the same tactics as before
        foreach tactic_id $expanded {
            if {[info exists tactic2item($tactic_id)]} {
                $ttree item expand $tactic2item($tactic_id)
            }
        }

        # NEXT, if there was a selection before, select it again
        if {$selKind eq "tactic"} {
            if {[info exists tactic2item($selId)]} {
                $ttree selection add $tactic2item($selId)
            }
        } elseif {$selKind eq "condition"} {
            if {[info exists condition2item($selId)]} {
                $ttree selection add $condition2item($selId)
            }
        }
    }

    # TTreeStripe
    #
    # Makes the odd tactics and their conditions use the stripe background.

    method TTreeStripe {} {
        set count 0
        
        foreach id [$ttree item children root] {
            set last  [$ttree item lastchild $id]

            if {$last eq ""} {
                set last $id
            }

            if {$count % 2 == 1} {
                $ttree item state set $id $last stripe
            } else {
                $ttree item state set $id $last !stripe
            }

            incr count
        }
    }

    # TTreeSelection
    #
    # Called when the ttree's selection has changed.

    method TTreeSelection {} {
        ::cond::simPP_predicate update \
            [list $caddbtn $editbtn $deletebtn $togglebtn \
                 $topbtn $raisebtn $lowerbtn $bottombtn]
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

    # TacticAdd
    #
    # Allows the user to pick a tactic from a pulldown, and
    # then pops up the related TACTIC:*:CREATE dialog.
    
    method TacticAdd {} {
        # FIRST, get a list of order names and titles
        set odict [dict create]

        foreach order [order names] {
            if {![string match "TACTIC:*:CREATE" $order]} {
                continue
            }

            # Get title, and remove the "Create Tactic: " prefix
            set title [order title $order]
            set ndx [string first ":" $title]
            set title [string range $title $ndx+2 end]
            dict set odict $title $order
        }

        set list [lsort [dict keys $odict]]

        # NEXT, let them pick one
        set title [messagebox pick \
                       -parent    [app topwin]      \
                       -initvalue [lindex $list 0]  \
                       -title     "Select a tactic" \
                       -values    $list             \
                       -message   [normalize "
                           Select a tactic to create for 
                           actor $info(actor).
                       "]]

        if {$title ne ""} {
            order enter [dict get $odict $title ] owner $info(actor)
        }
    }


    # TacticPriority prio
    #
    # prio    A token indicating the new priority.
    #
    # Sets the selected tactic's priority.

    method TacticPriority {prio} {
        # FIRST, there should be only one selected.
        set id [lindex [$ttree selection get] 0]

        # NEXT, get its tactic ID
        set tactic_id [$ttree item text $id {tag id}]

        # NEXT, Set its priority.
        order send gui TACTIC:PRIORITY tactic_id $tactic_id priority $prio
    }


    # TacticState
    #
    # Toggles the tactic's state from normal to disabled and back
    # again.

    method TacticState {} {
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

    # TacticDraw tdataVar
    #
    # tdataVar - Name of an array containing tactic attributes
    #
    # Adds/updates a tactic item in the ttree.

    method TacticDraw {tdataVar} {
        upvar $tdataVar tdata

        # FIRST, get the tactic item ID; if there is none,
        # create one.
        if {![info exists tactic2item($tdata(tactic_id))]} {
            set id [$ttree item create \
                        -parent root   \
                        -button auto   \
                        -tags   tactic]

            $ttree item collapse $id

            set tactic2item($tdata(tactic_id)) $id
        } else {
            set id $tactic2item($tdata(tactic_id))
        }

        # NEXT, get the execution timestamp
        if {$tdata(exec_ts) ne ""} {
            set timestamp [simclock toZulu $tdata(exec_ts)]
        } else {
            set timestamp ""
        }

        # NEXT, set the text.
        set tdict [array get tdata]

        $ttree item text $id                                  \
            0               $tdata(narrative)                 \
            {tag exec_ts}   $timestamp                        \
            {tag dollars}   [tactic call estdollars   $tdict] \
            {tag personnel} [tactic call estpersonnel $tdict] \
            {tag id}        $tdata(tactic_id)                 \
            {tag type}      $tdata(tactic_type)               \
            {tag priority}  $tdata(priority)

        # NEXT, set the state flags
        if {$tdata(state) eq "normal"} {
            $ttree item state set $id !overstrike
            $ttree item state set $id !error
        } elseif {$tdata(state) eq "disabled"} {
            $ttree item state set $id overstrike
            $ttree item state set $id !error
        } else {
            # invalid
            $ttree item state set $id overstrike
            $ttree item state set $id error
        }

        if {$tdata(exec_flag)} {
            $ttree item state set $id check
        } else {
            $ttree item state set $id !check
        }

        # NEXT, sort tactics by priority.
        $ttree item sort root -column {tag priority} -integer
    }

    # MonTactics update tactic_id
    #
    # tactic_id   - A tactic ID
    #
    # Displays/adds the tactic to the tactics tree.

    method {MonTactics update} {tactic_id} {
        # FIRST, we need to get the data about this tactic.
        # If it isn't for the currently displayed actor, we
        # can ignore it.
        array set tdata [tactic get $tactic_id]

        if {$tdata(owner) ne $info(actor)} {
            return
        }

        # NEXT, Display the tactic item
        $self TacticDraw tdata
        $self TTreeStripe
    }

    # MonTactics delete tactic_id
    #
    # tactic_id   - A tactic ID
    #
    # Deletes the tactic from the tactics tree.

    method {MonTactics delete} {tactic_id} {
        # FIRST, is this tactic displayed?
        if {![info exists tactic2item($tactic_id)]} {
            return
        }

        # NEXT, delete the item from the tree.
        $ttree item delete $tactic2item($tactic_id)
        unset tactic2item($tactic_id)
        $self TTreeStripe
    }

    # ConditionAdd
    #
    # Allows the user to pick a condition from a pulldown, and
    # then pops up the related CONDITION:*:CREATE dialog.
    
    method ConditionAdd {} {
        # FIRST, get a list of order names and titles
        set odict [dict create]

        foreach order [order names] {
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

        # NEXT, get the tactic_id
        set id    [lindex [$ttree selection get] 0]
        set otype [$ttree item text $id {tag type}]
        set oid   [$ttree item text $id {tag id}]

        if {"tactic" in [$ttree item tag names $id]} {
            set tactic_id $oid
        } else {
            set tactic_id [condition get $oid tactic_id]
        }

        # NEXT, let them pick one
        set title [messagebox pick \
                       -parent    [app topwin]      \
                       -initvalue [lindex $list 0]  \
                       -title     "Select a condition" \
                       -values    $list             \
                       -message   [normalize "
                           Select a condition to create for
                           actor $info(actor)'s tactic $tactic_id.
                       "]]

        if {$title ne ""} {
            order enter [dict get $odict $title ] tactic_id $tactic_id
        }
    }

    # ConditionDraw cdataVar
    #
    # cdataVar - Name of an array containing condition attributes
    #
    # Adds/updates a condition item in the ttree.

    method ConditionDraw {cdataVar} {
        upvar $cdataVar cdata

        # FIRST, get the parent item ID
        set parent $tactic2item($cdata(tactic_id))

        # NEXT, get the condition item ID; if there is none,
        # create one.
        if {![info exists condition2item($cdata(condition_id))]} {
            set id [$ttree item create     \
                        -parent $parent    \
                        -tags   condition]

            set condition2item($cdata(condition_id)) $id
        } else {
            set id $condition2item($cdata(condition_id))
        }

        # NEXT, set the text
        set cdict  [array get cdata]

        set flag [condition call eval $cdict $info(actor)]

        $ttree item text $id                       \
            0               $cdata(narrative)      \
            {tag dollars}   ""                     \
            {tag personnel} ""                     \
            {tag id}        $cdata(condition_id)   \
            {tag type}      $cdata(condition_type)

        # NEXT, set the state flags
        if {$cdata(state) eq "normal"} {
            $ttree item state set $id !overstrike
            $ttree item state set $id !error
        } elseif {$cdata(state) eq "disabled"} {
            $ttree item state set $id overstrike
            $ttree item state set $id !error
        } else {
            # invalid
            $ttree item state set $id overstrike
            $ttree item state set $id error
        }

        # NEXT, condition is true, false, or unknown
        if {$flag == 1} {
            $ttree item state set $id true
            $ttree item state set $id !false
        } elseif {$flag == 0} {
            $ttree item state set $id false
            $ttree item state set $id !true
        } else {
            $ttree item state set $id !false
            $ttree item state set $id !true
        }

        # NEXT, sort conditions by condition.
        $ttree item sort $parent -column {tag id} -integer
    }

    # MonConditions update condition_id
    #
    # condition_id   - A condition ID
    #
    # Displays/adds the condition to the conditions tree.

    method {MonConditions update} {condition_id} {
        # FIRST, we need to get the data about this condition.
        # If it isn't for a currently displayed tactic, we
        # can ignore it.
        array set cdata [condition get $condition_id]

        if {![info exists tactic2item($cdata(tactic_id))]} {
            return
        }

        # NEXT, Display the condition item
        $self ConditionDraw cdata
        $self TTreeStripe
    }

    # MonConditions delete condition_id
    #
    # condition_id   - A condition ID
    #
    # Deletes the condition from the conditions tree.

    method {MonConditions delete} {condition_id} {
        # FIRST, is this condition displayed?
        if {![info exists condition2item($condition_id)]} {
            return
        }

        # NEXT, delete the item from the tree.  NOTE: If 
        # a tactic is deleted, all of its conditions are deleted
        # as well; we might get this call *after* "MonTactics delete"
        # has already deleted the item.  So check.
        if {[$ttree item id $condition2item($condition_id)] ne ""} {
            $ttree item delete $condition2item($condition_id)
        }
        unset condition2item($condition_id)
        $self TTreeStripe
    }

    #-------------------------------------------------------------------
    # Reloading the Browser

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
        $self TTreeReload
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
    # Returns 1 if a valid (non-error) tactic is selected in the
    # TTree, and 0 otherwise.
    
    method {ttree validtactic} {} {
        if {[llength [$ttree selection get]] != 1} {
            return 0
        }

        set id [lindex [$ttree selection get] 0]
        
        if {"tactic" in [$ttree item tag names $id] &&
            ![$ttree item state get $id error]
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


