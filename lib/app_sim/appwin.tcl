#-----------------------------------------------------------------------
# TITLE:
#    appwin.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Main application window
#
#    This window is implemented as snit::widget; however, it's set up
#    to exit the program when it's closed, just like ".".  It's expected
#    that "." will be withdrawn at start-up.
#
#    Because this is an application window, it can make use of
#    application-wide resources, such as the RDB.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appwin

snit::widget appwin {
    hulltype toplevel

    #-------------------------------------------------------------------
    # Lookup Variables

    # Dictionary of duration values by label strings 
    # for the durations pulldown
    typevariable durations {
        "Until paused"  ""
        "1 days"         1
        "2 days"         2
        "3 days"         3
        "4 days"         4
        "5 days"         5
        "10 days"       10
        "15 days"       15
        "20 days"       20
        "25 days"       25
        "30 days"       30
        "45 days"       45
        "60 days"       60
        "75 days"       75
        "90 days"       90
    }

    #-------------------------------------------------------------------
    # Components

    component editmenu              ;# The Edit menu
    component cli                   ;# The cli(n) pane
    component msgline               ;# The messageline(n)
    component content               ;# The content notebook
    component viewer -public viewer ;# The mapviewer(n)
    component slog                  ;# The scrolling log
 
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -main flag
    #
    # If "yes", this is the main application window.  Otherwise,
    # this is just a browser window. This may affect the components, 
    # the menus, and so forth.
    
    option -main      \
        -default  no  \
        -readonly yes

    #-------------------------------------------------------------------
    # Instance variables

    # Dictionary of tabs to be created.
    #
    #    label     The tab text
    #
    #    parent    The tag of the parent tab, or "" if this is a top-level
    #              tab.
    #
    #    script    Widget command (and options) to create the tab.
    #              "%W" is replaced with the name of the widget contained
    #              in the new tab.  For tabs containing notebooks, the
    #              script is "".
    #
    #    tabwin    Once the tab is created, its window.

    variable tabs {
        viewer {
            label "Map"
            parent ""
            script { mapviewer %W -width 600 -height 600 }
        }

        plant {
            label "Plan"
            parent ""
            script ""
        }

        planforce {
            label "Force Levels"
            parent plant
            script { planforcebrowser %W }
        }

        schedule {
            label "Schedule"
            parent plant
            script { schedulebrowser %W }
        }

        units {
            label   "Units"
            parent  ""
            script  { unitbrowser %W }
        }

        nbhoodst {
            label   "Neighborhoods"
            parent  ""
            script  ""
        }

        nbhoods {
            label   "Neighborhoods"
            parent  nbhoodst
            script  { nbhoodbrowser %W }
        }

        nbrel {
            label   "Relationships"
            parent  nbhoodst
            script  { nbrelbrowser %W }
        }

        security {
            label   "Security"
            parent  nbhoodst
            script  { securitybrowser %W }
        }

        activity {
            label   "Activity"
            parent  nbhoodst
            script  { activitybrowser %W }
        }

        actsit {
            label   "ActSits"
            parent  nbhoodst
            script  { actsitbrowser %W }
        }

        demsit {
            label   "DemSits"
            parent  nbhoodst
            script  { demsitbrowser %W }
        }

        ensit {
            label   "EnSits"
            parent  nbhoodst
            script  { ensitbrowser %W }
        }

        groupst {
            label   "Groups"
            parent  ""
            script  ""
        }

        civgroups {
            label   "CivGroups"
            parent  groupst
            script  { civgroupbrowser %W }
        }

        frcgroups {
            label   "FrcGroups"
            parent  groupst
            script  { frcgroupbrowser %W }
        }

        orggroups {
            label   "OrgGroups"
            parent  groupst
            script  { orggroupbrowser %W }
        }

        rel {
            label   "Relationships"
            parent  groupst
            script  { relbrowser %W }
        }

        personnel {
            label   "Personnel"
            parent  groupst
            script  { personnelbrowser %W }
        }

        roet {
            label  "ROE"
            parent ""
            script ""
        }

        attroeuf {
            label  "Attack (Uniformed)"
            parent roet
            script { attroeufbrowser %W }
        }

        attroenf {
            label  "Attack (Non-Uniformed)"
            parent roet
            script { attroenfbrowser %W }
        }

        defroe {
            label  "Defend"
            parent roet
            script { defroebrowser %W }
        }

        demogt {
            label "Demog"
            parent ""
            script ""
        }

        demogg {
            label  "Groups"
            parent "demogt"
            script { demogbrowser %W }
        }

        demogn {
            label  "Nbhoods"
            parent "demogt"
            script { demognbrowser %W }
        }

        econt {
            label  "Econ"
            parent ""
            script ""
        }

        econov {
            label  "Overview"
            parent "econt"
            script { econsheet %W }
        }

        econcap {
            label  "Capacity"
            parent "econt"
            script { econcapbrowser %W }
        }

        econpop {
            label  "Population"
            parent "econt"
            script { econpopbrowser %W }
        }

        econng {
            label  "Nbgroups"
            parent "econt"
            script { econngbrowser %W }
        }

        gramt {
            label  "Attitudes"
            parent ""
            script ""
        }

        sat {
            label "Satisfaction"
            parent gramt
            script { satbrowser %W }
        }

        coop {
            label "Cooperation"
            parent gramt
            script { coopbrowser %W }
        }

        nbcoop {
            label "NbhoodCoop"
            parent gramt
            script { nbcoopbrowser %W }
        }

        mads {
            label "Magic Attitude Drivers"
            parent gramt
            script {madbrowser %W}
        }

        orderst {
            label "Orders"
            parent ""
            script ""
        }

        ordsched {
            label  "Scheduled"
            parent orderst
            script { 
                orderbrowser %W
            }
        }

        ordhist {
            label  "Sent"
            parent orderst
            script { 
                ordersentbrowser %W
            }
        }

        plot {
            label  "Plots"
            parent ""
            script { 
                plotviewer %W
            }
        }

        report {
            label  "Reports"
            parent ""
            script { 
                reportbrowser %W -db ::rdb
                %W refresh
            }
        }

        slog {
            label  "Log"
            parent ""
            script {
                scrollinglog %W \
                    -relief        flat                \
                    -height        30                  \
                    -logcmd        [mymethod puts]     \
                    -loglevel      "normal"            \
                    -showloglist   yes                 \
                    -rootdir       [workdir join log]  \
                    -defaultappdir app_sim             \
                    -format        {
                        {zulu  12 yes}
                        {v      7 yes}
                        {c      9 yes}
                        {m      0 yes}
                    }
            }
        }
    }


    # Status info
    #
    # simspeed    Current simulation speed
    # simstate    Current simulation state
    # tick        Current sim time as a four-digit tick
    # zulutime    Current sim time as a zulu time string
    # dayofweek   Day of week (edayname value)      

    variable info -array {
        simspeed  5
        simstate  ""
        tick      "0000"
        zulutime  ""
        dayofweek "??"
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options
        $self configurelist $args

        # NEXT, set the default window title
        wm title $win "Untitled - Athena [version]"

        # NEXT, Exit the app when this window is closed, if it's a 
        # main window.
        if {$options(-main)} {
            wm protocol $win WM_DELETE_WINDOW [mymethod FileExit]
        }

        # NEXT, Allow the developer to pop up the debugger.
        bind $win <Control-F12> [list debugger new]

        # NEXT, Create the major window components
        $self CreateMenuBar
        $self CreateComponents

        # NEXT, Allow the created widget sizes to propagate to
        # $win, so the window gets its default size; then turn off 
        # propagation.  From here on out, the user is in control of the 
        # size of the window.

        update idletasks
        grid propagate $win off

        # NEXT, Prepare to receive notifier events.
        notifier bind ::sim      <DbSyncB>       $self [mymethod DbSync]
        notifier bind ::scenario <ScenarioSaved> $self [mymethod DbSync]
        notifier bind ::sim      <State>         $self [mymethod SimState]
        notifier bind ::sim      <Time>          $self [mymethod SimTime]
        notifier bind ::sim      <Speed>         $self [mymethod SimSpeed]

        if {$options(-main)} {
            notifier bind ::app <Prefs> $self [mymethod AppPrefs]
        }

        # NEXT, Prepare to receive window events
        bind $content <<NotebookTabChanged>> [mymethod DbSync]

        bind $viewer <<Unit-1>>       [mymethod Unit-1   %d]
        bind $viewer <<Ensit-1>>      [mymethod Ensit-1  %d]
        bind $viewer <<Nbhood-1>>     [mymethod Nbhood-1 %d]

        # NEXT, prepare to append pucked points, etc., to the CLI
        if {$options(-main)} {
            bind $viewer <<Point-1>>      [mymethod Point-1      %d]
            bind $viewer <<PolyComplete>> [mymethod PolyComplete %d]
        }

        # NEXT, Sync with RDB on creation
        $self DbSync
    }

    destructor {
        notifier forget $self
    }

    # CreateMenuBar
    #
    # Creates the main menu bar

    method CreateMenuBar {} {
        # Menu Bar
        set menubar [menu $win.menubar -relief flat]
        $win configure -menu $menubar
        
        # File Menu
        set mnu [menu $menubar.file]
        $menubar add cascade -label "File" -underline 0 -menu $mnu

        $mnu add command                  \
            -label       "New Browser"         \
            -underline   4                     \
            -accelerator "Ctrl+N"              \
            -command     [list appwin new]
        bind $win <Control-n> [list appwin new]
        bind $win <Control-N> [list appwin new]
        
        cond::simNotRunning control \
            [menuitem $mnu command "New Scenario..."  \
                 -underline 0                         \
                 -command   [mymethod FileNew]]

        cond::simNotRunning control \
            [menuitem $mnu command "Open Scenario..." \
                 -underline 0                         \
                 -command   [mymethod FileOpen]]

        $mnu add command                  \
            -label       "Save Scenario"       \
            -underline   0                     \
            -accelerator "Ctrl+S"              \
            -command     [mymethod FileSave]
        bind $win <Control-s> [mymethod FileSave]
        bind $win <Control-S> [mymethod FileSave]

        $mnu add command                       \
            -label     "Save Scenario As..."   \
            -underline 14                      \
            -command   [mymethod FileSaveAs]

        cond::simIsPrep control \
            [menuitem $mnu command "Export As XML..."        \
                 -underline 0                                \
                 -command   [mymethod FileExportAsXml]]

        if {$options(-main)} {
            $mnu add command                               \
                -label     "Save CLI Scrollback Buffer..." \
                -underline 5                               \
                -command   [mymethod FileSaveCLI]
        }

        $mnu add separator

        cond::orderIsValid control                  \
            [menuitem $mnu command "Import Map..."    \
                 -underline 4                         \
                 -command   [mymethod FileImportMap]] \
            order MAP:IMPORT

        $mnu add separator

        set submenu [menu $mnu.parm]
        $mnu add cascade -label "Parameters" \
            -underline 0 -menu $submenu

        cond::orderIsValid control                           \
            [menuitem $submenu command "Import..."           \
                 -underline 0                                \
                 -command   [mymethod FileParametersImport]] \
            order PARM:IMPORT

        $submenu add command \
            -label     "Export..."                     \
            -underline 0                               \
            -command   [mymethod FileParametersExport]
        
        $submenu add command \
            -label     "Save as Default..."                   \
            -underline 0                                      \
            -command   [mymethod FileParametersSaveAsDefault]
        
        $submenu add command \
            -label     "Clear Defaults..."                    \
            -underline 0                                      \
            -command   [mymethod FileParametersClearDefaults]

        $mnu add separator

        if {$options(-main)} {
            $mnu add command                  \
                -label       "Exit"                \
                -underline   1                     \
                -accelerator "Ctrl+Q"              \
                -command     [mymethod FileExit]
            bind $win <Control-q> [mymethod FileExit]
            bind $win <Control-Q> [mymethod FileExit]
        } else {
            $mnu add command                  \
                -label       "Close Window"        \
                -underline   6                     \
                -accelerator "Ctrl+W"              \
                -command     [list destroy $win]
            bind $win <Control-w> [list destroy $win]
            bind $win <Control-W> [list destroy $win]
        }

        # Edit menu
        set editmenu [menu $menubar.edit \
                          -postcommand [mymethod PostEditMenu]]
        $menubar add cascade -label "Edit" -underline 0 -menu $editmenu

        $editmenu add command                \
            -label       "Undo"              \
            -underline   0                   \
            -accelerator "Ctrl+Z"            \
            -command     [mymethod EditUndo]

        bind $win <Control-z> [mymethod EditUndo]
        bind $win <Control-Z> [mymethod EditUndo]

        $editmenu add command                \
            -label       "Redo"              \
            -underline   0                   \
            -accelerator "Ctrl+Shift+Z"      \
            -command     [mymethod EditRedo]

        bind $win <Shift-Control-z> [mymethod EditRedo]
        bind $win <Shift-Control-Z> [mymethod EditRedo]

        $editmenu add separator
        
        $editmenu add command \
            -label "Cut" \
            -underline 2 \
            -accelerator "Ctrl+X" \
            -command {event generate [focus] <<Cut>>}

        $editmenu add command \
            -label "Copy" \
            -underline 0 \
            -accelerator "Ctrl+C" \
            -command {event generate [focus] <<Copy>>}
        
        $editmenu add command \
            -label "Paste" \
            -underline 0 \
            -accelerator "Ctrl+V" \
            -command {event generate [focus] <<Paste>>}
        
        $editmenu add separator
        
        $editmenu add command \
            -label "Select All" \
            -underline 7 \
            -accelerator "Ctrl+Shift+A" \
            -command {event generate [focus] <<SelectAll>>}

        # View menu
        set viewmenu [menu $menubar.view]
        $menubar add cascade -label "View" -underline 0 -menu $viewmenu

        $self AddTabMenuItems $viewmenu

        # Orders menu
        set ordersmenu [menu $menubar.orders]
        $menubar add cascade -label "Orders" -underline 0 -menu $ordersmenu

        # Orders/Simulation
        set submenu [menu $ordersmenu.sim]
        $ordersmenu add cascade -label "Simulation" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu SIM:STARTDATE

        # Orders/Personnel
        set submenu [menu $ordersmenu.personnel]
        $ordersmenu add cascade -label "Personnel" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu PERSONNEL:SET
        $self AddOrder $submenu PERSONNEL:ADJUST

        # Orders/Activity
        set submenu [menu $ordersmenu.activity]
        $ordersmenu add cascade -label "Activity" \
            -underline 4 -menu $submenu
        
        $self AddOrder $submenu ACTIVITY:SCHEDULE
        $self AddOrder $submenu ACTIVITY:UPDATE
        $self AddOrder $submenu ACTIVITY:CANCEL

        # Orders/Unit
        set submenu [menu $ordersmenu.unit]
        $ordersmenu add cascade -label "Unit" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu UNIT:MOVE
        $self AddOrder $submenu ATTRIT:UNIT

        # Orders/Attrition
        set submenu [menu $ordersmenu.attrit]
        $ordersmenu add cascade -label "Attrition" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu ATTRIT:NBHOOD
        $self AddOrder $submenu ATTRIT:GROUP
        $self AddOrder $submenu ATTRIT:UNIT

        # Orders/ROE
        set submenu [menu $ordersmenu.roe]
        $ordersmenu add cascade -label "ROE" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu ROE:DEFEND:UPDATE
        $self AddOrder $submenu ROE:ATTACK:UNIFORMED:CREATE
        $self AddOrder $submenu ROE:ATTACK:NONUNIFORMED:CREATE
        $self AddOrder $submenu ROE:ATTACK:UNIFORMED:UPDATE
        $self AddOrder $submenu ROE:ATTACK:NONUNIFORMED:UPDATE
        $self AddOrder $submenu ROE:ATTACK:DELETE

        # Orders/Situation
        set submenu [menu $ordersmenu.sit]
        $ordersmenu add cascade -label "Situation" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu SITUATION:ENVIRONMENTAL:CREATE
        $self AddOrder $submenu SITUATION:ENVIRONMENTAL:MOVE
        $self AddOrder $submenu SITUATION:ENVIRONMENTAL:DELETE
        $self AddOrder $submenu SITUATION:ENVIRONMENTAL:RESOLVE
        $self AddOrder $submenu SITUATION:ENVIRONMENTAL:UPDATE

        # Orders/Magic Attitude Drivers
        set submenu [menu $ordersmenu.mad]
        $ordersmenu add cascade -label "Magic Attitude Driver" \
            -underline 0 -menu $submenu

        $self AddOrder $submenu MAD:CREATE
        $self AddOrder $submenu MAD:UPDATE
        $self AddOrder $submenu MAD:DELETE
        $self AddOrder $submenu MAD:TERMINATE
        $self AddOrder $submenu MAD:COOP:ADJUST
        $self AddOrder $submenu MAD:COOP:SET
        $self AddOrder $submenu MAD:COOP:LEVEL
        $self AddOrder $submenu MAD:COOP:SLOPE
        $self AddOrder $submenu MAD:SAT:ADJUST
        $self AddOrder $submenu MAD:SAT:SET
        $self AddOrder $submenu MAD:SAT:LEVEL
        $self AddOrder $submenu MAD:SAT:SLOPE

        # Orders/Civilian Group
        set submenu [menu $ordersmenu.civgroup]
        $ordersmenu add cascade -label "Civilian Group" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu GROUP:CIVILIAN:CREATE
        $self AddOrder $submenu GROUP:CIVILIAN:UPDATE
        $self AddOrder $submenu GROUP:CIVILIAN:UPDATE:POSTPREP
        $self AddOrder $submenu GROUP:CIVILIAN:DELETE

        # Orders/Force Group
        set submenu [menu $ordersmenu.frcgroup]
        $ordersmenu add cascade -label "Force Group" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu GROUP:FORCE:CREATE
        $self AddOrder $submenu GROUP:FORCE:UPDATE
        $self AddOrder $submenu GROUP:FORCE:DELETE

        # Orders/Org Group
        set submenu [menu $ordersmenu.orggroup]
        $ordersmenu add cascade -label "Org Group" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu GROUP:ORGANIZATION:CREATE
        $self AddOrder $submenu GROUP:ORGANIZATION:UPDATE
        $self AddOrder $submenu GROUP:ORGANIZATION:DELETE

        # Orders/Neighborhood Menu
        set submenu [menu $ordersmenu.nbhood]
        $ordersmenu add cascade -label "Neighborhood" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu NBHOOD:CREATE
        $self AddOrder $submenu NBHOOD:UPDATE
        $self AddOrder $submenu NBHOOD:LOWER
        $self AddOrder $submenu NBHOOD:RAISE
        $self AddOrder $submenu NBHOOD:DELETE
        $self AddOrder $submenu NBHOOD:RELATIONSHIP:UPDATE

        # Orders/Relationship Menu
        set submenu [menu $ordersmenu.rel]
        $ordersmenu add cascade -label "Relationship" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu RELATIONSHIP:UPDATE

        # Orders/Cooperation Menu
        set submenu [menu $ordersmenu.coop]
        $ordersmenu add cascade -label "Cooperation" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu COOP:UPDATE
        $self AddOrder $submenu MAD:COOP:ADJUST
        $self AddOrder $submenu MAD:COOP:SET
        $self AddOrder $submenu MAD:COOP:LEVEL
        $self AddOrder $submenu MAD:COOP:SLOPE

        # Orders/Satisfaction Menu
        set submenu [menu $ordersmenu.sat]
        $ordersmenu add cascade -label "Satisfaction" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu SAT:UPDATE
        $self AddOrder $submenu MAD:SAT:ADJUST
        $self AddOrder $submenu MAD:SAT:SET
        $self AddOrder $submenu MAD:SAT:LEVEL
        $self AddOrder $submenu MAD:SAT:SLOPE

        # Orders/Economics Menu
        set submenu [menu $ordersmenu.econ]
        $ordersmenu add cascade -label "Economics" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu ECON:UPDATE

        # Reports menu
        set reportsmenu [menu $menubar.reports]
        $menubar add cascade -label "Reports" -underline 0 -menu $reportsmenu

        $self AddOrder $reportsmenu REPORT:DRIVER
        $self AddOrder $reportsmenu REPORT:SATISFACTION:CIVILIAN
        $self AddOrder $reportsmenu REPORT:SATISFACTION:CONTRIB
        $self AddOrder $reportsmenu REPORT:COOPERATION
        $self AddOrder $reportsmenu REPORT:PARMDB

        $reportsmenu add separator

        $reportsmenu add command \
            -label     "Save Hot List to Disk..." \
            -underline 0                          \
            -command   [list report hotlist save]

        $reportsmenu add command \
            -label     "Clear Hot List..." \
            -underline 0                          \
            -command   [list report hotlist clear]

        # Help menu
        set helpmenu [menu $menubar.helpmenu]
        $menubar add cascade -label "Help" -underline 0 -menu $helpmenu

        $helpmenu add command                \
            -label       "Help Contents"     \
            -underline   0                   \
            -accelerator "F1"                \
            -command     [list app help]

        bind $win <F1> [list app help]

        $helpmenu add command                    \
            -label       "Application Menus"     \
            -underline   0                       \
            -command     [list app help menu]

        $helpmenu add command                    \
            -label       "Application Tabs"      \
            -underline   0                       \
            -command     [list app help tabs]

        $helpmenu add command                    \
            -label       "Orders"                \
            -underline   0                       \
            -command     [list app help orders]

        $helpmenu add command                    \
            -label       "Reports"               \
            -underline   0                       \
            -command     [list app help reports]

        $helpmenu add command                    \
            -label       "Display Variables"     \
            -underline   0                       \
            -command     [list app help vars]

        $helpmenu add command                    \
            -label       "Executive Commands"    \
            -underline   0                       \
            -command     [list app help cmd]

        $helpmenu add command                    \
            -label       "Model Parameters"      \
            -underline   0                       \
            -command     [list app help parmdb]

        $helpmenu add separator

        $helpmenu add command                    \
            -label       "Release Notes"         \
            -underline   0                       \
            -command     [list app help release]

        $helpmenu add command                    \
            -label       "About Athena"          \
            -underline   0                       \
            -command     [list app help about]

    }

    # AddOrder mnu order
    #
    # mnu    A pull-down menu
    # order  An order name
    #
    # Adds a menu item for the order

    method AddOrder {mnu order} {
        cond::orderIsValid control \
            [menuitem $mnu command [order title $order]... \
                 -command [list order enter $order]]    \
            order $order
    }

    # CreateComponents
    #
    # Creates the main window's components

    method CreateComponents {} {
        # FIRST, prepare the grid.  The scrolling log/shell paner
        # should stretch vertically on resize; the others shouldn't.
        # And everything should stretch horizontally.

        grid rowconfigure $win 0 -weight 0    ;# Separator
        grid rowconfigure $win 1 -weight 0    ;# Tool Bar
        grid rowconfigure $win 2 -weight 0    ;# Separator
        grid rowconfigure $win 3 -weight 1    ;# Content
        grid rowconfigure $win 4 -weight 0    ;# Separator
        grid rowconfigure $win 5 -weight 0    ;# Status line

        grid columnconfigure $win 0 -weight 1

        # NEXT, put in the row widgets

        # ROW 0, add a separator between the menu bar and the rest of the
        # window.
        ttk::separator $win.sep0

        # ROW 1, add a simulation toolbar
        ttk::frame $win.toolbar

        # Prep Lock/Unlock
        ttk::button $win.toolbar.preplock            \
            -style    Toolbutton                     \
            -image    ::projectgui::icon::unlocked22 \
            -command  [mymethod PrepLock]

        # RunPause
        ttk::button $win.toolbar.runpause       \
            -style   Toolbutton                 \
            -image   ::projectgui::icon::play22 \
            -command [mymethod RunPause]

        # Duration

        menubox $win.toolbar.duration         \
            -justify   left                   \
            -width     10                     \
            -takefocus 0                      \
            -values    [dict keys $durations]

        $win.toolbar.duration set [lindex [dict keys $durations] 1]

        DynamicHelp::add $win.toolbar.duration -text "Duration of run"

        # Simulation Speed
        ttk::label $win.toolbar.slower \
            -text "Slower"

        ttk::scale $win.toolbar.speed        \
            -from     1                      \
            -to       10                     \
            -length   60                     \
            -orient   horizontal             \
            -value    5                      \
            -variable [myvar info(simspeed)] \
            -command  [mymethod SetSpeed]

        DynamicHelp::add $win.toolbar.speed -text "Simulation Speed"

        ttk::label $win.toolbar.faster \
            -text "Faster"

        # First Snapshot
        $self AddToolbarButton first first16 "Time 0 Snapshot" \
            [list ::sim snapshot first]

        # Previous Snapshot
        $self AddToolbarButton prev prev16 "Previous Snapshot" \
            [list ::sim snapshot prev]

        # Next Snapshot
        $self AddToolbarButton next next16 "Next Snapshot" \
            [list ::sim snapshot next]

        # Latest Snapshot
        $self AddToolbarButton last last16 "Latest Snapshot" \
            [list ::sim snapshot last]

        # Sim State
        ttk::label $win.toolbar.state                  \
            -text "State:"

        ttk::label $win.toolbar.simstate               \
            -font               codefont               \
            -width              26                     \
            -anchor             w                      \
            -textvariable       [myvar info(simstate)]

        # Zulu time
        ttk::label $win.toolbar.time                   \
            -text "Time:"

        ttk::label $win.toolbar.zulutime               \
            -font               codefont               \
            -width              12                     \
            -textvariable       [myvar info(zulutime)]

        ttk::label $win.toolbar.dayofweek              \
            -font               codefont               \
            -width              4                      \
            -textvariable       [myvar info(dayofweek)]

        # Tick
        ttk::label $win.toolbar.ticklab                \
            -text "Tick:"

        ttk::label $win.toolbar.tick                   \
            -font               codefont               \
            -width              4                      \
            -textvariable       [myvar info(tick)]

        pack $win.toolbar.preplock  -side left
        pack $win.toolbar.runpause  -side left    
        pack $win.toolbar.duration  -side left -padx {0 15}
        pack $win.toolbar.slower    -side left
        pack $win.toolbar.speed     -side left -padx 2
        pack $win.toolbar.faster    -side left -padx {0 15}
        pack $win.toolbar.first     -side left
        pack $win.toolbar.prev      -side left
        pack $win.toolbar.next      -side left
        pack $win.toolbar.last      -side left
        pack $win.toolbar.tick      -side right -padx 2 
        pack $win.toolbar.ticklab   -side right
        pack $win.toolbar.dayofweek -side right -padx 2 
        pack $win.toolbar.zulutime  -side right -padx 2 
        pack $win.toolbar.time      -side right
        pack $win.toolbar.simstate  -side right -padx 2 
        pack $win.toolbar.state     -side right -padx {15 0}

        # ROW 2, add a separator between the tool bar and the content
        # window.
        ttk::separator $win.sep2

        # ROW 3, create the content widgets.  If this is a main window,
        # then we have a paner containing the content notebook with 
        # a CLI underneath.  Otherwise, we get just the content
        # notebook.
        if {$options(-main)} {
            ttk::panedwindow $win.paner -orient vertical

            install content using ttk::notebook $win.paner.content \
                -padding 2 

            $win.paner add $content \
                -weight 1
            set row3 $win.paner
        } else {
            install content using ttk::notebook $win.content \
                -padding 2 

            set row3 $win.content
        }

        # ROW 4, add a separator
        ttk::separator $win.sep4

        # ROW 5, Create the Status Line frame.
        ttk::frame $win.status    \
            -borderwidth        2 

        # Message line
        install msgline using messageline $win.status.msgline

        pack $win.status.msgline -fill both -expand yes


        # NEXT, add the content tabs, and save relevant tabs
        # as components.  Also, finish configuring the tabs.
        $self AddTabs

        # Viewer
        set viewer [$self tab win viewer]

        # Report browser
        notifier bind ::report <Report> $self [mymethod ReportCB]
        notifier bind ::report <Update> $self [mymethod ReportUpdateCB] 

        # Scrolling log
        set slog   [$self tab win slog]
        $slog load [log cget -logfile]
        notifier bind ::app <AppLogNew> $self [list $slog load]

        # NEXT, add the CLI to the paner, if needed.
        if {$options(-main)} {
            install cli using cli $win.paner.cli    \
                -height    8                        \
                -relief    flat                     \
                -maxlines  [prefs get cli.maxlines] \
                -promptcmd [mymethod CliPrompt]     \
                -evalcmd   [list ::executive eval]
            
            $win.paner add $win.paner.cli

            # Load the CLI command history
            $self LoadCliHistory

            # Register the CLI, so that history is saved in the 
            # scenario file.
            # scenario register [list $cli saveable]
        }

        # NEXT, manage all of the components.
        grid $win.sep0     -sticky ew
        grid $win.toolbar  -sticky ew
        grid $win.sep2     -sticky ew
        grid $row3         -sticky nsew
        grid $win.sep4     -sticky ew
        grid $win.status   -sticky ew
    }

    # CliPrompt
    #
    # Returns a prompt string for the CLI

    method CliPrompt {} {
        if {[executive usermode] eq "super"} {
            return "super>"
        } else {
            return ">"
        }
    }

    # AddToolbarButton name icon tooltip command
    #
    # Creates a toolbar button with standard style

    method AddToolbarButton {name icon tooltip command} {
        ttk::button $win.toolbar.$name \
            -style   Toolbutton        \
            -state   normal            \
            -command $command          \
            -image   [list ::projectgui::icon::$icon \
                          disabled ::projectgui::icon::${icon}d]

        DynamicHelp::add $win.toolbar.$name -text $tooltip
    }

    #-------------------------------------------------------------------
    # Tab Management

    # AddTabs
    #
    # Adds all of the content tabs and subtabs to the window.

    method AddTabs {} {
        # FIRST, add each tab
        foreach tab [dict keys $tabs] {
            # Add a "tabwin" key to the 
            dict set tabs $tab tabwin ""

            # Create the tab
            dict with tabs $tab {
                # FIRST, get the parent
                if {$parent eq ""} {
                    set p $content
                } else {
                    set p [dict get $tabs $parent tabwin]
                }

                # NEXT, get the new tabwin name
                set tabwin $p.$tab

                # NEXT, create the new tab widget
                if {$script eq ""} {
                    ttk::notebook $tabwin -padding 2
                } else {
                    eval [string map [list %W $tabwin] $script]
                }

                # NEXT, add it to the parent notebook
                $p add $tabwin      \
                    -sticky  nsew   \
                    -padding 2      \
                    -text    $label
            }
        }
    }

    # AddTabMenuItems mnu
    #
    # mnu     The View menu
    #
    # Adds tabs to pop up the tabs to the View menu

    method AddTabMenuItems {mnu} {
        # FIRST, save the parent menu for toplevel tabs
        set pmenu() $mnu

        # FIRST, add each tab
        foreach tab [dict keys $tabs] {
            dict with tabs $tab {
                # FIRST, if this is a leaf tab just add its item.
                if {$script ne ""} {
                    $pmenu($parent) add command \
                        -label $label           \
                        -command [mymethod tab view $tab]
                    continue
                }

                # NEXT, this tab has subtabs.  Create a new menu
                set pmenu($tab) [menu $pmenu($parent).$tab]

                $pmenu($parent) add cascade \
                    -label $label \
                    -menu  $pmenu($tab)
            }
        }
    }

    # tab win tab
    #
    # Returns the window name of the specified tab
    
    method {tab win} {tab} {
        dict get $tabs $tab tabwin
    }

    # tab view tab
    #
    # Makes the window display the specified tab

    method {tab view} {tab} {
        dict with tabs $tab {
            if {$parent eq ""} {
                $content select $tabwin
            } else {
                set pwin [dict get $tabs $parent tabwin]

                $content select $pwin
                $pwin select $tabwin
            }
        }
    }
    
   
    #-------------------------------------------------------------------
    # CLI history

    # SaveCliHistory
    #
    # If there's a CLI, saves its command history to 
    # ~/.athena/history.cli.

    method savehistory {} {
        assert {$cli ne ""}

        set f [open ~/.athena/history.cli w]

        puts $f [$cli saveable checkpoint]
        
        close $f
    }

    # LoadCliHistory
    #
    # If there's a CLI, and a history file, read its command history.

    method LoadCliHistory {} {
        if {[file exists ~/.athena/history.cli]} {
            $cli saveable restore [readfile ~/.athena/history.cli]
        }
    }


    #-------------------------------------------------------------------
    # File Menu Handlers

    # FileNew
    #
    # Prompts the user to create a brand new scenario.

    method FileNew {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, create the new scenario
        scenario new
    }

    # FileOpen
    #
    # Prompts the user to open a scenario in a particular file.

    method FileOpen {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, query for the scenario file name.
        set filename [tk_getOpenFile                      \
                          -parent $win                    \
                          -title "Open Scenario"          \
                          -filetypes {
                              {{Athena Scenario}     {.adb} }
                              {{Athena Scenario XML} {.xml} }
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, Open the requested scenario.
        scenario open $filename
    }

    # FileSaveAs
    #
    # Prompts the user to save the scenario as a particular file.

    method FileSaveAs {} {
        # FIRST, query for the scenario file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                       \
                          -parent $win                     \
                          -title "Save Scenario As"        \
                          -filetypes {
                              {{Athena Scenario} {.adb} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the scenario using this name
        return [scenario save $filename]
    }

    # FileExportAsXml
    #
    # Prompts the user to save the scenario as an XML file.

    method FileExportAsXml {} {
        # FIRST, query for the XML file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                         \
                          -parent $win                       \
                          -title "Export Scenario As"        \
                          -filetypes {
                              {{Athena Scenario XML} {.xml} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Export the scenario using this name
        return [scenario export $filename]
    }

    # FileSave
    #
    # Saves the scenario to the current file, making a backup
    # copy.  Returns 1 on success and 0 on failure.

    method FileSave {} {
        # FIRST, if no file name is known, do a SaveAs.
        if {[scenario dbfile] eq ""} {
            return [$self FileSaveAs]
        }

        # NEXT, Save the scenario to the current file.
        return [scenario save]
    }

    # FileSaveCLI
    #
    # Prompts the user to save the CLI scrollback buffer to disk
    # as a text file.
    #
    # TBD: This has become a standard pattern (catch, try/finally,
    # logging errors, etc).  Consider packaging it up as a standard
    # save file mechanism.

    method FileSaveCLI {} {
        # FIRST, query for the file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                                   \
                          -parent      $win                            \
                          -title       "Save CLI Scrollback Buffer As" \
                          -initialfile "cli.txt"                       \
                          -filetypes   {
                              {{Text File} {.txt} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the CLI using this name
        if {[catch {
            try {
                set f [open $filename w]
                puts $f [$cli get 1.0 end]
            } finally {
                close $f
            }
        } result opts]} {
            log warning app "Could not save CLI buffer: $result"
            log error app [dict get $opts -errorinfo]
            app error {
                |<--
                Could not save the CLI buffer to
                
                    $filename

                $result
            }
            return
        }

        log normal scenario "Saved CLI Buffer to: $filename"

        app puts "Saved CLI Buffer to [file tail $filename]"

        return
    }


    # FileImportMap
    #
    # Asks the user to select a map file for import.

    method FileImportMap {} {
        # FIRST, query for a map file.
        set filename [tk_getOpenFile                  \
                          -parent $win                \
                          -title "Select a map image" \
                          -filetypes {
                              {{JPEG Images} {.jpg} }
                              {{GIF Images}  {.gif} }
                              {{PNG Images}  {.png} }
                              {{Any File}    *      }
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, Import the map
        if {[catch {
            order send gui MAP:IMPORT [list filename $filename]
        } result]} {
            app error {
                |<--
                Import failed: $result

                $filename
            }
        }
    }


    # FileParametersImport
    #
    # Imports model parameters from a .parmdb file

    method FileParametersImport {} {
        # FIRST, query for a parameters file.
        set filename [tk_getOpenFile                  \
                          -parent $win                \
                          -title "Select a parameters file" \
                          -filetypes {
                              {{Model Parameters} {.parmdb} }
                              {{Any File}         *         }
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, Import the map
        if {[catch {
            order send gui PARM:IMPORT [list filename $filename]
        } result]} {
            app error {
                |<--
                Import failed: $result

                $filename
            }
        }
    }

    # FileParametersExport
    #
    # Exports model parameters to a .parmdb file

    method FileParametersExport {} {
        # FIRST, query for the file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                       \
                          -parent $win                     \
                          -title "Export Parameters As"        \
                          -filetypes {
                              {{Model Parameters} {.parmdb} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the scenario using this name
        return [parm save $filename]
    }


    # FileParametersSaveAsDefault
    #
    # Saves the current model parameters to a default parameter file.

    method FileParametersSaveAsDefault {} {
        set message [normalize {
            Save the current model parameter settings as the
            default for new scenarios?
        }]

        set answer [messagebox popup                \
                        -icon    question           \
                        -message $message           \
                        -parent  $win               \
                        -title   "Athena [version]" \
                        -buttons {
                            ok      "Save"
                            cancel  "Cancel"
                        }]

        if {$answer eq "ok"} {
            parm defaults save
        }
    }

    # FileParametersClearDefaults
    #
    # Deletes any default parameter file.

    method FileParametersClearDefaults {} {
        set message [normalize {
            Clear the default model parameter settings for new
            scenarios to their original values?  (This will
            have no effect on the current scenario.)
        }]

        set answer [messagebox popup                \
                        -icon    question           \
                        -message $message           \
                        -parent  $win               \
                        -title   "Athena [version]" \
                        -buttons {
                            ok      "Clear"
                            cancel  "Cancel"
                        }]

        if {$answer eq "ok"} {
            parm defaults clear
        }
    }



    # FileExit
    #
    # Verifies that the user has saved data before exiting.

    method FileExit {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, the data has been saved if it's going to be; so exit.
        app exit
    }

    # SaveUnsavedData
    #
    # Allows the user to save unsaved changes.  Returns 1 if the user
    # is ready to proceed, and 0 if the current activity should be
    # cancelled.

    method SaveUnsavedData {} {
        if {[scenario unsaved]} {
            set name [file tail [scenario dbfile]]

            set message [tsubst {
                |<--
                The scenario [tif {$name ne ""} {"$name" }]has not been saved.
                Do you want to save your changes?
            }]

            set answer [messagebox popup                 \
                            -icon    warning             \
                            -message $message            \
                            -parent  $win                \
                            -title   "Athena [version]" \
                            -buttons {
                                save    "Save"
                                discard "Discard"
                                cancel  "Cancel"
                            }]

            if {$answer eq "cancel"} {
                return 0
            } elseif {$answer eq "save"} {
                # Stop exiting if the save failed
                if {![$self FileSave]} {
                    return 0
                }
            }
        }

        return 1
    }

    #-------------------------------------------------------------------
    # Edit Menu Handlers

    # PostEditMenu
    #
    # Enables/Disables the undo/redo menu items when the menu is posted.

    method PostEditMenu {} {
        # Undo item
        set title [cif canundo]

        if {$title ne ""} {
            $editmenu entryconfigure 0 \
                -state normal          \
                -label "Undo $title"
        } else {
            $editmenu entryconfigure 0 \
                -state disabled        \
                -label "Undo"
        }

        # Redo item
        set title [cif canredo]

        if {$title ne ""} {
            $editmenu entryconfigure 1 \
                -state normal          \
                -label "Redo $title"
        } else {
            $editmenu entryconfigure 1 \
                -state disabled        \
                -label "Redo"
        }
    }

    # EditUndo
    #
    # Undoes the top order on the undo stack, if any.

    method EditUndo {} {
        if {[cif canundo] ne ""} {
            cif undo
        }
    }

    # EditRedo
    #
    # Redoes the last undone order if any.

    method EditRedo {} {
        if {[cif canredo] ne ""} {
            cif redo
        }
    }

    #-------------------------------------------------------------------
    # Toolbar Event Handlers

    # RunPause
    #
    # Sends SIM:RUN or SIM:PAUSE, depending on state.

    method RunPause {} {
        if {[sim state] eq "RUNNING"} {
            order send gui SIM:PAUSE
        } elseif {[sim state] eq "SNAPSHOT"} {
            set last [expr {[llength [scenario snapshot list]] - 1}]
            set next [expr {[scenario snapshot current] + 1}]
            
            if {$last == $next} {
                set lostSnapshots "Snapshot $next"
            } elseif {$last == $next + 1} {
                set lostSnapshots "Snapshots $next and $last"
            } else {
                set lostSnapshots "Snapshots $next to $last"
            }


            set answer [messagebox popup \
                            -parent    $win                  \
                            -icon      peabody               \
                            -title     "Are you sure?"       \
                            -ignoretag "sim_snapshot_enter"  \
                            -buttons   {
                                ok      "Change the Future"
                                cancel  "Look, But Don't Touch"
                            } -message [normalize "
    Peabody here.  If you wish, you may use the Wayback Machine to re-enter the time stream at Snapshot [scenario snapshot current]; you may then make changes and run the simulation forward.  However, you will lose $lostSnapshots.
                            "]]

            if {$answer eq "ok"} {
                sim snapshot enter
            }
        } else {
            order send gui SIM:RUN \
                days [dict get $durations [$win.toolbar.duration get]]
        }
    }


    # PrepLock
    #
    # Sends SIM:LOCK or SIM:UNLOCK, depending on state.

    method PrepLock {} {
        # FIRST, if we're in PREP then it's time to leave it.
        if {[sim state] eq "PREP"} {
            if {![sim check onlock -report]} {
                messagebox popup \
                    -parent  $win               \
                    -icon    error              \
                    -title   "Not ready to run" \
                    -message [normalize {
            Scenario sanity check failed; time cannot advance.
            Fix the error, and try again.
            Please see the On-Lock Sanity Check report for details.
                    }]

                [app topwin] tab view report

                return
            }

            order send gui SIM:LOCK
            return
        }

        # NEXT, we're not in PREP; we want to return to it.  But
        # give the user the option.
        set answer [messagebox popup \
                        -parent    $win                  \
                        -icon      warning               \
                        -title     "Are you sure?"       \
                        -ignoretag "sim_unlock"          \
                        -default   cancel                \
                        -buttons   {
                            ok      "Return to Prep"
                            cancel  "Cancel"
                        } -message [normalize {
                            If you return to Scenario Preparation, you 
                            will lose any changes made since leaving
                            Scenario Preparation.
                        }]]

        if {$answer eq "ok"} {
            order send gui SIM:UNLOCK
        }
    }


    # SetSpeed speed
    #
    # Sets the simulation speed

    method SetSpeed {speed} {
        set speed [expr {round($speed)}]
        sim speed $speed

        app puts "Simulation Speed: $speed"
    }

    #-------------------------------------------------------------------
    # Mapviewer Event Handlers


    # Unit-1 u
    #
    # u      A unit ID
    #
    # Called when the user clicks on a unit icon.

    method Unit-1 {u} {
        rdb eval {SELECT * FROM gui_units WHERE u=$u} row {
        $self puts \
            "Unit $u  at: $row(location)  group: $row(g)  activity: $row(a)  personnel: $row(personnel)"
        }
    }

    # Ensit-1 s
    #
    # s      An ensit ID
    #
    # Called when the user clicks on an ensit icon.

    method Ensit-1 {s} {
        rdb eval {SELECT * FROM gui_ensits WHERE s=$s} row {
        $self puts \
            "Situation $s: $row(stype)  at: $row(location)  coverage: $row(coverage)"
        }
    }

    # Nbhood-1 n
    #
    # n      A nbhood ID
    #
    # Called when the user clicks on a nbhood.

    method Nbhood-1 {n} {
        rdb eval {SELECT longname FROM nbhoods WHERE n=$n} {}

        $self puts "Neighborhood $n: $longname"
    }

    # Point-1 ref
    #
    # ref     A map reference string
    #
    # The user has pucked a point in point mode. Append it to the
    # CLI.

    method Point-1 {ref} {
        $cli append " $ref"
    }

    # PolyComplete poly
    #
    # poly     A list of map references defining a polygon
    #
    # The user has drawn a polygon on the map.  Append it to the
    # CLI.

    method PolyComplete {poly} {
        $cli append " $poly"
    }




    #-------------------------------------------------------------------
    # Notifier Event Handlers

    # DbSync
    #
    # Syncs with the RDB.

    method DbSync {} {
        # FIRST, set the window title

        set dbfile [file tail [scenario dbfile]]
        if {$dbfile eq ""} {
            set dbfile "Untitled"
        }

        set tab [$content tab current -text]

        if {$options(-main)} {
            set wintype "Main"
        } else {
            set wintype "Browser"
        }

        wm title $win "$dbfile, $tab - Athena [version] $wintype"

        # NEXT, set the status variables
        $win.toolbar.speed configure -value [sim speed]
        $self SimState
        $self SimTime
        $self SimSpeed

        # NEXT, refresh the report browser
        [$self tab win report] refresh
    }

    # SimState
    #
    # This routine is called when the simulation state has changed
    # in some way.

    method SimState {} {
        # FIRST, get some snapshot data
        set now       [sim now]
        set snapshots [scenario snapshot list]
        set latest    [lindex $snapshots end]
        set current   [lsearch -exact $snapshots $now]

        # NEXT, display the simulation state
        if {[sim state] eq "RUNNING"} {
            set prefix [esimstate longname [sim state]]

            if {[sim stoptime] == 0} {
                set info(simstate) "$prefix until paused"
            } else {
                set info(simstate) \
                    "$prefix until [simclock toZulu [sim stoptime]]"
            }
        } elseif {[sim state] eq "SNAPSHOT"} {
            set info(simstate) \
                "Snapshot $current"
        } else {
            set info(simstate) [esimstate longname [sim state]]
        }
        
        # NEXT, update the Prep Lock button
        if {[sim state] eq "PREP"} {
            $win.toolbar.preplock configure \
                -image ::projectgui::icon::unlocked22
            DynamicHelp::add $win.toolbar.preplock \
                -text "Lock Scenario Preparation"
        } else {
            $win.toolbar.preplock configure -image {
                ::projectgui::icon::locked22
                disabled ::projectgui::icon::locked22d
            }

            if {[sim state] eq "RUNNING"} {
                $win.toolbar.preplock configure -state disabled
            } else {
                $win.toolbar.preplock configure -state normal
            }
                    
            DynamicHelp::add $win.toolbar.preplock \
                -text "Unlock Scenario Preparation"
        }

        # NEXT, Update Run/Pause button and the Duration
        if {[sim state] eq "RUNNING"} {
            $win.toolbar.runpause configure \
                -image ::projectgui::icon::pause22 \
                -state normal
            DynamicHelp::add $win.toolbar.runpause -text "Pause Simulation"

            $win.toolbar.duration configure -state disabled
        } elseif {[sim state] eq "SNAPSHOT"} {
            $win.toolbar.runpause configure \
                -image ::projectgui::icon::rewind22 \
                -state normal
            DynamicHelp::add $win.toolbar.runpause -text "Leave Snapshot Mode"

            $win.toolbar.duration configure -state disabled
        } elseif {[sim state] eq "PAUSED"} {
            $win.toolbar.runpause configure \
                -image ::projectgui::icon::play22 \
                -state normal
            DynamicHelp::add $win.toolbar.runpause -text "Run Simulation"

            $win.toolbar.duration configure -state readonly
        } else {
            # PREP
            $win.toolbar.runpause configure \
                -image ::projectgui::icon::play22d \
                -state disabled
            DynamicHelp::add $win.toolbar.runpause -text "Run Simulation"

            $win.toolbar.duration configure -state disabled

        }

        # NEXT, Update the snapshot buttons.
        if {[sim state] in {"PREP" "RUNNING"}} {
            $win.toolbar.first  configure -state disabled
            $win.toolbar.prev   configure -state disabled
            $win.toolbar.next   configure -state disabled
            $win.toolbar.last   configure -state disabled
        } else {
            if {$now > 0} {
                # Not at time 0, first is always valid; and prev is
                # valid if first is.
                $win.toolbar.first configure -state normal
                $win.toolbar.prev  configure -state normal
            } else {
                $win.toolbar.first  configure -state disabled
                $win.toolbar.prev   configure -state disabled
            }

            # If we're at a time earlier than the latest snapshot,
            # then last is valid; and next is valid if last is.
            if {$now < $latest} {
                $win.toolbar.next configure -state normal
                $win.toolbar.last configure -state normal
            } else {
                $win.toolbar.next configure -state disabled
                $win.toolbar.last configure -state disabled
            }
        }

        # NEXT, set the -recentlimit on the report browser, so that
        # reports from this run are recent.
        if {[sim state] eq "RUNNING"} {
            [$self tab win report] configure -recentlimit [simclock now]
        }
    }

    # SimTime
    #
    # This routine is called when the simulation time display has changed,
    # either because the start date has changed, or the time has advanced.

    method SimTime {} {
        # Display current sim time.
        set info(tick)     [format "%04d" [simclock now]]
        set info(zulutime) [simclock asZulu]
        
        # Get day of week
        set cs [zulu tosec $info(zulutime)]
        set dayIndex [clock format $cs -format %w -timezone :UTC]
        set info(dayofweek) "([lindex [edayname names] $dayIndex])"
    }

    # SimSpeed
    #
    # This routine is called when the simulation speed has changed.

    method SimSpeed {} {
        # Display current speed.
        if {round($info(simspeed)) != [sim speed]} {
            set info(simspeed) [sim speed]
        }
    }

    # AppPrefs parm
    #
    # parm     Name of the preferences parm, or ""
    #
    # This routine is called when application preferences have changed.

    method AppPrefs {parm} {
        switch -exact -- $parm {
            cli.maxlines -
            ""           {
                $cli configure -maxlines [prefs get cli.maxlines]
            }
        }
    }

    # ReportCB dict
    #
    # dict     A dictionary of report options
    #
    # Displays the report in the browser.

    method ReportCB {dict} {
        # If this is a requested report, and if this is the top window,
        # then switch the report browser to the "requested" bin, and
        # make the report browser visible.
        if {[dict get $dict -requested] &&
            $win eq [app topwin]
        } {
            $self tab view report
            [$self tab win report] setbin requested
        } else {
            [$self tab win report] update
        }
    }

    # ReportUpdateCB id
    #
    # Refreshes the report browser when an existing report or reports
    # are updated or deleted.

    method ReportUpdateCB {id} {
        [$self tab win report] refresh
    }

    #-------------------------------------------------------------------
    # Utility Methods

    delegate method nbfill to viewer

    # new ?option value...?
    #
    # Creates a new app window.

    typemethod new {args} {
        $type create .%AUTO% {*}$args
    }
    
    # error text
    #
    # text       A tsubst'd text string
    #
    # Displays the error in a message box

    method error {text} {
        set text [uplevel 1 [list tsubst $text]]

        messagebox popup   \
            -message $text \
            -icon    error \
            -parent  $win
    }

    # puts text
    #
    # text     A text string
    #
    # Writes the text to the message line

    method puts {text} {
        $msgline puts $text
    }

    # cli clear
    #
    # Clears the contents of the CLI scrollback buffer

    method {cli clear} {} {
        require {$cli ne ""} "No CLI in this window: $win"

        $cli clear
    }
}
