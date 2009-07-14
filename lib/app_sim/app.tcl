#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Application Ensemble
#
#    This module defines app, the application ensemble.  app encapsulates 
#    all of the functionality of athena_sim(1), including the application's 
#    start-up behavior.  To invoke the  application,
#
#        package require app_sim
#        app init $argv
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Required Packages

# All needed packages are required in app_sim.tcl.
 
#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Variables

    # Application options
    #
    # -ignoreuser     If yes, ignore user preferences, etc.

    typevariable opts -array {
        -ignoreuser no
    }

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv  Command line arguments (if any)
    #
    # Initializes the application.
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

        # NEXT, initialize and load the user preferences
        prefs init
        
        if {!$opts(-ignoreuser)} {
            prefs load
        }

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
        scenario  init -ignoredefaultparms $opts(-ignoreuser)
        cif       init
        order     init
        report    init
        dam       init
        demog     init
        aam       init
        aam_rules init
        nbhood    init
        nbrel     init
        group     init
        civgroup  init
        frcgroup  init
        orggroup  init
        nbgroup   init
        sat       init
        rel       init
        coop      init
        sim       init

        # NEXT, bind components together
        notifier bind ::sim <State> ::order {::order state [::sim state]}

        # NEXT, define global conditions
        namespace eval ::cond { }

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
        }
    }

    # NotifierTrace subject event eargs objects
    #
    # A notifier(n) trace command

    proc NotifierTrace {subject event eargs objects} {
        set objects [join $objects ", "]
        log detail notify "send $subject $event [list $eargs] to $objects"
    }


    #-------------------------------------------------------------------
    # Utility Type Methods

    # usage
    #
    # Displays the application's command-line syntax
    
    typemethod usage {} {
        puts "Usage: athena sim ?scenario.adb?"
        puts ""
        puts "See athena_sim(1) for more information."
    }

    # help ?page?
    #
    # page    A helpdb(n) page ID
    #
    # Pops up the helpbrowserwin on the specified page.

    typemethod help {{page home}} {
        helpbrowserwin showhelp $page
    }

    # puts text
    #
    # text     A text string
    #
    # Writes the text to the message line of the topmost appwin.

    typemethod puts {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            $topwin puts $text
        }
    }

    # error text
    #
    # text       A tsubst'd text string
    #
    # Displays the error in a message box

    typemethod error {text} {
        set topwin [app topwin]

        if {$topwin ne ""} {
            uplevel 1 [list [app topwin] error $text]
        } else {
            error $text
        }
    }

    # exit ?text?
    #
    # Optional error message, tsubst'd
    #
    # Exits the program

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

    # topwin ?subcommand...?
    #
    # subcommand    A subcommand of the topwin, as one argument or many
    #
    # If there's no subcommand, returns the name of the topmost appwin.
    # Otherwise, delegates the subcommand to the top win.  If there is
    # no top win, this is a noop.

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
# Miscellaneous Application Utilities

# profile command ?args...?
#
# command    A command
# args       Arguments to the command
#
# Calls the command once using [time], in the caller's context,
# and logs the outcome, returning the command's return value.
# In other words, you can stick "profile" before any command name
# and profile that call without changing code or adding new routines.

proc profile {args} {
    set msec [lindex [time {
        set result [uplevel 1 $args]
    } 1] 0]
    log normal app "profile [list $args] $msec"

    return $result
}


# bgerror msg
#
# Logs background errors; the errorInfo is stored in ::bgErrorInfo

proc bgerror {msg} {
    global errorInfo
    global bgErrorInfo

    set bgErrorInfo $errorInfo
    log error app "bgerror: $msg"
    log error app "Stack Trace:\n$bgErrorInfo"

    [app topwin] tab view slog

    if {[sim state] eq "RUNNING"} {
        # TBD: might need to send order?
        sim mutate pause
    }

    app error {
        |<--
        An unexpected error has occurred;
        please see the log for details.
    }
}





