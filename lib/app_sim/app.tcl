#-----------------------------------------------------------------------
# FILE: app.tcl
#
#   Application Ensemble.
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Required Packages

# All needed packages are required in app_sim.tcl.
 
#-----------------------------------------------------------------------
# Module: app
#
# app_sim(n) Application Ensemble
#
# This module defines app, the application ensemble.  app encapsulates 
# all of the functionality of athena_sim(1), including the application's 
# start-up behavior.  To invoke the  application,
#
# > package require app_sim
# > app init $argv
#
# The app_sim(n) package can be invoked by athena(1) and by 
# athena_test(1).

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Group: Global Lookup Variables

    # Type Variable: derivedfg
    #
    # The foreground color for derived data (as opposed to input data).
    # This color is used by a variety of data browsers throughout the
    # application.  TBD: Consider making this a preference.

    typevariable derivedfg "#008800"

    #-------------------------------------------------------------------
    # Group: Type Variables

    # Type Variable: opts
    #
    # Application command-line options.
    #
    # -batch           - If 1, run in batch mode.
    # 
    # -dev             - If 1, run in development mode (e.g., include 
    #                    debugging log in appwin)
    #
    # -ignoreuser      - If 1, ignore user preferences, etc.
    #                    Used for testing.
    #
    # -threads         - If 1, the app runs multi-threaded.
    #
    # -script filename - The name of a script to execute at start-up,
    #                    after loading the scenario file (if any).

    typevariable opts -array {
        -batch      0
        -dev        0
        -ignoreuser 0
        -threads    0
        -script     {}
    }

    #-------------------------------------------------------------------
    # Group: Application Initialization

    # Type Method: init
    #
    # Initializes the application.  This routine should be called once
    # at application start-up, and passed the arguments from the
    # shell command line.  In particular, it:
    #
    # * Determines where the application is installed.
    # * Creates a working directory.
    # * Opens the debugging log.
    # * Logs any loaded mods.
    # * Loads the user preferences, unless -ignoreuser is specified.
    # * Purges old working directories.
    # * Initializes the various application modules.
    # * Creates a number of statecontroller(n) objects to enable and
    #   disable various GUI components as application state changes.
    # * Sets the application icon.
    # * Opens the scenario specified on the command line, if any.
    #
    # Syntax:
    #   init _argv_
    #
    #   argv - Command line arguments (if any)
    #
    # See <usage> for the definition of the arguments.
    
    typemethod init {argv} {
        # FIRST, Process the command line.
        while {[string match "-*" [lindex $argv 0]]} {
            set opt [lshift argv]

            switch -exact -- $opt {
                -batch      -
                -dev        -
                -ignoreuser {
                    set opts($opt) 1
                }

                -threads    {
                    if {![catch {package require Thread}]} {
                        set opts($opt) 1
                    } else {
                        app exit "Multi-threading is not available."
                    }
                }

                -script {
                    set opts($opt) [lshift argv]
                }
                
                default {
                    app exit "Unknown option: \"$opt\"\n[app usage]"
                }
            }
        }

        if {[llength $argv] > 1} {
            app exit [app usage]
        }

        # NEXT, get the application directory
        appdir init

        # NEXT, create the working directory.
        if {[catch {workdir init} result]} {
            app exit {
                |<--
                Error, could not create working directory: 

                    [workdir join]

                Reason: $result
            }
        }

        # NEXT, Save the current PID to the workdir's parent directory
        # so that we can tell what the most recently used working directory 
        # was.  (Note that the parent directory is also an Athena-specific
        # directory.)

        set f [open [workdir join .. pid.txt] w]
        puts $f "pid=[pid] ts=[clock seconds]"
        close $f

        # NEXT, create the preferences directory.
        if {[catch {prefsdir init} result]} {
            app exit {
                |<--
                Error, could not create preferences directory: 

                    [prefsdir join]

                Reason: $result
            }
        }

        # NEXT, open the debugging log.
        log init $opts(-threads)

        # NEXT, log any loaded mods
        if {[namespace exists ::athena_mods::]} {
            ::athena_mods::logmods
        }

        # NEXT, initialize and load the user preferences
        prefs init
        
        if {!$opts(-ignoreuser)} {
            prefs load
        }

        prefs configure -notifycmd \
            [list notifier send ::app <Prefs>]

        # NEXT, purge old working directories
        workdir purge [prefs get session.purgeHours]


        # NEXT, enable notifier(n) tracing
        notifier trace [myproc NotifierTrace]

        # NEXT, configure the simclock with a default tick size of
        # one week
        ::simclock configure -tick {7 days}

        # NEXT, Create the working scenario RDB and initialize simulation
        # components
        executive init
        parm      init master
        map       init
        view      init
        cif       init
        order     init \
            -cancelstates {PREP PAUSED}          \
            -subject      ::order                \
            -rdb          ::rdb                  \
            -clock        ::simclock             \
            -usedtable    entities               \
            -logcmd       ::log                  \
            -ordercmd     [myproc AddOrderToCIF]
        scenario  init \
            -ignoredefaultparms $opts(-ignoreuser)
        firings   init
        nbhood    init
        sim       init

        # NEXT, register my:// servers with myagent.
        appserver init
        myagent register app ::appserver
        myagent register help \
            [helpserver %AUTO% \
                 -helpdb    [appdir join docs help athena.helpdb] \
                 -headercmd [mytypemethod HelpHeader]]
        myagent register rdb \
            [rdbserver %AUTO% -rdb ::rdb]

        # NEXT, define order interfaces

        # app: For internal orders
        order interface configure app \
            -errorcmd  [myproc UnexpectedOrderError]

        # gui: For user orders from the GUI
        order interface configure gui \
            -checkstate  yes                           \
            -trace       yes                           \
            -errorcmd    [myproc UnexpectedOrderError]

        # cli: For user orders from the CLI
        order interface add cli \
            -checkstate  yes                            \
            -trace       yes                            \
            -rejectcmd   [myproc FormatRejectionForCLI] \
            -errorcmd    [myproc UnexpectedOrderError]

        # raw: Like CLI, but with no special rejection formatting.
        # Used by "send" executive command.
        order interface add raw \
            -checkstate  yes    \
            -trace       yes

        # tactic: Like raw, but does not trace; used by "send"
        # when the order state is TACTIC.
        order interface add tactic \
            -checkstate  yes

        # test: For orders from the test suite.  No special handling
        # for unexpected errors, and no transactions, so that errors
        # remain in place.
        order interface add test \
            -checkstate  yes     \
            -trace       yes     \
            -transaction no

        # NEXT, initialize the order dialog manager
        orderdialog init \
            -parent    .main              \
            -appname   "Athena [version]" \
            -helpcmd   [list app help]    \
            -refreshon {
                ::cif <Update>
                ::sim <Tick>
                ::sim <DbSyncB>
            }

        # NEXT, bind components together
        notifier bind ::sim <State> ::order {::order state [::sim state]}
        notifier bind ::app <Puck>  ::order {::order puck}

        # NEXT, define custom field types for use in order dialogs.
        $type RegisterCustomFieldTypes

        # NEXT, create state controllers, to enable and disable
        # GUI components as application state changes.
        $type CreateStateControllers
        
        # NEXT, Create the main window, and register it as a saveable.
        # It does not, in fact, contain any scenario data; but this allows
        # us to capture the user's "session" as part of the scenario file.
        wm withdraw .

        if {!$opts(-batch)} {
            appwin .main -dev $opts(-dev)
            scenario register .main
        }


        # NEXT, log that we're up.
        log normal app "Athena [version]"

        # NEXT, if a scenario file is specified on the command line,
        # open it.
        if {[llength $argv] == 1} {
            scenario open [file normalize [lindex $argv 0]]
        } else {
            # This makes sure that the notifier events are sent that
            # initialize the user interface.
            sim dbsync
        }

        # NEXT, if there's a script, execute it.
        if {$opts(-script) ne ""} {
            if {[catch {
                executive eval [list call $opts(-script)]
            } result eopts]} {
                if {[dict get $eopts -errorcode] eq "REJECT"} {
                    set message {
                        |<--
                        Order rejected in -script:

                        $result
                    }

                    if {$opts(-batch)} {
                        app exit $message
                    } else {
                        app error $message
                    }
                } elseif {$opts(-batch)} {
                    app exit {
                        |<--
                        Error in -script:
                        $result

                        Stack Trace:
                        [dict get $eopts -errorinfo]
                    }
                } else {
                    log error app "Unexpected error in -script:\n$result"
                    log error app "Stack Trace:\n[dict get $eopts -errorinfo]"
                    
                    after idle {[app topwin] tab view slog}
                    
                    app error {
                        |<--
                        Unexpected error during the execution of
                        -script $opts(-script).  See the 
                        Log for details.
                    }
                }
            }
        }

        # NEXT, if we're in batch mode, exit; we're done.
        if {$opts(-batch)} {
            app exit
        }
    }

    # AddOrderToCIF interface name parmdict undoScript
    #
    # interface  - The interface by which the order was sent
    # name       - The order name
    # parmdict   - The order parameters
    # undoScript - The order's undo script, or "" if not undoable.
    #
    # Adds accepted orders to the CIF, export for REPORT:* orders,
    # which don't modify the RDB and hence don't need to be CIF'd.

    proc AddOrderToCIF {interface name parmdict undoScript} {
        if {![string match "REPORT:*" $name]} {
            cif add $name $parmdict $undoScript
        }
    }


    # UnexpectedOrderError name errmsg
    #
    # name    - The order name
    # errmsg  - The error message
    # einfo   - Error info (the stack trace)
    #
    # Handles unexpected order errors.

    proc UnexpectedOrderError {name errmsg einfo} {
        log error app "Unexpected error in $name:\n$errmsg"
        log error app "Stack Trace:\n$einfo"

        [app topwin] tab view slog

        app error {
            |<--
            $name

            There was an unexpected error during the 
            handling of this order.  The scenario has 
            been rolled back to its previous state, so 
            the application data  should not be 
            corrupted.  However:

            * You should probably save the scenario under
              a new name, just in case.

            * The error has been logged in detail.  Please
              contact JPL to get the problem fixed.
        }

        if {[sim state] eq "RUNNING"} {
            sim mutate pause
        }

        sim dbsync

        return "Unexpected error while handling order."
    }

    # FormatRejectionForCLI errdict
    #
    # errdict     A REJECT error dictionary
    #
    # Formats the rejection error dictionary for display at the console.
    
    proc FormatRejectionForCLI {errdict} {
        if {[dict exists $errdict *]} {
            lappend out [dict get $errdict *]
        }

        dict for {parm msg} $errdict {
            if {$parm ne "*"} {
                lappend out "$parm: $msg"
            }
        }

        return [join $out \n]
    }

    # RegisterCustomFieldTypes
    #
    # Registers custom field types with form(n)/orderdialog(n),
    # for use in order dialogs.

    typemethod RegisterCustomFieldTypes {} {
        # actor -- Actor IDs
        form register actor ::marsgui::keyfield \
            -table actors                       \
            -keys  a

        orderdialog fieldopts actor \
            -db ::rdb

        # agent -- Agent IDs
        form register agent ::marsgui::keyfield \
            -table agents                       \
            -keys  agent_id

        orderdialog fieldopts agent \
            -db ::rdb

        # command -- Executive Command
        form register command ::marsgui::textfield \
            -width 40

        # coop -- Cooperation Values
        form register coop ::marsgui::rangefield \
            -type        ::qcooperation          \
            -showsymbols yes                     \
            -resetvalue  50

        # expr -- Expression
        form register expr ::marsgui::textfield \
            -width 60

        # frac -- Fractions, 0.0 to 1.0
        form register frac ::marsgui::rangefield \
            -type        ::rfraction

        # glist -- listfield of appropriate size for group selection
        form register glist ::marsgui::listfield \
            -height      8                       \
            -width       30

        # goal -- Goal IDs
        form register goal ::marsgui::keyfield \
            -table goals                       \
            -keys  goal_id

        orderdialog fieldopts goal \
            -db ::rdb

        # goals -- listfield of appropriate size for goal selection
        form register goals ::marsgui::listfield \
            -height      8                       \
            -width       30

        # mag -- qmag(n) values
        form register mag ::marsgui::rangefield \
            -type        ::qmag                 \
            -showsymbols yes                    \
            -resetvalue  0.0                    \
            -resolution  0.5                    \
            -min         -40.0                  \
            -max         40.0

        # nlist -- listfield of appropriate size for nbhood selection
        form register nlist ::marsgui::listfield \
            -height      8                       \
            -width       50

        # pct -- Percentages, 0 to 100
        form register pct ::marsgui::rangefield \
            -type        ::ipercent             

        orderdialog fieldopts pct \
            -resetvalue %?-defval

        # rel -- Relationships, -1.0 to 1.0
        form register rel ::marsgui::rangefield \
            -type        ::qrel                 \
            -resolution  0.1

        # sat -- Satisfaction values
        form register sat ::marsgui::rangefield \
            -type        ::qsat                 \
            -showsymbols yes
    }

    # CreateStateControllers
    #
    # Creates a family of statecontroller(n) objects to manage
    # the state of GUI components as the application state changes.

    typemethod CreateStateControllers {} {
        namespace eval ::cond { }

        # Simulation state is PREP.

        statecontroller ::cond::simIsPrep -events {
            ::sim <State>
        } -condition {
            [::sim state] eq "PREP"
        }

        # Simulation state is PREP, plus browser predicate

        statecontroller ::cond::simPrepPredicate -events {
            ::sim <State>
        } -condition {
            [::sim state] eq "PREP" &&
            [$browser {*}$predicate]
        }

        # Simulation state is not RUNNING.

        statecontroller ::cond::simNotRunning -events {
            ::sim <State>
        } -condition {
            [::sim state] ne "RUNNING"
        }

        # Simulation state is PREP or PAUSED

        statecontroller ::cond::simPrepPaused -events {
            ::sim <State>
        } -condition {
            [::sim state] in {PREP PAUSED}
        }

        # Simulation state is PREP or PAUSED, plus browser predicate

        statecontroller ::cond::simPP_predicate -events {
            ::sim <State>
        } -condition {
            [::sim state] in {PREP PAUSED} &&
            [$browser {*}$predicate]
        }

        # Order is available in the current state.
        #
        # Objdict:   order   THE:ORDER:NAME

        statecontroller ::cond::available -events {
            ::order <State>
        } -condition {
            [::order available $order]
        }

        # Order is available, one browser entry is selected.  The
        # browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::availableSingle -events {
            ::order <State>
        } -condition {
            [::order available $order]                &&
            [llength [$browser curselection]] == 1
        }

        # Order is available, one or more browser entries are selected.  The
        # browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::availableMulti -events {
            ::order <State>
        } -condition {
            [::order available $order]              &&
            [llength [$browser curselection]] > 0
        }

        # Order is available, and the selection is deletable.
        # The browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::availableCanDelete -events {
            ::order <State>
        } -condition {
            [::order available $order] &&
            [$browser candelete]
        }

        # Order is available, and the selection is updateable.
        # The browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::availableCanUpdate -events {
            ::order <State>
        } -condition {
            [::order available $order] &&
            [$browser canupdate]
        }

        # Order is available, and the selection can be resolved.
        # The browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::availableCanResolve -events {
            ::order <State>
        } -condition {
            [::order available $order] &&
            [$browser canresolve]
        }
    }

    # Type Method: usage
    #
    # Returns the application's command-line syntax.
    
    typemethod usage {} {
        append usage \
            "Usage: athena ?options...? ?scenario.adb?\n"               \
            "\n"                                                        \
            "-batch              Executed Athena in batch mode.\n"      \
            "-script filename    A script to execute after loading\n"   \
            "                    the scenario file (if any).\n"         \
            "-dev                Turns on all developer tools (e.g.,\n" \
            "                    the CLI and scrolling log)\n"          \
            "-ignoreuser         Ignore preference settings.\n"         \
            "-threads            Run Athena multi-threaded.\n"          \
            "\n"                                                        \
            "See athena(1) for more information.\n"
    }

    # Type Method: NotifierTrace
    #
    # A notifier(n) trace command that logs all notifier events.
    #
    # Syntax:
    #   NotifierTrace _subject event eargs objects_

    proc NotifierTrace {subject event eargs objects} {
        set objects [join $objects ", "]
        log detail notify "send $subject $event [list $eargs] to $objects"
    }

    # HelpHeader udict
    #
    # Formats a custom header for help pages.

    typemethod HelpHeader {udict} {
        set out "<b><font size=2>Athena [version] Help</b>"
        append out "<hr><p>\n"
        
        return $out
    }

    #-------------------------------------------------------------------
    # Group: Utility Type Methods
    #
    # This routines are application-specific utilities provided to the
    # rest of the application.

    # help title
    #
    # title  - A help page title
    #
    # Shows a page with the desired title, if any, in the Detail Browser.

    typemethod help {{title ""}} {
        app show "my://help/?[string trim $title]"
    }

    # Type Method: puts
    #
    # Writes the _text_ to the message line of the topmost appwin.
    # This is a no-op in batch mode.
    #
    # Syntax: 
    #   puts _text_
    #
    #   text - A text string

    typemethod puts {text} {
        if {!$opts(-batch)} {
            set topwin [app topwin]

            if {$topwin ne ""} {
                $topwin puts $text
            }
        }
    }

    # Type Method: error
    #
    # Normally, displays the error _text_ in a message box.  In 
    # batchmode, calls [app exit].
    #
    # Syntax:
    #   error _text_
    #
    #   text - A tsubst'd text string

    typemethod error {text} {
        if {$opts(-batch)} {
            # Uplevel, so that [app exit] can expand the text.
            uplevel 1 [list app exit $text]
        } else {
            set topwin [app topwin]

            if {$topwin ne ""} {
                uplevel 1 [list [app topwin] error $text]
            } else {
                error $text
            }
        }
    }

    # Type Method: exit
    #
    # Exits the program,writing the text (if any) to standard output.
    # Saves the CLI's command history for the next session.
    #
    # Syntax:
    #   exit _?text?_
    #
    #   text - Optional error message, tsubst'd

    typemethod exit {{text ""}} {
        # FIRST, output the text.  In batch mode, write it to
        # error.log.
        if {$text ne ""} {
            set text [uplevel 1 [list tsubst $text]]

            if {!$opts(-batch)} {
                app DisplayExitText $text
            } else {
                app DisplayExitText \
                    "Error; see [file join [pwd] error.log] for details."
                set f [open "error.log" w]
                puts $f $text
                close $f
            }
        }

        # NEXT, save the CLI history, if any.
        if {!$opts(-ignoreuser) && [winfo exists .main]} {
            .main savehistory
        }

        # NEXT, release any threads
        log release

        # NEXT, exit
        if {$text ne ""} {
            exit 1
        } else {
            exit
        }
    }

    # DisplayExitText text...
    #
    # text - An exit message: multiple lines, each as a separate arg.
    #
    # Displays the [app exit] text appropriately for the platform.

    typemethod DisplayExitText {args} {
        set text [join $args \n]

        if {[os type] ne "win32"} {
            puts $text
        } else {
            wm withdraw .
            modaltextwin popup \
                -title   "Athena is shutting down" \
                -message $text
        }
    }

    # Type Method: topwin
    #
    # If there's no subcommand, returns the name of the topmost appwin.
    # Otherwise, delegates the subcommand to the top win.  If there is
    # no top win, this is a noop.
    #
    # Syntax:
    #   topwin _?subcommand...?_
    #
    #   subcommand - A subcommand of the topwin, as one argument or many

    typemethod topwin {args} {
        # FIRST, determine the topwin
        set topwin ""

        foreach w [lreverse [wm stackorder .]] {
            if {[winfo class $w] eq "Appwin"} {
                set topwin $w
                break
            }
        }

        if {[llength $args] == 0} {
            return $topwin
        } elseif {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        return [$topwin {*}$args]
    }

    # show uri
    #
    # uri - A URI for some application resource
    #
    # Shows the URI in some way.  If it's a "gui:" URI, tries to
    # display it as a tab or order dialog.  Otherwise, it passes it
    # to the Detail browser.

    typemethod show {uri} {
        # FIRST, if there's no main window, just return.
        # (This happens in batchmode, or when athena_test(1) runs the 
        # test suite.)

        if {![winfo exists .main]} {
            return
        }

        # NEXT, get the scheme.  If it's not a gui:, punt to 
        # the Detail browser.

        if {[catch {
            array set parts [uri::split $uri]
        }]} {
            # Punt to normal error handling
            $type ShowInDetailBrowser $uri
            return
        }

        # NEXT, if the scheme isn't "gui", show in detail browser.
        if {$parts(scheme) ne "gui"} {
            $type ShowInDetailBrowser $uri
            return
        }

        # NEXT, what kind of "gui" url is it?

        if {[regexp {^tab/(\w+)$} $parts(path) dummy tab]} {
            if {[.main tab exists $tab]} {
                .main tab view $tab
            } else {
                # Punt
                $type GuiUrlError $uri "No such application tab"
            }
            return
        }

        if {[regexp {^order/([A-Za-z0-9:]+)$} $parts(path) dummy order]} {
            set order [string toupper $order]

            if {[order exists $order]} {
                set parms [split $parts(query) "=+"]
                if {[catch {
                    order enter $order {*}$parms
                } result]} {
                    $type GuiUrlError $uri $result
                }
            } else {
                # Punt
                $type GuiUrlError $uri "No such order"
            }
            return
        }

        # NEXT, unknown kind of win; punt to normal error handling.
        $type GuiUrlError $uri "No such window"
    }

    # ShowInDetailBrowser uri
    #
    # uri - A URI for some application resource
    #
    # Shows the URI in the Detail browser.

    typemethod ShowInDetailBrowser {uri} {
        [.main tab win detail] show $uri
        .main tab view detail
    }

    # GuiUrlError uri message
    #
    # uri     - A URI for a window we don't have.
    # message - A specific error message
    #
    # Shows an error.

    typemethod GuiUrlError {uri message} {
        app error {
            |<--
            Error in URI:
            
            $uri

            The requested gui:// URL cannot be displayed by the application:

            $message
        }
    }
    
}


