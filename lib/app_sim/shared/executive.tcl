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
   
    # init
    #
    # Initializes the interpreter at start-up.
 
    typemethod init {} {
        log normal exec "init"

        $type InitializeInterp

        log normal exec "init complete"
    }


    # reset
    #
    # Resets the interpreter back to its original state.

    typemethod reset {} {
        assert {[info exists interp] && $interp ne ""}

        $interp destroy
        set interp ""

        $type InitializeInterp

        log normal exec "reset complete"

        return "Executive has been reset."
    }

    # InitializeInterp
    #
    # Creates and initializes the executive interpreter.

    typemethod InitializeInterp {} {
        # FIRST, create the interpreter.  It's a safe interpreter but
        # most Tcl commands are retained, to allow scripting.  Allow
        # the "source" command.
        set interp [smartinterp ${type}::interp -cli yes]

        # NEXT, make all mathfuncs available in the global namespace
        $interp eval {
            namespace path ::tcl::mathfunc
        }

        # NEXT, add a few commands back that we need.
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

        # NEXT, install the executive functions

        # ainfluence(n,a)
        $interp smartalias ::tcl::mathfunc::ainfluence 2 2 {n a} \
            [myproc influence]

        # controls(a,n,?n...?)
        $interp smartalias ::tcl::mathfunc::controls 2 - {a n ?n...?} \
            [myproc controls]

        # coop(f,g)
        $interp smartalias ::tcl::mathfunc::coop 2 2 {f g} \
            [myproc coop]

        # gdp()
        $interp smartalias ::tcl::mathfunc::gdp 0 0 {} \
            [myproc gdp]

        # mood(g)
        $interp smartalias ::tcl::mathfunc::mood 1 1 {g} \
            [myproc mood]

        # nbcoop(n,g)
        $interp smartalias ::tcl::mathfunc::nbcoop 2 2 {n g} \
            [myproc nbcoop]

        # nbmood(n)
        $interp smartalias ::tcl::mathfunc::nbmood 1 1 {n} \
            [myproc nbmood]

        # now()
        $interp smartalias ::tcl::mathfunc::now 0 0 {} \
            [list simclock now]

        # parm(parm)
        $interp smartalias ::tcl::mathfunc::parm 1 1 {parm} \
            [list ::parm get]

        # pctcontrol(a,?a,...?)
        $interp smartalias ::tcl::mathfunc::pctcontrol 1 - {a ?a...?} \
            [myproc pctcontrol]

        # sat(g,c)
        $interp smartalias ::tcl::mathfunc::sat 2 2 {g c} \
            [myproc sat]

        # security(n,g)
        $interp smartalias ::tcl::mathfunc::security 2 2 {n g} \
            [myproc security]

        # support(n,a)
        $interp smartalias ::tcl::mathfunc::support 2 2 {n a} \
            [myproc support]

        # supports(a,b,?n,...?)
        $interp smartalias ::tcl::mathfunc::supports 2 - {a b ?n...?} \
            [myproc supports]


        # troops(g,?n...?)
        $interp smartalias ::tcl::mathfunc::troops 1 - {g,?n...?} \
            [myproc troops]

        # unemp()
        $interp smartalias ::tcl::mathfunc::unemp 0 0 {} \
            [myproc unemp]

        # volatility(n)
        $interp smartalias ::tcl::mathfunc::volatility 1 1 {n} \
            [myproc volatility]

        # NEXT, install the executive commands

        # =
        $interp eval {
            interp alias {} = {} expr
        }

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

        # dump econ
        $interp smartalias {dump econ} 0 1 {?page?} \
            [list ::econ dump]

        # ensit
        $interp ensemble ensit

        # ensit id
        $interp smartalias {ensit id} 2 2 {n stype} \
            [myproc ensit_id]

        # ensit last
        $interp smartalias {ensit last} 0 0 {} \
            [myproc ensit_last]

        
        # errtrace
        $interp smartalias errtrace 0 0 {} \
            [mytypemethod errtrace]

        # export
        $interp smartalias export 1 1 {scriptFile} \
            [myproc export]

        # help
        $interp smartalias help 0 - {?-info? ?command...?} \
            [mytypemethod help]


        # last_mad
        $interp smartalias last_mad 0 0 {} \
            [myproc last_mad]

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
            [myproc parmImport]

        # parm list
        $interp smartalias {parm list} 0 1 {?pattern?} \
            [myproc parmList]

        # parm names
        $interp smartalias {parm names} 0 1 {?pattern?} \
            [list ::parm names]

        # parm reset
        $interp smartalias {parm reset} 0 0 {} \
            [myproc parmReset]

        # parm set
        $interp smartalias {parm set} 2 2 {parm value} \
            [myproc parmSet]

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

        # reset
        $interp smartalias {reset} 0 0 {} \
            [mytypemethod reset]

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

    # controls a n ?n...?
    #
    # a      - An actor
    # n      - A neighborhood
    #
    # Returns 1 if a controls all of the listed neighborhoods, and 
    # 0 otherwise.

    proc controls {a args} {
        set a [actor validate [string toupper $a]]

        if {[llength $args] == 0} {
            error "No neighborhoods given"
        }

        set nlist [list]

        foreach n $args {
            lappend nlist [nbhood validate [string toupper $n]]
        }

        set inClause "('[join $nlist ',']')"

        rdb eval "
            SELECT count(n) AS count
            FROM control_n
            WHERE n IN $inClause
            AND controller=\$a
        " {
            return [expr {$count == [llength $nlist]}]
        }
    }

    # coop f g
    #
    # f - A civilian group
    # g - A force group
    #
    # Returns the cooperation of f with g.

    proc coop {f g} {
        set f [civgroup validate [string toupper $f]]
        set g [frcgroup validate [string toupper $g]]

        rdb eval {
            SELECT coop FROM uram_coop WHERE f=$f AND g=$g
        } {
            return [format %.1f $coop]
        }

        error "coop not yet computed"
    }


    # ensit_id n stype
    #
    # n      - Neighborhood
    # stype  - Situation Type
    #
    # Returns the situation ID of the ensit of the given type
    # in the given neighborhood.  Returns "" if none.

    proc ensit_id {n stype} {
        set n [nbhood validate [string toupper $n]]
        set stype [eensit validate $stype]

        return [rdb onecolumn {
            SELECT s FROM ensits 
            WHERE n=$n AND stype=$stype
        }]
    }

    # ensit_last
    #
    # Returns the situation ID of the most recently created ensit.

    proc ensit_last {} {
        return [rdb onecolumn {
            SELECT s FROM ensits ORDER BY s DESC LIMIT 1;
        }]
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

        rdb eval {
            SELECT time,name,parmdict
            FROM cif
            WHERE name != 'SIM:UNLOCK'
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

            dict for {parm value} [order prune $name $parmdict] {
                lappend cmd -$parm $value
            }

            puts $f $cmd
        }

        close $f

        log normal exec "Exported orders as $fullname."

        return
    }

    # gdp
    #
    # Returns the GDP in base-year dollars (i.e., Out::DGDP).
    # It's an error if the economic model is disabled.

    proc gdp {} {
        if {[parm get econ.disable]} {
            error "Economic model is disabled.  To enable, set econ.disable to no."
        }

        return [format %.2f [econ value Out::DGDP]]
    }

    # influence n a
    #
    # n - A neighborhood
    # a - An actor
    #
    # Returns the influence of a in n.

    proc influence {n a} {
        set n [nbhood validate [string toupper $n]]
        set a [actor validate [string toupper $a]]

        rdb eval {
            SELECT influence FROM influence_na WHERE n=$n AND a=$a
        } {
            return [format %.2f $influence]
        }

        error "influence not yet computed"
    }

    # last_mad
    #
    # Returns the ID of the most recently created MAD.

    proc last_mad {} {
        return [rdb onecolumn {
            SELECT driver_id FROM mads ORDER BY driver_id DESC LIMIT 1;
        }]
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

    # mood g
    #
    # g - A civilian group
    #
    # Returns the mood of group g.

    proc mood {g} {
        set g [civgroup validate [string toupper $g]]

        rdb eval {
            SELECT mood FROM uram_mood WHERE g=$g
        } {
            return [format %.1f $mood]
        }

        error "mood not yet computed"
    }

    # nbcoop n g
    #
    # n - A neighborhood
    # g - A force group
    #
    # Returns the cooperation of n with g.

    proc nbcoop {n g} {
        set n [nbhood validate [string toupper $n]]
        set g [frcgroup validate [string toupper $g]]

        rdb eval {
            SELECT nbcoop FROM uram_nbcoop WHERE n=$n AND g=$g
        } {
            return $nbcoop
        }

        error "nbcoop not yet computed"
    }

    # nbmood n
    #
    # n - Neighborhood
    #
    # Returns the mood of neighborhood n.

    proc nbmood {n} {
        set n [nbhood validate [string toupper $n]]

        rdb eval {
            SELECT nbmood FROM uram_n WHERE n=$n
        } {
            return [format %.1f $nbmood]
        }

        error "nbmood not yet computed"
    }

    # parmImport filename
    #
    # filename   A .parmdb file
    #
    # Imports the .parmdb file

    proc parmImport {filename} {
        send PARM:IMPORT -filename $filename
    }


    # parmList ?pattern?
    #
    # pattern    A glob pattern
    #
    # Lists all parameters with their values, or those matching the
    # pattern.  If none are found, throws an error.

    proc parmList {{pattern *}} {
        set result [parm list $pattern]

        if {$result eq ""} {
            error "No matching parameters"
        }

        return $result
    }


    # parmReset 
    #
    # Resets all parameters to defaults.

    proc parmReset {} {
        send PARM:RESET
    }


    # parmSet parm value
    #
    # parm     A parameter name
    # value    A value
    #
    # Sets the parameter's value, using PARM:SET

    proc parmSet {parm value} {
        send PARM:SET -parm $parm -value $value
    }

    # pctcontrol a ?a...?
    #
    # a - An actor
    #
    # Returns the percentage of neighborhoods controlled by the
    # listed actors.

    proc pctcontrol {args} {
        # FIRST, validate the actor names.
        foreach a $args {
            lappend alist [actor validate [string toupper $a]]
        }

        # NEXT, create the inClause.
        set inClause "('[join $alist ',']')"

        # NEXT, query the number of neighborhoods controlled by
        # actors in the list.
        set count [rdb onecolumn "
            SELECT count(n) 
            FROM control_n
            WHERE controller IN $inClause
        "]

        set total [llength [nbhood names]]

        if {$total == 0.0} {
            return 0.0
        }

        return [expr {100.0*$count/$total}]
    }

    # sat g c
    #
    # g - A civilian grou
    # c - A concern
    #
    # Returns the satisfaction of g with c

    proc sat {g c} {
        set g [civgroup validate [string toupper $g]]
        set c [econcern validate $c]

        rdb eval {
            SELECT sat FROM uram_sat WHERE g=$g AND c=$c
        } {
            return [format %.1f $sat]
        }

        error "sat not yet computed"
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
    
    # security n g
    #
    # n - A neighborhood
    # g - A group
    #
    # Returns g's security in n

    proc security {n g} {
        set n [nbhood validate [string toupper $n]]
        set g [group validate [string toupper $g]]

        rdb eval {
            SELECT security FROM force_ng WHERE n=$n AND g=$g
        } {
            return $security
        }

        error "security not yet computed"
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
    #
    # Usually the order is sent using the "raw" interface; if the
    # order state is TACTIC, meaning that the order is sent by an
    # EXECUTIVE tactic script, the order is sent using the 
    # "tactic" interface.  That way the order state is checked but
    # the order is not CIF'd.

    proc send {order args} {
        # FIRST, build the parameter dictionary, validating the
        # parameter names as we go.
        set order [string toupper $order]

        order validate $order

        # NEXT, build the parameter dictionary, validating the
        # parameter names as we go.
        set parms [order parms $order]
        set pdict [dict create]

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
        }

        # NEXT, fill in default values.
        set userParms [dict keys $pdict]
        set pdict [order fill $order $pdict]

        # NEXT, determine the order interface.
        if {[order state] eq "TACTIC"} {
            set interface tactic
        } else {
            set interface raw
        }

        # NEXT, send the order, and handle errors.
        if {[catch {
            order send $interface $order $pdict
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

    # support n a
    #
    # n - A neighborhood
    # a - An actor
    #
    # Returns the support of a in n.

    proc support {n a} {
        set n [nbhood validate [string toupper $n]]
        set a [actor validate [string toupper $a]]

        rdb eval {
            SELECT support FROM influence_na WHERE n=$n AND a=$a
        } {
            return [format %.2f $support]
        }

        error "support not yet computed"
    }

    # supports a b ?n...?
    #
    # a - An actor
    # b - Another actor, SELF, or NONE
    # n - A neighborhood
    #
    # Returns 1 if actor a usually supports actor b, and 0 otherwise.
    # If one or more neighborhoods are given, actor a must support b in 
    # all of them.

    proc supports {a b args} {
        # FIRST, handle the playbox case.
        set a [actor validate [string toupper $a]]
        set b [ptype a+self+none validate [string toupper $b]]

        if {$b eq $a} {
            set b SELF
        }

        if {[llength $args] == 0} {
            if {[rdb exists {
                SELECT supports FROM gui_actors
                WHERE a=$a AND supports=$b
            }]} {
                return 1
            }

            return 0
        }

        # NEXT, handle the multiple neighborhoods case
        set nlist [list]

        foreach n $args {
            lappend nlist [nbhood validate [string toupper $n]]
        }

        set inClause "('[join $nlist ',']')"

        set count [rdb onecolumn "
            SELECT count(*)
            FROM gui_supports
            WHERE a=\$a AND supports=\$b and n IN $inClause
        "]

        if {$count == [llength $nlist]} {
            return 1
        } else {
            return 0
        }
    }

    # troops g ?n...?
    #
    # g      - A force or organization group
    # n      - A neighborhood
    #
    # If no neighborhood is given, returns the number of troops g has in
    # the playbox.  If one or more neighborhoods are given, returns the
    # number of troops g has in those neighborhoods.

    proc troops {g args} {
        set g [ptype fog validate [string toupper $g]]

        # FIRST, handle the playbox case
        if {[llength $args] == 0} {
            rdb eval {
                SELECT total(personnel) AS personnel
                FROM personnel_g WHERE g=$g
            } {
                return [format %.0f $personnel]
            }
        }

        # NEXT, handle the multiple neighborhoods case

        set nlist [list]

        foreach n $args {
            lappend nlist [nbhood validate [string toupper $n]]
        }

        set inClause "('[join $nlist ',']')"

        rdb eval "
            SELECT total(personnel) AS personnel
            FROM deploy_ng
            WHERE n IN $inClause
            AND g=\$g
        " {
            return [format %.0f $personnel]
        }
    }
 
    # unemp
    #
    # Returns the playbox unemployment rate as a percentage.
    # It's an error if the economic model is disabled.

    proc unemp {} {
        if {[parm get econ.disable]} {
            error "Economic model is disabled.  To enable, set econ.disable to no."
        }

        return [format %.1f [econ value Out::UR]]
    }

    # unlock
    #
    # Unlocks the scenario.

    proc unlock {} {
        send SIM:UNLOCK
    }

    # volatility n
    #
    # n - A neighborhood
    #
    # Returns the volatility of neighborhood n

    proc volatility {n} {
        set n [nbhood validate [string toupper $n]]

        rdb eval {
            SELECT volatility FROM force_n WHERE n=$n
        } {
            return $volatility
        }

        error "volatility not yet computed"
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

