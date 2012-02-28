#-----------------------------------------------------------------------
# TITLE:
#    reportbrowser.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsgui(n) package: Report Browser widget.
#
#    This widget allows the user to browse the reports in an
#    sqldocument(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export reportbrowser
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::marsgui::reportbrowser {
    hulltype ttk::frame
    
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    # -shownewest boolean
    #
    # Determines whether to scroll to the newest reports when loading
    # a bin, or not.
    option -shownewest -default 0

    # -showrecent boolean
    #
    # Determines whether or not only recent reports should be 
    # shown.
    option -showrecent -default 0 -configuremethod CfgShowRecent

    method CfgShowRecent {opt val} {
        set options($opt) $val
        
        $self LoadBin
    }

    # -recentlimit time
    #
    # Defines "recent" as no older than $time.
    option -recentlimit -default 0

    # -scrolllock boolean
    #
    # Determines whether or not the widget is locked from autoscrolling
    # when new reports are retrieved.
    option -scrolllock -default 0 -configuremethod CfgScrollLock

    method CfgScrollLock {opt val} {
        set options($opt) $val

        # Update the GUI
        $self UpdateScrollLock
    }

    # -db db
    #
    # Sets the database.  It is necessary to do an explicit refresh
    # when changing the database.

    option -db -configuremethod CfgDb

    method CfgDb {opt val} {
        set options($opt) $val
        set db            $val

        $viewer configure -db $db
    }
    
    # Option: -logcmd
    #
    # A command that takes one additional argument, a status message
    # to be displayed to the user.
    
    option -logcmd \
        -default ""

    #-------------------------------------------------------------------
    # Components

    component search      ;# The toolbar search box
    component bintree     ;# The rb_bintree of report bins
    component replist     ;# The listbox of report titles
    component viewer      ;# The report text widget
    component db          ;# The database object

    #-------------------------------------------------------------------
    # Instance variables

    variable reportList   {}      ;# List of report headers
    variable reportIds    {}      ;# Matching list of report IDs
    variable timeOfFirstReport -1 ;# Timestamp of earliest report in
                                   # reportList.

    variable currentView  {}      ;# The view name of the current view
    variable currentBin   {}      ;# The label of the current bin

    # Array of variables used by the Search box.
    variable searchInfo -array {
        TitleOnlyFlag 0
        QueryString   {}
    }

    #-------------------------------------------------------------------
    # Constructor
    #
    # There's a vertical list of report bins on the left-hand side; 
    # the right-hand side is divided top and bottom into a list of 
    # reports and the text of a single report.

    constructor {args} {
        # FIRST, prepare the grid.  The browser itself
        # should stretch vertically on resize; the toolbar and separator
        # shouldn't. And everything should stretch horizontally.

        grid rowconfigure $win 0 -weight 0
        grid rowconfigure $win 1 -weight 0
        grid rowconfigure $win 2 -weight 1

        grid columnconfigure $win 0 -weight 1

        # ROW 0: Toolbar
        ttk::frame $win.bar

        set search [$self CreateSearchBox $win.bar.search]

        ttk::label $win.bar.current \
            -textvariable [myvar currentBin]

        ttk::checkbutton $win.bar.recent              \
            -style       Toolbutton                   \
            -image       ::marsgui::icon::clock       \
            -command     [mymethod LoadBin]           \
            -variable    [myvar options(-showrecent)] 

        DynamicHelp::add $win.bar.recent \
            -text "When set, show recent reports only."

        ttk::checkbutton $win.bar.scrolllock              \
            -style       Toolbutton                       \
            -image       {
                         ::marsgui::icon::unlocked
                selected ::marsgui::icon::locked}         \
            -variable    [myvar options(-scrolllock)]     \
            -command     [mymethod UpdateScrollLock]

        DynamicHelp::add $win.bar.scrolllock \
            -text "When locked, do not jump to new reports."

        pack $win.bar.current    -side left
        pack $win.bar.scrolllock -side right
        pack $win.bar.recent     -side right
        pack $search             -side right -padx 2
        
        # ROW 1, add a separator
        ttk::separator $win.sep1 -orient horizontal

        # ROW 2, the left/right paner
        ttk::panedwindow $win.lr \
            -orient horizontal

        # Add bintree on the left.  TBD: Options needed?
        install bintree using ::marsgui::rb_bintree $win.lr.bintree
        $win.lr add $win.lr.bintree

        # Right-hand pane: top/bottom paner
        # TBD: Feed defaults back into paner(n).
        ttk::panedwindow $win.lr.tb           \
            -orient vertical
        $win.lr add $win.lr.tb

        # List pane
        ttk::frame $win.lr.tb.top
        $win.lr.tb add $win.lr.tb.top

        install replist using listbox $win.lr.tb.top.reports \
            -exportselection 0 \
            -selectmode single \
            -listvariable [myvar reportList] \
            -yscrollcommand [list $win.lr.tb.top.yscroll set] \
            -font codefont \
            -activestyle none \
            -height 10 \
            -highlightthickness 1
        bind $replist <1> {focus %W}

        ttk::scrollbar $win.lr.tb.top.yscroll \
            -orient  vertical                 \
            -command [list $replist yview]
       
        grid columnconfigure $win.lr.tb.top 0 -weight 1
        grid rowconfigure    $win.lr.tb.top 0 -weight 1
        grid $replist $win.lr.tb.top.yscroll -sticky nsew

        # Report Text pane
        install viewer using ::marsgui::reportviewer $win.lr.tb.bottom \
            -height 10                                                 \
            -logcmd [mymethod Log]
        $win.lr.tb add $win.lr.tb.bottom

        # NEXT, manage all of the components.
        grid $win.bar  -sticky ew -pady 2
        grid $win.sep1 -sticky ew
        grid $win.lr   -stick nsew

        # NEXT, select the bin when they click
        bind $bintree <<Selection>> [mymethod LoadBin]

        # NEXT, display a report when they click
        bind $replist <<ListboxSelect>> [mymethod LoadReport]
        bind $replist <Double-1> [mymethod DoubleClick %y]

        # NEXT, scrolling bindings
        bind $replist <Up>    [mymethod Step -1]
        bind $replist <Down>  [mymethod Step  1]
        bind $replist <Prior> [mymethod Step -1]
        bind $replist <Next>  [mymethod Step  1]
        bind $replist <Home>  [mymethod JumpToReport 0]
        bind $replist <End>   [mymethod JumpToReport end]
        bind $replist <Left>  {break}
        bind $replist <Right> {break}

        # NEXT, get the options.
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Event Handlers
    
    # Method: Log
    #
    # Logs a status message by calling the <-logcmd>.
    #
    # Syntax:
    #   Log _msg_
    #
    #   msg     A short text message
    
    method Log {msg} {
        callwith $options(-logcmd) $msg
    }


    # UpdateScrollLock
    #
    # Scrolls to the end of the report list when scroll lock is disabled.

    method UpdateScrollLock {} {
        if {!$options(-scrolllock)} {
            $self JumpToReport end
        }
    }

    # Step n
    #
    # n    The number of reports to step
    #
    # Steps to the report n away from the current report.
    
    method Step {n} {
        set ndx [$replist curselection]

        if {$ndx eq ""} {
            return -code break
        } elseif {$n < 0 && $ndx + $n < 0} {
            return -code break
        } elseif {$n > 0 && $ndx + $n >= [$replist index end]} {
            return -code break
        }

        incr ndx $n
        $self JumpToReport $ndx
        return -code break
    }

    # JumpToReport ndx
    #
    # ndx    An index in the replist
    #
    # Scrolls the replist to display the selected report.

    method JumpToReport {ndx} {
        # Do nothing if there are none.
        if {[llength $reportList] == 0} {
            return
        }

        # TBD: There has got to be a better way to do this.
        $replist see $ndx
        $replist selection clear 0 end
        $replist selection set $ndx $ndx
        $self LoadReport
        $replist see $ndx
        update idletasks ;# Needed?
    }

    # LoadBin
    #
    # Loads the currently selected bin

    method LoadBin {} {
        # If we don't have a database yet, do nothing.
        if {$db eq ""} {
            return
        }

        # Get the currently selected bin.
        set bin [$bintree get]

        # If nothing's selected, do nothing.
        if {$bin eq ""} {
            return
        }

        $self GetReports $bin
        $self JumpToReport end
    }

    # GetReports bin
    #
    # Loads the report headers for the specified bin.

    method GetReports {bin} {
        # FIRST, clear the displayed report.
        $self ClearReport

        # NEXT, save the view
        set currentView [reporter bin view  $bin]
        set currentBin  [reporter bin title $bin]

        # NEXT, get the reports for this view
        set reportList {}
        set reportIds {}

        set query "SELECT id,time,stamp,rtype,title FROM $currentView"

        set conditions {}

        if {$options(-showrecent)} {
            lappend conditions "(time >= $options(-recentlimit))"
        }

        if {$searchInfo(QueryString) ne ""} {
            lappend conditions $searchInfo(QueryString)
        }

        if {[llength $conditions] > 0} {
            append query "\nWHERE [join $conditions { AND }]"
        }

        append query "\nORDER BY id"

        # Get the new reports
        $self QueryReportsToReportList $query

        # Get time of first report
        set firstId [lindex $reportIds 0]
        set timeOfFirstReport [$db onecolumn {
            SELECT time FROM reports WHERE id=$firstId
        }]

        # NEXT, if -shownewest jump to end, else jump to beginning.
        if {$options(-shownewest)} {
            $self JumpToReport end
        } else {
            $self JumpToReport 0
        }
    }

    # QueryReportsToReportList query
    #
    # query            An SQL query for reports
    #
    # Performs the query, updating the reportIds and reportList
    # variables.  It's assumed that the caller clears these variables
    # first, if necessary.
    #
    # NOTE: reportList is tied to the replist widget--if we actually
    # updated reportList as we did the query, it would be *extremely*
    # slow.  By adding the report titles to a local variable and then
    # updating reportList once it takes a few seconds for a large
    # set of reports instead of MINUTES.

    method QueryReportsToReportList {query} {
        set list $reportList

        $db eval $query row {
            lappend reportIds $row(id)
            lappend list [format "#%06d %s %s" $row(id) $row(stamp) $row(title)]
        }

        set reportList $list
    }

    # update
    #
    # Looks for new reports in the current bin, and adds them to the list
    # if any.

    method update {} {
        # FIRST, do nothing until we have a db and a bin.
        if {$db eq ""} {
            return
        }

        # Get the currently selected bin.
        set bin [$bintree get]

        # If nothing's selected, do nothing.
        if {$bin eq ""} {
            return
        }

        # NEXT, get the current view, and the bin title
        set currentView [reporter bin view  $bin]
        set currentBin  [reporter bin title $bin]


        # NEXT, If we're browsing recent reports, periodically retrieve
        # the whole list instead of just the new ones.  Otherwise,
        # update normally.  Make sure scroll lock is off, or the display
        # will jump.
        if {$options(-showrecent) && 
            !$options(-scrolllock) &&
            $timeOfFirstReport < $options(-recentlimit)} {

            $self LoadBin
        } else {
            # FIRST, get the new reports for this view.
            if {[llength $reportIds] == 0} {
                set maxId 0
            } else {
                set maxId [lindex $reportIds end]
            }

            if {[catch {$self GetNewReports $maxId} result]} {
                # TBD: Need a logging interface.
                puts "$self update: Error, $result"
            }

            # NEXT, if we've added any, display the last, unless
            # scrolling is locked.
            if {!$options(-scrolllock)
                && [lindex $reportIds end] != $maxId} {
                $self JumpToReport end
            }
        }
    }

    # GetNewReports lastId
    #
    # lastId       A report ID
    #
    # Gets new reports matching the current view which have IDs greater
    # than last ID, and adds them to report list.
    #
    # NOTE: This method exists mostly so that it's easy to catch
    # errors (e.g., lock errors).

    method GetNewReports {lastId} {
        set query "
            SELECT id,stamp,rtype,title FROM $currentView 
            WHERE id > $lastId 
        " 

        if {$searchInfo(QueryString) ne ""} {
            append query "AND  $searchInfo(QueryString)"
        }
        append query "\nORDER BY id"

        $self QueryReportsToReportList $query
    }

    # LoadReport
    #
    # Loads the selected report into the viewer widget.

    method LoadReport {} {
        set ndx [$replist curselection]

        if {$ndx eq ""} {
            return
        }

        set id [lindex $reportIds $ndx]
        
        $viewer display $id
    }

    # DoubleClick y
    #
    # Loads a report into a window given coordinates of double click

    method DoubleClick {y} {
        set ndx [$replist nearest $y]

        if {$ndx eq ""} {
            return
        }

        set id [lindex $reportIds $ndx]

        ::marsgui::reportviewerwin display $db $id
    }

    # ClearReport
    #
    # Clears the viewer widget

    method ClearReport {} {
        $viewer clear
    }

    #-------------------------------------------------------------------
    # Search Methods

    # CreateSearchBox w
    # 
    # w    The name of the search box widget
    #
    # Creates a search box in the toolbar.

    method CreateSearchBox {w} {
        # FIRST, Create the commandentry
        commandentry $w \
            -width              30                          \
            -clearbtn           1                           \
            -changecmd          [mymethod SearchCheckEmpty] \
            -returncmd          [mymethod SearchDoSearch]
        
        # NEXT, Create the menu button, and put it at the beginning.
        set f [$w frame]
        
        set menu $f.menubtn.menu

        ttk::menubutton $f.menubtn                \
            -style  Entrybutton.Toolbutton        \
            -image  ::marsgui::icon::filter       \
            -menu   $menu
        
        pack $f.menubtn \
            -before [lindex [pack slaves $f] 0] \
            -side   left                        \
            -padx   2

        DynamicHelp::add $f.menubtn \
            -text "Search Options Menu"

        # The search-type menu
        menu $menu

        $menu add radio \
            -label "Search Title and Text" \
            -variable [myvar searchInfo(TitleOnlyFlag)] \
            -value 0 \
            -command [mymethod SearchAgain]

        $menu add radio \
            -label "Search Titles Only" \
            -variable [myvar searchInfo(TitleOnlyFlag)] \
            -value 1 \
            -command [mymethod SearchAgain]

        return $w
    }

    # SearchCheckEmpty text
    #
    # text     Current contents of the finder field.
    #
    # Check and return the empty state of the finder field.
    # Called on change.

    method SearchCheckEmpty {text} {
        if {[string is space $text]} {
            $self SearchClear
        }
    }

    # SearchDoSearch target
    #
    # target      Tne current search string
    #
    # Execute a search with the current search target.

    method SearchDoSearch {target} {
        # FIRST, Ignore empty targets
        if {[string is space $target]} {
            $self SearchClear
            return
        }

        # NEXT, get the query
        set pattern "*[string map {* \* [ \[ ] \]} $target]*"

        set query "(id || ' ' || stamp || ' ' || rtype || ' ' || title"

        if {!$searchInfo(TitleOnlyFlag)} {
            append query " || ' ' || text"
        }

        append query ") GLOB '$pattern'"

        set searchInfo(QueryString) $query

        # NEXT, do the search by loading the current bin.
        $self LoadBin
    }

    # SearchClear
    #
    # Deletes the search text.

    method SearchClear {} {
        $search clear

        if {$searchInfo(QueryString) ne ""} {
            set searchInfo(QueryString) {}
            $self LoadBin
        }
    }

    # SearchAgain
    #
    # Does another search, taking changed settings into account.

    method SearchAgain {} {
        $self SearchDoSearch [$search get]
    }

    #-------------------------------------------------------------------
    # Public Methods

    # connect dbname
    #
    # dbname      The name of the run-time database object.
    #
    # Connect to the database.
    
    method refresh {dbname} {
        # FIRST, get the database.
        set db $dbname

        # NEXT, notify the reportviewer of the change
        $viewer configure -db $db

        # NEXT, get the initial set of reports.
        $bintree refresh
    }

    # refresh
    #
    # Refresh from the database.  Reload all bins, and
    # view reports.
    
    method refresh {} {
        $bintree refresh
    }


    # setbin bin
    #
    # Selects and displays the named bin.
    
    method setbin {bin} {
        $bintree set $bin
        update idletasks  ;# TBD: Needed?
    }

    # menuitem showrecent menu args
    #
    # menu        The menu to which the item should be added
    # args        Menu option settings.
    #
    # Adds a menu item for the showrecent flag to a menu.
    
    method {menuitem showrecent} {menu args} {
        array set opts {
            -label      "Recent Reports Only"
            -underline  0
        }

        array set opts $args

        set opts(-variable) [myvar options(-showrecent)]
        set opts(-command)  [mymethod LoadBin]

        eval $menu add checkbutton [array get opts]
    }

    # menuitem scrolllock menu args
    #
    # menu        The menu to which the item should be added
    # args        Menu option settings.
    #
    # Adds a menu item for the showrecent flag to a menu.
    
    method {menuitem scrolllock} {menu args} {
        array set opts {
            -label      "Scroll Lock"
            -underline  0
        }

        array set opts $args

        set opts(-variable) [myvar options(-scrolllock)]
        set opts(-command)  [mymethod UpdateScrollLock]

        eval $menu add checkbutton [array get opts]
    }

}

