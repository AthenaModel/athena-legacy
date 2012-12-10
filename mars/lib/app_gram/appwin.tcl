#-----------------------------------------------------------------------
# FILE: appwin.tcl
#
# Main application window.
#
# PACKAGE:
#   app_gram(n) -- mars_gram(1) implementation package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#
# Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget: appwin
#
# Main application window widget; also used for secondary browser
# windows.  Note that an instance of this widget replaces the default
# main window, "."; closing the <-main> appwin will terminate
# the program.  It is expected that "." will be withdrawn at start-up.

snit::widget appwin {
    hulltype toplevel
    
    #-------------------------------------------------------------------
    # Type Components
    
    component cli           ;# The cli(n) pane
    component msgline       ;# The messageline(n)
    component content       ;# The content notebook
    component slog          ;# The scrolling log
 
    #-------------------------------------------------------------------
    # Group: Options

    # Delegate option: *
    #
    # All unknown options are delegated to the hull, a Tk toplevel.
    
    delegate option * to hull

    # Option: -main
    #
    # Whether or not this appwin is the main window (true) or just a
    # secondary browser window (false).  This affects the components, 
    # the menus, and so forth.  The value can be any boolean flag.
    
    option -main      \
        -default  no  \
        -readonly yes

    #-------------------------------------------------------------------
    # Group: Tab Definitions
    #
    # The body of the <appwin> consists of a tabbed notebook containing
    # variety of tabs, each containing some particular view of the
    # application data.  Some tabs have subtabs.  This section contains
    # the definitions of the tabs (in the <tabs> variable) along with
    # some helper routines used to create them.

    # Variable: tabs
    #
    # Dictionary of tab definitions.  The keys are the tab IDs, and
    # the values are tab definition dictionaries.  Each tab definition
    # dictionary has the following keys.  Note that subtabs may not
    # have subtabs of their own.
    #
    #    label  -  The tab text
    #
    #    parent -  The tag of the parent tab, or "" if this is a top-level
    #              tab.
    #
    #    script -  Widget command (and options) to create the tab.
    #              "%W" is replaced with the name of the widget contained
    #              in the new tab.  For tabs containing notebooks, the
    #              script is "".
    #
    #    tabwin -  Once the tab is created, its window.

    variable tabs {
        slog {
            label  "Log"
            parent ""
            script {
                scrollinglog %W \
                    -relief        flat                               \
                    -height        14                                 \
                    -logcmd        [mymethod puts]                    \
                    -loglevel      debug                              \
                    -showloglist   yes                                \
                    -rootdir       [file normalize [file join . log]] \
                    -defaultappdir mars_gram                          \
                    -format        {
                        {zulu  12 yes}
                        {v      7 yes}
                        {c      9 yes}
                        {m      0 yes}
                    }
            }
        }
        
        gram_driver {
            label Drivers
            parent ""
            script {
                gram_tab %W gram_driver 1 -layout {
                    { driver     - -sortmode integer }
                    { dtype      -                   }
                    { name       -                   }
                    { oneliner   -                   }
                    { last_input - -sortmode integer }
                }
            }
        }
        
        sat {
            label  "Satisfaction"
            parent ""
            script ""
        }
        
        gram_sat {
            label gram_sat
            parent sat
            script {
                gram_tab %W gv_gram_sat 6 -layout {
                    { ngc_id   - -sortmode integer }
                    { ng_id    - -sortmode integer }
                    { n        -                   }
                    { g        -                   }
                    { c        -                   }
                    { gtype    -                   }
                    { saliency - -sortmode real    }
                    { curve_id - -sortmode integer }
                    { sat0     - -sortmode real    }
                    { sat      - -sortmode real    }
                    { delta    - -sortmode real    }
                    { slope    - -sortmode real    }
                }
            }
        }
        
        satinf {
            label gram_sat_influence
            parent sat
            script {
                gram_tab %W gv_gram_sat_influence 6 -layout {
                    { direct_ng     - -sortmode integer }
                    { d_n           -                   }
                    { d_g           -                   }
                    { influenced_ng - -sortmode integer }
                    { i_n           -                   }
                    { i_g           -                   }
                    { prox          - -sortmode integer }
                    { delay         - -sortmode real    }
                    { factor        - -sortmode real    }
                }
            }
        }
        
        satlevels {
            label Levels
            parent sat
            script {
                gram_tab %W gv_gram_sat_levels 6 -layout {
                    { driver   - -sortmode integer }
                    { input    - -sortmode integer }
                    { id       - -sortmode integer }
                    { n        -                   }
                    { g        -                   }
                    { c        -                   }
                    { ts       - -sortmode integer }
                    { te       - -sortmode integer }
                    { dn       -                   }
                    { dg       -                   }
                    { cause    -                   }
                    { prox     - -sortmode integer }
                    { sat      - -sortmode real    }
                    { athresh  - -sortmode real    }
                    { dthresh  - -sortmode real    }
                    { days     - -sortmode real    }
                    { tau      - -sortmode real    }
                    { llimit   - -sortmode real    }
                    { tlast    - -sortmode integer }
                    { ncontrib - -sortmode real    }
                    { acontrib - -sortmode real    }
                    { nominal  - -sortmode real    }
                    { actual   - -sortmode real    }
                }
            }
        }

        satslopes {
            label Slopes
            parent sat
            script {
                gram_tab %W gv_gram_sat_slopes 6 -layout {
                    { driver   - -sortmode integer }
                    { input    - -sortmode integer }
                    { id       - -sortmode integer }
                    { n        -                   }
                    { g        -                   }
                    { c        -                   }
                    { ts       - -sortmode integer }
                    { te       - -sortmode integer }
                    { dn       -                   }
                    { dg       -                   }
                    { cause    -                   }
                    { prox     - -sortmode integer }
                    { sat      - -sortmode real    }
                    { athresh  - -sortmode real    }
                    { dthresh  - -sortmode real    }
                    { delay    - -sortmode real    }
                    { slope    - -sortmode real    }
                    { tlast    - -sortmode integer }
                    { ncontrib - -sortmode real    }
                    { acontrib - -sortmode real    }
                    { nominal  - -sortmode real    }
                    { actual   - -sortmode real    }
                    { future   -                   }
                } -views {
                    gv_gram_sat_slopes       "Exclude Trends"
                    gv_gram_sat_slopes_trend "Include Trends"
                }
            }
        }

        coop {
            label  "Cooperation"
            parent ""
            script ""
        }

        gram_coop {
            label gram_coop
            parent coop
            script {
                gram_tab %W gv_gram_coop 5 -layout {
                    { nfg_id   - -sortmode integer }
                    { curve_id - -sortmode integer }
                    { n        -                   }
                    { f        -                   }
                    { g        -                   }
                    { coop0    - -sortmode real    }
                    { coop     - -sortmode real    }
                    { delta    - -sortmode real    }
                    { slope    - -sortmode real    }
                }
            }
        }
        
        gram_coop_influence {
            label  gram_coop_influence
            parent coop
            script {
                gram_tab %W gv_gram_coop_influence 4 -layout {
                    { dn     -                    }
                    { dg     -                    }
                    { m      -                    }
                    { h      -                    }
                    { prox   -  -sortmode integer }
                    { delay  -  -sortmode real    }
                    { factor -  -sortmode real    }
                }
            }
        }

        cooplevels {
            label Levels
            parent coop
            script {
                gram_tab %W gv_gram_coop_levels 6 -layout {
                    { driver   - -sortmode integer }
                    { input    - -sortmode integer }
                    { id       - -sortmode integer }
                    { n        -                   }
                    { f        -                   }
                    { g        -                   }
                    { ts       - -sortmode integer }
                    { te       - -sortmode integer }
                    { dn       -                   }
                    { df       -                   }
                    { dg       -                   }
                    { cause    -                   }
                    { prox     - -sortmode integer }
                    { coop     - -sortmode real    }
                    { athresh  - -sortmode real    }
                    { dthresh  - -sortmode real    }
                    { days     - -sortmode real    }
                    { tau      - -sortmode real    }
                    { llimit   - -sortmode real    }
                    { tlast    - -sortmode integer }
                    { ncontrib - -sortmode real    }
                    { acontrib - -sortmode real    }
                    { nominal  - -sortmode real    }
                    { actual   - -sortmode real    }
                }
            }
        }

        coopslopes {
            label Slopes
            parent coop
            script {
                gram_tab %W gv_gram_coop_slopes 6 -layout {
                    { driver   - -sortmode integer }
                    { input    - -sortmode integer }
                    { id       - -sortmode integer }
                    { n        -                   }
                    { f        -                   }
                    { g        -                   }
                    { ts       - -sortmode integer }
                    { te       - -sortmode integer }
                    { dn       -                   }
                    { df       -                   }
                    { dg       -                   }
                    { cause    -                   }
                    { prox     - -sortmode integer }
                    { coop     - -sortmode real    }
                    { athresh  - -sortmode real    }
                    { dthresh  - -sortmode real    }
                    { delay    - -sortmode real    }
                    { slope    - -sortmode real    }
                    { tlast    - -sortmode integer }
                    { ncontrib - -sortmode real    }
                    { acontrib - -sortmode real    }
                    { nominal  - -sortmode real    }
                    { actual   - -sortmode real    }
                    { future   -                   }
                }
            }
        }

        gramdb {
            label  "gramdb(5)"
            parent ""
            script ""
        }

        gramdb_mn {
            label mn
            parent gramdb
            script {
                gramdb_tab %W gramdb_mn 2
            }
        }
        
        gramdb_g {
            label  g
            parent gramdb
            script { gramdb_tab %W gramdb_g 1 }
        }

        gramdb_ng {
            label  ng
            parent gramdb
            script { gramdb_tab %W gramdb_ng 2 }
        }
        
        gramdb_gc {
            label  gc
            parent gramdb
            script { gramdb_tab %W gramdb_gc 2 }
        }
        
        gramdb_ngc {
            label  ngc
            parent gramdb
            script { gramdb_tab %W gramdb_ngc 3 }
        }

        gramdb_fg {
            label  fg
            parent gramdb
            script { gramdb_tab %W gramdb_fg 2 }
        }
        
        gramdb_nfg {
            label  nfg
            parent gramdb
            script { gramdb_tab %W gramdb_nfg 3 }
        }
        
        query {
            label  Query
            parent ""
            script {
                querybrowser %W                 \
                    -db       ::rdb             \
                    -reloadon { ::sim <Reset> }
            }
        }
    }
    
    #-----------------------------------------------------------------------
    # Tab Helper Routines
    
    # proc: gram_tab
    #
    # Helper routine for use in <Tab Definitions>.
    # Creates an sqlbrowser(n) tab with default settings for a
    # gram(n) table.
    #
    # Syntax:
    #   gram_tab _win name tc ?option value...?_
    #
    #   win          - The window name
    #   name         - The name of a gram(n) table or view
    #   tc           - Number of title columns
    #   option value - sqlbrowser(n) options and their values.
    
    proc gram_tab {win name tc args} {
        sqlbrowser $win \
            -db           ::rdb               \
            -view         $name               \
            -titlecolumns $tc                 \
            -reloadbtn    yes                 \
            -reloadon     {
                ::sim <Reset>
                ::sim <Time>
            }                                 \
            {*}$args
    }

    # proc: gramdb_tab
    #
    # Helper routine for use in <Tab Definitions>.
    # Creates an sqlbrowser(n) tab with default settings
    # for a gramdb(5) table.
    #
    # Syntax:
    #   gram_tab _win name tc ?option value...?_
    #
    #   win          - The window name
    #   name         - The name of a gramdb(5) table or view
    #   tc           - Number of title columns
    #   option value - sqlbrowser(n) options and their values.

    proc gramdb_tab {win name tc args} {
        sqlbrowser $win \
            -db           ::rdb               \
            -view         $name               \
            -titlecolumns $tc                 \
            -reloadbtn    yes                 \
            -reloadon     { ::sim <Reset> }   \
            {*}$args
    }

    #-------------------------------------------------------------------
    # Group: Instance Variables

    # Variable: info
    #
    # Status info array.  The keys are as follows.
    #
    #   ticks - Current sim time as a four-digit tick, for display
    #           in the toolbar.
    #   zulu  - Current sim time as a zulu time string, for display
    #           in the toolbar.

    variable info -array {
        ticks  "0000"
        zulu   ""
    }

    #-------------------------------------------------------------------
    # Group: Constructor

    # Constructor: constructor
    #
    # Creates a new appwin with the specified <Options>.

    constructor {args} {
        # FIRST, get the options
        $self configurelist $args

        # NEXT, set the default window title
        wm title $win "GRAM Workbench"

        # NEXT, Exit the app when this window is closed, if it's a 
        # main window.
        if {$options(-main)} {
            wm protocol $win WM_DELETE_WINDOW [list app exit]
        }
        
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
        notifier bind ::sim <Reset>         $self [mymethod Reconfigure]
        notifier bind ::sim <Time>          $self [mymethod SimTime]

        # NEXT, Prepare to receive window events
        bind $content <<NotebookTabChanged>> [mymethod Reconfigure]

        # NEXT, Reconfigure self on creation
        $self Reconfigure
    }

    # Destructor: destructor
    #
    # Unsubscribes the <appwin> from all of its notifier(n) events.
    
    destructor {
        notifier forget $self
    }
    
    #===================================================================
    # Group: Menu Bar
    #
    # This section contains the routines that create the menu bar and
    # implement the individual menu items.
    
    #-------------------------------------------------------------------
    # Menu Bar: Creation

    # method: CreateMenuBar
    #
    # Creates the main menu bar.

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

        $mnu add command \
            -label "Load gramdb(5) File..." \
            -underline 0 \
            -accelerator "Ctrl+L" \
            -command [mymethod FileLoadGramdb]
        bind . <Control-l> [mymethod FileLoadGramdb]

        cond::dbloaded control \
            [menuitem $mnu command "Save RDB File..." \
                -underline 5                          \
                -command   [mymethod FileSaveRDB]]
        
        if {$options(-main)} {
            $mnu add command                               \
                -label     "Save CLI Scrollback Buffer..." \
                -underline 5                               \
                -command   [mymethod FileSaveCLI]
        }

        $mnu add separator

        if {$options(-main)} {
            $mnu add command                       \
                -label       "Exit"                \
                -underline   1                     \
                -accelerator "Ctrl+Q"              \
                -command     [list app exit]
            bind $win <Control-q> [list app exit]
            bind $win <Control-Q> [list app exit]
        } else {
            $mnu add command                       \
                -label       "Close Window"        \
                -underline   6                     \
                -accelerator "Ctrl+W"              \
                -command     [list destroy $win]
            bind $win <Control-w> [list destroy $win]
            bind $win <Control-W> [list destroy $win]
        }

        # Edit menu
        set mnu [menu $menubar.edit]
        $menubar add cascade -label "Edit" -underline 0 -menu $mnu

        $mnu add command \
            -label "Cut" \
            -underline 2 \
            -accelerator "Ctrl+X" \
            -command {event generate [focus] <<Cut>>}

        $mnu add command \
            -label "Copy" \
            -underline 0 \
            -accelerator "Ctrl+C" \
            -command {event generate [focus] <<Copy>>}
        
        $mnu add command \
            -label "Paste" \
            -underline 0 \
            -accelerator "Ctrl+V" \
            -command {event generate [focus] <<Paste>>}
        
        $mnu add separator
        
        $mnu add command \
            -label "Select All" \
            -underline 7 \
            -accelerator "Ctrl+Shift+A" \
            -command {event generate [focus] <<SelectAll>>}

        # View menu
        set viewmenu [menu $menubar.view]
        $menubar add cascade -label "View" -underline 0 -menu $viewmenu

        $self AddTabMenuItems $viewmenu
    }

    # method: AddTabMenuItems
    #
    # Adds menu items to the View menu to pop up each of the <tabs>.
    #
    # Syntax:
    #   AddTabMenuItems _mnu_
    #
    #   mnu - The View menu
    #
    # TBD: It isn't clear whether these View menu items are really all
    # that useful.

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
    
    #-------------------------------------------------------------------
    # Menu Bar: Menu Item Handlers

    # method: FileLoadGramdb
    #
    # File/Load gramdb(5) File... menu item.
    #
    # Allows the user to select a gramdb(5) file via an Open File dialog;
    # the file is then loaded.
    
    method FileLoadGramdb {} {
        set name [tk_getOpenFile \
                      -defaultextension ".gramdb"                 \
                      -filetypes        {{gramdb(5) {.gramdb}}}   \
                      -parent           .                         \
                      -title            "Load gramdb(5) File..."]
        
        if {$name ne ""} {
            executive evalsafe [list load $name]
        }
    }

    # method: FileSaveRDB
    #
    # File/Save RDB... menu item.
    #
    # Allows the user to save a snapshot of the RDB to a file.

    method FileSaveRDB {} {
        # FIRST, if there's no database loaded there's nothing to save.
        if {![sim dbloaded]} {
            app puts "No database to save."
            bell
            return
        }
        
        set dbfile [sim dbfile]
        set initialDir [file dirname $dbfile]
        
        set defaultName [file rootname [file tail $dbfile]].rdb
        
        set filename [tk_getSaveFile \
                          -filetypes        {{"Run-time Database" {.rdb}}} \
                          -initialfile      $defaultName     \
                          -initialdir       $initialDir      \
                          -defaultextension .rdb             \
                          -title            "Save RDB As..." \
                          -parent           .]

        if {$filename eq ""} {
            app puts "Cancelled."
            return
        }

        if {[catch {
            rdb saveas $filename
        } result]} {
            log warning app "Stack Trace:\n$::errorInfo"
            log warning app "Error saving '$filename': $result"
        } else {
            log normal app "Saved '$filename'"
        }
    }


    # method: FileSaveCLI
    #
    # File/Save CLI Scrollback Buffer... menu item.
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
    
    #===================================================================
    # Group: Components
    #
    # This section contains routines that build the <appwin>'s
    # major components.

    # method: CreateComponents
    #
    # Creates and lays out the <appwin>'s components (other than the
    # menus).

    method CreateComponents {} {
        # FIRST, prepare the grid.  The scrolling log/shell panedwindow
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
        ttk::separator $win.sep0 -orient horizontal

        # ROW 1, add a simulation toolbar
        ttk::frame $win.toolbar

        if {$options(-main)} {
            ttk::button $win.toolbar.step                \
                -style Toolbutton                        \
                -image [list                             \
                                 ::marsgui::icon::step   \
                        disabled ::marsgui::icon::stepd] \
                -command [list executive evalsafe step]
            cond::dbloaded control $win.toolbar.step
            
            DynamicHelp::add $win.toolbar.step \
                -text "Advance time one step"


            pack $win.toolbar.step      -side left
        }
        
        ttk::label $win.toolbar.zululabel \
            -text "Time:"
        
        ttk::label $win.toolbar.zulu              \
            -font         codefont                \
            -width        12                      \
            -textvariable [myvar info(zulu)]

        ttk::label $win.toolbar.ticklabel \
            -text "Tick:"
        
        ttk::label $win.toolbar.ticks             \
            -font         codefont                \
            -width        4                       \
            -anchor       e                       \
            -textvariable [myvar info(ticks)]

        pack $win.toolbar.ticks     -side right
        pack $win.toolbar.ticklabel -side right -padx {5 0}
        pack $win.toolbar.zulu      -side right
        pack $win.toolbar.zululabel -side right -padx {5 0}

        # ROW 2, add a separator between the tool bar and the content
        # window.
        ttk::separator $win.sep2 -orient horizontal

        # ROW 3, create the content widgets.  If this is a main window,
        # then we have a paner containing the content notebook with 
        # a CLI underneath.  Otherwise, we get just the content
        # notebook.
        if {$options(-main)} {
            ttk::panedwindow $win.paner -orient vertical
            install content using ttk::notebook $win.paner.content \
                -padding 2 

            $win.paner add $content -weight 1

            set row3 $win.paner
        } else {
            install content using ttk::notebook $win.content \
                -padding 2 

            set row3 $win.content
        }

        # ROW 4, add a separator
        ttk::separator $win.sep4 -orient horizontal

        # ROW 5, Create the Status Line frame.
        ttk::frame $win.status    \
            -relief      flat     \
            -borderwidth 2

        # Message line
        install msgline using messageline $win.status.msgline

        pack $win.status.msgline -fill both -expand yes


        # NEXT, add the content tabs, and save relevant tabs
        # as components.  Also, finish configuring the tabs.
        $self AddTabs

        # Scrolling log
        set slog   [$self tab win slog]
        $slog load [log cget -logfile]
        notifier bind ::app <AppLogNew> $self [list $slog load]

        # NEXT, add the CLI to the paner, if needed.
        if {$options(-main)} {
            install cli using cli $win.paner.cli    \
                -height    8                        \
                -relief    flat                     \
                -promptcmd [mymethod CliPrompt]     \
                -evalcmd   [list ::executive eval]
            
            $win.paner add $win.paner.cli -weight 0

            # Load the CLI command history
            $self LoadCliHistory
        }

        # NEXT, manage all of the components.
        grid $win.sep0     -sticky ew
        grid $win.toolbar  -sticky ew
        grid $win.sep2     -sticky ew
        grid $row3         -sticky nsew
        grid $win.sep4     -sticky ew
        grid $win.status   -sticky ew
    }

    # method: AddTabs
    #
    # Adds all of the content tabs and subtabs to the window,
    # reading the <Tab Definitions> from the <tabs> variable.

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
    
   
    #-------------------------------------------------------------------
    # Group: Event Handlers
    #
    # This section contains a variety of event handlers bound to
    # widgets and notifier events during creation of the window.

    # method: Reconfigure
    #
    # Reconfigure the window to reflect the current scenario, in
    # response to a variety of notifier events.

    method Reconfigure {} {
        if {[sim dbfile] ne ""} {
            wm title $win "[file tail [sim dbfile]] - GRAM Workbench"
        } else {
            wm title $win "GRAM Workbench"
        }
        $self SimTime
    }

    # method: SimTime
    #
    # Update the displayed simulation time, because either the start date
    # has changed or the simulation time has advanced.

    method SimTime {} {
        # Display current sim time.
        set info(ticks) [format "%04d" [simclock now]]
        set info(zulu)  [simclock asZulu]
    }

    # method: CliPrompt
    #
    # Return a prompt string for the CLI.

    method CliPrompt {} {
        return ">"
    }
    
    #===================================================================
    # Group: Public Methods - Tab management
    #
    # These methods manipulate the window's <tabs>.

    # Method: tab win
    #
    # Returns the window name of the content window on the
    # specified tab.
    #
    # Syntax:
    #   tab win _tab_
    #
    #   tab -  A tab ID, as defined in <tabs>
    
    method "tab win" {tab} {
        dict get $tabs $tab tabwin
    }

    # Method: tab view
    #
    # Brings the named tab to the front of the window.  If the tab is
    # a subtab, the parent tab is also brought to the front.
    #
    # Syntax:
    #   tab view _tab_
    #
    #   tab -  A tab ID, as defined in <tabs>.

    method "tab view" {tab} {
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
    # Group: CLI History

    # method: savehistory
    #
    # If there's a CLI, saves its command history to 
    # ~/.mars_gram/history.cli.
    #
    # TBD: This should probably be "cli savehistory".

    method savehistory {} {
        assert {$cli ne ""}

        file mkdir ~/.mars_gram
        
        set f [open ~/.mars_gram/history.cli w]

        puts $f [$cli saveable checkpoint]
        
        close $f
    }

    # method: LoadCliHistory
    #
    # Load the CLI history file, if any, into the CLI.
    #
    # TBD: This should probably be "cli loadhistory".

    method LoadCliHistory {} {
        if {[file exists ~/.mars_gram/history.cli]} {
            $cli saveable restore [readfile ~/.mars_gram/history.cli]
        }
    }

    # method: cli clear
    #
    # Clears the contents of the CLI scrollback buffer

    method "cli clear" {} {
        require {$cli ne ""} "No CLI in this window: $win"

        $cli clear
    }
    
    #-------------------------------------------------------------------
    # Group: Other Public Methods

    # method: new
    #
    # Creates a new application window with the specified options
    # and an automatically generated name.
    #
    # Syntax:
    #   new _?option value...?_
    #
    #   option value - The creation <options>.

    typemethod new {args} {
        $type create .%AUTO% {*}$args
    }
    
    # method: error
    #
    # Displays the error text in a messagebox(n) dialog.
    #
    # Syntax:
    #   error _text_
    #
    #   text - A tsubst'd text string

    method error {text} {
        set text [uplevel 1 [list tsubst $text]]

        messagebox popup   \
            -message $text \
            -icon    error \
            -parent  $win
    }

    # method: puts
    #
    # Writes the text to the window's message line.
    #
    # Syntax:
    #   puts _text_
    #
    #   text - A text string

    method puts {text} {
        $msgline puts $text
    }

}
