#-----------------------------------------------------------------------
# FILE: app.tcl
#
#   Logger thread app object
#
# PACKAGE:
#   app_sim_logger(n) -- athena(1) Logger thread main package.
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app -- app_sim_logger(n) App Object
#
# This module defines ::app, the thread's app object. ::app
# encapsulates all of the functionality of the Logger thread, 
# including the thread's start-up behavior.  To invoke the thread,
#
#     thread::create "
#         lappend auto_path <libdirs>
#         package require app_sim_logger
#
#         app init -appthread [thread::id] -logdir $logdir ...
#         thread::wait
#     "
#
# See below for the full list of options.
#
# This thread is created and managed by the App thread's ::log object,
# to which this thread sends notifications.  Other worker threads can
# send log entries to this thread by using
#
#    thread::send -async $tid [list log $level $component $message]

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent logger      ;# The logger(n) instance

    #-------------------------------------------------------------------
    # Type Variables

    # opts array - Thread configuration options
    #
    # -appthread  - The thread ID of the App thread.
    # -logdir     - The absolute path of the log directory, which should
    #               already exist.
    # -newlogcmd  - App thread command to call when there's a new log file.
    # -t0         - Simulation start date.

    typevariable opts -array {
        -appthread  ""
        -logdir     ""
        -newlogcmd  ""
        -t0         ""
    }

    #-------------------------------------------------------------------
    # Application Initialization

    # init options...
    #
    # options - The options listed in the opts array, above.
    #
    # Initializes the thread.  This routine should be called once
    # at thread start-up.  
    
    typemethod init {args} {
        # FIRST, get the options
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -appthread -
                -logdir    -
                -newlogcmd -
                -t0        {
                    set opts($opt) [lshift args]
                }
                
                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        require {$opts(-appthread) ne ""} "-appthread not specified"
        require {$opts(-logdir) ne ""}    "-logdir not specified"
        require {$opts(-t0) ne ""}        "-t0 not specified"

        # NEXT, configure the simclock.
        simclock configure -t0 $opts(-t0)
        simclock reset

        # NEXT, open the debugging log.
        logger ::log                                           \
            -simclock   ::simclock                             \
            -logdir     $opts(-logdir)                         \
            -newlogcmd  [mytypemethod NewLogCmd]

        set logger ::log

        # NEXT, log that the logger is available.
        log normal Logger "Opened new log file"
    }

    # simtime t0 now
    #
    # t0     - The new startdate
    # now    - The new simulation time
    #
    # Resets the simclock to the App thread's current simulation time.

    typemethod simtime {t0 now} {
        simclock configure -t0 $t0
        simclock reset
        simclock advance $now
    }

    #-------------------------------------------------------------------
    # Private Type Methods

    # NewLogCmd filename
    #
    # filename  - Name of the new log file.
    #
    # Notifies the application thread that there is a new log file.
    
    typemethod NewLogCmd {filename} {
        if {$opts(-newlogcmd) ne ""} {
            thread::send -async $opts(-appthread) \
                [list {*}$opts(-newlogcmd) $filename]
        }
    }
}




