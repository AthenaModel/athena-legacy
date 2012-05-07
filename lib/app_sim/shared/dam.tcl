#-----------------------------------------------------------------------
# TITLE:
#    dam.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Driver Assessment Model
#
#    This module provides the interface used to define the DAM Rules.
#    These rules assess the implications of various events and situations
#    and provide inputs to URAM (and eventually to other models as well).
#
#    The rule sets themselves are defined in other modules.
#
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# dam

snit::type dam {
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
        return "dam(sim)"
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
        return [readfile [file join $::app_sim_shared::library dam_temp.sql]]
    }

    # sqlsection functions
    #
    # Returns a dictionary of function names and command prefixes

    typemethod {sqlsection functions} {} {
        return ""
    }

    #-------------------------------------------------------------------
    # Non-Checkpointed Variables
    #
    # These variables are used to accumulate the inputs resulting from
    # a single rule firing.  They do not need to be checkpointed, as
    # they contain only transient data.

    # Standard format for "details"
    typevariable columns "%-22s %s\n"

    # Input array: data related to the input currently under construction
    #
    # Set by "ruleset":
    #
    # ruleset    The ruleset name
    #
    # driver_id  Driver ID
    #
    # setdefs    Dictionary of options and values used as defaults for
    #            the rules:
    #
    #            -s         Here effects factor.
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
    #            -s        Here effects factor.
    #            -p        As in setdefs, above
    #            -q        As in setdefs, above
    #            -cause    As in setdefs, above
    #
    # title      Title of DAM report
    # header     Text that goes between the title and the details
    # details    Text that goes between the header and the effects

    typevariable input -array {
        driver_id ""
    }

    #-------------------------------------------------------------------
    # Management
    #
    # The following methods are used by the DAM Rules to bracket sets
    # of related URAM inputs related to a single rule firing.
    # The commands also save an DAM report.

    # ruleset ruleset driver_id options
    #
    # ruleset    - The rule set name
    # driver_id  - The Driver ID
    #
    # Options:
    #           -cause             Cause, default from parmdb
    #           -s                 Here effects factor, defaults to 1.0
    #           -p                 Near effects factor, default from parmdb
    #           -q                 Far effects factor, default from parmdb
    #
    # Begins accumulating data in preparation for a rule firing.
    # The options establish the defaults for subsequent rule firings.

    typemethod ruleset {ruleset driver_id args} {
        # FIRST, save the driver, and the options specific to this method
        set input(ruleset)   $ruleset
        set input(driver_id) $driver_id
        set input(details)  ""

        # NEXT, set the default option values for the rules and 
        # inputs.
        set input(setdefs) \
            [dict create \
                 -cause       [parmdb get dam.$ruleset.cause]      \
                 -s           1.0                                  \
                 -p           [parmdb get dam.$ruleset.nearFactor] \
                 -q           [parmdb get dam.$ruleset.farFactor]]

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
    #                           edamrule longname)
    #
    # The following options specify defaults for the level and 
    # slope inputs for this rule firing, but can be overridden by
    # the individual inputs if need be:
    #
    #           -cause          See "ruleset"
    #           -s              See "ruleset"
    #           -p              See "ruleset"
    #           -q              See "ruleset"
    #
    # Begins accumulating attitude inputs for a 
    # given rule firing.

    typemethod rule {rule args} {
        # FIRST, save the rule and the options specific to this
        # method:
        set  input(rule)        $rule
        set  input(description) [optval args -description]

        if {$input(description) eq ""} {
            set input(description) [edamrule longname $rule]
            
            if {$input(description) eq ""} {
                error \
                  "Rule $rule has no description (see projtypes(n) edamrule)"
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

        log normal dam "Driver $input(driver_id), $rule $input(description)"

        # NEXT, save the rule defaults for the subsequent inputs.
        set input(ruledefs) $opts

        # NEXT, initialize the rest of the working data.
        set input(title)   "$rule: $input(description)"
        set input(header)  "$input(description)\n"

        # NEXT, clear the temp table used to accumulate the inputs
        rdb eval {DELETE FROM dam_inputs}
        
        # NEXT, evaluate the body
        set code [catch {uplevel 1 $body} result catchOpts]

        # Rethrow errors
        if {$code == 1} {
            return {*}$catchOpts $result
        }

        # NEXT, the input is complete
        dam Complete
    }

    # Complete
    #
    # The inputs are complete; enters them into URAM, and
    # saves an DAM report.

    typemethod Complete {} {
        # FIRST, submit the accumulated inputs to URAM.
        array set got {sat 0 coop 0}

        rdb eval {
            SELECT id, atype, mode, curve, mag, cause, s, p, q
            FROM dam_inputs
        } {
            # FIRST, prepare to give the input to URAM
            if {$atype in {sat coop}} {
                set opts [list -s $s -p $p -q $q]
            } else {
                set opts [list]
            } 

            if {$mode eq "P"} {
                set mode "persistent"
            } else {
                set mode "transient"
            }

            # NEXT, increment the inputs count for this driver, and
            # give the input to URAM 
            driver inputs incr $input(driver_id)
            aram $atype $mode $input(driver_id) $cause {*}$curve $mag {*}$opts
        }

        # NEXT, produce the rule firing report.

        # Add the gain settings:

        if {$got(sat)} {
            set satgain  [parmdb get dam.$input(rule).satgain]

            if {$satgain == 1.0} {
                append input(header) \
                    [format $columns "Satisfaction Gain:" "1.0 (default)"]

            } else {
                append input(header) \
                    [format $columns "Satisfaction Gain:" \
                         [format %.1f $satgain]]
            }
        }

        if {$got(coop)} {
            set coopgain [parmdb get dam.$input(rule).coopgain]

            if {$coopgain == 1.0} {
                append input(header) \
                    [format $columns "Cooperation Gain:" "1.0 (default)"]

            } else {
                append input(header) \
                    [format $columns "Cooperation Gain:" \
                         [format %.1f $coopgain]]
            }
        }

        # Add the details
        if {$input(details) ne ""} {
            append input(header) "\n"
            append input(header) $input(details)
        }

        # Add the inputs table to the report.
        set table \
            [rdb query {
                SELECT id,
                       mode,
                       atype,
                       curve,
                       CASE WHEN cause != '' THEN cause ELSE 'UNIQUE' END,
                       format('%6.2f', mag),
                       CASE WHEN s IS NOT NULL
                       THEN format('%4.2f',s) ELSE 'n/a' END,
                       CASE WHEN p IS NOT NULL
                       THEN format('%4.2f',p) ELSE 'n/a' END,
                       CASE WHEN q IS NOT NULL
                       THEN format('%4.2f',q) ELSE 'n/a' END,
                       note
                FROM dam_inputs
            } -labels {
                "Input" "P/T" "Att" "Curve" "Cause" "Mag"
                "Here" "Near" "Far" "Notes"
            }]
        
        append input(header) "\nATTITUDE INPUTS\n\n"
        append input(header) $table

        # Save the report to the firings tab
        firings save                 \
            -rtype    DAM            \
            -subtype $input(ruleset) \
            -meta1   $input(rule)    \
            -title   $input(title)   \
            -text    $input(header)
    }

    # get name
    #
    # Gets data from the "input" array
    
    typemethod get {name} {
        return $input($name)
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

    # detail label value
    #
    # label      Label text, max 22 characters wide
    # value      Formatted value
    #
    # Adds the labeled value to the "details" part of the report.  This can be
    # called any time after "ruleset".
    
    typemethod detail {label value} {
        dam details [format $columns $label $value]
    }

    # isactive ruleset
    #
    # ruleset    a Rule Set name
    #
    # Returns 1 if the result is active, and 0 otherwise.

    typemethod isactive {ruleset} {
        return [parmdb get dam.$ruleset.active]
    }


    #-------------------------------------------------------------------
    # Attitude Inputs

    # hrel mode flist glist mag ?note?
    #
    # mode   - P or T
    # flist  - A list of one or more groups
    # glist  - A list of one or more groups
    # mag    - A qmag(n) value
    # note   - A brief descriptive note
    #
    # Enters a horizontal relationship input with the given mode 
    # and magnitude for all pairs of groups in flist with glist
    # (but never for a group with itself).

    typemethod hrel {mode flist glist mag {note ""}} {
        assert {$mode in {P T}}

        array set opts $input(ruledefs)

        # NEXT, get the input gain.
        # TBD: No input gain defined for hrel.
        let mag [qmag value $mag]

        foreach f $flist {
            foreach g $glist {
                if {$f eq $g} {
                    continue
                }

                set curve [list $f $g]

                rdb eval {
                    INSERT INTO dam_inputs(
                        atype, mode, curve, mag, cause, note)
                    VALUES('hrel', $mode, $curve, $mag, $opts(-cause), $note)
                }
            }
        }
    }

    # vrel mode glist alist mag ?note?
    #
    # mode   - P or T
    # glist  - A list of one or more groups
    # alist  - A list of one or more actors
    # mag    - A qmag(n) value
    # note   - A brief descriptive note
    #
    # Enters a vertical relationship input with the given mode 
    # and magnitude for all pairs of groups in glist with actors
    # in alist.

    typemethod vrel {mode glist alist mag {note ""}} {
        assert {$mode in {P T}}

        array set opts $input(ruledefs)

        # NEXT, get the input gain.
        # TBD: No input gain defined for vrel.
        let mag [qmag value $mag]

        foreach g $glist {
            foreach a $alist {
                set curve [list $g $a]

                rdb eval {
                    INSERT INTO dam_inputs(
                        atype, mode, curve, mag, cause, note)
                    VALUES('vrel', $mode, $curve, $mag, $opts(-cause), $note)
                }
            }
        }
    }

    # sat mode glist c mag ?c mag...? ?note?
    #
    # mode   - P or T
    # glist  - A list of one or more civilian groups
    # c      - A concern
    # mag    - A qmag(n) value
    # note   - A brief descriptive note
    #
    # Enters satisfaction inputs with the given mode for all groups in
    # glist and the concerns and magnitudes as listed.

    typemethod sat {mode glist args} {
        assert {[llength $args] != 0}
        assert {$mode in {P T}}

        # FIRST, extract a note from the input, if any.
        if {[llength $args] %2 == 1} {
            set note [lindex $args end]
            set args [lrange $args 0 end-1]
        } else {
            set note ""
        }

        # NEXT, get the options.
        array set opts $input(ruledefs)

        # NEXT, get the input gain.
        set gain [parmdb get dam.$input(rule).satgain]


        foreach g $glist {
            foreach {c mag} $args {
                let mag {$gain * [qmag value $mag]}
                
                set curve [list $g $c]

                rdb eval {
                    INSERT INTO dam_inputs(
                        atype, mode, curve, mag, cause, s, p, q, note)
                    VALUES('sat', $mode, $curve, $mag, $opts(-cause), 
                            $opts(-s), $opts(-p), $opts(-q), $note)
                }
            }
        }
    }

    # coop mode flist glist mag ?note?
    #
    # mode   - P or T
    # flist  - A list of one or more civilian groups
    # glist  - A list of one or more force groups
    # mag    - A qmag(n) value
    # note   - A brief descriptive note.
    #
    # Enters a cooperation input with the given mode and magnitude
    # for all pairs of groups in flist with glist.

    typemethod coop {mode flist glist mag {note ""}} {
        assert {$mode in {P T}}

        array set opts $input(ruledefs)

        # NEXT, get the input gain.
        set gain [parmdb get dam.$input(rule).satgain]
        let mag {$gain * [qmag value $mag]}

        foreach f $flist {
            foreach g $glist {
                set curve [list $f $g]

                rdb eval {
                    INSERT INTO dam_inputs(
                        atype, mode, curve, mag, cause, s, p, q, note)
                    VALUES('coop', $mode, $curve, $mag, $opts(-cause), 
                            $opts(-s), $opts(-p), $opts(-q), $note)
                }
            }
        }
    }
}





