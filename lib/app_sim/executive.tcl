#-----------------------------------------------------------------------
# TITLE:
#    executive.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Executive Command Processor
#
#    The Executive is the program's command processor.  It's a singleton
#    that provides safe command interpretation for user input, separate
#    from the main interpreter.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# executive

snit::type executive {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Components

    typecomponent interp  ;# smartinterpreter(n) for processing commands.

    #-------------------------------------------------------------------
    # Instance Variables

    # Array of instance variables
    #
    #  userMode            normal | super
    #  stackTrace          Traceback for last error

    typevariable info -array {
        userMode     normal
        stackTrace   {}
    }
        

    #-------------------------------------------------------------------
    # Initialization
    
    typemethod init {} {
        log normal exec "Initializing"

        # FIRST, create the interpreter.  It's a safe interpreter but
        # most Tcl commands are retained, to allow scripting.  Allow
        # the "source" command.
        set interp [smartinterp ${type}::interp -cli yes]
        $interp expose file
        $interp expose pwd
        $interp expose source

        # NEXT, add commands that need to be defined in the slave itself.
        $interp proc call {script} {
            if {[file extension $script] eq ""} {
                append script ".tcl"
            }

            uplevel 1 [list source [file join [pwd] $script]]
        }

        # TBD: See if we like it!
        $interp proc select {args} {
            set query "SELECT $args"
            
            return [rdb query $query]
        }


        # NEXT, install the executive commands

        # =
        $interp smartalias = 1 - {expression...} \
            ::expr

        # debug
        $interp smartalias debug 0 0 {} \
            [list ::marsgui::debugger new]

        # errtrace
        $interp smartalias errtrace 0 0 {} \
            [mytypemethod errtrace]

        # help
        $interp smartalias help 0 - {?-info? ?command...?} \
            [mytypemethod help]

        # parm
        $interp ensemble parm

        # parm defaults
        $interp ensemble {parm defaults}

        # parm defaults clear
        $interp smartalias {parm defaults clear} 0 0 {} \
            [list ::parm defaults clear]

        # parm defaults save
        $interp smartalias {parm defaults save} 0 0 {} \
            [list ::parm defaults save]

        # parm export
        $interp smartalias {parm export} 1 1 {filename} \
            [list ::parm save]

        # parm get
        $interp smartalias {parm get} 1 1 {parm} \
            [list ::parm get]

        # parm import
        $interp smartalias {parm import} 1 1 {filename} \
            [list ::parm exec import]

        # parm list
        $interp smartalias {parm list} 0 1 {?pattern?} \
            [list ::parm exec list]

        # parm names
        $interp smartalias {parm names} 0 1 {?pattern?} \
            [list ::parm names]

        # parm reset
        $interp smartalias {parm reset} 0 0 {} \
            [list ::parm exec reset]

        # parm set
        $interp smartalias {parm set} 2 2 {parm value} \
            [list ::parm exec set]

        # prefs
        $interp ensemble prefs

        # prefs get
        $interp smartalias {prefs get} 1 1 {prefs} \
            [list prefs get]

        # prefs help
        $interp smartalias {prefs help} 1 1 {parm} \
            [list prefs help]

        # prefs list
        $interp smartalias {prefs list} 0 1 {?pattern?} \
            [list prefs list]

        # prefs names
        $interp smartalias {prefs names} 0 1 {?pattern?} \
            [list prefs names]

        # prefs reset
        $interp smartalias {prefs reset} 0 0 {} \
            [list prefs reset]

        # prefs set
        $interp smartalias {prefs set} 2 2 {prefs value} \
            [list prefs set]

        # rdb
        $interp ensemble rdb

        # rdb eval
        $interp smartalias {rdb eval}  1 1 {sql} \
            [list ::rdb safeeval]

        # rdb query
        $interp smartalias {rdb query} 1 1 {sql} \
            [list ::rdb safequery]

        # rdb schema
        $interp smartalias {rdb schema} 0 1 {?table?} \
            [list ::rdb schema]

        # rdb tables
        $interp smartalias {rdb tables} 0 0 {} \
            [list ::rdb tables]

        # super
        $interp smartalias super 1 - {arg ?arg...?} \
            [myproc super]

        # usermode
        $interp smartalias {usermode} 0 1 {?mode?} \
            [list ::executive usermode]
    }

    #-------------------------------------------------------------------
    # Private typemethods

    # TBD

    #-------------------------------------------------------------------
    # Public typemethods

    # commands
    #
    # Returns a list of the commands defined in the Executive's 
    # interpreter

    typemethod commands {} {
        $interp eval {info commands}
    }

    # errtrace
    #
    # returns the stack trace from the most recent evaluation error.

    typemethod errtrace {} {
        return $info(stackTrace)
    }
 
    # eval script
    #
    # Evaluate the script; throw an error or return the script's value.
    # Either way, log what happens. Ignore empty scripts.

    typemethod eval {script} {
        if {[string trim $script] eq ""} {
            return
        }

        log normal exec "Command: $script"

        # Make sure the command displays in the log before it
        # executes.
        update idletasks

        if {[catch {
            if {$info(userMode) eq "normal"} {
                $interp eval $script
            } else {
                uplevel \#0 $script
            }
        } result]} {
            set info(stackTrace) $::errorInfo
            log warning exec "Command error: $result"
            return -code error $result
        }

        return $result
    }

    # help ?-info? ?command...?
    #
    # Outputs the help for the command 

    typemethod help {args} {
        if {[llength $args] == 0} {
            app cmdhelp
        }

        if {[lindex $args 0] eq "-info"} {
            set args [lrange $args 1 end]

            set out [$interp help $args]

            append out "\n\n[$interp cmdinfo $args]"

            return $out
        } else {
            app cmdhelp $args
        }
    }

    # usermode ?mode?
    #
    # mode     normal|super
    #
    # Queries/sets the CLI mode.  In normal mode, all commands are 
    # processed by the smartinterp, unless "super" is used.  In
    # super mode, all commands are processed by the main interpreter.

    typemethod usermode {{mode ""}} {
        # FIRST, handle queries
        if {$mode eq ""} {
            return $info(userMode)
        }

        # NEXT, check the mode
        require {$mode in {normal super}} \
            "Invalid mode, should be one of: normal, super"

        # NEXT, save it.
        set info(userMode) $mode

        # NEXT, this is usually a CLI command; it looks odd to
        # return the mode in this case, so don't.
        return
    }

    #---------------------------------------------------------------
    # Procs

    # super args
    #
    # Executes args as a command in the global namespace
    proc super {args} {
        namespace eval :: $args
    }
}

#-------------------------------------------------------------------
# Commands defined in ::, for use when usermode is super

# usermode ?mode?
#
# Calls executive usermode

proc usermode {{mode ""}} {
    executive usermode $mode
}

