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
        nbhoods
        nbrel_mn
        groups
        nbgroups
        frcgroups
        orggroups
        sat_ngc
        rel_nfg
        coop_nfg
        units
        situations
        ensits_t
        actsits_t
        demog_n
        demog_ng
    }

    # cleanupModules -- list of modules that need to be reconfigured
    # after a test.

    typevariable cleanupModules {
        nbhood
        nbrel
        civgroup
        nbgroup
        frcgroup
        orggroup
        sat
        rel
        coop
        unit
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
            urbanization URBAN
            vtygain      1.0
            refpoint     {100 100}
            polygon      {80 80 120 80 100 120}
        }

        defentity OV1 ::nbhood {
            n            OV1
            longname     "Over Here"
            urbanization SUBURBAN
            vtygain      1.0
            refpoint     {101 101}
            polygon      {81 81 121 81 101 121}
        }

        defentity NB2 ::nbhood {
            n            NB2
            longname     "There"
            urbanization RURAL
            vtygain      1.0
            refpoint     {300 300}
            polygon      {280 280 320 280 300 320}
        }


        defentity NB3 ::nbhood {
            n            NB3
            longname     "County"
            urbanization RURAL
            vtygain      1.0
            refpoint     {500 500}
            polygon      {400 400 400 800 800 800 800 400}
        }

        defentity NB4 ::nbhood {
            n            NB4
            longname     "Town"
            urbanization URBAN
            vtygain      1.0
            refpoint     {700 700}
            polygon      {600 600 600 800 800 800 800 600}
        }


        # Civ Groups
        
        defentity SHIA ::civgroup {
            g        SHIA
            longname "Shia"
            color    "#c00001"
            shape    NEUTRAL
        }

        defentity SUNN ::civgroup {
            g        SUNN
            longname "Sunni"
            color    "#c00002"
            shape    NEUTRAL
        }

        defentity KURD ::civgroup {
            g        KURD
            longname "Kurd"
            color    "#c00003"
            shape    NEUTRAL
        }

        defentity PASH ::civgroup {
            g        PASH
            longname "Pashtuns"
            color    "#c00004"
            shape    NEUTRAL
        }

        # Neighborhood Groups

        defentity NB1SHIA ::nbgroup {
            n              NB1
            g              SHIA
            local_name     "NB1 Shias"
            basepop        1000
            demeanor       AVERAGE
            rollup_weight  1.0
            effects_factor 1.1
        }

        defentity NB1SUNN ::nbgroup {
            n              NB1
            g              SUNN
            local_name     "NB1 Sunnis"
            basepop        1000
            demeanor       AGGRESSIVE
            rollup_weight  1.2
            effects_factor 1.3
        }

        defentity NB2SHIA ::nbgroup {
            n              NB2
            g              SHIA
            local_name     "NB2 Shias"
            basepop        1000
            demeanor       AVERAGE
            rollup_weight  2.0
            effects_factor 2.1
        }

        defentity NB2SUNN ::nbgroup {
            n              NB2
            g              SUNN
            local_name     "NB2 Sunnis"
            basepop        1000
            demeanor       AGGRESSIVE
            rollup_weight  2.2
            effects_factor 2.3
        }

        # Force Groups

        defentity BLUE ::frcgroup {
            g         BLUE
            longname  "US Army"
            color     "#f00001"
            shape     FRIEND
            forcetype REGULAR
            demeanor  AVERAGE
            uniformed yes
            local     no
            coalition yes
        }

        defentity BRIT ::frcgroup {
            g         BRIT
            longname  "British Forces"
            color     "#f00002"
            shape     FRIEND
            forcetype REGULAR
            demeanor  AVERAGE
            uniformed yes
            local     no
            coalition yes
        }
        
        defentity ALQ ::frcgroup {
            g         ALQ
            longname  "Al Qaeda"
            color     "#f00003"
            shape     ENEMY
            forcetype IRREGULAR
            demeanor  AGGRESSIVE
            uniformed no
            local     no
            coalition no
        }
        
        # Organization Groups

        defentity USAID ::orggroup {
            g              USAID
            longname       "US Aid"
            color          "#000001"
            shape          NEUTRAL
            orgtype        NGO
            demeanor       AVERAGE
            rollup_weight  1.0
            effects_factor 1.1
        }

        defentity HAL ::orggroup {
            g              HAL
            longname       "Haliburton"
            color          "#000002"
            shape          NEUTRAL
            orgtype        CTR
            demeanor       AVERAGE
            rollup_weight  1.2
            effects_factor 1.3
        }

        # Units

        defentity BLUE1 ::unit {
            g         BLUE
            u         BLUE1
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity BLUE2 ::unit {
            g         BLUE
            u         BLUE2
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity BRIT1 ::unit {
            g         BRIT
            u         BRIT1
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity BRIT2 ::unit {
            g         BRIT
            u         BRIT2
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity USAID1 ::unit {
            g         USAID
            u         USAID1
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity USAID2 ::unit {
            g         USAID
            u         USAID2
            personnel 15
            location  {0 0}
            a         NONE
        } 

        defentity HAL1 ::unit {
            g         HAL
            u         HAL1
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity HAL2 ::unit {
            g         HAL
            u         HAL2
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity NB1SHIA1 ::unit {
            g         SHIA
            origin    NB1
            u         NB1SHIA1
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity NB1SHIA2 ::unit {
            g         SHIA
            origin    NB1
            u         NB1SHIA2
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity NB1SUNN1 ::unit {
            g         SUNN
            origin    NB1
            u         NB1SUNN1
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity NB1SUNN2 ::unit {
            g         SUNN
            origin    NB1
            u         NB1SUNN2
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity NB2SHIA1 ::unit {
            g         SHIA
            origin    NB2
            u         NB2SHIA1
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity NB2SHIA2 ::unit {
            g         SHIA
            origin    NB2
            u         NB2SHIA2
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity NB2SUNN1 ::unit {
            g         SUNN
            origin    NB2
            u         NB2SUNN1
            personnel 15
            location  {0 0}
            a         NONE
        }

        defentity NB2SUNN2 ::unit {
            g         SUNN
            origin    NB2
            u         NB2SUNN2
            personnel 15
            location  {0 0}
            a         NONE
        }
    }

    # defentity name module parmdict
    #
    # name      The entity name
    # module    The module that creates it
    # parmdict  The creation dictionary
    #
    # Adds the entity to the entities array

    proc defentity {name module parmdict} {
        set entities($name) [list $module $parmdict]
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
            lassign $entities($name) module parmdict

            {*}$module mutate create $parmdict
        }

        # TBD: This is REALLY unclean.  I should be using
        # the create orders instead, I fear, but since I'm
        # not I need to work around it.
        demog analyze
    }

    # cleanup
    #
    # Cleans up after a test:
    #
    # * Forgets notifier binds
    # * Deletes all records from the $cleanupTables
    # * Reconfigures the $cleanupModules
    # * Clears the CIF
    # * Resets the parms
    # * Restarts the eventq(n) queue
    
    typemethod cleanup {} {
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

        foreach module $cleanupModules {
            {*}$module reconfigure
        }

        cif    clear
        parm   reset
        eventq restart
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
    # Unit Routines

    # unit location u ?location?
    #
    # u     The unit ID
    # loc   A neighborhood id, a mapref
    #
    # Sets/queries the unit's location. 
    # Moves the unit to the neighborhood's refpoint, or to the
    # mapref.

    typemethod {unit location} {u {location ""}} {
        # FIRST, get the location
        if {$location ne ""} {
            if {$location in [nbhood names]} {
                set location [rdb onecolumn {
                    SELECT refpoint FROM gui_nbhoods WHERE n=$location
                }]
            }

            # NEXT, move the unit.
            ted order UNIT:MOVE u $u location $location
        }

        rdb onecolumn {SELECT location FROM gui_units WHERE u=$u}
    }


    # unit activity u ?a?
    #
    # u     The unit ID
    # a     The activity
    #
    # Sets/queries the unit's activity

    typemethod {unit activity} {u {a ""}} {
        if {$a ne ""} {
            ted order UNIT:ACTIVITY u $u a $a
        }

        rdb onecolumn {SELECT a FROM gui_units WHERE u=$u}
    }


    # unit personnel u ?num?
    #
    # u     The unit ID
    # num   Some number of personnel
    #
    # Sets/queries the unit's personnel

    typemethod {unit personnel} {u {num ""}} {
        if {$num ne ""} {
            ted order UNIT:PERSONNEL u $u personnel $num
        }

        rdb onecolumn {SELECT personnel FROM gui_units WHERE u=$u}
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







