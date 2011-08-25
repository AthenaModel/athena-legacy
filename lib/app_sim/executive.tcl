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
        log normal exec "init"

        # FIRST, create the interpreter.  It's a safe interpreter but
        # most Tcl commands are retained, to allow scripting.  Allow
        # the "source" command.
        set interp [smartinterp ${type}::interp -cli yes]
        $interp expose file
        $interp expose pwd
        $interp expose source

        # NEXT, add commands that need to be defined in the slave itself.
        $interp proc call {script args} {
            if {[file extension $script] eq ""} {
                append script ".tcl"
            }

            uplevel 1 [list set argv $args]
            uplevel 1 [list source [file join [pwd] $script]]
        }

        $interp proc select {args} {
            set query "SELECT $args"
            
            return [rdb query $query]
        }


        # NEXT, install the executive commands

        # =
        $interp smartalias = 1 - {expression...} \
            ::expr

        # advance
        $interp smartalias advance 1 1 {days} \
            [myproc advance]

        # clear
        $interp smartalias clear 0 0 {} \
            [list .main cli clear]

        # debug
        $interp smartalias debug 0 0 {} \
            [list ::marsgui::debugger new]

        # dump
        $interp ensemble dump


        # dump coop
        $interp ensemble {dump coop}

        # dump coop levels
        $interp smartalias {dump coop levels} 0 1 {?driver?} \
            [list ::aram dump coop levels]

        # dump coop level
        $interp smartalias {dump coop level} 2 2 {f g} \
            [mytypemethod dump coop level]

        # dump coop slopes
        $interp smartalias {dump coop slopes} 0 1 {?driver?} \
            [list ::aram dump coop slopes]

        # dump coop slope
        $interp smartalias {dump coop slope} 2 2 {f g} \
            [mytypemethod dump coop slope]

        # dump econ
        $interp smartalias {dump econ} 0 1 {?page?} \
            [list ::econ dump]

        # dump sat
        $interp ensemble {dump sat}

        # dump sat levels
        $interp smartalias {dump sat levels} 0 1 {?driver?} \
            [list ::aram dump sat levels]

        # dump sat level
        $interp smartalias {dump sat level} 2 2 {g c} \
            [mytypemethod dump sat level]

        # dump sat slopes
        $interp smartalias {dump sat slopes} 0 1 {?driver?} \
            [list ::aram dump sat slopes]

        # dump sat slope
        $interp smartalias {dump sat slope} 2 2 {g c} \
            [mytypemethod dump sat slope]
        
        # errtrace
        $interp smartalias errtrace 0 0 {} \
            [mytypemethod errtrace]

        # export
        $interp smartalias export 1 1 {scriptFile} \
            [myproc export]

        # help
        $interp smartalias help 0 - {?-info? ?command...?} \
            [mytypemethod help]

        # load
        $interp smartalias load 1 1 {filename} \
            [list scenario open]

        # lock
        $interp smartalias lock 0 0 {} \
            [myproc lock]

        # log
        $interp smartalias log 1 1 {message} \
            [myproc LogCmd]

        # nbfill
        $interp smartalias nbfill 1 1 {varname} \
            [list .main nbfill]

        # new
        $interp smartalias new 0 0 {} \
            [list scenario new]

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

        # save
        $interp smartalias save 1 1 {filename} \
            [myproc save]

        # send
        $interp smartalias send 1 - {order ?option value...?} \
            [myproc send]

        # show
        $interp smartalias show 1 1 {url} \
            [myproc show]

        # sigevent
        $interp smartalias sigevent 1 - {message ?tags...?} \
            [myproc SigEventLog]

        # super
        $interp smartalias super 1 - {arg ?arg...?} \
            [myproc super]

        # unlock
        $interp smartalias unlock 0 0 {} \
            [myproc unlock]

        # usermode
        $interp smartalias {usermode} 0 1 {?mode?} \
            [list ::executive usermode]

        log normal exec "init complete"
    }

    #-------------------------------------------------------------------
    # Private typemethods

    # dump coop level f g
    #
    # Capitalizes the arguments and forwards to GRAM.

    typemethod {dump coop level} {f g} {
        require {[sim state] ne "PREP"} \
            "This command is unavailable in the PREP state."
        
        aram dump coop level \
            [string toupper $f] \
            [string toupper $g]
    }

    # dump coop slope f g
    #
    # Capitalizes the arguments and forwards to GRAM.

    typemethod {dump coop slope} {f g} {
        require {[sim state] ne "PREP"} \
            "This command is unavailable in the PREP state."

        aram dump coop slope \
            [string toupper $f] \
            [string toupper $g]
    }

    # dump sat level g c
    #
    # Capitalizes the arguments and forwards to GRAM.

    typemethod {dump sat level} {g c} {
        require {[sim state] ne "PREP"} \
            "This command is unavailable in the PREP state."

        aram dump sat level \
            [string toupper $g] \
            [string toupper $c]
    }

    # dump sat slope g c
    #
    # Capitalizes the arguments and forwards to GRAM.

    typemethod {dump sat slope} {g c} {
        require {[sim state] ne "PREP"} \
            "This command is unavailable in the PREP state."

        aram dump sat slope \
            [string toupper $g] \
            [string toupper $c]
    }

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
        if {$info(stackTrace) ne ""} {
            log normal exec "errtrace:\n$info(stackTrace)"
        } else {
            log normal exec "errtrace: None"
        }

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
        } result eopts]} {
            set info(stackTrace) $::errorInfo
            log warning exec "Command error: $result"
            return {*}$eopts $result
        }

        return $result
    }

    # help ?-info? ?command...?
    #
    # Outputs the help for the command 

    typemethod help {args} {
        if {[llength $args] == 0} {
            app show my://help/command
        }

        if {[lindex $args 0] eq "-info"} {
            set args [lrange $args 1 end]

            set out [$interp help $args]

            append out "\n\n[$interp cmdinfo $args]"

            return $out
        } else {
            app help $args
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

    # advance days
    #
    # days    - An integer number of days
    #
    # advances time by the specified number of days.  Locks the
    # scenario if necessary.

    proc advance {days} {
        if {[sim state] eq "PREP"} {
            lock
        }

        send SIM:RUN -days $days -block YES
    }

    # export scriptFile
    #
    # scriptFile    Name of a file relative to the current working
    #               directory.
    #
    # Creates a script of "send" commands from the orders in the
    # CIF.  "SIM:UNLOCK" is explicitly ignored, as it gets left
    # behind in the CIF on unlock, and would break scripts.

    proc export {scriptFile} {
        # FIRST, get a list of the order data.  Skip SIM:UNLOCK, and 
        # prepare to fix up SIM:RUN and SIM:PAUSE
        set orders [list]
        set lastRun(index) ""
        set lastRun(time)  ""

        set mark [cif mark]

        rdb eval {
            SELECT time,name,parmdict
            FROM cif
            WHERE id <= $mark AND name != 'SIM:UNLOCK'
            ORDER BY id
        } {
            # SIM:RUN requires special handling.
            if {$name eq "SIM:RUN"} {
                # FIRST, all SIM:RUN's should be blocking.
                dict set parmdict block yes

                # NEXT, we might need to fix up the days; save this order's
                # index into the orders list.
                set lastRun(index) [llength $orders]
                set lastRun(time)  $time
            }

            # SIM:PAUSE updates previous SIM:RUN
            if {$name eq "SIM:PAUSE"} {
                # FIRST, update the previous SIM:RUN
                let days {$time - $lastRun(time) + 1}

                lassign [lindex $orders $lastRun(index)] runOrder runParms
                dict set runParms days $days
                lset orders $lastRun(index) [list $runOrder $runParms]

                # NEXT, the sim will stop running automatically now,
                # so no PAUSE is needed.
                continue
            }

            # Save the current order.
            lappend orders [list $name $parmdict]
        }

        # NEXT, if there are no orders, do nothing.
        if {[llength $orders] == 0} {
            error "no orders to export"
        }

        # NEXT, get file handle.  We'll throw an error if they
        # use a bad name; that's OK.
        set fullname [file join [pwd] $scriptFile]

        set f [open $fullname w]


        # NEXT, turn the orders into commands, and save them.
        foreach entry $orders {
            lassign $entry name parmdict

            # FIRST, build option list.  Include only parameters with
            # non-default values.
            set cmd [list send $name]

            dict for {parm value} $parmdict {
                if {$value ne [order parm $name $parm -defval]} {
                    lappend cmd -$parm $value
                }
            }

            puts $f $cmd
        }

        close $f

        log normal exec "Exported orders as $fullname."

        return
    }

    # lock
    #
    # Locks the scenario.

    proc lock {} {
        send SIM:LOCK
    }

    # LogCmd message
    #
    # message - A text string
    #
    # Logs the message at normal level as "script".

    proc LogCmd {message} {
        log normal script $message
    }

    # save filename
    # 
    # filename   - Scenario file name
    #
    # Saves the scenario using the name.  Errors are handled by
    # [app error].

    proc save {filename} {
        scenario save $filename

        # Don't let [scenario save]'s return value pass through.
        return
    }
    

    # send order ?option value...?
    #
    # order     The name of an order(sim) order.
    # option    One of order's parameter names, prefixed with "-"
    # value     The parameter's value
    #
    # This routine provides a convenient way to enter orders from
    # the command line or a script.  The order name is converted
    # to upper case automatically.  The parameter names are validated,
    # and a parameter dictionary is created.  The order is sent.
    # Any error message is pretty-printed.

    proc send {order args} {
        # FIRST, build the parameter dictionary, validating the
        # parameter names as we go.
        set order [string toupper $order]

        order validate $order

        set parms [order parms $order]
        set pdict [dict create]

        foreach parm [order parms $order] {
            dict set pdict $parm [order parm $order $parm -defval]
        }

        set userParms [list]

        while {[llength $args] > 0} {
            set opt [lshift args]

            set parm [string range $opt 1 end]

            if {![string match "-*" $opt] ||
                $parm ni $parms
            } {
                error "unknown option: $opt"
            }

            if {[llength $args] == 0} {
                error "missing value for option $opt"
            }

            dict set pdict $parm [lshift args]
            lappend userParms $parm
        }

        # NEXT, send the order, and handle errors.
        if {[catch {
            order send raw $order $pdict
        } result eopts]} {
            if {[dict get $eopts -errorcode] ne "REJECT"} {
                # Rethrow
                return {*}$eopts $result
            }

            set wid [lmaxlen [dict keys $pdict]]

            set text "$order rejected:\n"

            # FIRST, add the parms in error.
            dict for {parm msg} $result {
                append text [format "-%-*s   %s\n" $wid $parm $msg]
            }

            # NEXT, add the defaulted parms
            set defaulted [list]
            dict for {parm value} $pdict {
                if {$parm ni $userParms &&
                    ![dict exists $result $parm]
                } {
                    lappend defaulted $parm
                }
            }

            if {[llength $defaulted] > 0} {
                append text "\nDefaulted Parameters:\n"
                dict for {parm value} $pdict {
                    if {$parm in $defaulted} {
                        append text [format "-%-*s   %s\n" $wid $parm $value]
                    }
                }
            }

            return -code error -errorcode REJECT $text
        }

        return ""
    }

    # show url
    #
    # Shows a URL in the detail browser.

    proc show {url} {
        [.main tab win detail] show $url
        .main tab view detail
    }

    # SigEventLog message ?tags...?
    #
    # message - A sig event narrative
    # tags    - Zero or more neighborhoods/actors/groups
    #
    # Writes a message to the significant event log.

    proc SigEventLog {message args} {
        sigevent log 1 script $message {*}$args
    }

    # super args
    #
    # Executes args as a command in the global namespace
    proc super {args} {
        namespace eval :: $args
    }

    # unlock
    #
    # Unlocks the scenario.

    proc unlock {} {
        send SIM:UNLOCK
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

