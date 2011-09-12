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
#    See athena_test(1) for documentation of these utilities.
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# ted

snit::type ted {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Lookup tables

    # cleanupTables -- list of RDB tables that should be cleared after
    # a test.

    typevariable cleanupTables {
        activity_nga
        actors
        actsits_t
        attrit_nf
        attrit_nfg
        attroe_nfg
        civgroups
        conditions
        cond_collections
        coop_fg
        defroe_ng
        demog_g
        demog_local
        demsits_t
        deploy_ng
        ensits_t
        frcgroups
        goals
        groups
        mads
        nbhoods
        nbrel_mn
        orggroups
        personnel_g
        rel_fg
        sigevents
        sigevent_tags
        sigevent_marks
        situations
        sqdeploy_ng
        tactics
        units
        working_cash
        working_personnel
        working_deployment
    }

    # cleanupModules -- list of modules that need to be resync'd
    # after a test.
    #
    # TBD: Why don't we dbsync cif?  Should we "sim dbsync" instead?

    typevariable cleanupModules {
        nbhood
        situation
    }

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Import all util(n) and simlib(n) routines
        namespace import ::marsutil::* ::projectlib::* ::tcltest::*
    }

    #-------------------------------------------------------------------
    # Type Variables

    # Entities ted knows how to create.  The key is the entry ID; the
    # value is a pair, module name and creation dict.

    typevariable entities -array { }

    # List of entities created for this test; cleared by "ted cleanup"
    typevariable createdEntities {}

    # List of notifier events received since last "ted notifier forget".
    # Each event is "object event args..."

    typevariable notifierResults {}

    #-------------------------------------------------------------------
    # Initialization

    # init
    #
    # Initializes all TED-defined data and constraints

    typemethod init {} {
        DefineEntities

        # No constraints yet

        puts "Test Execution Deputy: Initialized"
    }

    # DefineEntities
    #
    # Defines the entities that can be created by TED

    proc DefineEntities {} {

        # Neighborhoods
        defentity NB1 ::nbhood {
            n            NB1
            longname     "Here"
            local        1
            urbanization URBAN
            controller   NONE
            vtygain      1.0
            refpoint     {100 100}
            polygon      {80 80 120 80 100 120}
        }

        defentity OV1 ::nbhood {
            n            OV1
            longname     "Over Here"
            local        1
            urbanization SUBURBAN
            controller   NONE
            vtygain      1.0
            refpoint     {101 101}
            polygon      {81 81 121 81 101 121}
        }

        defentity NB2 ::nbhood {
            n            NB2
            longname     "There"
            local        1
            urbanization RURAL
            controller   NONE
            vtygain      1.0
            refpoint     {300 300}
            polygon      {280 280 320 280 300 320}
        }


        defentity NB3 ::nbhood {
            n            NB3
            longname     "County"
            local        1
            urbanization RURAL
            controller   NONE
            vtygain      1.0
            refpoint     {500 500}
            polygon      {400 400 400 800 800 800 800 400}
        }

        defentity NB4 ::nbhood {
            n            NB4
            longname     "Town"
            local        1
            urbanization URBAN
            controller   NONE
            vtygain      1.0
            refpoint     {700 700}
            polygon      {600 600 600 800 800 800 800 600}
        }

        # Actors
        
        defentity JOE ::actor {
            a            JOE
            longname     "Joe the Actor"
            supports     SELF
            cash_reserve 200000
            income       10000
            cash_on_hand 0
        }

        defentity BOB ::actor {
            a            BOB
            longname     "Bob the Actor"
            supports     SELF
            cash_reserve 150000
            income       5000
            cash_on_hand 0
        }

        # Civ Groups
        
        defentity SHIA ::civgroup {
            g        SHIA
            longname "Shia"
            color    "#c00001"
            shape    NEUTRAL
            n        NB1
            basepop  1000
            sap      10
            demeanor AVERAGE
        } NB1

        defentity SUNN ::civgroup {
            g        SUNN
            longname "Sunni"
            color    "#c00002"
            shape    NEUTRAL
            n        NB1
            basepop  1000
            sap      0
            demeanor AGGRESSIVE
        } NB1

        defentity KURD ::civgroup {
            g        KURD
            longname "Kurd"
            color    "#c00003"
            shape    NEUTRAL
            n        NB2
            basepop  1000
            sap      0
            demeanor AGGRESSIVE
        } NB2

        # Force Groups

        defentity BLUE ::frcgroup {
            g           BLUE
            longname    "US Army"
            a           JOE
            color       "#f00001"
            shape       FRIEND
            forcetype   REGULAR
            demeanor    AVERAGE
            cost        0.0
            attack_cost 0.0
            uniformed   1
            local       0
        } JOE

        defentity BRIT ::frcgroup {
            g           BRIT
            longname    "British Forces"
            a           JOE
            color       "#f00002"
            shape       FRIEND
            forcetype   REGULAR
            demeanor    AVERAGE
            cost        0.0
            attack_cost 0.0
            uniformed   1
            local       0
        } JOE
        
        defentity ALQ ::frcgroup {
            g           ALQ
            longname    "Al Qaeda"
            a           BOB
            color       "#f00003"
            shape       ENEMY
            forcetype   IRREGULAR
            demeanor    AGGRESSIVE
            cost        0.0
            attack_cost 0.0
            uniformed   0
            local       0
        } BOB
        
        defentity TAL ::frcgroup {
            g           TAL
            longname    "Taliban"
            a           BOB
            color       "#f00004"
            shape       ENEMY
            forcetype   IRREGULAR
            demeanor    AGGRESSIVE
            cost        0.0
            attack_cost 0.0
            uniformed   0
            local       1
        } BOB
        
        # Organization Groups

        defentity USAID ::orggroup {
            g              USAID
            longname       "US Aid"
            a              JOE
            color          "#000001"
            shape          NEUTRAL
            orgtype        NGO
            demeanor       AVERAGE
            cost           0.0
        } JOE

        defentity HAL ::orggroup {
            g              HAL
            longname       "Haliburton"
            a              JOE
            color          "#000002"
            shape          NEUTRAL
            orgtype        CTR
            demeanor       AVERAGE
            cost           0.0
        } JOE

        # FRC/ORG Status Quo deployments
        defentity NB1_BLUE ::sqdeploy {
            id        {NB1 BLUE}
            personnel 5000
        } NB1 BLUE

        defentity NB1_BRIT ::sqdeploy {
            id        {NB1 BRIT}
            personnel 5000
        } NB1 BRIT

        defentity NB1_ALQ ::sqdeploy {
            id        {NB1 ALQ}
            personnel 2000
        } NB1 ALQ

        defentity NB1_TAL ::sqdeploy {
            id        {NB1 TAL}
            personnel 2000
        } NB1 TAL

        defentity NB1_USAID ::sqdeploy {
            id        {NB1 USAID}
            personnel 1000
        } NB1 USAID

        defentity NB1_HAL ::sqdeploy {
            id        {NB1 HAL}
            personnel 2000
        } NB1 HAL
    }

    # defentity name module parmdict ?entity...?
    #
    # name      The entity name
    # module    The module that creates it
    # parmdict  The creation dictionary
    # entity    An entity on which the group depends.
    #
    # Adds the entity to the entities array

    proc defentity {name module parmdict args} {
        set entities($name) [list $module $parmdict $args]
    }

    #-------------------------------------------------------------------
    # Other Client Commands

    # entity name ?dict?
    # entity name ?key value ...?
    #
    # name    The name of a defined entity
    #
    # By default returns the entity's creation dictionary
    # If additional creation parameters are given, as a single dictionary
    # or as separate keys and values, they are merged with the creation
    # dictionary and the result is returned.

    typemethod entity {name args} {
        # FIRST, entity's dict
        set dict [lindex $entities($name) 1]

        # NEXT, get the additional parameters, if any
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        if {[llength $args] > 0} {
            set dict [dict merge $dict $args]
        }

        return $dict
    }

    # create name ?name....?
    #
    # name     The name of an entity
    #
    # Calls "$module mutate create" for each named entity.

    typemethod create {args} {
        foreach name $args {
            if {$name ni $createdEntities} {
                lassign $entities($name) module parmdict parents

                # FIRST, Create any entities on which this entity depends
                $type create {*}$parents

                # NEXT, create the requested entity
                {*}$module mutate create $parmdict

                lappend createdEntities $name
            }
        }
    }

    # lock
    #
    # Reconciles the scenario, so that all implied entities are
    # created, and sends SIM:LOCK.

    typemethod lock {} {
        scenario mutate reconcile
        ted order SIM:LOCK
    }

    # cleanup
    #
    # Cleans up after a test:
    #
    # * Forgets notifier binds
    # * Deletes all records from the $cleanupTables
    # * Clears the SQLITE_SEQUENCE table
    # * Resyncs the $cleanupModules with the RDB
    # * Clears the CIF
    # * Resets the parms
    # * Restarts the eventq(n) queue
    
    typemethod cleanup {} {
        set createdEntities {}

        ted notifier forget

        if {[sim state] eq "RUNNING"} {
            sim mutate pause
        }

        if {[sim state] eq "PAUSED"} {
            sim restart
        }

        foreach table $cleanupTables {
            rdb eval "DELETE FROM $table;" 
        }

        # So that automatically generated IDs start over at 1.
        # Note that SQLite adds this table as needed.
        catch {
            rdb eval {DELETE FROM main.sqlite_sequence}
        }

        foreach module $cleanupModules {
            {*}$module dbsync
        }

        cif      clear
        parm     reset
        eventq   restart
        bsystem  clear
        simclock reset
    }

    # sendex ?-error? command...
    #
    # command...    A Tcl command, represented as either a single argument
    #               containing the entire command, or as multiple arguments.
    #
    # Executes the command in the Executive's client interpreter,
    # and returns the result.  If -error is specified, expects an error
    # returns the error message.
    #
    # Examples: The following calls are equivalent
    #
    #    ted sendex magic absit BADFOOD {1.0 1.0}
    #    ted sendex {magic absit BADFOOD {1.0 1.0}} 

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
                executive eval $command
            } result]

            if {$code} {
                return $result
            } else {
                return -code error "Expected error, got ok"
            }
        } else {
            # Normal case; let nature take its course
            # executive eval test $command
            executive eval $command
        }
    }

    # order ?-reject? name parmdict
    #
    # name       A simulation order
    # parmdict   The order's parameter dictionary, as a single
    #            argument or as multiple arguments.
    #
    # Sends the order as the test client, and returns the result.
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
                order send test $order $parmdict
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
            order send test $order $parmdict
        }
    }

    # schedule ?-reject? timespec name parmdict
    #
    # timespec   A time specification string
    # name       A simulation order
    # parmdict   The order's parameter dictionary, as a single
    #            argument or as multiple arguments.
    #
    # Schedules the order as the test client, and returns the result.
    # If "-reject" is used, expects the order to be rejected.

    typemethod schedule {args} {
        # FIRST, is -reject specified?
        if {[lindex $args 0] eq "-reject"} {
            lshift args
            set rejectFlag 1
        } else {
            set rejectFlag 0
        }

        # NEXT, get the timespec
        set timespec [lshift args]

        require {$timespec ne ""} "No timespec specified!"

        # NEXT, get the order name
        set order [lshift args]

        require {$order ne ""} "No order specified!"

        # NEXT, get the parm dict
        if {[llength $args] == 1} {
            set parmdict [lindex $args 0]
        } else {
            set parmdict $args
        }

        # NEXT, schedule the order
        if {$rejectFlag} {
            set code [catch {
                order schedule test $timespec $order $parmdict
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
            order schedule test $timespec $order $parmdict
        }
    }

    # query sql
    #
    # sql     - An SQL query
    #
    # Does an RDB query using the SQL text, and pretty-prints the 
    # whitespace.

    typemethod query {sql} {
        return "\n[rdb query $sql -maxcolwidth 80]    "
    }

    # querylist sql
    #
    # sql     - An SQL query
    #
    # Does an RDB query using the SQL text, and pretty-prints the 
    # whitespace, returning -list output

    typemethod querylist {sql args} {
        return "\n[rdb query $sql -mode list]    "
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

    # pdict dict
    #
    # dict - A dictionary
    # 
    # Pretty-prints a dictionary for use in -result

    typemethod pdict {dict} {
        set results "\n"

        set wid [lmaxlen [dict keys $dict]]

        foreach {key value} $dict {
            append results \
                "        [format {%-*s %s} $wid $key [list $value]]\n" 
        }
        append results "    "
                    
        return $results
    }

}









