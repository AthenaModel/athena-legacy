#-----------------------------------------------------------------------
# FILE: app.tcl
#
#   Engine thread app object
#
# PACKAGE:
#   app_sim_engine(n) -- athena(1) Engine thread main package.
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app -- app_sim_engine(n) App Object
#
# This module defines ::app, the thread's app object. ::app
# encapsulates all of the functionality of the Engine thread, 
# including the thread's start-up behavior.  To invoke the thread,
#
#     thread::create "
#         lappend auto_path <libdirs>
#         package require app_sim_engine
#
#         app init -appthread [thread::id] TBD
#         thread::wait
#     "
#
# This thread is created and managed by the App thread's ::engine object,
# to which this thread sends notifications.


snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # opts array - Thread configuration options
    #
    # -appthread  - The thread ID of the App thread.

    typevariable opts -array {
        -appthread  ""
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
                -appthread {
                    set opts($opt) [lshift args]
                }
                
                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        require {$opts(-appthread) ne ""} "-appthread not specified"
        
        # TBD
    }
}




