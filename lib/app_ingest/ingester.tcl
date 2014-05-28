#-----------------------------------------------------------------------
# FILE: ingester.tcl
#
#   Data ingester.
#
# PACKAGE:
#   app_ingest(n) -- athena_ingest(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# ingester
#
# app_ingest(n) Data Ingester
#
# This module is responsible for accumulating ingested data and preparing
# the final ingestion script to be given to athena_sim(1).

snit::type ingester {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent adb   ;# scenariodb(n) handle on the ADB file.
    

    #-------------------------------------------------------------------
    # Type Variables

    # info array: data structure for the ingested data.
    #
    # dbfile        => Name of the scenario file which will ingest the data.
    # events        => dictionary of simevents by event type
    #               -> $eventType => list of ::simevent::$eventType objects

    typevariable info -array {
        dbfile       ""
        sorting      {}
        events       {}
    }
    

    #-------------------------------------------------------------------
    # Application Initialization

    # init
    #
    # Initializes the ingester, which prepares the data structures.
    
    typemethod init {} {
        set adb [scenariodb ::adb]
    }


    #-------------------------------------------------------------------
    # Predicates
    #
    # These subcommands indicate whether we've acquired needed information
    # or not.

    # gotScenario
    #
    # Returns 1 if we've successfully opened a scenario file, and 
    # 0 otherwise.

    typemethod gotScenario {} {
        # We have a scenario file if dbfile has been set.
        return [expr {$info(dbfile) ne ""}]
    }

    # gotMessages
    #
    # Returns 1 if we've got some messages, and 0 otherwise.

    typemethod gotMessages {} {
        return [rdb exists {SELECT cid FROM messages}]
    }

    # gotSorting
    #
    # Returns 1 if we've sorted the messages by event, and 0 otherwise.

    typemethod gotSorting {} {
        return [rdb exists {SELECT cid FROM cid2etype}]
    }

    #-------------------------------------------------------------------
    # Other Queries

    # dbfile
    #
    # Returns the name of the currently open .adb file, or 
    # "" if none.

    typemethod dbfile {} {
        return $info(dbfile)
    }

    #-------------------------------------------------------------------
    # Mutators

    # openScenario dbfile
    #
    # dbfile   - The full path name of an .adb file.
    #
    # Attempts to open the .adb file, and verifies the version.
    # If it succeeds, the ::adb object will be a handle to it,
    # and gotScenario will return 1.
    #
    # TBD: Need to do a sanity check on the scenario, i.e., got
    # neighborhoods, actors, groups, etc.

    typemethod openScenario {dbfile} {
        # FIRST, create the database handle and try to open the
        # file.

        if {![file exists $dbfile]} {
            error "No such file: $dbfile"
        }

        # TBD: If the sqlite3 error message isn't good, we'll
        # wrap this and throw a better error.
        sqlite3 ${type}::db $dbfile -create false -readonly true

        # NEXT, does it have the latest schema?  This will throw
        # an error if not.
        scenariodb checkschema ${type}::db
        ${type}::db close 

        # NEXT, we've got it.
        if {[adb isopen]} {
            adb close
        }

        adb open $dbfile
        set info(dbfile) $dbfile

        nbhood dbsync 

        notifier send ::ingester <update>
    }

    # retrieveTestMessages
    #
    # Retrieves our canned test messages.

    typemethod retrieveTestMessages {} {
        tigr readTestData

        notifier send ::ingester <update>
    }

    # retrieveMessages filenames
    #
    # Ideally, this should have search arguments to pass along to
    # TIGR; or perhaps the wiztigr widget should talk directly to
    # tigr.

    typemethod retrieveMessages {filenames} {
        tigr readfiles $filenames

        notifier send ::ingester <update>
    }
    
    # saveSorting sorting
    #
    # sorting   - A sorting of message IDs into event bins, or ""
    #
    # Gives the current sorting to the ingestor.  If "", there is no
    # current sorting.

    typemethod saveSorting {sorting} {
        dict for {bin idlist} $sorting {
            if {$bin in {unsorted ignored}} {
                continue
            }

            foreach id $idlist {
                rdb eval {
                    INSERT INTO cid2etype(cid,etype)
                    VALUES($id,$bin)
                }
            }
        }

        notifier send ::ingester <update>
    }

    # ingestEvents 
    #
    # Creates candidate events based on the message sorting.

    typemethod ingestEvents {} {
        simevent ingest
    }

    # script
    #
    # Returns an ingestion script for the ingested events.

    typemethod script {} {
        set supportFile [file join $::app_ingest::library ingest_support.tcl]

        set ts [clock format [clock seconds]]

        set script [enscript {
            #-------------------------------------------------------
            # athena_ingest(1) Ingestion Script
            #
            # Generated at %timestamp

        } %timestamp $ts]


        append script "\n[readfile $supportFile]\n\n"

        append script [enscript {
            #-------------------------------------------------------
            # Ingested Events

        }]

        foreach id [simevent ids] {
            append script "\n"
            append script [[simevent get $id] export] "\n"
        }

        append script [enscript {

            # End of script
            #-------------------------------------------------------
        }]

        return $script
    }

    # docs
    #
    # Returns HTML documentation for the ingested messages.

    typemethod docs {} {
        set ht [htools %AUTO%]

        $ht page "Ingestion Report"

        $ht title "Ingestion Report"

        set nEvents [llength [simevent ids]]
        set nTigr   [llength [tigr ids]]

        $ht putln "<b>At:</b> [clock format [clock seconds]]<br>"
        $ht putln "<b>Ingested:</b> $nEvents Athena events<br>"
        $ht putln "<b>From:</b> $nTigr TIGR messages<br>"

        $ht para

        foreach id [simevent ids] {
            set e [simevent get $id]

            $ht putln [$e htmltext]
        }

        $ht /page

        return [$ht get]
    }

    # saveFile filename text
    #
    # filename   - A user selected file name
    # text       - The text to save
    #
    # Attempts to save the text to disk.
    # Errors are handled by caller.

    typemethod saveFile {filename text} {
        set f [open $filename w]
        puts $f $text
        close $f
        return
    }

}