#-----------------------------------------------------------------------
# Section: Miscellaneous Application Utility Procs

# profile ?depth? command ?args...?
#
# Calls the command once using [time], in the caller's context,
# and logs the outcome, returning the command's return value.
# In other words, you can stick "profile" before any command name
# and profile that call without changing code or adding new routines.
#
# If the depth is given, it must be an integer; that many "*" characters
# are added to the beginning of the log message.

proc profile {args} {
    if {[string is integer -strict [lindex $args 0]]} {
        set prefix "[string repeat * [lshift args]] "
    } else {
        set prefix ""
    }

    set msec [lindex [time {
        set result [uplevel 1 $args]
    } 1] 0]

    log detail app "${prefix}profile [list $args] $msec"

    return $result
}


# Proc: bgerror
#
# Logs background errors; the errorInfo is stored in ::bgErrorInfo
#
# Syntax:
#   bgerror _msg_

proc bgerror {msg} {
    global errorInfo
    global bgErrorInfo

    set bgErrorInfo $errorInfo
    log error app "bgerror: $msg"
    log error app "Stack Trace:\n$bgErrorInfo"

    if {[sim state] eq "RUNNING"} {
        # TBD: might need to send order?
        sim mutate pause
    }

    if {$app::opts(-batch)} {
        # app exit subst's in the caller's context
        app exit {$msg\n\nStack Trace:\n$bgErrorInfo}
    } elseif {[app topwin] ne ""} {
        [app topwin] tab view slog

        app error {
            |<--
            An unexpected error has occurred;
            please see the log for details.
        }
    } else {
        puts "bgerror: $msg"
        puts "Stack Trace:\n$bgErrorInfo"
    }
}


