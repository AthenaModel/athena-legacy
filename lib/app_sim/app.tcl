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
    # -dev             - If 1, run in development mode (e.g., include 
    #                    debugging log in appwin)
    #
    # -ignoreuser      - If 1, ignore user preferences, etc.
    #                    Used for testing.
    #
    # -script filename - The name of a script to execute at start-up,
    #                    after loading the scenario file (if any).

    typevariable opts -array {
        -ignoreuser 0
        -dev        0
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
                -dev        -
                -ignoreuser {
                    set opts($opt) 1
                }

                -script {
                    set opts($opt) [lshift argv]
                }
                
                default {
                    puts "Unknown option: \"$opt\""
                    app usage
                    exit 1
                }
            }

        }

        if {[llength $argv] > 1} {
            app usage
            exit 1
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

        # NEXT, open the debugging log.
        logger ::log                                           \
            -simclock   ::simclock                             \
            -logdir     [workdir join log app_sim]             \
            -newlogcmd  [list notifier send $type <AppLogNew>]

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
        # TBD: If this proves slow, we can make it an idle process.
        workdir purge [prefs get session.purgeHours]


        # NEXT, enable notifier(n) tracing
        notifier trace [myproc NotifierTrace]

        # NEXT, Create the working scenario RDB and initialize simulation
        # components
        executive init
        parm      init
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
        report    init
        nbhood    init
        sim       init

        # NEXT, register my:// servers with myagent.
        myagent register app ::appserver

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
            -checkstate  yes                            \
            -trace       yes                            \
            -errorcmd    [myproc UnexpectedOrderError]

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
        appwin .main -dev $opts(-dev)
        scenario register .main



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
            executive eval [list call $opts(-script)]
        }
    }

    # AddOrderToCIF interface name parmdict undoScript
    #
    # interface  - The interface by which the order was sent
    # name       - The order name
    # parmdict   - The order parameters
    # undoScript - The order's undo script, or "" if not undoable.
    #
    # Adds accepted orders to the CIF.

    proc AddOrderToCIF {interface name parmdict undoScript} {
        cif add $name $parmdict $undoScript
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

        # coop -- Cooperation Values
        form register coop ::marsgui::rangefield \
            -type        ::qcooperation          \
            -showsymbols yes                     \
            -resetvalue  50

        # frac -- Fractions, 0.0 to 1.0
        form register frac ::marsgui::rangefield \
            -type        ::rfraction

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
    # Displays the application's command-line syntax.
    
    typemethod usage {} {
        puts "Usage: athena sim ?options...? ?scenario.adb?"
        puts ""
        puts "-script filename    A script to execute after loading"
        puts "                    the scenario file (if any)."
        puts "-dev                Turns on all developer tools (e.g.,"
        puts "                    the CLI and scrolling log)"
        puts "-ignoreuser         Ignore preference settings."
        puts ""
        puts "See athena_sim(1) for more information."
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


    #-------------------------------------------------------------------
    # Group: Utility Type Methods
    #
    # This routines are application-specific utilities provided to the
    # rest of the application.

    # Type Method: help
    #
    # Pops up the helpbrowserwin on the specified page.
    #
    # Syntax: 
    #   help _?page?_
    #
    #   page - A helpdb(n) page ID

    typemethod help {{page home}} {
        helpbrowserwin showhelp $page
    }

    # Type Method: cmdhelp
    #
    # Pops up the helpbrowserwin on the specified command,
    # or the Executive Commands page if no command was specified.
    #
    # Syntax:
    #   cmdhelp _?command?_
    #
    #   command - An executive command name

    typemethod cmdhelp {{command {}}} {
        # FIRST, just pop up the command help if no particular
        # command was requested.
        if {$command eq ""} {
            helpbrowserwin showhelp cmd
            return
        }

        # NEXT, do we have such a command?
        set page cmd.[join $command .]

        if {![helpbrowserwin exists $page]} {
            error "No help found: $command"
        }

        helpbrowserwin showhelp $page
    }


    # Type Method: puts
    #
    # Writes the _text_ to the message line of the topmost appwin.
    #
    # Syntax: 
    #   puts _text_
    #
    #   text - A text string

    typemethod puts {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            $topwin puts $text
        }
    }

    # Type Method: error
    #
    # Displays the error _text_ in a message box
    #
    # Syntax:
    #   error _text_
    #
    #   text - A tsubst'd text string

    typemethod error {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            uplevel 1 [list [app topwin] error $text]
        } else {
            error $text
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
        # FIRST, output the text.
        if {$text ne ""} {
            puts [uplevel 1 [list tsubst $text]]
        }

        # NEXT, save the CLI history, if any.
        if {!$opts(-ignoreuser)} {
            .main savehistory
        }

        # NEXT, exit
        exit
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
    # Shows the URI in some way.  If it's a "win:" URI, tries to
    # display it as a tab or order dialog.  Otherwise, it passes it
    # to the Detail browser.

    typemethod show {uri} {
        # FIRST, get the scheme.  If it's not a win:, punt to 
        # the Detail browser.

        if {[catch {
            array set parts [uri::split $uri]
        }]} {
            # Punt to normal error handling
            $type ShowInDetailBrowser $uri
        }

        # NEXT, if the scheme isn't "win", show in detail browser.
        if {$parts(scheme) ne "win"} {
            $type ShowInDetailBrowser $uri
        }

        # NEXT, what kind of "win" url is it?

        if {[regexp {^tab/(\w+)$} $parts(path) dummy tab]} {
            if {[.main tab exists $tab]} {
                .main tab view $tab
            } else {
                # Punt
                $type WinUrlError $uri "No such application tab"
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
                    $type WinUrlError $uri $result
                }
            } else {
                # Punt
                $type WinUrlError $uri "No such order"
            }
            return
        }

        # NEXT, unknown kind of win; punt to normal error handling.
        $type WinUrlError $uri "No such window"
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

    # WinUrlError uri message
    #
    # uri     - A URI for a window we don't have.
    # message - A specific error message
    #
    # Shows an error.

    typemethod WinUrlError {uri message} {
        app error {
            |<--
            Error in URI:
            
            $uri

            The requested window URL cannot be displayed by the application:

            $message
        }
    }
    
}


#-----------------------------------------------------------------------
# Section: Miscellaneous Application Utility Procs

# Proc: profile
#
# Calls the command once using [time], in the caller's context,
# and logs the outcome, returning the command's return value.
# In other words, you can stick "profile" before any command name
# and profile that call without changing code or adding new routines.
# TBD: Possibly, this should go in a "misc" module.
#
# Syntax:
#   profile _command ?args...?_
#
#   command - A command
#   args    - Arguments to the command

proc profile {args} {
    set msec [lindex [time {
        set result [uplevel 1 $args]
    } 1] 0]
    log detail app "profile [list $args] $msec"

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

    if {[app topwin] ne ""} {
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






