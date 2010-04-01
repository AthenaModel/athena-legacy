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
    # -ignoreuser -  Boolean. If yes, ignore user preferences, etc.
    #                Used for testing.

    typevariable opts -array {
        -ignoreuser no
    }

    #-------------------------------------------------------------------
    # Group: Application Initialization

    # Type Method: init
    #
    # Initializes the applieconcation.  This routine should be called once
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
                -ignoreuser {
                    set opts(-ignoreuser) yes
                }
                
                default {
                    puts "Unknown option: \"$opt\""
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
        scenario  init -ignoredefaultparms $opts(-ignoreuser)
        cif       init
        order     init
        report    init
        nbhood    init
        sim       init

        # NEXT, bind components together
        notifier bind ::sim <State> ::order {::order state [::sim state]}

        # NEXT, define global conditions
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

        # Order is valid.
        #
        # Objdict:   order   THE:ORDER:NAME

        statecontroller ::cond::orderIsValid -events {
            ::order <State>
        } -condition {
            [::order isvalid $order]
        }

        # Order is valid, one browser entry is selected.  The
        # browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::orderIsValidSingle -events {
            ::order <State>
        } -condition {
            [::order isvalid $order]                &&
            [llength [$browser curselection]] == 1
        }

        # Order is valid, one or more browser entries are selected.  The
        # browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::orderIsValidMulti -events {
            ::order <State>
        } -condition {
            [::order isvalid $order]              &&
            [llength [$browser curselection]] > 0
        }

        # Order is valid, and the selection is deletable.
        # The browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::orderIsValidCanDelete -events {
            ::order <State>
        } -condition {
            [::order isvalid $order] &&
            [$browser candelete]
        }

        # Order is valid, and the selection is updateable.
        # The browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::orderIsValidCanUpdate -events {
            ::order <State>
        } -condition {
            [::order isvalid $order] &&
            [$browser canupdate]
        }

        # Order is valid, and the selection can be resolved.
        # The browser should call update for its widgets.
        #
        # Objdict:   order     THE:ORDER:NAME
        #            browser   The browser window

        statecontroller ::cond::orderIsValidCanResolve -events {
            ::order <State>
        } -condition {
            [::order isvalid $order] &&
            [$browser canresolve]
        }


        # NEXT, Withdraw the default toplevel window, and create 
        # the main GUI components.
        wm withdraw .
        appwin .main -main yes

        # NEXT, set the icon for this and subsequent windows.
        # TBD: Should this be done in appwin?
        set icon [image create photo \
                      -file [file join $::app_sim::library icon.png]]
        wm iconphoto .main -default $icon

        # NEXT, initialize the order GUI
        orderdialog init
        
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
    }

    # Type Method: usage
    #
    # Displays the application's command-line syntax.
    
    typemethod usage {} {
        puts "Usage: athena sim ?-ignoreuser? ?scenario.adb?"
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
    log normal app "profile [list $args] $msec"

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





