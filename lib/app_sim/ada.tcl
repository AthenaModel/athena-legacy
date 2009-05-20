#-----------------------------------------------------------------------
# TITLE:
#    ada.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Athena Driver Assessment Module
#
#    This module provides the interface used to define the ADA Rules.
#    These rules assess the implications of various events and situations
#    and provide inputs to GRAM (and eventually to other models as well).
#
#    The rule sets themselves are defined in other modules.
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# ada

snit::type ada {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Constructor
    
    typeconstructor {
        # Import needed commands
        namespace import ::marsutil::* 
        namespace import ::simlib::*
        namespace import ::projectlib::* 
    }

    #-------------------------------------------------------------------
    # sqlsection(i)
    #
    # The following variables and routines implement the module's 
    # sqlsection(i) interface.

    # sqlsection title
    #
    # Returns a human-readable title for the section

    typemethod {sqlsection title} {} {
        return "ada(sim)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions, if any.

    typemethod {sqlsection schema} {} {
        return ""
    }

    # sqlsection tempschema
    #
    # Returns the section's temporary schema definitions, if any.

    typemethod {sqlsection tempschema} {} {
        return [readfile [file join $::app_sim::library ada_temp.sql]]
    }

    # sqlsection functions
    #
    # Returns a dictionary of function names and command prefixes

    typemethod {sqlsection functions} {} {
        return ""
    }

    #-------------------------------------------------------------------
    # Checkpointed Variables

    # signatures
    #
    # Contains situation signatures by driver.  A signature is a string
    # that describes the outcome of a rule firing.  It consists of the
    # rule name (at a minimum) and also of the values of any variables 
    # that can cause the rule's firing to have a different effect if it 
    # fires again, e.g., an activity situation's coverage.  Signatures 
    # are set and checked by the "ada guard" command; if the situation's
    # signature has not changed, the remainder of the rule body is 
    # skipped.

    typevariable signatures -array {}

    #-------------------------------------------------------------------
    # Non-Checkpointed Variables
    #
    # These variables are used to accumulate the inputs resulting from
    # a single rule firing.  They do not need to be checkpointed, as
    # they contain only transient data.

    typevariable columns "%-21s %s\n"

    # Input array: data related to the input currently under construction
    #
    # Set by "ruleset":
    #
    # ruleset    The ruleset name
    #
    # driver     Driver ID
    #
    # count      Count of rules fired since "ruleset" was called.
    #
    # sit        Object command of the situation for which the rule set
    #            has been called.  (Remember, this is a temporary cache)
    #
    # setdefs    Dictionary of options and values used as defaults for
    #            the rules:
    #
    #            -doer      The responsible group(s), or {}.
    #            -location  Location at which the driver occurred,
    #                       or {}.
    #            -n         Affected neighborhood name, or *, or {}
    #            -f         Affected group or groups
    #            -p         Near effects factor.
    #            -q         Far effects factor.
    #            -cause     "Cause" (ecause(n)).
    #
    # Set by "rule":
    #
    # rule       The rule name
    # ruledefs   Dictionary of options and values used as defaults by
    #            the individual cooperation and satisfaction inputs:
    #
    #            -n        Affected neighborhood name, or *, or {}
    #            -f        Affected group or groups
    #            -p        As in setdefs, above
    #            -q        As in setdefs, above
    #            -cause    As in setdefs, above
    #
    # title      Title of INPUT report
    # header     Text that goes at the top of the report.
    # details    Text that goes between the header and the effects
    # logline    Log message; created by "rule", written by first
    #            level or slope input.
    #
    # Set by "guard":
    #
    # signature  The signature of the current rule firing.  Set to ""
    #            by rule.  The "guard" command compares it with
    #            a situation's previous signature.  At the end of the
    #            rule, if not set, the rule name is saved as the signature
    #            if input(sit) is defined.

    typevariable input -array {
        driver ""
        count  0
    }

    typevariable jsiParms  ;# Array of <JinSatInput> parameters

    #-------------------------------------------------------------------
    # Initialization method

    typemethod init {} {
        # FIRST, check requirements
        require {[info commands log]  ne ""} "log is not defined."

        # NEXT, prepare to delete signatures for ended situations
        notifier bind ::actsit <Entity> ::ada [mytypemethod SitEvent]
        notifier bind ::envsit <Entity> ::ada [mytypemethod SitEvent]

        # NEXT, ada is up.
        log normal ada "Initialized"
    }

    # SitEvent op s
    #
    # op  Operation
    # s   The situation ID
    #
    # When a situation has ended, forget its last signature.

    typemethod SitEvent {op s} {
        # TBD: Make sure timing is right.
        if {$op ne "delete"} {
            set sit [situation get $s]

            if {[$sit get state] eq "ENDED"} {
                unset -nocomplain signatures($s)
            }
        }
    }

    #-------------------------------------------------------------------
    # Management
    #
    # The following methods are used by the JIN Rules to bracket sets
    # of related JRAM inputs related to a single rule firing.
    # The commands take care of reporting the inputs to RTI and
    # to the console/workstation.

    # ruleset ruleset driver options
    #
    # ruleset   The rule set name
    # driver    The Driver ID
    #
    # Options:
    #           -sit               Situation object command, or ""
    #           -doer              The causing group(s)
    #           -location          Location of input (default, none)
    #           -n                 Name of affected neighborhood, or *
    #           -f                 Name of affected group or groups
    #           -cause             Cause, default ""
    #           -p                 Near effects factor, default 0
    #           -q                 Far effects factor, default 0
    #
    # Begins accumulating data in preparation for a rule firing.
    # The options establish the defaults for subsequent rule firings.

    typemethod ruleset {ruleset driver args} {
        # FIRST, save the driver, and the options specific to this method
        set input(ruleset)  $ruleset
        set input(driver)   $driver
        set input(count)    0
        set input(sit)      [optval args -sit ""]
        set input(details)  ""

        # NEXT, set the default option values for the rules and 
        # inputs.
        set input(setdefs) \
            [dict create \
                 -doer        {}  \
                 -location    {}  \
                 -n           {}  \
                 -f           {}  \
                 -cause       {}  \
                 -p           0.0 \
                 -q           0.0]

        # NEXT, get the passed in options.
        # TBD: Should throw an error if there are any unknown dict keys.
        foreach {opt val} $args { 
            dict set input(setdefs) $opt $val 
        }
    }


    # rule rule ?options? expr body
    #
    # rule      The rule name
    # expr      The logical expression
    # body      The rule's body
    #
    # The following options apply globally to this rule firing, and
    # do not affect specific slope or level inputs.  All but the
    # first default to the values established by the previous
    # call to "ruleset":
    #
    #           -description    Rule description (defaults to
    #                           eadarules longname)
    #           -location       See "ruleset"
    #
    # The following options specify defaults for the level and 
    # slope inputs for this rule firing, but can be overridden by
    # the individual inputs if need be:
    #
    #           -n              See "ruleset"
    #           -f              See "ruleset"
    #           -doer           See "ruleset"
    #           -cause          See "ruleset"
    #           -p              See "ruleset"
    #           -q              See "ruleset"
    #
    # Begins accumulating satisfaction and cooperation inputs for a 
    # given rule firing.

    typemethod rule {rule args} {
        # FIRST, save the rule and the options specific to this
        # method:
        set  input(rule)        $rule
        incr input(count)
        set  input(signature)   ""
        set  input(description) [optval args -description]

        if {$input(description) eq ""} {
            set input(description) [eadarules longname $rule]
            
            if {$input(description) eq ""} {
                error \
                  "Rule $rule has no description (see projtypes(n) eadarules)"
            }
        }

        # NEXT, get the body
        set expr [lindex $args end-1]
        set body [lindex $args end]

        # NEXT, get the rule set defaults, and save the remaining
        # options.
        set opts $input(setdefs)

        # TBD: Should check for invalid options.
        foreach {opt val} [lrange $args 0 end-2] { 
            dict set opts $opt $val 
        }

        # NEXT, evaluate the expression.  If it's false, just return.
        if {![uplevel 1 [list expr $expr]]} {
            return
        }

        # NEXT, save the rule defaults for the subsequent inputs.
        set input(ruledefs) $opts

        # NEXT, initialize the rest of the working data.
        set input(title)   "$rule: $input(description)"
        set input(header)  "$input(description)\n"
        set input(logline) "Driver $input(driver), $rule $input(description)"

        # NEXT, clear the temp table used to accumulate the inputs
        rdb eval {DELETE FROM ada_inputs}
        
        # NEXT, Add details to the header.

        # -doer, -location,
        dict with opts {
            # -doer
            set doer ${-doer}

            # -location
            if {[llength ${-location}] == 2} {
                set locText [map m2ref {*} ${-location}]
            } else {
                set locText ""
            }
        }

        # sit
        if {$input(sit) ne ""} {
            set sitText [$input(sit) id]
        } else {
            set sitText ""
        }

        # NEXT, add the parameter data to the header, if need be.
        if {$locText      ne "" ||
            $sitText      ne "" ||
            $doer         ne ""
        } {
            append input(header) "\n"
        }

        if {$locText ne ""} {
            append input(header) [format $columns "Location:" $locText]
        }

        if {$sitText ne ""} {
            append input(header) [format $columns "Situation ID:" $sitText]
        }

        if {$doer ne ""} {
            append input(header) \
                [format $columns "Responsible Group(s):" $doer]
        }

        # NEXT, evaluate the body
        set code [catch {uplevel 1 $body} result catchOpts]

        # Do not complete the rule firing on "break"; this will 
        # happen if "ada guard" determines that the rule should
        # not fire.
        if {$code == 3} {
            return
        }

        # Rethrow errors
        if {$code == 1} {
            return {*}$catchOpts $result
        }

        # NEXT, the input is complete
        ada Complete
    }

    # guard text
    #
    # text      Partial signature of the rule firing or "none" 
    #           if no signature.
    #
    # Protects a situation rule from firing twice in succession when
    # the outcome will be identical.  If the signature is the same as 
    # the situation's previous signature, the rule aborts.
    
    typemethod guard {{text none}} {
        # Doesn't matter if not situation.
        if {$input(sit) eq ""} {
            return
        }

        set input(signature) "$input(rule) $text"

        set s [$input(sit) id]

        
        if {[info exists signatures($s)]} {
            if {$signatures($s) eq $input(signature)} {
                return -code break
            }
        }
    }
    

    # Complete
    #
    # The inputs are complete; enters them into GRAM, and
    # saves an INPUT report.

    typemethod Complete {} {
        # FIRST, do special handling for situations
        # TBD: Consider moving "signature" to the situation table.
        if {$input(sit) ne ""} {
            # FIRST, get the situation's ID
            set s [$input(sit) id]
            
            # NEXT, Save the rule signature
            if {$input(signature) ne ""} {
                set signatures($s) $input(signature)
            } else {
                set signatures($s) $input(rule)
            }
        }

        # NEXT, submit the accumulated inputs to GRAM.
        array set got {sat 0 coop 0}

        rdb eval {
            SELECT id, itype, etype, n, f, g, c, slope, climit, days,
                   cause, p, q
            FROM ada_inputs
        } {
            incr got($itype)

            if {$itype eq "sat" && $etype eq "LEVEL"} {
                set dinput [aram sat level $input(driver) \
                               [simclock now]          \
                               $n                      \
                               $f                      \
                               $c                      \
                               $climit                 \
                               $days                   \
                               -p     $p               \
                               -q     $q               \
                               -cause $cause]
            } elseif {$itype eq "sat" && $etype eq "SLOPE"} {
                set dinput [aram sat slope $input(driver) \
                               [simclock now]          \
                               $n                      \
                               $f                      \
                               $c                      \
                               $slope                  \
                               -p     $p               \
                               -q     $q               \
                               -cause $cause]
            } elseif {$itype eq "coop" && $etype eq "LEVEL"} {
                set dinput [aram coop level $input(driver) \
                               [simclock now]           \
                               $n                       \
                               $f                       \
                               $g                       \
                               $climit                  \
                               $days                    \
                               -p     $p                \
                               -q     $q                \
                               -cause $cause]
            } elseif {$itype eq "coop" && $etype eq "SLOPE"} {
                set dinput [jram coop slope $input(driver) \
                               [simclock now]           \
                               $n                       \
                               $f                       \
                               $g                       \
                               $slope                   \
                               -p     $p                \
                               -q     $q                \
                               -cause $cause]
            }

            # NEXT, add the inputId to the ada_inputs
            set inputId "$input(driver).$dinput"

            rdb eval {
                UPDATE ada_inputs
                SET input = $inputId
                WHERE id = $id
            }
        }

        # NEXT, produce the INPUT report for the console/workstation
        # clients.

        # Add the gain settings:

        append input(header) "\n"

        if {$got(sat)} {
            set satgain  [parmdb get ada.$input(rule).satgain]

            if {$satgain == 1.0} {
                append input(header) \
                    "Satisfaction Gain: 1.0 (default)\n"
            } else {
                append input(header) \
                    "Satisfaction Gain: [format %.1f $satgain]\n"
            }
        }

        if {$got(coop)} {
            set coopgain [parmdb get ada.$input(rule).coopgain]

            if {$coopgain == 1.0} {
                append input(header) \
                    "Cooperation Gain:  1.0 (default)\n"
            } else {
                append input(header) \
                    "Cooperation Gain:  [format %.1f $coopgain]\n"
            }
        }

        # Add the details
        if {$input(details) ne ""} {
            append input(header) "\n"
            append input(header) $input(details)
        }

        # Add the satisfaction level inputs table to the report.
        set table \
            [rdb query {
                SELECT input,
                       n,
                       f,
                       c,
                       CASE WHEN cause != '' THEN cause ELSE 'n/a' END,
                       format('%5.1f (%s)',climit,qmag('name',climit)),
                       format('%g days',days),
                       format('%4.2f',p),
                       format('%4.2f',q)
                FROM ada_inputs
                WHERE itype = 'sat' AND etype = 'LEVEL'
            } -labels {
                "Input" "Nbhood" "Group" "Con" "Cause" "Limit" "Days" 
                "Near" "Far"
            }]
        
        if {$table ne ""} {
            append input(header) "\nSatisfaction Level Inputs\n\n"
            append input(header) $table
        }

        # Add the satisfaction slope inputs table to the report
        set table \
            [rdb query {
                SELECT input,
                       n,
                       f,
                       c,
                       CASE WHEN cause != '' THEN cause ELSE 'n/a' END,
                       format('%5.1f (%s)',slope,qmag('name',slope)),
                       format('%4.2f',p),
                       format('%4.2f',q)
                FROM ada_inputs
                WHERE itype = 'sat' AND etype = 'SLOPE'
            } -labels {
                "Input" "Nbhood" "Group" "Con" "Cause" "Slope"
                "Near" "Far"
            }]

        if {$table ne ""} {
            append input(header) "\nSatisfaction Slope Inputs\n\n"
            append input(header) $table
        }

        # Add the cooperation level inputs table to the report.
        set table \
            [rdb query {
                SELECT input,
                       n,
                       f,
                       g,
                       CASE WHEN cause != '' THEN cause ELSE 'n/a' END,
                       format('%5.1f (%s)',climit,qmag('name',climit)),
                       format('%g days (%s)',days),
                       format('%4.2f',p),
                       format('%4.2f',q)
                FROM ada_inputs
                WHERE itype = 'coop' AND etype = 'LEVEL'
            } -labels {
                "Input" "Nbhood" "Civ" "Frc" "Cause" "Limit" "Days" 
                "Near" "Far"
            }]
        
        if {$table ne ""} {
            append input(header) "\nCooperation Level Inputs\n\n"
            append input(header) $table
        }

        # Add the cooperation slope inputs table to the report
        set table \
            [rdb query {
                SELECT input,
                       n,
                       f,
                       g,
                       CASE WHEN cause != '' THEN cause ELSE 'n/a' END,
                       format('%5.1f (%s)',slope,qmag('name',slope)),
                       format('%4.2f',p),
                       format('%4.2f',q)
                FROM ada_inputs
                WHERE itype = 'coop' AND etype = 'SLOPE'
            } -labels {
                "Input" "Nbhood" "Civ" "Frc" "Cause" "Slope"
                "Near" "Far"
            }]

        if {$table ne ""} {
            append input(header) "\nCooperation Slope Inputs\n\n"
            append input(header) $table
        }

        # Save the report to the console/workstation
        report save                  \
            -type    INPUT           \
            -subtype $input(ruleset) \
            -meta1   $input(rule)    \
            -title   $input(title)   \
            -text    $input(header)
    }

    # count
    #
    # Returns number of rules that have fired in this call of this
    # ruleset.

    typemethod count {} {
        return $input(count)
    }

    # get name
    #
    # Gets data from the "input" array
    
    typemethod get {name} {
        return $input($name)
    }

    # rget opt
    #
    # opt      One of the rule options
    #
    # Returns the value of the rule default option.
    
    typemethod rget {opt} {
        dict get $input(ruledefs) $opt
    }
    

    # details text
    #
    # text       Arbitrary text
    #
    # Adds the text to the "details" part of the report.  This can be
    # called any time after "ruleset".
    
    typemethod details {text} {
        append input(details) $text
    }

    #-------------------------------------------------------------------
    # Satisfaction Inputs

    # sat level ?options? con limit days ?con limit days...?
    #
    # con    concern short name
    # limit  limit, qmag(n)
    # days   decimal days
    #
    # Options:
    #   The following default to values given for "rule".
    #
    #     -n      Name of affected neighborhood, or *.  Required if
    #             not specified by "ruleset" or "rule".
    #     -f      Name of affected group or groups.  Required if
    #             not specified by "ruleset" or "rule".
    #     -cause  Cause of this input (ecause)
    #     -p      Near effects multiplier
    #     -q      Far effects multiplier
    #
    # Adds a level effect to a set of inputs.

    typemethod {sat level} {args} {
        # FIRST, if the logline hasn't been logged, log it.
        LogFiring

        # NEXT, get the option defaults and values
        set opts [GetOpts args $input(ruledefs)]

        set n     [dict get $opts -n]
        set flist [dict get $opts -f]

        # NEXT, check some error conditions
        assert {$n ne ""}
        assert {[llength $flist] > 0}
        assert {[llength $args] != 0 && [llength $args] % 3 == 0}

        # NEXT, do each of the inputs
        foreach f $flist {
            foreach {con limit days} $args {
                SatLevel $n $f $con $limit $days \
                    [dict get $opts -cause]      \
                    [dict get $opts -p]          \
                    [dict get $opts -q]

            }
        }
    }

    # SatLevel n f c limit days cause p q
    #
    # Saves a single GRAM input

    proc SatLevel {n f c limit days cause p q} {
        # NEXT, update the level per the input gain.
        let limit {[parmdb get ada.$input(rule).satgain] * [qmag value $limit]}

        # NEXT, add this input to the ada_inputs
        rdb eval {
            INSERT INTO ada_inputs(
                itype,etype,n,f,c,cause,climit,days,p,q
            ) VALUES(
                'sat',
                'LEVEL',
                $n,
                $f,
                $c,
                $cause,
                $limit,
                $days,
                $p,
                $q
            );
        }
    }

    # sat slope ?options? con slope ?con slope...?
    #
    # con    concern short name
    # slope  change/day (qmag)
    #
    # Options: 
    #   The following default to values given for "rule".
    #
    #     -n      Name of affected neighborhood, or *.  Required if
    #             not specified by "ruleset" or "rule".
    #     -f      Name of affected group or groups.  Required if
    #             not specified by "ruleset" or "rule".
    #     -cause  Cause of this input (ecause)
    #     -p      Near effects multiplier
    #     -q      Far effects multiplier
    #
    # Adds a slope effect to a set of inputs, and submits it to GRAM

    typemethod {sat slope} {args} {
        # FIRST, if the logline hasn't been logged, log it.
        LogFiring

        # NEXT, get the option defaults and values
        set opts [GetOpts args $input(ruledefs)]

        set n     [dict get $opts -n]
        set flist [dict get $opts -f]

        # NEXT, check some error conditions
        assert {$n ne ""}
        assert {[llength $flist] > 0}
        assert {[llength $args] != 0 && [llength $args] % 2 == 0}

        # NEXT, do each of the inputs
        foreach f $flist {
            foreach {con slope} $args {
                SatSlope $n $f $con $slope   \
                    [dict get $opts -cause]  \
                    [dict get $opts -p]      \
                    [dict get $opts -q]
            }
        }
    }

    # SatSlope n f c slope cause p q
    #
    # Saves a single GRAM input

    proc SatSlope {n f c slope cause p q} {
        # FIRST, update the slope per the input gain.
        let slope {[parmdb get ada.$input(rule).satgain] * [qmag value $slope]}

        # NEXT, add this input to the ada_inputs
        rdb eval {
            INSERT INTO ada_inputs(
                itype,etype,n,f,c,cause,slope,p,q
            ) VALUES(
                'sat',
                'SLOPE',
                $n,
                $f,
                $c,
                $cause,
                $slope,
                $p,
                $q
            );
        }
    }

    # sat clear ?options? con ?con...?
    #
    # con    concern short name
    #
    # Options: 
    #   The following default to values given for "rule".
    #
    #     -n      Name of affected neighborhood, or *.  Required if
    #             not specified by "ruleset" or "rule".
    #     -f      Name of affected group or groups.  Required if
    #             not specified by "ruleset" or "rule".
    #     -cause  Cause of this input (ecause)
    #
    # Clears slope effects for a given -n, -f, -cause, and concerns

    typemethod {sat clear} {args} {
        # FIRST, if the logline hasn't been logged, log it.
        LogFiring

        # NEXT, get the option defaults and values
        set opts [GetOpts args $input(ruledefs)]

        set n     [dict get $opts -n]
        set flist [dict get $opts -f]

        assert {$n ne ""}
        assert {[llength $flist] > 0}
        assert {[llength $args] != 0}

        # NEXT, do each of the inputs
        foreach f $flist {
            foreach con $args {
                SatSlope $n $f $con 0       \
                    [dict get $opts -cause] \
                    0 0
            }
        }
    }

    #-------------------------------------------------------------------
    # Cooperation Inputs

    # coop level ?options? limit days ?limit days...?
    #
    # limit  limit, qmag(n)
    # days   decimal days
    #
    # Options:
    #   The following default to values given for "rule".
    #
    #     -n      Name of affected neighborhood, or *.  Required if
    #             not specified by "ruleset" or "rule".
    #     -f      Name of affected group or groups.  Required if
    #             not specified by "ruleset" or "rule".
    #     -cause  Cause of this input (ecause)
    #     -p      Near effects multiplier
    #     -q      Far effects multiplier
    #
    # Adds a level effect to a set of inputs, and submits it to JRAM.

    typemethod {coop level} {args} {
        # FIRST, if the logline hasn't been logged, log it.
        LogFiring

        # NEXT, get the option defaults and values
        set opts [GetOpts args $input(ruledefs)]

        set n     [dict get $opts -n]
        set flist [dict get $opts -f]

        # NEXT, check some error conditions
        assert {$n ne ""}
        assert {[llength $flist] > 0}
        assert {[llength $args] != 0 && [llength $args] % 2 == 0}

        # NEXT, do each of the inputs
        # TBD: Doers can only be force groups!
        foreach f $flist {
            foreach {limit days} $args {
                foreach doer [dict get $opts -doer] {
                    CoopLevel $n $f $doer $limit $days \
                        [dict get $opts -cause]         \
                        [dict get $opts -p]             \
                        [dict get $opts -q]
                }
            }
        }
    }

    # CoopLevel n f g limit days cause p q
    #
    # Enters a single JRAM-NG input

    proc CoopLevel {n f g limit days cause p q} {
        # NEXT, update the level per the input gain
        let limit {
            [parmdb get ada.$input(rule).coopgain] * [qmag value $limit]
        }

        # NEXT, add this input to the ada_inputs
        rdb eval {
            INSERT INTO ada_inputs(
                itype,etype,n,f,g,cause,climit,days,p,q
            ) VALUES(
                'coop',
                'LEVEL',
                $n,
                $f,
                $g,
                $cause,
                $limit,
                $days,
                $p,
                $q
            );
        }
    }

    # coop slope ?options? slope
    #
    # slope  change/day (qmag)
    #
    # Options: 
    #   The following default to values given for "rule".
    #
    #     -n      Name of affected neighborhood, or *.  Required if
    #             not specified by "ruleset" or "rule".
    #     -f      Name of affected group or groups.  Required if
    #             not specified by "ruleset" or "rule".
    #     -cause  Cause of this input (ecause)
    #     -p      Near effects multiplier
    #     -q      Far effects multiplier
    #
    # Adds a slope effect to a set of inputs, and submits it to JRAM

    typemethod {coop slope} {args} {
        # FIRST, if the logline hasn't been logged, log it.
        LogFiring

        # NEXT, get the option defaults and values
        set opts [GetOpts args $input(ruledefs)]

        set n     [dict get $opts -n]
        set flist [dict get $opts -f]

        # NEXT, check some error conditions
        assert {$n ne ""}
        assert {[llength $flist] > 0}
        assert {[llength $args] == 1}

        lassign $args slope

        # NEXT, do each of the inputs
        # TBD: Only for doers that are force groups!
        foreach f $flist {
            foreach doer [dict get $opts -doer] {
                CoopSlope $n $f $doer $slope  \
                    [dict get $opts -cause]   \
                    [dict get $opts -p]       \
                    [dict get $opts -q]
            }
        }
    }

    # CoopSlope n f g slope cause p q
    #
    # Saves a single GRAM input

    proc CoopSlope {n f g slope cause p q} {
        # FIRST, update the slope per the input gain.
        let slope {
            [parmdb get ada.$input(rule).coopgain] * [qmag value $slope]
        }

        rdb eval {
            INSERT INTO ada_inputs(
                itype,etype,n,f,g,cause,slope,p,q
            ) VALUES(
                'coop',
                'SLOPE',
                $n,
                $f,
                $g,
                $cause,
                $slope,
                $limit,
                $p,
                $q
            );
        }
    }

    # coop clear ?options?
    #
    # Options: 
    #   The following default to values given for "rule".
    #
    #     -n      Name of affected neighborhood, or *.  Required if
    #             not specified by "ruleset" or "rule".
    #     -f      Name of affected group or groups.  Required if
    #             not specified by "ruleset" or "rule".
    #     -cause  Cause of this input (ecause)
    #
    # Clears slope effects for a given -n, -f and -cause

    typemethod {coop clear} {args} {
        # FIRST, if the logline hasn't been logged, log it.
        LogFiring

        # NEXT, get the option defaults and values
        set opts [GetOpts args $input(ruledefs)]

        set n     [dict get $opts -n]
        set flist [dict get $opts -f]

        assert {$n ne ""}
        assert {[llength $flist] > 0}
        assert {[llength $args] == 0}

        # NEXT, do each of the inputs
        foreach f $flist {
            # TBD: Only for doers that are force groups!
            foreach doer [dict get $opts -doer] {
                CoopSlope $n $f $doer 0 0 \
                    [dict get $opts -cause] \
                    0 0
            }
        }
    }

    #-------------------------------------------------------------------
    # Input Utilities

    # LogFiring
    #
    # Writes the saved logline for this rule when the first input
    # is made.

    proc LogFiring {} {
        # FIRST, if the logline hasn't been logged, log it.
        if {$input(logline) ne ""} {
            log normal ada $input(logline)
            set input(logline) ""
        }
    }

    # GetOpts argvar defdict
    #
    # argvar           Variable containing list of options and values
    # defdict          A dictionary of default option values
    #
    # Returns a dictionary containing the defaults and any new
    # values.  Options not contained in the default dictionary
    # cause an error to be thrown.  Any remaining arguments are
    # left in the argvar.

    proc GetOpts {argvar defdict} {
        upvar 1 $argvar arglist

        set opts $defdict

        while {[llength $arglist] > 0} {
            if {[lindex $arglist 0] eq "--"} {
                lshift arglist
                break
            } elseif {[string index [lindex $arglist 0] 0] ne "-"} {
                break
            }
            set opt [lshift arglist]
            set val [lshift arglist]
            
            if {![dict exists $opts $opt]} {
                error "Unknown option: $opt"
            }

            dict set opts $opt $val
        }

        return $opts
    }



    #-------------------------------------------------------------------
    # Checkpoint/Restore

    # TBD: If I put "signature" in the situation, I don't need to
    # worry about this.

    # checkpoint
    #
    # Returns the component's checkpoint information as a string.

    typemethod checkpoint {} {
        list signatures [array get signatures]
    }

    # restore checkpoint
    #
    # checkpoint      A checkpoint string returned by "checkpoint"
    #
    # Restores the component's state to the checkpoint.

    typemethod restore {checkpoint} {
        foreach {name value} $checkpoint {
            array unset $name
            array set $name $value
        }
    }
}

