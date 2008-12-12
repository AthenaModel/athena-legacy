#-----------------------------------------------------------------------
# TITLE:
#    ted.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Text Execution Deputy package
#
#    At present, all ted routines are defined directly in this
#    file.  Ultimately we might define additional modules, in which case
#    this will become a loader script.
#
#    See minerva_test(1) for documentation of these utilities.
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# ted

snit::type ted {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Import all util(n) and simlib(n) routines
        namespace import ::marsutil::* ::minlib::* ::tcltest::*
    }

    #-------------------------------------------------------------------
    # Type Variables

    # List of notifier events received since last "ted notifier forget".
    # Each event is "object event args..."

    typevariable notifierResults {}

    #-------------------------------------------------------------------
    # Client Interface

    # init
    #
    # Initializes all TED-defined constraints. 

    typemethod init {} {
        # TBD: None yet.
    }

    # sendex ?-error? command...
    #
    # command...    A Tcl command, represented as either a single argument
    #               containing the entire command, or as multiple arguments.
    #
    # Executes the command in the Executive's "test" client interpreter,
    # and returns the result.  If -error is specified, expects an error
    # returns the error message.
    #
    # Examples: The following calls are equivalent
    #
    #    ted sendex magic absit BADFOOD {1.0 1.0}
    #    ted sendex {magic absit BADFOOD {1.0 1.0}} 
    #
    # TBD: As yet there isn't any executive; so the command is 
    # executed using uplevel.

    typemethod sendex {args} {
        # FIRST, is -error specified?
        if {[lindex $args 0] eq "-error"} {
            lshift args
            set errorFlag 1
        } else {
            set errorFlag 0
        }

        # NEXT, get the command
        if {[llength $args] == 1} {
            set command [lindex $args 0]
        } else {
            set command $args
        }

        # NEXT, execute the command
        if {$errorFlag} {
            set code [catch {
                # executive eval test $command
                uplevel \#0 $command
            } result]

            if {$code} {
                return $result
            } else {
                return -code error "Expected error, got ok"
            }
        } else {
            # Normal case; let nature take its course
            # executive eval test $command
            uplevel \#0 $command
        }
    }

    # order ?-reject? name parmdict
    #
    # name       A simulation order
    # parmdict   The order's parameter dictionary, as a single
    #            argument or as multiple arguments.
    #
    # Sends the order as the GUI client, and returns the result.
    # If "-reject" is used, expects the order to be rejected.

    typemethod order {args} {
        # FIRST, is -reject specified?
        if {[lindex $args 0] eq "-reject"} {
            lshift args
            set rejectFlag 1
        } else {
            set rejectFlag 0
        }

        # NEXT, get the order name
        set order [lshift args]

        require {$order ne ""} "No order specified!"

        # NEXT, get the parm dict
        if {[llength $args] == 1} {
            set parmdict [lindex $args 0]
        } else {
            set parmdict $args
        }

        # NEXT, send the order
        if {$rejectFlag} {
            set code [catch {
                order send "" gui $order $parmdict
            } result opts]

            if {$code} {
                if {[dict get $opts -errorcode] eq "REJECT"} {

                    set    results "\n"
                    foreach {parm error} $result {
                        append results "        $parm [list $error]\n" 
                    }
                    append results "    "
                    
                    return $results
                } else {
                    return {*}$opts $result
                }
            } else {
                return -code error "Expected rejection, got ok"
            }
        } else {
            # Normal case; let nature take its course
            order send "" gui $order $parmdict
        }
    }

    # query sql
    #
    # sql     An SQL query
    #
    # Does an RDB query using the SQL text, and pretty-prints the 
    # whitespace.

    typemethod query {sql} {
        return "\n[rdb query $sql]    "
    }

    #-------------------------------------------------------------------
    # Notifier events

    # notifier forget
    #
    # Clears all of ted's notifier bindings and data

    typemethod {notifier forget} {} {
        notifier forget ::ted

        set notifierResults [list]
    }

    # notifier bind subject event
    #
    # subject     The subject 
    # event       The event ID
    #
    # Binds to the named event; if received, it will go in the results.
    
    typemethod {notifier bind} {subject event} {
        notifier bind $subject $event ::ted \
            [mytypemethod NotifierEvent $subject $event]
    }

    # notifier received
    #
    # Returns a pretty-printed list of lists of the received events 
    # with their arguments.

    typemethod {notifier received} {} {
        if {[llength $notifierResults] > 0} {
            set    results "\n        {"
            append results [join $notifierResults "}\n        {"]
            append results "}\n    "

            return $results
        } else {
            return ""
        }
    }

    # NotifierEvent args...
    #
    # Lappends the args to the notifier results

    typemethod NotifierEvent {args} {
        lappend notifierResults $args
    }

    # notifier diff ndx event matchdict...
    #
    # ndx          The index of the event in the received event queue.
    # event        The event name
    # dict         A dictionary to diff with the event dictionary,
    #              expressed as one argument or many.
    #
    # Does a "ted dictdiff" of the selected event's dict with the
    # specified one, and confirms the event name.  The output is
    # as for dictdiff.

    typemethod {notifier diff} {ndx event args} {
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        set evt    [lindex [ted notifier received] $ndx 1]
        set eparms [lindex [ted notifier received] $ndx 2]

        assert {$evt eq $event}

        ted dictdiff $eparms $args
    } 

    # notifier match ndx event matchdict...
    #
    # ndx          The index of the event in the received event queue.
    # event        The event name
    # dict         A dictionary of keys and patterns match with the 
    #              event dictionary expressed as one argument or many.
    #
    # Does a "ted dictmatch" of the selected event's dict with the
    # specified one, and confirms the event name.  The output is
    # as for dictmatch.

    typemethod {notifier match} {ndx event args} {
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        set evt    [lindex [ted notifier received] $ndx 1]
        set eparms [lindex [ted notifier received] $ndx 2]

        assert {$evt eq $event}

        ted dictmatch $eparms $args
    } 


    #-------------------------------------------------------------------
    # dictdiff

    # dictdiff a b...
    #
    # a    A dict
    # b    A dict, possible specified as individual arguments
    #
    # Compares the two dicts, and returns a description of the values that
    # differ.  Each value is a list {A|B <name> <value>}.  If an item
    # appears in only A or B, an A or B entry will appear in the output.
    # If it appears in both with different values, the A entry will appear
    # followed by the B entry.
    #
    # If there are no differences, the result is an empty string.
    # Otherwise, the output is a valid list of lists, with one difference
    # entry per line, so as to appear nicely formatted in a test -result.

    typemethod dictdiff {a args} {
        # FIRST, get b.
        if {[llength $args] == 1} {
            set b [lindex $args 0]
        } else {
            set b $args
        }

        # NEXT, compare each entry in a with b
        set results [list]

        foreach key [lsort [dict keys $a]] {
            if {![dict exists $b $key]} {
                lappend results [list A $key [dict get $a $key]]
            } elseif {[dict get $b $key] ne [dict get $a $key]} {
                lappend results [list A $key [dict get $a $key]]
                lappend results [list B $key [dict get $b $key]]
            }

            # Remove the key from b, so that we can easily find
            # what's left.
            set b [dict remove $b $key]
        }

        # NEXT, add entries for anything left in b
        foreach key [lsort [dict keys $b]] {
            lappend results [list B $key [dict get $b $key]]
        }

        # NEXT, format.
        if {[llength $results] == 0} {
            return $results
        }
        
        set    out "\n        {"
        append out [join $results "}\n        {"]
        append out "}\n    "
        
        return $out
    }

    # dictmatch a b...
    #
    # a    A dict
    # b    A dict of glob patterns, possibly specified as individual 
    #      arguments
    #
    # Does a string match of each glob pattern in b with the
    # corresponding key and value in a, and returns a dict of the values
    # that differ.  keys in a that do not appear in b are ignored.
    #
    # If all of b's patterns match, the result is "OK".
    # Otherwise, the output is a dict with one key/value pair per line,
    # so as to appear nicely formatted in a test -result.

    typemethod dictmatch {a args} {
        # FIRST, get b.
        if {[llength $args] == 1} {
            set b [lindex $args 0]
        } else {
            set b $args
        }

        # NEXT, compare each entry in b with a
        set results [list]

        foreach key [lsort [dict keys $b]] {
            if {![dict exists $a $key]} {
                lappend results $key *null*
            } elseif {![string match [dict get $b $key] [dict get $a $key]]} {
                lappend results $key [dict get $a $key]
            }
        }

        # NEXT, format.
        if {[llength $results] == 0} {
            return "OK"
        }

        set out "\n"
        foreach {key val} $results {
            append out "        "
            append out [list $key $val]
            append out "\n"
        } 
        append out "    "
        
        return $out
    }


}


